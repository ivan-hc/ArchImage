#!/usr/bin/env bash

export ARCHIMAGE_VERSION="archimage5.0"

if [ -z "$TMPDIR" ]; then TMPDIR="/tmp"; fi

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
			for m in $archcn_mirrors; do
				if [ -z "$archcn_mirror" ]; then
					archcn_key_pkg=$(curl -Ls "$m/x86_64" | tr '"' '\n' | grep "^archlinuxcn-keyring.*zst$" | tail -1)
					if [ -n "$archcn_key_pkg" ]; then
						archcn_mirror="$m"
					fi
				fi
			done
			if [ -z "$archcn_mirror" ]; then
				exit 0
			fi
			_JUNEST_CMD -- sudo pacman --noconfirm -U "$archcn_mirror"/x86_64/"$archcn_key_pkg"
			printf "\n[archlinuxcn]\n#SigLevel = Never\nServer = $archcn_mirror/\$arch" >> ./.junest/etc/pacman.conf
		fi

		# Enable the chaoticaur third-party repository
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
		echo "Country code: $COUNTRY"
		if [ -n "$GITHUB_REPOSITORY_OWNER" ] || ! curl --output /dev/null --silent --head --fail "https://archlinux.org/mirrorlist/?country=$COUNTRY" 1>/dev/null; then
			TAKES_COUNT=0
			while [ "$TAKES_COUNT" -lt 10 ]; do
				MIRRORLIST=$(curl -Ls https://archlinux.org/mirrorlist/all | awk NR==2 RS=)
				if [ -z "$MIRRORLIST" ]; then
					printf "\n The mirrorlist is empty, attempt %b of 10 will start in 5 seconds...\n\n" "$((TAKES_COUNT + 1))"
					sleep 5
				fi
				TAKES_COUNT=$((TAKES_COUNT + 1))
			done
		else
			TAKES_COUNT=0
			while [ "$TAKES_COUNT" -lt 10 ]; do
				MIRRORLIST=$(curl -Ls "https://archlinux.org/mirrorlist/?country=$COUNTRY")
				if [ -z "$MIRRORLIST" ]; then
					printf "\n The mirrorlist is empty, attempt %b of 10 will start in 5 seconds...\n\n" "$((TAKES_COUNT + 1))"
					sleep 5
				fi
				TAKES_COUNT=$((TAKES_COUNT + 1))
			done
		fi
		if [ -z "$MIRRORLIST" ]; then
			echo " 💀 ERROR: MIRRORLIST IS EMPTY. ABORTED!"
			exit 1
		else
			echo "$MIRRORLIST" | sed 's/#Server/Server/g' > ./.junest/etc/pacman.d/mirrorlist
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
#	INSTALL PROGRAMS USING YAY
##########################################################################################################################################################

_install_packages() {
	_JUNEST_CMD -- yay -Syy

	# Enable AUR
	if [ -n "$BASICSTUFF" ]; then JUNEST_AUR_ENABLED="1"; fi
	if [ -n "$COMPILERS" ]; then JUNEST_AUR_ENABLED="1"; fi
	if [ -n "$CHAOTICAUR_ON" ]; then JUNEST_AUR_ENABLED="1"; fi
	if [ -n "$ARCHLINUXCN_ON" ]; then JUNEST_AUR_ENABLED="1"; fi
	if [ -n "$JUNEST_AUR_ENABLED" ]; then
		_JUNEST_CMD -- gpg --keyserver keyserver.ubuntu.com --recv-key C01E1CAD5EA2C4F0B8E3571504C367C218ADD4FF
	fi

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
		_JUNEST_CMD -- yay --noconfirm -S alsa-lib binutils gtk3 hicolor-icon-theme xapp xdg-utils xorg-server-xvfb
		_JUNEST_CMD -- yay --noconfirm -S "$APP"
		VERSION="$(_JUNEST_CMD -- yay -Q "$APP" | awk '{print $2; exit}' | sed 's@.*:@@')"
		# Use debloated packages
		debloated_soueces="https://github.com/pkgforge-dev/archlinux-pkgs-debloated/releases/download/continuous"
		extra_vk_packages="vulkan-broadcom vulkan-freedreno vulkan-intel vulkan-nouveau vulkan-panfrost vulkan-radeon"
		extra_packages="ffmpeg gdk-pixbuf2 intel-media-driver librsvg llvm-libs mangohud mesa opus qt6-base $extra_vk_packages"
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
		# Update mime database
		if [ ! -f ./.junest/usr/share/mime/mime.cache ]; then
			_JUNEST_CMD -- update-mime-database /usr/share/mime
		fi
		# Create loaders.cache for gdk-pixbuf
		if _JUNEST_CMD -- yay -Qs gdk-pixbuf2; then
			_JUNEST_CMD -- mkdir -p /usr/lib/gdk-pixbuf-2.0/2.10.0/loaders
			if [ ! -f ./.junest/usr/lib/gdk-pixbuf-2.0/2.10.0/loaders/* ]; then
				if [ ! -f ./.junest/usr/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache ]; then
					_JUNEST_CMD -- gdk-pixbuf-query-loaders --update-cache
				fi
			fi
		fi
	else
		echo "No app found, exiting"; exit 1
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
		if [ "$DEPENDENCES0" != "$DEPENDENCES" ]; then
			rm -Rf AppDir/*
		fi
	fi

	# Set locale
	rm -f archlinux/.junest/etc/locale.conf
	sed -i 's/LANG=${LANG:-C}/LANG=$LANG/g' archlinux/.junest/etc/profile.d/locale.sh

	# Remove existing .desktop files from AppDir
	rm -f AppDir/*.desktop

	# Add .desktop file
	if [ -f ./*.desktop ]; then
		LAUNCHER=$(grep -iRl "^Exec.*$BIN" ./* | grep "\.desktop$" | head -1)
	else
		DESKTOP_FILES=$(grep -iRl "^Exec.*$BIN" archlinux/.junest/usr/share/applications/* | grep ".desktop")
		if [ "$BIN" = libreoffice ]; then
			LAUNCHER=$(grep -iRl "^Exec.*$BIN" archlinux/.junest/lib/libreoffice/share/xdg/* | grep "startcenter.*.desktop" | head -1)
		elif [ -n "$LAUNCHER" ]; then
			LAUNCHER="archlinux/.junest/usr/share/applications/$LAUNCHER"
		elif [ -f archlinux/.junest/usr/share/applications/"$BIN".desktop ]; then
			LAUNCHER="archlinux/.junest/usr/share/applications/$BIN.desktop"
		elif [ -f archlinux/.junest/usr/share/applications/"$APP".desktop ]; then
			LAUNCHER="archlinux/.junest/usr/share/applications/$APP.desktop"
		elif [ "$(echo "$DESKTOP_FILES" | wc -l)" != 1 ]; then
			LAUNCHER=$(grep -iRl "^Exec.*$BIN" archlinux/.junest/usr/share/applications/* | grep ".desktop" | awk 'length < min || NR==1 {min=length; line=$0} END {print line}')
		else
			LAUNCHER=$(grep -iRl "^Exec.*$BIN" archlinux/.junest/usr/share/applications/* | grep ".desktop" | head -1)
		fi
	fi
	if [ -n "$LAUNCHER" ]; then
		cp -r "$LAUNCHER" AppDir/
	else
		echo "✖ ERROR: No .desktop file available. Aborting all the processes."
		exit 0
	fi

	# Add icon
	if [ -f ./*.png ]; then
		cp -r ./*.png AppDir/ | echo "◆ Add local .png to AppDir"
	elif [ -f ./*.svg ]; then
		cp -r ./*.svg AppDir/ | echo "◆ Add local .svg to AppDir"
	else
		if [ -z "$ICON" ]; then
			ICON=$(cat "$LAUNCHER" | grep "Icon=" | head -1 | cut -c 6-)
		fi
		if [ -z "$ICON" ]; then
			ICON="$BIN"
		fi
		cp -r archlinux/.junest/usr/share/icons/*"$ICON"* AppDir/ 2>/dev/null
		hicolor_dirs="22x22 24x24 32x32 48x4 64x64 128x128 192x192 256x256 512x512 scalable"
		for i in $hicolor_dirs; do
			cp -r archlinux/.junest/usr/share/icons/hicolor/"$i"/apps/*"$ICON"* AppDir/ 2>/dev/null || cp -r archlinux/.junest/usr/share/icons/hicolor/"$i"/mimetypes/*"$ICON"* AppDir/ 2>/dev/null
		done
		cp -r archlinux/.junest/usr/share/pixmaps/*"$ICON"* AppDir/ 2>/dev/null
	fi

	# Test if the desktop file and the icon are in the root of the future appimage (./*appdir/*)
	if test -f AppDir/*.desktop; then
		echo "◆ Found .desktop file"
	elif ! test -f archlinux/.junest/usr/bin/"$BIN"; then
	 	echo "No binary in path... aborting all the processes."
		exit 0
	fi

	if [ ! -d AppDir/.local ]; then
		mkdir -p AppDir/.local
		rsync -av --inplace --no-whole-file --size-only archlinux/.local/ AppDir/.local/ | echo "◆ Include JuNest-related .local directory into AppDir"
		# Made JuNest a portable app and remove "read-only file system" errors
		cat AppDir/.local/share/junest/lib/core/wrappers.patch > AppDir/.local/share/junest/lib/core/wrappers.sh
		cat AppDir/.local/share/junest/lib/core/namespace.patch > AppDir/.local/share/junest/lib/core/namespace.sh
	fi

	echo "◆ Include .junest directories structure into AppDir"
	rm -Rf AppDir/.junest/*
	archdirs=$(find archlinux/.junest -type d | sed 's/^archlinux\///g')
	for d in $archdirs; do
		mkdir -p AppDir/"$d"
	done
	symlink_dirs=" bin sbin lib lib64 usr/sbin usr/lib64"
	for l in $symlink_dirs; do
		rsync -av --inplace --no-whole-file --size-only archlinux/.junest/"$l" AppDir/.junest/"$l" 1>/dev/null
	done

	rsync -av --inplace --no-whole-file --size-only archlinux/.junest/usr/bin_wrappers/ AppDir/.junest/usr/bin_wrappers/ | echo "◆ Include bin_wrappers (JuNest)"
	rsync -av --inplace --no-whole-file --size-only archlinux/.junest/etc/* AppDir/.junest/etc/ | echo "◆ Include /etc elements from JuNest"
}

##########################################################################################################################################################
#	APPRUN
##########################################################################################################################################################

# This section contains the common functions used in all AppImages created with this method to fill the initial part of the AppRun.
# The final part of the AppRun is in the app script and can be used to add different functions, options, and actions, depending on the user's needs.

# The AppRun header includes core variables and a function to make the AppImage compatible with systems that have kernel-level restrictions (see BubbleWrap in Ubuntu)
_apprun_header() {
	cat <<-'HEREDOC' >> AppDir/AppRun
	#!/bin/sh
	HERE="$(dirname "$(readlink -f "$0")")"
	export JUNEST_HOME="$HERE"/.junest

	CACHEDIR="${XDG_CACHE_HOME:-$HOME/.cache}"
	mkdir -p "$CACHEDIR" || exit 1

	if command -v unshare >/dev/null 2>&1 && ! unshare -Urm /bin/true 2>/dev/null; then
	   echo "JuNest running in proot mode"
	   PROOT_ON=1
	   export PATH="$HERE"/.local/share/junest/bin/:"$PATH"
	else
	   export PATH="$PATH":"$HERE"/.local/share/junest/bin
	fi

	HEREDOC
}

# Nvidia driver support is optional. The "NVIDIA_ON" variable must be set to 1 in the app script to include the handler.
# Host libraries are copied to "${CACHEDIR}/junest_shared" and then exported to LD_LIBRARY_PATH.
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
		   libnvidia_vulkan=$(find /usr/lib -type f -name 'libnvidia*vulkan*' -print -quit 2>/dev/null | head -1)
		   libnv_paths=$(echo "$HOST_LIBS" | grep "libnv" | cut -d ">" -f 2)
		   for f in $libnv_paths; do strings "${f}" | grep -qi -m 1 "nvidia" && libnv_libs="$libnv_libs ${f}"; done
		   host_nvidia_libs=$(echo "$libnv_libs $libnvidia_libs $libvdpau_nvidia $libnvidia_vulkan" | sed 's/ /\n/g' | sort | grep .)
		   for n in $host_nvidia_libs; do libname=$(echo "$n" | sed 's:.*/::') && [ ! -f "${JUNEST_LIBS}"/"$libname" ] && cp "$n" "${JUNEST_LIBS}"/; done
		   libvdpau="${JUNEST_LIBS}/libvdpau_nvidia.so"
		   [ -f "${libvdpau}"."${nvidia_driver_version}" ] && [ ! -f "${libvdpau}" ] && ln -s "${libvdpau}"."${nvidia_driver_version}" "${libvdpau}"
		   export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}":"${JUNEST_LIBS}":"${LD_LIBRARY_PATH}"
		fi

		bind_nvidia_data_dirs="/usr/share/egl /usr/share/glvnd /usr/share/nvidia /usr/share/vulkan"

		HEREDOC
	fi
}

# BubbleWrap (default) and PROOT require mount points on the host. This function sets the variables dynamically.
# The /home, /run/user, /tmp, /sys, /proc, /dev, and /run/user/$($ID -u) directories are already mounted by default in JuNest.
# If NVIDIA_ON is set to 1, the directories listed in the "$bind_nvidia_data_dirs" variable (see above) will also be mounted.
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

	# The path to the files listed in "$mountpoint_files" by the user, in the app script, will be mounted dynamically.
	if [ -n "$mountpoint_files" ]; then
		sed -i "s#bind_files=\"#bind_files=\"$mountpoint_files #g" AppDir/AppRun
	fi
	# The path to the directories listed in "$mountpoint_dirs" by the user, in the app script, will be mounted dynamically.
	if [ -n "$mountpoint_dirs" ]; then
		sed -i "s#bind_dirs=\"#bind_dirs=\"$mountpoint_dirs #g" AppDir/AppRun
	fi
}

