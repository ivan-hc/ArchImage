#!/usr/bin/env bash

##########################################################################################################################################################
#	USER'S SETTINGS
##########################################################################################################################################################

# Set the main package name for Arch Linux (APP), the binary name (BIN) and the dependencies (DEPENDENCES).
APP=SAMPLE
BIN="$APP" #CHANGE THIS IF THE NAME OF THE BINARY IS DIFFERENT FROM "$APP" (for example, the binary of "obs-studio" is "obs")
DEPENDENCES="" #SYNTAX: "APP1 APP2 APP3 APP4...", LEAVE BLANK IF NO OTHER DEPENDENCIES ARE NEEDED
#BASICSTUFF="binutils debugedit gzip"
#COMPILERS="base-devel"

# Set keywords to searchan include in names of directories and files in /usr/bin (BINSAVED), /usr/share (SHARESAVED) and /usr/lib (LIBSAVED)
BINSAVED="SAVEBINSPLEASE"
SHARESAVED="SAVESHAREPLEASE"
#lib_audio_keywords="alsa jack pipewire pulse"
#lib_browser_launcher="gio-launch-desktop libasound.so libatk-bridge libatspi libcloudproviders libdb- libdl.so libedit libepoxy libgtk-3.so.0 libjson-glib libnssutil libpthread.so librt.so libtinysparql libwayland-cursor libX11-xcb.so libxapp-gtk3-module.so libXcursor libXdamage libXi.so libxkbfile.so libXrandr p11 pk"
LIBSAVED="SAVELIBSPLEASE $lib_audio_keywords $lib_browser_launcher"
[ -n "$lib_browser_launcher" ] && DEPENDENCES="$DEPENDENCES xapp hicolor-icon-theme"

# Set the extraction level of dependencies to be included. The larger the number, the more packages will be included, increasing the size of the final AppImage.
#
# - extraction_count=0 means that no dependence will be included
# - extraction_count=1 (default) means that only dependencies of the main package will be inclided
# - extraction_count=2 means that also the dependencies of the dependencies will be included (this level often generates a large AppImage that may works out of the box)
# - extraction_count=3 means that also the dependencies of the dependencies of the dependencies will be included
#
# ...and so on, until the whole Arch Linux system will be included into a gigantic AppImage package.
extraction_count=1

# Set packages to be treated as if they were the main base package, syntax: "package1|package2|package3"
FORCE_PACKAGES="hicolor-icon-theme|xapp"

# Set the items you want to manually REMOVE in /etc, /usr/bin, /usr/lib and /usr/share respectively.
# The "rm" command will take into account the listed object/path and add an asterisk at the end, completing the path to be removed.
# Some keywords and paths are already set. Remove them if you consider them necessary for the AppImage to function properly.
ETC_REMOVED="makepkg.conf pacman"
BIN_REMOVED="gcc"
LIB_REMOVED="gcc python*/__pycache__/"
SHARE_REMOVED="gcc icons/AdwaitaLegacy icons/Adwaita/cursors/"

##########################################################################################################################################################
#	SETUP THE ENVIRONMENT
##########################################################################################################################################################

# Create and enter the AppDir
mkdir -p "$APP".AppDir archlinux && cd archlinux || exit 1

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
	printf -- "-----------------------------------------------------------------------------\n◆ Clone JuNest from https://github.com/fsquillace/junest\n-----------------------------------------------------------------------------\n"
	git clone https://github.com/fsquillace/junest.git ./.local/share/junest
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
	_JUNEST_CMD -- yay --noconfirm -S alsa-lib gtk3 xapp
	_JUNEST_CMD -- yay --noconfirm -S "$APP"
	# Use debloated gdk-pixbuf2
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

cd ..

printf -- "\n-----------------------------------------------------------------------------\n CREATING THE APPDIR\n-----------------------------------------------------------------------------\n"

