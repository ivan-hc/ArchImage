#!/bin/sh

# DOWNLOAD AND INSTALL JUNEST
git clone https://github.com/fsquillace/junest.git ~/.local/share/junest
./.local/share/junest/bin/junest setup

# CUSTOM MIRRORLIST
rm -R ./.junest/etc/pacman.d/mirrorlist
COUNTRY=$(echo $LANG | cut -c -2 | tr a-z A-Z)
wget -q https://archlinux.org/mirrorlist/?country="$(echo $COUNTRY)" -O - | sed 's/#Server/Server/g' >> ./.junest/etc/pacman.d/mirrorlist

# INSTALL OBS AND PYTHON
./.local/share/junest/bin/junest -- sudo pacman -Syy
./.local/share/junest/bin/junest -- sudo pacman --noconfirm -S obs-studio python3

# VERSION NAME
VERSION=$(./.local/share/junest/bin/junest -- obs --version | cut -c 14-)

# CREATE THE APPDIR
wget -q https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage -O appimagetool
chmod a+x appimagetool
mkdir obs-studio.AppDir
cp -r ./.local ./obs-studio.AppDir/
cp -r ./.junest ./obs-studio.AppDir/
cp ./obs-studio.AppDir/.junest/usr/share/icons/hicolor/scalable/apps/*obs* ./obs-studio.AppDir/
cp ./obs-studio.AppDir/.junest/usr/share/applications/*obs* ./obs-studio.AppDir/
cat >> ./obs-studio.AppDir/AppRun << 'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f $0)")"
export UNION_PRELOAD=$HERE
export JUNEST_HOME=$HERE/.junest
export PATH=$HERE/.local/share/junest/bin/:$PATH
echo "obs $@" | $HERE/.local/share/junest/bin/junest -n
EOF
chmod a+x ./obs-studio.AppDir/AppRun

# REMOVE SOME BLOATWARES
rm -R -f ./obs-studio.AppDir/.junest/var

# REMOVE THE INBUILT HOME AND SYMLINK THE ONE FROM THE HOST (EXPERIMENTAL, NEEDED FOR PORTABILITY)
#rm -R -f ./obs-studio.AppDir/.junest/home
#ln -s /home ./obs-studio.AppDir/.junest/home

# CREATE THE APPIMAGE
ARCH=x86_64 ./appimagetool -n ./obs-studio.AppDir
mv ./*AppImage ./OBS-Studio_$VERSION-x86_64.AppImage
