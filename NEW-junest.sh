#!/usr/bin/env bash

APP=SAMPLE
BIN="$APP" #CHANGE THIS IF THE NAME OF THE BINARY IS DIFFERENT FROM "$APP" (for example, the binary of "obs-studio" is "obs")
DEPENDENCES="" #SYNTAX: "APP1 APP2 APP3 APP4...", LEAVE BLANK IF NO OTHER DEPENDENCIES ARE NEEDED
#BASICSTUFF="binutils debugedit gzip"
#COMPILERS="base-devel"

# Set keywords to searchan include in names of directories and files in /usr/bin (BINSAVED), /usr/share (SHARESAVED) and /usr/lib (LIBSAVED)
BINSAVED="SAVEBINSPLEASE"
SHARESAVED="SAVESHAREPLEASE"
lib_browser_launcher="gio-launch-desktop libasound.so libatk-bridge libatspi libcloudproviders libdb- libdl.so libedit libepoxy libgtk-3.so.0 libjson-glib libnssutil libpthread.so librt.so libtinysparql libwayland-cursor libX11-xcb.so libxapp-gtk3-module.so libXcursor libXdamage libXi.so libxkbfile.so libXrandr p11 pk"
LIBSAVED="SAVELIBSPLEASE $lib_browser_launcher"

# Set the items you want to manually REMOVE in /etc, /usr/bin, /usr/lib and /usr/share respectively.
# The "rm" command will take into account the listed object/path and add an asterisk at the end, completing the path to be removed.
# Some keywords and paths are already set. Remove them if you consider them necessary for the AppImage to function properly.
ETC_REMOVED="makepkg.conf pacman"
BIN_REMOVED="gcc"
LIB_REMOVED="gcc"
PYTHON_REMOVED="__pycache__/"
SHARE_REMOVED="gcc icons/AdwaitaLegacy icons/Adwaita/cursors/ terminfo"

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
mkdir -p AppDir archlinux && cd archlinux || exit 1

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
	_JUNEST_CMD -- yay --noconfirm -S alsa-lib gtk3 hicolor-icon-theme xapp xdg-utils xorg-server-xvfb
	_JUNEST_CMD -- yay --noconfirm -S "$APP"
	VERSION="$(_JUNEST_CMD -- yay -Q "$APP" | awk '{print $2; exit}')"
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

cd ..

printf -- "\n-----------------------------------------------------------------------------\n CREATING THE APPDIR\n-----------------------------------------------------------------------------\n\n"

# Set locale
rm -f archlinux/.junest/etc/locale.conf
sed -i 's/LANG=${LANG:-C}/LANG=$LANG/g' archlinux/.junest/etc/profile.d/locale.sh

