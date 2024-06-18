ArchImage is the bundling of Arch Linux packages into an AppImage using [JuNest](https://github.com/fsquillace/junest).

This allows you to use the latest programs from Arch Linux and AUR on every distribution, old or newer.

Being this a container into an AppImage, it has its own "bubblewrap" to work using its inbuilt resources, including GLIBC, so it can run also on 10+ years old GNU/Linux distributions.

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

[Compared to classic AppImage construction](#compared-to-classic-appimage-construction)
- [Advantages](#advantages)
- [Disadvantages](#disadvantages)

[Files removed by default](#files-removed-by-default)

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

1. Create the script, use the option `-b` or `--build`, example with "firefox" (see the above "[video](#example)"):
```
./archimage-cli -b firefox
```
2. The script will ask you if you want to specify the name of the binary or leave blank if the name is the same of [PROGRAM]. Being the executable `/usr/bin/firefox` of "firefox" named "firefox", press ENTER to leave blank. Some apps, have a different name for their executable (for example "handbrake" have `/usr/bin/ghb`, so just write "ghb" for it). If you're not sure about thename of the main executable, use https://archlinux.org/packages/ or read the PKGBUILD if the app is hosted on the AUR. By default, the script will use "yay" to install all the programs in JuNest.
3. The script will ask you to add a list of additional packages you want to include into the AppImage (with the syntax `app1 app2 app3...`), leave blank if no dependency is needed.
4. The next questions are about implementing or not all dependences, choose "Y" to bundle all the dependences, or "N" to do this in other steps.
5. This phase, shown in the [video](#example), has a last message asking you to use a standard configuration with the following defaults if you press "Y":
- a package availability check in the Arch User Repository (if so, enable AUR and installs "binutils", "gzip" and "basedevel", all of them are only required to compile from and will not be included in the AppImage package)
- the AUR is enabled
- installs "ca-certificates"
- includes keywords for the internet connections and audio trying to enable them
- the file "/usr/lib/dri/swrast_dri.so" will NOT be included if not needed
If you press "N" (or leave blank) instead, you have a lot of configurations you can do by your own.
6. Run the script.

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
- hardware acceleration is absent (for now), see https://github.com/ivan-hc/ArchImage/issues/20

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

For more detailed output, I redirect you to the guide on the usage of `LD_DEBUG`, at https://www.bnikolic.co.uk/blog/linux-ld-debug.html

For example, to know what are the missing libraries:
```
LD_DEBUG=libs ./AppRun
```
and then add the missing libraries from the directory "junest-backups" and try again until your app runs as expected. 

3. Add your changes to your script and try to rebuild the AppImage.

If you have any doubts you can [open an issue](https://github.com/ivan-hc/ArchImage/issues) or search for a solution among the existing ones ([here](https://github.com/ivan-hc/ArchImage/issues?q=)).

------------------------------------------------------------------------

| [Back to "Index"](#index) |
| - |

------------------------------------------------------------------------
# Credits
This project wont be possible without:
- JuNest https://github.com/fsquillace/junest
- Arch Linux https://archlinux.org

-----------------------------------------------------------
# Related projects
- "AM", the package manager for AppImage an portable apps for GNU/Linux https://github.com/ivan-hc/AM
- "AppImagen", build AppImage packages using .deb packages from Debian and Ubuntu https://github.com/ivan-hc/AppImaGen
