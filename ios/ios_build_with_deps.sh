#!/bin/bash

echo "This is script automate Luanti build process for iOS."

if [[ $# -ne 8 ]] ; then
	echo "Usage: ios_build_with_deps.sh https_repo branch where_luanti where_deps build_type arch osver step"
	echo "  arch - iPhone, iPhoneSimulator"
	echo "  osver  - 10.15, 11, 15 etc."
	echo "  step - all"
	echo "         clone|libs_get|libs_untar|libs_build|build"
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
osver=$7
step=$8

if [[ "$arch" != "iPhoneOS" ]] && [[ "$arch" != "iPhoneSimulator" ]]; then
	echo "Unsuported value of arch argument: $arch"
	exit 1
fi

source $SCRIPT_DIR/ios_build_deps.sh

if [[ "$step" == *"all"* ]] || [[ "$step" == *"clone"* ]] || [[ "$step" == *"luanti_all"* ]]; then
	echo "CLONING LUANTI"

	rm -fr $where_luanti
	mkdir -p $where_luanti

	git clone --depth=1 -b $branch $repo $where
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
	download_ios_deps $arch $osver
fi

if [[ "$step" == *"all"* ]] || [[ "$step" == *"libs_untar"* ]] || [[ "$step" == *"libs_all"* ]]; then
	echo "UNARCHIVING LIBRARY SOURCES"
	untar_ios_deps $arch $osver
fi

if [[ "$step" == *"all"* ]] || [[ "$step" == *"libs_build"* ]] || [[ "$step" == *"libs_all"* ]]; then
	echo "COMPILING LIBRARIES"

	compile_ios_deps $arch $osver $step
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

	unset IPHONEOS_DEPLOYMENT_TARGET
	unset CMAKE_PREFIX_PATH
	unset CPPFLAGS
	unset CC
	unset CFLAGS
	unset CXX
	unset CXXFLAGS
	unset LDFLAGS

	sdk=$(echo "$arch" | tr '[:upper:]' '[:lower:]')
	sdkroot="$(realpath $(xcrun --sdk ${sdk} --show-sdk-path)/../${arch}${osver}.sdk)"
	export CMAKE_PREFIX_PATH=$DEPS_DIR/install
	export SDKROOT="$sdkroot"
	echo "GENERATION XCODE PROJECT..."
	cmake .. -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_DEPLOYMENT_TARGET=$osver -DCMAKE_FIND_FRAMEWORK=LAST -DCMAKE_OSX_ARCHITECTURES=arm64 \
					-DCMAKE_INSTALL_PREFIX=../build/ios/ -DRUN_IN_PLACE=FALSE -DENABLE_GETTEXT=TRUE -DCMAKE_BUILD_TYPE=$build_type \
					-DCMAKE_PREFIX_PATH=${DEPS_DIR}/install \
					-DENABLE_OPENGL=OFF \
					-DENABLE_OPENGL3=OFF \
					-DENABLE_GLES2=ON \
					-DUSE_SDL2=ON \
					-DSDL2_DIR=${DEPS_DIR}/install/lib/cmake/SDL2 \
					-DSDL2_LIBRARIES="${DEPS_DIR}/install/lib/libSDL2.a;${DEPS_DIR}/install/lib/libSDL2main.a" \
					-DSDL2_INCLUDE_DIRS=${DEPS_DIR}/install/include/SDL2 \
					-DOPENGLES2_LIBRARY="" \
					-DOPENGLES2_INCLUDE_DIR=/Users/sfence/Desktop/minetest/angle/include \
					-DCURL_LIBRARY=${DEPS_DIR}/install/lib/libcurl.a \
					-DCURL_INCLUDE_DIR=${DEPS_DIR}/install/include \
					-DFREETYPE_LIBRARY=${DEPS_DIR}/install/lib/libfreetype.a \
					-DFREETYPE_INCLUDE_DIRS=${DEPS_DIR}/install/include/freetype2 \
					-DGETTEXT_INCLUDE_DIR=${DEPS_DIR}/install/include \
					-DGETTEXT_LIBRARY=${DEPS_DIR}/install/lib/libintl.a \
					-DLUA_LIBRARY=${DEPS_DIR}/install/lib/libluajit-5.1.a \
					-DLUA_INCLUDE_DIR=${DEPS_DIR}/install/include/luajit-2.1 \
					-DOGG_LIBRARY=${DEPS_DIR}/install/lib/libogg.a \
					-DOGG_INCLUDE_DIR=${DEPS_DIR}/install/include \
					-DVORBIS_LIBRARY=${DEPS_DIR}/install/lib/libvorbis.a \
					-DVORBISFILE_LIBRARY=${DEPS_DIR}/install/lib/libvorbisfile.a \
					-DVORBIS_INCLUDE_DIR=${DEPS_DIR}/install/include \
					-DZSTD_LIBRARY=${DEPS_DIR}/install/lib/libzstd.a \
					-DZSTD_INCLUDE_DIR=${DEPS_DIR}/install/include \
					-DGMP_LIBRARY=${DEPS_DIR}/install/lib/libgmp.a \
					-DGMP_INCLUDE_DIR=${DEPS_DIR}/install/include \
					-DJSON_LIBRARY=${DEPS_DIR}/install/lib/libjsoncpp.a \
					-DJSON_INCLUDE_DIR=${DEPS_DIR}/install/include \
					-DENABLE_LEVELDB=OFF \
					-DENABLE_POSTGRESQL=OFF \
					-DENABLE_REDIS=OFF \
					-DJPEG_LIBRARY=${DEPS_DIR}/install/lib/libjpeg.a \
					-DJPEG_INCLUDE_DIR=${DEPS_DIR}/install/include \
					-DPNG_LIBRARY=${DEPS_DIR}/install/lib/libpng.a \
					-DPNG_PNG_INCLUDE_DIR=${DEPS_DIR}/install/include \
					-DCMAKE_EXE_LINKER_FLAGS="-lbz2 -F/Users/sfence/Desktop/minetest/angle/out/ios -framework libEGL -framework libGLESv2" \
					-DXCODE_CODE_SIGN_ENTITLEMENTS=${LUANTI_DIR}/misc/ios/entitlements/release.entitlements \
					-GXcode
	: '
	cmake .. -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_DEPLOYMENT_TARGET=$osver -DCMAKE_FIND_FRAMEWORK=LAST -DCMAKE_OSX_ARCHITECTURES=arm64 \
					-DCMAKE_INSTALL_PREFIX=../build/ios/ -DRUN_IN_PLACE=FALSE -DENABLE_GETTEXT=TRUE -DCMAKE_BUILD_TYPE=$build_type \
					-DCMAKE_PREFIX_PATH=${DEPS_DIR}/deps/install \
					-DENABLE_OPENGL=OFF \
					-DENABLE_OPENGL3=OFF \
					-DENABLE_GLES2=ON \
					-DUSE_SDL2=OFF \
					-DUSE_SDL3=ON \
					-DSDL3_DIR=${DEPS_DIR}/deps/install/lib/cmake/SDL3 \
					-DSDL3_LIBRARIES="${DEPS_DIR}/deps/install/lib/liSDL3.a;${DEPS_DIR}/deps/install/lib/libSDL3main.a" \
					-DSDL3_INCLUDE_DIRS=${DEPS_DIR}/deps/install/include/SDL3 \
					-DOPENGLES2_LIBRARY_NO=${DEPS_DIR}/deps/install/lib/libGLESv2_static.a \
					-DOPENGLES2_INCLUDE_DIR=/Users/sfence/Desktop/minetest/angle/include \
					-DCURL_LIBRARY=${DEPS_DIR}/deps/install/lib/libcurl.a \
					-DCURL_INCLUDE_DIR=${DEPS_DIR}/deps/install/include \
					-DFREETYPE_LIBRARY=${DEPS_DIR}/deps/install/lib/libfreetype.a \
					-DFREETYPE_INCLUDE_DIRS=${DEPS_DIR}/deps/install/include/freetype2 \
					-DGETTEXT_INCLUDE_DIR=${DEPS_DIR}/deps/install/include \
					-DGETTEXT_LIBRARY=${DEPS_DIR}/deps/install/lib/libintl.a \
					-DLUA_LIBRARY=${DEPS_DIR}/deps/install/lib/libluajit-5.1.a \
					-DLUA_INCLUDE_DIR=${DEPS_DIR}/deps/install/include/luajit-2.1 \
					-DOGG_LIBRARY=${DEPS_DIR}/deps/install/lib/libogg.a \
					-DOGG_INCLUDE_DIR=${DEPS_DIR}/deps/install/include \
					-DVORBIS_LIBRARY=${DEPS_DIR}/deps/install/lib/libvorbis.a \
					-DVORBISFILE_LIBRARY=${DEPS_DIR}/deps/install/lib/libvorbisfile.a \
					-DVORBIS_INCLUDE_DIR=${DEPS_DIR}/deps/install/include \
					-DZSTD_LIBRARY=${DEPS_DIR}/deps/install/lib/libzstd.a \
					-DZSTD_INCLUDE_DIR=${DEPS_DIR}/deps/install/include \
					-DGMP_LIBRARY=${DEPS_DIR}/deps/install/lib/libgmp.a \
					-DGMP_INCLUDE_DIR=${DEPS_DIR}/deps/install/include \
					-DJSON_LIBRARY=${DEPS_DIR}/deps/install/lib/libjsoncpp.a \
					-DJSON_INCLUDE_DIR=${DEPS_DIR}/deps/install/include \
					-DENABLE_LEVELDB=OFF \
					-DENABLE_POSTGRESQL=OFF \
					-DENABLE_REDIS=OFF \
					-DJPEG_LIBRARY=${DEPS_DIR}/deps/install/lib/libjpeg.a \
					-DJPEG_INCLUDE_DIR=${DEPS_DIR}/deps/install/include \
					-DPNG_LIBRARY=${DEPS_DIR}/deps/install/lib/libpng.a \
					-DPNG_PNG_INCLUDE_DIR=${DEPS_DIR}/deps/install/include \
					-DCMAKE_EXE_LINKER_FLAGS="-lbz2 -F/Users/sfence/Desktop/minetest/angle/out/ios -framework libGLESv2" \
					-DXCODE_CODE_SIGN_ENTITLEMENTS=${LUANTI_DIR}/misc/ios/entitlements/release.entitlements \
					-GXcode'
	cd ..
fi

cd $RUN_DIR
