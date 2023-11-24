#!/bin/sh

# NAME OF THE APP BY REPLACING "SAMPLE"
APP=SAMPLE
BIN="$APP" #CHANGE THIS IF THE NAME OF THE BINARY IS DIFFERENT FROM "$APP" (for example, the binary of "obs-studio" is "obs")
DEPENDENCES="" #SYNTAX: "APP1 APP2 APP3 APP4...", LEAVE BLANK IF NO OTHER DEPENDENCES ARE NEEDED
#BASICSTUFF="binutils gzip"
#COMPILERS="gcc"

# ADD A VERSION, THIS IS NEEDED FOR THE NAME OF THE FINEL APPIMAGE, IF NOT AVAILABLE ON THE REPO, THE VALUE COME FROM AUR, AND VICE VERSA
for REPO in { "core" "extra" "community" "multilib" }; do
echo "$(wget -q https://archlinux.org/packages/$REPO/x86_64/$APP/flag/ -O - | grep $APP | grep details | head -1 | grep -o -P '(?<=/a> ).*(?= )' | grep -o '^\S*')" >> version
done
VERSION=$(cat ./version | grep -w -v "" | head -1)
VERSIONAUR=$(wget -q https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=$APP -O - | grep pkgver | head -1 | cut -c 8-)

# CREATE THE APPDIR (DON'T TOUCH THIS)...
wget -q https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage -O appimagetool
chmod a+x appimagetool
mkdir $APP.AppDir

# ENTER THE APPDIR
cd $APP.AppDir

# SET APPDIR AS A TEMPORARY $HOME DIRECTORY, THIS WILL DO ALL WORK INTO THE APPDIR
HOME="$(dirname "$(readlink -f $0)")" 

# DOWNLOAD AND INSTALL JUNEST (DON'T TOUCH THIS)
git clone https://github.com/fsquillace/junest.git ~/.local/share/junest
./.local/share/junest/bin/junest setup

# ENABLE MULTILIB (optional)
echo "
[multilib]
Include = /etc/pacman.d/mirrorlist" >> ./.junest/etc/pacman.conf

# ENABLE CHAOTIC-AUR
###./.local/share/junest/bin/junest -- sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
###./.local/share/junest/bin/junest -- sudo pacman-key --lsign-key 3056513887B78AEB
###./.local/share/junest/bin/junest -- sudo pacman --noconfirm -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
###echo "
###[chaotic-aur]
###Include = /etc/pacman.d/chaotic-mirrorlist" >> ./.junest/etc/pacman.conf

# CUSTOM MIRRORLIST, THIS SHOULD SPEEDUP THE INSTALLATION OF THE PACKAGES IN PACMAN (COMMENT EVERYTHING TO USE THE DEFAULT MIRROR)
COUNTRY=$(curl -i ipinfo.io | grep country | cut -c 15- | cut -c -2)
rm -R ./.junest/etc/pacman.d/mirrorlist
wget -q https://archlinux.org/mirrorlist/?country="$(echo $COUNTRY)" -O - | sed 's/#Server/Server/g' >> ./.junest/etc/pacman.d/mirrorlist

# UPDATE ARCH LINUX IN JUNEST
./.local/share/junest/bin/junest -- sudo pacman -Syy
./.local/share/junest/bin/junest -- sudo pacman --noconfirm -Syu

# INSTALL THE PROGRAM USING YAY
./.local/share/junest/bin/junest -- yay -Syy
./.local/share/junest/bin/junest -- yay --noconfirm -S gnu-free-fonts $(echo "$BASICSTUFF $COMPILERS $DEPENDENCES $APP")

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

