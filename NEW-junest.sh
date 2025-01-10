#!/usr/bin/env bash

APP=SAMPLE
BIN="$APP" #CHANGE THIS IF THE NAME OF THE BINARY IS DIFFERENT FROM "$APP" (for example, the binary of "obs-studio" is "obs")
DEPENDENCES="" #SYNTAX: "APP1 APP2 APP3 APP4...", LEAVE BLANK IF NO OTHER DEPENDENCES ARE NEEDED
#BASICSTUFF="binutils debugedit gzip"
#COMPILERS="base-devel"

#############################################################################
#	KEYWORDS TO FIND AND SAVE WHEN COMPILING THE APPIMAGE
#############################################################################

BINSAVED="SAVEBINSPLEASE"
SHARESAVED="SAVESHAREPLEASE"
#lib_audio_keywords="alsa jack pipewire pulse"
#lib_browser_launcher="gio-launch-desktop libdl.so libpthread.so librt.so libasound.so libX11-xcb.so libxapp-gtk3-module.so libgtk-3.so.0 pk p11"
LIBSAVED="SAVELIBSPLEASE $lib_audio_keywords $lib_browser_launcher"

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
mkdir -p "$APP".AppDir && cd "$APP".AppDir || exit 1

# Set the AppDir as a temporary $HOME directory
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
	_custom_mirrorlist
	_bypass_signature_check_level

	# Update arch linux in junest
	./.local/share/junest/bin/junest -- sudo pacman -Syy
	./.local/share/junest/bin/junest -- sudo pacman --noconfirm -Syu
}

_restore_junest() {
	cd ..
	echo "-----------------------------------------------------------------------------"
	echo " RESTORATION OF BACKUPS IN PROGRESS..."
	echo "-----------------------------------------------------------------------------"
	echo ""
	rsync -av ./junest-backups/ ./"$APP".AppDir/.junest/ | echo "◆ Restore the content of the Arch Linux container, please wait"
	[ -d ./"$APP".AppDir/.cache ] && rsync -av ./stock-cache/ ./"$APP".AppDir/.cache/ | echo "◆ Restore the content of JuNest's ~/.cache directory"
	rsync -av ./stock-local/ ./"$APP".AppDir/.local/ | echo "◆ Restore the content of JuNest's ~/.local directory"
	echo ""
	echo "-----------------------------------------------------------------------------"
	echo ""
	cd ./"$APP".AppDir || exit 1
}

if ! test -d "$HOME/.local/share/junest"; then
	_install_junest
else
	_restore_junest
fi

#############################################################################
#	INSTALL PROGRAMS USING YAY
#############################################################################

./.local/share/junest/bin/junest -- yay -Syy
#./.local/share/junest/bin/junest -- gpg --keyserver keyserver.ubuntu.com --recv-key C01E1CAD5EA2C4F0B8E3571504C367C218ADD4FF # UNCOMMENT IF YOU USE THE AUR
if [ -n "$BASICSTUFF" ]; then
	./.local/share/junest/bin/junest -- yay --noconfirm -S "$BASICSTUFF"
fi
if [ -n "$COMPILERS" ]; then
	./.local/share/junest/bin/junest -- yay --noconfirm -S "$COMPILERS"
fi
if [ -n "$DEPENDENCES" ]; then
	./.local/share/junest/bin/junest -- yay --noconfirm -S "$DEPENDENCES"
fi
if [ -n "$APP" ]; then
	./.local/share/junest/bin/junest -- yay --noconfirm -S alsa-lib gtk3 xapp
	./.local/share/junest/bin/junest -- yay --noconfirm -S "$APP"
	./.local/share/junest/bin/junest -- glib-compile-schemas /usr/share/glib-2.0/schemas/
else
	echo "No app found, exiting"; exit 1
fi

