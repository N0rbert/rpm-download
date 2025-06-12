#!/bin/bash
usage="$(basename "$0") [-h] [-d DISTRO] [-r RELEASE] [-p \"PACKAGE1 PACKAGE2 ..\"] [-s] [-a] [-t]
Download rpm-package(s) for given distribution release,
where:
    -h  show this help text
    -d  distro name (alt, fedora, mageia, openmandriva, opensuse, rosa, rockylinux, almalinux, oraclelinux, redos, msvsphere, centos)
    -r  release name (p8/p9/p10/sisyphus, 22 to rawhide, 7 to cauldron, 4.2 and cooker, leap and tumbleweed, only 2021.1, from 8.4, from 8.4, only latest, from 8.0, from stream9)
    -p  packages
    -s  also download source-code package(s) (optional)
    -a  enable Autoimports repository (optional for ALTLinux)
    -u  enable Autoports repository (optional for ALTLinux)
    -t  extra repository in three possible formats - <URL of .repo-file> or \"<URL> <LABEL>\" (Fedora, OpenSuSe, Mageia, Rocky Linux, AlmaLinux, Oracle Linux, RedOS), full rpm sources.list line (ALTLinux) (optional)"

get_source=0
use_autoimports=0
use_autoports=0
while getopts ":hd:r:p:saut:" opt; do
  case "$opt" in
    h) echo "$usage"; exit;;
    d) distro=$OPTARG;;
    r) release=$OPTARG;;
    p) packages=$OPTARG;;
    s) get_source=1;;
    a) use_autoimports=1;;
    u) use_autoports=1;;
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

if [ "$distro" == "redos" ] && [ $get_source == 1 ]; then
  echo "Warning: for RedOS getting source from repository is not possible, you have been informed!"
fi

# commands which are dynamically generated from optional arguments
get_source_command="true"
third_party_repo_command="true"

# distros and their versions
alt_releases="p8|p9|p10|p11|sisyphus";
fedora_releases="22|23|24|25|26|27|28|29|30|31|32|33|34|35|36|37|38|39|40|41|42|rawhide";
mageia_releases="7|8|9|cauldron";
openmandriva_releases="4.2|cooker|rome"
opensuse_releases="15.3|15.4|15.5|15.6|leap|tumbleweed"
rosa_releases="2021.1|2023.1|13"

rockylinux_releases="8.4|8.5|8.6|8.7|8.8|8.9|8.10|9.0|9.1|9.2|9.3|9.4|9.5|9.6|^10$"
almalinux_releases="8.4|8.5|8.6|8.7|8.8|8.9|8.10|9.0|9.1|9.2|9.3|9.4|9.5|9.6|^10$"
oraclelinux_releases="^8$|8.0|8.1|8.2|8.3|8.4|8.5|8.6|8.7|8.8|8.9|8.10|^9$"
centos_releases="stream9|stream10"

redos_releases="latest"
msvsphere_releases="8|8.9|9|9.1|9.2|9.3|latest"