# Set locale
rm -f archlinux/.junest/etc/locale.conf
sed -i 's/LANG=${LANG:-C}/LANG=$LANG/g' archlinux/.junest/etc/profile.d/locale.sh

# Add launcher and icon
rm -f "$APP".AppDir/*.desktop
LAUNCHER=$(grep -iRl "^Exec.*$BIN" archlinux/.junest/usr/share/applications/* | grep ".desktop" | head -1)
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
elif ! test -f archlinux/.junest/usr/bin/"$BIN"; then
 	echo "No binary in path... aborting all the processes."
	exit 0
fi

if [ ! -d "$APP".AppDir/.local ]; then
	mkdir -p "$APP".AppDir/.local
	rsync -av archlinux/.local/ "$APP".AppDir/.local/ | echo "◆ Rsync .local directory to the AppDir"
	# Made JuNest a portable app and remove "read-only file system" errors
	sed -i 's#${JUNEST_HOME}/usr/bin/junest_wrapper#${HOME}/.cache/junest_wrapper.old#g' "$APP".AppDir/.local/share/junest/lib/core/wrappers.sh
	sed -i 's/rm -f "${JUNEST_HOME}${bin_path}_wrappers/#rm -f "${JUNEST_HOME}${bin_path}_wrappers/g' "$APP".AppDir/.local/share/junest/lib/core/wrappers.sh
	sed -i 's/ln/#ln/g' "$APP".AppDir/.local/share/junest/lib/core/wrappers.sh
	sed -i 's/rm -f "$file"/test -f "$file"/g' "$APP".AppDir/.local/share/junest/lib/core/wrappers.sh
	sed -i 's#--bind "$HOME" "$HOME"#--bind-try /home /home --bind-try /run/user /run/user#g' "$APP".AppDir/.local/share/junest/lib/core/namespace.sh
fi

echo "◆ Rsync .junest directories structure to the AppDir"
rm -Rf "$APP".AppDir/.junest/*
archdirs=$(find archlinux/.junest -type d | sed 's/^archlinux\///g')
for d in $archdirs; do
	mkdir -p "$APP".AppDir/"$d"
done
symlink_dirs=" bin sbin lib lib64 usr/sbin usr/lib64"
for l in $symlink_dirs; do
	cp -r archlinux/.junest/"$l" "$APP".AppDir/.junest/"$l"
done

rsync -av archlinux/.junest/usr/bin_wrappers/ "$APP".AppDir/.junest/usr/bin_wrappers/ | echo "◆ Rsync bin_wrappers to the AppDir"
rsync -av archlinux/.junest/etc/* "$APP".AppDir/.junest/etc/ | echo "◆ Rsync /etc"

##########################################################################################################################################################
#	APPRUN
##########################################################################################################################################################

rm -f "$APP".AppDir/AppRun
cat <<-'HEREDOC' >> "$APP".AppDir/AppRun
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"
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
      mkdir -p "${CONTY_DIR}"/nvidia "${CONTY_DIR}"/up/usr/lib
      [ ! -f "${CONTY_DIR}"/nvidia/current-nvidia-version ] && echo "${nvidia_driver_version}" > "${CONTY_DIR}"/nvidia/current-nvidia-version
      [ -f "${CONTY_DIR}"/nvidia/current-nvidia-version ] && nvidia_driver_conty=$(cat "${CONTY_DIR}"/nvidia/current-nvidia-version)
      if [ "${nvidia_driver_version}" != "${nvidia_driver_conty}" ]; then
         rm -f "${CONTY_DIR}"/up/usr/lib/*; echo "${nvidia_driver_version}" > "${CONTY_DIR}"/nvidia/current-nvidia-version
      fi
      /sbin/ldconfig -p > "${CONTY_DIR}"/nvidia/host_libs
      grep -i "nvidia\|libcuda" "${CONTY_DIR}"/nvidia/host_libs | cut -d ">" -f 2 > "${CONTY_DIR}"/nvidia/host_nvidia_libs
      libnv_paths=$(grep "libnv" "${CONTY_DIR}"/nvidia/host_libs | cut -d ">" -f 2)
      for f in $libnv_paths; do
         strings "${f}" | grep -qi -m 1 "nvidia" && echo "${f}" >> "${CONTY_DIR}"/nvidia/host_nvidia_libs
      done
      nvidia_libs=$(cat "${CONTY_DIR}"/nvidia/host_nvidia_libs)
      for n in $nvidia_libs; do
         libname=$(echo "$n" | sed 's:.*/::') && [ ! -f "${CONTY_DIR}"/up/usr/lib/"$libname" ] && cp "$n" "${CONTY_DIR}"/up/usr/lib/
      done
      libvdpau_nvidia="${CONTY_DIR}/up/usr/lib/libvdpau_nvidia.so"
      if ! test -f "${libvdpau_nvidia}*"; then
         cp "$(find /usr/lib -type f -name 'libvdpau_nvidia.so*' -print -quit 2>/dev/null | head -1)" "${CONTY_DIR}"/up/usr/lib/
      fi
      [ -f "${libvdpau_nvidia}"."${nvidia_driver_version}" ] && [ ! -f "${libvdpau_nvidia}" ] && ln -s "${libvdpau_nvidia}"."${nvidia_driver_version}" "${libvdpau_nvidia}"
      [ -d "${CONTY_DIR}"/up/usr/lib ] && export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}":"${CONTY_DIR}"/up/usr/lib:"${LD_LIBRARY_PATH}"
   fi