# Backup JuNest for furter tests
cd ..
echo ""
echo "-----------------------------------------------------------------------------"
echo " BACKUP OF JUNEST FOR FURTHER APPIMAGE BUILDING ATTEMPTS"
echo "-----------------------------------------------------------------------------"
mkdir -p ./junest-backups ./stock-cache ./stock-local
echo ""
rsync -av --ignore-existing ./"$APP".AppDir/.junest/ ./junest-backups/ | echo "◆ Backup the content of the Arch Linux container, please wait"
[ -d ./"$APP".AppDir/.cache ] && rsync -av --ignore-existing ./"$APP".AppDir/.cache/ ./stock-cache/ | echo "◆ Backup the content of JuNest's ~/.cache directory"
rsync -av --ignore-existing ./"$APP".AppDir/.local/ ./stock-local/ | echo "◆ Backup the content of JuNest's ~/.local directory"
echo ""
echo "-----------------------------------------------------------------------------"
cd ./"$APP".AppDir || exit 1

#############################################################################
#	LAUNCHER AND ICON / MADE JUNEST A PORTABLE CONTAINER
#############################################################################

# Set locale
rm -f ./.junest/etc/locale.conf
sed -i 's/LANG=${LANG:-C}/LANG=$LANG/g' ./.junest/etc/profile.d/locale.sh

