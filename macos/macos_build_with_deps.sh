#!/bin/bash

if [[ $# -ne 7 ]] ; then
	echo "Usage: compile_minetest.sh https_repo branch where build_type arch osx step"
	echo "  arch - x86_64 or arm64"
	echo "  osx  - 10.14, 11, 15 etc."
	echo "  step - all"
	echo "         clone|libs_get|libs_untar|libs_build|build|run"
	echo "         libs_all"
	exit 1
fi

PWD=$(pwd)
DIR=$(dirname "$0")

repo=$1
branch=$2
where=$3
build_type=$4
arch=$5
osx=$6
step=$7

if [[ "$arch" != "x86_64" ]] && [[ "$arch" != "arm64" ]]; then
	echo "Unsuported value of arch argument: $arch"
	exit 1
fi

source $DIR/macos_build_deps.sh

if [[ "$step" == *"all"* ]] || [[ "$step" == *"clone"* ]]; then
	echo "CLONING MINETEST"

	rm -fr $where
	mkdir -p $where

	git clone --depth=1 -b $branch $repo $where
fi

cd $where
if [ $? -ne 0 ]; then
	echo "Bad target directory $where."
	exit 1
fi
MAIN_DIR=$(pwd)


if [[ "$step" == *"all"* ]] || [[ "$step" == *"libs_get"* ]] || [[ "$step" == *"libs_all"* ]]; then
	echo "GETTING LIBRARY SOURCES"
	download_macos_deps
fi

if [[ "$step" == *"all"* ]] || [[ "$step" == *"libs_untar"* ]] || [[ "$step" == *"libs_all"* ]]; then
	echo "UNARCHIVING LIBRARY SOURCES"
	untar_macos_deps
fi

if [[ "$step" == *"all"* ]] || [[ "$step" == *"libs_build"* ]] || [[ "$step" == *"libs_all"* ]]; then
	echo "COMPILING LIBRARIES"

	compile_macos_deps $arch $osx
fi

if [[ "$step" == *"all"* ]] || [[ "$step" == *"build"* ]]; then
	echo "COMPILING MINETEST"

	rm -fr build
	mkdir build
	cd build
	sdkroot="$(realpath $(xcrun --show-sdk-path)/../MacOSX${osx}.sdk)"
	export CMAKE_PREFIX_PATH=$MAIN_DIR/deps/install
	if [[ ! -d "$sdkroot/usr/include/c++/v1" ]]; then
		export CXXFLAGS="-I$(xcrun --show-sdk-path)/usr/include/c++/v1"
	fi
	export SDKROOT="$sdkroot"
	cmake .. -DCMAKE_OSX_DEPLOYMENT_TARGET=$osx -DCMAKE_FIND_FRAMEWORK=LAST -DCMAKE_OSX_ARCHITECTURES=$arch \
					-DCMAKE_INSTALL_PREFIX=../build/macos/ -DRUN_IN_PLACE=FALSE -DENABLE_GETTEXT=TRUE -DCMAKE_BUILD_TYPE=$build_type
	make -j$(sysctl -n hw.logicalcpu)
	make install
	if [[ "$arch" == "arm64" ]]; then
		codesign --force --deep -s - macos/minetest.app
	fi
	cd ..
fi


if [[ "$step" == *"all"* ]] || [[ "$step" == *"run"* ]]; then
	echo "RUNNING MINETEST"

	open ./build/macos/minetest.app
fi

cd $PWD