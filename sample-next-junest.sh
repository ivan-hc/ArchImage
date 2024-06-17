#!/usr/bin/env bash

# NAME OF THE APP BY REPLACING "SAMPLE"
APP=SAMPLE
BIN="$APP" #CHANGE THIS IF THE NAME OF THE BINARY IS DIFFERENT FROM "$APP" (for example, the binary of "obs-studio" is "obs")
DEPENDENCES="" #SYNTAX: "APP1 APP2 APP3 APP4...", LEAVE BLANK IF NO OTHER DEPENDENCES ARE NEEDED
#BASICSTUFF="binutils debugedit gzip"
#COMPILERS="base-devel"

# CREATE THE APPDIR (DON'T TOUCH THIS)...
if ! test -f ./appimagetool; then
	wget -q "$(wget -q https://api.github.com/repos/probonopd/go-appimage/releases -O - | sed 's/"/ /g; s/ /\n/g' | grep -o 'https.*continuous.*tool.*86_64.*mage$')" -O appimagetool
	chmod a+x appimagetool
fi
mkdir -p "$APP".AppDir

# ENTER THE APPDIR
cd "$APP".AppDir || return

# SET APPDIR AS A TEMPORARY $HOME DIRECTORY, THIS WILL DO ALL WORK INTO THE APPDIR
HOME="$(dirname "$(readlink -f $0)")"

# DOWNLOAD AND INSTALL JUNEST (DON'T TOUCH THIS)
if ! test -d "$HOME/.local/share/junest"; then
	git clone https://github.com/fsquillace/junest.git ./.local/share/junest
	if wget --version | head -1 | grep -q ' 1.'; then
		wget -q --show-progress https://github.com/ivan-hc/junest/releases/download/continuous/junest-x86_64.tar.gz
	else
		wget https://github.com/ivan-hc/junest/releases/download/continuous/junest-x86_64.tar.gz
	fi
	./.local/share/junest/bin/junest setup -i junest-x86_64.tar.gz
	rm -f junest-x86_64.tar.gz

	# ENABLE MULTILIB (optional)
	echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" >> ./.junest/etc/pacman.conf

	# ENABLE LIBSELINUX FROM THIRD PARTY REPOSITORY
	if [[ "$DEPENDENCES" = *"libselinux"* ]]; then
		echo -e "\n[selinux]\nServer = https://github.com/archlinuxhardened/selinux/releases/download/ArchLinux-SELinux\nSigLevel = Never" >> ./.junest/etc/pacman.conf
	fi

	# ENABLE CHAOTIC-AUR
	function _enable_chaoticaur(){
		./.local/share/junest/bin/junest -- sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
		./.local/share/junest/bin/junest -- sudo pacman-key --lsign-key 3056513887B78AEB
		./.local/share/junest/bin/junest -- sudo pacman-key --populate chaotic
		./.local/share/junest/bin/junest -- sudo pacman --noconfirm -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
		echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" >> ./.junest/etc/pacman.conf
	}
	###_enable_chaoticaur

	# CUSTOM MIRRORLIST, THIS SHOULD SPEEDUP THE INSTALLATION OF THE PACKAGES IN PACMAN (COMMENT EVERYTHING TO USE THE DEFAULT MIRROR)
	function _custom_mirrorlist(){
		#COUNTRY=$(curl -i ipinfo.io | grep country | cut -c 15- | cut -c -2)
		rm -R ./.junest/etc/pacman.d/mirrorlist
		wget -q https://archlinux.org/mirrorlist/all/ -O - | awk NR==2 RS= | sed 's/#Server/Server/g' >> ./.junest/etc/pacman.d/mirrorlist # ENABLES WORLDWIDE MIRRORS
		#wget -q https://archlinux.org/mirrorlist/?country="$(echo $COUNTRY)" -O - | sed 's/#Server/Server/g' >> ./.junest/etc/pacman.d/mirrorlist # ENABLES MIRRORS OF YOUR COUNTY
	}
	_custom_mirrorlist

	# BYPASS SIGNATURE CHECK LEVEL
	sed -i 's/#SigLevel/SigLevel/g' ./.junest/etc/pacman.conf
	sed -i 's/Required DatabaseOptional/Never/g' ./.junest/etc/pacman.conf

	# UPDATE ARCH LINUX IN JUNEST
	./.local/share/junest/bin/junest -- sudo pacman -Syy
	./.local/share/junest/bin/junest -- sudo pacman --noconfirm -Syu
