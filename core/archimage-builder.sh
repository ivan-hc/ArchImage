#!/usr/bin/env bash

if grep -q "_junest_setup" ../*-junest.sh; then
	exit 0
fi

##########################################################################################################################################################
#	DOWNLOAD, INSTALL AND CONFIGURE JUNEST
##########################################################################################################################################################

_junest_setup() {
	if ! test -d "$HOME/.local/share/junest"; then
		printf -- "-----------------------------------------------------------------------------\n DOWNLOAD, INSTALL AND CONFIGURE JUNEST\n-----------------------------------------------------------------------------\n"

		# Download and install JuNest
		printf -- "-----------------------------------------------------------------------------\n◆ Clone JuNest from https://github.com/ivan-hc/junest\n-----------------------------------------------------------------------------\n"
		git clone https://github.com/ivan-hc/junest.git ./.local/share/junest
		printf -- "-----------------------------------------------------------------------------\n◆ Downloading JuNest archive from https://github.com/ivan-hc/junest\n-----------------------------------------------------------------------------\n"
		if [ ! -f ./junest-x86_64.tar.gz ]; then
			curl -#Lo junest-x86_64.tar.gz https://github.com/ivan-hc/junest/releases/download/continuous/junest-x86_64.tar.gz || exit 1
		fi
		_JUNEST_CMD setup -i junest-x86_64.tar.gz

		echo " Apply patches to PacMan..."

		# Enable the archlinuxcn third-party repository
		if [ "$ARCHLINUXCN_ON" = 1 ]; then
			archlinuxcn_mirrorlist="https://raw.githubusercontent.com/archlinuxcn/mirrorlist-repo/refs/heads/master/archlinuxcn-mirrorlist"
			archcn_mirrors=$(curl -Ls "$archlinuxcn_mirrorlist" | tr ' ' '\n' | grep "^https://" | sed 's#/$arch##g')
			for m in $archlinuxcn_mirrorlist; do
				if [ -z "$archcn_mirror" ]; then
					archcn_key_pkg=$(curl -Ls "$m/x86_64" | tr '"' '\n' | grep "^archlinuxcn-keyring.*zst$" | tail -1)
					if [ -n "$archcn_key_pkg" ]; then
						archcn_mirror="$m"
					fi
				fi
			done
			[ -z "$archcn_mirror" ] && exit 0
			_JUNEST_CMD -- sudo pacman --noconfirm -U "$archcn_mirror"/"$ARCH"/"$archcn_key_pkg"
			printf "\n[archlinuxcn]\n#SigLevel = Never\nServer = $archcn_mirror/\$arch" >> ./.junest/etc/pacman.conf
		fi

		# Enable the chaoticaut third-party repository
		if [ "$CHAOTICAUR_ON" = 1 ]; then
			_JUNEST_CMD -- sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
			_JUNEST_CMD -- sudo pacman-key --lsign-key 3056513887B78AEB
			_JUNEST_CMD -- sudo pacman-key --populate chaotic
			_JUNEST_CMD -- sudo pacman --noconfirm -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
			printf "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" >> ./.junest/etc/pacman.conf
		fi

		# Enable multilib
		if [ "$MULTILIB_ON" = 1 ]; then
			printf "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" >> ./.junest/etc/pacman.conf
		fi

		# Use a custom mirrolist depending on your zone or the usage on github.com
		COUNTRY=$(curl -i ipinfo.io 2>/dev/null | grep country | cut -c 15- | cut -c -2)
		if [ -n "$GITHUB_REPOSITORY_OWNER" ] || ! curl --output /dev/null --silent --head --fail "https://archlinux.org/mirrorlist/?country=$COUNTRY" 1>/dev/null; then
			curl -Ls https://archlinux.org/mirrorlist/all | awk NR==2 RS= | sed 's/#Server/Server/g' > ./.junest/etc/pacman.d/mirrorlist
		else
			curl -Ls "https://archlinux.org/mirrorlist/?country=$COUNTRY" | sed 's/#Server/Server/g' > ./.junest/etc/pacman.d/mirrorlist
		fi

		# Bypass signature check level
		sed -i 's/#SigLevel/SigLevel/g; s/Required DatabaseOptional/Never/g' ./.junest/etc/pacman.conf

		# Update arch linux in junest
		_JUNEST_CMD -- sudo pacman -Syy
		_JUNEST_CMD -- sudo pacman --noconfirm -Syu
	else
		printf -- "-----------------------------------------------------------------------------\n RESTART JUNEST\n-----------------------------------------------------------------------------\n"
	fi
}

##########################################################################################################################################################
#	APPDIR
##########################################################################################################################################################

_root_appdir() {
	printf -- "\n-----------------------------------------------------------------------------\n CREATING THE APPDIR\n-----------------------------------------------------------------------------\n\n"

	if [ ! -f ./deps ]; then
		rm -Rf AppDir/*
	elif [ -f ./deps ]; then
		DEPENDENCES0=$(cat ./deps)
		[ "$DEPENDENCES0" != "$DEPENDENCES" ] && rm -Rf AppDir/*
	fi

	# Set locale
	rm -f archlinux/.junest/etc/locale.conf
	sed -i 's/LANG=${LANG:-C}/LANG=$LANG/g' archlinux/.junest/etc/profile.d/locale.sh

	# Add launcher and icon
	rm -f AppDir/*.desktop
	if [ "$BIN" = libreoffice ]; then
		LAUNCHER=$(grep -iRl "^Exec.*$BIN" archlinux/.junest/lib/libreoffice/share/xdg/* | grep "startcenter.*.desktop" | head -1)
	else
		LAUNCHER=$(grep -iRl "^Exec.*$BIN" archlinux/.junest/usr/share/applications/* | grep ".desktop" | head -1)
	fi
	cp -r "$LAUNCHER" AppDir/
	[ -z "$ICON" ] && ICON=$(cat "$LAUNCHER" | grep "Icon=" | cut -c 6-)
	[ -z "$ICON" ] && ICON="$BIN"
	cp -r archlinux/.junest/usr/share/icons/*"$ICON"* AppDir/ 2>/dev/null
	hicolor_dirs="22x22 24x24 32x32 48x4 64x64 128x128 192x192 256x256 512x512 scalable"
	for i in $hicolor_dirs; do
		cp -r archlinux/.junest/usr/share/icons/hicolor/"$i"/apps/*"$ICON"* AppDir/ 2>/dev/null || cp -r archlinux/.junest/usr/share/icons/hicolor/"$i"/mimetypes/*"$ICON"* AppDir/ 2>/dev/null
	done
	cp -r archlinux/.junest/usr/share/pixmaps/*"$ICON"* AppDir/ 2>/dev/null

	# Test if the desktop file and the icon are in the root of the future appimage (./*appdir/*)
	if test -f AppDir/*.desktop; then
		echo "◆ The .desktop file is available in AppDir/"
	elif ! test -f archlinux/.junest/usr/bin/"$BIN"; then
	 	echo "No binary in path... aborting all the processes."
		exit 0
	fi

	if [ ! -d AppDir/.local ]; then
		mkdir -p AppDir/.local
		rsync -av archlinux/.local/ AppDir/.local/ | echo "◆ Rsync .local directory to the AppDir"
		# Made JuNest a portable app and remove "read-only file system" errors
		cat AppDir/.local/share/junest/lib/core/wrappers.patch > AppDir/.local/share/junest/lib/core/wrappers.sh
		cat AppDir/.local/share/junest/lib/core/namespace.patch > AppDir/.local/share/junest/lib/core/namespace.sh
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
}

##########################################################################################################################################################
#	APPRUN
##########################################################################################################################################################

_apprun_header() {
	cat <<-'HEREDOC' >> AppDir/AppRun
	#!/bin/sh
	HERE="$(dirname "$(readlink -f "$0")")"
	export JUNEST_HOME="$HERE"/.junest

	CACHEDIR="${XDG_CACHE_HOME:-$HOME/.cache}"
	mkdir -p "$CACHEDIR" || exit 1

	if command -v unshare >/dev/null 2>&1 && ! unshare --user -p /bin/true >/dev/null 2>&1; then
	   PROOT_ON=1 && export PATH="$HERE"/.local/share/junest/bin/:"$PATH"
	else
	   export PATH="$PATH":"$HERE"/.local/share/junest/bin
	fi

	HEREDOC
}

_apprun_nvidia() {
	if [ "$NVIDIA_ON" = 1 ]; then
		cat <<-'HEREDOC' >> AppDir/AppRun

		[ -z "$NVIDIA_ON" ] && NVIDIA_ON=1
		if [ -f /sys/module/nvidia/version ] && [ "$NVIDIA_ON" = 1 ]; then
		   nvidia_driver_version="$(cat /sys/module/nvidia/version)"
		   JUNEST_DIRS="${CACHEDIR}/junest_shared/usr" JUNEST_LIBS="${JUNEST_DIRS}/lib" JUNEST_NVIDIA_DATA="${JUNEST_DIRS}/share/nvidia"
		   mkdir -p "${JUNEST_LIBS}" "${JUNEST_NVIDIA_DATA}" || exit 1
		   [ ! -f "${JUNEST_NVIDIA_DATA}"/current-nvidia-version ] && echo "${nvidia_driver_version}" > "${JUNEST_NVIDIA_DATA}"/current-nvidia-version
		   [ -f "${JUNEST_NVIDIA_DATA}"/current-nvidia-version ] && nvidia_driver_conty=$(cat "${JUNEST_NVIDIA_DATA}"/current-nvidia-version)
		   if [ "${nvidia_driver_version}" != "${nvidia_driver_conty}" ]; then
		      rm -f "${JUNEST_LIBS}"/*; echo "${nvidia_driver_version}" > "${JUNEST_NVIDIA_DATA}"/current-nvidia-version
		   fi
		   HOST_LIBS=$(/sbin/ldconfig -p)
		   libnvidia_libs=$(echo "$HOST_LIBS" | grep -i "nvidia\|libcuda" | cut -d ">" -f 2)
		   libvdpau_nvidia=$(find /usr/lib -type f -name 'libvdpau_nvidia.so*' -print -quit 2>/dev/null | head -1)
		   libnv_paths=$(echo "$HOST_LIBS" | grep "libnv" | cut -d ">" -f 2)
		   for f in $libnv_paths; do strings "${f}" | grep -qi -m 1 "nvidia" && libnv_libs="$libnv_libs ${f}"; done
		   host_nvidia_libs=$(echo "$libnv_libs $libnvidia_libs $libvdpau_nvidia" | sed 's/ /\n/g' | sort | grep .)
		   for n in $host_nvidia_libs; do libname=$(echo "$n" | sed 's:.*/::') && [ ! -f "${JUNEST_LIBS}"/"$libname" ] && cp "$n" "${JUNEST_LIBS}"/; done
		   libvdpau="${JUNEST_LIBS}/libvdpau_nvidia.so"
		   [ -f "${libvdpau}"."${nvidia_driver_version}" ] && [ ! -f "${libvdpau}" ] && ln -s "${libvdpau}"."${nvidia_driver_version}" "${libvdpau}"
		   export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}":"${JUNEST_LIBS}":"${LD_LIBRARY_PATH}"
		fi

		bind_nvidia_data_dirs="/usr/share/egl /usr/share/glvnd /usr/share/nvidia /usr/share/vulkan"

		HEREDOC
	fi
}

