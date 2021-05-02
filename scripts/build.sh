#!/bin/bash

# Build script which sets up environment variables appropriately so cross-compilation
# works inside the docker container.

# This script should also be runnable on the host system itself, if SYSROOT is configured appropriately,
# but that has not been tested.

SCRIPTPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
HOST=arm-remarkable-linux-gnueabihf

if [ -z "$TARGET_WORKSPACE" ]; then echo "TARGET_WORKSPACE is required, but not set." && exit 1; fi

if [ -z "$MAKE" ]; then export MAKE=make; fi

source $SCRIPTPATH/versions.sh
source $SCRIPTPATH/env.sh

# Required so the netsurf make picks up the previously built libraries
export CFLAGS="$CFLAGS -I$TARGET_WORKSPACE/inst-$HOST/include"
export LDFLAGS="$LDFLAGS -L$TARGET_WORKSPACE/inst-$HOST/lib" 
export LDFLAGS="$LDFLAGS -L$TARGET_WORKSPACE/inst-$HOST/lib" 
# freetype libs end up in /usr/local, so include that for pkg-config
export PKG_CONFIG_LIBDIR="$PKG_CONFIG_LIBDIR:$SYSROOT/usr/local/lib/pkgconfig"

# For local development, you can clone any repository into target workspace
# before running this script
ns-clone
ns-make-tools install
ns-make-libs install

cd $TARGET_WORKSPACE/netsurf/

# Would probably be nicer to to pkg_config libevdev in the netsurf Makefile,
# but we are re-pulling that Makefile every build.
# This works for now.
export LDFLAGS="$LDFLAGS -levdev -lpthread"

export LDFLAGS="$LDFLAGS  -Wl,--rpath,/opt/lib,--dynamic-linker,/opt/lib/ld-linux.so.3"

export BUILD_CC="arm-remarkable-linux-gnueabihf-gcc"
$MAKE TARGET=framebuffer NETSURF_FB_FONTLIB=freetype NETSURF_USE_DUKTAPE=NO CC=$BUILD_CC
