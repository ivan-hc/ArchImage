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

_enable_multilib() {
	printf "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" >> ./.junest/etc/pacman.conf
}

_enable_chaoticaur() {
	# This function is ment to be used during the installation of JuNest, see "_pacman_patches"
	_JUNEST_CMD -- sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
	_JUNEST_CMD -- sudo pacman-key --lsign-key 3056513887B78AEB
	_JUNEST_CMD -- sudo pacman-key --populate chaotic
	_JUNEST_CMD -- sudo pacman --noconfirm -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
	printf "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" >> ./.junest/etc/pacman.conf
}

_enable_archlinuxcn() {
	_JUNEST_CMD -- sudo pacman --noconfirm -U "https://repo.archlinuxcn.org/x86_64/$(curl -Ls https://repo.archlinuxcn.org/x86_64/ | tr '"' '\n' | grep "^archlinuxcn-keyring.*zst$" | tail -1)"
	printf "\n[archlinuxcn]\n#SigLevel = Never\nServer = http://repo.archlinuxcn.org/\$arch" >> ./.junest/etc/pacman.conf
}

_custom_mirrorlist() {
	COUNTRY=$(curl -i ipinfo.io 2>/dev/null | grep country | cut -c 15- | cut -c -2)
	if [ -n "$GITHUB_REPOSITORY_OWNER" ] || ! curl --output /dev/null --silent --head --fail "https://archlinux.org/mirrorlist/?country=$COUNTRY" 1>/dev/null; then
		curl -Ls https://archlinux.org/mirrorlist/all | awk NR==2 RS= | sed 's/#Server/Server/g' > ./.junest/etc/pacman.d/mirrorlist
	else
		curl -Ls "https://archlinux.org/mirrorlist/?country=$COUNTRY" | sed 's/#Server/Server/g' > ./.junest/etc/pacman.d/mirrorlist
	fi
}

_bypass_signature_check_level() {
	sed -i 's/#SigLevel/SigLevel/g; s/Required DatabaseOptional/Never/g' ./.junest/etc/pacman.conf
}

_install_junest() {
	printf -- "-----------------------------------------------------------------------------\n◆ Clone JuNest from https://github.com/ivan-hc/junest\n-----------------------------------------------------------------------------\n"
	git clone https://github.com/ivan-hc/junest.git ./.local/share/junest
	printf -- "-----------------------------------------------------------------------------\n◆ Downloading JuNest archive from https://github.com/ivan-hc/junest\n-----------------------------------------------------------------------------\n"
	if [ ! -f ./junest-x86_64.tar.gz ]; then
		curl -#Lo junest-x86_64.tar.gz https://github.com/ivan-hc/junest/releases/download/continuous/junest-x86_64.tar.gz || exit 1
	fi
	_JUNEST_CMD setup -i junest-x86_64.tar.gz
	echo " Apply patches to PacMan..."
	#_enable_multilib
	#_enable_chaoticaur
	#_enable_archlinuxcn
	_custom_mirrorlist
	_bypass_signature_check_level

	# Update arch linux in junest
	_JUNEST_CMD -- sudo pacman -Syy
	_JUNEST_CMD -- sudo pacman --noconfirm -Syu
}

if ! test -d "$HOME/.local/share/junest"; then
	printf -- "-----------------------------------------------------------------------------\n DOWNLOAD, INSTALL AND CONFIGURE JUNEST\n-----------------------------------------------------------------------------\n"
	_install_junest
else
	printf -- "-----------------------------------------------------------------------------\n RESTART JUNEST\n-----------------------------------------------------------------------------\n"
fi

##########################################################################################################################################################
#	INSTALL PROGRAMS USING YAY
##########################################################################################################################################################

_JUNEST_CMD -- yay -Syy
#_JUNEST_CMD -- gpg --keyserver keyserver.ubuntu.com --recv-key C01E1CAD5EA2C4F0B8E3571504C367C218ADD4FF # UNCOMMENT IF YOU USE THE AUR
if [ -n "$BASICSTUFF" ]; then
	_JUNEST_CMD -- yay --noconfirm -S $BASICSTUFF
fi
if [ -n "$COMPILERS" ]; then
	_JUNEST_CMD -- yay --noconfirm -S $COMPILERS
	_JUNEST_CMD -- yay --noconfirm -S python # to force one Python version and prevent modules from being installed in different directories (e.g. "mesonbuild")
fi
if [ -n "$DEPENDENCES" ]; then
	_JUNEST_CMD -- yay --noconfirm -S $DEPENDENCES
