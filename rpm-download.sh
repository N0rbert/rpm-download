#!/bin/bash
usage="$(basename "$0") [-h] [-d DISTRO] [-r RELEASE] [-p \"PACKAGE1 PACKAGE2 ..\"] [-s] [-a] [-t]
Download rpm-package(s) for given distribution release,
where:
    -h  show this help text
    -d  distro name (alt, fedora, mageia, openmandriva, opensuse, rosa, rockylinux)
    -r  release name (p8/p9/p10/sisyphus, 22 to rawhide, 7 to cauldron, 4.2 and cooker, leap and tumbleweed, only 2021.1, from 8.4)
    -p  packages
    -s  also download source-code package(s) (optional)
    -a  enable Autoimports repository (optional for ALTLinux)
    -t  extra repository in three possible formats - <URL of .repo-file> or \"<URL> <LABEL>\" (Fedora, OpenSuSe, Mageia), full rpm sources.list line (ALTLinux) (optional)"

get_source=0
use_autoimports=0
while getopts ":hd:r:p:sat:" opt; do
  case "$opt" in
    h) echo "$usage"; exit;;
    d) distro=$OPTARG;;
    r) release=$OPTARG;;
    p) packages=$OPTARG;;
    s) get_source=1;;
    a) use_autoimports=1;;
    t) third_party_repo=$OPTARG;;
    \?) echo "Error: Unimplemented option chosen!"; echo "$usage" >&2; exit 1;;
  esac
done

# mandatory arguments
if [ ! "$distro" ] || [ ! "$release" ] || [ ! "$packages" ]; then
  echo "Error: arguments -d, -r and -p must be provided!"
  echo "$usage" >&2; exit 1
fi

# exclusions
if [ "$distro" == "alt" ] && [ $get_source == 1 ] && [ -n "$third_party_repo" ]; then
  echo "Warning: for ALTLinux getting source from third-party repository is not supported yet, you have been informed!"
fi

# commands which are dynamically generated from optional arguments
get_source_command="true"
third_party_repo_command="true"

# distros and their versions
alt_releases="p8|p9|p10|sisyphus";
fedora_releases="22|23|24|25|26|27|28|29|30|31|32|33|34|35|36|37|38|39|rawhide";
mageia_releases="7|8|cauldron";
openmandriva_releases="4.2|cooker"
opensuse_releases="15.3|15.4|15.5|leap|tumbleweed"
rosa_releases="2021.1"
rockylinux_releases="8.4|8.5|8.6|8.7|8.8|9.0|9.1|9.2"

# main code
if [ "$distro" != "alt" ] && [ "$distro" != "fedora" ] && [ "$distro" != "mageia" ] && [ "$distro" != "openmandriva" ] && [ "$distro" != "opensuse" ] && [ "$distro" != "rosa" ] && [ "$distro" != "rockylinux" ] ; then
    echo "Error: only ALTLinux, Fedora, Mageia, OpenMandriva, OpenSuSe, Rosa and Rocky Linux are supported!";
    exit 1;
else
    if [ "$distro" == "alt" ]; then
       if ! echo "$release" | grep -wEq "$alt_releases"
       then
            echo "Error: ALTLinux $release is not supported!";
            echo "Supported ALTLinux releases are ${alt_releases//|/, }.";
            exit 1;
       fi
    fi
    if [ "$distro" == "fedora" ]; then
       if ! echo "$release" | grep -wEq "$fedora_releases"
       then
            echo "Error: Fedora $release is not supported!";
            echo "Supported Fedora releases are ${fedora_releases//|/, }.";
            exit 1;
       fi
    fi
    if [ "$distro" == "mageia" ]; then
       if ! echo "$release" | grep -wEq "$mageia_releases"
       then
            echo "Error: Mageia $release is not supported!";
            echo "Supported Mageia releases are ${mageia_releases//|/, }.";
            exit 1;
       fi
    fi
    if [ "$distro" == "openmandriva" ]; then
       if ! echo "$release" | grep -wEq "$openmandriva_releases"
       then
            echo "Error: OpenMandriva $release is not supported!";
            echo "Supported OpenMandriva releases are ${openmandriva_releases//|/, }.";
            exit 1;
       fi
    fi
    if [ "$distro" == "opensuse" ]; then
       if ! echo "$release" | grep -wEq "$opensuse_releases"
       then
            echo "Error: OpenSuSe $release is not supported!";
            echo "Supported OpenSuSe releases are ${opensuse_releases//|/, }.";
            exit 1;
       fi
    fi
    if [ "$distro" == "rosa" ]; then
       if ! echo "$release" | grep -wEq "$rosa_releases"
       then
            echo "Error: Rosa $release is not supported!";
            echo "Supported Rosa releases are ${rosa_releases//|/, }.";
            exit 1;
       fi
    fi
    if [ "$distro" == "rockylinux" ]; then
       if ! echo "$release" | grep -wEq "$rockylinux_releases"
       then
            echo "Error: Rocky Linux $release is not supported!";
            echo "Supported Rocky Linux releases are ${rockylinux_releases//|/, }.";
            exit 1;
       fi
    fi