fi

PROOT_BINDINGS=""
BWRAP_BINDINGS=""

bind_files="/etc/resolv.conf /etc/hosts /etc/nsswitch.conf /etc/passwd /etc/group /etc/machine-id /etc/asound.conf /etc/localtime "
for f in $bind_files; do
   [ -f "$f" ] && PROOT_BINDINGS=" $PROOT_BINDINGS --bind=$f" && BWRAP_BINDINGS=" $BWRAP_BINDINGS --ro-bind-try $f $f"
done

bind_nvidia_data_dirs="/usr/share/egl /usr/share/glvnd /usr/share/nvidia /usr/share/vulkan"
bind_dirs=" /media /mnt /opt /run/media /usr/lib/locale /usr/share/fonts /usr/share/themes /var $bind_nvidia_data_dirs"
for d in $bind_dirs; do
   [ -d "$d" ] && PROOT_BINDINGS=" $PROOT_BINDINGS --bind=$d" && BWRAP_BINDINGS=" $BWRAP_BINDINGS --bind-try $d $d"
done

PROOT_BINDS=" --bind=/dev --bind=/sys --bind=/tmp --bind=/proc $PROOT_BINDINGS --bind=/home --bind=/home/$USER "
BWRAP_BINDS=" --dev-bind /dev /dev --ro-bind /sys /sys --bind-try /tmp /tmp --proc /proc $BWRAP_BINDINGS --cap-add CAP_SYS_ADMIN "

_JUNEST_CMD() {
   if [ "$PROOT_ON" = 1 ]; then
      "$HERE"/.local/share/junest/bin/junest proot -n -b "$PROOT_BINDS" "$@"
   else
      "$HERE"/.local/share/junest/bin/junest -n -b "$BWRAP_BINDS" "$@"
   fi
}

