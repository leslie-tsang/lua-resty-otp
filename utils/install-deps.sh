#!/usr/bin/env bash

################################################################
# github action use `runner` as default exec user
################################################################

set -ex


# Install dependencies on centos and fedora
function install_dependencies_with_yum() {
    # add OpenResty repo
    sudo yum install yum-utils
    sudo yum-config-manager --add-repo "https://openresty.org/package/${1}/openresty.repo"

    # install OpenResty and some compilation tools
    sudo yum install -y make curl git gcc unzip
    sudo yum install -y pcre pcre-devel openresty openresty-openssl111-devel openldap-devel
    sudo yum install -y perl cpanminus
}


# Install dependencies on ubuntu and debian
function install_dependencies_with_apt() {
    # add OpenResty source
    sudo apt-get update
    sudo apt-get -y install software-properties-common wget lsb-release
    wget -qO - https://openresty.org/package/pubkey.gpg | sudo apt-key add -
    if [[ "${1}" == "ubuntu" ]]; then
        sudo add-apt-repository -y "deb http://openresty.org/package/ubuntu $(lsb_release -sc) main"
    elif [[ "${1}" == "debian" ]]; then
        sudo add-apt-repository -y "deb http://openresty.org/package/debian $(lsb_release -sc) openresty"
    fi
    sudo apt-get update

    # install OpenResty and some compilation tools
    sudo apt-get install -y make curl git gcc build-essential
    sudo apt-get install -y openresty openresty-openssl111-dev libncurses5-dev libreadline-dev libssl-dev libpcre3 libpcre3-dev libldap2-dev
    sudo apt-get install -y perl cpanminus
}


function install_unit_test_deps() {
    sudo cpanm --notest Test::Nginx IPC::Run
}


# Identify the different distributions and call the corresponding function
function multi_distro_installation() {
    if grep -Eqi "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release; then
        install_dependencies_with_yum "centos"
    elif grep -Eqi "Fedora" /etc/issue || grep -Eq "Fedora" /etc/*-release; then
        install_dependencies_with_yum "fedora"
    elif grep -Eqi "Debian" /etc/issue || grep -Eq "Debian" /etc/*-release; then
        install_dependencies_with_apt "debian"
    elif grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
        install_dependencies_with_apt "ubuntu"
    else
        echo "Non-supported operating system version"
    fi
}

multi_distro_installation "centos"
install_unit_test_deps
