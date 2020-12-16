#!/usr/bin/env zsh
#
#  before-nrtest.sh - Runs before numerical regression test
#
#  Date Created: 11/15/2017
#       Updated: 08/21/2020
#
#  Author:       See AUTHORS
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
#

export TEST_HOME="nrtests"

# check that env variables are set
REQUIRED_VARS=(PROJECT BUILD_HOME PLATFORM)
for i in ${REQUIRED_VARS}; do
    [[ ! -v ${i} ]] && { echo "ERROR: $i must be defined"; return 1 }
done

# determine project directory
CUR_DIR=${PWD}
SCRIPT_HOME=${0:a:h}
cd ${SCRIPT_HOME}
cd ./../../
PROJECT_DIR=${PWD}

# set URL to github repo with nrtest files
if [[ -z "${NRTESTS_URL}" ]]
then
NRTESTS_URL="https://github.com/OpenWaterAnalytics/${PROJECT}-nrtestsuite"
fi

echo INFO: Staging files for regression testing

# use release tag arg else determine latest hard coded for now.
if [[ ! -z "$1" ]]
then
  RELEASE_TAG=$1
else
  LATEST_URL="${NRTESTS_URL}/releases/latest"
  RELEASE_TAG=$( basename $( curl -Ls -o /dev/null -w %{url_effective} ${LATEST_URL} ) )
  echo INFO: Latest nrtestsuite release: ${RELEASE_TAG}
fi


# build URLs for test and benchmark files
if [[ ! -v RELEASE_TAG ]]
then
  echo "ERROR: tag RELEASE_TAG is invalid" ; return 1
else
  TESTFILES_URL="${NRTESTS_URL}/archive/${RELEASE_TAG}.tar.gz"
  BENCHFILES_URL="${NRTESTS_URL}/releases/download/${RELEASE_TAG}/benchmark-${PLATFORM}.tar.gz"
fi

echo INFO: Staging files for regression testing

# create a clean directory for staging regression tests
if [[ -d ${TEST_HOME} ]]; then
  rm -rf ${TEST_HOME}
fi

mkdir ${TEST_HOME}
cd ${TEST_HOME}

# retrieve tests and benchmarks for regression testing
curl -fsSL -o nrtestfiles.tar.gz ${TESTFILES_URL}
# retrieve swmm benchmark results
curl -fsSL -o benchmarks.tar.gz ${BENCHFILES_URL}

# extract tests and setup symlink
tar xzf nrtestfiles.tar.gz
ln -s ${PROJECT}-nrtestsuite-${RELEASE_TAG:1}/public tests


# create benchmark dir and extract benchmarks
mkdir benchmark
tar xzf benchmarks.tar.gz -C benchmark


#determine ref_build_id
MANIFEST_FILE=$( find . -name manifest.json )

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
cd ${CUR_DIR}