EXEC=$(grep -e '^Exec=.*' "${HERE}"/*.desktop | head -n 1 | cut -d "=" -f 2- | sed -e 's|%.||g')
if ! echo "$EXEC" | grep -q "/usr/bin"; then
   EXEC="/usr/bin/$EXEC"
fi

_JUNEST_CMD -- $EXEC "$@"

HEREDOC
chmod a+x "$APP".AppDir/AppRun

##########################################################################################################################################################
#	EXTRACT PACKAGES
##########################################################################################################################################################

[ ! -f ./autodeps ] && echo "$extraction_count" > ./autodeps
[ -f ./autodeps ] && autodeps=$(cat ./autodeps)
[ "$autodeps" != "$extraction_count" ] && rm -Rf ./deps ./packages && echo "$extraction_count" > ./autodeps

[ ! -f ./userdeps ] && echo "$DEPENDENCES" > ./userdeps
[ -f ./userdeps ] && userdeps=$(cat ./userdeps)
[ "$userdeps" != "$DEPENDENCES" ] && rm -Rf ./deps ./packages && echo "$DEPENDENCES" > ./userdeps

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
	mkdir -p deps
}

_download_missing_packages() {
	localpackage=$(find ./archlinux -name "$arg-[0-9]*zst")
	if ! test -f "$localpackage"; then
		./archlinux/.local/share/junest/bin/junest -- yay --noconfirm -Sw "$arg"
	fi
}

_extract_package() {
	_download_missing_packages &> /dev/null
	pkg_full_path=$(find ./archlinux -name "$arg-[0-9]*zst")
	pkgname=$(echo "$pkg_full_path" | sed 's:.*/::')
	[ ! -f ./packages ] && rm -Rf ./deps/* && touch ./packages
	if [ -z "$( ls -A './deps' )" ]; then
		rm -f ./packages
		printf -- "\n-----------------------------------------------------------------------------\n EXTRACTING PACKAGES\n-----------------------------------------------------------------------------\n"
	fi
	if test -f "$pkg_full_path"; then
		if ! grep -q "$pkgname" ./packages 2>/dev/null;then
			echo "◆ Extracting $pkgname"
			tar fx "$pkg_full_path" -C ./deps/ --warning=no-unknown-keyword
			echo "$pkgname" >> ./packages
		fi
		[[ "$arg" =~ ($FORCE_PACKAGES) ]] && tar fx "$pkg_full_path" -C ./base/ --warning=no-unknown-keyword --exclude='.PKGINFO'
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

_extract_all_dependencies() {
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

	# Set the level of sub-dependencies extraction, the higher the number, the bigger the AppImage will be
	if [ "$extraction_count" != 0 ]; then
		for e in $(seq "$extraction_count"); do _extract_deps; done
	fi
}

_extract_main_package
_extract_all_dependencies

printf -- "\n-----------------------------------------------------------------------------\n IMPLEMENTING NECESSARY LIBRARIES (MAY TAKE SEVERAL MINUTES)\n-----------------------------------------------------------------------------\n"

# Save files in /usr/bin
_savebins() {
	echo "◆ Saving files in /usr/bin"
	cp -r ./archlinux/.junest/usr/bin/bwrap ./"$APP".AppDir/.junest/usr/bin/
	cp -r ./archlinux/.junest/usr/bin/proot* ./"$APP".AppDir/.junest/usr/bin/
	cp -r ./archlinux/.junest/usr/bin/*$BIN* ./"$APP".AppDir/.junest/usr/bin/
	coreutils="[ basename cat chmod chown cp cut dir dirname du echo env expand expr fold head id ln ls mkdir mv readlink realpath rm rmdir seq sleep sort stty sum sync tac tail tee test timeout touch tr true tty uname uniq wc who whoami yes"
	utils_bin="awk bash $coreutils gawk gio grep ld ldd sed sh strings xdg-open"
	for b in $utils_bin; do
 		cp -r ./archlinux/.junest/usr/bin/"$b" ./"$APP".AppDir/.junest/usr/bin/
   	done
	for arg in $BINSAVED; do
		cp -r ./archlinux/.junest/usr/bin/*"$arg"* ./"$APP".AppDir/.junest/usr/bin/
	done
}

# Save files in /usr/lib
_savelibs() {
	echo "◆ Detect libraries related to /usr/bin files"
	libs4bin=$(readelf -d ./"$APP".AppDir/.junest/usr/bin/* 2>/dev/null | grep NEEDED | tr '[] ' '\n' | grep ".so")

	echo "◆ Saving JuNest core libraries"
	cp -r ./archlinux/.junest/usr/lib/ld-linux-x86-64.so* ./"$APP".AppDir/.junest/usr/lib/
	lib_preset="$APP $BIN gconv libcurl libdw libelf libresolv.so libtinfo.so profile.d $libs4bin"
	LIBSAVED="$lib_preset $LIBSAVED $SHARESAVED"
	for arg in $LIBSAVED; do
		LIBPATHS="$LIBPATHS $(find ./archlinux/.junest/usr/lib -maxdepth 20 -wholename "*$arg*" | sed 's/\.\/archlinux\///g')"
	done
	for arg in $LIBPATHS; do
		[ ! -d "$APP".AppDir/"$arg" ] && cp -r ./archlinux/"$arg" "$APP".AppDir/"$arg" &
	done
	wait
	core_libs=$(find ./"$APP".AppDir -type f)
	lib_core=$(for c in $core_libs; do readelf -d "$c" 2>/dev/null | grep NEEDED | tr '[] ' '\n' | grep ".so"; done)

	echo "◆ Detect libraries of the main package"
	base_libs=$(find ./base -type f | uniq)
	lib_base_0=$(for b in $base_libs; do readelf -d "$b" 2>/dev/null | grep NEEDED | tr '[] ' '\n' | grep ".so"; done)

	echo "◆ Detect libraries of the dependencies"
	dep_libs=$(find ./deps -executable -name "*.so*")
	lib_deps=$(for d in $dep_libs; do readelf -d "$d" 2>/dev/null | grep NEEDED | tr '[] ' '\n' | grep ".so"; done)

	echo "◆ Detect and copy base libs"
	basebin_libs=$(find ./base -executable -name "*.so*")
	lib_base_1=$(for b in $basebin_libs; do readelf -d "$b" 2>/dev/null | grep NEEDED | tr '[] ' '\n' | grep ".so"; done)
	lib_base_1=$(echo "$lib_base_1" | tr ' ' '\n' | sort -u | xargs)
	lib_base_2=$(for b in $lib_base_1; do readelf -d ./archlinux/.junest/usr/lib/"$b" 2>/dev/null | grep NEEDED | tr '[] ' '\n' | grep ".so"; done)
	lib_base_2=$(echo "$lib_base_2" | tr ' ' '\n' | sort -u | xargs)
	lib_base_3=$(for b in $lib_base_2; do readelf -d ./archlinux/.junest/usr/lib/"$b" 2>/dev/null | grep NEEDED | tr '[] ' '\n' | grep ".so"; done)
	lib_base_3=$(echo "$lib_base_3" | tr ' ' '\n' | sort -u | xargs)
	lib_base_4=$(for b in $lib_base_3; do readelf -d ./archlinux/.junest/usr/lib/"$b" 2>/dev/null | grep NEEDED | tr '[] ' '\n' | grep ".so"; done)
	lib_base_4=$(echo "$lib_base_4" | tr ' ' '\n' | sort -u | xargs)
	lib_base_5=$(for b in $lib_base_4; do readelf -d ./archlinux/.junest/usr/lib/"$b" 2>/dev/null | grep NEEDED | tr '[] ' '\n' | grep ".so"; done)
	lib_base_5=$(echo "$lib_base_5" | tr ' ' '\n' | sort -u | xargs)
	lib_base_6=$(for b in $lib_base_5; do readelf -d ./archlinux/.junest/usr/lib/"$b" 2>/dev/null | grep NEEDED | tr '[] ' '\n' | grep ".so"; done)
	lib_base_6=$(echo "$lib_base_6" | tr ' ' '\n' | sort -u | xargs)
	lib_base_7=$(for b in $lib_base_6; do readelf -d ./archlinux/.junest/usr/lib/"$b" 2>/dev/null | grep NEEDED | tr '[] ' '\n' | grep ".so"; done)
	lib_base_7=$(echo "$lib_base_7" | tr ' ' '\n' | sort -u | xargs)
	lib_base_8=$(for b in $lib_base_7; do readelf -d ./archlinux/.junest/usr/lib/"$b" 2>/dev/null | grep NEEDED | tr '[] ' '\n' | grep ".so"; done)
	lib_base_8=$(echo "$lib_base_8" | tr ' ' '\n' | sort -u | xargs)
	lib_base_9=$(for b in $lib_base_8; do readelf -d ./archlinux/.junest/usr/lib/"$b" 2>/dev/null | grep NEEDED | tr '[] ' '\n' | grep ".so"; done)
	lib_base_9=$(echo "$lib_base_9" | tr ' ' '\n' | sort -u | xargs)
	lib_base_libs="$lib_core $lib_base_0 $lib_base_1 $lib_base_2 $lib_base_3 $lib_base_4 $lib_base_5 $lib_base_6 $lib_base_7 $lib_base_8 $lib_base_9 $lib_deps"
	lib_base_libs=$(echo "$lib_base_libs" | tr ' ' '\n' | sort -u | sed 's/.so.*/.so/' | xargs)
	for l in $lib_base_libs; do
		rsync -av ./archlinux/.junest/usr/lib/"$l"* ./"$APP".AppDir/.junest/usr/lib/ &
	done
	wait
	for l in $lib_base_libs; do
		rsync -av ./deps/usr/lib/"$l"* ./"$APP".AppDir/.junest/usr/lib/ &
	done
	wait
}

