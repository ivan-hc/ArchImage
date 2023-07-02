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
mkdir -p $HOME/.cache
echo "obs $@" | $HERE/.local/share/junest/bin/junest proot -n
EOF
chmod a+x ./$APP.AppDir/AppRun

# REMOVE "READ-ONLY FILE SYSTEM" ERRORS
sed -i 's#${JUNEST_HOME}/usr/bin/junest_wrapper#${HOME}/.cache/junest_wrapper.old#g' ./$APP.AppDir/.local/share/junest/lib/core/wrappers.sh

# REMOVE SOME BLOATWARES
rm -R -f ./$APP.AppDir/.junest/var
rm -R -f ./$APP.AppDir/.junest/usr/lib/liblsan.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libtsan.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libgfortran.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libgo.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libphobos.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libOSMesa.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libPyImath_Python*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libasan.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/d3d
rm -R -f ./$APP.AppDir/.junest/usr/lib/dri/crocus_dri.so
rm -R -f ./$APP.AppDir/.junest/usr/lib/dri/d3d12_dri.so
rm -R -f ./$APP.AppDir/.junest/usr/lib/dri/i*
rm -R -f ./$APP.AppDir/.junest/usr/lib/dri/kms_swrast_dri.so
rm -R -f ./$APP.AppDir/.junest/usr/lib/dri/r*
rm -R -f ./$APP.AppDir/.junest/usr/lib/dri/nouveau_dri.so
rm -R -f ./$APP.AppDir/.junest/usr/lib/dri/radeonsi_dri.so
rm -R -f ./$APP.AppDir/.junest/usr/lib/dri/virtio_gpu_dri.so
rm -R -f ./$APP.AppDir/.junest/usr/lib/dri/vmwgfx_dri.so
rm -R -f ./$APP.AppDir/.junest/usr/lib/dri/zink_dri.so
rm -R -f ./$APP.AppDir/.junest/usr/lib/systemd*
rm -R -f ./$APP.AppDir/.junest/usr/lib/udev
mkdir ./save
mv ./$APP.AppDir/.junest/usr/share/obs ./save/obs
mv ./$APP.AppDir/.junest/usr/share/glvnd ./save/glvnd
rm -R -f ./$APP.AppDir/.junest/usr/share/*
mv ./save/* ./$APP.AppDir/.junest/usr/share/

# REMOVE THE INBUILT HOME
rm -R -f ./$APP.AppDir/.junest/home

# CREATE THE APPIMAGE
ARCH=x86_64 ./appimagetool -n ./$APP.AppDir
mv ./*AppImage ./OBS-Studio_$VERSION-x86_64.AppImage
