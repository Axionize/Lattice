#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

need_cmd find

BUILD_JDK="${BUILD_JDK:-temurin25}"
BUILD_HOME="$(jdk_home "$BUILD_JDK")"
[[ -x "$BUILD_HOME/bin/java" ]] || die "build JDK not installed: $BUILD_JDK ($BUILD_HOME)"

BUILD_MAJOR="$(runtime_major "$BUILD_HOME")"
TARGETS="${TARGETS:-17 21 25}"
GRADLE_ARGS="${GRADLE_ARGS:---no-daemon}"

printf 'Using build JDK %s (%s), Java %s\n' "$BUILD_JDK" "$BUILD_HOME" "$BUILD_MAJOR"

for target in $TARGETS; do
    if (( target > BUILD_MAJOR )); then
        printf 'skipping release %s; build JDK is only %s\n' "$target" "$BUILD_MAJOR"
        continue
    fi

    printf '\nBuilding JMH jar for --release %s\n' "$target"
    (
        cd "$ROOT_DIR"
        JAVA_HOME="$BUILD_HOME" PATH="$BUILD_HOME/bin:$PATH" ./gradlew $GRADLE_ARGS \
            clean jmhJar \
            -Plattice.javaRelease="$target" \
            -Plattice.javaToolchain="$BUILD_MAJOR"
    )

    jar="$(find "$ROOT_DIR/build/libs" -maxdepth 1 -type f -name '*-jmh.jar' | head -n 1)"
    [[ -n "$jar" ]] || die "could not find generated JMH jar for release $target"
    cp "$jar" "$JARS_DIR/lattice-jmh-release-${target}.jar"
    printf 'wrote %s\n' "$JARS_DIR/lattice-jmh-release-${target}.jar"
done