# Save files in /usr/share
_saveshare() {
	echo "◆ Saving directories in /usr/share"
	SHARESAVED="$SHARESAVED $APP $BIN fontconfig glib- locale mime wayland X11"
	for arg in $SHARESAVED; do
		cp -r ./archlinux/.junest/usr/share/*"$arg"* ./"$APP".AppDir/.junest/usr/share/
 	done
}

_savebins 2>/dev/null
_savelibs 2>/dev/null
_saveshare 2>/dev/null

printf -- "\n-----------------------------------------------------------------------------\n ASSEMBLING THE APPIMAGE\n-----------------------------------------------------------------------------\n"

_rsync_main_package() {
	rm -Rf ./base/.*
	rsync -av ./base/ ./"$APP".AppDir/.junest/ | echo "◆ Rsync the content of the \"$APP\" package"
}

_rsync_dependencies() {
	rm -Rf ./deps/.*
	chmod -R 777 ./deps/*
	#rsync -av ./deps/ ./"$APP".AppDir/.junest/ | echo "◆ Rsync all dependencies, please wait"
}

_rsync_main_package
_rsync_dependencies

##########################################################################################################################################################
#	REMOVE BLOATWARES, ENABLE MOUNTPOINTS
##########################################################################################################################################################

_remove_more_bloatwares() {
	for r in $ETC_REMOVED; do rm -Rf ./"$APP".AppDir/.junest/etc/"$r"*; done
	for r in $BIN_REMOVED; do rm -Rf ./"$APP".AppDir/.junest/usr/bin/"$r"*; done
	for r in $LIB_REMOVED; do rm -Rf ./"$APP".AppDir/.junest/usr/lib/"$r"*; done
	for r in $SHARE_REMOVED; do rm -Rf ./"$APP".AppDir/.junest/usr/share/"$r"*; done
	echo Y | rm -Rf ./"$APP".AppDir/.cache/yay/*
	find ./"$APP".AppDir/.junest/usr/share/doc/* -not -iname "*$BIN*" -a -not -name "." -delete 2> /dev/null #REMOVE ALL DOCUMENTATION NOT RELATED TO THE APP
	find ./"$APP".AppDir/.junest/usr/share/locale/*/*/* -not -iname "*$BIN*" -a -not -name "." -delete 2> /dev/null #REMOVE ALL ADDITIONAL LOCALE FILES
	rm -Rf ./"$APP".AppDir/.junest/home # remove the inbuilt home
	rm -Rf ./"$APP".AppDir/.junest/usr/include # files related to the compiler
	rm -Rf ./"$APP".AppDir/.junest/usr/share/man # AppImages are not ment to have man command
	#rm -Rf ./"$APP".AppDir/.junest/usr/lib/libgallium*
	#rm -Rf ./"$APP".AppDir/.junest/usr/lib/libgo.so*
	#rm -Rf ./"$APP".AppDir/.junest/usr/lib/libLLVM* # included in the compilation phase, can sometimes be excluded for daily use
	rm -Rf ./"$APP".AppDir/.junest/var/* # remove all packages downloaded with the package manager
}

_enable_mountpoints_for_the_inbuilt_bubblewrap() {
	mkdir -p ./"$APP".AppDir/.junest/home
	mkdir -p ./"$APP".AppDir/.junest/media
	mkdir -p ./"$APP".AppDir/.junest/usr/lib/locale
	share_dirs="egl fonts glvnd nvidia themes vulkan"
	for d in $share_dirs; do mkdir -p ./"$APP".AppDir/.junest/usr/share/"$d"; done
	mkdir -p ./"$APP".AppDir/.junest/run/media
	mkdir -p ./"$APP".AppDir/.junest/run/user
	rm -f ./"$APP".AppDir/.junest/etc/localtime && touch ./"$APP".AppDir/.junest/etc/localtime
	[ ! -f ./"$APP".AppDir/.junest/etc/asound.conf ] && touch ./"$APP".AppDir/.junest/etc/asound.conf
	[ ! -e ./"$APP".AppDir/.junest/usr/share/X11/xkb ] && rm -f ./"$APP".AppDir/.junest/usr/share/X11/xkb && mkdir -p ./"$APP".AppDir/.junest/usr/share/X11/xkb && sed -i -- 's# /var"$# /usr/share/X11/xkb /var"#g' ./"$APP".AppDir/AppRun
}

_remove_more_bloatwares
find ./"$APP".AppDir/.junest/usr/lib ./"$APP".AppDir/.junest/usr/lib32 -type f -regex '.*\.a' -exec rm -f {} \; 2>/dev/null
find ./"$APP".AppDir/.junest/usr -type f -regex '.*\.so.*' -exec strip --strip-debug {} \;
find ./"$APP".AppDir/.junest/usr/bin -type f ! -regex '.*\.so.*' -exec strip --strip-unneeded {} \;
find ./"$APP".AppDir/.junest/usr -type d -empty -delete
_enable_mountpoints_for_the_inbuilt_bubblewrap

##########################################################################################################################################################
#	CREATE THE APPIMAGE
##########################################################################################################################################################

if test -f ./*.AppImage; then rm -Rf ./*archimage*.AppImage; fi

APPNAME=$(cat ./"$APP".AppDir/*.desktop | grep '^Name=' | head -1 | cut -c 6- | sed 's/ /-/g')
REPO="$APPNAME-appimage"
TAG="continuous"
VERSION="$VERSION"
UPINFO="gh-releases-zsync|$GITHUB_REPOSITORY_OWNER|$REPO|$TAG|*x86_64.AppImage.zsync"

_appimagetool() {
	if ! command -v appimagetool 1>/dev/null; then
		if [ ! -f ./appimagetool ]; then
			echo " Downloading appimagetool..." && curl -#Lo appimagetool https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-"$ARCH".AppImage && chmod a+x ./appimagetool || exit 1
		fi
		./appimagetool "$@"
	else
		appimagetool "$@"
	fi
}

ARCH=x86_64 _appimagetool -u "$UPINFO" \
	./"$APP".AppDir "$APPNAME"_"$VERSION"-archimage4.3.1-x86_64.AppImage
