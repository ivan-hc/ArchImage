#!/bin/sh
# NAME OF THE APP, REPLACE SAMPLE OR EDIT THE PARTS INCLUDING "$APP" MANUALLY, IF NEEDED
# FOR EXAMPLE THE PACKAGE "obs-studio" CAN BE STARTED WITH THE BINARY IS "obs"
APP=abiword

# THIS WILL DO ALL WORK INTO THE CURRENT DIRECTORY
HOME="$(dirname "$(readlink -f $0)")" 

# DOWNLOAD AND INSTALL JUNEST (DON'T TOUCH THIS)
git clone https://github.com/fsquillace/junest.git ~/.local/share/junest
./.local/share/junest/bin/junest setup

# ENABLE MULTILIB (optional)
#echo "
#[multilib]
#Include = /etc/pacman.d/mirrorlist" >> ./.junest/etc/pacman.conf

# CUSTOM MIRRORLIST, THIS SHOULD SPEEDUP THE INSTALLATION OF THE PACKAGES IN PACMAN (COMMENT EVERYTHING TO USE THE DEFAULT MIRROR)
rm -R ./.junest/etc/pacman.d/mirrorlist
COUNTRY=$(curl -i ipinfo.io | grep country | cut -c 15- | cut -c -2)
wget -q https://archlinux.org/mirrorlist/?country="$(echo $COUNTRY)" -O - | sed 's/#Server/Server/g' >> ./.junest/etc/pacman.d/mirrorlist

# INSTALL THE APP WITH ALL THE DEPENDENCES NEEDED, THE WAY YOU DO WITH PACMAN (YOU CAN ALSO REPLACE "$APP", SEE LINE 4)
# BEING JUNEST STRICTLY MINIMAL, YOU NEED TO ADD ALL YOU NEED, INCLUDING BINUTILS AND GZIP IF YOU NEED TO COMPILE SOMETHING FROM AUR
./.local/share/junest/bin/junest -- sudo pacman -Syy
./.local/share/junest/bin/junest -- sudo pacman --noconfirm -Syu
./.local/share/junest/bin/junest -- sudo pacman --noconfirm -S abiword
#./.local/share/junest/bin/junest -- yay --noconfirm -S $APP

# SET THE LOCALE (DON'T TOUCH THIS)
#sed "s/# /#>/g" ./.junest/etc/locale.gen | sed "s/#//g" | sed "s/>/#/g" >> ./locale.gen # UNCOMMENT TO ENABLE ALL THE LANGUAGES
#sed "s/#$(echo $LANG)/$(echo $LANG)/g" ./.junest/etc/locale.gen >> ./locale.gen # ENABLE ONLY YOUR LANGUAGE, COMMENT IF YOU NEED MORE THAN ONE
#rm ./.junest/etc/locale.gen
#mv ./locale.gen ./.junest/etc/locale.gen
rm ./.junest/etc/locale.conf
echo "LANG=$LANG" >> ./.junest/etc/locale.conf
sed -i 's/LANG=${LANG:-C}/LANG=$LANG/g' ./.junest/etc/profile.d/locale.sh
#./.local/share/junest/bin/junest -- sudo pacman --noconfirm -S glibc gzip
#./.local/share/junest/bin/junest -- sudo locale-gen