# Add launcher and icon
rm -f ./*.desktop
LAUNCHER=$(grep -iRl "$BIN" ./.junest/usr/share/applications/* | grep ".desktop" | head -1)
cp -r "$LAUNCHER" ./
ICON=$(cat "$LAUNCHER" | grep "Icon=" | cut -c 6-)
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

# Test if the desktop file and the icon are in the root of the future appimage (./*appdir/*)
if test -f ./*.desktop; then
	echo "◆ The .desktop file is available in $APP.AppDir/"
elif test -f ./.junest/usr/bin/"$BIN"; then
 	echo ""
 	echo "◆ No .desktop file available for $APP, creating a new one..."
 	echo ""
 	cat <<-HEREDOC >> ./"$APP".desktop
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
	curl -Lo tux.png https://raw.githubusercontent.com/Portable-Linux-Apps/Portable-Linux-Apps.github.io/main/favicon.ico 2>/dev/null
else
	echo "No binary in path... aborting all the processes."
	exit 0
fi

# Made JuNest a portable app and remove "read-only file system" errors
sed -i 's#${JUNEST_HOME}/usr/bin/junest_wrapper#${HOME}/.cache/junest_wrapper.old#g' ./.local/share/junest/lib/core/wrappers.sh
sed -i 's/rm -f "${JUNEST_HOME}${bin_path}_wrappers/#rm -f "${JUNEST_HOME}${bin_path}_wrappers/g' ./.local/share/junest/lib/core/wrappers.sh
sed -i 's/ln/#ln/g' ./.local/share/junest/lib/core/wrappers.sh
sed -i 's/rm -f "$file"/test -f "$file"/g' ./.local/share/junest/lib/core/wrappers.sh
sed -i 's#--bind "$HOME" "$HOME"#--bind-try /home /home --bind-try /run/user /run/user#g' .local/share/junest/lib/core/namespace.sh

#############################################################################
#	APPRUN
#############################################################################

rm -f ./AppRun
cat <<-'HEREDOC' >> ./AppRun
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"
export UNION_PRELOAD="$HERE"
export JUNEST_HOME="$HERE"/.junest

if command -v unshare >/dev/null 2>&1 && ! unshare --user -p /bin/true >/dev/null 2>&1; then
   PROOT_ON=1
   export PATH="$HERE"/.local/share/junest/bin/:"$PATH"
   mkdir -p "$HOME"/.cache
else
   export PATH="$PATH":"$HERE"/.local/share/junest/bin
fi

[ -z "$NVIDIA_ON" ] && NVIDIA_ON=0
if [ "$NVIDIA_ON" = 1 ]; then
   DATADIR="${XDG_DATA_HOME:-$HOME/.local/share}"
   CONTY_DIR="${DATADIR}/Conty/overlayfs_shared"
   [ -f /sys/module/nvidia/version ] && nvidia_driver_version="$(cat /sys/module/nvidia/version)"
   if [ -n "$nvidia_driver_version" ]; then
      mkdir -p "${CONTY_DIR}"/nvidia "${CONTY_DIR}"/up/usr/lib "${CONTY_DIR}"/up/usr/share
      nvidia_data_dirs="egl glvnd nvidia vulkan"
      for d in $nvidia_data_dirs; do [ ! -d "${CONTY_DIR}"/up/usr/share/"$d" ] && ln -s /usr/share/"$d" "${CONTY_DIR}"/up/usr/share/ 2>/dev/null; done
      [ ! -f "${CONTY_DIR}"/nvidia/current-nvidia-version ] && echo "${nvidia_driver_version}" > "${CONTY_DIR}"/nvidia/current-nvidia-version
      [ -f "${CONTY_DIR}"/nvidia/current-nvidia-version ] && nvidia_driver_conty=$(cat "${CONTY_DIR}"/nvidia/current-nvidia-version)
      if [ "${nvidia_driver_version}" != "${nvidia_driver_conty}" ]; then
         rm -f "${CONTY_DIR}"/up/usr/lib/*; echo "${nvidia_driver_version}" > "${CONTY_DIR}"/nvidia/current-nvidia-version
      fi
      /sbin/ldconfig -p > "${CONTY_DIR}"/nvidia/host_libs
      grep -i "nvidia\|libcuda" "${CONTY_DIR}"/nvidia/host_libs | cut -d ">" -f 2 > "${CONTY_DIR}"/nvidia/host_nvidia_libs
      libnv_paths=$(grep "libnv" "${CONTY_DIR}"/nvidia/host_libs | cut -d ">" -f 2)
      for f in $libnv_paths; do strings "${f}" | grep -qi -m 1 "nvidia" && echo "${f}" >> "${CONTY_DIR}"/nvidia/host_nvidia_libs; done
      nvidia_libs=$(cat "${CONTY_DIR}"/nvidia/host_nvidia_libs)
      for n in $nvidia_libs; do libname=$(echo "$n" | sed 's:.*/::') && [ ! -f "${CONTY_DIR}"/up/usr/lib/"$libname" ] && cp "$n" "${CONTY_DIR}"/up/usr/lib/; done
      libvdpau_nvidia="${CONTY_DIR}/up/usr/lib/libvdpau_nvidia.so"
      if ! test -f "${libvdpau_nvidia}*"; then cp "$(find /usr/lib -type f -name 'libvdpau_nvidia.so*' -print -quit 2>/dev/null | head -1)" "${CONTY_DIR}"/up/usr/lib/; fi
      [ -f "${libvdpau_nvidia}"."${nvidia_driver_version}" ] && [ ! -f "${libvdpau_nvidia}" ] && ln -s "${libvdpau_nvidia}"."${nvidia_driver_version}" "${libvdpau_nvidia}"
      [ -d "${CONTY_DIR}"/up/usr/lib ] && export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}":"${CONTY_DIR}"/up/usr/lib:"${LD_LIBRARY_PATH}"
      [ -d "${CONTY_DIR}"/up/usr/share ] && export XDG_DATA_DIRS="${XDG_DATA_DIRS}":"${CONTY_DIR}"/up/usr/share:"${XDG_DATA_DIRS}"
   fi
fi

PROOT_BINDINGS=""
BWRAP_BINDINGS=""

bind_files="/etc/resolv.conf /etc/hosts /etc/nsswitch.conf /etc/passwd /etc/group /etc/machine-id /etc/asound.conf /etc/localtime "
for f in $bind_files; do [ -f "$f" ] && PROOT_BINDINGS=" $PROOT_BINDINGS --bind=$f" && BWRAP_BINDINGS=" $BWRAP_BINDINGS --ro-bind-try $f $f"; done