fi

# prepare storage folder
rm -rf storage
mkdir -p storage
cd storage || { echo "Error: can't cd to storage directory!"; exit 3; }

# prepare Dockerfile
if [ "$distro" == "alt" ] || [ "$distro" == "fedora" ] || [ "$distro" == "mageia" ] ; then
    echo "FROM $distro:$release" > Dockerfile
elif [ "$distro" == "openmandriva" ]; then
    echo "FROM openmandriva/$release" > Dockerfile
    echo "RUN dnf install -y awk" >> Dockerfile
elif [ "$distro" == "opensuse" ]; then
    if [ "$release" == "leap" ]; then
        echo "FROM $distro/$release:latest" > Dockerfile
        echo "RUN zypper install -y dnf rpm-repos-openSUSE-Leap" >> Dockerfile
    elif [ "$release" == "tumbleweed" ]; then
        echo "FROM $distro/$release:latest" > Dockerfile
        echo "RUN zypper install -y dnf rpm-repos-openSUSE-Tumbleweed gawk" >> Dockerfile
    else
        echo "FROM $distro/leap:$release" > Dockerfile
        echo "RUN zypper install -y dnf rpm-repos-openSUSE-Leap" >> Dockerfile
    fi
elif [ "$distro" == "rosa" ]; then
    echo "FROM rosalab/rosa$release" > Dockerfile
elif [ "$distro" == "rockylinux" ]; then
    echo "FROM rockylinux/rockylinux:$release" > Dockerfile
fi

if [ "$distro" == "alt" ]; then
cat << EOF >> Dockerfile
RUN [ -z "$http_proxy" ] && echo "Using direct network connection" || echo 'Acquire::http::Proxy "$http_proxy";' >> /etc/apt/apt.conf
EOF
    if [ "$release" == "p8" ] || [ "$release" == "p9" ] || [ "$release" == "p10" ]; then
        echo "RUN sed -i 's|^rpm \[$release\] http|#rpm \[$release\] http|g' /etc/apt/sources.list.d/*.list" >> Dockerfile
        echo "RUN sed -i 's|^#rpm \[$release\] http|rpm \[$release\] http|g' /etc/apt/sources.list.d/yandex.list" >> Dockerfile

        if [ $use_autoimports == 1 ]; then
            echo "RUN echo 'rpm http://mirror.yandex.ru/altlinux/autoimports/$release x86_64 autoimports' >> /etc/apt/sources.list.d/yandex.list" >> Dockerfile
            echo "RUN echo 'rpm http://mirror.yandex.ru/altlinux/autoimports/$release noarch autoimports' >> /etc/apt/sources.list.d/yandex.list" >> Dockerfile
        fi

        if [ $get_source == 1 ]; then
            echo "RUN echo 'rpm-src [$release] http://mirror.yandex.ru/altlinux $release/branch/x86_64 classic' >> /etc/apt/sources.list.d/yandex.list" >> Dockerfile
            echo "RUN echo 'rpm-src [$release] http://mirror.yandex.ru/altlinux $release/branch/noarch classic' >> /etc/apt/sources.list.d/yandex.list" >> Dockerfile

            if [ $use_autoimports == 1 ]; then
                echo "RUN echo 'rpm-src http://mirror.yandex.ru/altlinux/autoimports/$release x86_64 autoimports' >> /etc/apt/sources.list.d/yandex.list" >> Dockerfile
                echo "RUN echo 'rpm-src http://mirror.yandex.ru/altlinux/autoimports/$release noarch autoimports' >> /etc/apt/sources.list.d/yandex.list" >> Dockerfile
            fi
        fi
    else
        echo "RUN sed -i 's|^rpm \[alt\] http|#rpm \[alt\] http|g' /etc/apt/sources.list.d/*.list" >> Dockerfile
        echo "RUN sed -i 's|^#rpm \[alt\] http|rpm \[alt\] http|g' /etc/apt/sources.list.d/yandex.list" >> Dockerfile

        if [ $use_autoimports == 1 ]; then
            echo "RUN echo 'rpm http://mirror.yandex.ru/altlinux/autoimports/ Sisyphus/x86_64 autoimports' >> /etc/apt/sources.list.d/yandex.list" >> Dockerfile
            echo "RUN echo 'rpm http://mirror.yandex.ru/altlinux/autoimports/ Sisyphus/noarch autoimports' >> /etc/apt/sources.list.d/yandex.list" >> Dockerfile
        fi

        if [ $get_source == 1 ]; then
            echo "RUN echo 'rpm-src [alt] http://mirror.yandex.ru/altlinux/ Sisyphus/x86_64 classic' >> /etc/apt/sources.list.d/yandex.list" >> Dockerfile
            echo "RUN echo 'rpm-src [alt] http://mirror.yandex.ru/altlinux/ Sisyphus/noarch classic' >> /etc/apt/sources.list.d/yandex.list" >> Dockerfile

            if [ $use_autoimports == 1 ]; then
                echo "RUN echo 'rpm-src http://mirror.yandex.ru/altlinux/autoimports/ Sisyphus/x86_64 autoimports' >> /etc/apt/sources.list.d/yandex.list" >> Dockerfile
                echo "RUN echo 'rpm-src http://mirror.yandex.ru/altlinux/autoimports/ Sisyphus/noarch autoimports' >> /etc/apt/sources.list.d/yandex.list" >> Dockerfile
            fi
        fi
    fi

    # source code
    if [ $get_source == 1 ]; then
        get_source_command="apt-get source ${packages[*]} --print-uris | grep ^\'http:// | awk '{print \$1}' | sed \"s|'||g\" >> /var/cache/apt/archives/urls.txt && apt-get source ${packages[*]}"
    fi

    # third party repository
    if [ -n "$third_party_repo" ]; then
        third_party_repo_command="apt-get install -y apt-repo apt-https && apt-get clean && apt-repo add ${third_party_repo[*]} && apt-get update "
    fi

