#!/bin/bash

#
#  make.sh - Builds swmm executable
#
#  Date Created: 06/29/2020
#
#  Authors:      Michael E. Tryby
#                US EPA - ORD/NRMRL
#                
#                Caleb A. Buahin
#                Xylem Inc.
#

export PROJECT="swmm"
export BUILD_HOME="build"

GENERATOR="Ninja"


# determine project directory
CUR_DIR=${PWD}
SCRIPT_HOME=$(cd `dirname $0` && pwd)

cd ${SCRIPT_HOME}/../..

# perform the build
# cmake -E make_directory ${BUILD_HOME}
cmake -E chdir ${BUILD_HOME} cmake -G ${GENERATOR} ..
cmake --build ./${BUILD_HOME} --config Release --target all -- -v


export PLATFORM="Linux"


# return user to current dir
cd ${CUR_DIR}