bind_dirs=" /media /mnt /opt /run/media /usr/lib/locale /usr/share/fonts /usr/share/themes /var"
for d in $bind_dirs; do [ -d "$d" ] && PROOT_BINDINGS=" $PROOT_BINDINGS --bind=$d" && BWRAP_BINDINGS=" $BWRAP_BINDINGS --bind-try $d $d"; done

PROOT_BINDS=" --bind=/dev --bind=/sys --bind=/tmp --bind=/proc $PROOT_BINDINGS --bind=/home --bind=/home/$USER "
BWRAP_BINDS=" --dev-bind /dev /dev --ro-bind /sys /sys --bind-try /tmp /tmp --proc /proc $BWRAP_BINDINGS "

_JUNEST_CMD() {
   if [ "$PROOT_ON" = 1 ]; then
      "$HERE"/.local/share/junest/bin/junest proot -n -b "$PROOT_BINDS" "$@"
   else
      "$HERE"/.local/share/junest/bin/junest -n -b "$BWRAP_BINDS" "$@"
   fi
}

EXEC=$(grep -e '^Exec=.*' "${HERE}"/*.desktop | head -n 1 | cut -d "=" -f 2- | sed -e 's|%.||g')

_JUNEST_CMD -- "$EXEC" "$@"

HEREDOC
chmod a+x ./AppRun

cd .. || exit 1

#############################################################################
#	EXTRACT PACKAGES
#############################################################################

# EXTRACT PACKAGES
_extract_main_package() {
	mkdir -p base
	rm -Rf ./base/*
	pkg_full_path=$(find ./"$APP".AppDir -type f -name "$APP-*zst")
	if [ "$(echo "$pkg_full_path" | wc -l)" = 1 ]; then
		pkg_full_path=$(find ./"$APP".AppDir -type f -name "$APP-*zst")
	else
		for p in $pkg_full_path; do
			if tar "$p" .PKGINFO -O | grep -q "pkgname = $APP$"; then
				pkg_full_path="$p"
			fi
		done
	fi
	[ -z "$pkg_full_path" ] && echo "💀 ERROR: no package found for \"$APP\", operation aborted!" && exit 0
	tar fx "$pkg_full_path" -C ./base/
	VERSION=$(cat ./base/.PKGINFO | grep pkgver | cut -c 10- | sed 's@.*:@@')
	mkdir -p deps
	rm -Rf ./deps/*
}

_download_missing_packages() {
	localpackage=$(find ./"$APP".AppDir -name "$arg-[0-9]*zst")
	if ! test -f "$localpackage"; then
		./"$APP".AppDir/.local/share/junest/bin/junest -- yay --noconfirm -Sw "$arg"
	fi
}

_extract_package() {
	_download_missing_packages &> /dev/null
	pkg_full_path=$(find ./"$APP".AppDir -name "$arg-[0-9]*zst")
	pkgname=$(echo "$pkg_full_path" | sed 's:.*/::')
	if test -f "$pkg_full_path"; then
		if ! grep -q "$pkgname" ./packages 2>/dev/null;then
			echo "◆ Extracting $pkgname"
			tar fx "$pkg_full_path" -C ./deps/ --warning=no-unknown-keyword
			echo "$pkgname" >> ./packages
		else
			tar fx "$pkg_full_path" -C ./deps/ --warning=no-unknown-keyword
			echo "$pkgname" >> ./packages
		fi
	fi
}

_determine_packages_and_libraries() {
	if echo "$arg" | grep -q "\.so"; then
		LIBSAVED="$LIBSAVED $arg"
	elif [ "$arg" != autoconf ] && [ "$arg" != autoconf ] && [ "$arg" != automake ] && [ "$arg" != bison ] && [ "$arg" != debugedit ] && [ "$arg" != dkms ] && [ "$arg" != fakeroot ] && [ "$arg" != flatpak ] && [ "$arg" != linux ] && [ "$arg" != gcc ] && [ "$arg" != make ] && [ "$arg" != pacman ] && [ "$arg" != patch ] && [ "$arg" != systemd ]; then
		_extract_package
		cat ./deps/.PKGINFO 2>/dev/null | grep "^depend = " | cut -c 10- | sed 's/=.*//' >> depdeps
		rm -f ./deps/.*
	fi
}

