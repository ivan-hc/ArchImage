#!/bin/sh

APP=SAMPLE

# DOWNLOAD AND INSTALL JUNEST
git clone https://github.com/fsquillace/junest.git ~/.local/share/junest
./.local/share/junest/bin/junest setup

# INSTALL $APP AND PYTHON
./.local/share/junest/bin/junest -- sudo pacman -Syy
./.local/share/junest/bin/junest -- sudo pacman --noconfirm -S $APP

# VERSION NAME
VERSION=$(./.local/share/junest/bin/junest --  --version | cut -c 14-)

# CREATE THE APPDIR
wget -q https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage -O appimagetool
chmod a+x appimagetool
mkdir $APP.AppDir
cp -r ./.local ./$APP.AppDir/
cp -r ./.junest ./$APP.AppDir/
cp ./$APP.AppDir/.junest/usr/share/icons/hicolor/scalable/apps/*$APP* ./$APP.AppDir/
cp ./$APP.AppDir/.junest/usr/share/applications/*$APP* ./$APP.AppDir/
cat >> ./$APP.AppDir/AppRun << 'EOF'
#!/bin/sh
APP=SAMPLE
HERE="$(dirname "$(readlink -f $0)")"
export UNION_PRELOAD=$HERE
export JUNEST_HOME=$HERE/.junest
export PATH=$HERE/.local/share/junest/bin/:$PATH
echo "$APP $@" | $HERE/.local/share/junest/bin/junest -n
EOF
chmod a+x ./$APP.AppDir/AppRun

# REMOVE SOME BLOATWARES
rm -R -f ./$APP.AppDir/.junest/var

# REMOVE THE INBUILT HOME AND SYMLINK THE ONE FROM THE HOST (EXPERIMENTAL, NEEDED FOR PORTABILITY)
#rm -R -f ./$APP.AppDir/.junest/home
#ln -s /home ./$APP.AppDir/.junest/home

# CREATE THE APPIMAGE
ARCH=x86_64 ./appimagetool -n ./$APP.AppDir
mv ./*AppImage ./$APP-$VERSION-x86_64.AppImage