# VERSION NAME, BY DEFAULT THIS POINTS TO THE NUMBER, CHANGE 'REPO' TO 'core', 'extra'...
# OR COMMENT AND ENABLE THE NEXT LINE THAT POINTS TO A PKGBUILD ON THE AUR, IF YOUR APP IS HOSTED THERE
VERSION=$(wget -q https://archlinux.org/packages/extra/x86_64/$APP/ -O - | grep $APP | head -1 | grep -o -P '(?<='$APP' ).*(?=</)' | tr -d " (x86_64)")
#VERSION=$(wget -q https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=$APP -O - | grep pkgver | head -1 | cut -c 8-)

# CREATE THE APPDIR (DON'T TOUCH THIS)...
wget -q https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage -O appimagetool
chmod a+x appimagetool
mkdir $APP.AppDir
cp -r ./.local ./$APP.AppDir/
cp -r ./.junest ./$APP.AppDir/

# ...ADD THE ICON AND THE DESKTOP FILE AT THE ROOT OF THE APPDIR (IF PATHS AND APPS ARE DIFFERENT YOU CAN CHANGE EVERYTHING)...
cp ./$APP.AppDir/.junest/usr/share/icons/hicolor/scalable/apps/*$APP* ./$APP.AppDir/
cp ./$APP.AppDir/.junest/usr/share/applications/*$APP* ./$APP.AppDir/

# ...AND FINALLY CREATE THE APPRUN, IE THE MAIN SCRIPT TO RUN THE APPIMAGE!
# THE APPROACH "echo "$APP $@" | $HERE/.local/share/junest/bin/junest -n" ALLOWS YOU TO RUN THE APP IN A JUNEST SECTION DIRECTLY
# EDIT THE FOLLOWING LINES IF YOU THINK SOME ENVIRONMENT VARIABLES ARE MISSING
cat >> ./$APP.AppDir/AppRun << 'EOF'
#!/bin/sh
APP=abiword
HERE="$(dirname "$(readlink -f $0)")"
export UNION_PRELOAD=$HERE
export JUNEST_HOME=$HERE/.junest
export PATH=$HERE/.local/share/junest/bin/:$PATH
mkdir -p $HOME/.cache
echo "$APP $@" | $HERE/.local/share/junest/bin/junest proot -n -b "--bind=/home --bind=/home/$(echo $USER) --bind=/media --bind=/opt"
EOF
chmod a+x ./$APP.AppDir/AppRun

# REMOVE "READ-ONLY FILE SYSTEM" ERRORS
sed -i 's#${JUNEST_HOME}/usr/bin/junest_wrapper#${HOME}/.cache/junest_wrapper.old#g' ./$APP.AppDir/.local/share/junest/lib/core/wrappers.sh
sed -i 's/rm -f "${JUNEST_HOME}${bin_path}_wrappers/#rm -f "${JUNEST_HOME}${bin_path}_wrappers/g' ./$APP.AppDir/.local/share/junest/lib/core/wrappers.sh
sed -i 's/ln/#ln/g' ./$APP.AppDir/.local/share/junest/lib/core/wrappers.sh

# REMOVE SOME BLOATWARES, ADD HERE ALL THE FOLDERS THAT YOU DON'T NEED FOR THE FINAL APPIMAGE
mkdir -p ./save/lib
mv ./$APP.AppDir/.junest/usr/lib/abiword* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/gconv* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/ld-linux-x86-64* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libabiword-3* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libatk-1* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libatk-bridge-2* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libatspi* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libavahi-client* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libavahi-common* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libavahi-core* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libavahi-glib* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libavahi-gobject* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libavahi-libevent* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libavahi-qt5* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libavahi-ui-gtk3* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libblkid* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libbrotlicommon* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libbrotlicommon-static* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libbrotlidec* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libbrotlidec-static* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libbrotlienc* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libbrotlienc-static* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libbz2* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libcairo-gobject* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libcairo-script-interpreter* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libcairo* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libcap* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libcloudproviders* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libcom_err* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libcrypto* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libc* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libcupsimage* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libcups* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libcurl* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libdatrie* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libdbus-1* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libdl* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libenchant-2* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libepoxy* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libexpat* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libffi* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libfontconfig* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libfreetype* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libfribidi* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libgcc_s* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libgcrypt* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libgdk-3* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libgdk_pixbuf-2* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libgio-2* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libglib-2* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libgmodule-2* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libgmp* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libgnutls-openssl* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libgnutls* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libgnutlsxx* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libgobject-2* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libgoffice-0* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libgpg-error* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libgraphite2* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libgsf-1* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libgssapi_krb5* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libgs* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libgtk-3* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libharfbuzz* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libhogweed* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libical* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libICE* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libicudata* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libicui18n* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libicuuc* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libidn2* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libidn* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libijs-0* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libijs* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libjbig2dec* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libjpeg* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libjson-c* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libjson-glib-1* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libk5crypto* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libkeyutils* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libkrb5* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libkrb5support* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/liblasem-0* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/liblcms2* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libltdl* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/liblz4* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/liblzma* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libm* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libmount* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libmpfr* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libm* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libncursesw* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libnettle* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libnghttp2* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libopenjp2* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libp11-kit* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libpango-1* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libpangocairo-1* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libpangoft2-1* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libpaper* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libpcre16* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libpcre2-16* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libpcre2-32* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libpcre2-8* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libpcre2-posix* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libpcre32* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libpcrecpp* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libpcreposix* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libpcre* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libpixman-1* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libpng16* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libpng* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libpsl* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libraptor2* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/librasqal* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/librdf* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libreadline* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libresolv* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/librsvg-2* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libSM* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libspectre* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libsqlite3* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libssh2* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libssl* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libstdc++* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libsystemd* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libtasn1* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libthai* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libtiff* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libtracker-sparql-3* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libunistring* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libuuid* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libwayland-client* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libwayland-cursor* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libwayland-egl* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libwv-1* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libwv* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libX11* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libX11-xcb* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libXau* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libxcb-render* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libxcb-shm* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libxcb* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libXcomposite* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libXcursor* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libXdamage* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libXdmcp* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libXext* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libXfixes* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libXinerama* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libXi* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libxkbcommon* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libxml2* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libXrandr* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libXrender* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libxslt* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libXt* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libz* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/libzstd* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/list* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/localepaper* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/preloadable_libintl* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/tracker-xdg-portal-3* ./save/lib/
mv ./$APP.AppDir/.junest/usr/lib/

mkdir -p ./save/share
mv ./$APP.AppDir/.junest/usr/share/abiword* ./save/share/
mv ./$APP.AppDir/.junest/usr/share/fontconfig ./save/share/
mv ./$APP.AppDir/.junest/usr/share/fonts ./save/share/
mv ./$APP.AppDir/.junest/usr/share/glib-2.0 ./save/share/
mv ./$APP.AppDir/.junest/usr/share/icons ./save/share/
mv ./$APP.AppDir/.junest/usr/share/mime ./save/share/

rm -R -f ./$APP.AppDir/.junest/usr/lib/*
rm -R -f ./$APP.AppDir/.junest/usr/share/*
rm -R -f ./$APP.AppDir/.junest/var

mv ./save/lib/* ./$APP.AppDir/.junest/usr/lib/
mv ./save/share/* ./$APP.AppDir/.junest/usr/share/

# REMOVE THE INBUILT HOME (optional)
rm -R -f ./$APP.AppDir/.junest/home

# ENABLE MOUNTPOINTS
mkdir -p ./$APP.AppDir/.junest/home
mkdir -p ./$APP.AppDir/.junest/media

# CREATE THE APPIMAGE
ARCH=x86_64 ./appimagetool -n ./$APP.AppDir
mv ./*AppImage ./Abiword_$VERSION-x86_64.AppImage
