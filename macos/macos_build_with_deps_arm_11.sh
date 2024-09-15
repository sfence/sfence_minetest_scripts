#!/bin/bash

if [[ $# -ne 4 ]] ; then
	echo 'Usage: compile_minetest.sh https_repo branch where build_type'
	exit 1
fi

PWD=$(pwd)
DIR=$(dirname "$0")

source $DIR/macos_build_deps.sh

echo "CLONING MINETEST"

rm -fr $3
mkdir -p $3

git clone --depth=1 -b $2 $1 $3

cd $3
MAIN_DIR=$(pwd)

echo "GETTING LIBRARY SOURCES"

download_macos_deps
untar_macos_deps

echo "COMPILING LIBRARIES"

compile_macos_deps "11" "arm64"

echo "COMPILING MINETEST"

mkdir build
cd build
export CMAKE_PREFIX_PATH=$MAIN_DIR/deps/install
cmake .. -DCMAKE_OSX_DEPLOYMENT_TARGET=11 -DCMAKE_FIND_FRAMEWORK=LAST -DCMAKE_OSX_ARCHITECTURES=arm64 -DCMAKE_INSTALL_PREFIX=../build/macos/ -DRUN_IN_PLACE=FALSE -DENABLE_GETTEXT=TRUE -DCMAKE_BUILD_TYPE=$4
make -j6
make install
codesign --force --deep -s - macos/minetest.app

echo "RUNNING MINETEST"

open ./macos/minetest.app

cd $PWD
