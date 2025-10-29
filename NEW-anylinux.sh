#!/usr/bin/env bash

APP=SAMPLE
BIN="$APP" #CHANGE THIS IF THE NAME OF THE BINARY IS DIFFERENT FROM "$APP" (for example, the binary of "obs-studio" is "obs")
DEPENDENCES="" #SYNTAX: "APP1 APP2 APP3 APP4...", LEAVE BLANK IF NO OTHER DEPENDENCIES ARE NEEDED
#BASICSTUFF="binutils debugedit gzip"
#COMPILERS="base-devel"

# Set keywords to searchan include in names of directories and files in /usr/bin (BINSAVED), /usr/share (SHARESAVED) and /usr/lib (LIBSAVED)
BINSAVED="SAVEBINSPLEASE"
SHARESAVED="SAVESHAREPLEASE"
LIBSAVED="SAVELIBSPLEASE"

# Set the items you want to manually REMOVE. Complete the path in /etc/, /usr/bin/, /usr/lib/, /usr/lib/python*/ and /usr/share/ respectively.
# The "rm" command will take into account the listed object/path and add an asterisk at the end, completing the path to be removed.
# Some keywords and paths are already set. Remove them if you consider them necessary for the AppImage to function properly.
ETC_REMOVED="makepkg.conf pacman"
BIN_REMOVED="gcc"
LIB_REMOVED="gcc"
PYTHON_REMOVED="__pycache__/"
SHARE_REMOVED="gcc"

# Post-installation processes (add whatever you want)
_post_installation_processes() {
	printf "\n◆ User's processes: \n\n"
	echo " - None"
	# Add here your code
}

##########################################################################################################################################################
#	SETUP THE ENVIRONMENT
##########################################################################################################################################################

# Download archimage-builder.sh
if [ ! -f ./archimage-builder.sh ]; then
	ARCHIMAGE_BUILDER="https://raw.githubusercontent.com/ivan-hc/ArchImage/refs/heads/main/core/archimage-builder.sh"
	wget --retry-connrefused --tries=30 "$ARCHIMAGE_BUILDER" -O ./archimage-builder.sh || exit 0
fi

# Create and enter the AppDir
mkdir -p archlinux && cd archlinux || exit 1

_JUNEST_CMD() {
	./.local/share/junest/bin/junest "$@"
}

# Set archlinux as a temporary $HOME directory
HOME="$(dirname "$(readlink -f "$0")")"

##########################################################################################################################################################
#	DOWNLOAD, INSTALL AND CONFIGURE JUNEST
##########################################################################################################################################################

_enable_archlinuxcn() {	ARCHLINUXCN_ON="1"; }
_enable_chaoticaur() { CHAOTICAUR_ON="1"; }
_enable_multilib() { MULTILIB_ON="1"; }

#_enable_archlinuxcn
#_enable_chaoticaur
#_enable_multilib

[ -f ../archimage-builder.sh ] && source ../archimage-builder.sh junest-setup "$@"

##########################################################################################################################################################
#	INSTALL PROGRAMS USING YAY
##########################################################################################################################################################

_JUNEST_CMD -- yay -Syy
#_JUNEST_CMD -- gpg --keyserver keyserver.ubuntu.com --recv-key C01E1CAD5EA2C4F0B8E3571504C367C218ADD4FF # UNCOMMENT IF YOU USE THE AUR

[ -f ../archimage-builder.sh ] && source ../archimage-builder.sh install "$@"

anylinux_utils="xorg-server-xvfb zsync"
for alu in $anylinux_utils; do
	if ! _JUNEST_CMD -- yay -Qs "$alu"; then
		_JUNEST_CMD -- yay --noconfirm -S "$alu"
	fi
done

##########################################################################################################################################################
#	APPDIR
##########################################################################################################################################################