# main code
if [ "$distro" != "alt" ] && [ "$distro" != "fedora" ] && [ "$distro" != "mageia" ] && [ "$distro" != "openmandriva" ] && [ "$distro" != "opensuse" ] && [ "$distro" != "rosa" ] && [ "$distro" != "rockylinux" ] && [ "$distro" != "almalinux" ] && [ "$distro" != "oraclelinux" ] && [ "$distro" != "redos" ] && [ "$distro" != "msvsphere" ] && [ "$distro" != "centos" ] ; then
    echo "Error: only ALTLinux, Fedora, Mageia, OpenMandriva, OpenSuSe, Rosa, Rocky Linux, AlmaLinux, Oracle Linux, RedOS, MSVSphere and CentOS are supported!";
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
    if [ "$distro" == "almalinux" ]; then
       if ! echo "$release" | grep -wEq "$almalinux_releases"
       then
            echo "Error: AlmaLinux $release is not supported!";
            echo "Supported AlmaLinux releases are ${almalinux_releases//|/, }.";
            exit 1;
       fi
    fi
    if [ "$distro" == "oraclelinux" ]; then
       if ! echo "$release" | grep -wEq "$oraclelinux_releases"
       then
            echo "Error: Oracle Linux $release is not supported!";
            echo "Supported Oracle Linux releases are ${oraclelinux_releases//|/, }." | sed 's|[\^\$]||g';
            exit 1;
       fi
    fi
    if [ "$distro" == "redos" ]; then
       if ! echo "$release" | grep -wEq "$redos_releases"
       then
            echo "Error: RedOS $release is not supported!";
            echo "Supported RedOS releases are ${redos_releases//|/, }.";
            exit 1;
       fi
    fi
    if [ "$distro" == "msvsphere" ]; then
       if ! echo "$release" | grep -wEq "$msvsphere_releases"
       then
            echo "Error: MSVSphere $release is not supported!";
            echo "Supported MSVSphere releases are ${msvsphere_releases//|/, }.";
            exit 1;
       fi
    fi
    if [ "$distro" == "centos" ]; then
       if ! echo "$release" | grep -wEq "$centos_releases"
       then
            echo "Error: CentOS $release is not supported!";
            echo "Supported CentOS releases are ${centos_releases//|/, }.";
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
    if [ "$release" == "rome" ]; then
        echo "FROM openmandriva/cooker" > Dockerfile
        echo "RUN dnf install -y 'dnf-command(config-manager)'" >> Dockerfile
        echo "RUN dnf config-manager --disable openmandriva-x86_64" >> Dockerfile
        echo "RUN dnf config-manager --disable cooker-x86_64" >> Dockerfile
        echo "RUN dnf config-manager --enable rolling-x86_64" >> Dockerfile
        echo "RUN dnf config-manager --enable rolling-x86_64-non-free" >> Dockerfile
        echo "RUN dnf config-manager --enable rolling-x86_64-restricted" >> Dockerfile
        echo "RUN dnf config-manager --enable rolling-x86_64-unsupported" >> Dockerfile
    elif [ "$release" == "cooker" ]; then
        echo "FROM openmandriva/cooker" > Dockerfile
        echo "RUN dnf install -y 'dnf-command(config-manager)'" >> Dockerfile
        echo "RUN dnf config-manager --enable cooker-x86_64-non-free" >> Dockerfile
        echo "RUN dnf config-manager --enable cooker-x86_64-restricted" >> Dockerfile
        echo "RUN dnf config-manager --enable cooker-x86_64-unsupported" >> Dockerfile
    else
        echo "FROM openmandriva/$release" > Dockerfile
    fi
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
elif [ "$distro" == "almalinux" ]; then
    echo "FROM almalinux:$release" > Dockerfile
elif [ "$distro" == "oraclelinux" ]; then
    echo "FROM oraclelinux:$release" > Dockerfile
elif [ "$distro" == "redos" ]; then
    echo "FROM registry.red-soft.ru/ubi7/ubi:$release" > Dockerfile
elif [ "$distro" == "msvsphere" ]; then
    echo "FROM inferit/$distro:$release" > Dockerfile
elif [ "$distro" == "centos" ]; then
    echo "FROM quay.io/$distro/$distro:$release" > Dockerfile
fi