else
	cd ..
	echo "-------------------------------------"
	echo " RESTORATION OF BACKUPS IN PROGRESS"
	echo "-------------------------------------"
	rsync -av ./junest-backups/* ./"$APP".AppDir/.junest/ | echo -e "\n◆ Restore the content of the Arch Linux container, please wait"
	rsync -av ./stock-cache/* ./"$APP".AppDir/.cache/ | echo "◆ Restore the content of JuNest's ~/.cache directory"
	rsync -av ./stock-local/* ./"$APP".AppDir/.local/ | echo -e "◆ Restore the content of JuNest's ~/.local directory\n"
	echo -e "-----------------------------------------------------------\n"
	cd ./"$APP".AppDir || return
fi

# INSTALL THE PROGRAM USING YAY
./.local/share/junest/bin/junest -- yay -Syy
#./.local/share/junest/bin/junest -- gpg --keyserver keyserver.ubuntu.com --recv-key C01E1CAD5EA2C4F0B8E3571504C367C218ADD4FF # UNCOMMENT IF YOU USE THE AUR
if [ ! -z "$BASICSTUFF" ]; then
	./.local/share/junest/bin/junest -- yay --noconfirm -S "$BASICSTUFF"
fi
if [ ! -z "$COMPILERS" ]; then
	./.local/share/junest/bin/junest -- yay --noconfirm -S "$COMPILERS"
fi
if [ ! -z "$DEPENDENCES" ]; then
	./.local/share/junest/bin/junest -- yay --noconfirm -S "$DEPENDENCES"
fi
if [ ! -z "$APP" ]; then
	./.local/share/junest/bin/junest -- yay --noconfirm -S "$APP"
else
	echo "No app found, exiting" exit 0
fi

# DO A BACKUP OF THE CURRENT STATE OF JUNEST
cd ..
echo -e "\n-----------------------------------------------------------"
echo " BACKUP OF JUNEST FOR FURTHER APPIMAGE BUILDING ATTEMPTS"
echo "-----------------------------------------------------------"
mkdir -p ./junest-backups
mkdir -p ./stock-cache
mkdir -p ./stock-local
rsync -av --ignore-existing ./"$APP".AppDir/.junest/* ./junest-backups/ | echo -e "\n◆ Backup the content of the Arch Linux container, please wait"
rsync -av --ignore-existing ./"$APP".AppDir/.cache/* ./stock-cache/ | echo "◆ Backup the content of JuNest's ~/.cache directory"
rsync -av --ignore-existing ./"$APP".AppDir/.local/* ./stock-local/ | echo -e "◆ Backup the content of JuNest's ~/.local directory\n"
echo -e "-----------------------------------------------------------\n"
cd ./"$APP".AppDir || return

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
cp -r ./.junest/usr/share/icons/*"$ICON"* ./ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/22x22/apps/*"$ICON"* ./ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/24x24/apps/*"$ICON"* ./ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/32x32/apps/*"$ICON"* ./ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/48x48/apps/*"$ICON"* ./ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/64x64/apps/*"$ICON"* ./ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/128x128/apps/*"$ICON"* ./ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/192x192/apps/*"$ICON"* ./ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/256x256/apps/*"$ICON"* ./ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/512x512/apps/*"$ICON"* ./ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/scalable/apps/*"$ICON"* ./ 2>/dev/null
cp -r ./.junest/usr/share/pixmaps/*"$ICON"* ./ 2>/dev/null

# TEST IF THE DESKTOP FILE AND THE ICON ARE IN THE ROOT OF THE FUTURE APPIMAGE (./*AppDir/*)
if test -f ./*.desktop; then
	echo -e "◆ The .desktop file is available in $APP.AppDir/\n"
elif test -f ./.junest/usr/bin/"$BIN"; then
 	echo -e "◆ No .desktop file available for $APP, creating a new one...\n"
 	cat <<-HEREDOC >> ./"$APP".desktop
	[Desktop Entry]
	Version=1.0
	Type=Application
	Name=$(echo "$APP" | tr a-z A-Z)
	Comment=
	Exec=$BIN
	Icon=tux
	Categories=Utility;
	Terminal=true
	StartupNotify=true
	HEREDOC
	wget https://raw.githubusercontent.com/Portable-Linux-Apps/Portable-Linux-Apps.github.io/main/favicon.ico -O ./tux.png
else
	echo "No binary in path... aborting all the processes."
	exit 0
fi

# ...AND FINALLY CREATE THE APPRUN, IE THE MAIN SCRIPT TO RUN THE APPIMAGE!
# EDIT THE FOLLOWING LINES IF YOU THINK SOME ENVIRONMENT VARIABLES ARE MISSING
rm -R -f ./AppRun
cat >> ./AppRun << 'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f $0)")"
export UNION_PRELOAD=$HERE
export JUNEST_HOME=$HERE/.junest
export PATH=$PATH:$HERE/.local/share/junest/bin

if test -f /etc/resolv.conf; then
ETC_RESOLV=' --bind /etc/resolv.conf /etc/resolv.conf '; fi
if test -d /media; then
MNT_MEDIA_DIR=' --bind /media /media '; fi
if test -d /mnt; then
MNT_DIR=' --bind /mnt /mnt '; fi
if test -d /opt; then
OPT_DIR=' --bind /opt /opt '; fi
if test -d /run/user; then
USR_LIB_LOCALE_DIR=' --bind /usr/lib/locale /usr/lib/locale '; fi
if test -d /usr/share/fonts; then
USR_SHARE_FONTS_DIR=' --bind /usr/share/fonts /usr/share/fonts '; fi
if test -d /usr/share/themes; then
USR_SHARE_THEMES_DIR=' --bind /usr/share/themes /usr/share/themes '; fi

BINDS=" $ETC_RESOLV $MNT_MEDIA_DIR $MNT_DIR $OPT_DIR $USR_LIB_LOCALE_DIR $USR_SHARE_FONTS_DIR $USR_SHARE_THEMES_DIR "

if test -f $JUNEST_HOME/usr/lib/libselinux.so; then
	export LD_LIBRARY_PATH=/lib/:/lib64/:/lib/x86_64-linux-gnu/:/usr/lib/:"${LD_LIBRARY_PATH}"
fi

EXEC=$(grep -e '^Exec=.*' "${HERE}"/*.desktop | head -n 1 | cut -d "=" -f 2- | sed -e 's|%.||g')
$HERE/.local/share/junest/bin/junest -n -b "$BINDS" -- $EXEC "$@"
EOF
chmod a+x ./AppRun

# REMOVE "READ-ONLY FILE SYSTEM" ERRORS
sed -i 's#${JUNEST_HOME}/usr/bin/junest_wrapper#${HOME}/.cache/junest_wrapper.old#g' ./.local/share/junest/lib/core/wrappers.sh
sed -i 's/rm -f "${JUNEST_HOME}${bin_path}_wrappers/#rm -f "${JUNEST_HOME}${bin_path}_wrappers/g' ./.local/share/junest/lib/core/wrappers.sh
sed -i 's/ln/#ln/g' ./.local/share/junest/lib/core/wrappers.sh
sed -i 's#--bind "$HOME" "$HOME"#--bind /home /home --bind-try /run/user /run/user#g' .local/share/junest/lib/core/namespace.sh
sed -i 's/rm -f "$file"/test -f "$file"/g' ./.local/share/junest/lib/core/wrappers.sh

# EXIT THE APPDIR
cd ..

# EXTRACT PACKAGE CONTENT
echo "-----------------------------------------------------------"
echo " EXTRACTING DEPENDENCES"
echo -e "-----------------------------------------------------------\n"

mkdir -p base
rm -R -f ./base/*

tar fx "$(find ./"$APP".AppDir -name "$APP-[0-9]*zst" | head -1)" -C ./base/
VERSION=$(cat ./base/.PKGINFO | grep pkgver | cut -c 10- | sed 's@.*:@@')

mkdir -p deps
rm -R -f ./deps/*

function _download_missing_packages() {
	localpackage=$(find ./"$APP".AppDir -name "$arg-[0-9]*zst")
	if ! test -f "$localpackage"; then
		cd ./"$APP".AppDir
		./.local/share/junest/bin/junest -- yay --noconfirm -Sw "$arg"
		cd ..
	fi
}

function _extract_package() {
	_download_missing_packages &> /dev/null
	pkgname=$(find ./"$APP".AppDir -name "$arg-[0-9]*zst")
	if test -f "$pkgname"; then
		if ! grep -q "$(echo "$pkgname" | sed 's:.*/::')" ./packages 2>/dev/null;then
			echo "◆ Extracting $(echo "$pkgname" | sed 's:.*/::')"
			tar fx "$pkgname" -C ./deps/
			echo "$(echo "$pkgname" | sed 's:.*/::')" >> ./packages
		fi
	fi
}

