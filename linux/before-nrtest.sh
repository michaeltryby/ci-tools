#! /bin/bash
#
#  before-test.sh - Prepares Travis CI worker to run swmm regression tests
#
#  Date Created: 04/05/2018
#
#  Authors:      See AUTHORS
#
#  Dependencies:
#    curl
#    tar
#
#  Environment Variables:
#    PROJECT
#    BUILD_HOME - relative path
#    PLATFORM
#    NRTESTS_URL
#
#  Arguments:
#    1 - (RELEASE_TAG)  - Release tag
#
#  Note:
#    Tests and benchmark files are stored in the swmm-example-networks repo.
#    This script retreives them using a stable URL associated with a release on
#    GitHub and stages the files for nrtest to run. The script assumes that
#    before-test.sh and app-config.sh are located together in the same folder.


export TEST_HOME="nrtests"


# check that env variables are set
REQUIRED_VARS=('PROJECT' 'BUILD_HOME' 'PLATFORM')
for i in ${REQUIRED_VARS[@]}
do
    if [[ -z "${i}" ]]; then
      echo "ERROR: $i must be defined"; exit 1;
    fi
done


# determine project directory
SCRIPT_HOME="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd ${SCRIPT_HOME}
cd ./../../
PROJECT_DIR=${PWD}

# set URL to github repo with nrtest files
if [[ -z "${NRTESTS_URL}" ]]; then
  NRTESTS_URL="https://github.com/OpenWaterAnalytics/${PROJECT}-nrtestsuite"
fi


echo INFO: Staging files for regression testing


# use release tag arg else determine latest when available (need to be released for ;o)
if [[ ! -z "$1" ]]
then
    RELEASE_TAG=$1
else
    echo INFO: Checking latest nrtestsuite release tag ...
    LATEST_URL="${NRTESTS_URL}/releases/latest"
    LATEST_URL=${LATEST_URL/"github.com"/"api.github.com/repos"}
    RELEASE_TAG=$( curl --silent "${LATEST_URL}" | grep -o '"tag_name": *"[^"]*"' | grep -o '"[^"]*"$' )
    RELEASE_TAG="${RELEASE_TAG%\"}"
    RELEASE_TAG="${RELEASE_TAG#\"}"
    RELEASE_TAG=${RELEASE_TAG:1}
    echo INFO: Latest nrtestsuite release: ${RELEASE_TAG}
fi


# build URLs for test and benchmark files; need to standardize urls or change into argument
if [[ ! -z "${RELEASE_TAG}" ]]
  then
    TESTFILES_URL="${NRTESTS_URL}/archive/v${RELEASE_TAG}.tar.gz"
    BENCHFILES_URL="${NRTESTS_URL}/releases/download/v${RELEASE_TAG}/benchmark-${PLATFORM}.tar.gz"
  else
    echo "ERROR: tag %RELEASE_TAG% is invalid" ; exit 1
fi

echo INFO: Staging files for regression testing

# create a clean directory for staging regression tests
if [ -d ${TEST_HOME} ]; then
  rm -rf ${TEST_HOME}
fi

mkdir ${TEST_HOME}
cd ${TEST_HOME}


# retrieve swmm-examples for regression testing tar.gz
curl -fsSL -o nrtestfiles.tar.gz ${TESTFILES_URL}

# retrieve swmm benchmark results
curl -fsSL -o benchmark.tar.gz ${BENCHFILES_URL}

# extract tests and benchmarks
tar xzf nrtestfiles.tar.gz
ln -s ${PROJECT}-nrtestsuite-${RELEASE_TAG}/public tests

# create benchmark dir and extract benchmarks
mkdir benchmark
tar xzf benchmark.tar.gz -C benchmark

#determine ref_build_id
MANIFEST_FILE=$( find . -name manifest.json )
echo MANIFEST FILE: $MANIFEST_FILE

while read line; do
  if [[ $line == *"${PLATFORM} "* ]]; then
    REF_BUILD_ID=${line#*"${PLATFORM} "}
    REF_BUILD_ID=${REF_BUILD_ID//"\","/""}
  fi
done < $MANIFEST_FILE

if [[ -z "${REF_BUILD_ID}" ]]
  then
  echo "ERROR: REF_BUILD_ID could not be determined" ; exit 1
fi

export REF_BUILD_ID=$REF_BUILD_ID

# GitHub Actions
echo "REF_BUILD_ID=$REF_BUILD_ID" >> $GITHUB_ENV

# return user to current dir
cd ${PROJECT_DIR}
