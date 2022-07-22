#!/bin/bash
usage="$(basename "$0") [-h] [-d DISTRO] [-r RELEASE] [-p \"PACKAGE1 PACKAGE2 ..\"] [-s]
Download rpm-package(s) for given distribution release,
where:
    -h  show this help text
    -d  distro name (alt, fedora, mageia)
    -r  release name (p8/p9/p10/sisyphus, 22 to rawhide, 7 to cauldron)
    -p  packages
    -s  also download source-code package(s) (optional)
    -a  enable Autoimports repository (optional for ALTLinux)"

get_source=0
use_autoimports=0
while getopts ":hd:r:p:sa" opt; do
  case "$opt" in
    h) echo "$usage"; exit;;
    d) distro=$OPTARG;;
    r) release=$OPTARG;;
    p) packages=$OPTARG;;
    s) get_source=1;;
    a) use_autoimports=1;;
    \?) echo "Error: Unimplemented option chosen!"; echo "$usage" >&2; exit 1;;
  esac
done

# mandatory arguments
if [ ! "$distro" ] || [ ! "$release" ] || [ ! "$packages" ]; then
  echo "Error: arguments -d, -r and -p must be provided!"
  echo "$usage" >&2; exit 1
fi

# commands which are dynamically generated from optional arguments
get_source_command="true"

# distros and their versions
alt_releases="p8|p9|p10|sisyphus";
fedora_releases="22|23|24|25|26|27|28|29|30|31|32|33|34|35|36|rawhide";
mageia_releases="7|8|cauldron";

# main code
if [ "$distro" != "alt" ] && [ "$distro" != "fedora" ] && [ "$distro" != "mageia" ]  ; then
    echo "Error: only ALTLinux and Fedora are supported!";
    exit 1;
else
    if [ "$distro" == "alt" ]; then
       if ! echo "$release" | grep -wEq "$alt_releases"
       then
            echo "Error: ALTLinux $release is not supported!";
            exit 1;
       fi
    fi
    if [ "$distro" == "fedora" ]; then
       if ! echo "$release" | grep -wEq "$fedora_releases"
       then
            echo "Error: Fedora $release is not supported!";
            exit 1;
       fi
    fi
    if [ "$distro" == "mageia" ]; then
       if ! echo "$release" | grep -wEq "$mageia_releases"
       then
            echo "Error: Mageia $release is not supported!";
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

# prepare download script
cat << EOF > script.sh
set -x

export DEBIAN_FRONTEND=noninteractive
rm -rfv /var/cache/apt/archives/partial
mkdir -p /var/cache/apt/archives/partial
cd /var/cache/apt/archives
apt-get update && \
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

if [ "$distro" == "fedora" ] || [ "$distro" == "mageia" ]; then
cat << EOF >> Dockerfile
RUN [ -z "$http_proxy" ] && echo "Using direct network connection" || echo 'proxy=$http_proxy' >> /etc/dnf/dnf.conf
EOF

    echo "RUN dnf install -y 'dnf-command(download)'" >> Dockerfile

    # source code
    if [ $get_source == 1 ]; then
        get_source_command="dnf download --source ${packages[*]} --url | grep ^http:// | awk '{print \$1}' >> /var/cache/rpm/archives/urls.txt && dnf download --source ${packages[*]}"
    fi

# prepare download script
cat << EOF > script.sh
set -x

cd /var/cache/rpm/archives
$get_source_command || true && \
dnf download ${packages[*]} --url | grep ^http:// | awk '{print \$1}' >> /var/cache/rpm/archives/urls.txt &&
dnf download ${packages[*]}
chown -R "$(id --user):$(id --group)" /var/cache/rpm/archives
EOF

    # build container
    docker build . -t "rd-$distro-$release"

    # run script inside container
    docker run --rm -v "${PWD}":/var/cache/rpm/archives -it "rd-$distro-$release" sh /var/cache/rpm/archives/script.sh

fi # /distro=fedora,mageia
