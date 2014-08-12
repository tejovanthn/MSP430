#!/bin/bash

#Download the files
#http://sourceforge.net/apps/mediawiki/mspgcc/index.php?title=Install:fromsource
echo "Downloading the required files for installing mspgcc from source"
mkdir ~/mspgcc
cd ~/mspgcc

wget -nc -nv http://sourceforge.net/projects/mspgcc/files/mspgcc/mspgcc-20120406.tar.bz2
wget -nc -nv http://sourceforge.net/projects/mspgcc/files/msp430mcu/msp430mcu-20120406.tar.bz2
wget -nc -nv http://sourceforge.net/projects/mspgcc/files/msp430-libc/msp430-libc-20120224.tar.bz2
wget -nc -nv http://ftpmirror.gnu.org/binutils/binutils-2.21.1a.tar.bz2
wget -nc -nv http://ftpmirror.gnu.org/gcc/gcc-4.6.3/gcc-core-4.6.3.tar.bz2
wget -nc -nv http://ftpmirror.gnu.org/gdb/gdb-7.2a.tar.bz2
wget -nc -nv http://sourceforge.net/projects/mspdebug/files/mspdebug-0.19.tar.gz

#Download  patches
wget -nc -nv http://sourceforge.net/projects/mspgcc/files/Patches/LTS/20120406/msp430-gcc-4.6.3-20120406-sf3540953.patch
wget -nc -nv http://sourceforge.net/projects/mspgcc/files/Patches/LTS/20120406/msp430-gcc-4.6.3-20120406-sf3559978.patch
wget -nc -nv http://sourceforge.net/projects/mspgcc/files/Patches/LTS/20120406/msp430-libc-20120224-sf3522752.patch
wget -nc -nv http://sourceforge.net/projects/mspgcc/files/Patches/LTS/20120406/msp430mcu-20120406-sf3522088.patch

if [ ! -d "msp430-build" ]; then
    echo "Creating a build area"
    ##Create a temporary build directory
    mkdir msp430-build

    #copy all the downloaded files into here
    cd msp430-build
    cp ../*.tar.* .

    # extract all the following files into the msp430-build directory
    tar xvfj binutils-*
    tar xvfj gcc-core-*
    tar xvfj gdb-*
    tar xvfj mspgcc-*
    tar xvfj msp430mcu-*
    tar xvfj msp430-libc-*
    tar xvfz mspdebug-*

    # Make sure any additional patch files (from LTS) are located here as well
    cp ../*.patch .

else
    echo "Build area available"
    cd msp430-build
fi

echo "Getting gcc dependencies"
cd gcc-4.6.3
./contrib/download_prerequisites
cd ..

# patch binutils (using the files provided in the Release Files, and repeat for any additional patches or LTS files)
echo "Patching binutils"
cd binutils-2.21.1
# Patch binutils to bring it to Release 20120406 (still at 20120406)
patch -p1<../mspgcc-20120406/msp430-binutils-2.21.1a-20120406.patch
cd ..

# patch GCC to bring it up to Release 20120406
echo "Patching gcc"
cd gcc-4.6.3
patch -p1<../mspgcc-20120406/msp430-gcc-4.6.3-20120406.patch
#LTS
patch -p1<../msp430-gcc-4.6.3-20120406-sf3540953.patch
patch -p1<../msp430-gcc-4.6.3-20120406-sf3559978.patch
cd ..

# Patch GDB to bring it to release 20120406
echo "Patching gdb"
cd gdb-7.2
patch -p1<../mspgcc-20120406/msp430-gdb-7.2a-20120406.patch
cd ..

echo "Patching msp430-libc"
cd msp430-libc*
patch -p1<../msp430-libc-20120224-sf3522752.patch
cd ..

echo "Patching msp430mcu"
cd msp430mcu*
patch -p1<../msp430mcu-20120406-sf3522088.patch
cd ..

echo "INSTALLING"
#Create a sub-set of Build Directories
mkdir binutils-2.21.1-msp430
mkdir gcc-4.6.3-msp430
mkdir gdb-7.2-msp430


# Configure Binutils
cd binutils-2.21.1-msp430
# We need to build binutils for the msp430
../binutils-2.21.1/configure --target=msp430 --program-prefix="msp430-" 

make
#Do the install as root (e.g., sudo)
sudo make install

#  I have seen issues where the msp430-ranlib doesn't get detected correctly causing build issues later.
#  if that happens uncomment the following:
cd /usr/bin
sudo ln -s /usr/local/bin/msp430-ranlib

#Configure GCC
cd -
cd ../gcc-4.6.3-msp430
../gcc-4.6.3/configure --target=msp430 --enable-languages=c --program-prefix="msp430-" 

make
#Do the install as root (e.g., sudo)
sudo make install

#Configure GDB

cd ../gdb-7.2-msp430
../gdb-7.2/configure --target=msp430 --program-prefix="msp430-" 

make
#Do the install as root (e.g., sudo)
sudo make install

#Install the mspgcc-mcu files
cd ../msp430mcu-20120406
sudo MSP430MCU_ROOT=`pwd` ./scripts/install.sh /usr/local/

# Install the mspgcc-libc
cd ../msp430-libc-20120224

#  If you need to disable features, run configure here with any of the following flags to enable/disable features.
#  --disable-printf-int64 : Remove 64-bit integer support to printf formats
#  --disable-printf-int32 : Remove 32-bit integer support from printf formats
#  --enable-ieee754-errors : Use IEEE 754 error checking in libfp functions

cd src
make 
#Do the install as root (e.g., sudo)
sudo PATH=$PATH make PREFIX=/usr/local install
cd ../..

# Now let's build the debugger
cd mspdebug-0.19
make
#Do the install as root (e.g., sudo)
sudo make install
cd ../..

# ALL DONE
echo "Install completed"