if [ "$distro" == "alt" ]; then
cat << EOF >> Dockerfile
RUN [ -z "$http_proxy" ] && echo "Using direct network connection" || echo 'Acquire::http::Proxy "$http_proxy";' >> /etc/apt/apt.conf
EOF
    if [ "$release" == "p8" ] || [ "$release" == "p9" ] || [ "$release" == "p10" ] || [ "$release" == "p11" ]; then
        echo "RUN sed -i 's|^rpm \[$release\] http|#rpm \[$release\] http|g' /etc/apt/sources.list.d/*.list" >> Dockerfile
        echo "RUN sed -i 's|^#rpm \[$release\] http|rpm \[$release\] http|g' /etc/apt/sources.list.d/yandex.list" >> Dockerfile

        if [ $use_autoimports == 1 ]; then
            echo "RUN echo 'rpm http://mirror.yandex.ru/altlinux/autoimports/$release x86_64 autoimports' >> /etc/apt/sources.list.d/yandex.list" >> Dockerfile
            echo "RUN echo 'rpm http://mirror.yandex.ru/altlinux/autoimports/$release noarch autoimports' >> /etc/apt/sources.list.d/yandex.list" >> Dockerfile
        fi

        if [ $use_autoports == 1 ]; then
            echo "RUN echo 'rpm http://autoports.altlinux.org/pub/ALTLinux/autoports/$release/  x86_64 autoports' >> /etc/apt/sources.list" >> Dockerfile
            echo "RUN echo 'rpm http://autoports.altlinux.org/pub/ALTLinux/autoports/$release/  noarch autoports' >> /etc/apt/sources.list" >> Dockerfile
        fi

        if [ $get_source == 1 ]; then
            echo "RUN echo 'rpm-src [$release] http://mirror.yandex.ru/altlinux $release/branch/x86_64 classic' >> /etc/apt/sources.list.d/yandex.list" >> Dockerfile
            echo "RUN echo 'rpm-src [$release] http://mirror.yandex.ru/altlinux $release/branch/noarch classic' >> /etc/apt/sources.list.d/yandex.list" >> Dockerfile

            if [ $use_autoimports == 1 ]; then
                echo "RUN echo 'rpm-src http://mirror.yandex.ru/altlinux/autoimports/$release x86_64 autoimports' >> /etc/apt/sources.list.d/yandex.list" >> Dockerfile
                echo "RUN echo 'rpm-src http://mirror.yandex.ru/altlinux/autoimports/$release noarch autoimports' >> /etc/apt/sources.list.d/yandex.list" >> Dockerfile
            fi

            if [ $use_autoports == 1 ]; then
                echo "RUN echo 'rpm-src http://autoports.altlinux.org/pub/ALTLinux/autoports/$release/  noarch autoports' >> /etc/apt/sources.list" >> Dockerfile
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

if [ "$distro" == "fedora" ] || [ "$distro" == "mageia" ] || [ "$distro" == "openmandriva" ] || [ "$distro" == "opensuse" ] || [ "$distro" == "rosa" ] || [ "$distro" == "rockylinux" ] || [ "$distro" == "almalinux" ] || [ "$distro" == "oraclelinux" ] || [ "$distro" == "redos" ] || [ "$distro" == "msvsphere" ] || [ "$distro" == "centos" ]; then
cat << EOF >> Dockerfile
RUN [ -z "$http_proxy" ] && echo "Using direct network connection" || echo 'proxy=$http_proxy' >> /etc/dnf/dnf.conf
EOF
    if [ -n "$third_party_repo" ]; then
      if [ "$distro" == "centos" ]; then
        if [ "$third_party_repo" == "epel" ]; then
          crb_command="dnf install -y 'dnf-command(config-manager)' && dnf config-manager --set-enabled crb"
          if [ "$release" == "stream9" ]; then
            third_party_repo_command="$crb_command && dnf install -y https://dl.fedoraproject.org/pub/epel/epel{,-next}-release-latest-9.noarch.rpm"
          elif [ "$release" == "stream10" ]; then
            third_party_repo_command="$crb_command && dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-10.noarch.rpm"
          fi
        else
          echo "Warning: on CentOS currently only EPEL third-party repository is supported!"
        fi
      else
        third_party_repo_command="dnf install -y 'dnf-command(config-manager)' && echo 'Please press <y> to accept GPG key!' && dnf config-manager --add-repo ${third_party_repo[*]}"
      fi
    fi

    echo "RUN dnf install -y 'dnf-command(download)' awk || dnf install -y 'dnf-command(download)' gawk" >> Dockerfile

    # source code
    if [ $get_source == 1 ]; then
        get_source_command="dnf download --source ${packages[*]} --url | grep -E '^http://|^rsync://' | awk '{print \$1}' >> /var/cache/rpm/archives/urls.txt && dnf download --source ${packages[*]}"
    fi

# prepare download script
cat << EOF > script.sh
set -x

mkdir -p /var/cache/rpm/archives
cd /var/cache/rpm/archives
$third_party_repo_command || true && \
$get_source_command || true && \
dnf download ${packages[*]} --url | grep -E '^http://|^rsync://' | awk '{print \$1}' >> /var/cache/rpm/archives/urls.txt &&
dnf download ${packages[*]}
chown -R "$(id --user):$(id --group)" /var/cache/rpm/archives
EOF

    # build container
    docker build . -t "rd-$distro-$release"

    # run script inside container
    docker run --rm -v "${PWD}":/var/cache/rpm/archives -it "rd-$distro-$release" sh /var/cache/rpm/archives/script.sh

fi # /distro=fedora,mageia,opensuse,rosa,rockylinux,almalinux,oraclelinux,redos,msvsphere