# Add launcher and icon
rm -f AppDir/*.desktop
LAUNCHER=$(grep -iRl "^Exec.*$BIN" archlinux/.junest/usr/share/applications/* | grep ".desktop" | head -1)
cp -r "$LAUNCHER" AppDir/
ICON=$(cat "$LAUNCHER" | grep "Icon=" | cut -c 6-)
[ -z "$ICON" ] && ICON="$BIN"
cp -r archlinux/.junest/usr/share/icons/*"$ICON"* AppDir/ 2>/dev/null
cp -r archlinux/.junest/usr/share/icons/hicolor/22x22/apps/*"$ICON"* AppDir/ 2>/dev/null
cp -r archlinux/.junest/usr/share/icons/hicolor/24x24/apps/*"$ICON"* AppDir/ 2>/dev/null
cp -r archlinux/.junest/usr/share/icons/hicolor/32x32/apps/*"$ICON"* AppDir/ 2>/dev/null
cp -r archlinux/.junest/usr/share/icons/hicolor/48x48/apps/*"$ICON"* AppDir/ 2>/dev/null
cp -r archlinux/.junest/usr/share/icons/hicolor/64x64/apps/*"$ICON"* AppDir/ 2>/dev/null
cp -r archlinux/.junest/usr/share/icons/hicolor/128x128/apps/*"$ICON"* AppDir/ 2>/dev/null
cp -r archlinux/.junest/usr/share/icons/hicolor/192x192/apps/*"$ICON"* AppDir/ 2>/dev/null
cp -r archlinux/.junest/usr/share/icons/hicolor/256x256/apps/*"$ICON"* AppDir/ 2>/dev/null
cp -r archlinux/.junest/usr/share/icons/hicolor/512x512/apps/*"$ICON"* AppDir/ 2>/dev/null
cp -r archlinux/.junest/usr/share/icons/hicolor/scalable/apps/*"$ICON"* AppDir/ 2>/dev/null
cp -r archlinux/.junest/usr/share/pixmaps/*"$ICON"* AppDir/ 2>/dev/null

# Test if the desktop file and the icon are in the root of the future appimage (./*appdir/*)
if test -f AppDir/*.desktop; then
	echo "◆ The .desktop file is available in $APP.AppDir/"
elif ! test -f archlinux/.junest/usr/bin/"$BIN"; then
 	echo "No binary in path... aborting all the processes."
	exit 0
fi

if [ ! -d AppDir/.local ]; then
	mkdir -p AppDir/.local
	rsync -av archlinux/.local/ AppDir/.local/ | echo "◆ Rsync .local directory to the AppDir"
	# Made JuNest a portable app and remove "read-only file system" errors
	sed -i 's#${JUNEST_HOME}/usr/bin/junest_wrapper#${HOME}/.cache/junest_wrapper.old#g' AppDir/.local/share/junest/lib/core/wrappers.sh
	sed -i 's/rm -f "${JUNEST_HOME}${bin_path}_wrappers/#rm -f "${JUNEST_HOME}${bin_path}_wrappers/g' AppDir/.local/share/junest/lib/core/wrappers.sh
	sed -i 's/ln/#ln/g' AppDir/.local/share/junest/lib/core/wrappers.sh
	sed -i 's/rm -f "$file"/test -f "$file"/g' AppDir/.local/share/junest/lib/core/wrappers.sh
	sed -i 's#--bind "$HOME" "$HOME"#--bind-try /home /home --bind-try /run/user /run/user#g' AppDir/.local/share/junest/lib/core/namespace.sh
fi

echo "◆ Rsync .junest directories structure to the AppDir"
rm -Rf AppDir/.junest/*
archdirs=$(find archlinux/.junest -type d | sed 's/^archlinux\///g')
for d in $archdirs; do
	mkdir -p AppDir/"$d"
done
symlink_dirs=" bin sbin lib lib64 usr/sbin usr/lib64"
for l in $symlink_dirs; do
	cp -r archlinux/.junest/"$l" AppDir/.junest/"$l"
done

rsync -av archlinux/.junest/usr/bin_wrappers/ AppDir/.junest/usr/bin_wrappers/ | echo "◆ Rsync bin_wrappers to the AppDir"
rsync -av archlinux/.junest/etc/* AppDir/.junest/etc/ | echo "◆ Rsync /etc"

##########################################################################################################################################################
#	APPRUN
##########################################################################################################################################################

rm -f AppDir/AppRun
cat <<-'HEREDOC' >> AppDir/AppRun
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
chmod a+x AppDir/AppRun

##########################################################################################################################################################
#	DEPLOY DEPENDENCIES
##########################################################################################################################################################

printf -- "\n-----------------------------------------------------------------------------\n IMPLEMENTING APP'S SPECIFIC LIBRARIES (SHARUN)\n-----------------------------------------------------------------------------\n"

_run_quick_sharun() {
	cd archlinux || exit 1
	SHARUN="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/quick-sharun.sh"

	if [ ! -f ./quick-sharun ]; then
		wget --retry-connrefused --tries=30 "$SHARUN" -O ./quick-sharun || exit 1
		chmod +x ./quick-sharun
	fi

	_JUNEST_CMD -- ./quick-sharun /usr/bin/"$BIN"

	cd .. || exit 1
	echo "$DEPENDENCES" > ./deps
	[ ! -f ./deps ] && touch ./deps
	printf "\n-----------------------------------------------------------------------------\n"
}

if [ ! -f ./deps ]; then
	_run_quick_sharun
	echo "$DEPENDENCES" > ./deps
elif [ -f ./deps ]; then
	DEPENDENCES0=$(cat ./deps)
	if [ "$DEPENDENCES0" != "$DEPENDENCES" ]; then
		_run_quick_sharun
	fi
fi

rsync -av archlinux/AppDir/etc/* AppDir/.junest/etc/ | printf "\n◆ Saving /etc" 
rsync -av archlinux/AppDir/bin/* AppDir/.junest/usr/bin/ | printf "\n◆ Saving /usr/bin"
rsync -av archlinux/AppDir/lib/* AppDir/.junest/usr/lib/ | printf "\n◆ Saving /usr/lib"
rsync -av archlinux/AppDir/share/* AppDir/.junest/usr/share/ | printf "\n◆ Saving /usr/share\n"

printf -- "\n-----------------------------------------------------------------------------\n IMPLEMENTING USER'S SELECTED FILES AND DIRECTORIES\n-----------------------------------------------------------------------------\n\n"

# Save files in /usr/bin
_savebins() {
	echo "◆ Saving files in /usr/bin"
	cp -r ./archlinux/.junest/usr/bin/bwrap AppDir/.junest/usr/bin/
	cp -r ./archlinux/.junest/usr/bin/proot* AppDir/.junest/usr/bin/
	cp -r ./archlinux/.junest/usr/bin/*$BIN* AppDir/.junest/usr/bin/
	cp -r ./archlinux/.junest/usr/bin/gio* AppDir/.junest/usr/bin/
	cp -r ./archlinux/.junest/usr/bin/xdg-* AppDir/.junest/usr/bin/
	coreutils="[ basename cat chmod chown cp cut dir dirname du echo env expand expr fold head id ln ls mkdir mv readlink realpath rm rmdir seq sleep sort stty sum sync tac tail tee test timeout touch tr true tty uname uniq wc who whoami yes"
	utils_bin="awk bash $coreutils gawk gio grep ld ldd sed sh strings"
	for b in $utils_bin; do
 		cp -r ./archlinux/.junest/usr/bin/"$b" AppDir/.junest/usr/bin/
   	done
	for arg in $BINSAVED; do
		cp -r ./archlinux/.junest/usr/bin/*"$arg"* AppDir/.junest/usr/bin/
	done
}

# Save files in /usr/lib
_savelibs() {
	echo "◆ Detect libraries related to /usr/bin files"
	libs4bin=$(readelf -d AppDir/.junest/usr/bin/* 2>/dev/null | grep NEEDED | tr '[] ' '\n' | grep ".so")

	echo "◆ Saving JuNest core libraries"
	cp -r ./archlinux/.junest/usr/lib/ld-linux-x86-64.so* AppDir/.junest/usr/lib/
	lib_preset="$APP $BIN libdw libelf libresolv.so libtinfo.so profile.d $libs4bin"
	LIBSAVED="$lib_preset $LIBSAVED"
	for arg in $LIBSAVED; do
		LIBPATHS="$LIBPATHS $(find ./archlinux/.junest/usr/lib -maxdepth 20 -wholename "*$arg*" | sed 's/\.\/archlinux\///g')"
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
	lib_base_libs="$lib_core $lib_base_1 $lib_base_2 $lib_base_3 $lib_base_4 $lib_base_5 $lib_base_6 $lib_base_7 $lib_base_8 $lib_base_9"
	lib_base_libs=$(echo "$lib_base_libs" | tr ' ' '\n' | sort -u | sed 's/.so.*/.so/' | xargs)
	for l in $lib_base_libs; do
		rsync -av ./archlinux/.junest/usr/lib/"$l"* AppDir/.junest/usr/lib/ &
	done
	wait
}

