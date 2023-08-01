#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}Error: ${plain} must be root to run this script! \n" && exit 1

# check os
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "armbian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
else
    echo -e "System version not detected by ${red}, please contact the script author! ${plain}\n" && exit 1
fi

arch=$(arch)

if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
    arch="amd64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
    arch="arm64"
elif [[ $arch == "s390x" ]]; then
    arch="s390x"
elif [[ $arch == "riscv64" ]]; then
    arch="riscv64"
else
    arch="x86_64"
    echo -e "${red}Failed to detect schema, use default schema: ${arch}${plain}"
fi

echo "Your CPU arch: ${arch}"

if [ $(getconf WORD_BIT) != '32' ] && [ $(getconf LONG_BIT) != '64' ]; then
    echo "This software does not support 32-bit system (x86), please use 64-bit system (x86_64), if the detection is wrong, please contact the author"
    exit -1
fi

os_version=""

# os version
if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

if [[ x"${release}" == x"centos" ]]; then
    if [[ ${os_version} -le 6 ]]; then
        echo -e "${red}Please use CentOS 7 or higher! ${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}Please use Ubuntu 16 or later! ${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}Please use Debian 8 or higher!${plain}\n" && exit 1
    fi
fi

if [ "$release" = "debian" ]; then
    echo "This is Debian."
elif [ "$release" = "ubuntu" ]; then
    echo "This is Ubuntu."
else
    echo "${red}You Device Using $release. It's not support, using Debian or Ubuntu or Armbian.${plain}"
    exit 1
fi

if [ "$arch" = "arm64" ]; then
    echo "CPU: arm64"
elif [ "$arch" = "amd64" ]; then
    echo "CPU: amd64"
else
    echo "Is not support $arch cpu type"
    exit 1
fi

sudo apt-get update -yq

sudo apt-get install \
    ca-certificates \
    curl \
    wget \
    gnupg \
    lsb-release -yq

curl -fsSL https://download.docker.com/linux/${release}/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/${release} \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -yq
sudo apt-get install docker-ce docker-ce-cli containerd.io -yq
sudo systemctl enable docker.service

git clone -b master \
          --single-branch \
          https://github.com/dopaemon/TPBox.git \
          TPBox

cp -r ./TPBox/logfs /sbin/
cp -r ./TPBox/myearn.service /etc/systemd/system/
sudo systemctl enable myearn.service
sudo systemctl start myearn.service

wget -O /usr/bin/TPBox https://github.com/dopaemon/TPBox/raw/Binary/TPBox-${arch}
sudo chmod +x /usr/bin/TPBox