##########################################################################################################################################################
#	COMPILE
##########################################################################################################################################################

# Deploy core libraries of the app

_run_quick_sharun_in_parallel() {
	export DESKTOP=$(grep -iRl "^Exec.*$b" .junest/usr/share/applications/* | grep ".desktop")
	_JUNEST_CMD -- ./quick-sharun /usr/bin/"$b"*
}

# The "quick-sharun" script is used to test the app's startup behavior and collect the libraries required for the program to run and function at startup.
# This function also tests its validity.
_run_quick_sharun() {
	printf -- "\n-----------------------------------------------------------------------------\n IMPLEMENTING APP'S SPECIFIC LIBRARIES (SHARUN)\n-----------------------------------------------------------------------------\n"

	if [ -n "$LAUNCHER" ]; then
		export DESKTOP="$LAUNCHER"
	fi

	cd archlinux || exit 1
	rm -Rf AppDir/*
	SHARUN="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/quick-sharun.sh"

	mkdir -p ./.config ./.local
	export XDG_DATA_HOME="$PWD/.local"
	export XDG_CONFIG_HOME="$PWD/.config"

	if [ ! -f ./quick-sharun ]; then
		wget --retry-connrefused --tries=30 "$SHARUN" -O ./quick-sharun || exit 1
		chmod +x ./quick-sharun
	fi

	# Run quick-sharun on the main binary ("$BIN" variable)
	_JUNEST_CMD -- ./quick-sharun /usr/bin/"$BIN"*

	# This function is executed if the "$extra_bins" variable is set.
	# Each keyword will be searched in /usr/bin and considered a program from which to collect the libraries needed to run it.
	if [ -n "$extra_bins" ]; then
		for b in $extra_bins; do
			_run_quick_sharun_in_parallel &
		done
		wait
	fi

	# Validate sharun-aio
	if [ ! -f "$TMPDIR"/sharun-aio ]; then
		echo "ERROR: sharun was not downloaded at all!"
		exit 1
	fi
	if ! head -c 4 "$TMPDIR"/sharun-aio | grep -qa 'ELF'; then
		echo "ERROR: What was downloaded is not sharun!"
		exit 1
	fi

	cd .. || exit 1

	# Save the dependency list to a file. If this file isn't present, quick-sharun will also restart when the script is restarted
	# which will list the newly installed libraries with the new dependencies added in "$DEPENDENCES".
	echo "$DEPENDENCES" > ./deps
	if [ ! -f ./deps ]; then
		touch ./deps
	fi
	printf "\n-----------------------------------------------------------------------------\n"
}

# Add the content of the base package to the AppDir
_extract_base_to_AppDir() {
	rsync -av --inplace --no-whole-file --size-only base/etc/* AppDir/.junest/etc/ 2>/dev/null
	rsync -av --inplace --no-whole-file --size-only base/usr/bin/* AppDir/.junest/usr/bin/ 2>/dev/null
	rsync -av --inplace --no-whole-file --size-only base/usr/lib/* AppDir/.junest/usr/lib/ 2>/dev/null
	rsync -av --inplace --no-whole-file --size-only base/usr/share/* AppDir/.junest/usr/share/ 2>/dev/null
	if [ -d archlinux/.junest/usr/lib32 ]; then
		mkdir -p AppDir/.junest/usr/lib32
		rsync -av --inplace --no-whole-file --size-only archlinux/.junest/usr/lib32/* AppDir/.junest/usr/lib32/ 1>/dev/null
	fi
}

# Extract the base package to "base", before placing them in the AppDir
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
	if [ -z "$pkg_full_path" ]; then
		echo "💀 ERROR: no package found for \"$APP\", operation aborted!"
		exit 0
	fi
	tar fx "$pkg_full_path" -C ./base/ --warning=no-unknown-keyword
	_extract_base_to_AppDir | printf "\n◆ Extract the base package to AppDir\n"
}

# Extract all dependencies listed in "$DEPENDENCES" do dependencies, before placing them in the AppDir
_extract_core_dependencies() {
	if [ -n "$DEPENDENCES" ]; then
		mkdir -p dependencies
		rm -Rf ./dependencies/*
		for d in $DEPENDENCES; do
			if test -f ./archlinux/"$d"-*; then
				tar fx ./archlinux/"$d"-* -C ./dependencies/ --warning=no-unknown-keyword | printf "\n◆ Force \"$d\""
			else
				pkg_full_path=$(find ./archlinux -type f -name "$d-[0-9]*zst")
				if [ -z "$pkg_full_path" ]; then
					pkg_full_path=$(find ./archlinux -type f -name "$d-*zst")
				fi
				for p in $pkg_full_path; do
					pkgname=$(echo "$pkg_full_path" | sed 's:.*/::')
					tar fx "$pkg_full_path" -C ./dependencies/ --warning=no-unknown-keyword | printf "\n◆ Force \"$pkgname\""
				done
			fi
		done
		_extract_base_to_AppDir | printf "\n\n◆ Extract core dependencies to AppDir\n"
		if [ -z "$extra_bins" ]; then
			rm -Rf dependencies/usr/share/locale
		fi
		rm -f dependencies/.*
		rsync -av --inplace --no-whole-file --size-only dependencies/* AppDir/.junest/ 1>/dev/null
	fi
}

# Save files in /usr/bin
_savebins() {
	echo "◆ Saving files in /usr/bin"
	rsync -av --inplace --no-whole-file --size-only ./archlinux/.junest/usr/bin/bwrap AppDir/.junest/usr/bin/ 1>/dev/null
	rsync -av --inplace --no-whole-file --size-only ./archlinux/.junest/usr/bin/proot* AppDir/.junest/usr/bin/ 1>/dev/null
	rsync -av --inplace --no-whole-file --size-only ./archlinux/.junest/usr/bin/*$BIN* AppDir/.junest/usr/bin/ 1>/dev/null
	rsync -av --inplace --no-whole-file --size-only ./archlinux/.junest/usr/bin/gio* AppDir/.junest/usr/bin/ 1>/dev/null
	rsync -av --inplace --no-whole-file --size-only ./archlinux/.junest/usr/bin/xdg-* AppDir/.junest/usr/bin/ 1>/dev/null
	coreutils="[ basename cat chmod chown cp cut dir dirname du echo env expand expr fold head id ln ls mkdir mv readlink realpath rm rmdir seq sleep sort stty sum sync tac tail tee test timeout touch tr true tty uname uniq wc who whoami yes"
	utils_bin="awk bash $coreutils gawk gio grep ld ldd sed sh strings"
	for b in $utils_bin; do
 		rsync -av --inplace --no-whole-file --size-only archlinux/.junest/usr/bin/"$b" AppDir/.junest/usr/bin/ 1>/dev/null
   	done
	for arg in $BINSAVED; do
		rsync -av --inplace --no-whole-file --size-only archlinux/.junest/usr/bin/*"$arg"* AppDir/.junest/usr/bin/ 1>/dev/null
	done
}

# Save files in /usr/lib
_savelibs_parallel() {
	if [ ! -d AppDir/"$arg" ]; then
		rsync -av --inplace --no-whole-file --size-only archlinux/"$arg" AppDir/"$arg" 1>/dev/null
	fi
}

_savelibs() {
	echo "◆ Detect libraries related to /usr/bin files"
	libs4bin=$(readelf -d AppDir/.junest/usr/bin/* 2>/dev/null | grep NEEDED | tr '[] ' '\n' | grep ".so")

	echo "◆ Select JuNest core libraries"
	cp -r ./archlinux/.junest/usr/lib/ld-linux-x86-64.so* AppDir/.junest/usr/lib/
	lib_browser_launcher="gio-launch-desktop libasound.so libatk-bridge libatspi libcloudproviders libdb- libdl.so libedit libepoxy libgtk-3.so.0 libjson-glib libnssutil libpthread.so librt.so libtinysparql libwayland-cursor libX11-xcb.so libxapp-gtk3-module.so libXcursor libXdamage libXi.so libxkbfile.so libXrandr p11 pk"
	lib_preset="$APP $BIN libdw libelf libresolv.so libtinfo.so profile.d $libs4bin $lib_browser_launcher"
	LIBSAVED="$lib_preset $LIBSAVED"
	for arg in $LIBSAVED; do
		LIBPATHS="$LIBPATHS $(find ./archlinux/.junest/usr/lib -maxdepth 20 -wholename "*$arg*" | sed 's/\.\/archlinux\///g')"
	done
	echo "$LIBPATHS" | tr ' ' '\n' | grep -v "__pycache__" | grep "/usr/lib" | sort -u > libs
	LIBPATHS=$(sort ./libs)
	echo "◆ Copy selected libraries to AppDir"
	for arg in $LIBPATHS; do
		_savelibs_parallel &
	done
	wait
	core_libs=$(find AppDir -type f)
	lib_core=$(for c in $core_libs; do readelf -d "$c" 2>/dev/null | grep NEEDED | tr '[] ' '\n' | grep ".so"; done)

	printf "◆ Detect and copy base libs\n"
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
		rsync -av --inplace --no-whole-file --size-only ./archlinux/.junest/usr/lib/"$l"* AppDir/.junest/usr/lib/ 1>/dev/null &
	done
	wait
}

# Save files in /usr/share
_saveshare() {
	echo "◆ Saving directories in /usr/share"
	SHARESAVED="$SHARESAVED $APP $BIN fontconfig glib- locale mime wayland X11"
	for arg in $SHARESAVED; do
		rsync -av --inplace --no-whole-file --size-only ./archlinux/.junest/usr/share/*"$arg"* AppDir/.junest/usr/share/ 1>/dev/null
 	done
}

##########################################################################################################################################################
#	REMOVE BLOATWARES, ENABLE MOUNTPOINTS
##########################################################################################################################################################

_save_doc_and_locale() {
	if [ -d AppDir/.junest/usr/share/doc ]; then
		find AppDir/.junest/usr/share/doc/* -not -iname "*$BIN*" -a -not -name "." -delete 2> /dev/null # Remove all documentation not related to the app
		rsync -av --inplace --no-whole-file --size-only base/usr/share/doc/* / 2>/dev/null | printf "◆ Save documentation from base package\n"
	fi
	if [ -d AppDir/.junest/usr/share/locale ]; then
		if [ -z "$extra_bins" ]; then
			find AppDir/.junest/usr/share/locale/*/*/* -not -iname "*$BIN*" -a -not -name "." -delete 2> /dev/null # Remove all additional locale files
		fi
		rsync -av --inplace --no-whole-file --size-only base/usr/share/locale/* AppDir/.junest/usr/share/locale/ 2>/dev/null | printf "◆ Save locale from base package\n"
	fi
}

_import_hicolor_icon_theme() {
	mkdir -p AppDir/.junest/usr/share/icons/hicolor
	rsync -av --inplace --no-whole-file --size-only archlinux/.junest/usr/share/icons/hicolor/* AppDir/.junest/usr/share/icons/hicolor/ 2>/dev/null | printf "◆ Save hicolor icon theme\n"
}

_remove_more_bloatwares() {
	for r in $ETC_REMOVED; do rm -Rf AppDir/.junest/etc/"$r"*; done
	for r in $BIN_REMOVED; do rm -Rf AppDir/.junest/usr/bin/"$r"*; done
	for r in $LIB_REMOVED; do rm -Rf AppDir/.junest/usr/lib/"$r"*; rm -Rf AppDir/.junest/usr/lib32/"$r"*; done
	for r in $PYTHON_REMOVED; do rm -Rf AppDir/.junest/usr/lib/python*/"$r"*; done
	for r in $SHARE_REMOVED; do rm -Rf AppDir/.junest/usr/share/"$r"*; done

	# AUR packages
	echo Y | rm -Rf AppDir/.cache/yay/*

	# Unneeded files and directories
	rm -Rf AppDir/.junest/home # remove the inbuilt home
	rm -Rf AppDir/.junest/usr/bin/qt.conf # created by Sharun, causes troubles in Qt-based Archimages
	rm -Rf AppDir/.junest/usr/include # files related to the compiler
	rm -Rf AppDir/.junest/usr/share/man # AppImages are not ment to have man command
	rm -Rf AppDir/.junest/var/* # remove all packages downloaded with the package manager

	# Handle 32 bits libraries
	if [ -f AppDir/.junest/usr/lib32/ld-linux.so.2 ]; then
		find AppDir/.junest/usr/lib32 -type f -regex '.*\.a' -exec rm -f {} \; 2>/dev/null | printf "◆ Delete all .a files in /usr/lib32\n"
		find AppDir/.junest/usr/lib32 -type f -regex '.*\.so.*' -exec strip --strip-debug {} \; 2>/dev/null | printf "◆ Discard symbols and other data from libraries in /usr/lib32\n"
	else
		rm -Rf AppDir/.junest/usr/lib32 | printf "◆ Delete /usr/lib32\n"
	fi

	# Handle 64 bits libraries
	find AppDir/.junest/usr/lib -type f -regex '.*\.a' -exec rm -f {} \; 2>/dev/null | printf "◆ Delete all .a files in /usr/lib\n"
	find AppDir/.junest/usr/lib -type f -regex '.*\.so.*' -exec strip --strip-debug {} \; 2>/dev/null | printf "◆ Discard symbols and other data from libraries in /usr/lib\n"

	# Use "strip" on files in /usr/bin
	find AppDir/.junest/usr/bin -type f ! -regex '.*\.so.*' -exec strip --strip-unneeded {} \; 2>/dev/null | printf "◆ Discard symbols and other data from some files in /usr/bin\n"

	# Remove all empty directories
	find AppDir/.junest/usr -type d -empty -delete | printf "◆ Delete all empty directories\n"
}

_enable_mountpoints_for_the_inbuilt_bubblewrap() {
	printf "◆ Create mount points\n\n"
	mkdir -p AppDir/.junest/home
	bind_dirs=$(grep "_dirs=" AppDir/AppRun | tr '" ' '\n' | grep "/" | sort | xargs)
	for d in $bind_dirs; do mkdir -p AppDir/.junest"$d"; done
	mkdir -p AppDir/.junest/run/user

	rm -f AppDir/.junest/etc/localtime
	touch AppDir/.junest/etc/localtime

	if [ ! -f AppDir/.junest/etc/asound.conf ]; then
		touch AppDir/.junest/etc/asound.conf
	fi
	if [ ! -e AppDir/.junest/usr/share/X11/xkb ]; then
		rm -f AppDir/.junest/usr/share/X11/xkb
		mkdir -p AppDir/.junest/usr/share/X11/xkb
		sed -i -- 's# /var"$# /usr/share/X11/xkb /var"#g' AppDir/AppRun
	fi
	if [ -n "$mountpoint_files" ]; then
		for f in $mountpoint_files; do
			if [ ! -f AppDir/.junest"$f" ]; then
				touch AppDir/.junest"$f"
			fi
			if [ ! -e AppDir/.junest"$f" ]; then
				rm -f AppDir/.junest"$f"
				touch AppDir/.junest"$f"
			fi
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
		_install_packages
		;;

	"appdir")
		_root_appdir
		;;

	"apprun")
		echo "◆ Create AppRun"
		_apprun_header
		_apprun_nvidia
		_apprun_binds
		;;

	"compile")
		# Deploy libraries
		if [ ! -f ./deps ]; then
			_run_quick_sharun
			echo "$DEPENDENCES" > ./deps
		elif [ -f ./deps ]; then
			DEPENDENCES0=$(cat ./deps)
			if [ "$DEPENDENCES0" != "$DEPENDENCES" ]; then
				_run_quick_sharun
			fi
		fi

		printf -- "\n-----------------------------------------------------------------------------\n IMPORT CORE ELEMENTS INTO APPDIR\n-----------------------------------------------------------------------------\n"

		# Compile AppDir
		rsync -av --inplace --no-whole-file --size-only archlinux/AppDir/etc/* AppDir/.junest/etc/ | printf "\n◆ Saving /etc" 
		rsync -av --inplace --no-whole-file --size-only archlinux/AppDir/bin/* AppDir/.junest/usr/bin/ | printf "\n◆ Saving /usr/bin"
		rsync -av --inplace --no-whole-file --size-only archlinux/AppDir/lib/* AppDir/.junest/usr/lib/ | printf "\n◆ Saving /usr/lib"
		rsync -av --inplace --no-whole-file --size-only archlinux/AppDir/share/* AppDir/.junest/usr/share/ | printf "\n◆ Saving /usr/share\n"

		printf -- "\n-----------------------------------------------------------------------------\n INCLUDE THE CONTENTS OF THE MAIN PACKAGES\n-----------------------------------------------------------------------------\n"

		_extract_main_package
		_extract_core_dependencies

		tar fx "$(find ./archlinux -type f -name "hicolor-icon-theme-[0-9]*zst")" -C ./base/ 2>/dev/null

		printf -- "\n-----------------------------------------------------------------------------\n ASSEMBLING THE APPDIR\n-----------------------------------------------------------------------------\n\n"

		_savebins 2>/dev/null
		_savelibs 2>/dev/null
		_saveshare 2>/dev/null

		_post_installation_processes

		printf -- "\n\n-----------------------------------------------------------------------------\n ATTEMPTS TO REDUCE THE SIZE\n-----------------------------------------------------------------------------\n\n"

		_save_doc_and_locale

		_import_hicolor_icon_theme

		_remove_more_bloatwares

		_enable_mountpoints_for_the_inbuilt_bubblewrap

		printf -- "-----------------------------------------------------------------------------\n EXPORT TO APPIMAGE\n-----------------------------------------------------------------------------\n\n"
		;;
esac