fi
if [ -n "$APP" ]; then
	_JUNEST_CMD -- yay --noconfirm -S alsa-lib gtk3 hicolor-icon-theme xapp xdg-utils xorg-server-xvfb zsync
	_JUNEST_CMD -- yay --noconfirm -S "$APP"
	# Use debloated packages
	debloated_soueces="https://github.com/pkgforge-dev/archlinux-pkgs-debloated/releases/download/continuous"
	extra_vk_packages="vulkan-asahi vulkan-broadcom vulkan-freedreno vulkan-intel vulkan-nouveau vulkan-panfrost vulkan-radeon"
	extra_packages="ffmpeg gdk-pixbuf2 gtk3 gtk4 intel-media-driver llvm-libs mangohud mesa opus qt6-base $extra_vk_packages"
	for p in $extra_packages; do
		if _JUNEST_CMD -- yay -Qs "$p"; then
			if [ ! -f ./"$p"-2.x-x86_64.pkg.tar.zst ]; then
				curl -#Lo "$p"-2.x-x86_64.pkg.tar.zst "$debloated_soueces/$p-mini-x86_64.pkg.tar.zst" || exit 1
			fi
			_JUNEST_CMD -- yay --noconfirm -U "$HOME"/"$p"-2.x-x86_64.pkg.tar.zst
		fi
	done
	# Try to compile schema files
	_JUNEST_CMD -- glib-compile-schemas /usr/share/glib-2.0/schemas/
else
	echo "No app found, exiting"; exit 1
fi

##########################################################################################################################################################
#	CREATE THE APPIMAGE
##########################################################################################################################################################

# AppDir setup
mkdir -p AppDir

# Add launcher and icon
rm -f AppDir/*.desktop
LAUNCHER=$(grep -iRl "^Exec.*$BIN" .junest/usr/share/applications/* | grep ".desktop" | head -1)
cp -r "$LAUNCHER" AppDir/
ICON=$(cat "$LAUNCHER" | grep "Icon=" | cut -c 6-)
[ -z "$ICON" ] && ICON="$BIN"
cp -r .junest/usr/share/icons/*"$ICON"* AppDir/ 2>/dev/null
cp -r .junest/usr/share/icons/hicolor/22x22/apps/*"$ICON"* AppDir/ 2>/dev/null
cp -r .junest/usr/share/icons/hicolor/24x24/apps/*"$ICON"* AppDir/ 2>/dev/null
cp -r .junest/usr/share/icons/hicolor/32x32/apps/*"$ICON"* AppDir/ 2>/dev/null
cp -r .junest/usr/share/icons/hicolor/48x48/apps/*"$ICON"* AppDir/ 2>/dev/null
cp -r .junest/usr/share/icons/hicolor/64x64/apps/*"$ICON"* AppDir/ 2>/dev/null
cp -r .junest/usr/share/icons/hicolor/128x128/apps/*"$ICON"* AppDir/ 2>/dev/null
cp -r .junest/usr/share/icons/hicolor/192x192/apps/*"$ICON"* AppDir/ 2>/dev/null
cp -r .junest/usr/share/icons/hicolor/256x256/apps/*"$ICON"* AppDir/ 2>/dev/null
cp -r .junest/usr/share/icons/hicolor/512x512/apps/*"$ICON"* AppDir/ 2>/dev/null
cp -r .junest/usr/share/icons/hicolor/scalable/apps/*"$ICON"* AppDir/ 2>/dev/null
cp -r .junest/usr/share/pixmaps/*"$ICON"* AppDir/ 2>/dev/null

# Version
export VERSION="$(_JUNEST_CMD -- yay -Q "$APP" | awk '{print $2; exit}')"
echo "$VERSION" > ~/version

# Anylinux variables
ARCH="x86_64"
URUNTIME="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/uruntime2appimage.sh"
SHARUN="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/quick-sharun.sh"

export APPNAME=$(cat AppDir/*.desktop | grep '^Name=' | head -1 | cut -c 6- | sed 's/ /-/g')
export REPO="$APPNAME-appimage"
export TAG="latest"
export UPINFO="gh-releases-zsync|$GITHUB_REPOSITORY_OWNER|$REPO|$TAG|*x86_64.AppImage.zsync"

export OUTNAME="$APPNAME"-"$VERSION"-anylinux-"$ARCH".AppImage

# Deploy dependencies
wget --retry-connrefused --tries=30 "$SHARUN" -O ./quick-sharun
chmod +x ./quick-sharun
_JUNEST_CMD -- ./quick-sharun /usr/bin/"$BIN"

printf -- "\n-----------------------------------------------------------------------------\n IMPLEMENTING USER'S SELECTED FILES AND DIRECTORIES\n-----------------------------------------------------------------------------\n\n"

# Save files in /usr/bin
_savebins() {
	echo "◆ Saving files in /usr/bin"
	for arg in $BINSAVED; do
		cp -r ./.junest/usr/bin/*"$arg"* AppDir/bin/
	done
}

# Save files in /usr/lib
_savelibs() {
	echo "◆ Detect libraries related to /usr/bin files"
	libs4bin=$(readelf -d AppDir/bin/* 2>/dev/null | grep NEEDED | tr '[] ' '\n' | grep ".so")

	LIBSAVED="$libs4bin $LIBSAVED"
	for arg in $LIBSAVED; do
		LIBPATHS="$LIBPATHS $(find ./.junest/usr/lib -maxdepth 20 -wholename "*$arg*" | sed 's/\.\/archlinux\///g')"
	done
	for arg in $LIBPATHS; do
		[ ! -d AppDir/"$arg" ] && cp -r ./archlinux/"$arg" AppDir/"$arg" &
	done
	wait
	core_libs=$(find AppDir -type f)
	lib_core=$(for c in $core_libs; do readelf -d "$c" 2>/dev/null | grep NEEDED | tr '[] ' '\n' | grep ".so"; done)

	echo "◆ Detect and copy base libs"
	basebin_libs=$(find ./AppDir -executable -name "*.so*")
	lib_base_1=$(for b in $basebin_libs; do readelf -d "$b" 2>/dev/null | grep NEEDED | tr '[] ' '\n' | grep ".so"; done)
	lib_base_1=$(echo "$lib_base_1" | tr ' ' '\n' | sort -u | xargs)
	lib_base_2=$(for b in $lib_base_1; do readelf -d ./.junest/usr/lib/"$b" 2>/dev/null | grep NEEDED | tr '[] ' '\n' | grep ".so"; done)
	lib_base_2=$(echo "$lib_base_2" | tr ' ' '\n' | sort -u | xargs)
	lib_base_3=$(for b in $lib_base_2; do readelf -d ./.junest/usr/lib/"$b" 2>/dev/null | grep NEEDED | tr '[] ' '\n' | grep ".so"; done)
	lib_base_3=$(echo "$lib_base_3" | tr ' ' '\n' | sort -u | xargs)
	lib_base_4=$(for b in $lib_base_3; do readelf -d ./.junest/usr/lib/"$b" 2>/dev/null | grep NEEDED | tr '[] ' '\n' | grep ".so"; done)
	lib_base_4=$(echo "$lib_base_4" | tr ' ' '\n' | sort -u | xargs)
	lib_base_5=$(for b in $lib_base_4; do readelf -d ./.junest/usr/lib/"$b" 2>/dev/null | grep NEEDED | tr '[] ' '\n' | grep ".so"; done)
	lib_base_5=$(echo "$lib_base_5" | tr ' ' '\n' | sort -u | xargs)
	lib_base_6=$(for b in $lib_base_5; do readelf -d ./.junest/usr/lib/"$b" 2>/dev/null | grep NEEDED | tr '[] ' '\n' | grep ".so"; done)
	lib_base_6=$(echo "$lib_base_6" | tr ' ' '\n' | sort -u | xargs)
	lib_base_7=$(for b in $lib_base_6; do readelf -d ./.junest/usr/lib/"$b" 2>/dev/null | grep NEEDED | tr '[] ' '\n' | grep ".so"; done)
	lib_base_7=$(echo "$lib_base_7" | tr ' ' '\n' | sort -u | xargs)
	lib_base_8=$(for b in $lib_base_7; do readelf -d ./.junest/usr/lib/"$b" 2>/dev/null | grep NEEDED | tr '[] ' '\n' | grep ".so"; done)
	lib_base_8=$(echo "$lib_base_8" | tr ' ' '\n' | sort -u | xargs)
	lib_base_9=$(for b in $lib_base_8; do readelf -d ./.junest/usr/lib/"$b" 2>/dev/null | grep NEEDED | tr '[] ' '\n' | grep ".so"; done)
	lib_base_9=$(echo "$lib_base_9" | tr ' ' '\n' | sort -u | xargs)
	lib_base_libs="$lib_core $lib_base_1 $lib_base_2 $lib_base_3 $lib_base_4 $lib_base_5 $lib_base_6 $lib_base_7 $lib_base_8 $lib_base_9"
	lib_base_libs=$(echo "$lib_base_libs" | tr ' ' '\n' | sort -u | sed 's/.so.*/.so/' | xargs)
	for l in $lib_base_libs; do
		rsync -av ./.junest/usr/lib/"$l"* AppDir/lib/ &
	done
	wait
}

