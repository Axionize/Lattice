#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
MATRIX_DIR="${MATRIX_DIR:-$ROOT_DIR/.jmh-matrix}"
JDKS_DIR="${JDKS_DIR:-$MATRIX_DIR/jdks}"
DOWNLOADS_DIR="${DOWNLOADS_DIR:-$MATRIX_DIR/downloads}"
JARS_DIR="${JARS_DIR:-$MATRIX_DIR/jars}"
RESULTS_DIR="${RESULTS_DIR:-$MATRIX_DIR/results}"

mkdir -p "$JDKS_DIR" "$DOWNLOADS_DIR" "$JARS_DIR" "$RESULTS_DIR"

die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

need_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

linux_arch() {
    case "$(uname -m)" in
        x86_64|amd64) printf 'x64' ;;
        aarch64|arm64) printf 'aarch64' ;;
        *) die "unsupported architecture: $(uname -m)" ;;
    esac
}

adoptium_arch() {
    case "$(linux_arch)" in
        x64) printf 'x64' ;;
        aarch64) printf 'aarch64' ;;
    esac
}

azul_arch() {
    case "$(linux_arch)" in
        x64) printf 'x64' ;;
        aarch64) printf 'arm' ;;
    esac
}

graal_arch() {
    case "$(linux_arch)" in
        x64) printf 'x64' ;;
        aarch64) printf 'aarch64' ;;
    esac
}

adoptium_url() {
    local version="$1"
    printf 'https://api.adoptium.net/v3/binary/latest/%s/ga/linux/%s/jdk/hotspot/normal/eclipse' \
        "$version" "$(adoptium_arch)"
}

azul_url() {
    local version="$1"
    local url
    url="$(curl -fsSL --connect-timeout 10 --max-time 60 "https://api.azul.com/metadata/v1/zulu/packages/?java_version=${version}&os=linux&arch=$(azul_arch)&java_package_type=jdk&javafx_bundled=false&archive_type=tar.gz&release_status=ga&availability_types=CA&certifications=tck&page=1&page_size=1" \
        | sed -n 's/.*"download_url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
        | head -n 1)"
    [[ -n "$url" ]] || die "could not resolve Azul Zulu JDK $version"
    printf '%s' "$url"
}

graal_url() {
    local version="$1"
    printf 'https://download.oracle.com/graalvm/%s/latest/graalvm-jdk-%s_linux-%s_bin.tar.gz' \
        "$version" "$version" "$(graal_arch)"
}

graal17_archive_url() {
    printf 'https://download.oracle.com/graalvm/17/archive/graalvm-jdk-17.0.12_linux-%s_bin.tar.gz' \
        "$(graal_arch)"
}

jdknet_url() {
    local version="$1"
    local arch
    local url
    arch="$(linux_arch)"
    url="$(curl -fsSL "https://jdk.java.net/${version}/" \
        | grep -Eo "https://download\\.java\\.net/java/[^\"']+linux-${arch}_bin\\.tar\\.gz" \
        | head -n 1 || true)"
    if [[ -z "$url" ]]; then
        url="$(curl -fsSL 'https://jdk.java.net/archive/' \
            | grep -Eo "https://download\\.java\\.net/java/[^\"']+jdk-${version}[^\"']+linux-${arch}_bin\\.tar\\.gz" \
            | head -n 1 || true)"
    fi
    [[ -n "$url" ]] || die "could not resolve jdk.java.net JDK $version"
    printf '%s' "$url"
}

jdk_home() {
    local name="$1"
    printf '%s/%s' "$JDKS_DIR" "$name"
}

download_and_extract() {
    local name="$1"
    local url="$2"
    local home
    local archive
    local tmp
    local extracted

    home="$(jdk_home "$name")"
    if [[ -x "$home/bin/java" ]]; then
        printf '%s already installed at %s\n' "$name" "$home"
        return
    fi

    archive="$DOWNLOADS_DIR/${name}.tar.gz"
    tmp="$DOWNLOADS_DIR/extract-${name}"
    rm -rf "$tmp" "$home"
    mkdir -p "$tmp"

    printf 'downloading %s\n  %s\n' "$name" "$url"
    curl -fL --retry 3 --retry-delay 2 -o "$archive" "$url"
    tar -xzf "$archive" -C "$tmp"
    extracted="$(find "$tmp" -mindepth 1 -maxdepth 3 -type f -path '*/bin/java' -printf '%h\n' | head -n 1)"
    [[ -n "$extracted" ]] || die "archive for $name did not contain bin/java"
    mv "$(dirname "$extracted")" "$home"
    rm -rf "$tmp"
    "$home/bin/java" -version
}

runtime_major() {
    local java_bin="$1/bin/java"
    local version
    version="$("$java_bin" -XshowSettings:properties -version 2>&1 \
        | sed -n 's/[[:space:]]*java.specification.version = //p' \
        | head -n 1)"
    [[ -n "$version" ]] || die "could not read java.specification.version from $java_bin"
    printf '%s' "${version#1.}"
}

runtime_names() {
    find "$JDKS_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort
}
