# ArchImage
Build AppImage packages for all distributions by including Arch Linux packages. Powered by JuNest.

# What is this?
ArchImage is the bundling of Arch Linux packages into an AppImage using [JuNest](https://github.com/fsquillace/junest).

This allows you to use the latest programs from Arch Linux and AUR on every distribution, old or newer.

# Installation
Download the main script and made it executable:

    wget https://raw.githubusercontent.com/ivan-hc/ArchImage/main/archimage-cli
    chmod a+x ./archimage-cli

# Usage

    ./archimage-cli [OPTION]
or

    ./archimage-cli [OPTION] [PROGRAM]

This tool will create a script to compile an AppImage based on JuNest. To create the script use the option `-b` or `--build`, example:

    ./archimage-cli -b handbrake
Here we are using "handbrake", the script will ask you if you want to specify the name of the binary or leave blank if the name is the same of [PROGRAM], being the executable not `/usr/bin/handbrake` but `/usr/bin/ghb`, just write "ghb". If you're not sure about thename of the main executable, use https://archlinux.org/packages/ or read the PKGBUILD if the app is hosted on the AUR. By default, the script will use "yay" to install all the programs in JuNest.

After you've/you've not named the executable, the script will ask you to add a list of additional packages you want to include into the AppImage (with the syntax `app1 app2 app3...`).

Finally you've finished and you're ready to run the final script. This will automatically build all the stuff starting from the less options you've decided.

# Suggestion
At line 88 of the script it is possible to manually add the list of files and folders to delete, check the contents of "AppDir" (the folder of the AppImage to be created), JuNest is installed in `$PROGRAM.AppDir/.junest` and is equivalent to the root of the Arch Linux guest. 

# Compared to classic AppImage construction
In the past AppImages were built using .deb packages or guessing instructions to make them work. With the "ArchImage" method all you have to do is the reverse, i.e. "delete" what is no longer needed.

For example, an OBS Studio ArchImage equals 650MB in total, I managed to get it to 260MB by removing what wasn't necessary. This is the only disadvantage, having to look for the files to delete requires a long search... but at least you already have a working program using minimal effort!

This is a list of the AppImages I've built until I wrote this brief guide:
- Abiword https://github.com/ivan-hc/Abiword-appimage
- Gnumeric https://github.com/ivan-hc/Gnumeric-appimage
- MPV https://github.com/ivan-hc/MPV-appimage
- OBS Studio https://github.com/ivan-hc/OBS-Studio-appimage

### Advantages
- compatibility with all versions of Linux starting from kernel 2.6, therefore also older distributions than those normally indicated by the classic AppImage developers;
- easy and immediate compilation;
- AppRun script very minimal and easy to configure;
- all programs for Arch Linux within AppImage's reach, therefore one of the most extensive software parks in the GNU/Linux panorama.

### Disadvantages
Since JuNest is a standalone system, it won't be able, for example, to open the host's browser, it relies almost completely on its own built-in resources.

# How a newly created script works
This video is from when this repository was created, since then the Appimage build script has greatly improved.

https://github.com/ivan-hc/ArchImage/assets/88724353/6335f0c4-c274-4e6c-9360-d22a24bb8594

# This project wont be possible without
- JuNest https://github.com/fsquillace/junest
- Arch Linux https://archlinux.org

# Related projects
- Portable Linux Apps https://portable-linux-apps.github.io
- "AM" Application Manager https://github.com/ivan-hc/AM-Application-Manager 
