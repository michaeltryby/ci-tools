#! /bin/bash

#
#  app-config.sh - Generates nrtest app configuration file for test executable
#
#  Date Created: 11/15/2017
#       Updated: 08/21/2020
#
#  Authors:      See AUTHORS
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
#    3 - build identifier for SUT
#

# Check requirements
type git >/dev/null 2>&1 || { echo "ERROR: git not installed"; exit 1; }


# check that env variables are set
if [[ ! -v PROJECT ]]; then echo "ERROR: PROJECT must be defined"; exit 1; fi

# check if project is swmm otherwise EPANET
TEST_CMD="run${PROJECT}"

# path to executable in cmake build tree
ABS_BUILD_PATH=$1

# process optional arguments
if [ ! -z "$2" ]; then
    PLATFORM=$2
else
    PLATFORM="unknown"
fi

if [ ! -z "$3" ]; then
    BUILD_ID=$3
else
    BUILD_ID="unknown"
fi

# determine version
VERSION=$( git rev-parse --short HEAD )
if [ -z ${VERSION} ]; then echo "ERROR: VERSION must be determined"; exit 1; fi;

build_description="${PLATFORM} ${BUILD_ID}"

cat<<EOF
{
    "name" : "${PROJECT}",
    "version" : "${VERSION}",
    "description" : "${PLATFORM} ${BUILD_ID}",
    "setup_script" : "",
    "exe" : "${ABS_BUILD_PATH}/${TEST_CMD}"
}
EOF