# AppDir setup
mkdir -p AppDir
if [ ! -f ./deps ]; then
	rm -Rf AppDir/*
elif [ -f ./deps ]; then
	DEPENDENCES0=$(cat ./deps)
	[ "$DEPENDENCES0" != "$DEPENDENCES" ] && rm -Rf AppDir/*
fi
echo "$DEPENDENCES" > ./deps
[ ! -f ./deps ] && touch ./deps

# Add launcher and icon
rm -f AppDir/*.desktop
if [ "$BIN" = libreoffice ]; then
	LAUNCHER=$(grep -iRl "^Exec.*$BIN" ./.junest/lib/libreoffice/share/xdg/* | grep "startcenter.*.desktop" | head -1)
else
	LAUNCHER=$(grep -iRl "^Exec.*$BIN" ./.junest/usr/share/applications/* | grep ".desktop" | head -1)
fi
cp -r "$LAUNCHER" AppDir/
[ -z "$ICON" ] && ICON=$(cat "$LAUNCHER" | grep "Icon=" | cut -c 6-)
[ -z "$ICON" ] && ICON="$BIN"
cp -r ./.junest/usr/share/icons/*"$ICON"* AppDir/ 2>/dev/null
hicolor_dirs="22x22 24x24 32x32 48x4 64x64 128x128 192x192 256x256 512x512 scalable"
for i in $hicolor_dirs; do
	cp -r ./.junest/usr/share/icons/hicolor/"$i"/apps/*"$ICON"* AppDir/ 2>/dev/null || cp -r ./.junest/usr/share/icons/hicolor/"$i"/mimetypes/*"$ICON"* AppDir/ 2>/dev/null
done
cp -r ./.junest/usr/share/pixmaps/*"$ICON"* AppDir/ 2>/dev/null

# Test if the desktop file and the icon are in the root of the future appimage (./*appdir/*)
if test -f AppDir/*.desktop; then
	echo "◆ The .desktop file is available in AppDir/"
elif ! test -f ./.junest/usr/bin/"$BIN"; then
 	echo "No binary in path... aborting all the processes."
	exit 0
fi

# Version
export VERSION="$(_JUNEST_CMD -- yay -Q "$APP" | awk '{print $2; exit}' | sed 's@.*:@@')"
echo "$VERSION" > ~/version

##########################################################################################################################################################
#	COMPILE
##########################################################################################################################################################

ARCH="x86_64"

# Deploy dependencies
SHARUN="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/quick-sharun.sh"

wget --retry-connrefused --tries=30 "$SHARUN" -O ./quick-sharun
chmod +x ./quick-sharun
_JUNEST_CMD -- ./quick-sharun /usr/bin/"$BIN"

# Extract the main package in the AppDir
_extract_base_to_AppDir() {
	#rsync -av base/etc/* AppDir/etc/ 2>/dev/null
	#rsync -av base/usr/bin/* AppDir/bin/ 2>/dev/null
	#rsync -av base/usr/lib/* AppDir/lib/ 2>/dev/null
	rsync -av base/usr/share/* AppDir/share/ 2>/dev/null
}

_extract_main_package() {
	mkdir -p base
	rm -Rf ./base/*
	pkg_full_path=$(find ./.junest -type f -name "$APP-*zst")
	if [ -z "$pkg_full_path" ]; then
		pkg_full_path=$(find . -type f -name "$APP-*zst")
	fi
	if [ "$(echo "$pkg_full_path" | wc -l)" != 1 ]; then
		for p in $pkg_full_path; do
			if tar fx "$p" .PKGINFO -O | grep -q "pkgname = $APP$"; then
				pkg_full_path="$p"
			fi
		done
	fi
	[ -z "$pkg_full_path" ] && echo "💀 ERROR: no package found for \"$APP\", operation aborted!" && exit 0
	tar fx "$pkg_full_path" -C ./base/ --warning=no-unknown-keyword
	_extract_base_to_AppDir | printf "\n◆ Extract the base package to AppDir\n"
}

_extract_main_package

printf -- "\n-----------------------------------------------------------------------------\n IMPLEMENTING USER'S SELECTED FILES AND DIRECTORIES\n-----------------------------------------------------------------------------\n\n"

# Save files in /usr/bin
_savebins() {
	echo "◆ Saving files in /usr/bin"
	for arg in $BINSAVED; do
		rsync -av ./.junest/usr/bin/*"$arg"* AppDir/bin/ 1>/dev/null
	done
}

# Save files in /usr/lib
_savelibs() {
	echo "◆ Saving directories and files in /usr/lib"
	LIBSAVED="$LIBSAVED $APP $BIN"
	for arg in $LIBSAVED; do
		rsync -av ./.junest/usr/lib/*"$arg"* AppDir/lib/ 1>/dev/null
 	done
}

# Save files in /usr/share
_saveshare() {
	echo "◆ Saving directories in /usr/share"
	SHARESAVED="$SHARESAVED $APP $BIN"
	for arg in $SHARESAVED; do
		rsync -av ./.junest/usr/share/*"$arg"* AppDir/share/ 1>/dev/null
 	done
}

_savebins 2>/dev/null
_savelibs 2>/dev/null
_saveshare 2>/dev/null

printf -- "\n-----------------------------------------------------------------------------\n ASSEMBLING THE APPIMAGE\n-----------------------------------------------------------------------------\n"

_post_installation_processes

##########################################################################################################################################################
#	REMOVE BLOATWARES
##########################################################################################################################################################

# Remove bloatwares
for r in $BIN_REMOVED; do rm -Rf AppDir/bin/"$r"*; done
for r in $LIB_REMOVED; do rm -Rf AppDir/lib/"$r"*; done
for r in $PYTHON_REMOVED; do rm -Rf AppDir/lib/python*/"$r"*; done
for r in $SHARE_REMOVED; do rm -Rf AppDir/share/"$r"*; done
find AppDir/share/doc/* -not -iname "*$BIN*" -a -not -name "." -delete 2> /dev/null #REMOVE ALL DOCUMENTATION NOT RELATED TO THE APP
find AppDir/share/locale/*/*/* -not -iname "*$BIN*" -a -not -name "." -delete 2> /dev/null #REMOVE ALL ADDITIONAL LOCALE FILES
rsync -av base/usr/share/locale/* AppDir/share/locale/ | printf "◆ Save locale from base package\n"
rm -Rf AppDir/share/man # AppImages are not ment to have man command

##########################################################################################################################################################
#	CREATE THE APPIMAGE WITH URUNTIME
##########################################################################################################################################################

URUNTIME="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/uruntime2appimage.sh"

export APPNAME=$(cat AppDir/*.desktop | grep '^Name=' | head -1 | cut -c 6- | sed 's/ /-/g')
export REPO="$APPNAME-appimage"
export TAG="latest"
export UPINFO="gh-releases-zsync|$GITHUB_REPOSITORY_OWNER|$REPO|$TAG|*x86_64.AppImage.zsync"

export OUTNAME="$APPNAME"-"$VERSION"-anylinux-"$ARCH".AppImage

wget --retry-connrefused --tries=30 "$URUNTIME" -O ./uruntime2appimage
chmod +x ./uruntime2appimage
_JUNEST_CMD -- ./uruntime2appimage

cd ..
mv archlinux/*.AppImage* ./