ARGS=$(echo "$DEPENDENCES" | tr " " "\n")
for arg in $ARGS; do
	_extract_package
 	cat ./deps/.PKGINFO 2>/dev/null | grep "depend = " | grep -v "makedepend = " | cut -c 10- | grep -v "=\|>\|<" > depdeps
done

DEPS=$(cat ./base/.PKGINFO | grep "depend = " | grep -v "makedepend = " | cut -c 10- | grep -v "=\|>\|<")
for arg in $DEPS; do
	_extract_package
 	cat ./deps/.PKGINFO 2>/dev/null | grep "depend = " | grep -v "makedepend = " | cut -c 10- | grep -v "=\|>\|<" > depdeps
done

DEPS2=$(cat ./depdeps | uniq)
for arg in $DEPS2; do
	_extract_package
 	cat ./deps/.PKGINFO 2>/dev/null | grep "depend = " | grep -v "makedepend = " | cut -c 10- | grep -v "=\|>\|<" > depdeps2
done

DEPS3=$(cat ./depdeps2 | uniq)
for arg in $DEPS3; do
	_extract_package
 	cat ./deps/.PKGINFO 2>/dev/null | grep "depend = " | grep -v "makedepend = " | cut -c 10- | grep -v "=\|>\|<" > depdeps3
