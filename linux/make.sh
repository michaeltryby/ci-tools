#!/bin/bash

#
#  make.sh - Builds swmm executable
#
#  Date Created: 06/29/2020
#  Date Modified: 07/06/2020
#
#  Authors:      Michael E. Tryby
#                US EPA - ORD/NRMRL
#                
#                Caleb A. Buahin
#                Xylem Inc.
#
#  Environment Variables:
#    PROJECT

# Check to make sure PROJECT is defined
if [[ ! -v PROJECT ]]; then echo "ERROR: PROJECT must be defined"; exit 1; fi


export BUILD_HOME="build"

GENERATOR="Ninja"


# determine project directory
CUR_DIR=${PWD}
SCRIPT_HOME=$(cd `dirname $0` && pwd)

cd ${SCRIPT_HOME}/../../

# perform the build
cmake -E make_directory ${BUILD_HOME}
cmake -E chdir ${BUILD_HOME} cmake -G ${GENERATOR} ..
cmake --build ./${BUILD_HOME} --config Release --target all -- -v


export PLATFORM="Linux"


# return user to current dir
cd ${CUR_DIR}
