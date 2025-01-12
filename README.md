ArchImage is the bundling of Arch Linux packages into an AppImage using [JuNest](https://github.com/fsquillace/junest). Hardware accelleration is provided by [Conty](https://github.com/Kron4ek/Conty) instead.

This allows you to use the latest programs from Arch Linux and AUR on every distribution, old or newer.

Being this a container into an AppImage, it has its own "bubblewrap" or "proot" to work using its inbuilt resources, including GLIBC, so it can run also on 10+ years old GNU/Linux distributions.

From version 4.2 is available a NEW template that creates AppImages that can work on both systems with or without Namespaces restrictions:

- [NEW-junest.sh](https://github.com/ivan-hc/ArchImage/blob/main/NEW-junest.sh)

It is the mix of the two previous templates used until version 4.1:
- [sample-next-junest.sh](https://github.com/ivan-hc/ArchImage/blob/main/sample-next-junest.sh) uses bubblewrap and namespaces, so it is more flexible
- [sample-junest.sh](https://github.com/ivan-hc/ArchImage/blob/main/sample-junest.sh) uses proot to be more portable but less integrated with the host system

Archimage combines the flexibility of JuNest with the power of Conty, the two portable Arch Linux containers that run on any other GNU/Linux distribution, offering the ability to package all the software available in the official Arch Linux repositories, the AUR and ChaoticAUR.

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
  - [Dotfiles tip](#dotfiles-tip)
  - [Repeat the build](#repeat-the-build)

[Tutorial](#tutorial)

[Hardware Acceleration](#hardware-acceleration)

[Compared to classic AppImage construction](#compared-to-classic-appimage-construction)
- [Advantages](#advantages)
- [Disadvantages](#disadvantages)

[Files removed by default](#files-removed-by-default)

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
-v,--version	Shows the version.
-b,--build		Create the script to build the AppImage.
-s,--sync		Update archimage-cli to the latest version.
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

#### EXAMPLE
In this video I will show all the steps that I will describe in this section (Archimage 3.4.2):

https://github.com/ivan-hc/ArchImage/assets/88724353/d7ecb9e5-1db7-4d5c-ae6b-374b6c32e87c

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

1. Create the script, use the option `-b` or `--build`, example with "obs-studio"
```
./archimage-cli -b obs-studio
```

![1](https://github.com/user-attachments/assets/d9c7b29b-2ccc-4cf0-b3ff-5de10cf13e5b)

this will download and rename the script [NEW-junest.sh](https://github.com/ivan-hc/ArchImage/blob/dev/NEW-junest.sh) on your desktop.

2. The script will ask you if you want to specify the name of the binary or leave blank if the name is the same of [PROGRAM]. In most cases we can leave blank, but for some applications, like OBS Studio, the executable name is different, in our case it is `obs`

![2](https://github.com/user-attachments/assets/961d03ec-9c6a-4faa-a9ab-fa7dbb557b14)

If you're not sure about thename of the main executable, use https://archlinux.org/packages/ or read the PKGBUILD if the app is hosted on the AUR. By default, the script will use "yay" to install all the programs in JuNest.

3. The script will ask you to add a list of additional packages you want to include into the AppImage (with the syntax `app1 app2 app3...`)

![3](https://github.com/user-attachments/assets/2d6a3a5a-9fab-4c32-9081-d5bf5f51fe28)

leave blank if no dependency is needed. In our example, we are using Archimage version 4.2, so we don't need add dependencies for `obs-studio`. Previous versions were less automatic and to build `obs-studio` we needed to add `python`. You can add many more packages, according to your needs.

4. Assign a number to the variable "`$extraction_count`". The higher the number, the more dependencies will be downloaded separately, the longer the process will be, the bigger the final AppImage package will be... but at the same time the easier our AppImage will work.

![4](https://github.com/user-attachments/assets/7e46e63a-8a60-426f-91c3-6eca36effb15)

By default the level is 1, so only the dependencies of the direct dependencies of the application we want to package are extracted. For OBS Studio I set a level of 2, and this is enough to have an AppImage that works out of the box, but only if you include all dependencies and set the "**standard  configuration**". Keep read.

5. Do you want to include all dependencies? Press "y", or leave blank if you want to keep customize (recommended)

![5](https://github.com/user-attachments/assets/d50dd4bc-9bd4-43d9-82d7-6819d7c86d74)

In my workflows I usually include all dependencies, to remove the extra files after I confirm that the application works.

If you press "N" or leave blank, only the main package will be included, near the libraries and files imported when the script is running.

Please, see the [tutorial](#tutorial) to learn more on how to investigate on app's malfunctions.

5,5. Between question 5 (include all dependencies) and 6 (enable multilib) exists another hidden question

![Istantanea_2025-01-12_07-20-18](https://github.com/user-attachments/assets/ab650430-a2da-4663-ae9d-c4d97d3f4103)

this question come up only if the program is not hosted on the official repositories, so it come from AUR.

In this case `binutils`, `gzip` and `base-devel` are enabled by default. You can choose to enable ChaoticAUR to save time and resources while compiling the program. For example `gimp-git` lasts 5 minutes or less from ChaoticAUR, while from AUR it can take 30 minutes or more (with the risk that it fails).

Of course, this question will not come up with `obs-studio`, since it is on the official Arch Linux repositories.

6. Want to enable the "multilib" repo? It is usally needed for 32bit libraries, used in programs like WINE and frontends like Bottles

![Istantanea_2025-01-12_06-53-42](https://github.com/user-attachments/assets/2e036728-49d5-4362-a042-f6b44efff393)

in our case, we can leave blank or press "N". We don't need 32 bits libraries at all in this case.

7. Do you want to allow hardware acceleration? This will enable Nvidia users to use your application where hardware acceleration is needed

![Istantanea_2025-01-12_06-55-57](https://github.com/user-attachments/assets/2bd7483d-c521-4827-b7b8-20bb6301f704)

to learn more on how hardware acceleration works with Archimages, see "[Hardware Acceleration](#hardware-acceleration)".

8. Standard configuration only enables keywords for Networking and Audio. If you have choosen to include all dependencies at point 5, press "y". This will exit the wizard

![8](https://github.com/user-attachments/assets/c0f55b4f-b28f-4153-8735-14cf23ea8b92)

if you press N or leave blank, you can keep customize the script.

9. Junest is a very minimal system, you can choose to include `gzip` and `binutils` if you know that none of the previous packages will install them as dependencies.
10. If you need to build something from AUR, enable `base-devel` with all its related compilers

This is how questions 9 and 10 appear

![9-10](https://github.com/user-attachments/assets/0595778d-1687-4546-b3b4-3a26cffb095e)

10. Questions about keywords for binaries in /usr/bin, directories in /usr/share and various files and directories (mostly libraries) in /usr/lib are up to you. For example, if you want to include all Qt related files and directories, write `Qt` for the question related to the interested path. In my case I included `libgallium.so`, the search will be done using `find` and `grep`

![Istantanea_2025-01-12_07-08-55](https://github.com/user-attachments/assets/1cb78573-d653-4866-a770-fbc95207977f)

11. Next two questions are related to a preset of keywords used to check files and libraries for networking and audio, the same that can be enabled in one go at point 8

![Istantanea_2025-01-12_07-12-50](https://github.com/user-attachments/assets/adc17a3b-36b9-4d27-8d8b-7d5f1f32df94)

Personally I never go further than point 8, and press "y", because the script is simple enough to understand, if you have the patience to read what is written. So i prefer to edit manually my scripts when they are ready.

At the end of the wizard you will have a series of suggestions like this

![Istantanea_2025-01-12_07-19-02](https://github.com/user-attachments/assets/139698b4-c2aa-4675-9840-4c7c93e73c39)

now you can finally run the script in an empty and dedicated directory.

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
An Archimage is a Type3 AppImage, i.e. one that does not require libfuse2 to function.

Unlike many other AppImages, its structure, [other than the requirements above](#requirements-of-an-appimage), resembles a $HOME directory:
```
App.AppDir/
  |
  |_/App.desktop
  |
  |_/app.png
  |
  |_/.cache/
  |
  |_/.local/share/junest/
  |
  |_/.junest/
```
Hidden directories are those used in a normal Junest installation:
- ".junest" contains the Arch Linux system;
- ".local/share/junest" contains the JuNest files to start Arch Linux in a container;
- ".cache" is usually empty and used by YAY during the temporary JuNest session.

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

------------------------------------------------------------------------

# Drafts
You can download some experimental scripts made with this tool and to which I have not dedicated a repository (also because I have too many) at the following link:

https://github.com/ivan-hc/ArchImage/tree/main/drafts

in my experiments, if I uploaded them here, it means that they work quite well or at least start the graphical interface. I have not looked into their operation. If you want, you can download them and modify them to your liking, or even open a dedicated repository.

------------------------------------------------------------------------

# Files removed by default
After the line "`# REMOVE SOME BLOATWARES`" I added a list of functions that you can use with Archimage 2.x and above. You can edit the script as you like to add/remove files in case they are not enough for your experiments.

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
