#!/bin/sh

APP=obs-studio

# THIS WILL DO ALL WORK INTO THE CURRENT DIRECTORY
HOME="$(dirname "$(readlink -f $0)")" 

# DOWNLOAD AND INSTALL JUNEST
git clone https://github.com/fsquillace/junest.git ~/.local/share/junest
./.local/share/junest/bin/junest setup

# CUSTOM MIRRORLIST, THIS SHOULD SPEEDUP THE INSTALLATION OF THE PACKAGES IN PACMAN (COMMENT EVERYTHING TO USE THE DEFAULT MIRROR)
rm -R ./.junest/etc/pacman.d/mirrorlist
COUNTRY=$(curl -i ipinfo.io | grep country | cut -c 15- | cut -c -2)
wget -q https://archlinux.org/mirrorlist/?country="$(echo $COUNTRY)" -O - | sed 's/#Server/Server/g' >> ./.junest/etc/pacman.d/mirrorlist

# INSTALL OBS AND PYTHON
./.local/share/junest/bin/junest -- sudo pacman -Syy
./.local/share/junest/bin/junest -- sudo pacman --noconfirm -Syu
./.local/share/junest/bin/junest -- sudo pacman --noconfirm -S $APP python3

# SET THE LOCALE
#sed "s/# /#>/g" ./.junest/etc/locale.gen | sed "s/#//g" | sed "s/>/#/g" >> ./locale.gen # ENABLE ALL THE LANGUAGES
sed "s/#$(echo $LANG)/$(echo $LANG)/g" ./.junest/etc/locale.gen >> ./locale.gen # ENABLE ONLY ONE LANGUAGE
rm -R ./.junest/etc/locale.gen
mv ./locale.gen ./.junest/etc/locale.gen
rm ./.junest/etc/locale.conf
#echo "LANG=$LANG" >> ./.junest/etc/locale.conf
sed -i 's/LANG=${LANG:-C}/LANG=$LANG/g' ./.junest/etc/profile.d/locale.sh
./.local/share/junest/bin/junest -- sudo pacman --noconfirm -S glibc gzip
./.local/share/junest/bin/junest -- sudo locale-gen

# VERSION NAME
VERSION=$(wget -q https://archlinux.org/packages/extra/x86_64/$APP/ -O - | grep $APP | head -1 | grep -o -P '(?<='$APP' ).*(?=</)' | tr -d " (x86_64)")

# CREATE THE APPDIR
wget -q https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage -O appimagetool
chmod a+x appimagetool
mkdir $APP.AppDir
cp -r ./.local ./$APP.AppDir/
cp -r ./.junest ./$APP.AppDir/
cp ./$APP.AppDir/.junest/usr/share/icons/hicolor/scalable/apps/*obs* ./$APP.AppDir/
cp ./$APP.AppDir/.junest/usr/share/applications/*obs* ./$APP.AppDir/
cat >> ./$APP.AppDir/AppRun << 'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f $0)")"
export UNION_PRELOAD=$HERE
export JUNEST_HOME=$HERE/.junest
export PATH=$HERE/.local/share/junest/bin/:$PATH
echo "obs $@" | $HERE/.local/share/junest/bin/junest proot -n
EOF
chmod a+x ./$APP.AppDir/AppRun

# REMOVE SOME BLOATWARES
rm -R -f ./$APP.AppDir/.junest/var

# REMOVE THE INBUILT HOME
rm -R -f ./$APP.AppDir/.junest/home

# CREATE THE APPIMAGE
ARCH=x86_64 ./appimagetool -n ./$APP.AppDir
mv ./*AppImage ./OBS-Studio_$VERSION-x86_64.AppImage
