#!/bin/sh

APP=bottles

# THIS WILL DO ALL WORK INTO THE CURRENT DIRECTORY
HOME="$(dirname "$(readlink -f $0)")" 

# DOWNLOAD AND INSTALL JUNEST
git clone https://github.com/fsquillace/junest.git ~/.local/share/junest
./.local/share/junest/bin/junest setup

# ENABLE MULTILIB
echo "
[multilib]
Include = /etc/pacman.d/mirrorlist" >> ./.junest/etc/pacman.conf

# CUSTOM MIRRORLIST, THIS SHOULD SPEEDUP THE INSTALLATION OF THE PACKAGES IN PACMAN (COMMENT EVERYTHING TO USE THE DEFAULT MIRROR)
rm -R ./.junest/etc/pacman.d/mirrorlist
COUNTRY=$(curl -i ipinfo.io | grep country | cut -c 15- | cut -c -2)
wget -q https://archlinux.org/mirrorlist/?country="$(echo $COUNTRY)" -O - | sed 's/#Server/Server/g' >> ./.junest/etc/pacman.d/mirrorlist

# INSTALL PROGRAMS
./.local/share/junest/bin/junest -- sudo pacman -Syy
./.local/share/junest/bin/junest -- sudo pacman --noconfirm -Syu
./.local/share/junest/bin/junest -- yay --noconfirm -S $APP gzip binutils procps-ng

# CHECK PGREP
if test -t ./.junest/usr/bin/pgrep; then
	wget https://archlinux.org/packages/core/x86_64/procps-ng/download/ -O procps-ng-x86_64.pkg.tar.zst
	tar fx ./*.zst
	cp -R ./usr/bin/pgrep ./.junest/usr/bin/pgrep
else
	echo "/usr/bin/pgrep exists"
fi

# SET THE LOCALE
#sed "s/# /#>/g" ./.junest/etc/locale.gen | sed "s/#//g" | sed "s/>/#/g" >> ./locale.gen # ENABLE ALL THE LANGUAGES
sed "s/#$(echo $LANG)/$(echo $LANG)/g" ./.junest/etc/locale.gen >> ./locale.gen # ENABLE ONLY ONE LANGUAGE
rm -R ./.junest/etc/locale.gen
mv ./locale.gen ./.junest/etc/locale.gen
rm ./.junest/etc/locale.conf
#echo "LANG=$LANG" >> ./.junest/etc/locale.conf
sed -i 's/LANG=${LANG:-C}/LANG=$LANG/g' ./.junest/etc/profile.d/locale.sh
./.local/share/junest/bin/junest -- sudo pacman --noconfirm -S glibc
./.local/share/junest/bin/junest -- sudo locale-gen

# VERSION NAME
VERSION=$(wget -q https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=bottles -O - | grep pkgver | head -1 | cut -c 8-)

# CREATE THE APPDIR
wget -q https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage -O appimagetool
chmod a+x appimagetool
mkdir $APP.AppDir
cp -r ./.local ./$APP.AppDir/
cp -r ./.junest ./$APP.AppDir/
cp ./$APP.AppDir/.junest/usr/share/icons/hicolor/scalable/apps/com.usebottles.bottles.svg ./$APP.AppDir/com.usebottles.bottles.svg
cp ./$APP.AppDir/.junest/usr/share/applications/com.usebottles.bottles.desktop ./$APP.AppDir/com.usebottles.bottles.desktop
cat >> ./$APP.AppDir/AppRun << 'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f $0)")"
export UNION_PRELOAD=$HERE
export JUNEST_HOME=$HERE/.junest
export PATH=$HERE/.local/share/junest/bin/:$PATH
export GTK_THEME=Adwaita:dark
echo "bottles $@" | $HERE/.local/share/junest/bin/junest proot -n
EOF
chmod a+x ./$APP.AppDir/AppRun

# REMOVE SOME BLOATWARES
rm -R -f ./$APP.AppDir/.junest/var

# REMOVE THE INBUILT HOME
rm -R -f ./$APP.AppDir/.junest/home

# CREATE THE APPIMAGE
ARCH=x86_64 ./appimagetool -n ./$APP.AppDir
mv ./*AppImage ./Bottles_$VERSION-x86_64.AppImage
