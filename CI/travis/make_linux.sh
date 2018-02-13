#!/bin/sh

INSTALLED_DEPS=${TRAVIS_BUILD_DIR}/static-deps/usr
ls /usr/local/lib
ls /usr/lib/x86_64-linux-gnu | grep avahi
echo $INSTALLED_DEPS
cd ${TRAVIS_BUILD_DIR}/build
mkdir -p appdir/usr/bin/decoders
mkdir -p appdir/usr/lib/python3.6
mkdir -p appdir/usr/lib/python2.7

sudo apt-get remove --auto-remove python3.4
cp /usr/lib/python3.6/* appdir/usr/lib/python3.6/
cp /usr/lib/python2.7/* appdir/usr/lib/python2.7/
cp ${TRAVIS_BUILD_DIR}/resources/decoders/* appdir/usr/bin/decoders/

echo "import sys,os
prefix = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(sys.path[0]))))
sys.path = [ prefix+s for s in sys.path if not s.startswith(prefix) ]" > appdir/usr/lib/python3.6/sitecustomize.py

echo "import sys,os
prefix = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(sys.path[0]))))
sys.path = [ prefix+s for s in sys.path if not s.startswith(prefix) ]" > appdir/usr/lib/python2.7/sitecustomize.py

export PYTHONPATH=${TRAVIS_BUILD_DIR}/build/appdir/usr/lib/python3.6

cd ${TRAVIS_BUILD_DIR}/build
rm -rf *
echo $INSTALLED_DEPS
echo "/opt/scopy/lib/cmake;$INSTALLED_DEPS"
cmake -DENABLE_STATIC_LINKING=ON -DCMAKE_FIND_LIBRARY_SUFFIXES=".a" -DCMAKE_PREFIX_PATH="/opt/scopy/lib/cmake;$INSTALLED_DEPS" -DCMAKE_INSTALL_PREFIX=$INSTALLED_DEPS ..

#cmake -DCMAKE_PREFIX_PATH=/opt/qt59/lib/cmake -DCMAKE_INSTALL_PREFIX=appdir/usr ..
make -j4
ldd scopy
#make -j4 install ; find appdir/