_apprun_binds() {
	cat <<-'HEREDOC' >> AppDir/AppRun

	bind_files="/etc/resolv.conf /etc/hosts /etc/nsswitch.conf /etc/passwd /etc/group /etc/machine-id /etc/asound.conf /etc/localtime "
	bind_dirs=" /media /mnt /opt /run/media /usr/lib/locale /usr/share/fonts /usr/share/themes /var $bind_nvidia_data_dirs"
	if [ "$PROOT_ON" = 1 ]; then
	   for f in $bind_files; do [ -f "$f" ] && BINDINGS=" $BINDINGS --bind=$f"; done
	   for d in $bind_dirs; do [ -d "$d" ] && BINDINGS=" $BINDINGS --bind=$d"; done
	   junest_options="proot -n -b"
	   junest_bindings=" --bind=/dev --bind=/sys --bind=/tmp --bind=/proc $BINDINGS --bind=/home --bind=/home/$USER "
	else
	   for f in $bind_files; do [ -f "$f" ] && BINDINGS=" $BINDINGS --ro-bind-try $f $f"; done
	   for d in $bind_dirs; do [ -d "$d" ] && BINDINGS=" $BINDINGS --bind-try $d $d"; done
	   junest_options="-n -b"
	   junest_bindings=" --dev-bind /dev /dev --ro-bind /sys /sys --bind-try /tmp /tmp --proc /proc $BINDINGS --cap-add CAP_SYS_ADMIN "
	fi

	_JUNEST_CMD() {
	   "$HERE"/.local/share/junest/bin/junest $junest_options "$junest_bindings" "$@"
	}

	HEREDOC
	[ -n "$mountpoint_files" ] && sed -i "s#bind_files=\"#bind_files=\"$mountpoint_files #g" AppDir/AppRun
	[ -n "$mountpoint_dirs" ] && sed -i "s#bind_dirs=\"#bind_dirs=\"$mountpoint_dirs #g" AppDir/AppRun
}

