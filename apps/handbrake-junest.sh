#!/bin/sh
# NAME OF THE APP, REPLACE SAMPLE OR EDIT THE PARTS INCLUDING "$APP" MANUALLY, IF NEEDED
# FOR EXAMPLE THE PACKAGE "obs-studio" CAN BE STARTED WITH THE BINARY IS "obs"
APP=handbrake

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
./.local/share/junest/bin/junest -- sudo pacman --noconfirm -S gnu-free-fonts handbrake libdvdcss ffmpeg
#./.local/share/junest/bin/junest -- yay --noconfirm -S $APP

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

# VERSION NAME, BY DEFAULT THIS POINTS TO THE NUMBER, CHANGE 'REPO' TO 'core', 'extra'...
# OR COMMENT AND ENABLE THE NEXT LINE THAT POINTS TO A PKGBUILD ON THE AUR, IF YOUR APP IS HOSTED THERE
VERSION=$(wget -q https://archlinux.org/packages/extra/x86_64/handbrake/ -O - | grep handbrake | head -1 | cut -c 35- | rev | cut -c 18- | rev)
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
HERE="$(dirname "$(readlink -f $0)")"
export UNION_PRELOAD=$HERE
export JUNEST_HOME=$HERE/.junest
export PATH=$HERE/.local/share/junest/bin/:$PATH
mkdir -p $HOME/.cache
$HERE/.local/share/junest/bin/junest proot -n -b "--bind=/home --bind=/home/$(echo $USER) --bind=/media --bind=/opt" 2> /dev/null -- ghb "$@"
EOF
chmod a+x ./$APP.AppDir/AppRun

# REMOVE "READ-ONLY FILE SYSTEM" ERRORS
sed -i 's#${JUNEST_HOME}/usr/bin/junest_wrapper#${HOME}/.cache/junest_wrapper.old#g' ./$APP.AppDir/.local/share/junest/lib/core/wrappers.sh
sed -i 's/rm -f "${JUNEST_HOME}${bin_path}_wrappers/#rm -f "${JUNEST_HOME}${bin_path}_wrappers/g' ./$APP.AppDir/.local/share/junest/lib/core/wrappers.sh
sed -i 's/ln/#ln/g' ./$APP.AppDir/.local/share/junest/lib/core/wrappers.sh

# REMOVE SOME BLOATWARES, ADD HERE ALL THE FOLDERS THAT YOU DON'T NEED FOR THE FINAL APPIMAGE
rm -R -f ./$APP.AppDir/.junest/var

rm -R -f ./$APP.AppDir/.junest/usr/share/aclocal
#rm -R -f ./$APP.AppDir/.junest/usr/share/alsa
rm -R -f ./$APP.AppDir/.junest/usr/share/applications
rm -R -f ./$APP.AppDir/.junest/usr/share/audit
rm -R -f ./$APP.AppDir/.junest/usr/share/avahi
rm -R -f ./$APP.AppDir/.junest/usr/share/awk
rm -R -f ./$APP.AppDir/.junest/usr/share/bash-completion
rm -R -f ./$APP.AppDir/.junest/usr/share/ca-certificates
rm -R -f ./$APP.AppDir/.junest/usr/share/common-lisp
rm -R -f ./$APP.AppDir/.junest/usr/share/dbus-1
rm -R -f ./$APP.AppDir/.junest/usr/share/defaults
rm -R -f ./$APP.AppDir/.junest/usr/share/doc
rm -R -f ./$APP.AppDir/.junest/usr/share/drirc.d
rm -R -f ./$APP.AppDir/.junest/usr/share/emacs
rm -R -f ./$APP.AppDir/.junest/usr/share/et
rm -R -f ./$APP.AppDir/.junest/usr/share/factory
rm -R -f ./$APP.AppDir/.junest/usr/share/file
rm -R -f ./$APP.AppDir/.junest/usr/share/fish
#rm -R -f ./$APP.AppDir/.junest/usr/share/GConf
rm -R -f ./$APP.AppDir/.junest/usr/share/gdb
rm -R -f ./$APP.AppDir/.junest/usr/share/gettext
rm -R -f ./$APP.AppDir/.junest/usr/share/gettext-0.22
rm -R -f ./$APP.AppDir/.junest/usr/share/gir-1.0
rm -R -f ./$APP.AppDir/.junest/usr/share/git
rm -R -f ./$APP.AppDir/.junest/usr/share/git-gui
rm -R -f ./$APP.AppDir/.junest/usr/share/gitk
rm -R -f ./$APP.AppDir/.junest/usr/share/gitweb
rm -R -f ./$APP.AppDir/.junest/usr/share/glvnd
rm -R -f ./$APP.AppDir/.junest/usr/share/gnupg
rm -R -f ./$APP.AppDir/.junest/usr/share/graphite2
rm -R -f ./$APP.AppDir/.junest/usr/share/gtk-3.0
rm -R -f ./$APP.AppDir/.junest/usr/share/gtk-doc
rm -R -f ./$APP.AppDir/.junest/usr/share/hwdata
rm -R -f ./$APP.AppDir/.junest/usr/share/i18n
rm -R -f ./$APP.AppDir/.junest/usr/share/iana-etc
rm -R -f ./$APP.AppDir/.junest/usr/share/icu
rm -R -f ./$APP.AppDir/.junest/usr/share/info
rm -R -f ./$APP.AppDir/.junest/usr/share/iptables
rm -R -f ./$APP.AppDir/.junest/usr/share/iso-codes
rm -R -f ./$APP.AppDir/.junest/usr/share/java
rm -R -f ./$APP.AppDir/.junest/usr/share/kbd
rm -R -f ./$APP.AppDir/.junest/usr/share/keyutils
rm -R -f ./$APP.AppDir/.junest/usr/share/libalpm
rm -R -f ./$APP.AppDir/.junest/usr/share/libdrm
rm -R -f ./$APP.AppDir/.junest/usr/share/libgpg-error
rm -R -f ./$APP.AppDir/.junest/usr/share/libthai
rm -R -f ./$APP.AppDir/.junest/usr/share/licenses
rm -R -f ./$APP.AppDir/.junest/usr/share/locale
rm -R -f ./$APP.AppDir/.junest/usr/share/makepkg
rm -R -f ./$APP.AppDir/.junest/usr/share/makepkg-template
rm -R -f ./$APP.AppDir/.junest/usr/share/man
rm -R -f ./$APP.AppDir/.junest/usr/share/metainfo
rm -R -f ./$APP.AppDir/.junest/usr/share/misc
rm -R -f ./$APP.AppDir/.junest/usr/share/p11-kit
rm -R -f ./$APP.AppDir/.junest/usr/share/pacman
rm -R -f ./$APP.AppDir/.junest/usr/share/perl5
rm -R -f ./$APP.AppDir/.junest/usr/share/pixmaps
rm -R -f ./$APP.AppDir/.junest/usr/share/pkgconfig
rm -R -f ./$APP.AppDir/.junest/usr/share/polkit-1
rm -R -f ./$APP.AppDir/.junest/usr/share/readline
rm -R -f ./$APP.AppDir/.junest/usr/share/ss
rm -R -f ./$APP.AppDir/.junest/usr/share/systemd
rm -R -f ./$APP.AppDir/.junest/usr/share/tabset
rm -R -f ./$APP.AppDir/.junest/usr/share/terminfo
rm -R -f ./$APP.AppDir/.junest/usr/share/themes
rm -R -f ./$APP.AppDir/.junest/usr/share/thumbnailers
rm -R -f ./$APP.AppDir/.junest/usr/share/tracker3
rm -R -f ./$APP.AppDir/.junest/usr/share/vala
rm -R -f ./$APP.AppDir/.junest/usr/share/wayland
rm -R -f ./$APP.AppDir/.junest/usr/share/X11
rm -R -f ./$APP.AppDir/.junest/usr/share/xcb
rm -R -f ./$APP.AppDir/.junest/usr/share/xml
rm -R -f ./$APP.AppDir/.junest/usr/share/xtables
rm -R -f ./$APP.AppDir/.junest/usr/share/zoneinfo
rm -R -f ./$APP.AppDir/.junest/usr/share/zoneinfo-leaps
rm -R -f ./$APP.AppDir/.junest/usr/share/zoneinfo-posix
rm -R -f ./$APP.AppDir/.junest/usr/share/zsh

rm -R -f ./$APP.AppDir/.junest/usr/lib
mkdir -p ./$APP.AppDir/.junest/usr/lib
cp -r ./.junest/usr/lib/*ffmpeg* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*gdk-pixbuf-2.0* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*gstreamer* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*ld-linux-x86-64.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libass.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libatk-1.0.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libatk-bridge-2.0.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libatspi.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libav* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libblkid.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libbrotlicommon.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libbrotlidec.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libbz*.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libcairo-gobject.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libcairo.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libcap.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libcloudproviders.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libc.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libdatrie.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libdbus-1.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libdrm.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libdw-0.*.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libdw.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libelf-0.*.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libelf.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libepoxy.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libexpat.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libffi.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libfontconfig.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libfreetype.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libfribidi.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libgcc_s.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libgcrypt.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libgdk-*.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libgdk_pixbuf-2.0.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libgio-2.0.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libglib-2.0.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libgmodule-2.0.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libgobject-2.0.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libgpg-error.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libgraphite2.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libgstaudio-1.0.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libgstbase-1.0.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libgstnet-1.0.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libgstpbutils-1.0.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libgstriff-1.0.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libgstrtp-1.0.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libgstrtsp-1.0.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libgstsdp-1.0.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libgsttag-1.0.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libgstvideo-1.0.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libgtk-*.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libgudev-1.0.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libharfbuzz.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libicudata.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libicuuc.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libjansson.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libjpeg.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libjson-glib-1.0.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*liblz*.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*liblzma.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*liblzo2.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libmount.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libmp3lame.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libm.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libmvec.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libncurses++.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libncurses.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libncurses++w.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libncursesw.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libncurses++w.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libncursesw.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libncurses++w.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libncursesw.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libnuma.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libogg.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libopus.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*liborc-0.*.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libpango-1.0.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libpangocairo-1.0.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libpangoft2-1.0.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libpcre*.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libpixman-1.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libpng*.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libpng.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libreadline.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*librsvg-2.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libspeex.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libsqlite*.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libstdc++.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libsystemd.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libthai.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libtheora* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libtiff.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libtracker-sparql-3.0.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libturbojpeg.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libudev.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libunwind.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libva-drm.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libva.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libvorbisenc.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libvorbis.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libvpx.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libwayland-client.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libwayland-cursor.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libwayland-egl.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libX11.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libx*.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libXau.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libxcb-render.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libxcb-shm.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libxcb.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libXcomposite.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libXcursor.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libXdamage.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libXdmcp.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libXext.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libXfixes.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libXinerama.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libXi.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libxkbcommon.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libxml2.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libXrandr.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libXrender.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libz.so* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libzstd.so* ./$APP.AppDir/.junest/usr/lib/

cp -r ./.junest/usr/lib/*libasound* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libgstapp* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libXv* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libcdda_paranoia* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libgstgl* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libgstcontroller* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libcdda_interface* ./$APP.AppDir/.junest/usr/lib/
cp -r ./.junest/usr/lib/*libdvdcss* ./$APP.AppDir/.junest/usr/lib/

# REMOVE THE INBUILT HOME (optional)
rm -R -f ./$APP.AppDir/.junest/home

# ENABLE MOUNTPOINTS
mkdir -p ./$APP.AppDir/.junest/home
mkdir -p ./$APP.AppDir/.junest/media

# CREATE THE APPIMAGE
ARCH=x86_64 ./appimagetool -n ./$APP.AppDir
mv ./*AppImage ./Handbrake_$VERSION-x86_64.AppImage
