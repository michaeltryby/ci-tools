#!/usr/bin/env zsh

#
#  run-nrtests.zsh - Runs numerical regression test
#
#  Date Created: 04/01/2020
#       Updated: 06/08/2025
#
#  Author:       See AUTHORS
#


# Cleanup function for consistent error handling
cleanup_and_exit() {
    local exit_code=${1:-1}

    # Return to original directory if it was set
    if [ -n "${CUR_DIR}" ]; then
        cd "${CUR_DIR}"
    fi

    return $exit_code
}

# Function to display usage information
usage() {
    cat << EOF
run-nrtests.zsh -- Runs numerical regression tests

USAGE:
    run-nrtests.zsh [OPTIONS] [SUT_BUILD_ID]

DESCRIPTION:
    Executes numerical regression tests using nrtest and compares results
    against reference benchmarks. Creates test artifacts and performs
    comparison analysis.

OPTIONS:
    -h, --help      Show this help message and exit

ARGUMENTS:
    SUT_BUILD_ID    Optional build identifier for the system under test.
                    If not provided, generates a random identifier.

REQUIRED ENVIRONMENT VARIABLES:
    PROJECT         Name of the project (e.g., 'swmm', 'epanet')
    BUILD_HOME      Relative path to build directory
    TEST_HOME       Relative path to test directory
    PLATFORM        Target platform identifier
    REF_BUILD_ID    Reference build identifier for comparison

DEPENDENCIES:
    - python with nrtest package installed
    - pip install -r requirements.txt

EXAMPLES:
    # Run tests with random build ID
    $(basename "$0")

    # Run tests with specific build ID
    $(basename "$0") my-build-123

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
            cleanup_and_exit 1
            ;;
        *)
            # This is the SUT_BUILD_ID argument
            SUT_BUILD_ID_ARG="$1"
            break
            ;;
    esac
    shift
done

# check that env variables are set
REQUIRED_VARS=(PROJECT BUILD_HOME TEST_HOME PLATFORM REF_BUILD_ID)
for i in ${REQUIRED_VARS}; do
    [[ ! -v ${i} ]] && { echo "ERROR: ${i} must be defined"; cleanup_and_exit 1; }
done


# determine project root directory
CUR_DIR=${PWD}
SCRIPT_HOME=${0:a:h}
cd ${SCRIPT_HOME}/../../
PROJ_DIR=${PWD}


# change current directory to test suite
cd ${TEST_HOME}


# use passed argument or generate a "unique" identifier
if [ ! -z "$SUT_BUILD_ID_ARG" ]; then
    SUT_BUILD_ID=$SUT_BUILD_ID_ARG
else
    SUT_BUILD_ID=$RANDOM
fi

# check if app config file exists
if [ ! -a "./apps/${PROJECT}-${SUT_BUILD_ID}.json" ]; then
    mkdir -p "apps"
    ${SCRIPT_HOME}/app-config.zsh "${PROJ_DIR}/${BUILD_HOME}/bin/Release" \
    ${PLATFORM} ${SUT_BUILD_ID} > "./apps/${PROJECT}-${SUT_BUILD_ID}.json"
fi

# build list of directories contaiing tests
TESTS=$( find ./tests -mindepth 1 -type d -follow | paste -sd " " - )

# build nrtest execute command
NRTEST_EXECUTE_CMD='nrtest execute'
TEST_APP_PATH="./apps/${PROJECT}-${SUT_BUILD_ID}.json"
TEST_OUTPUT_PATH="./benchmark/${PROJECT}-${SUT_BUILD_ID}"

# build nrtest compare command
NRTEST_COMPARE_CMD='nrtest compare'
REF_OUTPUT_PATH="benchmark/${PROJECT}-${REF_BUILD_ID}"
RTOL_VALUE='0.01'
ATOL_VALUE='1.E-6'


# if present clean test benchmark results
if [ -d "${TEST_OUTPUT_PATH}" ]; then
    rm -rf "${TEST_OUTPUT_PATH}"
fi

# perform nrtest execute
echo "INFO: Creating SUT ${SUT_BUILD_ID} artifacts"
NRTEST_COMMAND="${NRTEST_EXECUTE_CMD} ${TEST_APP_PATH} ${TESTS} -o ${TEST_OUTPUT_PATH}"
echo $NRTEST_COMMAND
eval ${NRTEST_COMMAND}
RESULT=$?

if [ "$RESULT" -ne 0 ]; then
    echo "WARNING: nrtest execute exited with errors"
fi

# perform nrtest compare
if [ -z "${REF_BUILD_ID}" ]; then
    echo "WARNING: no ref benchmark found comparison not performed"
    RESULT=1
else
    echo "INFO: Comparing SUT artifacts to REF ${REF_BUILD_ID}"
    NRTEST_COMMAND="${NRTEST_COMPARE_CMD} ${TEST_OUTPUT_PATH} ${REF_OUTPUT_PATH} --rtol ${RTOL_VALUE} --atol ${ATOL_VALUE}"
    eval ${NRTEST_COMMAND}
    RESULT=$?
fi

# Stage artifacts for upload
cd ./benchmark

if [ "$RESULT" -eq 0 ]; then
    echo "INFO: nrtest compare exited successfully"
    mv receipt.json ${PROJ_DIR}/upload/receipt.json
else
    echo "INFO: nrtest exited abnormally"
    tar -zcf benchmark-${PLATFORM}.tar.gz ./${PROJECT}-${SUT_BUILD_ID}
    mv benchmark-${PLATFORM}.tar.gz ${PROJ_DIR}/upload/benchmark-${PLATFORM}.tar.gz
fi

# Normal completion cleanup
cleanup_and_exit $RESULT
