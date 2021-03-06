#!/bin/bash

if ! grep -i "ubuntu 1[46].04" /etc/issue > /dev/null; then
    echo "  *** This script only supports Ubuntu 14.04 / 16.04 release."
    echo "  *** Please manually modify it to make things work."
    exit 1
fi

export PATH="$HOME/.rbenv/bin:$HOME/.rbenv/shims:$HOME/.local/bin:$PATH"

run_cmd() {
    echo + $@
    $@
}

apt_get_install_packages() {
    local pkgs=(
        build-essential
        cmake
        exuberant-ctags
        git
        htop
        libreadline-dev
        libssl-dev
        ncdu
        openssh-server
        python-dev
        ruby
        silversearcher-ag
        tig
        tmux
        vim
    )

    local pkgs_to_install=""

    for pkg in "${pkgs[@]}"
    do
        if ! dpkg -s $pkg > /dev/null 2>&1; then
            pkgs_to_install="$pkgs_to_install $pkg"
        fi
    done

    if [ ! -z "$pkgs_to_install" ]; then
        run_cmd sudo apt-get -y install $pkgs_to_install
    fi
}

get_rbenv() {
    pushd ~ > /dev/null
    if [ -d ~/.rbenv ]; then
        cd ~/.rbenv
        git pull
    else
        git clone https://github.com/sstephenson/rbenv.git ~/.rbenv
    fi
    if [ -d ~/.rbenv/plugins/ruby-build ]; then
        cd ~/.rbenv/plugins/ruby-build
        git pull
    else
        git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
    fi
    if ! grep "rbenv init" ~/.bashrc > /dev/null 2>&1; then
        echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
        echo 'eval "$(rbenv init -)"' >> ~/.bashrc
    fi
    popd > /dev/null
}

get_ruby() {
    local ruby_ver="2.3.1"
    yes n | rbenv install $ruby_ver -v
    rbenv global $ruby_ver
    rbenv rehash
}

# get_linuxbrew() {
#     if ! which brew > /dev/null 2>&1; then
#         yes | ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/linuxbrew/go/install)"
#     fi
#     if ! grep "linuxbrew/bin" ~/.bashrc > /dev/null 2>&1; then
#         echo 'export PATH=$HOME/.linuxbrew/bin:$PATH' >> ~/.bashrc
#     fi
#     # bootstrap gcc: https://github.com/Homebrew/linuxbrew/issues/137
#     if [ -f /usr/bin/gcc ]; then
#         ln -s /usr/bin/gcc ~/.linuxbrew/bin/gcc-4.4
#     fi
#     if [ -f /usr/bin/g++ ]; then
#         ln -s /usr/bin/g++ ~/.linuxbrew/bin/g++-4.4
#     fi
#     if [ -f /usr/bin/gfortran ]; then
#         ln -s /usr/bin/gfortran ~/.linuxbrew/bin/gfortran-4.4
#     fi
# }

get_pip() {
    mkdir -p ~/.local
    cd ~/.local
    if ! grep "export PATH=.*HOME/.local/bin" ~/.bashrc > /dev/null 2>&1; then
        echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.bashrc
    fi
    wget http://bootstrap.pypa.io/get-pip.py -O get-pip.py
    python get-pip.py --user
    pip install -U setuptools
}

private_set_ssh_authorized_keys() {
    mkdir -p ~/.ssh
    cd ~/.ssh
    if [ -f authorized_keys ]; then
        cp authorized_keys authorized_keys~
        cp authorized_keys authorized_keys~~
    fi
    curl http://www.yzhang.net/aws/authorized_keys >> authorized_keys~~
    if [ -f id_ras.pub ]; then
        cat id_ras.pub >> authorized_keys~~
    fi
    sort authorized_keys~~ | uniq > authorized_keys
    rm -f authorized_keys~~
}

private_get_toolkit() {
    if [ -d ~/.toolkit ]; then
        cd ~/.toolkit
        git pull
    else
        git clone https://github.com/santazhang/toolkit.git ~/.toolkit
        cd ~/.toolkit
    fi
    ./housekeeper.py dotfiles-link
    gem install teamocil
}

apt_get_install_packages

get_rbenv
get_ruby
# get_linuxbrew
get_pip

gem install bundler pry

# brew install ag ncdu

pip install -U --user ipython numpy PyYaml requests

if [ "$PRIVATE" == "1" ]; then
    private_set_ssh_authorized_keys
    private_get_toolkit
fi
