Official repository - get binary and source package:

```
http_proxy=http://192.168.3.222:8000 ./rpm-download.sh -d alt -r p10 -p 'mate-panel' -s && tree storage
http_proxy=http://192.168.3.222:8000 ./rpm-download.sh -d fedora -r 35 -p 'mate-panel' -s && tree storage
http_proxy=http://192.168.3.222:8000 ./rpm-download.sh -d mageia -r 8 -p 'mate-panel' -s && tree storage
http_proxy=http://192.168.3.222:8000 ./rpm-download.sh -d openmandriva -r 4.2 -p htop -s && tree storage
http_proxy=http://192.168.3.222:8000 ./rpm-download.sh -d opensuse -r leap -p 'mate-panel' -s && tree storage
http_proxy=http://192.168.3.222:8000 ./rpm-download.sh -d rosa -r 2021.1 -p 'meld' -s && tree storage
http_proxy=http://192.168.3.222:8000 ./rpm-download.sh -d rockylinux -r 9.2 -p 'bash' -s && tree storage
http_proxy=http://192.168.3.222:8000 ./rpm-download.sh -d almalinux -r 9.2 -p 'bash' -s && tree storage
http_proxy=http://192.168.3.222:8000 ./rpm-download.sh -d redos -r latest -p 'bash' -s && tree storage # src.rpm are not available
```

Third-party repository as .repo-URL - get only binary:

```
http_proxy=http://192.168.3.222:8000 ./rpm-download.sh -d fedora -r 35 -p 'VirtualBox-6.1' -t "https://download.virtualbox.org/virtualbox/rpm/fedora/virtualbox.repo" && tree storage
http_proxy=http://192.168.3.222:8000 ./rpm-download.sh -d opensuse -r 15.3 -p 'VirtualBox-6.1' -t "https://download.virtualbox.org/virtualbox/rpm/opensuse/virtualbox.repo" && tree storage
http_proxy=http://192.168.3.222:8000 ./rpm-download.sh -d rockylinux -r 9.2 -p 'VirtualBox-6.1' -t "https://download.virtualbox.org/virtualbox/rpm/el/virtualbox.repo" && tree storage
http_proxy=http://192.168.3.222:8000 ./rpm-download.sh -d almalinux -r 9.2 -p 'VirtualBox-6.1' -t "https://download.virtualbox.org/virtualbox/rpm/el/virtualbox.repo" && tree storage
```

Third-party repository as .repo-URL - get binary and source:

```
http_proxy=http://192.168.3.222:8000 ./rpm-download.sh -d opensuse -r leap -p 'ayatana-settings' -s -t "https://download.opensuse.org/repositories/home:/Ionic:/branches:/X11:/Unity/openSUSE_Leap_15.4/home:Ionic:branches:X11:Unity.repo" && tree storage
http_proxy=http://192.168.3.222:8000 ./rpm-download.sh -d opensuse -r tumbleweed -p 'ayatana-settings' -s -t "https://download.opensuse.org/repositories/home:/Ionic:/branches:/X11:/Unity/openSUSE_Tumbleweed/home:Ionic:branches:X11:Unity.repo" && tree storage
```

Third-party repository as URL with LABEL - get only binary:

```
http_proxy=http://192.168.3.222:8000 ./rpm-download.sh -d fedora -r 35 -p 'drweb-workstations' -t "https://repo.drweb.com/drweb/linux/11.1/x86_64/ drweb" && tree storage
http_proxy=http://192.168.3.222:8000 ./rpm-download.sh -d mageia -r 8 -p 'drweb-workstations' -t "https://repo.drweb.com/drweb/linux/11.1/x86_64/ drweb" && tree storage
http_proxy=http://192.168.3.222:8000 ./rpm-download.sh -d opensuse -r leap -p 'drweb-workstations' -t "https://repo.drweb.com/drweb/linux/11.1/x86_64/ drweb" && tree storage
```

Third-party repository as sources.list line for ALTLinux - get only binary:

```
http_proxy=http://192.168.3.222:8000 ./rpm-download.sh -d alt -r p9 -p anydesk -t "rpm http://altrepo.ru/local-p9 x86_64 local-p9" && tree storage
http_proxy=http://192.168.3.222:8000 ./rpm-download.sh -d alt -r p10 -p drweb-workstations -t "rpm https://repo.drweb.com/drweb/altlinux 11.1/x86_64 drweb" && tree storage
```

Third-party task as for ALTLinux - get only binary:

```
http_proxy=http://192.168.3.222:8000 ./rpm-download.sh -d alt -r p8 -p 'pciids' -t "task 303713" && tree storage
```
