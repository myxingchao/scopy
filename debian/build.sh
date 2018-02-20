#!/bin/bash

CURRENT=$(pwd)
mkdir -p ${CURRENT}/debian/scopy/opt/scopy/bin
mkdir -p ${CURRENT}/debian/scopy/opt/scopy/lib
echo "=============================================="
cp ${CURRENT}/../libs/* debian/scopy/opt/scopy/lib/
cp ${CURRENT}/../bin/scopy debian/scopy/opt/scopy/bin/
cp -R ${CURRENT}/../qt.conf debian/scopy/opt/scopy/bin/
cp -R ${CURRENT}/resources/decoders debian/scopy/opt/scopy/bin/
cp -R ${CURRENT}/../plugins debian/scopy/opt/scopy/
ls -R -la debian
ldd debian/scopy/opt/scopy/bin/scopy
ls -la debian/scopy/opt/scopy/bin/
