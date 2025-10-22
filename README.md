ArchImage is the bundling of Arch Linux packages into an AppImage using [JuNest](https://github.com/fsquillace/junest).

This allows you to use the latest programs from Arch Linux and AUR on every distribution, old or newer.

Being this a container into an AppImage, it has its own "bubblewrap" or "proot" to work using its inbuilt resources, including GLIBC, so it can run also on 10+ years old GNU/Linux distributions.

**From version 5.0, the CLI also supports scripts for [SHARUN-based Anylinux AppImages](https://github.com/pkgforge-dev/Anylinux-AppImages)**

If you have already installed `archimage-cli`, please run
```
archimage-cli -s
```
...to use the latest version.

Archimage combines the flexibility of JuNest with the portability of an AppImage, offering the ability to package all the software available in the official Arch Linux repositories, the AUR and ChaoticAUR.

## SEE IT IN ACTION

In this video, how to create an Archimage 5.0 of Abiword.

https://github.com/user-attachments/assets/231da48c-8b1f-49f1-8f40-8d439f0ccfae

*Video sped up due to GitHub limitations for media uploads. Real-time 3 minutes and 30 seconds.*

------------------------------------------------------------------------
### Index
------------------------------------------------------------------------

[Installation](#installation)

[Usage](#usage)

- [Options](#options)

- [What to do](#what-to-do)

- [What NOT to do](#what-not-to-do)

- [Step by step guide](#step-by-step-guide)

- [Requirements of an AppImage](#requirements-of-an-appimage)

- [Archimage structure](#archimage-structure)

- [Test the AppImage](#test-the-appimage)

  - [How to add missing libraries manually](#how-to-add-missing-libraries-manually)
  - [Dotfiles tip](#dotfiles-tip)
  - [Repeat the build](#repeat-the-build)
  - [How to debloat an Archimage (and made it smaller)](#how-to-debloat-an-archimage)
  - [Customize your script](#customize-your-script)

[Hardware Acceleration](#hardware-acceleration)

[Compared to classic AppImage construction](#compared-to-classic-appimage-construction)
- [Advantages](#advantages)
- [Disadvantages](#disadvantages)

[Credits](#credits)

[Related projects](#related-projects)

------------------------------------------
# Installation
Download the main script and made it executable:
```
wget https://raw.githubusercontent.com/ivan-hc/ArchImage/main/archimage-cli
chmod a+x ./archimage-cli
```

-----------------------------------------------------------
# USAGE:
```
archimage-cli [OPTION]
archimage-cli [OPTION] [PROGRAM]
```
### OPTIONS:
```
-h,--help		Shows this message.
-v,--version		Shows the version.
-b,--build		Create the script to build the AppImage.
-s,--sync		Update archimage-cli to the latest version.
--devmode-enable	Use the development branch (at your own risk).
--devmode-disable	Undo "--devmode-enable" (see below).
```

------------------------------------------------------------------------

| [Back to "Index"](#index) |
| - |

------------------------------------------------------------------------
### What to do
To prevent problems of any kind, dedicate a single directory to the created script, proceed as follows:
1. create the script;
2. create an empty directory, the name must not contain spaces, for example "tmp" or "test";
3. move the script you created to the directory in step 2;
4. open a terminal in the directory created in step 2;
5. run the script inside the directory, like this: `./sample-junest.sh`

NOTE, older versions are significantly slower to build.

Pay attention to the file extension, it must contain the version of Archimage used, for example
```
Appname-$VERSION-archimage5.0-x86_64.AppImage
```

Always try to get the latest version to build your Appimages:

- since version 4 hardware acceleration is available
- since version 4.2 the AppImages created use PROOT as a fallback in case the host system has Namespaces restrictions (see Ubuntu), also the Appimages created are updatable
- since version 4.3 the scripts are faster and more selective for libraries, automating much of the process
- since version 5.0 librariesw are collected via SHARUN, to check and import as much as possible only the needed libraries to made the app run

Please refer to the [releases](https://github.com/ivan-hc/ArchImage/releases) page to see the developments and new features introduced in this project so far.

------------------------------------------
### What NOT to do
Here's what absolutely NOT to do when running a script you created:
- DO NOT DRAG THE CREATED SCRIPT INTO THE TERMINAL! The script only works if run in place, [see point 5 above](#what-to-do).
- DO NOT RUN THE CREATED SCRIPT IN YOUR $HOME DIRECTORY! The script will use the directory where it is run as $HOME. [You must follow points 2, 3 and 4 above](#what-to-do).
- DO NOT RUN THE CREATED SCRIPT IN ANY OTHER DIRECTORIES! Create an empty one and dedicate that to the script. Again, [just follow points 2, 3 and 4 above](#what-to-do).
- DO NOT USE THE SAME DIRECTORY FOR TWO DIFFERENT APPLICATIONS! Create a new one for each new script created.

Follow the steps at "[*What to do*](#what-to-do)" and watch the "[video example](#example)" above.

##### Referenced issues https://github.com/ivan-hc/ArchImage/issues/19 and https://github.com/ivan-hc/ArchImage/issues/23

------------------------------------------------------------------------

| [Back to "Index"](#index) |
| - |

------------------------------------------------------------------------
### Step by step guide
Before proceeding, make sure you have understood "[What to do](#what-to-do)" and above all "[**What NOT to do**](#what-not-to-do)"!

Also, THIS GUIDE APPLIES TO **ARCHIMAGE 5.0 OR HIGHER**!

Archimage 4.3 or lower are considered OBSOLETE and UNSUPPORTED.

### 1. Create the script
Use the option `-b` or `--build`, example with "obs-studio"
```
./archimage-cli -b obs-studio
```
<img width="747" height="798" alt="Istantanea_2025-10-22_00-57-36" src="https://github.com/user-attachments/assets/0b18343b-e480-4f71-a474-0016bfe3a79b" />

The first question is about creating an Archimage script (1, default), a SHARUN-based Anylinux script (2) or press any other key to abort.

The two scripts are not much different:
- this is the Junest-based Archimage [NEW-junest.sh](https://github.com/ivan-hc/ArchImage/blob/main/NEW-junest.sh)
- this is the SHARUN-based AppImagee [NEW-anylinux.sh](https://github.com/ivan-hc/ArchImage/blob/main/NEW-anylinux.sh)

The JuNest-based script supports more configurable variables and an editable AppRun and body in general. The SHARUN-based is efficient, but lacks of configurations. Also the AppRun come from a preset.

The JuNest-based Appimage (Archimage) is a portable container, so it relies on its own resources, while mounts few other files and directories using BubbleWrap or Proot (depending on system's restrictions), so it is not much integrated with the host system. On the contrary, SHARUN-based AppImages are more independent and work in harmony with other applications.

**To learn more about Anylinux AppImages, visit https://github.com/pkgforge-dev/Anylinux-AppImages**

Choose the script you prefer.

**NOTE, both the scripts use JuNest in Bubblewrap mode (requires unrestricted Namespaces) in the build process.** See [here](https://github.com/ivan-hc/AM/blob/main/docs/troubleshooting.md#ubuntu-mess) for more context.

### 2. Add binary name
The CLI will ask you if you want to specify the name of the binary or leave blank if the name is the same of [PROGRAM]. In most cases we can leave blank, but for some applications, like OBS Studio, the executable name is different, in our case it is `obs`

<img width="701" height="78" alt="Istantanea_2025-10-22_01-25-18" src="https://github.com/user-attachments/assets/90aceb33-30a8-4eb2-a76f-587c0940ef87" />

If you're not sure about the name of the main executable, use https://archlinux.org/packages/ or read the PKGBUILD if the app is hosted on the AUR. By default, the script will use "yay" to install all the programs in JuNest.

### 3. Add extra dependencies
The script will ask you to add a list of additional packages you want to include into the AppImage (with the syntax `app1 app2 app3...`)

<img width="697" height="75" alt="Istantanea_2025-10-22_01-26-21" src="https://github.com/user-attachments/assets/73271046-be23-4bfc-b432-00deef4b6ee8" />

leave blank if no dependency is needed. In our example, I add `python`, also if it is not necessary anymore. You can add many more packages, according to your needs.

### 3,5. AUR, want to use ChaoticAUR instead? The hidden question
Between question 3 (include all dependencies) and 4 (enable multilib) exists another hidden question

<img width="709" height="74" alt="402320114-ab650430-a2da-4663-ae9d-c4d97d3f4103" src="https://github.com/user-attachments/assets/408134a1-bef6-468c-9798-006b2f6b0ec5" />

this question come up only if the program is not hosted on the official repositories, so it come from AUR.

In this case `binutils`, `gzip` and `base-devel` are enabled by default. You can choose to enable ChaoticAUR to save time and resources while compiling the program. For example `gimp-git` lasts 5 minutes or less from ChaoticAUR, while from AUR it can take 30 minutes or more (with the risk that it fails).

Of course, this question will not come up with `obs-studio`, since it is on the official Arch Linux repositories.

### 4. Enable multilib
Want to enable the "multilib" repo? It is usally needed for 32bit libraries, used in programs like WINE and frontends like Bottles

<img width="659" height="69" alt="Istantanea_2025-10-22_01-32-26" src="https://github.com/user-attachments/assets/56eef331-c247-45f3-923f-6dce3d5b5eb2" />

in our case, we can leave blank or press "N". We don't need 32 bits libraries at all in this case.

### Ending message
At the end of the wizard you will have a message that will remembe4r you to run the script into an empty directory.

Again, make sure you have understood "[What to do](#what-to-do)" and above all "[**What NOT to do**](#what-not-to-do)"!

Also, see the **[tutorial](#tutorial)** to debug and improve your AppImage.

-----------------------------------------------------------
## Requirements of an AppImage
To be valid, an AppImage must contain, in the root of the .AppDir directory:
1. a valid .desktop file (the application one is selected by default, otherwise a custom one is created);
2. an icon, whose name (without extension) must correspond to the "Icon=" entry of the .desktop file at point 1;
3. the binary file must be contained in the $PATH (/usr/bin) of the AppImage, and must correspond to the "Exec=" entry of the .desktop file at point 1.

If this requirement is not met, no AppImage will be created.

-----------------------------------------------------------
## Archimage structure
An Archimage does not require libfuse2 to function.

Unlike many other AppImages, its structure, [other than the requirements above](#requirements-of-an-appimage), resembles a $HOME directory:
```
App.AppDir/
  |
  |_/App.desktop
  |
  |_/app.png
  |
  |_/.local/share/junest/
  |
  |_/.junest/
```
Hidden directories are those used in a normal Junest installation:
- ".junest" contains the Arch Linux system;
- ".local/share/junest" contains the JuNest files to start Arch Linux in a container.

<img width="897" height="732" alt="Istantanea_2025-10-22_01-46-25" src="https://github.com/user-attachments/assets/c1bae221-d838-4594-8d1e-4b2a5334947c" />

The Archimage is first built, and then reassembled with only the essential files indicated in the script you created.

-----------------------------------------------------------
## Test the AppImage
Once the script has finished and the AppImage has been created, run the AppImage from the terminal, and check that there are no errors (e.g. libraries not found, missing dependencies...):
```
./Sample-1.2.3-x86_64.AppImage
```
For more verbose output, use `LD_DEBUG`.

To see the missing libraries, run
```
LD_DEBUG=libs ./Sample-1.2.3-x86_64.AppImage
```
to see the missing files, run
```
LD_DEBUG=files ./Sample-1.2.3-x86_64.AppImage
```

To learn more about `LD_DEBUG` usage, see https://www.bnikolic.co.uk/blog/linux-ld-debug.html

### Dotfiles tip
To not flood your $HOME and yout ~/.config directories with dotfiles, I recommend creating a .home and a .config directory with the same name as the AppImage:
```
mkdir -p Sample-1.2.3-x86_64.AppImage.home Sample-1.2.3-x86_64.AppImage.config
./Sample-1.2.3-x86_64.AppImage
```
If your file manager supports custom actions (for example Thunar in XFCE4), you can right-click on an AppImage using this command
```
grep -Eaoq -m 1 'github.com/AppImage/AppImageKit/wiki/FUSE' %f && chmod a+x %f && mkdir -p %f.home %f.config
```
I suggest you empty/remove/recreate these direcftories at the end of each test, in order to rewrite the dotfiles using a clean configuration.

### Repeat the build
If you encounter any problems after testing, manually edit the script by adding dependencies or keywords in the respective listed variables, then run the script again to build the AppImage.
```
./sample-junest.sh
```
This will repeat the construction of the AppImage starting from the shortcomings of the Arch Linux container.

On-screen messages will tell you what's happening.

Wait until the end and try the AppImage again.

Run the tests until you get the desired result.

## How to add missing libraries manually
On top of the script (under APP, DEPENDENCES, etcetera...) you can see the following variables:
```
BINSAVED="SAVEBINSPLEASE"
SHARESAVED="SAVESHAREPLEASE"
lib_browser_launcher="gio-launch-desktop libasound.so libatk-bridge libatspi libcloudproviders libdb- libdl.so libedit libepoxy libgtk-3.so.0 libjson-glib libnssutil libpthread.so librt.so libtinysparql libwayland-cursor libX11-xcb.so libxapp-gtk3-module.so libXcursor libXdamage libXi.so libxkbfile.so libXrandr p11 pk"
LIBSAVED="SAVELIBSPLEASE $lib_browser_launcher"
```
Set keywords to searchan include in names of directories and files in /usr/bin (BINSAVED), /usr/share (SHARESAVED) and /usr/lib (LIBSAVED).

The "$lib_browser_launcher" set of keyword is intended to allow the links inside an AppImage (for example in the Info dialog) to be clicked to launch the host's browser. They come up after a long search using Firefox. Any improvement is wellcome.

Here are the more common scenarios in which you may need to edit the three main variables. If while launching the AppImage from the command line, it prompts (for example)...
- "`capocchia: command not foud`", add `capocchia` to BINSAVED
- "`Cannot load libcapocchia.so: file not found`" or "`Cannot find libcapocchia.so: No such file or directory`", add `libcapocchia` or just `capocchia` to LIBSAVED
- "`Cannot read /usr/share/some/program/capocchia.svg`", add `some` to SHARESAVED

Once you have done so, [repeat the build](#Repeat the build).

NOTE, if the same error about the same file persists, this may mean that such file was not installed in JuNest during the build. In this case, use your favourite search engine (I use [startpage.com](https://www.startpage.com)) and search
```
libcapocchia.so archlinux
```
And see the results, then try to find the exact package required. In our example, you have found that such library is in the package `capocchia`, so add this to DEPENDENCES
```
DEPENDENCES="" #SYNTAX: "APP1 APP2 APP3 APP4...", LEAVE BLANK IF NO OTHER DEPENDENCIES ARE NEEDED
```
...so change the above to
```
DEPENDENCES="capocchia" #SYNTAX: "APP1 APP2 APP3 APP4...", LEAVE BLANK IF NO OTHER DEPENDENCIES ARE NEEDED
```
...then [repeat the build](#Repeat the build).

Since you have already added the `capocchia` keyword to LIBSAVED, this time the error should disappear.

Maybe another error about another missing ligrary and not included may come up. If so, repeat the steps you have done for the `capocchia` package and the `libcapocchia.so` library of our example.

*PS: as far as I know, there is not (yet) a package or a library with that kind of name... but if I am wrong, I suppose it would be a tool that does random things. It would be an idea for someone.*

*PPS: I'm obviously kidding. Please don't hate me.*

## How to debloat an Archimage
From version 5, you can find all configurable variables on top of the script, and among them, you can see the following ones
```
ETC_REMOVED="makepkg.conf pacman"
BIN_REMOVED="gcc"
LIB_REMOVED="gcc"
PYTHON_REMOVED="__pycache__/"
SHARE_REMOVED="gcc icons/AdwaitaLegacy icons/Adwaita/cursors/ terminfo"
```
Set the items you want to manually REMOVE. Complete the path in /etc/, /usr/bin/, /usr/lib/, /usrlib/python*/ and /usr/share/ respectively.

For example, suppose that we have a directory `some/dir` under /usr/lib:
- to remove its content, write `some/dir/`
- to remove only "dir", use `some/dir`
- to remove the content of "some", write `some/`
- to remove "some", write only `some` (note, all files and directories starting with "some" in /usr/lib will be removed)

The "`rm`" command will take into account the listed object/path and add an asterisk at the end, completing the path to be removed.
Some keywords and paths are already set. Remove them if you consider them necessary for the AppImage to function properly.

------------------------------------------------------------------------
# Customize your script
Once you created the script, it is yours and only yours. You can add/remove functions as you like.

Of course, **DO IT ON YOUR OWN RISK!**

------------------------------------------------------------------------

| [Back to "Index"](#index) |
| - |

------------------------------------------------------------------------
# Tutorial
This is a step-by-step tutorial on how to create an Archimage correctly. To write this one I tried to help a user into a comment, so I decided to publish it here too, with the same videos in real time.

In this example I'll build "Signal", available in Arch Linux as "[signal-desktop](https://archlinux.org/packages/extra/x86_64/signal-desktop/)", in "extra" (not an AUR package).

To create the basic script I'll use a standard configuration:
1. name: signal-desktop
2. name binary: leave blank, its the same
3. dependences: none
4. extraction level: 1, default... leave blank. Whit only one level, the app will be smaller, but will not easily run at first go (for the sake of this tutorial)
5. include all dependences: y
6. multilib: nope, leave blank
7. hardware acceleration: nope, leave blank
8. use defaults: y

like this:

https://github.com/user-attachments/assets/0e373cbd-f473-4214-bf3c-8530867762dd

Once I created the script, I create a "tmp" directory (you can name it the way you want) and I put the script into it.

I run the script and after 2 minutes I got the AppImage.

The AppImage is 296 MB. Here is what happens when I run it:

https://github.com/user-attachments/assets/b0d6474c-c7bc-4df0-bc91-bcde8d764176

as expected, it does not work at first attempt. To fix it you can start to read the logs and see what files are missing, like this

https://github.com/user-attachments/assets/fed38d05-bf11-4804-9846-93e55e14e6b0

it is looking for a missing module named "xapp-gtk3-module", contained into a package to search on Google (or in my case via "Startpage"), in this case the package is "xapp". You can enter the page of the package and read the content, under "Package content".

All you need to do is to take note of the missing package and then add to dependences, like this:

https://github.com/user-attachments/assets/bbe35505-d8f9-489c-9e31-ef5713a7cc3c

and as you can see, "xapp" is downloaded and then it wil be extracted with all the other packages listed during this process in the "deps" directory.

Now the AppImage is increased of 0,1 MB, let we see if it works...

https://github.com/user-attachments/assets/5c832f45-e3fa-4a10-8b16-69f381492685

also this time it is not working, but I've found that there is a missing library "libgnomekbdui", contained in the "libgnomekbd" package... so I'll do the same as I did with xapp.

Now the package is 296,2 MB... let we see if it runs...

https://github.com/user-attachments/assets/bad4d6cc-a16c-498b-a9fa-528894c3cb8f

this time it is missing the library "libudev.so", I'll add the keyword "libudev" to $LIBSAVED, to fetch all files under /usr/lib containing this keyword, for this will be added all depending libraries and it too will be bundled in the AppImage.

In case it is not saved, search the package containing that library as I did with "xapp" and "libgnomekbd".

Now the package is 296,3 MB... let se again:

https://github.com/user-attachments/assets/bf6ff485-80b7-4c33-a753-19e8c2a08d74

Magic!

If the app works, you are good with it. Anyway it is still suggested to find missing libraries t mede it work as better as you can.

If you feel that the package is too big, use a tool like Baobab or "du" to find the big files or the ones that you think are unneeded.

You can also disable/comment the `rsync` command referencing to the content of the "deps" directory, not to include them all, and add only the keyworkd of missing libraries you will see usind LD_DEBUG, one by one.

To test the debloating, sun theAppRun script into the AppDir directory, it will run the program as it were the AppImage. Try to move elsewhere all files you think are unneeded, run the AppRun and see if it works. It the app still works without the files and directories you moved, take note of what you can remove and add the commands in the script, maybe under the "_remove_more_bloatwares" function.

If you do all this correctly, the package will be even smaller.

------------------------------------------------------------------------

| [Back to "Index"](#index) |
| - |

------------------------------------------------------------------------
# Hardware Acceleration
From version 5.0, Archimage handles a copy of the system's Nvidia drivers into a temporary "$HOME/.cache/junest_shared" directory, shared with other Archimages 5.0 or higher.

The check is enabled by default and can be disabled by exporting the `NVIDIA_ON` variable with a value not equalt to 1.

This is the logic in the AppRun
```
CACHEDIR="${XDG_CACHE_HOME:-$HOME/.cache}"
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
```

For the old Archimage 4.x series, hardware accelleration was provided by [Conty](https://github.com/Kron4ek/Conty). The drivers were placed in a "$HOME/.local/share/Conty" directory. If you already use a Conty container or run 4.x Archimages (see the name of the AppImage), you will be able to use the same Conty directory.

------------------------------------------------------------------------

| [Back to "Index"](#index) |
| - |

------------------------------------------------------------------------
# Compared to classic AppImage construction
In the past AppImages were built using .deb packages or guessing instructions to make them work. With the "ArchImage" method all you have to do is the reverse, i.e. "delete" what is no longer needed.

This is a list of the AppImages I've built until I wrote this brief guide:

| Application | Stars |
| -- | -- |
| [*Abiword*](https://github.com/ivan-hc/Abiword-appimage) | ![](https://img.shields.io/github/stars/ivan-hc/Abiword-appimage?label=%E2%AD%90&style=for-the-badge)
| [*Aisleriot*](https://github.com/ivan-hc/Aisleriot-appimage) | ![](https://img.shields.io/github/stars/ivan-hc/Aisleriot-appimage?label=%E2%AD%90&style=for-the-badge)
| [*Amarok*](https://github.com/ivan-hc/Amarok-appimage) | ![](https://img.shields.io/github/stars/ivan-hc/Amarok-appimage?label=%E2%AD%90&style=for-the-badge)
| [*Avidemux*](https://github.com/ivan-hc/Avidemux-unofficial-appimage) | ![](https://img.shields.io/github/stars/ivan-hc/Avidemux-unofficial-appimage?label=%E2%AD%90&style=for-the-badge)
| [*Bottles*](https://github.com/ivan-hc/Bottles-appimage) | ![](https://img.shields.io/github/stars/ivan-hc/Bottles-appimage?label=%E2%AD%90&style=for-the-badge)
| [*Celestia "Enanched"*](https://github.com/ivan-hc/Celestia-appimage) | ![](https://img.shields.io/github/stars/ivan-hc/Celestia-appimage?label=%E2%AD%90&style=for-the-badge)
| [*Emacs*](https://github.com/ivan-hc/Emacs-appimage) | ![](https://img.shields.io/github/stars/ivan-hc/Emacs-appimage?label=%E2%AD%90&style=for-the-badge)
| [*Evince*](https://github.com/ivan-hc/Evince-appimage) | ![](https://img.shields.io/github/stars/ivan-hc/Evince-appimage?label=%E2%AD%90&style=for-the-badge)
| [*Gedit*](https://github.com/ivan-hc/Gedit-appimage) | ![](https://img.shields.io/github/stars/ivan-hc/Gedit-appimage?label=%E2%AD%90&style=for-the-badge)
| [*GIMP Stable/Git/Hybrid*](https://github.com/ivan-hc/GIMP-appimage) | ![](https://img.shields.io/github/stars/ivan-hc/GIMP-appimage?label=%E2%AD%90&style=for-the-badge)
| [*GNOME Boxes*](https://github.com/ivan-hc/Boxes-appimage) | ![](https://img.shields.io/github/stars/ivan-hc/Boxes-appimage?label=%E2%AD%90&style=for-the-badge)
| [*Gnome-calculator*](https://github.com/ivan-hc/Gnome-calculator-appimage) | ![](https://img.shields.io/github/stars/ivan-hc/Gnome-calculator-appimage?label=%E2%AD%90&style=for-the-badge)
| [*Gnumeric*](https://github.com/ivan-hc/Gnumeric-appimage) | ![](https://img.shields.io/github/stars/ivan-hc/Gnumeric-appimage?label=%E2%AD%90&style=for-the-badge)
| [*Handbrake*](https://github.com/ivan-hc/Handbrake-appimage) | ![](https://img.shields.io/github/stars/ivan-hc/Handbrake-appimage?label=%E2%AD%90&style=for-the-badge)
| [*Hypnotix*](https://github.com/ivan-hc/Hypnotix-appimage) | ![](https://img.shields.io/github/stars/ivan-hc/Hypnotix-appimage?label=%E2%AD%90&style=for-the-badge)
| [*Inkscape*](https://github.com/ivan-hc/Inkscape-appimage) | ![](https://img.shields.io/github/stars/ivan-hc/Inkscape-appimage?label=%E2%AD%90&style=for-the-badge)
| [*KDE-games*](https://github.com/ivan-hc/KDE-games-suite-appimage) | ![](https://img.shields.io/github/stars/ivan-hc/KDE-games-suite-appimage?label=%E2%AD%90&style=for-the-badge)
| [*KDE-utils*](https://github.com/ivan-hc/KDE-utils-appimage) | ![](https://img.shields.io/github/stars/ivan-hc/KDE-utils-appimage?label=%E2%AD%90&style=for-the-badge)
| [*LibreOffice Still/Fresh*](https://github.com/ivan-hc/LibreOffice-appimage) | ![](https://img.shields.io/github/stars/ivan-hc/LibreOffice-appimage?label=%E2%AD%90&style=for-the-badge)
| [*MPV*](https://github.com/ivan-hc/MPV-appimage) | ![](https://img.shields.io/github/stars/ivan-hc/MPV-appimage?label=%E2%AD%90&style=for-the-badge)
| [*OBS-Studio*](https://github.com/ivan-hc/OBS-Studio-appimage) | ![](https://img.shields.io/github/stars/ivan-hc/OBS-Studio-appimage?label=%E2%AD%90&style=for-the-badge)
| [*ocenaudio*](https://github.com/ivan-hc/ocenaudio-appimage) | ![](https://img.shields.io/github/stars/ivan-hc/ocenaudio-appimage?label=%E2%AD%90&style=for-the-badge)
| [*Rhythmbox*](https://github.com/ivan-hc/Rhythmbox-appimage) | ![](https://img.shields.io/github/stars/ivan-hc/Rhythmbox-appimage?label=%E2%AD%90&style=for-the-badge)
| [*SpaceCadet Pinball (AUR)*](https://github.com/ivan-hc/Spacecadetpinball-git-appimage) | ![](https://img.shields.io/github/stars/ivan-hc/Spacecadetpinball-git-appimage?label=%E2%AD%90&style=for-the-badge)
| [*Torcs*](https://github.com/ivan-hc/Torcs-appimage) | ![](https://img.shields.io/github/stars/ivan-hc/Torcs-appimage?label=%E2%AD%90&style=for-the-badge)
| [*Transmission-gtk*](https://github.com/ivan-hc/Transmission-gtk-appimage) | ![](https://img.shields.io/github/stars/ivan-hc/Transmission-gtk-appimage?label=%E2%AD%90&style=for-the-badge)
| [*VirtualBox KVM*](https://github.com/ivan-hc/VirtualBox-appimage) | ![](https://img.shields.io/github/stars/ivan-hc/VirtualBox-appimage?label=%E2%AD%90&style=for-the-badge)
| [*VLC Stable/Git*](https://github.com/ivan-hc/VLC-appimage) | ![](https://img.shields.io/github/stars/ivan-hc/VLC-appimage?label=%E2%AD%90&style=for-the-badge)
| [*Database of pkg2appimaged packages**](https://github.com/ivan-hc/Database-of-pkg2appimaged-packages) (*Various sources*) | ![](https://img.shields.io/github/stars/ivan-hc/Database-of-pkg2appimaged-packages?label=%E2%AD%90&style=for-the-badge)

**NOTE, the last one in the table above is a database containing small random apps and games that you may need. The Archimages contained in this repository are:*

| Application |
| -- |
| [*Asunder*](https://github.com/ivan-hc/Database-of-pkg2appimaged-packages/releases/tag/asunder) |
| [*Audacious*](https://github.com/ivan-hc/Database-of-pkg2appimaged-packages/releases/tag/audacious) |
| [*Chromium BSU*](https://github.com/ivan-hc/Database-of-pkg2appimaged-packages/releases/tag/chromium-bsu) |
| [*Falkon*](https://github.com/ivan-hc/Database-of-pkg2appimaged-packages/releases/tag/falkon) |
| [*FileZilla*](https://github.com/ivan-hc/Database-of-pkg2appimaged-packages/releases/tag/filezilla) |
| [*kwave*](https://github.com/ivan-hc/Database-of-pkg2appimaged-packages/releases/tag/kwave) |
| [*Poedit*](https://github.com/ivan-hc/Database-of-pkg2appimaged-packages/releases/tag/poedit) |
| [*Sunvox*](https://github.com/ivan-hc/Database-of-pkg2appimaged-packages/releases/tag/sunvox) |
| [*Webcamoid*](https://github.com/ivan-hc/Database-of-pkg2appimaged-packages/releases/tag/webcamoid) |


### Advantages
- compatibility with all versions of Linux starting from kernel 2.6, therefore also older distributions than those normally indicated by the classic AppImage developers;
- easy and immediate compilation;
- AppRun script very minimal and easy to configure;
- all programs for Arch Linux within AppImage's reach, therefore one of the most extensive software parks in the GNU/Linux panorama.

### Disadvantages
- the AppImage can be bloated if you don't set a list of removable items manually

------------------------------------------------------------------------

| [Back to "Index"](#index) |
| - |

------------------------------------------------------------------------
# Credits
This project wont be possible without:
- **Anylinux** at https://github.com/pkgforge-dev/Anylinux-AppImages for library deploy method (Archimage 5.x and higher) and the debloated packages
- **Conty** at https://github.com/Kron4ek/Conty for the idea and the implementation of Nvidia hardware acceleration support (Archimage 4.x and higher) 
- **JuNest** at https://github.com/fsquillace/junest for the whole base of this project
- **Arch Linux** https://archlinux.org for keep providing brand new software in its repositories

-----------------------------------------------------------
# Related projects
- **"AM"** at https://github.com/ivan-hc/AM, the package manager for AppImage an portable apps for GNU/Linux
- **AppImagen** at https://github.com/ivan-hc/AppImaGen, build AppImage packages using .deb packages from Debian and Ubuntu

------------------------------------------------------------------------

| [**ko-fi.com**](https://ko-fi.com/IvanAlexHC) | [**PayPal.me**](https://paypal.me/IvanAlexHC) | ["Index"](#index) |
| - | - | - |

------------------------------------------------------------------------
