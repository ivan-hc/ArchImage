#!/bin/sh
# NAME OF THE APP, REPLACE SAMPLE OR EDIT THE PARTS INCLUDING "$APP" MANUALLY, IF NEEDED
# FOR EXAMPLE THE PACKAGE "obs-studio" CAN BE STARTED WITH THE BINARY IS "obs"
APP=gnumeric

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
./.local/share/junest/bin/junest -- sudo pacman --noconfirm -S gnumeric gzip
#./.local/share/junest/bin/junest -- yay --noconfirm -S $APP

# SET THE LOCALE (DON'T TOUCH THIS)
#sed "s/# /#>/g" ./.junest/etc/locale.gen | sed "s/#//g" | sed "s/>/#/g" >> ./locale.gen # UNCOMMENT TO ENABLE ALL THE LANGUAGES
#sed "s/#$(echo $LANG)/$(echo $LANG)/g" ./.junest/etc/locale.gen >> ./locale.gen # ENABLE ONLY YOUR LANGUAGE, COMMENT IF YOU NEED MORE THAN ONE
rm ./.junest/etc/locale.gen
#mv ./locale.gen ./.junest/etc/locale.gen
rm ./.junest/etc/locale.conf
#echo "LANG=$LANG" >> ./.junest/etc/locale.conf
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
cp ./$APP.AppDir/.junest/usr/share/applications/*$APP* ./$APP.AppDir/
cp ./$APP.AppDir/.junest/usr/share/icons/hicolor/256x256/apps/*$APP* ./$APP.AppDir/

# ...AND FINALLY CREATE THE APPRUN, IE THE MAIN SCRIPT TO RUN THE APPIMAGE!
# THE APPROACH "echo "$APP $@" | $HERE/.local/share/junest/bin/junest -n" ALLOWS YOU TO RUN THE APP IN A JUNEST SECTION DIRECTLY
# EDIT THE FOLLOWING LINES IF YOU THINK SOME ENVIRONMENT VARIABLES ARE MISSING
cat >> ./$APP.AppDir/AppRun << 'EOF'
#!/bin/sh
APP=gnumeric
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
rm -R -f ./$APP.AppDir/.junest/var

rm -R -f ./$APP.AppDir/.junest/usr/share/aclocal
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
rm -R -f ./$APP.AppDir/.junest/usr/share/fontconfig
rm -R -f ./$APP.AppDir/.junest/usr/share/GConf
rm -R -f ./$APP.AppDir/.junest/usr/share/gdb
rm -R -f ./$APP.AppDir/.junest/usr/share/gettext
rm -R -f ./$APP.AppDir/.junest/usr/share/gettext-0.22
rm -R -f ./$APP.AppDir/.junest/usr/share/ghostscript
rm -R -f ./$APP.AppDir/.junest/usr/share/gir-1.0
rm -R -f ./$APP.AppDir/.junest/usr/share/git
rm -R -f ./$APP.AppDir/.junest/usr/share/git-core
rm -R -f ./$APP.AppDir/.junest/usr/share/git-gui
rm -R -f ./$APP.AppDir/.junest/usr/share/gitk
rm -R -f ./$APP.AppDir/.junest/usr/share/gitweb
rm -R -f ./$APP.AppDir/.junest/usr/share/glvnd
rm -R -f ./$APP.AppDir/.junest/usr/share/gnupg
rm -R -f ./$APP.AppDir/.junest/usr/share/goffice
rm -R -f ./$APP.AppDir/.junest/usr/share/graphite2
rm -R -f ./$APP.AppDir/.junest/usr/share/gtk-3.0
rm -R -f ./$APP.AppDir/.junest/usr/share/gtk-doc
rm -R -f ./$APP.AppDir/.junest/usr/share/help
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
rm -R -f ./$APP.AppDir/.junest/usr/share/poppler
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
rm -R -f ./$APP.AppDir/.junest/usr/lib/dri
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
rm -R -f ./$APP.AppDir/.junest/usr/lib/gnome-settings-daemon-3.0
rm -R -f ./$APP.AppDir/.junest/usr/lib/gnupg
rm -R -f ./$APP.AppDir/.junest/usr/lib/goffice
rm -R -f ./$APP.AppDir/.junest/usr/lib/gtk-2.0
rm -R -f ./$APP.AppDir/.junest/usr/lib/gtk-3.0
rm -R -f ./$APP.AppDir/.junest/usr/lib/icu
rm -R -f ./$APP.AppDir/.junest/usr/lib/initcpio
rm -R -f ./$APP.AppDir/.junest/usr/lib/kernel
rm -R -f ./$APP.AppDir/.junest/usr/lib/krb5
rm -R -f ./$APP.AppDir/.junest/usr/lib/libfakeroot
rm -R -f ./$APP.AppDir/.junest/usr/lib/libnl
rm -R -f ./$APP.AppDir/.junest/usr/lib/libproxy
rm -R -f ./$APP.AppDir/.junest/usr/lib/libxslt-plugins
rm -R -f ./$APP.AppDir/.junest/usr/lib/locale
rm -R -f ./$APP.AppDir/.junest/usr/lib/modprobe.d
rm -R -f ./$APP.AppDir/.junest/usr/lib/modules-load.d
rm -R -f ./$APP.AppDir/.junest/usr/lib/omxloaders
rm -R -f ./$APP.AppDir/.junest/usr/lib/openjpeg-2.5
rm -R -f ./$APP.AppDir/.junest/usr/lib/ossl-modules
rm -R -f ./$APP.AppDir/.junest/usr/lib/p11-kit
rm -R -f ./$APP.AppDir/.junest/usr/lib/pam.d
rm -R -f ./$APP.AppDir/.junest/usr/lib/perl5
rm -R -f ./$APP.AppDir/.junest/usr/lib/pkcs11
rm -R -f ./$APP.AppDir/.junest/usr/lib/pkgconfig
rm -R -f ./$APP.AppDir/.junest/usr/lib/python3.11
rm -R -f ./$APP.AppDir/.junest/usr/lib/sasl2
rm -R -f ./$APP.AppDir/.junest/usr/lib/security
rm -R -f ./$APP.AppDir/.junest/usr/lib/sysctl.d
rm -R -f ./$APP.AppDir/.junest/usr/lib/systemd
rm -R -f ./$APP.AppDir/.junest/usr/lib/sysusers.d
rm -R -f ./$APP.AppDir/.junest/usr/lib/tmpfiles.d
rm -R -f ./$APP.AppDir/.junest/usr/lib/tracker3
rm -R -f ./$APP.AppDir/.junest/usr/lib/tracker-3.0
rm -R -f ./$APP.AppDir/.junest/usr/lib/udev
rm -R -f ./$APP.AppDir/.junest/usr/lib/utempter
rm -R -f ./$APP.AppDir/.junest/usr/lib/xkbcommon
rm -R -f ./$APP.AppDir/.junest/usr/lib/xtables
rm -R -f ./$APP.AppDir/.junest/usr/lib/*.a
rm -R -f ./$APP.AppDir/.junest/usr/lib/*.o

rm -R -f ./$APP.AppDir/.junest/usr/lib/at-spi2-registryd*
rm -R -f ./$APP.AppDir/.junest/usr/lib/at-spi-bus-launcher*
rm -R -f ./$APP.AppDir/.junest/usr/lib/dconf-service*
rm -R -f ./$APP.AppDir/.junest/usr/lib/e2initrd_helper*
rm -R -f ./$APP.AppDir/.junest/usr/lib/gio-launch-desktop*
rm -R -f ./$APP.AppDir/.junest/usr/lib/glib-pacrunner*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libacl.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libalpm.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libanl.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libarchive.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libargon2.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libasan.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libasm-0.189.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libasm.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libasprintf.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libassuan.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libatomic.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libattr.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libaudit.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libauparse.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libavahi-core.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libavahi-glib.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libavahi-gobject.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libavahi-libevent.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libavahi-qt5.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libavahi-ui-gtk3.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libBrokenLocale.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libcairo-script-interpreter.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libcap-ng.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libc_malloc_debug.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libcolordcompat.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libcolord.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libcom_err.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libcrypto.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libcryptsetup.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libcrypt.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libcupsimage.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libcurl.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libcurses.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libcursesw.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libdaemon.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libdb-5.3.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libdb-5.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libdb-6.2.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libdb-6.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libdb_cxx-5.3.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libdb_cxx-5.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libdb_cxx-6.2.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libdb_cxx-6.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libdb_cxx.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libdb.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libdb_stl-5.3.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libdb_stl-5.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libdb_stl-6.2.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libdb_stl-6.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libdb_stl.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libdconf.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libdebuginfod-0.189.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libdebuginfod.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libdevmapper-event.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libdevmapper.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libdl.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libdns_sd.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libdrm_amdgpu.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libdrm_intel.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libdrm_nouveau.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libdrm_radeon.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libdrm.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libdrop_ambient.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libduktaped.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libduktape.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libdw-0.189.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libdw.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libe2p.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libedit.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libEGL_mesa.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libEGL.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libelf-0.189.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libelf.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libevent-2.1.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libevent_core-2.1.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libevent_core.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libevent_extra-2.1.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libevent_extra.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libevent_openssl-2.1.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libevent_openssl.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libevent_pthreads-2.1.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libevent_pthreads.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libevent.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libexslt.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libext2fs.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libfdisk.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libform.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libformw.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libgailutil-3.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libgbm.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libgdbm_compat.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libgdbm.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libgdruntime.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libgettextlib-0.22.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libgettextlib.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libgettextpo.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libgettextsrc-0.22.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libgettextsrc.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libgfortran.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libglapi.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libGLdispatch.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libGLESv2.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libGL.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libGLX_indirect.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libGLX_mesa.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libGLX.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libgmpxx.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libgnutls-openssl.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libgnutlsxx.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libgomp.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libgo.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libgpgmepp.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libgpgme.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libgphobos.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libgssapi_krb5.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libgssrpc.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libgthread-2.0.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libharfbuzz-gobject.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libharfbuzz-subset.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libhistory.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libicui18n.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libicuio.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libicutest.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libicutu.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libijs.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libip4tc.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libip6tc.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libipq.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libitm.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libjson-c.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libk5crypto.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libkadm5clnt_mit.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libkadm5clnt.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libkadm5srv_mit.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libkadm5srv.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libkdb5.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libkdb_ldap.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libkeyutils.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libkmod.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libkrad.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libkrb5.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libkrb5support.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libksba.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/liblber.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libldap.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libLLVM-15.0.7.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libLLVM-15.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libLLVM.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/liblsan.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libLTO.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/liblzo2.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libmagic.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libmemusage.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libmenu.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libmenuw.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libminilzo.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libmnl.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libmpfr.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libmvec.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libnetfilter_conntrack.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libnfnetlink.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libnftnl.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libnghttp2.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libnl-3.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libnl-cli-3.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libnl-genl-3.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libnl-idiag-3.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libnl-nf-3.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libnl-route-3.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libnl-xfrm-3.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libnpth.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libnsl.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libnss_compat.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libnss_db.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libnss_dns.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libnss_files.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libnss_hesiod.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libnss_myhostname.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libnss_mymachines.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libnss_resolve.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libnss_systemd.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libobjc.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libomxil-bellagio.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libOpenGL.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libOSMesa.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libpamc.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libpam_misc.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libpam.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libpanel.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libpanelw.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libpangoxft-1.0.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libpcap.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libpciaccess.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libpcprofile.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libpcre2-16.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libpcre2-32.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libpcre2-posix.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libpng.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libpopt.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libproxy.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libpsl.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libpsx.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libpthread.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libquadmath.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libRemarks.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libresolv.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/librt.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libsasl2.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libseccomp.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libsecret-1.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libsensors.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libsmartcols.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libsoup-3.0.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libspreadsheet.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libssh2.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libssl.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libss.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libstemmer.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libsubid.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libthread_db.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libtic.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libtiffxx.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libtinfo.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libtirpc.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libtsan.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libtss2-esys.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libtss2-fapi.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libtss2-mu.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libtss2-policy.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libtss2-rc.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libtss2-sys.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libtss2-tcti-cmd.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libtss2-tcti-device.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libtss2-tctildr.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libtss2-tcti-libtpms.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libtss2-tcti-mssim.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libtss2-tcti-pcap.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libtss2-tcti-spi-helper.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libtss2-tcti-swtpm.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libturbojpeg.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libubsan.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libudev.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libunwind-coredump.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libunwind-generic.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libunwind-ptrace.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libunwind-setjmp.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libunwind.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libunwind-x86_64.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libutempter.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libutil.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libverto-libevent.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libverto.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libvulkan.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libwayland-server.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libX11-xcb.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libxatracker.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libxcb-composite.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libxcb-damage.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libxcb-dpms.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libxcb-dri2.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libxcb-dri3.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libxcb-glx.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libxcb-present.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libxcb-randr.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libxcb-record.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libxcb-res.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libxcb-screensaver.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libxcb-shape.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libxcb-sync.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libxcb-xf86dri.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libxcb-xfixes.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libxcb-xinerama.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libxcb-xinput.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libxcb-xkb.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libxcb-xtest.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libxcb-xvmc.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libxcb-xv.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libXft.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libxkbregistry.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libxshmfence.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libxtables.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libXtst.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libXxf86vm.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/LLVMgold.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/localepaper*
rm -R -f ./$APP.AppDir/.junest/usr/lib/os-release*
rm -R -f ./$APP.AppDir/.junest/usr/lib/p11-kit-proxy.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/preloadable_libintl.so*
rm -R -f ./$APP.AppDir/.junest/usr/lib/terminfo*
rm -R -f ./$APP.AppDir/.junest/usr/lib/tracker-xdg-portal-3*
rm -R -f ./$APP.AppDir/.junest/usr/lib/xsltConf.sh*

# REMOVE THE INBUILT HOME (optional)
rm -R -f ./$APP.AppDir/.junest/home

# ENABLE MOUNTPOINTS
mkdir -p ./$APP.AppDir/.junest/home
mkdir -p ./$APP.AppDir/.junest/media

# CREATE THE APPIMAGE
ARCH=x86_64 ./appimagetool -n ./$APP.AppDir
mv ./*AppImage ./Gnumeric_$VERSION-x86_64.AppImage