##########################################################################################################################################################
#	COMPILE
##########################################################################################################################################################

# Deploy core libraries of the app
_run_quick_sharun() {
	cd archlinux || exit 1
	rm -Rf AppDir/*
	SHARUN="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/quick-sharun.sh"

	if [ ! -f ./quick-sharun ]; then
		wget --retry-connrefused --tries=30 "$SHARUN" -O ./quick-sharun || exit 1
		chmod +x ./quick-sharun
	fi

	_JUNEST_CMD -- ./quick-sharun /usr/bin/"$BIN"*

	cd .. || exit 1
	echo "$DEPENDENCES" > ./deps
	[ ! -f ./deps ] && touch ./deps
	printf "\n-----------------------------------------------------------------------------\n"
}

# Extract the main package in the AppDir
_extract_base_to_AppDir() {
	rsync -av base/etc/* AppDir/.junest/etc/ 2>/dev/null
	rsync -av base/usr/bin/* AppDir/.junest/usr/bin/ 2>/dev/null
	rsync -av base/usr/lib/* AppDir/.junest/usr/lib/ 2>/dev/null
	rsync -av base/usr/share/* AppDir/.junest/usr/share/ 2>/dev/null
	if [ -d archlinux/.junest/usr/lib32 ]; then
		mkdir -p AppDir/.junest/usr/lib32
		rsync -av archlinux/.junest/usr/lib32/* AppDir/.junest/usr/lib32/ 2>/dev/null
	fi
}

_extract_main_package() {
	mkdir -p base
	rm -Rf ./base/*
	pkg_full_path=$(find ./archlinux/.junest -type f -name "$APP-*zst")
	if [ -z "$pkg_full_path" ]; then
		pkg_full_path=$(find ./archlinux -type f -name "$APP-*zst")
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

_extract_core_dependencies() {
	if [ -n "$DEPENDENCES" ]; then
		for d in $DEPENDENCES; do
			if test -f ./archlinux/"$d"-*; then
				tar fx ./archlinux/"$d"-* -C ./base/ --warning=no-unknown-keyword | printf "\n◆ Force \"$d\""
			else
				pkg_full_path=$(find ./archlinux -type f -name "$d-[0-9]*zst")
				if [ -z "$pkg_full_path" ]; then
					pkg_full_path=$(find ./archlinux -type f -name "$d-*zst")
				fi
				for p in $pkg_full_path; do
					pkgname=$(echo "$pkg_full_path" | sed 's:.*/::')
					tar fx "$pkg_full_path" -C ./base/ --warning=no-unknown-keyword | printf "\n◆ Force \"$pkgname\""
				done
			fi
		done
		_extract_base_to_AppDir | printf "\n\n◆ Extract core dependencies to AppDir\n"
	fi
}

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
	lib_browser_launcher="gio-launch-desktop libasound.so libatk-bridge libatspi libcloudproviders libdb- libdl.so libedit libepoxy libgtk-3.so.0 libjson-glib libnssutil libpthread.so librt.so libtinysparql libwayland-cursor libX11-xcb.so libxapp-gtk3-module.so libXcursor libXdamage libXi.so libxkbfile.so libXrandr p11 pk"
	lib_preset="$APP $BIN libdw libelf libresolv.so libtinfo.so profile.d $libs4bin $lib_browser_launcher"
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