# Save files in /usr/share
_saveshare() {
	echo "◆ Saving directories in /usr/share"
	SHARESAVED="$SHARESAVED $APP $BIN fontconfig glib- locale mime wayland X11"
	for arg in $SHARESAVED; do
		cp -r ./archlinux/.junest/usr/share/*"$arg"* AppDir/.junest/usr/share/
 	done
}

_savebins 2>/dev/null
_savelibs 2>/dev/null
_saveshare 2>/dev/null

printf -- "\n-----------------------------------------------------------------------------\n ASSEMBLING THE APPIMAGE\n-----------------------------------------------------------------------------\n"

_post_installation_processes

##########################################################################################################################################################
#	REMOVE BLOATWARES, ENABLE MOUNTPOINTS
##########################################################################################################################################################

_remove_more_bloatwares() {
	for r in $ETC_REMOVED; do rm -Rf AppDir/.junest/etc/"$r"*; done
	for r in $BIN_REMOVED; do rm -Rf AppDir/.junest/usr/bin/"$r"*; done
	for r in $LIB_REMOVED; do rm -Rf AppDir/.junest/usr/lib/"$r"*; done
	for r in $PYTHON_REMOVED; do rm -Rf AppDir/.junest/usr/lib/python*/"$r"*; done
	for r in $SHARE_REMOVED; do rm -Rf AppDir/.junest/usr/share/"$r"*; done
	echo Y | rm -Rf AppDir/.cache/yay/*
	find AppDir/.junest/usr/share/doc/* -not -iname "*$BIN*" -a -not -name "." -delete 2> /dev/null #REMOVE ALL DOCUMENTATION NOT RELATED TO THE APP
	find AppDir/.junest/usr/share/locale/*/*/* -not -iname "*$BIN*" -a -not -name "." -delete 2> /dev/null #REMOVE ALL ADDITIONAL LOCALE FILES
	rm -Rf AppDir/.junest/home # remove the inbuilt home
	rm -Rf AppDir/.junest/usr/include # files related to the compiler
	rm -Rf AppDir/.junest/usr/share/man # AppImages are not ment to have man command
	rm -Rf AppDir/.junest/var/* # remove all packages downloaded with the package manager
}

_enable_mountpoints_for_the_inbuilt_bubblewrap() {
	mkdir -p AppDir/.junest/home
	mkdir -p AppDir/.junest/media
	mkdir -p AppDir/.junest/usr/lib/locale
	share_dirs="egl fonts glvnd nvidia themes vulkan"
	for d in $share_dirs; do mkdir -p AppDir/.junest/usr/share/"$d"; done
	mkdir -p AppDir/.junest/run/media
	mkdir -p AppDir/.junest/run/user
	rm -f AppDir/.junest/etc/localtime && touch AppDir/.junest/etc/localtime
	[ ! -f AppDir/.junest/etc/asound.conf ] && touch AppDir/.junest/etc/asound.conf
	[ ! -e AppDir/.junest/usr/share/X11/xkb ] && rm -f AppDir/.junest/usr/share/X11/xkb && mkdir -p AppDir/.junest/usr/share/X11/xkb && sed -i -- 's# /var"$# /usr/share/X11/xkb /var"#g' AppDir/AppRun
}

printf "\n◆ Trying to reduce size:\n\n"

_remove_more_bloatwares
find AppDir/.junest/usr/lib AppDir/.junest/usr/lib32 -type f -regex '.*\.a' -exec rm -f {} \; 2>/dev/null
find AppDir/.junest/usr -type f -regex '.*\.so.*' -exec strip --strip-debug {} \;
find AppDir/.junest/usr/bin -type f ! -regex '.*\.so.*' -exec strip --strip-unneeded {} \;
find AppDir/.junest/usr -type d -empty -delete
_enable_mountpoints_for_the_inbuilt_bubblewrap

##########################################################################################################################################################
#	CREATE THE APPIMAGE
##########################################################################################################################################################

if test -f ./*.AppImage; then rm -Rf ./*archimage*.AppImage; fi

APPNAME=$(cat AppDir/*.desktop | grep '^Name=' | head -1 | cut -c 6- | sed 's/ /-/g')
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
	AppDir "$APPNAME"_"$VERSION"-archimage5.0-x86_64.AppImage
