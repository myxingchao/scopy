#!/bin/sh

set -e
cd ${WORKDIR}

sudo apt-get install python-markdown python-cheetah libfftw3-dev libusb-1.0-0-dev
mkdir -p deps
cd deps
WORKDIR=$PWD

#if [[ `lsb_release -rs` == "" ]]

cd ${WORKDIR}
if [ ! -f volk-1.3.tar.gz ]; then
  wget http://libvolk.org/releases/volk-1.3.tar.gz
  tar -xzf volk-1.3.tar.gz
fi  
if [ ! -d volk-1.3 ]; then
  cd volk-1.3
  mkdir build && cd build
  cmake ..
  make
else
  cd volk-1.3/build
fi
sudo make install

cd ${WORKDIR}
if [ ! -d gnuradio ]; then
  git clone https://github.com/analogdevicesinc/gnuradio -b signal_source_phase
  cd gnuradio
  mkdir build
  cd build
else
  cd gnuradio
  git pull
  cd build
fi
cmake -DENABLE_INTERNAL_VOLK:BOOL=OFF -DENABLE_GR_FEC:BOOL=OFF -DENABLE_GR_DIGITAL:BOOL=OFF -DENABLE_GR_DTV:BOOL=OFF -DENABLE_GR_ATSC:BOOL=OFF -DENABLE_GR_AUDIO:BOOL=OFF -DENABLE_GR_CHANNELS:BOOL=OFF -DENABLE_GR_NOAA:BOOL=OFF -DENABLE_GR_PAGER:BOOL=OFF -DENABLE_GR_TRELLIS:BOOL=OFF -DENABLE_GR_VOCODER:BOOL=OFF ..
make
sudo make install >/dev/null

cd  ${WORKDIR}
if [ ! -d qwt ]; then
  git clone https://github.com/osakared/qwt.git -b qwt-6.1-multiaxes
  cd qwt
  curl https://raw.githubusercontent.com/analogdevicesinc/scopy/osx/qwt-6.1-multiaxes.patch |patch -p1 --forward
  qmake qwt.pro
  make
else
  cd qwt
fi
sudo make install

cd ${WORKDIR}
if [ ! -d qwtpolar-1.1.1 ]; then
  wget https://downloads.sourceforge.net/project/qwtpolar/qwtpolar/1.1.1/qwtpolar-1.1.1.tar.bz2
  tar xvjf qwtpolar-1.1.1.tar.bz2
  cd qwtpolar-1.1.1
  curl -o qwtpolar-qwt-6.1-compat.patch https://raw.githubusercontent.com/analogdevicesinc/scopy-flatpak/master/qwtpolar-qwt-6.1-compat.patch
  patch -p1 < qwtpolar-qwt-6.1-compat.patch

  # Disable components that we won't build
  sed -i "/^QWT_POLAR_CONFIG\\s*+=\\s*QwtPolarExamples$/s/^/#/g" qwtpolarconfig.pri
  sed -i "/^QWT_POLAR_CONFIG\\s*+=\\s*QwtPolarDesigner$/s/^/#/g" qwtpolarconfig.pri
  # Fix prefix
  sed -i "s/^\\s*QWT_POLAR_INSTALL_PREFIX.*$/QWT_POLAR_INSTALL_PREFIX=\/usr\/local/g" qwtpolarconfig.pri
  sed -i "/^QWT_POLAR_INSTALL_HEADERS/s/$/\/qwt/g" qwtpolarconfig.pri
  cat qwtpolarconfig.pri | grep QWT_POLAR_INSTALL_PREFIX
  qmake LIBS+="-L/usr/local/lib -lqwt" INCLUDEPATH+="/usr/local/include/qwt" qwtpolar.pro
  make
else
  cd qwtpolar-1.1.1
fi
sudo make install

cd ${WORKDIR}
if [ ! -d libad9361-iio ]; then
  git clone https://github.com/analogdevicesinc/libad9361-iio
  cd libad9361-iio
  mkdir build
  cd build
  cmake ..
  make
else
  cd libad9361-iio
  git pull
  cd build
fi
sudo make install

cd ${WORKDIR}
if [ ! -d gr-iio ]; then
  git clone https://github.com/analogdevicesinc/gr-iio
  cd gr-iio
  mkdir build
  cd build
  cmake ..
  make
else
  cd gr-iio
  git pull
  cd build
fi
sudo make install