_extract_deps() {
	DEPS=$(sort -u ./depdeps)
	for arg in $DEPS; do
		_determine_packages_and_libraries
	done
}

_extract_all_dependences() {
	rm -f ./depdeps

	OPTDEPS=$(cat ./base/.PKGINFO 2>/dev/null | grep "^optdepend = " | sed 's/optdepend = //g' | sed 's/=.*//' | sed 's/:.*//')
	for arg in $OPTDEPS; do
		_determine_packages_and_libraries
	done
	[ -f ./depdeps ] && _extract_deps
	rm -f ./depdeps

	ARGS=$(echo "$DEPENDENCES" | tr " " "\n")
	for arg in $ARGS; do
		_determine_packages_and_libraries
	done

	DEPS=$(cat ./base/.PKGINFO 2>/dev/null | grep "^depend = " | sed 's/depend = //g' | sed 's/=.*//')
	for arg in $DEPS; do
		_determine_packages_and_libraries
	done

	_extract_deps

	rm -f ./packages
}

echo "-----------------------------------------------------------------------------"
echo " EXTRACTING DEPENDENCES"
echo "-----------------------------------------------------------------------------"
echo ""
_extract_main_package
_extract_all_dependences

# SAVE ESSENTIAL FILES AND LIBRARIES
echo ""
echo "-----------------------------------------------------------------------------"
echo " IMPLEMENTING NECESSARY LIBRARIES (MAY TAKE SEVERAL MINUTES)"
echo "-----------------------------------------------------------------------------"
echo ""

#############################################################################
#	SAVE FILES AND DIRECTORIES AND DETECT THE NEEDED LIBRARIES
#############################################################################

