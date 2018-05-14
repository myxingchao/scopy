#!/bin/sh

TRAVIS_BUILD=false
if [ "$#" -eq 2 ]
then
	TRAVIS_BUILD_DIR=$1
	INSTALLED_DEPS=$2
else
	INSTALLED_DEPS=/usr/local/scopy
	TRAVIS_BUILD=true
fi

sudo cp -R /opt/qt59/* /usr/local/scopy
mkdir -p ${TRAVIS_BUILD_DIR}/build
cd ${TRAVIS_BUILD_DIR}/build

rm -rf ${TRAVIS_BUILD_DIR}/debian/scopy
cd ${TRAVIS_BUILD_DIR}/build
cmake -DENABLE_STATIC_LINKING=ON -DCMAKE_FIND_LIBRARY_SUFFIXES=".a" -DCMAKE_PREFIX_PATH="/usr/local/scopy/lib/cmake;$INSTALLED_DEPS" ..
make

mkdir -p ${TRAVIS_BUILD_DIR}/../libs ${TRAVIS_BUILD_DIR}/../bin ${TRAVIS_BUILD_DIR}/../plugins/platforms ${TRAVIS_BUILD_DIR}/../plugins/xcbglintegrations ${TRAVIS_BUILD_DIR}/../plugins/imageformats
mkdir -p ${TRAVIS_BUILD_DIR}/../plugins/iconengines
rm ${TRAVIS_BUILD_DIR}/debian/source/include-binaries
rm ${TRAVIS_BUILD_DIR}/debian/scopy.install

sudo cp -R /usr/local/scopy/plugins/platforms/* ${TRAVIS_BUILD_DIR}/../plugins/platforms/
sudo cp -R /usr/local/scopy/plugins/xcbglintegrations/* ${TRAVIS_BUILD_DIR}/../plugins/xcbglintegrations/
sudo cp -R /usr/local/scopy/plugins/imageformats/* ${TRAVIS_BUILD_DIR}/../plugins/imageformats/
sudo cp -R /usr/local/scopy/plugins/iconengines/* ${TRAVIS_BUILD_DIR}/../plugins/iconengines/

echo "[Paths]" > ${TRAVIS_BUILD_DIR}/../qt.conf
echo "Prefix = ../lib" >> ${TRAVIS_BUILD_DIR}/../qt.conf
echo "Plugins = ../plugins" >> ${TRAVIS_BUILD_DIR}/../qt.conf

#sudo cp /usr/local/scopy/lib/libQt5XcbQpa.so.5 ${TRAVIS_BUILD_DIR}/../libs/
#sudo cp /usr/local/scopy/lib/libQt5DBus.so.5 ${TRAVIS_BUILD_DIR}/../libs/
#echo "debian/scopy/usr/local/scopy/lib/libQt5XcbQpa.so.5 usr/local/scopy/lib/"  >> ${TRAVIS_BUILD_DIR}/debian/scopy.install;
#echo "debian/scopy/usr/local/scopy/lib/libQt5XcbQpa.so.5"  >> ${TRAVIS_BUILD_DIR}/debian/source/include-binaries;
#echo "debian/scopy/usr/local/scopy/lib/libQt5DBus.so.5 usr/local/scopy/lib/"  >> ${TRAVIS_BUILD_DIR}/debian/scopy.install;
#echo "debian/scopy/usr/local/scopy/lib/libQt5DBus.so.5"  >> ${TRAVIS_BUILD_DIR}/debian/source/include-binaries;

libs="$(ldd ${TRAVIS_BUILD_DIR}/build/scopy | grep libicu | cut -d " " -f 3)"
echo "$libs" | while read -r lib_path; do
	echo $lib_path;
	sudo cp $lib_path ${TRAVIS_BUILD_DIR}/../libs/

	lib_name="$(echo $lib_path | rev | cut -d "/" -f 1 | rev)"
	echo "debian/scopy/usr/local/scopy/lib/$lib_name usr/local/scopy/lib/"  >> ${TRAVIS_BUILD_DIR}/debian/scopy.install;
	echo "debian/scopy/usr/local/scopy/lib/$lib_name"  >> ${TRAVIS_BUILD_DIR}/debian/source/include-binaries;
done

sudo cp -R /usr/local/scopy/lib/*.so* ${TRAVIS_BUILD_DIR}/../libs/
for ent in /usr/local/scopy/lib/*.so*
do 
	if [ -f $ent ]; then
		lib_name="$(echo $ent | rev | cut -d "/" -f 1 | rev)"
		echo "lib name " $lib_name "\n"
		echo "debian/scopy/usr/local/scopy/lib/$lib_name usr/local/scopy/lib/"  >> ${TRAVIS_BUILD_DIR}/debian/scopy.install;
		echo "debian/scopy/usr/local/scopy/lib/$lib_name"  >> ${TRAVIS_BUILD_DIR}/debian/source/include-binaries;
	fi;
done

echo "debian/53-adi-m2k-usb.rules lib/udev/rules.d/53-adi-m2k-usb.rules" >> ${TRAVIS_BUILD_DIR}/debian/scopy.install
echo "debian/scopy/usr/local/scopy/bin/decoders usr/local/scopy/bin/decoders" >> ${TRAVIS_BUILD_DIR}/debian/scopy.install
echo "debian/scopy/usr/local/scopy/bin/qt.conf usr/local/scopy/bin/qt.conf" >> ${TRAVIS_BUILD_DIR}/debian/scopy.install
echo "resources/*" >> ${TRAVIS_BUILD_DIR}/debian/source/include-binaries;
echo "plugins/*" >> ${TRAVIS_BUILD_DIR}/debian/source/include-binaries;
sudo chmod -R 755 ${TRAVIS_BUILD_DIR}/../libs/*
sudo chmod -R 755 ${TRAVIS_BUILD_DIR}/../plugins/*
cp ${TRAVIS_BUILD_DIR}/build/scopy ${TRAVIS_BUILD_DIR}/../bin
cp -R ${TRAVIS_BUILD_DIR}/build ${TRAVIS_BUILD_DIR}/../build
rm -rf ${TRAVIS_BUILD_DIR}/build

cd ${TRAVIS_BUILD_DIR}/..
sudo apt-get install -y devscripts debhelper
rm scopy_1.0.orig.tar.gz
mkdir -p ${TRAVIS_BUILD_DIR}/debian/scopy/usr/local/scopy/bin
mkdir -p ${TRAVIS_BUILD_DIR}/debian/scopy/usr/local/scopy/lib
tar -zcf scopy_1.0.orig.tar.gz scopy
sudo rm -rf /usr/local/scopy
cd ${TRAVIS_BUILD_DIR}
debuild -us -uc

curl --upload-file ${TRAVIS_BUILD_DIR}/../scopy_*.deb https://transfer.sh/scopy_1.0.deb
curl --upload-file ${TRAVIS_BUILD_DIR}/../scopy_1.0.orig.tar.gz https://transfer.sh/scopy_1.0.orig.tar.gz
