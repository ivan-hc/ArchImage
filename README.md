ArchImage is the bundling of Arch Linux packages into an AppImage using [JuNest](https://github.com/fsquillace/junest).

This allows you to use the latest programs from Arch Linux and AUR on every distribution, old or newer.

------------------------------------------
- [Installation](#installation)
- [Usage](#usage)
- [Compared to classic AppImage construction](#compared-to-classic-appimage-construction)
- [Troubleshooting](#troubleshooting)
- [Credits](#credits)
- [Related projects](#related-projects)

------------------------------------------

# Installation
Download the main script and made it executable:

    wget https://raw.githubusercontent.com/ivan-hc/ArchImage/main/archimage-cli
    chmod a+x ./archimage-cli

# Usage
In this video I will show all the steps that I will describe in this section:

https://github.com/ivan-hc/ArchImage/assets/88724353/d53f7e11-ceb3-4bc4-bee9-9372fd88cf8d


### Step 1: create the script
    ./archimage-cli [OPTION]
or

    ./archimage-cli [OPTION] [PROGRAM]

This tool will create a script to compile an AppImage based on JuNest. To create the script use the option `-b` or `--build`, example:

    ./archimage-cli -b handbrake
Here we are using "handbrake", the script will ask you if you want to specify the name of the binary or leave blank if the name is the same of [PROGRAM], being the executable not `/usr/bin/handbrake` but `/usr/bin/ghb`, just write "ghb". If you're not sure about thename of the main executable, use https://archlinux.org/packages/ or read the PKGBUILD if the app is hosted on the AUR. By default, the script will use "yay" to install all the programs in JuNest.

After you've/you've not named the executable, the script will ask you to add a list of additional packages you want to include into the AppImage (with the syntax `app1 app2 app3...`).

### Step 2: run the script
Finally you've finished and you're ready to run the final script. This will automatically build all the stuff starting from the less options you've decided.

# Compared to classic AppImage construction
In the past AppImages were built using .deb packages or guessing instructions to make them work. With the "ArchImage" method all you have to do is the reverse, i.e. "delete" what is no longer needed.

For example, an OBS Studio ArchImage equals 650MB in total, I managed to get it to 260MB by removing what wasn't necessary. This is the only disadvantage, having to look for the files to delete requires a long search... but at least you already have a working program using minimal effort!

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
Since JuNest is a standalone system, it won't be able, for example, to open the host's browser, it relies almost completely on its own built-in resources.

# Troubleshooting
If your AppImage package isn't working, here's how to debug it:
1. Edit the "AppRun" file in the directory with the .AppRun extension and remove `2> /dev/null` from the end of the last line. Save changes to the file;
2. Execute the AppRun file, I suggest to set the AppDir as a temporary $HOME directory, like this:
```
cd ./*.AppDir
HOME=./
./AppRun
```
It is now possible to read errors related to application execution in JuNest.

If you have any doubts you can [open an issue](https://github.com/ivan-hc/ArchImage/issues) or search for a solution among the existing ones ([here](https://github.com/ivan-hc/ArchImage/issues?q=)).

# Credits
This project wont be possible without:
- JuNest https://github.com/fsquillace/junest
- Arch Linux https://archlinux.org

# Related projects
- Portable Linux Apps https://portable-linux-apps.github.io
- "AM" Application Manager https://github.com/ivan-hc/AM-Application-Manager 
