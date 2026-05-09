#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

need_cmd curl
need_cmd tar
need_cmd grep
need_cmd sed
need_cmd find

DEFAULT_JDKS=(
    temurin17
    temurin21
    temurin25
    zulu17
    zulu21
    zulu25
    graal21
    graal25
    jdknet26
)

selected=("$@")
if [[ ${#selected[@]} -eq 0 ]]; then
    selected=("${DEFAULT_JDKS[@]}")
fi

for name in "${selected[@]}"; do
    case "$name" in
        temurin17) download_and_extract "$name" "$(adoptium_url 17)" ;;
        temurin21) download_and_extract "$name" "$(adoptium_url 21)" ;;
        temurin25) download_and_extract "$name" "$(adoptium_url 25)" ;;
        zulu17) download_and_extract "$name" "$(azul_url 17)" ;;
        zulu21) download_and_extract "$name" "$(azul_url 21)" ;;
        zulu25) download_and_extract "$name" "$(azul_url 25)" ;;
        graal17) download_and_extract "$name" "$(graal17_archive_url)" ;;
        graal21) download_and_extract "$name" "$(graal_url 21)" ;;
        graal25) download_and_extract "$name" "$(graal_url 25)" ;;
        jdknet26) download_and_extract "$name" "$(jdknet_url 26)" ;;
        *)
            die "unknown JDK name: $name"
            ;;
    esac
done

printf '\nInstalled JDKs:\n'
for name in $(runtime_names); do
    printf '  %-12s %s\n' "$name" "$(jdk_home "$name")"
done
