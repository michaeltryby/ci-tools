#!/usr/bin/env zsh

#
#  build.zsh - Builds swmm/epanet executable
#
#  Date Created: 06/07/2025
#       Updated:
#
#  Author:  Michael E. Tryby
#

# Function to display usage information
print_usage() {
cat << EOF

Build SWMM/EPANET executables using CMake presets.

Usage:
  build.zsh [options]

Options:
  -p, --preset PRESET   Specify the CMake preset to use (default: darwin-release)
  -l, --list            List available CMake configure presets
  -h, --help            Display this help message and exit

Environment:
  BUILD_HOME            Directory for build artifacts (default: build)
  PROJECT               Set to 'swmm' or 'epanet' to specify project
  PLATFORM              Set to 'darwin_x86_64' or 'darwin_arm64' based on system architecture

Examples:
  build.zsh -l                  List available presets
  build.zsh                     Build with default preset (darwin-release)
  build.zsh -p darwin-debug     Build with debug preset and run tests
EOF
}

# Function to list available CMake presets
list_presets() {
    cmake --list-presets
}

setopt extendedglob

# determine project directory
CUR_DIR=${PWD}
SCRIPT_HOME=${0:a:h}
cd ${SCRIPT_HOME}
cd ./../../
PROJECT_DIR=${PWD}


# Check requirements
if ! command -v cmake &> /dev/null; then
    echo "Error: cmake not installed"
fi

# set defaults
export BUILD_HOME="build"
PRESET="darwin-release"

# determine project
if [[ ! -v PROJECT ]]
then
[[ $( basename $PROJECT_DIR ) = ((#i)'STO'*|(#i)'SWM'*) ]] && { export PROJECT="swmm" }
[[ $( basename $PROJECT_DIR ) = ((#i)'WAT'*|(#i)'EPA'*) ]] && { export PROJECT="epanet" }
fi
# check that PROJECT is defined
[[ ! -v PROJECT ]] && { echo "ERROR: PROJECT must be defined"; return 1 }

# prepare for artifact upload
if [ ! -d upload ]; then
    mkdir upload
fi


while [[ $# -gt 0 ]]
do
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
    print_usage
    return 0
    ;;
    *)
    echo "Error: Unknown option: $1"
    print_usage
    return 1
    ;;
esac
done


# Validate preset name - must end with debug or release
if [[ ! "${PRESET}" == *"debug" && ! "${PRESET}" == *"release" ]]; then
    echo "Error: Preset ${PRESET} must end with 'debug' or 'release'"
    return 1
else
    echo CHECK: using PRESET = ${PRESET}
fi

# perform the build using presets
if [[ "${PRESET}" == *"debug" ]]; then
    echo "Building debug preset and running tests:"
    cmake --preset ${PRESET} && cmake --build --preset ${PRESET}
    ctest --preset ${PRESET} --output-on-failure
    RESULT=$?
elif [[ "${PRESET}" == *"release" ]]; then
    echo "Building release preset and packaging artifacts:"
    cmake --preset ${PRESET} && cmake --build --preset ${PRESET} --target package
    RESULT=$?
    cp ./build/${PRESET}/*.tar.gz ./upload 2>/dev/null || true
fi


# set platform variable
export PLATFORM="${$( uname ):l}_$( uname -m )"

#GitHub Actions
if [[ -v GITHUB_ENV ]]; then
    echo "PLATFORM=$PLATFORM" >> $GITHUB_ENV
fi


# return user to current dir
cd ${CUR_DIR}

return $RESULT
