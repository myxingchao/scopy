#!/bin/bash

CURRENT=pwd
cp ${CURRENT}/../libs/* debian/scopy/opt/scopy/lib/
cp ${CURRENT}/build/scopy debian/scopy/opt/scopy/bin/
ldd debian/scopy/opt/scopy/bin/scopy
