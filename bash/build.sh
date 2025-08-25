#!/usr/bin/env bash

#
#  build.sh - Builds swmm/epanet executable
#
#  Date Created: Aug 24, 2025
#
#
#  Copyright (c) 2025 Michael E. Tryby and contributors
#  License: MIT
#

# Function to display usage information
usage() {
    cat << EOF
build.sh -- Builds SWMM/EPANET executables using CMake presets

USAGE:
    build.sh [OPTIONS]

DESCRIPTION:
    Builds SWMM/EPANET executables using CMake presets. Supports both debug
    and release builds with automatic testing for debug builds and packaging
    for release builds.

OPTIONS:
    -p, --preset PRESET   Specify the CMake preset to use (default: darwin-release)
    -l, --list            List available CMake configure presets
    -h, --help            Show this help message and exit

REQUIRED ENVIRONMENT VARIABLES:
    PROJECT               Set to 'swmm' or 'epanet' to specify project
    BUILD_HOME            Directory for build artifacts (default: build)
    PLATFORM              Set to 'darwin_x86_64' or 'darwin_arm64' based on system architecture
    PRESET                CMake preset to use for building (default: darwin-release)

DEPENDENCIES:
    - cmake (for building executables)

EXAMPLES:
    # List available configure presets (source from project root)
    . ci-tools/bash/build.sh -l

    # Build with default preset (source from project root)
    . ci-tools/bash/build.sh

    # Build with debug preset and run tests (source from project root)
    . ci-tools/bash/build.sh -p darwin-debug

    # Show help (source from project root)
    . ci-tools/bash/build.sh --help
EOF
}

# Function to list available CMake configure presets
list_presets() {
    cmake --list-presets
}

# determine project directory - assume script is sourced from project root
CUR_DIR=${PWD}
PROJECT_DIR=${PWD}

# Check requirements
if ! command -v cmake >/dev/null 2>&1; then
    echo "Error: cmake not installed"
    cd "${CUR_DIR}" || return 1
    return 1
fi

# set defaults
export BUILD_HOME="build"
PRESET="darwin-release"

while [ $# -gt 0 ]; do
    case "$1" in
        -p|--preset)
            PRESET="$2"
            shift 2
            ;;
        -l|--list)
            list_presets
            return 0
            ;;
        -h|--help)
            usage
            return 0
            ;;
        *)
            echo "Error: Unknown option: $1"
            usage
            return 1
            ;;
    esac
done

# determine project
if [ -z "${PROJECT:-}" ]; then
    PROJECT_BASENAME=$(basename "$PROJECT_DIR")
    # Convert to lowercase for comparison
    PROJECT_LOWER=$(echo "$PROJECT_BASENAME" | tr '[:upper:]' '[:lower:]')

    case "$PROJECT_LOWER" in
        sto*|swm*)
            export PROJECT="swmm"
            ;;
        wat*|epa*)
            export PROJECT="epanet"
            ;;
    esac
fi

# check that PROJECT is defined
if [ -z "${PROJECT:-}" ]; then
    echo "ERROR: PROJECT must be defined"
    cd "${CUR_DIR}" || return 1
    return 1
fi

# prepare for artifact upload
if [ ! -d upload ]; then
    mkdir upload
fi

# Validate preset name - must end with debug or release
case "$PRESET" in
    *debug|*release)
        echo "CHECK: using PRESET = ${PRESET}"
        ;;
    *)
        echo "Error: Preset ${PRESET} must end with 'debug' or 'release'"
        cd "${CUR_DIR}" || return 1
        return 1
        ;;
esac

export PRESET=$PRESET

# perform the build using presets
case "$PRESET" in
    *debug)
        echo "Building debug preset and running tests:"
        cmake --preset "${PRESET}" && cmake --build --preset "${PRESET}"
        ctest --preset "${PRESET}" --output-on-failure
        RESULT=$?
        ;;
    *release)
        echo "Building release preset and packaging artifacts:"
        cmake --preset "${PRESET}" && cmake --build --preset "${PRESET}" --target package
        RESULT=$?
        cp ./build/"${PRESET}"/*.tar.gz ./upload 2>/dev/null || true
        ;;
esac

# set platform variable
UNAME_SYSTEM=$(uname | tr '[:upper:]' '[:lower:]')
UNAME_MACHINE=$(uname -m)
export PLATFORM="${UNAME_SYSTEM}-${UNAME_MACHINE}"

# GitHub Actions
if [ -n "${GITHUB_ENV:-}" ]; then
    echo "PLATFORM=$PLATFORM" >> "$GITHUB_ENV"
fi

# return user to current dir
cd "${CUR_DIR}" || return 1

return $RESULT
