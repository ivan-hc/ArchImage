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

https://github.com/user-attachments/assets/4f7cc08f-1c08-468a-b654-44bab268ad94

*Video sped up due to GitHub limitations for media uploads. Real-time 30 minutes and 30 seconds.*

------------------------------------------------------------------------
### Index
------------------------------------------------------------------------

[Installation](#installation)

[Usage](#usage)
- [Options](#options)

- [What to do](#what-to-do)
  - [Archimage versions](#archimage-versions)

- [What NOT to do](#what-not-to-do)

- [Step by step guide](#step-by-step-guide)

- [Requirements of an AppImage](#requirements-of-an-appimage)

- [Archimage structure](#archimage-structure)

- [Test the AppImage](#test-the-appimage)
  - [Dotfiles tip](#dotfiles-tip)
  - [Repeat the build](#repeat-the-build)
  - [Extraction levels](#extraction-levels)

[Tutorial](#tutorial)

[Hardware Acceleration](#hardware-acceleration)

[Compared to classic AppImage construction](#compared-to-classic-appimage-construction)
- [Advantages](#advantages)
- [Disadvantages](#disadvantages)

[Files removed by default](#files-removed-by-default)

[Customize your script](#customize-your-script)

[Drafts](#drafts)

[Troubleshooting](#troubleshooting)

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

### Archimage versions
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
For more verbose output, use `LD_DEBUG`, like this:
```
LD_DEBUG=libs ./Sample-1.2.3-x86_64.AppImage
```
to see the missing libraries, or
```
LD_DEBUG=files ./Sample-1.2.3-x86_64.AppImage
```
to see the missing files.

I redirect you to the guide on the usage of `LD_DEBUG`, at https://www.bnikolic.co.uk/blog/linux-ld-debug.html

### Dotfiles tip
To not flood your $HOME with dotfiles, I recommend creating a .home directory with the same name as the AppImage:
```
mkdir Sample-1.2.3-x86_64.AppImage.home
./Sample-1.2.3-x86_64.AppImage
```
I suggest you empty it or remove/recreate it at the end of each test, in order to rewrite the dotfiles using a clean configuration.

### Repeat the build
If you encounter any problems after testing, manually edit the script by adding dependencies or keywords in the respective listed variables, then run the script again to build the AppImage.
```
./sample-junest.sh
```
This will repeat the construction of the AppImage starting from the shortcomings of the Arch Linux container.

On-screen messages will tell you what's happening.

Wait until the end and try the AppImage again.

Run the tests until you get the desired result.

### Extraction levels
Since version 4.2 you can set extraction levels by assigning the variable "$extraction_count" (in the middle of the script) a number from zero and up. The default value is 1. Here's what the number means:
- level 0 extracts only the dependencies, the "optdepends" and the dependencies you specify in the variable "DEPENDENCES"
- level 1 is the default, it extracts the dependencies of dependencies of the main package (not the "optdepends") and the dependencies of packages in "DEPENDENCES"
- level 2 extracts the dependencies of the packages extracted at point 1
- level 3 extracts the dependencies of the packages at point 2

...and so on.

If you decide to include all the dependencies, the package will be much larger, and at the same time you will have a better chance of running the program you are building.

If you decide NOT to include the dependencies, you will still have all the files to check to include only the libraries shared between the dependencies.

However, there is no guarantee that the AppImage will work immediately. Please refer to the "[tutorial](#tutorial)" to perform your own tests.

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
If you are an Nvidia user, hardware accelleration is provided by [Conty](https://github.com/Kron4ek/Conty). At first start it will copy Nvidia libraries locally to allow the builtin Arch Linux container the use of hardware accelleration.

According to the Conty project, the drivers will be placed in a "Conty" directory located in $HOME/.local/share. If you already use a Conty container or run other Archimages v4 or higher, you will be able to use the same drivers.

The check is enabled in the AppRun, the script inside the AppImage, using the variable `NVIDIA_ON` with a value equal to `1`. To disable it, simply assign a different value to this variable, for example `0`. The creators of the AppImage will be able to decide whether to enable it during the creation of the script, via `archimage-cli`, from version 4 onwards, or they can enable it manually.

- Archimage v4 was able to download a script that used a mini `conty.sh` to compile the Nvidia drivers using the official online installer, and it took a few minutes to complete the process
- Archimage v4.1 instead is able to intercept the drivers installed on the system and copy them locally, taking less than a second

**It is recommended to keep your Archimages up to date with the portion of the code available in new releases.**

<details>
  <summary>Click here to see the part of the AppRun that handles Nvidia drivers</summary>

```
[ -z "$NVIDIA_ON" ] && NVIDIA_ON=1
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
```

For the existing Archimages, its enough to add this part to the AppRun.

</details>

By default the value inside the templates and AppRuns is set to "`0`"
```
NVIDIA_ON=0
```

NOTE, make sure your release has Archimage version 4.1 or higher in the file name.

------------------------------------------------------------------------

| [Back to "Index"](#index) |
| - |

------------------------------------------------------------------------
# Compared to classic AppImage construction
In the past AppImages were built using .deb packages or guessing instructions to make them work. With the "ArchImage" method all you have to do is the reverse, i.e. "delete" what is no longer needed.

For example, an OBS Studio ArchImage equals 650MB in total, I managed to get it to 260MB by removing what wasn't necessary, while now (since Archimage2.x was released) is about 180MB.

This is a list of the AppImages I've built until I wrote this brief guide:
- Abiword https://github.com/ivan-hc/Abiword-appimage
- GIMP Stable & Deveveloper Edition https://github.com/ivan-hc/GIMP-appimage
- Gnumeric https://github.com/ivan-hc/Gnumeric-appimage
- Handbrake https://github.com/ivan-hc/Handbrake-appimage
- MPV https://github.com/ivan-hc/MPV-appimage
- OBS Studio https://github.com/ivan-hc/OBS-Studio-appimage
- VLC https://github.com/ivan-hc/VLC-appimage

### Advantages
- compatibility with all versions of Linux starting from kernel 2.6, therefore also older distributions than those normally indicated by the classic AppImage developers;
- easy and immediate compilation;
- AppRun script very minimal and easy to configure;
- all programs for Arch Linux within AppImage's reach, therefore one of the most extensive software parks in the GNU/Linux panorama.

### Disadvantages
- the AppImage can be bloated if you don't set a list of removable items manually

------------------------------------------------------------------------

# Drafts
You can download some experimental scripts made with this tool and to which I have not dedicated a repository (also because I have too many) at the following link:

https://github.com/ivan-hc/ArchImage/tree/main/drafts

in my experiments, if I uploaded them here, it means that they work quite well or at least start the graphical interface. I have not looked into their operation. If you want, you can download them and modify them to your liking, or even open a dedicated repository.

------------------------------------------------------------------------

# Files removed by default
The following function is responsible of removals of unneeded files and directories, you can find it to the end of the script
```
_remove_more_bloatwares() {
	etc_remove="makepkg.conf pacman"
	for r in $etc_remove; do
		rm -Rf ./"$APP".AppDir/.junest/etc/"$r"*
	done
	bin_remove="gcc"
	for r in $bin_remove; do
		rm -Rf ./"$APP".AppDir/.junest/usr/bin/"$r"*
	done
	lib_remove="gcc"
	for r in $lib_remove; do
		rm -Rf ./"$APP".AppDir/.junest/usr/lib/"$r"*
	done
	share_remove="gcc"
	for r in $share_remove; do
		rm -Rf ./"$APP".AppDir/.junest/usr/share/"$r"*
	done
	echo Y | rm -Rf ./"$APP".AppDir/.cache/yay/*
	find ./"$APP".AppDir/.junest/usr/share/doc/* -not -iname "*$BIN*" -a -not -name "." -delete 2> /dev/null #REMOVE ALL DOCUMENTATION NOT RELATED TO THE APP
	find ./"$APP".AppDir/.junest/usr/share/locale/*/*/* -not -iname "*$BIN*" -a -not -name "." -delete 2> /dev/null #REMOVE ALL ADDITIONAL LOCALE FILES
	rm -Rf ./"$APP".AppDir/.junest/home # remove the inbuilt home
	rm -Rf ./"$APP".AppDir/.junest/usr/include # files related to the compiler
	rm -Rf ./"$APP".AppDir/.junest/usr/share/man # AppImages are not ment to have man command
	rm -Rf ./"$APP".AppDir/.junest/usr/lib/python*/__pycache__/* # if python is installed, removing this directory can save several megabytes
	#rm -Rf ./"$APP".AppDir/.junest/usr/lib/libgallium*
	#rm -Rf ./"$APP".AppDir/.junest/usr/lib/libgo.so*
	#rm -Rf ./"$APP".AppDir/.junest/usr/lib/libLLVM* # included in the compilation phase, can sometimes be excluded for daily use
	rm -Rf ./"$APP".AppDir/.junest/var/* # remove all packages downloaded with the package manager
}
```
it contains 4 variables:
- `etc_remove` to remove files in /etc
- `bin_remove` to remove files in /usr/bin
- `lib_remove` to remove files and directories in /usr/lib
- `share_remove` to remove files and directories in /usr/share

it is enough to add the name or the first keywords of the names you want to remove. For example if you add `z` in `share_remove`, all directories starting with "z" will be removed. If you add `icons/Adwaita/cursors/` in `share_remove`, all files under /usr/share/icons/Adwaita/cursors/ will be removed.

A known list of big ligraries is also commented in this function (`libgallium`, `libgo.so` and `libLLVM`), uncomment if the app works without them.

The `find` commands of the abofe function will remove languages and documentation not related to "`$BIN`" (the binary name of the app, in most cases the value is `BIN="$APP"`, but it may change, depending on the script you have created.

------------------------------------------------------------------------
# Customize your script
Once you created the script, it is yours and only yours. You can add/remove functions as you like.

Of course, **DO IT ON YOUR OWN RISK!**

------------------------------------------------------------------------

| [Back to "Index"](#index) |
| - |

------------------------------------------------------------------------
# Troubleshooting
1. If the AppImage is already bundled, extract the AppImage using `./*.AppImage --appimage-extract`
2. Execute the AppRun file:
```
./AppRun
```
In case you wont to parse dotfiles in your $HOME directory, use the AppDir itself as a custom $HOME, like this:
```
cd ./*.AppDir
HOME="$(dirname "$(readlink -f $0)")"
./AppRun
```
It is now possible to read errors related to the application.

For more verbose output, use `LD_DEBUG`, like this (for example, to know what are the missing libraries):
```
LD_DEBUG=libs ./AppRun
```
I redirect you to the guide on the usage of `LD_DEBUG`, at https://www.bnikolic.co.uk/blog/linux-ld-debug.html

See also

- [Archimage structure](#archimage-structure)
- [Test the AppImage](#test-the-appimage)
- [Dotfiles tip](#dotfiles-tip)
- [Repeat the build](#repeat-the-build)

If you have any doubts you can [open an issue](https://github.com/ivan-hc/ArchImage/issues) or search for a solution among the existing ones ([here](https://github.com/ivan-hc/ArchImage/issues?q=)).


------------------------------------------------------------------------

| [Back to "Index"](#index) |
| - |

------------------------------------------------------------------------
# Credits
This project wont be possible without:
- Conty https://github.com/Kron4ek/Conty
- JuNest https://github.com/fsquillace/junest
- Arch Linux https://archlinux.org

-----------------------------------------------------------
# Related projects
- "AM", the package manager for AppImage an portable apps for GNU/Linux https://github.com/ivan-hc/AM
- "AppImagen", build AppImage packages using .deb packages from Debian and Ubuntu https://github.com/ivan-hc/AppImaGen

------------------------------------------------------------------------

| [**ko-fi.com**](https://ko-fi.com/IvanAlexHC) | [**PayPal.me**](https://paypal.me/IvanAlexHC) | ["Index"](#index) |
| - | - | - |

------------------------------------------------------------------------
