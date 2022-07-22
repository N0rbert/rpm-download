# rpm-download

Shell script for downloading rpm-package(s) from modern RPM repositories

Under the hood this script uses Docker to obtain minimal file-system of needed system release. And then it download package(s) to the `storage` sub-directory and saves the list of download URL(s) in `storage/urls.txt` file. The created Docker images will be named with `rd-` prefix, you can remove them manually later.

The `rpm-download.sh` takes at least three pairs of arguments, as shown in example below:

```
./rpm-download.sh -d alt -r p8 -p mc
```

* `-d` (distribution, mandatory) - `alt` for ALTLinux, `fedora` for Fedora, `mageia` for Mageia, `opensuse` for OpenSuSe;
* `-r` (release, mandatory) - supported versions are the following: ALTLinux from `p8` to `sisyphus`, Fedora from `22` to `rawhide`, Mageia from `7` to `cauldron`, OpenSuSe from `leap` to `tumbleweed`;
* `-p` (with quotes for multiple packages, mandatory) - represent package(s) name(s) - in the above example it is single `mc` package. For two packages use `"mc htop"` (for example);
* `-s` (get source code of package(s), optional);
* `-a` (enable Autoimports for ALTLinux, optional).

Note: if you have configured proxy in your network, then you can supply its address as the argument to the application - `http_proxy=http://192.168.12.34:8000 ./rpm-download.sh -d alt -r p8 -p mc` .

How to start using this script:

1. Install Docker and dependencies to the host system
   
       sudo apt-get update
       sudo apt-get install docker.io git

1. Add current user to the `docker` group
   
       sudo usermod -a -G docker $USER
   
   then reboot machine.

1. Clone this repository

       cd ~/Downloads
       git clone https://github.com/N0rbert/rpm-download.git

1. Fetch some random rpm-package

       cd rpm-download
       chmod +x rpm-download.sh
       ./rpm-download.sh -d alt -r p9 -p fslint

1. Carefully inspect the contents of `storage` folder, then try to install main rpm-package to the target system, then fix its dependencies one-by-one.

   Please also note that this `storage` folder will be cleared on next run of the script!

**Warning:** author of this script can't provide any warranty about successful installation of downloaded rpm-packages on the target system. Be careful!
