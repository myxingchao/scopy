#!/bin/sh

cd ${TRAVIS_BUILD_DIR}/build

cmake -DCMAKE_PREFIX_PATH=/opt/qt59/lib/cmake ..
make
make install
