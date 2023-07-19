#!/bin/sh

# NAME OF THE APP BY REPLACING "SAMPLE"
APP=SAMPLE
BIN="$APP" #CHANGE THIS IF THE NAME OF THE BINARY IS DIFFERENT FROM "$APP" (for example, the binary of "obs-studio" is "obs")
DEPENDENCES=""
#BASICSTUFF="binutils gzip"
#COMPILERS="gcc"

# ADD A VERSION, THIS IS NEEDED FOR THE NAME OF THE FINEL APPIMAGE, IF NOT AVAILABLE ON THE REPO, THE VALUE COME FROM AUR, AND VICE VERSA
for REPO in { "core" "extra" "community" "multilib" }; do
echo "$(wget -q https://archlinux.org/packages/$REPO/x86_64/$APP/flag/ -O - | grep $APP | grep details | head -1 | grep -o -P '(?<=/a> ).*(?= )' | grep -o '^\S*')" >> version
echo "$(wget -q https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=$APP -O - | grep pkgver | head -1 | cut -c 8-)" >> version
done
VERSION=$(cat ./version | grep -w -v "" | head -1)

# THIS WILL DO ALL WORK INTO THE CURRENT DIRECTORY
HOME="$(dirname "$(readlink -f $0)")" 

# DOWNLOAD AND INSTALL JUNEST (DON'T TOUCH THIS)
git clone https://github.com/fsquillace/junest.git ~/.local/share/junest
./.local/share/junest/bin/junest setup

# ENABLE MULTILIB (optional)
echo "
[multilib]
Include = /etc/pacman.d/mirrorlist" >> ./.junest/etc/pacman.conf

# CUSTOM MIRRORLIST, THIS SHOULD SPEEDUP THE INSTALLATION OF THE PACKAGES IN PACMAN (COMMENT EVERYTHING TO USE THE DEFAULT MIRROR)
COUNTRY=$(curl -i ipinfo.io | grep country | cut -c 15- | cut -c -2)
rm -R ./.junest/etc/pacman.d/mirrorlist
wget -q https://archlinux.org/mirrorlist/?country="$(echo $COUNTRY)" -O - | sed 's/#Server/Server/g' >> ./.junest/etc/pacman.d/mirrorlist

# INSTALL THE APP, BEING JUNEST STRICTLY MINIMAL, YOU NEED TO ADD ALL YOU NEED, INCLUDING BINUTILS AND GZIP
./.local/share/junest/bin/junest -- sudo pacman -Syy
./.local/share/junest/bin/junest -- sudo pacman --noconfirm -Syu

# COPY BASIC JUNEST TO AN APPDIR
mkdir $APP.AppDir
cp -r ./.local ./$APP.AppDir/
cp -r ./.junest ./$APP.AppDir/

# INSTALL THE PROGRAM USING YAY
./.local/share/junest/bin/junest -- yay -Syy
./.local/share/junest/bin/junest -- yay --noconfirm -S gnu-free-fonts "$BASICSTUFF" "$COMPILERS"
./.local/share/junest/bin/junest -- yay --noconfirm -S "$APP"
./.local/share/junest/bin/junest -- yay --noconfirm -S "$DEPENDENCES"

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

# ADD APPIMAGETOOL TO CONVERT THE APPDIR TO AN APPIMAGE...
wget -q https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage -O appimagetool
chmod a+x appimagetool