done

DEPS4=$(cat ./depdeps3 | uniq)
for arg in $DEPS4; do
	_extract_package
 	cat ./deps/.PKGINFO 2>/dev/null | grep "depend = " | grep -v "makedepend = " | cut -c 10- | grep -v "=\|>\|<" > depdeps4
done

rm -f ./packages

# REMOVE SOME BLOATWARES
echo Y | rm -R -f ./"$APP".AppDir/.cache/yay/*
find ./"$APP".AppDir/.junest/usr/share/doc/* -not -iname "*$BIN*" -a -not -name "." -delete #REMOVE ALL DOCUMENTATION NOT RELATED TO THE APP
find ./"$APP".AppDir/.junest/usr/share/locale/*/*/* -not -iname "*$BIN*" -a -not -name "." -delete #REMOVE ALL ADDITIONAL LOCALE FILES
rm -R -f ./"$APP".AppDir/.junest/etc/makepkg.conf
rm -R -f ./"$APP".AppDir/.junest/etc/pacman.conf
rm -R -f ./"$APP".AppDir/.junest/usr/include #FILES RELATED TO THE COMPILER
rm -R -f ./"$APP".AppDir/.junest/usr/man #APPIMAGES ARE NOT MENT TO HAVE MAN COMMAND
rm -R -f ./"$APP".AppDir/.junest/var/* #REMOVE ALL PACKAGES DOWNLOADED WITH THE PACKAGE MANAGER

echo -e "\n-----------------------------------------------------------"
echo " IMPLEMENTING NECESSARY LIBRARIES (MAY TAKE SEVERAL MINUTES)"
echo -e "-----------------------------------------------------------\n"

# SAVE FILES USING KEYWORDS
BINSAVED="SAVEBINSPLEASE" # Enter here keywords to find and save in /usr/bin
SHARESAVED="SAVESHAREPLEASE" # Enter here keywords or file/folder names to save in both /usr/share and /usr/lib
LIBSAVED="SAVELIBSPLEASE" # Enter here keywords or file/folder names to save in /usr/lib

# STEP 2, FUNCTION TO SAVE THE BINARIES IN /usr/bin THAT ARE NEEDED TO MADE JUNEST WORK, PLUS THE MAIN BINARY/BINARIES OF THE APP
# IF YOU NEED TO SAVE MORE BINARIES, LIST THEM IN THE "BINSAVED" VARIABLE. COMMENT THE LINE "_savebins" IF YOU ARE NOT SURE.
function _savebins(){
	mkdir save
	mv ./"$APP".AppDir/.junest/usr/bin/*$BIN* ./save/
	mv ./"$APP".AppDir/.junest/usr/bin/bash ./save/
 	mv ./"$APP".AppDir/.junest/usr/bin/bwrap ./save/
	mv ./"$APP".AppDir/.junest/usr/bin/env ./save/
	mv ./"$APP".AppDir/.junest/usr/bin/sh ./save/
 	mv ./"$APP".AppDir/.junest/usr/bin/tr ./save/
   	mv ./"$APP".AppDir/.junest/usr/bin/tty ./save/
	for arg in $BINSAVED; do
		mv ./"$APP".AppDir/.junest/usr/bin/*"$arg"* ./save/
	done
	rm -R -f ./"$APP".AppDir/.junest/usr/bin/*
	mv ./save/* ./"$APP".AppDir/.junest/usr/bin/
	rmdir save
}
#_savebins 2> /dev/null

# STEP 3, MOVE UNNECESSARY LIBRARIES TO A BACKUP FOLDER (FOR TESTING PURPOSES)
mkdir save

function _binlibs(){
	readelf -d ./"$APP".AppDir/.junest/usr/bin/* | grep .so | sed 's:.* ::' | cut -c 2- | sed 's/\(^.*so\).*$/\1/' | uniq >> ./list
	mv ./"$APP".AppDir/.junest/usr/lib/ld-linux-x86-64.so* ./save/
	mv ./"$APP".AppDir/.junest/usr/lib/*$APP* ./save/
	mv ./"$APP".AppDir/.junest/usr/lib/*$BIN* ./save/
	mv ./"$APP".AppDir/.junest/usr/lib/libdw* ./save/
	mv ./"$APP".AppDir/.junest/usr/lib/libelf* ./save/
	for arg in $SHARESAVED; do
		mv ./"$APP".AppDir/.junest/usr/lib/*"$arg"* ./save/
	done
	ARGS=$(tail -n +2 ./list | sort -u | uniq)
	for arg in $ARGS; do
		mv ./"$APP".AppDir/.junest/usr/lib/$arg* ./save/
		find ./"$APP".AppDir/.junest/usr/lib/ -name "$arg" -exec cp -r --parents -t save/ {} +
	done
	rm -R -f "$(find ./save/ | sort | grep ".AppDir" | head -1)"
	rm list
}

function _include_swrast_dri(){
	mkdir ./save/dri
	mv ./"$APP".AppDir/.junest/usr/lib/dri/swrast_dri.so ./save/dri/
}

function _libkeywords(){
	for arg in $LIBSAVED; do
		mv ./"$APP".AppDir/.junest/usr/lib/*"$arg"* ./save/
	done
}

function _liblibs(){
	readelf -d ./save/* | grep .so | sed 's:.* ::' | cut -c 2- | sed 's/\(^.*so\).*$/\1/' | uniq >> ./list
	readelf -d ./save/*/* | grep .so | sed 's:.* ::' | cut -c 2- | sed 's/\(^.*so\).*$/\1/' | uniq >> ./list
	readelf -d ./save/*/*/* | grep .so | sed 's:.* ::' | cut -c 2- | sed 's/\(^.*so\).*$/\1/' | uniq >> ./list
	readelf -d ./save/*/*/*/* | grep .so | sed 's:.* ::' | cut -c 2- | sed 's/\(^.*so\).*$/\1/' | uniq >> ./list
	readelf -d ./save/*/*/*/*/* | grep .so | sed 's:.* ::' | cut -c 2- | sed 's/\(^.*so\).*$/\1/' | uniq >> ./list
 	readelf -d ./base/* | grep .so | sed 's:.* ::' | cut -c 2- | sed 's/\(^.*so\).*$/\1/' | uniq >> ./list
	readelf -d ./base/*/* | grep .so | sed 's:.* ::' | cut -c 2- | sed 's/\(^.*so\).*$/\1/' | uniq >> ./list
	readelf -d ./base/*/*/* | grep .so | sed 's:.* ::' | cut -c 2- | sed 's/\(^.*so\).*$/\1/' | uniq >> ./list
	readelf -d ./base/*/*/*/* | grep .so | sed 's:.* ::' | cut -c 2- | sed 's/\(^.*so\).*$/\1/' | uniq >> ./list
	readelf -d ./base/*/*/*/*/* | grep .so | sed 's:.* ::' | cut -c 2- | sed 's/\(^.*so\).*$/\1/' | uniq >> ./list
  	readelf -d ./deps/* | grep .so | sed 's:.* ::' | cut -c 2- | sed 's/\(^.*so\).*$/\1/' | uniq >> ./list
	readelf -d ./deps/*/* | grep .so | sed 's:.* ::' | cut -c 2- | sed 's/\(^.*so\).*$/\1/' | uniq >> ./list
	readelf -d ./deps/*/*/* | grep .so | sed 's:.* ::' | cut -c 2- | sed 's/\(^.*so\).*$/\1/' | uniq >> ./list
	readelf -d ./deps/*/*/*/* | grep .so | sed 's:.* ::' | cut -c 2- | sed 's/\(^.*so\).*$/\1/' | uniq >> ./list
	readelf -d ./deps/*/*/*/*/* | grep .so | sed 's:.* ::' | cut -c 2- | sed 's/\(^.*so\).*$/\1/' | uniq >> ./list
	ARGS=$(tail -n +2 ./list | sort -u | uniq)
	for arg in $ARGS; do
		mv ./"$APP".AppDir/.junest/usr/lib/"$arg"* ./save/
		find ./"$APP".AppDir/.junest/usr/lib/ -name "$arg" -exec cp -r --parents -t save/ {} +
	done
	rsync -av ./save/"$APP".AppDir/.junest/usr/lib/* ./save/
 	rm -R -f "$(find ./save/ | sort | grep ".AppDir" | head -1)"
	rm list
}

function _mvlibs(){
	rm -R -f ./"$APP".AppDir/.junest/usr/lib/*
	mv ./save/* ./"$APP".AppDir/.junest/usr/lib/
}

#_binlibs 2> /dev/null

#_include_swrast_dri 2> /dev/null

#_libkeywords 2> /dev/null

#_liblibs 2> /dev/null
#_liblibs 2> /dev/null
#_liblibs 2> /dev/null
#_liblibs 2> /dev/null
#_liblibs 2> /dev/null

#_mvlibs 2> /dev/null

rmdir save

# STEP 4, SAVE ONLY SOME DIRECTORIES CONTAINED IN /usr/share
# IF YOU NEED TO SAVE MORE FOLDERS, LIST THEM IN THE "SHARESAVED" VARIABLE. COMMENT THE LINE "_saveshare" IF YOU ARE NOT SURE.
function _saveshare(){
	mkdir save
	mv ./"$APP".AppDir/.junest/usr/share/*$APP* ./save/
 	mv ./"$APP".AppDir/.junest/usr/share/*$BIN* ./save/
	mv ./"$APP".AppDir/.junest/usr/share/fontconfig ./save/
	mv ./"$APP".AppDir/.junest/usr/share/glib-* ./save/
	mv ./"$APP".AppDir/.junest/usr/share/locale ./save/
	mv ./"$APP".AppDir/.junest/usr/share/mime ./save/
	mv ./"$APP".AppDir/.junest/usr/share/wayland ./save/
	mv ./"$APP".AppDir/.junest/usr/share/X11 ./save/
	for arg in $SHARESAVED; do
		mv ./"$APP".AppDir/.junest/usr/share/*"$arg"* ./save/
	done
	rm -R -f ./"$APP".AppDir/.junest/usr/share/*
	mv ./save/* ./"$APP".AppDir/.junest/usr/share/
 	rmdir save
}
#_saveshare 2> /dev/null

# RSYNC THE CONTENT OF THE APP'S PACKAGE
echo -e "\n-----------------------------------------------------------"
rm -R -f ./base/.*
rsync -av ./base/* ./"$APP".AppDir/.junest/ | echo -e "◆ Rsync the content of the \"$APP\" package"

# RSYNC DEPENDENCES
rm -R -f ./deps/.*
#rsync -av ./deps/* ./"$APP".AppDir/.junest/ | echo -e "◆ Rsync all dependeces, please wait..."
echo -e "-----------------------------------------------------------\n"

# ADDITIONAL REMOVALS
#rm -R -f ./"$APP".AppDir/.junest/usr/lib/libLLVM-* #INCLUDED IN THE COMPILATION PHASE, CAN SOMETIMES BE EXCLUDED FOR DAILY USE
rm -R -f ./"$APP".AppDir/.junest/usr/lib/python*/__pycache__/* #IF PYTHON IS INSTALLED, REMOVING THIS DIRECTORY CAN SAVE SEVERAL MEGABYTES

# REMOVE THE INBUILT HOME
rm -R -f ./"$APP".AppDir/.junest/home

# ENABLE MOUNTPOINTS
mkdir -p ./"$APP".AppDir/.junest/home
mkdir -p ./"$APP".AppDir/.junest/media
mkdir -p ./"$APP".AppDir/.junest/usr/lib/locale
mkdir -p ./"$APP".AppDir/.junest/usr/share/fonts
mkdir -p ./"$APP".AppDir/.junest/usr/share/themes
mkdir -p ./"$APP".AppDir/.junest/run/user

# CREATE THE APPIMAGE
if test -f ./*.AppImage; then
	rm -R -f ./*archimage*.AppImage
fi
ARCH=x86_64 VERSION=$(./appimagetool -v | grep -o '[[:digit:]]*') ./appimagetool -s ./"$APP".AppDir
mv ./*AppImage ./"$(cat ./"$APP".AppDir/*.desktop | grep 'Name=' | head -1 | cut -c 6- | sed 's/ /-/g')"_"$VERSION"-archimage3.4.2-x86_64.AppImage
