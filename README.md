
<!---
   README.md

   Created: May 3, 2020
   Updated:

   Author: See AUTHORS
--->

# ci-tools
Tools for local and remote testing for SWMM and EPANET


### Features

  - Zero configuration local testing
  - Simplifies CI setup
  - Support for testing on Windows, Linux, and Mac platforms
  - Unique identification of Software Under Test (SUT)
  - Creation of manifest and receipt artifacts to document QA/QC activities
  - Management of tests and benchmarks in separate repository
  - Automatic generation of test artifacts to simplify benchmark maintenance
  

### Dependencies

Before the project can be built and tested the required dependencies must be installed.

**Summary of Build Dependencies: Windows**

  - Build
      - Build Tools for Visual Studio 2017
      - CMake 3.17

  - Regression Test
      - Python 3.7 64 bit
      - curl
      - git
      - 7z

Once Python is present, the following command installs the required packages for regression testing.
```
\> cd < PROJECT_ROOT >
\>pip install -r tools\requirements-< PROJECT >.txt
```


### Build

EPANET can be built with one simple command.
```
\>tools\make.cmd
```


### Regression Test

This command runs regression tests for the local build and compares them to the latest benchmark.
```
\>tools\before-nrtest.cmd
\>tools\run-nrtest.cmd
```
