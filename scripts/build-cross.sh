#!/bin/bash
## Usage: build-cross
##
##
## Downloads and builds the cross compiler
##   -h, --help    Display this message.
##   -n            Dry-run; only show what would be done.
##


usage () {

  ["$*"] && echo "$0: $*"
  sed -n '/^##/,/^$/s/^## \{0,1\}//p' "$0"
  exit 2
} 

function package_check() {
    # Tell apt-get we're never going to be able to give manual feedback:
    export DEBIAN_FRONTEND=noninteractive
    sudo apt-get update

    PKG_LIST='curl build-essential bison flex libgmp3-dev libmpc-dev libmpfr-dev texinfo'
    #if input is a file, convert it to a string like:
    #PKG_LIST=$(cat ./packages.txt)
    #PKG_LIST=$1
    for package in $PKG_LIST; do 
        CHECK_PACKAGE=$(sudo dpkg -l \
        | grep --max-count 1 "$package" \
        | awk '{print$ 2}')
            
        if [[ ! -z "$CHECK_PACKAGE" ]]; then 
            echo "$package" 'IS installed'; 
            pkg_installed="yes"
        else 
            echo "$package" 'IS NOT installed, installing';
            sudo apt-get --yes install --no-install-recommends "$package"

            pkg_installed="no"
            package_install "$package"
        fi
    done
    # Delete cached files we don't need anymore
    sudo apt-get clean
}

stuff() {
  cd $HOME/src
  # Download Binutils and GCC
  curl -O https://ftp.gnu.org/gnu/binutils/binutils-2.41.tar.xz
  curl -O https://ftp.gnu.org/gnu/gcc/gcc-13.2.0/gcc-13.2.0.tar.xz

  mkdir build-gcc build-binutils
  tar xf binutils*
  tar xf gcc*

  #Start building the Binutils
  cd build-binutils
  ../binutils-2.41/configure --target=$TARGET --prefix="$PREFIX" --with-sysroot --disable-nls --disable-werror
  make
  make install

  #Build Cross Compiler
  cd ../build-gcc
  ../gcc-13.2.0/configure --target=$TARGET --prefix="$PREFIX" --disable-nls --enable-languages=c,c++ --without-headers
  make all-gcc
  make all-target-libgcc
  make install-gcc
  make install-target-libgcc

  echo "Cross Compiler Build Complete!"
}

do_prequisites() {

  export PREFIX="$HOME/opt/cross"
  export TARGET=i686-elf
  export PATH="$PREFIX/bin:$PATH"

  mkdir -p $PREFIX
  mkdir -p $HOME/src
}

main() {
  package_check
  do_prequisites
  stuff
}

while getopts "h" a; do
  case "${a}" in
    h)
      usage
      ;;
  esac
done