# Save files in /usr/bin
_savebins() {
	echo "◆ Saving files in /usr/bin"
	mkdir save
	mv ./"$APP".AppDir/.junest/usr/bin/bwrap ./save/
	mv ./"$APP".AppDir/.junest/usr/bin/proot* ./save/
	mv ./"$APP".AppDir/.junest/usr/bin/*$BIN* ./save/
	coreutils="[ basename cat chmod chown cp cut dir du echo env expand expr fold head id ln ls mkdir mv readlink realpath rm rmdir seq sleep sort stty sum sync tac tail tee test timeout touch tr true tty uname uniq wc who whoami yes"
	utils_bin="bash $coreutils grep ld sed sh"
	for b in $utils_bin; do
 		mv ./"$APP".AppDir/.junest/usr/bin/"$b" ./save/
   	done
	for arg in $BINSAVED; do
		mv ./"$APP".AppDir/.junest/usr/bin/*"$arg"* ./save/
	done
	rm -Rf ./"$APP".AppDir/.junest/usr/bin/*
	mv ./save/* ./"$APP".AppDir/.junest/usr/bin/
	rmdir save
}

# Save files in /usr/lib
_binlibs() {
	echo "◆ Saving libraries related to /usr/bin files"
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
		mv ./"$APP".AppDir/.junest/usr/lib/"$arg"* ./save/
		find ./"$APP".AppDir/.junest/usr/lib/ -name "$arg" -exec cp -r --parents -t save/ {} +
	done
	rm -Rf "$(find ./save/ | sort | grep ".AppDir" | head -1)"
	rm list
}

_include_swrast_dri() {
	mkdir ./save/dri
	mv ./"$APP".AppDir/.junest/usr/lib/dri/swrast_dri.so ./save/dri/
}

_libkeywords() {
	echo "◆ Saving libraries using keywords"
	for arg in $LIBSAVED; do
		mv ./"$APP".AppDir/.junest/usr/lib/*"$arg"* ./save/
	done
}

_readelf_save() {
	echo "◆ Saving libraries related to previously saved files"
	find_libs=$(find ./save -type f -name '*.so*' | uniq)
	for f in $find_libs; do
		readelf -d "$f" | grep .so | sed 's:.* ::' | cut -c 2- | sed 's/\(^.*so\).*$/\1/' | uniq >> ./list &
	done
	wait
	ARGS=$(tail -n +2 ./list | sort -u | uniq)
	for arg in $ARGS; do
		mv ./"$APP".AppDir/.junest/usr/lib/"$arg"* ./save/
		find ./"$APP".AppDir/.junest/usr/lib/ -name "$arg" -exec cp -r --parents -t save/ {} +
	done
	rsync -av ./save/"$APP".AppDir/.junest/usr/lib/ ./save/
 	rm -Rf "$(find ./save/ | sort | grep ".AppDir" | head -1)"
	rm list
}

_readelf_base() {
	echo "◆ Detect libraries of the main package"
	find_libs=$(find ./base -type f | uniq)
	for f in $find_libs; do
		readelf -d "$f" | grep .so | sed 's:.* ::' | cut -c 2- | sed 's/\(^.*so\).*$/\1/' | uniq >> ./list &
	done
	wait
}

_readelf_deps() {
	echo "◆ Detect libraries of the dependencies"
	find_libs=$(find ./deps -executable -type f | uniq)
	for f in $find_libs; do
		readelf -d "$f" | grep .so | sed 's:.* ::' | cut -c 2- | sed 's/\(^.*so\).*$/\1/' | uniq >> ./list &
	done
	wait
}

_liblibs() {
 	_readelf_base
  	_readelf_deps
	echo "◆ Saving libraries related to the previously extracted packages"
	ARGS=$(tail -n +2 ./list | sort -u | uniq)
	for arg in $ARGS; do
		mv ./"$APP".AppDir/.junest/usr/lib/"$arg"* ./save/
		find ./"$APP".AppDir/.junest/usr/lib/ -name "$arg" -exec cp -r --parents -t save/ {} +
	done
	rsync -av ./save/"$APP".AppDir/.junest/usr/lib/ ./save/
 	rm -Rf "$(find ./save/ | sort | grep ".AppDir" | head -1)"
	rm list
	_readelf_save
	_readelf_save
	_readelf_save
	_readelf_save
}

_mvlibs() {
	echo "◆ Restore saved libraries to /usr/lib"
	rm -Rf ./"$APP".AppDir/.junest/usr/lib/*
	mv ./save/* ./"$APP".AppDir/.junest/usr/lib/
}

_savelibs() {
	mkdir save
	#_binlibs 2> /dev/null
	#_include_swrast_dri 2> /dev/null
	#_libkeywords 2> /dev/null
	#_liblibs 2> /dev/null
	#_mvlibs 2> /dev/null
	rmdir save
}

# Save files in /usr/share
_saveshare() {
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
	rm -Rf ./"$APP".AppDir/.junest/usr/share/*
	mv ./save/* ./"$APP".AppDir/.junest/usr/share/
 	rmdir save
}

#_savebins 2> /dev/null
_savelibs
#_saveshare 2> /dev/null

# ASSEMBLING THE APPIMAGE PACKAGE
_rsync_main_package() {
	echo ""
	echo "-----------------------------------------------------------------------------"
	rm -Rf ./base/.*
	rsync -av ./base/ ./"$APP".AppDir/.junest/ | echo "◆ Rsync the content of the \"$APP\" package"
}

_rsync_dependences() {
	rm -Rf ./deps/.*
	#rsync -av ./deps/ ./"$APP".AppDir/.junest/ | echo "◆ Rsync all dependeces, please wait..."
	echo "-----------------------------------------------------------------------------"
	echo ""
}

#############################################################################
#	REMOVE BLOATWARES, ENABLE MOUNTPOINTS
#############################################################################

_remove_more_bloatwares() {
	echo Y | rm -Rf ./"$APP".AppDir/.cache/yay/*
	find ./"$APP".AppDir/.junest/usr/share/doc/* -not -iname "*$BIN*" -a -not -name "." -delete 2> /dev/null #REMOVE ALL DOCUMENTATION NOT RELATED TO THE APP
	find ./"$APP".AppDir/.junest/usr/share/locale/*/*/* -not -iname "*$BIN*" -a -not -name "." -delete 2> /dev/null #REMOVE ALL ADDITIONAL LOCALE FILES
	rm -Rf ./"$APP".AppDir/.junest/etc/makepkg.conf
	rm -Rf ./"$APP".AppDir/.junest/etc/pacman*
	rm -Rf ./"$APP".AppDir/.junest/usr/include # files related to the compiler
	rm -Rf ./"$APP".AppDir/.junest/usr/share/man # AppImages are not ment to have man command
	rm -Rf ./"$APP".AppDir/.junest/var/* # remove all packages downloaded with the package manager
 	rm -Rf ./"$APP".AppDir/.junest/home # remove the inbuilt home
	rm -Rf ./"$APP".AppDir/.junest/usr/bin/gcc* \
		./"$APP".AppDir/.junest/usr/lib/gcc* \
		./"$APP".AppDir/.junest/usr/share/gcc* # comment if you plan to use a compiler
	rm -Rf ./"$APP".AppDir/.junest/usr/lib/python*/__pycache__/* # if python is installed, removing this directory can save several megabytes
	#rm -Rf ./"$APP".AppDir/.junest/usr/lib/libLLVM* # included in the compilation phase, can sometimes be excluded for daily use
}

_enable_mountpoints_for_the_inbuilt_bubblewrap() {
	mkdir -p ./"$APP".AppDir/.junest/home
	mkdir -p ./"$APP".AppDir/.junest/media
	mkdir -p ./"$APP".AppDir/.junest/usr/lib/locale
	mkdir -p ./"$APP".AppDir/.junest/usr/share/fonts
	mkdir -p ./"$APP".AppDir/.junest/usr/share/themes
	mkdir -p ./"$APP".AppDir/.junest/run/media
	mkdir -p ./"$APP".AppDir/.junest/run/user
	rm -f ./"$APP".AppDir/.junest/etc/localtime && touch ./"$APP".AppDir/.junest/etc/localtime
	[ ! -f ./"$APP".AppDir/.junest/etc/asound.conf ] && touch ./"$APP".AppDir/.junest/etc/asound.conf
}

_rsync_main_package
_rsync_dependences
_remove_more_bloatwares
find ./"$APP".AppDir/.junest/usr/lib ./"$APP".AppDir/.junest/usr/lib32 -type f -regex '.*\.a' -exec rm -f {} \;
find ./"$APP".AppDir/.junest/usr -type f -regex '.*\.so.*' -exec strip --strip-debug {} \;
find ./"$APP".AppDir/.junest/usr/bin -type f ! -regex '.*\.so.*' -exec strip --strip-unneeded {} \;
_enable_mountpoints_for_the_inbuilt_bubblewrap

#############################################################################
#	CREATE THE APPIMAGE
#############################################################################

if test -f ./*.AppImage; then rm -Rf ./*archimage*.AppImage; fi

APPNAME=$(cat ./"$APP".AppDir/*.desktop | grep 'Name=' | head -1 | cut -c 6- | sed 's/ /-/g')
REPO="$APPNAME-appimage"
TAG="continuous"
VERSION="$VERSION"
UPINFO="gh-releases-zsync|$GITHUB_REPOSITORY_OWNER|$REPO|$TAG|*x86_64.AppImage.zsync"

ARCH=x86_64 ./appimagetool --comp zstd --mksquashfs-opt -Xcompression-level --mksquashfs-opt 20 \
	-u "$UPINFO" \
	./"$APP".AppDir "$APPNAME"_"$VERSION"-archimage4.2-x86_64.AppImage
