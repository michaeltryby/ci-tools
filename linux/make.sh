#!/bin/bash

#
#  make.sh - Builds swmm executable
#
#  Date Created: 06/29/2020
#  Date Modified: 07/06/2020
#
#  Authors:      See AUTHORS
#
#  Environment Variables:
#    PROJECT name for project
#
#  Optional Arguments:
#    -g ("GENERATOR") defaults to "Ninja"
#    -t builds and runs unit tests (requires Boost)


# Check to make sure PROJECT is defined
if [[ -z "${PROJECT}" ]]; then
    echo "ERROR: PROJECT could not be determined"
    exit 1
else
    echo INFO: Building ${PROJECT}  ...
fi

# set global defaults
export BUILD_HOME="build"
export PLATFORM="linux"

# determine project directories
SCRIPT_HOME=$(cd `dirname $0` && pwd)
cd ${SCRIPT_HOME}
cd ../../
PROJECT_DIR=${PWD}

# prepare for artifact upload
if [ ! -d upload ]; then
    mkdir upload
fi

echo INFO: Building ${PROJECT}  ...

GENERATOR="Unix Makefiles"
TESTING=0

POSITIONAL=()

while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    -g|--gen)
    GENERATOR="$2"
    shift # past argument
    shift # past value
    ;;
    -t|--test)
    TESTING=1
    shift # past argument
    ;;
    *)    # unknown option
    shift # past argument
    ;;
esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters

# perform the build
cmake -E make_directory ${BUILD_HOME}

RESULT=$?

if [ ${TESTING} -eq 1 ];
then
    cmake -E chdir ./${BUILD_HOME} cmake -G "${GENERATOR}" -DBUILD_TESTS=ON .. \
    && cmake --build ./${BUILD_HOME}  --config Debug \
    && cmake -E chdir ./${BUILD_HOME}  ctest -C Debug --output-on-failure
    RESULT=$?

else
    cmake -E chdir ./${BUILD_HOME} cmake -G "${GENERATOR}" -DBUILD_TESTS=OFF .. \
    && cmake --build ./${BUILD_HOME} --config Release --target package
    RESULT=$?
    cp ./${BUILD_HOME}/*.tar.gz ./upload >&1
fi

#GitHub Actions
echo "PLATFORM=$PLATFORM" >> $GITHUB_ENV

# return user to current dir
cd ${PROJECT_DIR}

exit $RESULT
