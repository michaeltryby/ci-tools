#!/usr/bin/env zsh

#
#  before-nrtest.zsh - Runs before numerical regression test
#
#  Date Created: 11/15/2017
#       Updated: 06/08/2025
#
#  Author:       See AUTHORS
#
#  Notes:
#    Tests and benchmark files are stored in the swmm-nrtestsuite repo or in
#    repo pointed to by shell variable NRTESTS_URL.
#
#    This script retreives them using a stable URL associated with a release on
#    GitHub and stages the files in directory TEST_HOME for nrtest to run.
#
#    The script takes RELEASE_TAG as an argument to select with tagged version
#    of tests and benchmarks is used for testing. Default behavior is to
#    determine the "latest" tagged release and use it.
#

export TEST_HOME="nrtests"


# Function to display usage information
usage() {
    cat << EOF
before-nrtest.zsh -- Performs setup for numerical regression test

USAGE:
    before-nrtest.zsh [OPTIONS] [RELEASE_TAG]

DESCRIPTION:
    Stages files for numerical regression testing by downloading test suites
    and benchmarks from GitHub. This script prepares the test environment
    before running numerical regression tests.

OPTIONS:
    -h, --help      Show this help message and exit

ARGUMENTS:
    RELEASE_TAG     Optional release tag to specify which version of tests
                    and benchmarks to use. If not provided, uses the latest
                    tagged release from the repository.

REQUIRED ENVIRONMENT VARIABLES:
    PROJECT         Name of the project (e.g., 'swmm', 'epanet')
    BUILD_HOME      Relative path to build directory
    PLATFORM        Target platform identifier

OPTIONAL ENVIRONMENT VARIABLES:
    NRTESTS_URL     URL to GitHub repository containing test suite
                    (default: https://github.com/USEPA/\${PROJECT}-nrtestsuite)

DEPENDENCIES:
    - curl (for downloading files)
    - tar (for extracting archives)

EXAMPLES:
    # Use latest release
    $(basename "$0")

    # Use specific release tag
    $(basename "$0") v1.2.0

    # Show help
    $(basename "$0") --help
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            return 0
            ;;
        -*)
            echo "ERROR: Unknown option: $1"
            echo "Use -h or --help for usage information"
            return 1
            ;;
        *)
            # This is the RELEASE_TAG argument
            RELEASE_TAG_ARG="$1"
            break
            ;;
    esac
    shift
done

echo INFO: Staging files for regression testing

# check that env variables are set
REQUIRED_VARS=(PROJECT BUILD_HOME PLATFORM)
for i in ${REQUIRED_VARS}; do
    [[ ! -v ${i} ]] && { echo "ERROR: $i must be defined"; cd ${CUR_DIR}; return 1; }
done
echo "CHECK: all required variables are set"

# determine project directory
CUR_DIR=${PWD}
SCRIPT_HOME=${0:a:h}
cd ${SCRIPT_HOME}
cd ./../../
PROJECT_DIR=${PWD}


# create a clean directory for staging regression tests
if [ -d ${TEST_HOME} ]; then
  rm -rf ${TEST_HOME}
fi

mkdir ${TEST_HOME}
cd ${TEST_HOME}
mkdir benchmark

# set and check URL to github repo with nrtest files
if [ -z $NRTESTS_URL ]; then
    NRTESTS_URL="https://github.com/USEPA/${PROJECT}-nrtestsuite"
fi

curl -Ifs -o /dev/null ${NRTESTS_URL}
if [ $? -ne 0 ]; then
    echo "ERROR: NRTESTS_URL = ${NRTESTS_URL} does not exist"; cd ${CUR_DIR}; return 1
fi


# if no release tag arg determine latest else use passed argument
if [ -z "$RELEASE_TAG_ARG" ]; then
    echo INFO: Checking latest nrtestsuite release tag ...
    RELEASE_TAG=$( basename $( curl -Ls -o /dev/null -w %{url_effective} "${NRTESTS_URL}/releases/latest" ) )
else
    RELEASE_TAG=$RELEASE_TAG_ARG
fi

# perform release tag check
if [ -v RELEASE_TAG ]; then
    echo CHECK: using RELEASE_TAG = ${RELEASE_TAG}
else
    echo "ERROR: tag RELEASE_TAG is invalid"; cd ${CUR_DIR}; return 1
fi


# build URLs for test and benchmark files
TESTFILES_URL="${NRTESTS_URL}/archive/${RELEASE_TAG}.tar.gz"
BENCHFILES_URL="${NRTESTS_URL}/releases/download/${RELEASE_TAG}/benchmark-${PLATFORM}.tar.gz"

# retrieve tests for regression testing
echo CHECK: using TESTFILES_URL = ${TESTFILES_URL}
curl -fsSL -o nrtestfiles.tar.gz ${TESTFILES_URL}

# retrieve swmm benchmark results
echo CHECK: using BENCHFILES_URL = ${BENCHFILES_URL}
curl -fsSL -o benchmark.tar.gz ${BENCHFILES_URL}


# extract tests and benchmarks
if [ -f nrtestfiles.tar.gz ]; then
    tar xzf nrtestfiles.tar.gz
else
    echo "ERROR: file nrtestfiles.tar.gz does not exist"; cd ${CUR_DIR}; return 1
fi

# create benchmark dir and extract benchmarks
# benchmark may not exist yet -- like when running first time
if [ -f benchmark.tar.gz ]; then
    tar xzf benchmark.tar.gz -C benchmark
else
    echo "WARNING: file benchmark.tar.gz does not exist"
fi


# set up link to tests
ln -s ${PROJECT}-nrtestsuite-${RELEASE_TAG:1}/public tests


# determine REF_BUILD_ID from manifest
MANIFEST_FILE=$( find . -name manifest.json )
if [ -v MANIFEST_FILE ]; then
    while read line; do
        if [[ $line == *"${PLATFORM} "* ]]; then
            tokens=(${(s: :)line})
            REF_BUILD_ID=$tokens[3]
        fi
    done < $MANIFEST_FILE
else
    echo "WARNING: file manifest.json does not exist"
fi

if [ -z "${REF_BUILD_ID}" ]; then
    echo "WARNING: REF_BUILD_ID could not be determined"
else
    echo "CHECK: using REF_BUILD_ID = $REF_BUILD_ID"
fi

export REF_BUILD_ID=$REF_BUILD_ID

# GitHub Actions
echo "REF_BUILD_ID=$REF_BUILD_ID" >> $GITHUB_ENV


# clean up
unset RELEASE_TAG

# return user to current dir
cd ${CUR_DIR}

return 0
