# ArchImage
Build AppImage packages for all distributions by including Arch Linux packages. Powered by JuNest.

#### NOTE: this solution is highly experimental! *Please, read carefully!*

# What is this?
ArchImage is the bundling of Arch Linux packages into an AppImage using [JuNest](https://github.com/fsquillace/junest).

This allows you to use the latest programs from Arch Linux and AUR on every distribution, old or newer.

# What works?
Only the scripts to create the AppImage on your system, but only for your user.

# What is not working?
The portability of the AppImage. For now the only way to made it work for other users is to extract it. Alternativelly you must download the installation script and create it by yourself.

This method is still highly experimental.

# Known issue
- JuNest runs in isolation, it won't be able to see mounted partitions unless explicitly specified in the script used to create the Appimage.
- Due to isolation, it will not be possible to launch a link in the browser or any application installed on the host, these "should" be included in the Appimage itself to work.

# Usage
In this example I'm working for an AppImage of OBS Studio:

    mkdir tmp
    cd tmp
    wget https://raw.githubusercontent.com/ivan-hc/ArchImage/main/apps/obs-junest.sh
    chmod a+x ./obs-junest.sh
    ./obs-junest.sh

Wait the time that the AppImage is ready before you test it wherever you want but on your system, for your user only.

https://github.com/ivan-hc/ArchImage/assets/88724353/6335f0c4-c274-4e6c-9360-d22a24bb8594

# Main issue
The only problem I encountered while testing the AppImage under a different account was that it recognized the $HOME as a read-only filesystem. Junest by default must rewrite and update its wrapper scripts, and cannot do so if forced into a read-only file system.

The only way you can get the app to work is to extract the AppImage:

    ./*AppImage --appimage-extract
To use the app instead:

    ./squashfs-root/AppRun

In the example of OBS Studio, the resulting archive is just over 400MB (note that the /var directory is removed in the script, if we include it, the AppImage reached 650MB), extracted reaches 1.7GB (but it may be possible to remove something else in future, just knowing how to investigate).

# Conclusion
This repository is only a work in progress. If you like the idea, please consider to fork and contribute to improve this solution. Thank you in advance.