# prepare download script
cat << EOF > script.sh
set -x

export DEBIAN_FRONTEND=noninteractive
rm -rfv /var/cache/apt/archives/partial
mkdir -p /var/cache/apt/archives/partial
cd /var/cache/apt/archives
apt-get update && \
$third_party_repo_command || true && \
$get_source_command || true && \
apt-get install -y --reinstall --download-only ${packages[*]} --print-uris | grep ^\'http:// | awk '{print \$1}' | sed "s|'||g" >> /var/cache/apt/archives/urls.txt &&
apt-get install -y --reinstall --download-only ${packages[*]}
chown -R "$(id --user):$(id --group)" /var/cache/apt/archives
EOF

    # build container
    docker build . -t "rd-$distro-$release"

    # run script inside container
    docker run --rm -v "${PWD}":/var/cache/apt/archives -it "rd-$distro-$release" sh /var/cache/apt/archives/script.sh

fi # /distro=alt

if [ "$distro" == "fedora" ] || [ "$distro" == "mageia" ] || [ "$distro" == "openmandriva" ] || [ "$distro" == "opensuse" ] || [ "$distro" == "rosa" ] || [ "$distro" == "rockylinux" ]; then
cat << EOF >> Dockerfile
RUN [ -z "$http_proxy" ] && echo "Using direct network connection" || echo 'proxy=$http_proxy' >> /etc/dnf/dnf.conf
EOF
    if [ -n "$third_party_repo" ]; then
        third_party_repo_command="dnf install -y 'dnf-command(config-manager)' && echo 'Please press <y> to accept GPG key!' && dnf config-manager --add-repo ${third_party_repo[*]}"
    fi

    echo "RUN dnf install -y 'dnf-command(download)'" >> Dockerfile

    # source code
    if [ $get_source == 1 ]; then
        get_source_command="dnf download --source ${packages[*]} --url | grep ^http:// | awk '{print \$1}' >> /var/cache/rpm/archives/urls.txt && dnf download --source ${packages[*]}"
    fi

# prepare download script
cat << EOF > script.sh
set -x

mkdir -p /var/cache/rpm/archives
cd /var/cache/rpm/archives
$third_party_repo_command || true && \
$get_source_command || true && \
dnf download ${packages[*]} --url | grep ^http:// | awk '{print \$1}' >> /var/cache/rpm/archives/urls.txt &&
dnf download ${packages[*]}
chown -R "$(id --user):$(id --group)" /var/cache/rpm/archives
EOF

    # build container
    docker build . -t "rd-$distro-$release"

    # run script inside container
    docker run --rm -v "${PWD}":/var/cache/rpm/archives -it "rd-$distro-$release" sh /var/cache/rpm/archives/script.sh

fi # /distro=fedora,mageia,opensuse
