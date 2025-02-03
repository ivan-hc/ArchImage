#!/usr/bin/env bash

APP=gearlever
BIN="$APP" #CHANGE THIS IF THE NAME OF THE BINARY IS DIFFERENT FROM "$APP" (for example, the binary of "obs-studio" is "obs")
DEPENDENCES="python-gobject python-dbus python-graphene python-chardet graphene python-cairo cairo ibus libibus fuse3 file 7zip" #SYNTAX: "APP1 APP2 APP3 APP4...", LEAVE BLANK IF NO OTHER DEPENDENCIES ARE NEEDED
BASICSTUFF="binutils debugedit gzip"
COMPILERS="base-devel"

#############################################################################
#	SETUP THE ENVIRONMENT
#############################################################################

# Download appimagetool
if [ ! -f ./appimagetool ]; then
	echo "-----------------------------------------------------------------------------"
	echo "◆ Downloading \"appimagetool\" from https://github.com/AppImage/appimagetool"
	echo "-----------------------------------------------------------------------------"
	curl -#Lo appimagetool https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage && chmod a+x appimagetool
fi

# Create and enter the AppDir
mkdir -p "$APP".AppDir archlinux && cd archlinux || exit 1

# Set archlinux as a temporary $HOME directory
HOME="$(dirname "$(readlink -f "$0")")"

#############################################################################
#	DOWNLOAD, INSTALL AND CONFIGURE JUNEST
#############################################################################

_enable_multilib() {
	printf "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" >> ./.junest/etc/pacman.conf
}

_enable_chaoticaur() {
	# This function is ment to be used during the installation of JuNest, see "_pacman_patches"
	./.local/share/junest/bin/junest -- sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
	./.local/share/junest/bin/junest -- sudo pacman-key --lsign-key 3056513887B78AEB
	./.local/share/junest/bin/junest -- sudo pacman-key --populate chaotic
	./.local/share/junest/bin/junest -- sudo pacman --noconfirm -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
	printf "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" >> ./.junest/etc/pacman.conf
}

_enable_archlinuxcn() {
	./.local/share/junest/bin/junest -- sudo pacman --noconfirm -U "https://repo.archlinuxcn.org/x86_64/$(curl -Ls https://repo.archlinuxcn.org/x86_64/ | tr '"' '\n' | grep "^archlinuxcn-keyring.*zst$" | tail -1)"
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
	echo "-----------------------------------------------------------------------------"
	echo "◆ Clone JuNest from https://github.com/fsquillace/junest"
	echo "-----------------------------------------------------------------------------"
	git clone https://github.com/fsquillace/junest.git ./.local/share/junest
	echo "-----------------------------------------------------------------------------"
	echo "◆ Downloading JuNest archive from https://github.com/ivan-hc/junest"
	echo "-----------------------------------------------------------------------------"
	curl -#Lo junest-x86_64.tar.gz https://github.com/ivan-hc/junest/releases/download/continuous/junest-x86_64.tar.gz
	./.local/share/junest/bin/junest setup -i junest-x86_64.tar.gz
	rm -f junest-x86_64.tar.gz
	echo " Apply patches to PacMan..."
	#_enable_multilib
	#_enable_chaoticaur
	#_enable_archlinuxcn
	_custom_mirrorlist
	_bypass_signature_check_level

	# Update arch linux in junest
	./.local/share/junest/bin/junest -- sudo pacman -Syy
	./.local/share/junest/bin/junest -- sudo pacman --noconfirm -Syu
}

if ! test -d "$HOME/.local/share/junest"; then
	echo "-----------------------------------------------------------------------------"
	echo " DOWNLOAD, INSTALL AND CONFIGURE JUNEST"
	echo "-----------------------------------------------------------------------------"
	_install_junest
else
	echo "-----------------------------------------------------------------------------"
	echo " RESTART JUNEST"
	echo "-----------------------------------------------------------------------------"
fi

#############################################################################
#	INSTALL PROGRAMS USING YAY
#############################################################################

cd .. || exit 1
if [ ! -d ./base ]; then
	cd ./archlinux || exit 1
	./.local/share/junest/bin/junest -- yay -Syy
	./.local/share/junest/bin/junest -- gpg --keyserver keyserver.ubuntu.com --recv-key C01E1CAD5EA2C4F0B8E3571504C367C218ADD4FF # UNCOMMENT IF YOU USE THE AUR
	if [ -n "$BASICSTUFF" ]; then
		./.local/share/junest/bin/junest -- yay --noconfirm -S $BASICSTUFF
	fi
	if [ -n "$COMPILERS" ]; then
		./.local/share/junest/bin/junest -- yay --noconfirm -S $COMPILERS
		./.local/share/junest/bin/junest -- yay --noconfirm -Rc python
		./.local/share/junest/bin/junest -- yay --noconfirm -S python
	fi
	if [ -n "$DEPENDENCES" ]; then
		./.local/share/junest/bin/junest -- yay --noconfirm -S $DEPENDENCES
	fi
	if [ -n "$APP" ]; then
		./.local/share/junest/bin/junest -- yay --noconfirm -S alsa-lib gtk3 xapp
		./.local/share/junest/bin/junest -- yay --noconfirm -S "$APP"
		./.local/share/junest/bin/junest -- glib-compile-schemas /usr/share/glib-2.0/schemas/
	else
		echo "No app found, exiting"; exit 1
	fi

	cd ..
