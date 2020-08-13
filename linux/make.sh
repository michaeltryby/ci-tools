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
#    PROJECT name for project
#
#  Optional Arguments:
#    -g ("GENERATOR") defaults to "Ninja"
#    -t builds and runs unit tests (requires Boost)


# set global defaults
export BUILD_HOME="build"

# determine project directories
CUR_DIR=${PWD}
SCRIPT_HOME=$(cd `dirname $0` && pwd)

echo INFO: Building ${PROJECT}  ...

# Check to make sure PROJECT is defined
if [[ ! -v PROJECT ]];
then 
    echo "ERROR: PROJECT must be defined"
    exit 1 
fi

echo INFO: Building ${PROJECT}  ...

GENERATOR="Ninja"
TESTING=0


cd ${SCRIPT_HOME}/../../

# perform the build
cmake -E make_directory ${BUILD_HOME}

if [ ${TESTING}=1 ]; 
then
# cmake -E chdir ${BUILD_HOME} cmake -G ${GENERATOR} ..
# cmake --build ./${BUILD_HOME} --config Release --target all -- -v
    cmake -E chdir ./${BUILD_HOME} cmake -G ${GENERATOR} -DBUILD_TESTS=ON .. \
    && cmake --build ./${BUILD_HOME}  --config Debug \
    & echo. && cmake -E chdir ./${BUILD_HOME}  ctest -C Debug --output-on-failure

else
    cmake -E chdir ./${BUILD_HOME} cmake -G ${GENERATOR} -DBUILD_TESTS=OFF .. \
    && cmake --build ./${BUILD_HOME} --config Release --target package \
    && cp ./${BUILD_HOME}/*.zip ./upload >&1
fi

export PLATFORM="Linux"

# return user to current dir
cd ${CUR_DIR}
