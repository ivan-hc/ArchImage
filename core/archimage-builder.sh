#!/usr/bin/env bash

##########################################################################################################################################################
#	DEPLOY DEPENDENCIES
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
	if [ "$(echo "$pkg_full_path" | wc -l)" = 1 ]; then
		pkg_full_path=$(find ./archlinux/.junest -type f -name "$APP-*zst")
	else
		for p in $pkg_full_path; do
			if tar fx "$p" .PKGINFO -O | grep -q "pkgname = $APP$"; then
				pkg_full_path="$p"
			fi
		done
	fi
	[ -z "$pkg_full_path" ] && echo "💀 ERROR: no package found for \"$APP\", operation aborted!" && exit 0
	tar fx "$pkg_full_path" -C ./base/
	_extract_base_to_AppDir | printf "\n◆ Extract the base package to AppDir\n"
}

_extract_core_dependencies() {
	if [ -n "$DEPENDENCES" ]; then
		for d in $DEPENDENCES; do
			if test -f ./archlinux/"$d"-*; then
				tar fx ./archlinux/"$d"-* -C ./base/ | printf "\n◆ Force \"$d\""
			else
				pkg_full_path=$(find ./archlinux -type f -name "$d-[0-9]*zst")
				tar fx "$pkg_full_path" -C ./base/ | printf "\n◆ Force \"$d\""
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
}

##########################################################################################################################################################
#	USAGE
##########################################################################################################################################################

case "$1" in
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

