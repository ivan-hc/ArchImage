#!/bin/sh

# NAME OF THE APP BY REPLACING "SAMPLE"
APP=vlc
BIN="$APP" #CHANGE THIS IF THE NAME OF THE BINARY IS DIFFERENT FROM "$APP" (for example, the binary of "obs-studio" is "obs")
DEPENDENCES="zvbi pipewire-jack libdvdread libbluray"

# ADD A VERSION, THIS IS NEEDED FOR THE NAME OF THE FINEL APPIMAGE, IF NOT AVAILABLE ON THE REPO, THE VALUE COME FROM AUR, AND VICE VERSA
for REPO in { "core" "extra" "community" "multilib" }; do
echo "$(wget -q https://archlinux.org/packages/$REPO/x86_64/$APP/flag/ -O - | grep $APP | grep details | head -1 | grep -o -P '(?<=/a> ).*(?= )' | grep -o '^\S*')" >> version
done
VERSION=$(cat ./version | grep -w -v "" | head -1)
VERSIONAUR=$(wget -q https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=$APP -O - | grep pkgver | head -1 | cut -c 8-)

# THIS WILL DO ALL WORK INTO THE CURRENT DIRECTORY
HOME="$(dirname "$(readlink -f $0)")" 

# DOWNLOAD AND INSTALL JUNEST (DON'T TOUCH THIS)
git clone https://github.com/fsquillace/junest.git ~/.local/share/junest
./.local/share/junest/bin/junest setup

# ENABLE MULTILIB (optional)
echo "
[multilib]
Include = /etc/pacman.d/mirrorlist" >> ./.junest/etc/pacman.conf

# CUSTOM MIRRORLIST, THIS SHOULD SPEEDUP THE INSTALLATION OF THE PACKAGES IN PACMAN (COMMENT EVERYTHING TO USE THE DEFAULT MIRROR)
COUNTRY=$(curl -i ipinfo.io | grep country | cut -c 15- | cut -c -2)
rm -R ./.junest/etc/pacman.d/mirrorlist
wget -q https://archlinux.org/mirrorlist/?country="$(echo $COUNTRY)" -O - | sed 's/#Server/Server/g' >> ./.junest/etc/pacman.d/mirrorlist

# INSTALL THE APP, BEING JUNEST STRICTLY MINIMAL, YOU NEED TO ADD ALL YOU NEED, INCLUDING BINUTILS AND GZIP
./.local/share/junest/bin/junest -- sudo pacman -Syy
./.local/share/junest/bin/junest -- sudo pacman --noconfirm -Syu
./.local/share/junest/bin/junest -- yay -Syy
./.local/share/junest/bin/junest -- yay --noconfirm -S binutils gnu-free-fonts "$APP" "$DEPENDENCES"
#./.local/share/junest/bin/junest -- sudo pacman --noconfirm -S gnu-free-fonts $APP

# REMOVE SOME UNNEEDED PACKAGES
./.local/share/junest/bin/junest -- sudo pacman --noconfirm -Scc

# SET THE LOCALE (DON'T TOUCH THIS)
#sed "s/# /#>/g" ./.junest/etc/locale.gen | sed "s/#//g" | sed "s/>/#/g" >> ./locale.gen # UNCOMMENT TO ENABLE ALL THE LANGUAGES
#sed "s/#$(echo $LANG)/$(echo $LANG)/g" ./.junest/etc/locale.gen >> ./locale.gen # ENABLE ONLY YOUR LANGUAGE, COMMENT IF YOU NEED MORE THAN ONE
#rm ./.junest/etc/locale.gen
#mv ./locale.gen ./.junest/etc/locale.gen
rm ./.junest/etc/locale.conf
#echo "LANG=$LANG" >> ./.junest/etc/locale.conf
sed -i 's/LANG=${LANG:-C}/LANG=$LANG/g' ./.junest/etc/profile.d/locale.sh
#./.local/share/junest/bin/junest -- sudo pacman --noconfirm -S glibc gzip
#./.local/share/junest/bin/junest -- sudo locale-gen

# CREATE THE APPDIR (DON'T TOUCH THIS)...
wget -q https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage -O appimagetool
chmod a+x appimagetool
mkdir $APP.AppDir
cp -r ./.local ./$APP.AppDir/
cp -r ./.junest ./$APP.AppDir/

