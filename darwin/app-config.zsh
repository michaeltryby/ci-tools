#!/usr/bin/env zsh

#
#  app-config.sh - Generates nrtest app configuration file for test executable
#
#  Date Created: 11/15/2017
#       Updated: 4/1/2020
#
#  Author:       Michael E. Tryby
#                US EPA - ORD/NRMRL
#
#  Requires:
#    git
#
#  Environment Variables:
#    PROJECT
#    PLATFORM
#
#  Arguments:
#    1 - absolute path to test executable
#    2 - (SUT build id)
#

# Check requirements
where git &> /dev/null
[[ ! $? ]] && { echo "ERROR: git not installed"; return 1 }

# check that env variables are set
[[ ! -v PROJECT ]] && { echo "ERROR: PROJECT must be defined"; return 1 }
[[ ! -v PLATFORM ]] && { echo "ERROR: PLATFORM must be defined"; return 1 }


# check if project is swmm otherwise EPANET
if [[ ${PROJECT} == *"swmm"* ]]; then
    TEST_CMD="run-${PROJECT}"
else
    TEST_CMD="run${PROJECT}"
fi

# path to executable in cmake build tree
ABS_BUILD_PATH=$1

# process optional arguments
if [ ! -z "$2" ]; then
    BUILD_ID=$2
else
    BUILD_ID="unknown"
fi


# determine version
VERSION=$( git rev-parse --short HEAD )
[[ ! -v VERSION ]] && { echo "ERROR: VERSION must be determined"; return 1 }

cat<<EOF
{
    "name" : "${PROJECT}",
    "version" : "${VERSION}",
    "description" : "${PLATFORM} ${BUILD_ID}",
    "setup_script" : "",
    "exe" : "${ABS_BUILD_PATH}/${TEST_CMD}"
}
EOF
