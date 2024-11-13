#!/bin/bash

echo "This is script automate Luanti build process."

if [[ $# -ne 7 ]] ; then
	echo "Usage: macos_build_with_deps.sh https_repo branch where build_type arch osx step"
	echo "  arch - x86_64 or arm64"
	echo "  osx  - 10.15, 11, 15 etc."
	echo "  step - all"
	echo "         clone|libs_get|libs_untar|libs_build|build|run|Xcode"
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
	echo "CLONING LUANTI"

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
	download_macos_deps $arch $osx
fi

if [[ "$step" == *"all"* ]] || [[ "$step" == *"libs_untar"* ]] || [[ "$step" == *"libs_all"* ]]; then
	echo "UNARCHIVING LIBRARY SOURCES"
	untar_macos_deps $arch $osx
fi

if [[ "$step" == *"all"* ]] || [[ "$step" == *"libs_build"* ]] || [[ "$step" == *"libs_all"* ]]; then
	echo "COMPILING LIBRARIES"

	compile_macos_deps $arch $osx
fi

if [[ "$step" == *"all"* ]] || [[ "$step" == *"build"* ]]; then
	echo "COMPILING LUANTI"

	rm -fr build
	mkdir build
	cd build

	unset MACOSX_DEPLOYMENT_TARGET
	unset MACOS_DEPLOYMENT_TARGET
	unset CMAKE_PREFIX_PATH
	unset CPPFLAGS
	unset CC
	unset CFLAGS
	unset CXX
	unset CXXFLAGS
	unset LDFLAGS

	sdkroot="$(realpath $(xcrun --show-sdk-path)/../MacOSX${osx}.sdk)"
	export CMAKE_PREFIX_PATH=$MAIN_DIR/deps/install
	#if [[ ! -d "$sdkroot/usr/include/c++/v1" ]]; then
	#	export CXXFLAGS="-I$(xcrun --show-sdk-path)/usr/include/c++/v1"
	#fi
	export SDKROOT="$sdkroot"
	if [[ "$step" == *"Xcode"* ]]; then
		echo "GENERATION XCODE PROJECT..."
		cmake .. -DCMAKE_OSX_DEPLOYMENT_TARGET=$osx -DCMAKE_FIND_FRAMEWORK=LAST -DCMAKE_OSX_ARCHITECTURES=$arch \
						-DCMAKE_INSTALL_PREFIX=../build/macos/ -DRUN_IN_PLACE=FALSE -DENABLE_GETTEXT=TRUE -DCMAKE_BUILD_TYPE=$build_type \
						-DFREETYPE_LIBRARY=${MAIN_DIR}/deps/install/lib/libfreetype.a \
						-DGETTEXT_INCLUDE_DIR=${MAIN_DIR}/deps/install/include \
						-DGETTEXT_LIBRARY=${MAIN_DIR}/deps/install/lib/libintl.a \
						-DLUA_LIBRARY=${MAIN_DIR}/deps/install/lib/libluajit-5.1.a \
						-DOGG_LIBRARY=${MAIN_DIR}/deps/install/lib/libogg.a \
						-DVORBIS_LIBRARY=${MAIN_DIR}/deps/install/lib/libvorbis.a \
						-DVORBISFILE_LIBRARY=${MAIN_DIR}/deps/install/lib/libvorbisfile.a \
						-DZSTD_LIBRARY=${MAIN_DIR}/deps/install/lib/libzstd.a \
						-DGMP_LIBRARY=${MAIN_DIR}/deps/install/lib/libgmp.a \
						-DJSON_LIBRARY=${MAIN_DIR}/deps/install/lib/libjsoncpp.a \
						-DENABLE_LEVELDB=OFF \
						-DENABLE_POSTGRESQL=OFF \
						-DENABLE_REDIS=OFF \
						-DJPEG_LIBRARY=${MAIN_DIR}/deps/install/lib/libjpeg.a \
						-DPNG_LIBRARY=${MAIN_DIR}/deps/install/lib/libpng.a \
						-DCMAKE_EXE_LINKER_FLAGS=-lbz2 \
						-DXCODE_CODE_SIGN_ENTITLEMENTS=${MAIN_DIR}/misc/macos/entitlements/release_map_jit.entitlements \
						-GXcode
	else
		cmake .. -DCMAKE_OSX_DEPLOYMENT_TARGET=$osx -DCMAKE_FIND_FRAMEWORK=LAST -DCMAKE_OSX_ARCHITECTURES=$arch \
						-DCMAKE_INSTALL_PREFIX=../build/macos/ -DRUN_IN_PLACE=FALSE -DENABLE_GETTEXT=TRUE -DCMAKE_BUILD_TYPE=$build_type \
						-DFREETYPE_LIBRARY=${MAIN_DIR}/deps/install/lib/libfreetype.dylib \
						-DGETTEXT_INCLUDE_DIR=${MAIN_DIR}/deps/install/include \
						-DGETTEXT_LIBRARY=${MAIN_DIR}/deps/install/lib/libintl.dylib \
						-DLUA_LIBRARY=${MAIN_DIR}/deps/install/lib/libluajit-5.1.dylib \
						-DOGG_LIBRARY=${MAIN_DIR}/deps/install/lib/libogg.dylib \
						-DVORBIS_LIBRARY=${MAIN_DIR}/deps/install/lib/libvorbis.dylib \
						-DVORBISFILE_LIBRARY=${MAIN_DIR}/deps/install/lib/libvorbisfile.dylib \
						-DZSTD_LIBRARY=${MAIN_DIR}/deps/install/lib/libzstd.dylib \
						-DGMP_LIBRARY=${MAIN_DIR}/deps/install/lib/libgmp.dylib \
						-DJSON_LIBRARY=${MAIN_DIR}/deps/install/lib/libjsoncpp.dylib \
						-DENABLE_LEVELDB=OFF \
						-DENABLE_POSTGRESQL=OFF \
						-DENABLE_REDIS=OFF \
						-DJPEG_LIBRARY=${MAIN_DIR}/deps/install/lib/libjpeg.dylib \
						-DPNG_LIBRARY=${MAIN_DIR}/deps/install/lib/libpng.dylib
		make -j$(sysctl -n hw.logicalcpu)
		make install
		if [[ "$arch" == "arm64" ]]; then
			codesign --force --deep -s - --entitlements ../misc/macos/entitlements/debug.entitlements macos/luanti.app
		fi
	fi
	cd ..
fi


if [[ "$step" == *"all"* ]] || [[ "$step" == *"run"* ]]; then
	echo "RUNNING LUANTI"

	open ./build/macos/luanti.app
fi

cd $PWD