##########################################################################################################################################################
#	REMOVE BLOATWARES, ENABLE MOUNTPOINTS
##########################################################################################################################################################

_remove_more_bloatwares() {
	for r in $ETC_REMOVED; do rm -Rf AppDir/.junest/etc/"$r"*; done
	for r in $BIN_REMOVED; do rm -Rf AppDir/.junest/usr/bin/"$r"*; done
	for r in $LIB_REMOVED; do rm -Rf AppDir/.junest/usr/lib/"$r"*; rm -Rf AppDir/.junest/usr/lib32/"$r"*; done
	for r in $PYTHON_REMOVED; do rm -Rf AppDir/.junest/usr/lib/python*/"$r"*; done
	for r in $SHARE_REMOVED; do rm -Rf AppDir/.junest/usr/share/"$r"*; done
	echo Y | rm -Rf AppDir/.cache/yay/*
	find AppDir/.junest/usr/share/doc/* -not -iname "*$BIN*" -a -not -name "." -delete 2> /dev/null #REMOVE ALL DOCUMENTATION NOT RELATED TO THE APP
	find AppDir/.junest/usr/share/locale/*/*/* -not -iname "*$BIN*" -a -not -name "." -delete 2> /dev/null #REMOVE ALL ADDITIONAL LOCALE FILES
	rsync -av base/usr/share/locale/* AppDir/.junest/usr/share/locale/ | printf "◆ Save locale from base package\n\n"
	rm -Rf AppDir/.junest/home # remove the inbuilt home
	rm -Rf AppDir/.junest/usr/include # files related to the compiler
	rm -Rf AppDir/.junest/usr/share/man # AppImages are not ment to have man command
	rm -Rf AppDir/.junest/var/* # remove all packages downloaded with the package manager
}

_enable_mountpoints_for_the_inbuilt_bubblewrap() {
	mkdir -p AppDir/.junest/home
	bind_dirs=$(grep "_dirs=" AppDir/AppRun | tr '" ' '\n' | grep "/" | sort | xargs)
	for d in $bind_dirs; do mkdir -p AppDir/.junest"$d"; done
	mkdir -p AppDir/.junest/run/user
	rm -f AppDir/.junest/etc/localtime && touch AppDir/.junest/etc/localtime
	[ ! -f AppDir/.junest/etc/asound.conf ] && touch AppDir/.junest/etc/asound.conf
	[ ! -e AppDir/.junest/usr/share/X11/xkb ] && rm -f AppDir/.junest/usr/share/X11/xkb && mkdir -p AppDir/.junest/usr/share/X11/xkb && sed -i -- 's# /var"$# /usr/share/X11/xkb /var"#g' AppDir/AppRun
	if [ -n "$mountpoint_files" ]; then
		for f in $mountpoint_files; do
			[ ! -f AppDir/.junest"$f" ] && touch AppDir/.junest"$f"
			[ ! -e AppDir/.junest"$f" ] && rm -f AppDir/.junest"$f" && touch AppDir/.junest"$f"
		done
	fi
			
}

##########################################################################################################################################################
#	USAGE
##########################################################################################################################################################

case "$1" in
	"junest-setup")
		_junest_setup
		;;

	"install")
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
			VERSION="$(_JUNEST_CMD -- yay -Q "$APP" | awk '{print $2; exit}' | sed 's@.*:@@')"
			# Use debloated packages
			debloated_soueces="https://github.com/pkgforge-dev/archlinux-pkgs-debloated/releases/download/continuous"
			extra_vk_packages="vulkan-asahi vulkan-broadcom vulkan-freedreno vulkan-intel vulkan-nouveau vulkan-panfrost vulkan-radeon"
			extra_packages="ffmpeg gdk-pixbuf2 gtk3 gtk4 intel-media-driver librsvg llvm-libs mangohud mesa opus qt6-base $extra_vk_packages"
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
		;;

	"appdir")
		_root_appdir
		;;

	"apprun")
		_apprun_header
		_apprun_nvidia
		_apprun_binds
		;;

	"compile")
		# Deploy libraries
		printf -- "\n-----------------------------------------------------------------------------\n IMPLEMENTING APP'S SPECIFIC LIBRARIES (SHARUN)\n-----------------------------------------------------------------------------\n"

		if [ ! -f ./deps ]; then
			_run_quick_sharun
			echo "$DEPENDENCES" > ./deps
		elif [ -f ./deps ]; then
			DEPENDENCES0=$(cat ./deps)
			if [ "$DEPENDENCES0" != "$DEPENDENCES" ]; then
				_run_quick_sharun
			fi
		fi

		# Compile AppDir
		rsync -av archlinux/AppDir/etc/* AppDir/.junest/etc/ | printf "\n◆ Saving /etc" 
		rsync -av archlinux/AppDir/bin/* AppDir/.junest/usr/bin/ | printf "\n◆ Saving /usr/bin"
		rsync -av archlinux/AppDir/lib/* AppDir/.junest/usr/lib/ | printf "\n◆ Saving /usr/lib"
		rsync -av archlinux/AppDir/share/* AppDir/.junest/usr/share/ | printf "\n◆ Saving /usr/share\n"

		_extract_main_package
		_extract_core_dependencies

		tar fx "$(find ./archlinux -type f -name "hicolor-icon-theme-[0-9]*zst")" -C ./base/ 2>/dev/null

		printf -- "\n-----------------------------------------------------------------------------\n IMPLEMENTING USER'S SELECTED FILES AND DIRECTORIES\n-----------------------------------------------------------------------------\n\n"

		_savebins 2>/dev/null
		_savelibs 2>/dev/null
		_saveshare 2>/dev/null

		printf -- "\n-----------------------------------------------------------------------------\n ASSEMBLING THE APPIMAGE\n-----------------------------------------------------------------------------\n"

		_post_installation_processes

		# Remove bloatwares and enable mountpoints
		printf "\n◆ Trying to reduce size:\n\n"

		_remove_more_bloatwares
		find AppDir/.junest/usr/lib AppDir/.junest/usr/lib32 -type f -regex '.*\.a' -exec rm -f {} \; 2>/dev/null
		find AppDir/.junest/usr -type f -regex '.*\.so.*' -exec strip --strip-debug {} \;
		find AppDir/.junest/usr/bin -type f ! -regex '.*\.so.*' -exec strip --strip-unneeded {} \;
		find AppDir/.junest/usr -type d -empty -delete

		_enable_mountpoints_for_the_inbuilt_bubblewrap
		;;
esac

