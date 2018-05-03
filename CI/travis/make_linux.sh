#!/bin/sh
set -e

#OLD_PATH=$PATH
#export PATH=/usr/lib/x86_64-linux-gnu/cmake/:$PATH

cd ${TRAVIS_BUILD_DIR}/build

cmake ..
make
make install

#PATH=$OLD_PATH
