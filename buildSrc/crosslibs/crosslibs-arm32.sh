#!/bin/bash


if [[ "$1" != "" ]]; then
    DESTDIR="$1"
else
    DESTDIR=/opt/arm32
fi
DEST_VERSION=armv6hf

checkReinstall() {
    if [[ -d $1 ]]; then
        echo
        echo $1 already exists.
        echo -n "Delete and re-install? [y/N]: "
        read -n 1 -r
        echo
        if [[ $REPLY == "y" || $REPLY == "Y" ]]; then
            /bin/rm -rf $1
        fi
    fi
}

getPackages() {
    TOOLCHAIN=$1
    REPO=$2
    DISTRO=$3
    CATEGORY=$4
    ARCH=$5
    PACKAGES=${@:6}

    PACKAGEDIR=`echo $REPO | tr /: -`-$DISTRO-$CATEGORY-$ARCH

    OUT="$DESTDIR/$TOOLCHAIN"
    OUTDAT=$OUT.data

    PACKAGELIST=$OUTDAT/$PACKAGEDIR/Packages

    mkdir -p $OUT
    mkdir -p $OUTDAT
    cd $OUT
    echo Working in $PWD

    WGET="`which wget` -N --no-verbose"

    echo "Checking to see if we have ${PACKAGELIST}"
    if [ ! -f ${PACKAGELIST}/ ]
    then
        cd $OUTDAT
        mkdir -p $PACKAGEDIR
        cd $PACKAGEDIR
        echo Getting package list
        $WGET $REPO/dists/$DISTRO/$CATEGORY/binary-$ARCH/Packages.gz
        if [ ! -f Packages.gz ]
        then
            echo "Failed to download Packages for this distro"
            exit -1
        fi
        gunzip -c Packages.gz > Packages
        cd $OUT
    else 
        echo "Already have ${PACKAGELIST}, will reuse"
    fi

    DPKG_DEB=`which dpkg-deb`
    if [ ! "$DPKG_DEB" ]
    then
        echo "did not find dpkg-deb"
    fi
    SED=`which sed`
    if [ ! "$SED" ]
    then
        echo "did not find sed"
    fi

    echo
    echo "Processing our packages"

    for PACKAGE in ${PACKAGES}; do
        echo Working on package $PACKAGE
        PACKPATH=`$SED -ne "/^Package: $PACKAGE\$/,/Filename:/ s/^Filename: // p" ${PACKAGELIST}`
        if [[ -z "$PACKPATH" ]]; then
            echo "Could not find package $PACKAGE at $PACKPATH"
        else
            FILE=`/usr/bin/basename $PACKPATH`
            if [ ! -f "${OUTDAT}/${FILE}" ]
            then
                echo "Fetching $PACKAGE ($FILE)"
                cd $OUTDAT
                $WGET $REPO/$PACKPATH
                cd $OUT
            else
                echo Reusing cached $PACKAGE 
            fi
            echo Unpacking $PACKAGE
            $DPKG_DEB -x $OUTDAT/$FILE .
        fi
    done

}

installLibs() {
    DESTINATION=$DEST_VERSION

    getPackages  \
        $DESTINATION \
        http://ftp.debian.org/debian/ stretch main armhf \
            libatk1.0-dev \
            libcairo2-dev \
            libfontconfig1 \
            libfontconfig1-dev \
            libfreetype6 \
            libfreetype6-dev  \
	    libgbm-dev \
	    libgbm1 \
	    libgdk-pixbuf2.0-dev \
	    libgles2-mesa-dev \
	    libgles2-mesa \
            libglib2.0-0 \
            libglib2.0-dev \
            libgstreamer1.0-0 \
            libgstreamer1.0-dev \
            libgstreamer-plugins-base1.0-0 \
	    libgstreamer-plugins-base1.0-dev \
            libgtk-3-dev \
            libpango-1.0-0 \
            libpango1.0-dev \
            libpangoft2-1.0.0 \
            libpcre3-dev \
            libx11-6 \
            libx11-dev

    getPackages  \
        $DESTINATION \
        http://ftp.debian.org/debian/ buster main armhf \
            libasound2 \
            libasound2-dev \
            libavcodec-dev \
            libavformat-dev \
            libavutil-dev \
            libavcodec-extra58 \
            libavcodec58 \
            libavformat58 \
            libswresample-dev \

}
echo Building crosslibs in directory $DESTDIR

mkdir -p $DESTDIR || exit 1
installLibs

echo Add some links
rm $DESTDIR/$DEST_VERSION/usr/lib/arm-linux-gnueabihf/libglib-2.0.so
ln -s $DESTDIR/$DEST_VERSION/lib/arm-linux-gnueabihf/libglib-2.0.so.0 $DESTDIR/$DEST_VERSION/usr/lib/arm-linux-gnueabihf/libglib-2.0.so

echo
echo Done.