# ...ADD THE ICON AND THE DESKTOP FILE AT THE ROOT OF THE APPDIR...
rm -R -f ./*.desktop
LAUNCHER=$(grep -iRl $BIN ./.junest/usr/share/applications/* | grep ".desktop" | head -1)
cp -r "$LAUNCHER" ./
ICON=$(cat $LAUNCHER | grep "Icon=" | cut -c 6-)
cp -r ./.junest/usr/share/icons/hicolor/22x22/apps/*$ICON* ./ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/24x24/apps/*$ICON* ./ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/32x32/apps/*$ICON* ./ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/48x48/apps/*$ICON* ./ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/64x64/apps/*$ICON* ./ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/128x128/apps/*$ICON* ./ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/192x192/apps/*$ICON* ./ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/256x256/apps/*$ICON* ./ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/512x512/apps/*$ICON* ./ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/scalable/apps/*$ICON* ./ 2>/dev/null
cp -r ./.junest/usr/share/pixmaps/*$ICON* ./ 2>/dev/null

# TEST IF THE DESKTOP FILE AND THE ICON ARE IN THE ROOT OF THE FUTURE APPIMAGE (./*AppDir/*)
if test -f ./*.desktop; then
	echo "The .desktop file is available in $APP.AppDir/"
else 
	cat <<-HEREDOC >> "./$APP.desktop"
	[Desktop Entry]
	Version=1.0
	Type=Application
	Name=NAME
	Comment=
	Exec=BINARY
	Icon=tux
	Categories=Utility;
	Terminal=true
	StartupNotify=true
	HEREDOC
	sed -i "s#BINARY#$BIN#g" ./$APP.desktop
	sed -i "s#Name=NAME#Name=$(echo $APP | tr a-z A-Z)#g" ./$APP.desktop
	wget https://raw.githubusercontent.com/Portable-Linux-Apps/Portable-Linux-Apps.github.io/main/favicon.ico -O ./tux.png
fi

# ...AND FINALLY CREATE THE APPRUN, IE THE MAIN SCRIPT TO RUN THE APPIMAGE!
# EDIT THE FOLLOWING LINES IF YOU THINK SOME ENVIRONMENT VARIABLES ARE MISSING
rm -R -f ./AppRun
cat >> ./AppRun << 'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f $0)")"
export UNION_PRELOAD=$HERE
export JUNEST_HOME=$HERE/.junest
export PATH=$HERE/.local/share/junest/bin/:$PATH
mkdir -p $HOME/.cache
EXEC=$(grep -e '^Exec=.*' "${HERE}"/*.desktop | head -n 1 | cut -d "=" -f 2- | sed -e 's|%.||g')
$HERE/.local/share/junest/bin/junest proot -n -b "--bind=/home --bind=/home/$(echo $USER) --bind=/media --bind=/mnt --bind=/opt --bind=/usr/lib/locale --bind=/etc/fonts --bind=/usr/share/fonts --bind=/usr/share/themes" 2> /dev/null -- $EXEC "$@"
EOF
chmod a+x ./AppRun

# REMOVE "READ-ONLY FILE SYSTEM" ERRORS
sed -i 's#${JUNEST_HOME}/usr/bin/junest_wrapper#${HOME}/.cache/junest_wrapper.old#g' ./.local/share/junest/lib/core/wrappers.sh
sed -i 's/rm -f "${JUNEST_HOME}${bin_path}_wrappers/#rm -f "${JUNEST_HOME}${bin_path}_wrappers/g' ./.local/share/junest/lib/core/wrappers.sh
sed -i 's/ln/#ln/g' ./.local/share/junest/lib/core/wrappers.sh

# EXIT THE APPDIR
cd ..

# REMOVE SOME BLOATWARES
find ./$APP.AppDir/.junest/usr/share/doc/* -not -iname "*$BIN*" -a -not -name "." -delete #REMOVE ALL DOCUMENTATION NOT RELATED TO THE APP
find ./$APP.AppDir/.junest/usr/share/locale/*/*/* -not -iname "*$BIN*" -a -not -name "." -delete #REMOVE ALL ADDITIONAL LOCALE FILES
rm -R -f ./$APP.AppDir/.junest/etc/makepkg.conf
rm -R -f ./$APP.AppDir/.junest/etc/pacman.conf
rm -R -f ./$APP.AppDir/.junest/usr/include #FILES RELATED TO THE COMPILER
rm -R -f ./$APP.AppDir/.junest/usr/man #APPIMAGES ARE NOT MENT TO HAVE MAN COMMAND
rm -R -f ./$APP.AppDir/.junest/var/* #REMOVE ALL PACKAGES DOWNLOADED WITH THE PACKAGE MANAGER

# FUNCTION TO SAVE THE BINARIES IN /usr/bin THAT ARE NEEDED TO MADE JUNEST WORK, PLUS THE MAIN BINARY/BINARIES OF THE APP
# IF YOU NEED TO SAVE MORE BINARIES, LIST THEM IN THE "BINSAVED" VARIABLE. COMMENT THE LINE "_savebins" IF YOU ARE NOT SURE.
_savebins(){
	BINSAVED="SAVEBINSPLEASE"
	mkdir save
	cp -r ./$APP.AppDir/.junest/usr/bin/*$BIN* ./save/
	cp -r ./$APP.AppDir/.junest/usr/bin/bash ./save/
	cp -r ./$APP.AppDir/.junest/usr/bin/env ./save/
	cp -r ./$APP.AppDir/.junest/usr/bin/proot* ./save/
	cp -r ./$APP.AppDir/.junest/usr/bin/sh ./save/
	for arg in $BINSAVED; do
		for var in $arg; do
 			cp -r ./$APP.AppDir/.junest/usr/bin/*"$arg"* ./save/
		done
	done
	rm -R -f ./$APP.AppDir/.junest/usr/bin/*
	mv ./save/* ./$APP.AppDir/.junest/usr/bin/
	rmdir save
}
#_savebins

# REMOVE LIBRARIES
rm -R -f ./$APP.AppDir/.junest/usr/lib32
rm -R -f ./$APP.AppDir/.junest/usr/lib/*.a
rm -R -f ./$APP.AppDir/.junest/usr/lib/bfd-plugins/liblto_plugin.so
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
rm -R -f ./$APP.AppDir/.junest/usr/lib/gcc
rm -R -f ./$APP.AppDir/.junest/usr/lib/git-*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libalpm.so
rm -R -f ./$APP.AppDir/.junest/usr/lib/libalpm.so.13
rm -R -f ./$APP.AppDir/.junest/usr/lib/libalpm.so.13.0.2
rm -R -f ./$APP.AppDir/.junest/usr/lib/libasan_preinit.o
rm -R -f ./$APP.AppDir/.junest/usr/lib/libcc1.so
rm -R -f ./$APP.AppDir/.junest/usr/lib/libcc1.so.0
rm -R -f ./$APP.AppDir/.junest/usr/lib/libcc1.so.0.0.0
rm -R -f ./$APP.AppDir/.junest/usr/lib/libgomp.spec
rm -R -f ./$APP.AppDir/.junest/usr/lib/libitm.spec
rm -R -f ./$APP.AppDir/.junest/usr/lib/liblsan_preinit.o
rm -R -f ./$APP.AppDir/.junest/usr/lib/libsanitizer.spec
rm -R -f ./$APP.AppDir/.junest/usr/lib/libstdc++.a
rm -R -f ./$APP.AppDir/.junest/usr/lib/libstdc++exp.a
rm -R -f ./$APP.AppDir/.junest/usr/lib/libstdc++fs.a
rm -R -f ./$APP.AppDir/.junest/usr/lib/libstdc++_libbacktrace.a
rm -R -f ./$APP.AppDir/.junest/usr/lib/libsupc++.a
rm -R -f ./$APP.AppDir/.junest/usr/lib/libtsan_preinit.o
rm -R -f ./$APP.AppDir/.junest/usr/lib/*.o
rm -R -f ./$APP.AppDir/.junest/usr/lib/pkgconfig/*
rm -R -f ./$APP.AppDir/.junest/usr/lib/pkgconfig/libalpm.pc
rm -R -f ./$APP.AppDir/.junest/usr/lib/systemd/system/git-daemon@.service
rm -R -f ./$APP.AppDir/.junest/usr/lib/systemd/system/git-daemon.socket
rm -R -f ./$APP.AppDir/.junest/usr/lib/sysusers.d/git.conf

# REMOVE SOME DIRECTORIES FROM /usr/share THAT MAY NOT BE USED
rm -R -f ./$APP.AppDir/.junest/usr/share/bash-completion
rm -R -f ./$APP.AppDir/.junest/usr/share/devtools
rm -R -f ./$APP.AppDir/.junest/usr/share/fonts/*
rm -R -f ./$APP.AppDir/.junest/usr/share/gcc-*
rm -R -f ./$APP.AppDir/.junest/usr/share/gdb
rm -R -f ./$APP.AppDir/.junest/usr/share/git
rm -R -f ./$APP.AppDir/.junest/usr/share/git-*
rm -R -f ./$APP.AppDir/.junest/usr/share/gitk
rm -R -f ./$APP.AppDir/.junest/usr/share/gitweb
rm -R -f ./$APP.AppDir/.junest/usr/share/makepkg
rm -R -f ./$APP.AppDir/.junest/usr/share/makepkg-template
rm -R -f ./$APP.AppDir/.junest/usr/share/pacman
rm -R -f ./$APP.AppDir/.junest/usr/share/perl5/vendor_perl/Git
rm -R -f ./$APP.AppDir/.junest/usr/share/perl5/vendor_perl/Git.pm
rm -R -f ./$APP.AppDir/.junest/usr/share/pkgconfig/libmakepkg.pc
rm -R -f ./$APP.AppDir/.junest/usr/share/themes/*
rm -R -f ./$APP.AppDir/.junest/usr/share/zsh/site-functions/_pacman

# ADDITIONAL REMOVALS

# REMOVE THE INBUILT HOME
rm -R -f ./$APP.AppDir/.junest/home

# ENABLE MOUNTPOINTS
mkdir -p ./$APP.AppDir/.junest/home
mkdir -p ./$APP.AppDir/.junest/media

# CREATE THE APPIMAGE
ARCH=x86_64 ./appimagetool -n ./$APP.AppDir
mv ./*AppImage ./"$(cat ./$APP.AppDir/*.desktop | grep 'Name=' | head -1 | cut -c 6- | sed 's/ /-/g')"_"$VERSION""$VERSIONAUR"-x86_64.AppImage
