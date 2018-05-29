#!/bin/sh
sudo apt-get update
sudo add-apt-repository --yes ppa:alexlarsson/flatpak
sudo apt-get -qq update

sudo rm /var/lib/dpkg/lock
sudo dpkg --configure -a

sudo apt-get -y install flatpak flatpak-builder

flatpak list

flatpak --user remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak --user remote-add --if-not-exists kdeapps --from https://distribute.kde.org/kdeapps.flatpakrepo

flatpak --user install flathub org.kde.Platform//5.9 org.kde.Sdk//5.9

git clone https://github.com/analogdevicesinc/scopy-flatpak
cd scopy-flatpak
make
