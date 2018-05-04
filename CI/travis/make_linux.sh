#!/bin/sh

TRAVIS_BUILD=false
if [ "$#" -eq 2 ]
then
	TRAVIS_BUILD_DIR=$1
	INSTALLED_DEPS=$2
else
	INSTALLED_DEPS=${TRAVIS_BUILD_DIR}/../static-deps/usr
	TRAVIS_BUILD=true
fi

sudo mkdir -p /opt/scopy
sudo cp -R /opt/qt59/* /opt/scopy
sudo cp /usr/local/lib/libsigrok*.so* /opt/scopy/lib
mkdir -p ${TRAVIS_BUILD_DIR}/build
cd ${TRAVIS_BUILD_DIR}/build

if [ "$TRAVIS_BUILD" = true ]
then
	sudo apt-get remove --auto-remove python3.4
fi

rm -rf ${TRAVIS_BUILD_DIR}/debian/scopy
cd ${TRAVIS_BUILD_DIR}/build
cmake -DENABLE_STATIC_LINKING=ON -DCMAKE_FIND_LIBRARY_SUFFIXES=".a" -DCMAKE_PREFIX_PATH="/opt/scopy/lib/cmake;$INSTALLED_DEPS" -DCMAKE_INSTALL_PREFIX=$INSTALLED_DEPS ..
make

mkdir -p ${TRAVIS_BUILD_DIR}/../libs
mkdir -p ${TRAVIS_BUILD_DIR}/../bin
mkdir -p ${TRAVIS_BUILD_DIR}/../plugins/platforms
mkdir -p ${TRAVIS_BUILD_DIR}/../plugins/xcbglintegrations
rm ${TRAVIS_BUILD_DIR}/debian/source/include-binaries
rm ${TRAVIS_BUILD_DIR}/debian/scopy.install

#sudo cp -R /usr/lib/python3.5/encodings ${TRAVIS_BUILD_DIR}/../libs
sudo cp -R /opt/scopy/plugins/platforms/* ${TRAVIS_BUILD_DIR}/../plugins/platforms/
sudo cp -R /opt/scopy/plugins/xcbglintegrations/* ${TRAVIS_BUILD_DIR}/../plugins/xcbglintegrations/

echo "[Paths]" > ${TRAVIS_BUILD_DIR}/../qt.conf
echo "Prefix = ../lib" >> ${TRAVIS_BUILD_DIR}/../qt.conf
echo "Plugins = ../plugins" >> ${TRAVIS_BUILD_DIR}/../qt.conf

sudo cp /opt/scopy/lib/libQt5XcbQpa.so.5 ${TRAVIS_BUILD_DIR}/../libs/
sudo cp /opt/scopy/lib/libQt5DBus.so.5 ${TRAVIS_BUILD_DIR}/../libs/
echo "debian/scopy/opt/scopy/lib/libQt5XcbQpa.so.5 opt/scopy/lib/"  >> ${TRAVIS_BUILD_DIR}/debian/scopy.install;
echo "debian/scopy/opt/scopy/lib/libQt5XcbQpa.so.5"  >> ${TRAVIS_BUILD_DIR}/debian/source/include-binaries;
echo "debian/scopy/opt/scopy/lib/libQt5DBus.so.5 opt/scopy/lib/"  >> ${TRAVIS_BUILD_DIR}/debian/scopy.install;
echo "debian/scopy/opt/scopy/lib/libQt5DBus.so.5"  >> ${TRAVIS_BUILD_DIR}/debian/source/include-binaries;

libs="$(ldd ${TRAVIS_BUILD_DIR}/build/scopy | grep Qt | cut -d " " -f 3)"
echo "$libs" | while read -r lib_path; do
	echo $lib_path;
	sudo cp $lib_path ${TRAVIS_BUILD_DIR}/../libs/

	lib_name="$(echo $lib_path | rev | cut -d "/" -f 1 | rev)"
	echo "debian/scopy/opt/scopy/lib/$lib_name opt/scopy/lib/"  >> ${TRAVIS_BUILD_DIR}/debian/scopy.install;
	echo "debian/scopy/opt/scopy/lib/$lib_name"  >> ${TRAVIS_BUILD_DIR}/debian/source/include-binaries;
done

libs="$(ldd ${TRAVIS_BUILD_DIR}/build/scopy | grep sigrok | cut -d " " -f 3)"
echo "$libs" | while read -r lib_path; do
	echo $lib_path;
	sudo cp $lib_path ${TRAVIS_BUILD_DIR}/../libs/

	lib_name="$(echo $lib_path | rev | cut -d "/" -f 1 | rev)"
	echo "debian/scopy/opt/scopy/lib/$lib_name opt/scopy/lib/"  >> ${TRAVIS_BUILD_DIR}/debian/scopy.install;
	echo "debian/scopy/opt/scopy/lib/$lib_name"  >> ${TRAVIS_BUILD_DIR}/debian/source/include-binaries;
done

libs="$(ldd ${TRAVIS_BUILD_DIR}/build/scopy | grep libicu | cut -d " " -f 3)"
echo "$libs" | while read -r lib_path; do
	echo $lib_path;
	sudo cp $lib_path ${TRAVIS_BUILD_DIR}/../libs/

	lib_name="$(echo $lib_path | rev | cut -d "/" -f 1 | rev)"
	echo "debian/scopy/opt/scopy/lib/$lib_name opt/scopy/lib/"  >> ${TRAVIS_BUILD_DIR}/debian/scopy.install;
	echo "debian/scopy/opt/scopy/lib/$lib_name"  >> ${TRAVIS_BUILD_DIR}/debian/source/include-binaries;
done

#libs="$(ldd ${TRAVIS_BUILD_DIR}/build/scopy | grep libpython | cut -d " " -f 3)"
#echo "$libs" | while read -r lib_path; do
#	echo $lib_path;
#	sudo cp $lib_path ${TRAVIS_BUILD_DIR}/../libs/
#
#	lib_name="$(echo $lib_path | rev | cut -d "/" -f 1 | rev)"
#	echo "debian/scopy/opt/scopy/lib/$lib_name opt/scopy/lib/"  >> ${TRAVIS_BUILD_DIR}/debian/scopy.install;
#	echo "debian/scopy/opt/scopy/lib/$lib_name"  >> ${TRAVIS_BUILD_DIR}/debian/source/include-binaries;
#done

echo "debian/scopy/opt/scopy/bin/decoders opt/scopy/bin/decoders" >> ${TRAVIS_BUILD_DIR}/debian/scopy.install
echo "debian/scopy/opt/scopy/bin/qt.conf opt/scopy/bin/qt.conf" >> ${TRAVIS_BUILD_DIR}/debian/scopy.install
echo "resources/*" >> ${TRAVIS_BUILD_DIR}/debian/source/include-binaries;
echo "plugins/*" >> ${TRAVIS_BUILD_DIR}/debian/source/include-binaries;
sudo chmod 755 ${TRAVIS_BUILD_DIR}/../libs/*
sudo chmod -R 755 ${TRAVIS_BUILD_DIR}/../plugins/*
cp ${TRAVIS_BUILD_DIR}/build/scopy ${TRAVIS_BUILD_DIR}/../bin
cp -R ${TRAVIS_BUILD_DIR}/build ${TRAVIS_BUILD_DIR}/../build
rm -rf ${TRAVIS_BUILD_DIR}/build
cat ${TRAVIS_BUILD_DIR}/debian/scopy.install
cat ${TRAVIS_BUILD_DIR}/debian/source/include-binaries

cd ${TRAVIS_BUILD_DIR}/..
sudo apt-get install -y devscripts debhelper
rm scopy_1.0.orig.tar.gz
mkdir -p ${TRAVIS_BUILD_DIR}/debian/scopy/opt/scopy/bin
mkdir -p ${TRAVIS_BUILD_DIR}/debian/scopy/opt/scopy/lib
tar -zcf scopy_1.0.orig.tar.gz scopy
sudo rm -rf /opt/scopy
cd ${TRAVIS_BUILD_DIR}
debuild -us -uc

curl --upload-file ${TRAVIS_BUILD_DIR}/../scopy_*.deb https://transfer.sh/scopy_1.0.deb
#dpkg-buildpackage -us -uc