# ...ADD THE ICON AND THE DESKTOP FILE AT THE ROOT OF THE APPDIR...
LAUNCHER=$(grep -iRl $APP ~/.junest/usr/share/applications/* | grep ".desktop" | head -1)
cp -r "$LAUNCHER" ./$APP.AppDir/
ICON=$(cat $LAUNCHER | grep "Icon=" | cut -c 6-)
cp -r ./.junest/usr/share/icons/hicolor/22x22/apps/*$ICON* ./$APP.AppDir/ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/24x24/apps/*$ICON* ./$APP.AppDir/ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/32x32/apps/*$ICON* ./$APP.AppDir/ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/48x48/apps/*$ICON* ./$APP.AppDir/ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/64x64/apps/*$ICON* ./$APP.AppDir/ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/128x128/apps/*$ICON* ./$APP.AppDir/ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/192x192/apps/*$ICON* ./$APP.AppDir/ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/256x256/apps/*$ICON* ./$APP.AppDir/ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/512x512/apps/*$ICON* ./$APP.AppDir/ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/scalable/apps/*$ICON* ./$APP.AppDir/ 2>/dev/null

# ...AND FINALLY CREATE THE APPRUN, IE THE MAIN SCRIPT TO RUN THE APPIMAGE!
# EDIT THE FOLLOWING LINES IF YOU THINK SOME ENVIRONMENT VARIABLES ARE MISSING
cat >> ./$APP.AppDir/AppRun << 'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f $0)")"
export UNION_PRELOAD=$HERE
export JUNEST_HOME=$HERE/.junest
export PATH=$HERE/.local/share/junest/bin/:$PATH
mkdir -p $HOME/.cache
$HERE/.local/share/junest/bin/junest proot -n -b "--bind=/home --bind=/home/$(echo $USER) --bind=/media --bind=/opt --bind=/usr/share --bind=/usr/lib/locale --bind=/usr/lib/dri --bind=/usr/lib/x86_64-linux-gnu/dri --bind=/etc --bind=/var --bind=/var/tmp --bind=/usr/include" 2> /dev/null -- vlc "$@"
EOF
chmod a+x ./$APP.AppDir/AppRun
sed -i "s#BINARY#$BIN#g" ./$APP.AppDir/AppRun

# REMOVE "READ-ONLY FILE SYSTEM" ERRORS
sed -i 's#${JUNEST_HOME}/usr/bin/junest_wrapper#${HOME}/.cache/junest_wrapper.old#g' ./$APP.AppDir/.local/share/junest/lib/core/wrappers.sh
sed -i 's/rm -f "${JUNEST_HOME}${bin_path}_wrappers/#rm -f "${JUNEST_HOME}${bin_path}_wrappers/g' ./$APP.AppDir/.local/share/junest/lib/core/wrappers.sh
sed -i 's/ln/#ln/g' ./$APP.AppDir/.local/share/junest/lib/core/wrappers.sh

# REMOVE SOME BLOATWARES, ADD HERE ALL THE FOLDERS THAT YOU DON'T NEED FOR THE FINAL APPIMAGE
rm -R -f ./$APP.AppDir/.junest/var/*

mkdir save
cp -r ./$APP.AppDir/.junest/usr/share/vlc ./save/
cp -r ./$APP.AppDir/.junest/usr/share/icons ./save/
cp -r ./$APP.AppDir/.junest/usr/share/locale ./save/
rm -R -f ./$APP.AppDir/.junest/usr/share/*
mv ./save/* ./$APP.AppDir/.junest/usr/share/

rm -R -f ./$APP.AppDir/.junest/usr/lib/*.a
rm -R -f ./$APP.AppDir/.junest/usr/lib/*.o
rm -R -f ./$APP.AppDir/.junest/usr/lib/audit
rm -R -f ./$APP.AppDir/.junest/usr/lib/avahi
rm -R -f ./$APP.AppDir/.junest/usr/lib/awk
rm -R -f ./$APP.AppDir/.junest/usr/lib/bash
rm -R -f ./$APP.AppDir/.junest/usr/lib/bellagio
rm -R -f ./$APP.AppDir/.junest/usr/lib/bfd-plugins
rm -R -f ./$APP.AppDir/.junest/usr/lib/binfmt.d
rm -R -f ./$APP.AppDir/.junest/usr/lib/cairo
rm -R -f ./$APP.AppDir/.junest/usr/lib/cmake
rm -R -f ./$APP.AppDir/.junest/usr/lib/coreutils
rm -R -f ./$APP.AppDir/.junest/usr/lib/cryptsetup
rm -R -f ./$APP.AppDir/.junest/usr/lib/d3d
rm -R -f ./$APP.AppDir/.junest/usr/lib/dbus-1.0
rm -R -f ./$APP.AppDir/.junest/usr/lib/depmod.d

cp -r ./$APP.AppDir/.junest/usr/lib/dri/swrast_dri.so ./save/
rm -R -f ./$APP.AppDir/.junest/usr/lib/dri/*
mv ./save/* ./$APP.AppDir/.junest/usr/lib/dri/

rm -R -f ./$APP.AppDir/.junest/usr/lib/e2fsprogs
rm -R -f ./$APP.AppDir/.junest/usr/lib/engines-3
rm -R -f ./$APP.AppDir/.junest/usr/lib/environment.d
rm -R -f ./$APP.AppDir/.junest/usr/lib/gawk
rm -R -f ./$APP.AppDir/.junest/usr/lib/gconv
rm -R -f ./$APP.AppDir/.junest/usr/lib/gdk-pixbuf-2.0
rm -R -f ./$APP.AppDir/.junest/usr/lib/getconf
rm -R -f ./$APP.AppDir/.junest/usr/lib/gettext
rm -R -f ./$APP.AppDir/.junest/usr/lib/gio
rm -R -f ./$APP.AppDir/.junest/usr/lib/girepository-1.0
rm -R -f ./$APP.AppDir/.junest/usr/lib/git-core
rm -R -f ./$APP.AppDir/.junest/usr/lib/glib-2.0
rm -R -f ./$APP.AppDir/.junest/usr/lib/gnupg
rm -R -f ./$APP.AppDir/.junest/usr/lib/gprofng
rm -R -f ./$APP.AppDir/.junest/usr/lib/icu
rm -R -f ./$APP.AppDir/.junest/usr/lib/initcpio
rm -R -f ./$APP.AppDir/.junest/usr/lib/kernel
rm -R -f ./$APP.AppDir/.junest/usr/lib/krb5
rm -R -f ./$APP.AppDir/.junest/usr/lib/ldscripts
rm -R -f ./$APP.AppDir/.junest/usr/lib/libfakeroot
rm -R -f ./$APP.AppDir/.junest/usr/lib/libinput
rm -R -f ./$APP.AppDir/.junest/usr/lib/libnl
rm -R -f ./$APP.AppDir/.junest/usr/lib/libproxy
rm -R -f ./$APP.AppDir/.junest/usr/lib/libv4l
rm -R -f ./$APP.AppDir/.junest/usr/lib/metatypes
rm -R -f ./$APP.AppDir/.junest/usr/lib/modprobe.d
rm -R -f ./$APP.AppDir/.junest/usr/lib/modules-load.d
rm -R -f ./$APP.AppDir/.junest/usr/lib/mpg123
rm -R -f ./$APP.AppDir/.junest/usr/lib/omxloaders
rm -R -f ./$APP.AppDir/.junest/usr/lib/openjpeg-2.5
rm -R -f ./$APP.AppDir/.junest/usr/lib/ossl-modules
rm -R -f ./$APP.AppDir/.junest/usr/lib/p11-kit
rm -R -f ./$APP.AppDir/.junest/usr/lib/pam.d
rm -R -f ./$APP.AppDir/.junest/usr/lib/perl5
rm -R -f ./$APP.AppDir/.junest/usr/lib/pkcs11
#rm -R -f ./$APP.AppDir/.junest/usr/lib/pkgconfig
rm -R -f ./$APP.AppDir/.junest/usr/lib/python3.11
rm -R -f ./$APP.AppDir/.junest/usr/lib/sasl2
rm -R -f ./$APP.AppDir/.junest/usr/lib/security
rm -R -f ./$APP.AppDir/.junest/usr/lib/sysctl.d
rm -R -f ./$APP.AppDir/.junest/usr/lib/systemd
rm -R -f ./$APP.AppDir/.junest/usr/lib/sysusers.d
rm -R -f ./$APP.AppDir/.junest/usr/lib/tmpfiles.d
rm -R -f ./$APP.AppDir/.junest/usr/lib/ts
rm -R -f ./$APP.AppDir/.junest/usr/lib/udev
rm -R -f ./$APP.AppDir/.junest/usr/lib/utempter
rm -R -f ./$APP.AppDir/.junest/usr/lib/vdpau
rm -R -f ./$APP.AppDir/.junest/usr/lib/xkbcommon
rm -R -f ./$APP.AppDir/.junest/usr/lib/xtables

rm -R -f ./$APP.AppDir/.junest/usr/lib/libasan.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libgfortran.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libgo.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libgphobos.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libLLVM*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libOSMesa.so*

rm -R -f ./$APP.AppDir/.junest/usr/include/*

# REMOVE THE INBUILT HOME
rm -R -f ./$APP.AppDir/.junest/home

# ENABLE MOUNTPOINTS
mkdir -p ./$APP.AppDir/.junest/home
mkdir -p ./$APP.AppDir/.junest/media

# CREATE THE APPIMAGE
ARCH=x86_64 ./appimagetool -n ./$APP.AppDir
mv ./*AppImage ./"$(cat ./$APP.AppDir/*.desktop | grep 'Name=' | head -1 | cut -c 6- | sed 's/ /-/g')"_"$VERSION""$VERSIONAUR"-x86_64.AppImage
