#!/bin/sh
# NAME OF THE APP, REPLACE SAMPLE OR EDIT THE PARTS INCLUDING "$APP" MANUALLY, IF NEEDED
# FOR EXAMPLE THE PACKAGE "obs-studio" CAN BE STARTED WITH THE BINARY IS "obs"
APP=gnome-boxes

# THIS WILL DO ALL WORK INTO THE CURRENT DIRECTORY
HOME="$(dirname "$(readlink -f $0)")" 

# DOWNLOAD AND INSTALL JUNEST (DON'T TOUCH THIS)
git clone https://github.com/fsquillace/junest.git ~/.local/share/junest
./.local/share/junest/bin/junest setup

# ENABLE MULTILIB (optional)
#echo "
#[multilib]
#Include = /etc/pacman.d/mirrorlist" >> ./.junest/etc/pacman.conf

# CUSTOM MIRRORLIST, THIS SHOULD SPEEDUP THE INSTALLATION OF THE PACKAGES IN PACMAN (COMMENT EVERYTHING TO USE THE DEFAULT MIRROR)
rm -R ./.junest/etc/pacman.d/mirrorlist
COUNTRY=$(curl -i ipinfo.io | grep country | cut -c 15- | cut -c -2)
wget -q https://archlinux.org/mirrorlist/?country="$(echo $COUNTRY)" -O - | sed 's/#Server/Server/g' >> ./.junest/etc/pacman.d/mirrorlist

# INSTALL THE APP WITH ALL THE DEPENDENCES NEEDED, THE WAY YOU DO WITH PACMAN (YOU CAN ALSO REPLACE "$APP", SEE LINE 4)
# BEING JUNEST STRICTLY MINIMAL, YOU NEED TO ADD ALL YOU NEED, INCLUDING BINUTILS AND GZIP IF YOU NEED TO COMPILE SOMETHING FROM AUR
./.local/share/junest/bin/junest -- sudo pacman -Syy
./.local/share/junest/bin/junest -- sudo pacman --noconfirm -Syu
./.local/share/junest/bin/junest -- sudo pacman --noconfirm -S gnome-boxes gzip
#./.local/share/junest/bin/junest -- yay --noconfirm -S $APP

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

# VERSION NAME, BY DEFAULT THIS POINTS TO THE NUMBER, CHANGE 'REPO' TO 'core', 'extra'...
# OR COMMENT AND ENABLE THE NEXT LINE THAT POINTS TO A PKGBUILD ON THE AUR, IF YOUR APP IS HOSTED THERE
VERSION=$(wget -q https://archlinux.org/packages/REPO/x86_64/$APP/ -O - | grep $APP | head -1 | grep -o -P '(?<='$APP' ).*(?=</)' | tr -d " (x86_64)")
#VERSION=$(wget -q https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=$APP -O - | grep pkgver | head -1 | cut -c 8-)

# CREATE THE APPDIR (DON'T TOUCH THIS)...
wget -q https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage -O appimagetool
chmod a+x appimagetool
mkdir $APP.AppDir
cp -r ./.local ./$APP.AppDir/
cp -r ./.junest ./$APP.AppDir/

# ...ADD THE ICON AND THE DESKTOP FILE AT THE ROOT OF THE APPDIR (IF PATHS AND APPS ARE DIFFERENT YOU CAN CHANGE EVERYTHING)...
cp ./$APP.AppDir/.junest/usr/share/icons/hicolor/scalable/apps/org.gnome.Boxes.svg ./$APP.AppDir/
cp ./$APP.AppDir/.junest/usr/share/applications/org.gnome.Boxes.desktop ./$APP.AppDir/

# ...AND FINALLY CREATE THE APPRUN, IE THE MAIN SCRIPT TO RUN THE APPIMAGE!
# THE APPROACH "echo "$APP $@" | $HERE/.local/share/junest/bin/junest -n" ALLOWS YOU TO RUN THE APP IN A JUNEST SECTION DIRECTLY
# EDIT THE FOLLOWING LINES IF YOU THINK SOME ENVIRONMENT VARIABLES ARE MISSING
cat >> ./$APP.AppDir/AppRun << 'EOF'
#!/bin/sh
APP=gnome-boxes
HERE="$(dirname "$(readlink -f $0)")"
export UNION_PRELOAD=$HERE
export JUNEST_HOME=$HERE/.junest
export PATH=$HERE/.local/share/junest/bin/:$PATH
mkdir -p $HOME/.cache
echo "$APP $@" | $HERE/.local/share/junest/bin/junest proot -n -b "--bind=/home --bind=/home/$(echo $USER) --bind=/media --bind=/opt"
EOF
chmod a+x ./$APP.AppDir/AppRun

# REMOVE "READ-ONLY FILE SYSTEM" ERRORS
sed -i 's#${JUNEST_HOME}/usr/bin/junest_wrapper#${HOME}/.cache/junest_wrapper.old#g' ./$APP.AppDir/.local/share/junest/lib/core/wrappers.sh
sed -i 's/rm -f "${JUNEST_HOME}${bin_path}_wrappers/#rm -f "${JUNEST_HOME}${bin_path}_wrappers/g' ./$APP.AppDir/.local/share/junest/lib/core/wrappers.sh
sed -i 's/ln/#ln/g' ./$APP.AppDir/.local/share/junest/lib/core/wrappers.sh

# REMOVE SOME BLOATWARES, ADD HERE ALL THE FOLDERS THAT YOU DON'T NEED FOR THE FINAL APPIMAGE
rm -R -f ./$APP.AppDir/.junest/var

# REMOVE THE INBUILT HOME (optional)
rm -R -f ./$APP.AppDir/.junest/home

# ENABLE MOUNTPOINTS
mkdir -p ./$APP.AppDir/.junest/home
mkdir -p ./$APP.AppDir/.junest/media

# CREATE THE APPIMAGE
ARCH=x86_64 ./appimagetool -n ./$APP.AppDir
mv ./*AppImage ./GNOME-Boxes_$VERSION-x86_64.AppImage
