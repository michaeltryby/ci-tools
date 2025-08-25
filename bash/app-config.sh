#!/usr/bin/env bash

#
#  app-config.sh - Generates nrtest app configuration file for test executable
#
#  Date Created: Aug 24, 2025
#
#  Requires:
#    git
#
#  Environment Variables:
#    PROJECT
#
#  Arguments:
#    1 - absolute path to test executable
#    2 - Platform
#    3 - (SUT build id)
#
#
#  Copyright (c) 2025 Michael E. Tryby and contributors
#  License: MIT
#

# Check requirements
if ! command -v git >/dev/null 2>&1; then
    echo "ERROR: git not installed"
    return 1
fi

# check that env variables are set
if [ -z "${PROJECT:-}" ]; then
    echo "ERROR: PROJECT must be defined"
    return 1
fi

# check if project is swmm otherwise EPANET
TEST_CMD="run${PROJECT}"

# path to executable in cmake build tree
ABS_BUILD_PATH=$1

# process optional arguments
if [ -n "$2" ]; then
    PLATFORM=$2
else
    PLATFORM="unknown"
fi

if [ -n "$3" ]; then
    BUILD_ID=$3
else
    BUILD_ID="unknown"
fi

# determine SUT version
V=$( "${ABS_BUILD_PATH}/${TEST_CMD}" -v )
VERSION=${V#?}
if [ -z "${VERSION}" ]; then
    echo "ERROR: VERSION could not be determined"
    return 1
fi

# determine git hash
GIT_HASH=$( git rev-parse --short HEAD )
if [ -z "${GIT_HASH}" ]; then
    echo "ERROR: GIT_HASH could not be determined"
    return 1
fi

cat<<EOF
{
    "name" : "${PROJECT}",
    "version" : "${VERSION}",
    "description" : "${PLATFORM} ${BUILD_ID} ${GIT_HASH}",
    "setup_script" : "",
    "exe" : "${ABS_BUILD_PATH}/${TEST_CMD}"
}
EOF
