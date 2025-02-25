#!/bin/bash

echo "This is script automate Luanti build process."

if [[ $# -ne 8 ]] ; then
	echo "Usage: macos_build_with_deps.sh https_repo branch where_luanti where_deps build_type arch osx step"
	echo "  arch - x86_64 or arm64"
	echo "  osx  - 10.15, 11, 15 etc."
	echo "  step - all"
	echo "         clone|libs_get|libs_untar|libs_build|build|run|Xcode"
	echo "         luanti_all|libs_all"
	exit 1
fi

RUN_DIR=$(pwd)
SCRIPT_DIR=$(dirname "$0")

repo=$1
branch=$2
where_luanti=$3
where_deps=$4
build_type=$5
arch=$6
osx=$7
step=$8

if [[ "$arch" != "x86_64" ]] && [[ "$arch" != "arm64" ]]; then
	echo "Unsuported value of arch argument: $arch"
	exit 1
fi

source $SCRIPT_DIR/macos_build_deps.sh

if [[ "$step" == *"all"* ]] || [[ "$step" == *"clone"* ]] || [[ "$step" == *"luanti_all"* ]]; then
	echo "CLONING LUANTI"

	rm -fr $where_luanti
	mkdir -p $where_luanti

	git clone --depth=1 -b $branch $repo $where_luanti
fi

if [[ "$step" == *"all"* ]] || [[ "$step" == *"libs_get"* ]] || [[ "$step" == *"libs_all"* ]]; then
	rm -fr $where_deps
fi

mkdir -p $where_deps

cd $where_deps
if [ $? -ne 0 ]; then
	echo "Bad target directory $where_deps."
	exit 1
fi
DEPS_DIR=$(pwd)

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

cd $RUN_DIR

cd $where_luanti
if [ $? -ne 0 ]; then
	echo "Bad target directory $where_luanti."
	exit 1
fi
LUANTI_DIR=$(pwd)

if [[ "$step" == *"all"* ]] || [[ "$step" == *"build"* ]] || [[ "$step" == *"luanti_all"* ]]; then
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
	export CMAKE_PREFIX_PATH=$DEPS_DIR/install
	#if [[ ! -d "$sdkroot/usr/include/c++/v1" ]]; then
	#	export CXXFLAGS="-I$(xcrun --show-sdk-path)/usr/include/c++/v1"
	#fi
	export SDKROOT="$sdkroot"
	if [[ "$step" == *"Xcode"* ]]; then
		echo "GENERATION XCODE PROJECT..."
		cmake .. -DCMAKE_OSX_DEPLOYMENT_TARGET=$osx -DCMAKE_FIND_FRAMEWORK=LAST -DCMAKE_OSX_ARCHITECTURES=$arch \
						-DCMAKE_INSTALL_PREFIX=../build/macos/ -DRUN_IN_PLACE=FALSE -DENABLE_GETTEXT=TRUE -DCMAKE_BUILD_TYPE=$build_type \
						-DFREETYPE_LIBRARY=${DEPS_DIR}/install/lib/libfreetype.a \
						-DGETTEXT_INCLUDE_DIR=${DEPS_DIR}/install/include \
						-DGETTEXT_LIBRARY=${DEPS_DIR}/install/lib/libintl.a \
						-DLUA_LIBRARY=${DEPS_DIR}/install/lib/libluajit-5.1.a \
						-DOGG_LIBRARY=${DEPS_DIR}/install/lib/libogg.a \
						-DVORBIS_LIBRARY=${DEPS_DIR}/install/lib/libvorbis.a \
						-DVORBISFILE_LIBRARY=${DEPS_DIR}/install/lib/libvorbisfile.a \
						-DZSTD_LIBRARY=${DEPS_DIR}/install/lib/libzstd.a \
						-DGMP_LIBRARY=${DEPS_DIR}/install/lib/libgmp.a \
						-DJSON_LIBRARY=${DEPS_DIR}/install/lib/libjsoncpp.a \
						-DENABLE_LEVELDB=OFF \
						-DENABLE_POSTGRESQL=OFF \
						-DENABLE_REDIS=OFF \
						-DENABLE_OPENSSL=OFF \
						-DJPEG_LIBRARY=${DEPS_DIR}/install/lib/libjpeg.a \
						-DPNG_LIBRARY=${DEPS_DIR}/install/lib/libpng.a \
						-DCMAKE_EXE_LINKER_FLAGS=-lbz2 \
						-DXCODE_CODE_SIGN_ENTITLEMENTS=${LUANTI_DIR}/misc/macos/entitlements/release_map_jit.entitlements \
						-GXcode
	else
		cmake .. -DCMAKE_OSX_DEPLOYMENT_TARGET=$osx -DCMAKE_FIND_FRAMEWORK=LAST -DCMAKE_OSX_ARCHITECTURES=$arch \
						-DCMAKE_INSTALL_PREFIX=../build/macos/ -DRUN_IN_PLACE=FALSE -DENABLE_GETTEXT=TRUE -DCMAKE_BUILD_TYPE=$build_type \
						-DFREETYPE_LIBRARY=${DEPS_DIR}/install/lib/libfreetype.dylib \
						-DGETTEXT_INCLUDE_DIR=${DEPS_DIR}/install/include \
						-DGETTEXT_LIBRARY=${DEPS_DIR}/install/lib/libintl.dylib \
						-DLUA_LIBRARY=${DEPS_DIR}/install/lib/libluajit-5.1.dylib \
						-DOGG_LIBRARY=${DEPS_DIR}/install/lib/libogg.dylib \
						-DVORBIS_LIBRARY=${DEPS_DIR}/install/lib/libvorbis.dylib \
						-DVORBISFILE_LIBRARY=${DEPS_DIR}/install/lib/libvorbisfile.dylib \
						-DZSTD_LIBRARY=${DEPS_DIR}/install/lib/libzstd.dylib \
						-DGMP_LIBRARY=${DEPS_DIR}/install/lib/libgmp.dylib \
						-DJSON_LIBRARY=${DEPS_DIR}/install/lib/libjsoncpp.dylib \
						-DENABLE_LEVELDB=OFF \
						-DENABLE_POSTGRESQL=OFF \
						-DENABLE_REDIS=OFF \
						-DENABLE_OPENSSL=OFF \
						-DJPEG_LIBRARY=${DEPS_DIR}/install/lib/libjpeg.dylib \
						-DPNG_LIBRARY=${DEPS_DIR}/install/lib/libpng.dylib
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

cd $RUN_DIR
