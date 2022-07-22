#!/bin/bash
usage="$(basename "$0") [-h] [-d DISTRO] [-r RELEASE] [-p \"PACKAGE1 PACKAGE2 ..\"] [-s]
Download rpm-package(s) for given distribution release,
where:
    -h  show this help text
    -d  distro name (alt)
    -r  release name (p8/p9/p10/sisyphus)
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
supported_alt_releases="p8|p9|p10|sisyphus";

# main code
if [ "$distro" != "alt" ]; then
    echo "Error: only ALTLinux is supported!";
    exit 1;
else
    if [ "$distro" == "alt" ]; then
       if ! echo "$release" | grep -wEq "$supported_alt_releases"
       then
            echo "Error: ALTLinux $release is not supported!";
            exit 1;
       fi
    fi
fi

# prepare storage folder
rm -rf storage
mkdir -p storage
cd storage || { echo "Error: can't cd to storage directory!"; exit 3; }

# prepare Dockerfile
if [ "$distro" == "alt" ]; then
    echo "FROM $distro:$release" > Dockerfile
fi

cat << EOF >> Dockerfile
RUN [ -z "$http_proxy" ] && echo "Using direct network connection" || echo 'Acquire::http::Proxy "$http_proxy";' >> /etc/apt/apt.conf
EOF

if [ "$distro" == "alt" ]; then
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