# ...ADD THE ICON AND THE DESKTOP FILE AT THE ROOT OF THE APPDIR...
LAUNCHER=$(grep -iRl $APP ~/.junest/usr/share/applications/* | grep ".desktop" | head -1)
cp -r "$LAUNCHER" ./$APP.AppDir/
ICON=$(cat $LAUNCHER | grep "Icon=" | cut -c 6-)
cp -r ./.junest/usr/share/icons/hicolor/22x22/apps/*$ICON* ./$APP.AppDir/ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/24x24/apps/*$ICON* ./$APP.AppDir/ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/32x32/apps/*$ICON* ./$APP.AppDir/ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/48x48/apps/*$ICON* ./$APP.AppDir/ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/64x64/apps/*$ICON* ./$APP.AppDir/ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/128x128/apps/*$ICON* ./$APP.AppDir/ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/192x192/apps/*$ICON* ./$APP.AppDir/ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/256x256/apps/*$ICON* ./$APP.AppDir/ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/512x512/apps/*$ICON* ./$APP.AppDir/ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/scalable/apps/*$ICON* ./$APP.AppDir/ 2>/dev/null

# ...AND FINALLY CREATE THE APPRUN, IE THE MAIN SCRIPT TO RUN THE APPIMAGE!
# EDIT THE FOLLOWING LINES IF YOU THINK SOME ENVIRONMENT VARIABLES ARE MISSING
cat >> ./$APP.AppDir/AppRun << 'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f $0)")"
export UNION_PRELOAD=$HERE
export JUNEST_HOME=$HERE/.junest
export PATH=$HERE/.local/share/junest/bin/:$PATH
mkdir -p $HOME/.cache
$HERE/.local/share/junest/bin/junest proot -n -b "--bind=/home --bind=/home/$(echo $USER) --bind=/media --bind=/mnt --bind=/opt --bind=/usr/share --bind=/usr/lib/locale --bind=/etc/fonts" 2> /dev/null -- BINARY "$@"
EOF
chmod a+x ./$APP.AppDir/AppRun
sed -i "s#BINARY#$BIN#g" ./$APP.AppDir/AppRun

# REMOVE "READ-ONLY FILE SYSTEM" ERRORS
sed -i 's#${JUNEST_HOME}/usr/bin/junest_wrapper#${HOME}/.cache/junest_wrapper.old#g' ./$APP.AppDir/.local/share/junest/lib/core/wrappers.sh
sed -i 's/rm -f "${JUNEST_HOME}${bin_path}_wrappers/#rm -f "${JUNEST_HOME}${bin_path}_wrappers/g' ./$APP.AppDir/.local/share/junest/lib/core/wrappers.sh
sed -i 's/ln/#ln/g' ./$APP.AppDir/.local/share/junest/lib/core/wrappers.sh

# REMOVE SOME BLOATWARES
rm -R -f ./$APP.AppDir/.junest/var/* #REMOVE ALL PACKAGES DOWNLOADED WITH THE PACKAGE MANAGER

# TRY TO COPY THE FILES INSTALLED WITH THE APP
echo $(echo $(./.local/share/junest/bin/junest -- sudo pacman -Si $APP | grep Depends | sed 's/ /\n/g' | grep -v -w "" | grep -w -v Depends | grep -w -v On | sort -u)) > deps
./.local/share/junest/bin/junest -- pacman -Ql $APP "$DEPENDENCES" $(cat ./deps) | sed 's/[^ ]* //' >> list

./.local/share/junest/bin/junest -- ldd /usr/bin/"$BIN" | grep "=>" | awk '{print $3}' >> list
./.local/share/junest/bin/junest -- ldd $(cat ./list | grep "bin") | grep "=>" | awk '{print $3}' | grep -w -v " " | uniq | sort -u >> list

ARGS=$(tail -n +2 ./list | sort -u | uniq)
for arg in $ARGS; do
	for var in $arg; do
		cp --parents ./.junest"$arg" ./$APP.AppDir/
	done 
done

# REMOVE THE INBUILT HOME
rm -R -f ./$APP.AppDir/.junest/home

# ENABLE MOUNTPOINTS
mkdir -p ./$APP.AppDir/.junest/home
mkdir -p ./$APP.AppDir/.junest/media

# CREATE THE APPIMAGE
ARCH=x86_64 ./appimagetool -n ./$APP.AppDir
mv ./*AppImage ./"$(cat ./$APP.AppDir/*.desktop | grep 'Name=' | head -1 | cut -c 6- | sed 's/ /-/g')"_"$VERSION"-x86_64.AppImage