# Save files in /usr/share
_saveshare() {
	echo "◆ Saving directories in /usr/share"
	SHARESAVED="$SHARESAVED $APP $BIN"
	for arg in $SHARESAVED; do
		cp -r ./.junest/usr/share/*"$arg"* AppDir/share/
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

_remove_more_bloatwares() {
	for r in $BIN_REMOVED; do rm -Rf AppDir/bin/"$r"*; done
	for r in $LIB_REMOVED; do rm -Rf AppDir/lib/"$r"*; done
	for r in $PYTHON_REMOVED; do rm -Rf AppDir/lib/python*/"$r"*; done
	for r in $SHARE_REMOVED; do rm -Rf AppDir/share/"$r"*; done
	find AppDir/share/doc/* -not -iname "*$BIN*" -a -not -name "." -delete 2> /dev/null #REMOVE ALL DOCUMENTATION NOT RELATED TO THE APP
	find AppDir/share/locale/*/*/* -not -iname "*$BIN*" -a -not -name "." -delete 2> /dev/null #REMOVE ALL ADDITIONAL LOCALE FILES
	rm -Rf AppDir/share/man # AppImages are not ment to have man command
}

##########################################################################################################################################################
#	CREATE THE APPIMAGE WITH URUNTIME
##########################################################################################################################################################

wget --retry-connrefused --tries=30 "$URUNTIME" -O ./uruntime2appimage
chmod +x ./uruntime2appimage
_JUNEST_CMD -- ./uruntime2appimage

cd ..
mv archlinux/*.AppImage* ./
