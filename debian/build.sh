#!/bin/bash

CURRENT=$(pwd)
mkdir -p ${CURRENT}/debian/scopy/usr/local/scopy/bin
mkdir -p ${CURRENT}/debian/scopy/usr/local/scopy/lib
cp -R ${CURRENT}/../libs/*.so* debian/scopy/usr/local/scopy/lib/
cp -R ${CURRENT}/../libs/*.a* debian/scopy/usr/local/scopy/lib/
#cp ${CURRENT}/../bin/scopy debian/scopy/usr/local/scopy/bin/
cp -R ${CURRENT}/../qt.conf debian/scopy/usr/local/scopy/bin/
cp -R ${CURRENT}/resources/decoders debian/scopy/usr/local/scopy/bin/
cp -R ${CURRENT}/../plugins debian/scopy/usr/local/scopy/
