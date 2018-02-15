#!/bin/sh

INSTALLED_DEPS=${TRAVIS_BUILD_DIR}/../static-deps/usr
cd ${TRAVIS_BUILD_DIR}/build
mkdir -p appdir/usr/bin/decoders
mkdir -p appdir/usr/lib/python3.6
mkdir -p appdir/usr/lib/python2.7

sudo apt-get remove --auto-remove python3.4
#cp /usr/lib/python3.6/* appdir/usr/lib/python3.6/
#cp /usr/lib/python2.7/* appdir/usr/lib/python2.7/
#cp ${TRAVIS_BUILD_DIR}/resources/decoders/* appdir/usr/bin/decoders/

#echo "import sys,os
#prefix = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(sys.path[0]))))
#sys.path = [ prefix+s for s in sys.path if not s.startswith(prefix) ]" > appdir/usr/lib/python3.6/sitecustomize.py

#echo "import sys,os
#prefix = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(sys.path[0]))))
#sys.path = [ prefix+s for s in sys.path if not s.startswith(prefix) ]" > appdir/usr/lib/python2.7/sitecustomize.py

export PYTHONPATH=${TRAVIS_BUILD_DIR}/build/appdir/usr/lib/python3.6

cd ${TRAVIS_BUILD_DIR}/build
cmake -DENABLE_STATIC_LINKING=ON -DCMAKE_FIND_LIBRARY_SUFFIXES=".a" -DCMAKE_PREFIX_PATH="/opt/scopy/lib/cmake;$INSTALLED_DEPS" -DCMAKE_INSTALL_PREFIX=$INSTALLED_DEPS ..

make -j4
ldd scopy

mkdir -p ${TRAVIS_BUILD_DIR}/../libs
libs="$(ldd ${TRAVIS_BUILD_DIR}/build/scopy | grep Qt | cut -d " " -f 3)"
echo "$libs" | while read -r lib_path; do
	echo $lib_path;
	sudo cp $lib_path ${TRAVIS_BUILD_DIR}/../libs/

	lib_name="$(echo $lib_path | rev | cut -d "/" -f 1 | rev)"
	echo "debian/scopy/opt/scopy/lib/$lib_name opt/scopy/lib/"  >> ${TRAVIS_BUILD_DIR}/debian/scopy.install;
done

libs="$(ldd ${TRAVIS_BUILD_DIR}/build/scopy | grep sigrok | cut -d " " -f 3)"
echo "$libs" | while read -r lib_path; do
	echo $lib_path;
	sudo cp $lib_path ${TRAVIS_BUILD_DIR}/../libs/

	lib_name="$(echo $lib_path | rev | cut -d "/" -f 1 | rev)"
	echo "debian/scopy/opt/scopy/lib/$lib_name opt/scopy/lib/"  >> ${TRAVIS_BUILD_DIR}/debian/scopy.install;
done
sudo chmod 755 ${TRAVIS_BUILD_DIR}/../libs/*

cd ${TRAVIS_BUILD_DIR}/..
tar -zcvf scopy-1.0.orig.tar.gz scopy
cd scopy
debuild -us -uc
