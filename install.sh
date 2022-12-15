#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}Mistake: ${plain} The ROOT User Must Be Used To Run This Script!\n" && exit 1

# check os
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
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
    echo -e "${red}System Version Not Detected, Please Contact The Script Author! ${plain}\n" && exit 1
fi

arch=$(arch)

if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
    arch="amd64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
    arch="arm64"
elif [[ $arch == "s390x" ]]; then
    arch="s390x"
else
    arch="amd64"
    echo -e "${red}Failed To Detect Schema, Use Default Schema: ${arch}${plain}"
fi

echo "Architecture: ${arch}"

if [ $(getconf WORD_BIT) != '32' ] && [ $(getconf LONG_BIT) != '64' ]; then
    echo "This Software Does Not Support 32 bit System(x86), Please Use 64 bit System(x86_64), If The Detection Is Incorrect, Please Contact The Author"
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
        echo -e "${red}Please Use CentOS 7 or Higher Version Of The System! ${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}Please Use Ubuntu 16 Higher Version Of The System! ${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}Please Use Debian 8 Higher Version Of The System! ${plain}\n" && exit 1
    fi
fi

install_base() {
    if [[ x"${release}" == x"centos" ]]; then
        yum install wget curl tar -y
    else
        apt install wget curl tar -y
    fi
}

#This function will be called when user installed x-ui out of sercurity
config_after_install() {
    echo -e "${yellow}For Safety Reasons, Install / After The Update Is Complete, The Port And Account Password Must Be Changed Forcibly ${plain}"
    read -p "Confirm Whether To Continue?[y/n]": config_confirm
    if [[ x"${config_confirm}" == x"y" || x"${config_confirm}" == x"Y" ]]; then
        read -p "Please Set Your Account Name:" config_account
        echo -e "${yellow}Your Account Name Will Be Set To:${config_account}${plain}"
        read -p "Please Set Your Account Password:" config_password
        echo -e "${yellow}Your Account Password Will Be Set To:${config_password}${plain}"
        read -p "Please Set The Panel Access Port:" config_port
        echo -e "${yellow}Your Panel Access Port Will Be Set To:${config_port}${plain}"
        echo -e "${yellow}Confirm Settings , Setting${plain}"
        /usr/local/x-ui/x-ui setting -username ${config_account} -password ${config_password}
        echo -e "${yellow}The Account Password Is Set${plain}"
        /usr/local/x-ui/x-ui setting -port ${config_port}
        echo -e "${yellow}Panel Port Setting Completed${plain}"
    else
        echo -e "${red}Cancelled, All Settings Are Default Settings, Please Revise In Time${plain}"
    fi
}

install_x-ui() {
    systemctl stop x-ui
    cd /usr/local/

    if [ $# == 0 ]; then
        last_version=$(curl -Ls "https://api.github.com/repos/vaxilu/x-ui/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        if [[ ! -n "$last_version" ]]; then
            echo -e "${red}Detection x-ui Version Failed, Probably Out of Github API Limit, Please Try Again Later, Or Specify Manually x-ui Version Installation${plain}"
            exit 1
        fi
        echo -e "Detected x-ui The Latest Version Of: ${last_version}, Start Installation"
        wget -N --no-check-certificate -O /usr/local/x-ui-linux-${arch}.tar.gz https://github.com/vaxilu/x-ui/releases/download/${last_version}/x-ui-linux-${arch}.tar.gz
        if [[ $? -ne 0 ]]; then
            echo -e "${red}Download x-ui Failed, Please Make Sure Your Server Is Able To Download Github Document${plain}"
            exit 1
        fi
    else
        last_version=$1
        url="https://github.com/vaxilu/x-ui/releases/download/${last_version}/x-ui-linux-${arch}.tar.gz"
        echo -e "Start Installation x-ui v$1"
        wget -N --no-check-certificate -O /usr/local/x-ui-linux-${arch}.tar.gz ${url}
        if [[ $? -ne 0 ]]; then
            echo -e "${red}Download x-ui v$1 Failed, Make Sure This Version Exists${plain}"
            exit 1
        fi
    fi

    if [[ -e /usr/local/x-ui/ ]]; then
        rm /usr/local/x-ui/ -rf
    fi

    tar zxvf x-ui-linux-${arch}.tar.gz
    rm x-ui-linux-${arch}.tar.gz -f
    cd x-ui
    chmod +x x-ui bin/xray-linux-${arch}
    cp -f x-ui.service /etc/systemd/system/
    wget --no-check-certificate -O /usr/bin/x-ui https://raw.githubusercontent.com/vaxilu/x-ui/main/x-ui.sh
    chmod +x /usr/local/x-ui/x-ui.sh
    chmod +x /usr/bin/x-ui
    config_after_install
    #echo -e "If it is a fresh installation, the default web port is ${green}54321${plain}, the default username and password are ${green}admin${plain}"
    #echo -e "Please make sure that this port is not occupied by other programs, ${yellow}and make sure 54321 Port has been released${plain}"
    #    echo -e "If you want to 54321 Change it to another port, enter x-ui Command to modify, also make sure that the port you modify is also released"
    #echo -e ""
    #echo -e "If updating the panel, access the panel as you did before"
    #echo -e ""
    systemctl daemon-reload
    systemctl enable x-ui
    systemctl start x-ui
    echo -e "${green}x-ui v${last_version}${plain} The Installation Is Complete, The Panel Is Activated, "
    echo -e ""
    echo -e "x-ui How To Use The Management Script: "
    echo -e "----------------------------------------------"
    echo -e "x-ui              - Show Admin Menu (More Functions)"
    echo -e "x-ui start        - Start Up x-ui Panel"
    echo -e "x-ui stop         - Stop x-ui Panel"
    echo -e "x-ui restart      - Reboot x-ui Panel"
    echo -e "x-ui status       - Check x-ui State"
    echo -e "x-ui enable       - Set Up x-ui Boot Up"
    echo -e "x-ui disable      - Cancel x-ui Boot Up"
    echo -e "x-ui log          - Check x-ui Log"
    echo -e "x-ui v2-ui        - Migrate This Machine's v2-ui Account Data To x-ui"
    echo -e "x-ui update       - Update x-ui Panel"
    echo -e "x-ui install      - Install x-ui Panel"
    echo -e "x-ui uninstall    - Uninstall x-ui Panel"
    echo -e "----------------------------------------------"
}

echo -e "${green}Start Installation${plain}"
install_base
install_x-ui $1