fi

#############################################################################
#	EXTRACT PACKAGES
#############################################################################

_extract_main_package() {
	mkdir -p base
	rm -Rf ./base/*
	pkg_full_path=$(find ./archlinux -type f -name "$APP-*zst")
	if [ "$(echo "$pkg_full_path" | wc -l)" = 1 ]; then
		pkg_full_path=$(find ./archlinux -type f -name "$APP-*zst")
	else
		for p in $pkg_full_path; do
			if tar fx "$p" .PKGINFO -O | grep -q "pkgname = $APP$"; then
				pkg_full_path="$p"
			fi
		done
	fi
	[ -z "$pkg_full_path" ] && echo "💀 ERROR: no package found for \"$APP\", operation aborted!" && exit 0
	tar fx "$pkg_full_path" -C ./base/
	VERSION=$(cat ./base/.PKGINFO | grep pkgver | cut -c 10- | sed 's@.*:@@')
}

_extract_main_package

#############################################################################
#	DEBIAN BASE
#############################################################################

# DOWNLOADING THE DEPENDENCIES
if test -f ./pkg2appimage; then
	echo " pkg2appimage already exists" 1> /dev/null
else
	echo " Downloading pkg2appimage..."
	wget -q https://raw.githubusercontent.com/ivan-hc/AM-application-manager/main/tools/pkg2appimage
fi
chmod a+x ./pkg2appimage

# CREATING THE HEAD OF THE RECIPE
echo "app: gearlever
binpatch: true

ingredients:

  dist: stable
  sources:
    - deb http://ftp.debian.org/debian/ stable main contrib non-free
    - deb http://security.debian.org/debian-security/ stable-security main contrib non-free
    - deb http://ftp.debian.org/debian/ stable-updates main contrib non-free
  packages:
    - gearlever
    - python3
    - python3-gi
    - python3-dbus
    - python3-chardet
    - libgtk-4-dev
    - libadwaita-1-dev
    - python3-xdg
    - 7zip
    - gsettings-backend
    - dconf-gsettings-backend" > recipe.yml

# DOWNLOAD ALL THE NEEDED PACKAGES AND COMPILE THE APPDIR
./pkg2appimage ./recipe.yml

rsync -av ./"$APP"/"$APP".AppDir/ ./"$APP".AppDir/

# LIBUNIONPRELOAD
wget https://github.com/project-portable/libunionpreload/releases/download/amd64/libunionpreload.so
chmod a+x libunionpreload.so
mv ./libunionpreload.so ./"$APP".AppDir/

# COMPILE SCHEMAS
glib-compile-schemas ./"$APP".AppDir/usr/share/glib-2.0/schemas/ || echo "No ./usr/share/glib-2.0/schemas/"

# CUSTOMIZE THE APPRUN
rm -f ./"$APP".AppDir/AppRun
cat >> ./"$APP".AppDir/AppRun << 'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f "${0}")")"
export UNION_PRELOAD="${HERE}"
export LD_PRELOAD="${HERE}"/libunionpreload.so
export LD_LIBRARY_PATH=/lib/:/lib64/:/lib/x86_64-linux-gnu/:/usr/lib/:"${HERE}"/usr/lib/:"${HERE}"/usr/lib/i386-linux-gnu/:"${HERE}"/usr/lib/x86_64-linux-gnu/:"${HERE}"/lib/:"${HERE}"/lib/i386-linux-gnu/:"${HERE}"/lib/x86_64-linux-gnu/:"${LD_LIBRARY_PATH}"
export PATH="${HERE}"/usr/bin/:"${HERE}"/usr/sbin/:"${HERE}"/usr/games/:"${HERE}"/bin/:"${HERE}"/sbin/:"${PATH}"
export PYTHONPATH="${HERE}"/usr/lib/python3/dist-packages/:"${HERE}"/usr/lib/python3.11/lib-dynload/:"${PYTHONPATH}"
export PYTHONHOME="${HERE}"/usr/
export XDG_DATA_DIRS="${HERE}"/usr/share/:"${XDG_DATA_DIRS}"
export PERLLIB="${HERE}"/usr/share/perl5/:"${HERE}"/usr/lib/perl5/:"${PERLLIB}"
export GSETTINGS_SCHEMA_DIR="${HERE}"/usr/share/glib-2.0/schemas/:"${GSETTINGS_SCHEMA_DIR}"
EXEC=$(grep -e '^Exec=.*' "${HERE}"/*.desktop | head -n 1 | cut -d "=" -f 2- | sed -e 's|%.||g')
$HERE/usr/bin/${EXEC}
EOF
	
# MADE THE APPRUN EXECUTABLE
chmod a+x ./"$APP".AppDir/AppRun
# END OF THE PART RELATED TO THE APPRUN, NOW WE WELL SEE IF EVERYTHING WORKS ----------------------------------------------------------------------

# IMPORT THE LAUNCHER AND THE ICON TO THE APPDIR IF THEY NOT EXIST
rm -f ./"$APP".AppDir/*.desktop
LAUNCHER=$(grep -iRl "$BIN" archlinux/.junest/usr/share/applications/* | grep ".desktop" | head -1)
cp -r "$LAUNCHER" "$APP".AppDir/
ICON=$(cat "$LAUNCHER" | grep "Icon=" | cut -c 6-)
[ -z "$ICON" ] && ICON="$BIN"
cp -r archlinux/.junest/usr/share/icons/*"$ICON"* "$APP".AppDir/ 2>/dev/null
cp -r archlinux/.junest/usr/share/icons/hicolor/22x22/apps/*"$ICON"* "$APP".AppDir/ 2>/dev/null
cp -r archlinux/.junest/usr/share/icons/hicolor/24x24/apps/*"$ICON"* "$APP".AppDir/ 2>/dev/null
cp -r archlinux/.junest/usr/share/icons/hicolor/32x32/apps/*"$ICON"* "$APP".AppDir/ 2>/dev/null
cp -r archlinux/.junest/usr/share/icons/hicolor/48x48/apps/*"$ICON"* "$APP".AppDir/ 2>/dev/null
cp -r archlinux/.junest/usr/share/icons/hicolor/64x64/apps/*"$ICON"* "$APP".AppDir/ 2>/dev/null
cp -r archlinux/.junest/usr/share/icons/hicolor/128x128/apps/*"$ICON"* "$APP".AppDir/ 2>/dev/null
cp -r archlinux/.junest/usr/share/icons/hicolor/192x192/apps/*"$ICON"* "$APP".AppDir/ 2>/dev/null
cp -r archlinux/.junest/usr/share/icons/hicolor/256x256/apps/*"$ICON"* "$APP".AppDir/ 2>/dev/null
cp -r archlinux/.junest/usr/share/icons/hicolor/512x512/apps/*"$ICON"* "$APP".AppDir/ 2>/dev/null
cp -r archlinux/.junest/usr/share/icons/hicolor/scalable/apps/*"$ICON"* "$APP".AppDir/ 2>/dev/null
cp -r archlinux/.junest/usr/share/pixmaps/*"$ICON"* "$APP".AppDir/ 2>/dev/null

# Test if the desktop file and the icon are in the root of the future appimage (./*appdir/*)
if test -f "$APP".AppDir/*.desktop; then
	echo "◆ The .desktop file is available in $APP.AppDir/"
elif test -f archlinux/.junest/usr/bin/"$BIN"; then
 	echo "◆ No .desktop file available for $APP, creating a new one"
 	cat <<-HEREDOC >> "$APP".AppDir/"$APP".desktop
	[Desktop Entry]
	Version=1.0
	Type=Application
	Name=$(echo "$APP" | tr '[:lower:]' '[:upper:]')
	Comment=
	Exec=$BIN
	Icon=tux
	Categories=Utility;
	Terminal=true
	StartupNotify=true
	HEREDOC
	curl -Lo "$APP".AppDir/tux.png https://raw.githubusercontent.com/Portable-Linux-Apps/Portable-Linux-Apps.github.io/main/favicon.ico 2>/dev/null
else
	echo "No binary in path... aborting all the processes."
	exit 0
fi

rsync -av ./base/ ./"$APP".AppDir/

# DEBLOAT PACKAGE
rm -Rf ./"$APP".AppDir/usr/lib/gcc
rm -Rf ./"$APP".AppDir/.*

#############################################################################
#	CREATE THE APPIMAGE
#############################################################################

if test -f ./*.AppImage; then rm -Rf ./*archimage*.AppImage; fi

APPNAME=$(cat ./"$APP".AppDir/*.desktop | grep 'Name=' | head -1 | cut -c 6- | sed 's/ /-/g')
REPO="Database-of-pkg2appimaged-packages"
TAG="gearlever"
VERSION="$VERSION"
UPINFO="gh-releases-zsync|$GITHUB_REPOSITORY_OWNER|$REPO|$TAG|*x86_64.AppImage.zsync"

ARCH=x86_64 ./appimagetool --comp zstd --mksquashfs-opt -Xcompression-level --mksquashfs-opt 20 \
	-u "$UPINFO" \
	./"$APP".AppDir "$APPNAME"_"$VERSION"-archimage4.3-x86_64.AppImage
