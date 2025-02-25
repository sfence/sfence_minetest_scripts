#!/bin/bash -e

download_ios_archive() {
	rm -f $1
	wget -O $1 $2
	checksum=$(shasum -a 256 $1)
	if [[ "$checksum" != "$3  $1" ]]; then
		echo "Downloaded file $1 has unexpected checksum $checksum."
		exit 1
	fi
}

download_ios_deps() {
	arch=$1
	osver=$2

	brew install cmake nasm wget m4 autoconf automake libtool

	echo "Downloading sources..."
	download_ios_archive gettext.tar.gz https://ftp.gnu.org/gnu/gettext/gettext-0.22.5.tar.gz ec1705b1e969b83a9f073144ec806151db88127f5e40fe5a94cb6c8fa48996a0
	download_ios_archive freetype.tar.xz https://downloads.sourceforge.net/project/freetype/freetype2/2.13.3/freetype-2.13.3.tar.xz 0550350666d427c74daeb85d5ac7bb353acba5f76956395995311a9c6f063289
	download_ios_archive gmp.tar.xz https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz a3c2b80201b89e68616f4ad30bc66aee4927c3ce50e33929ca819d5c43538898
	download_ios_archive libjpeg-turbo.tar.gz https://github.com/libjpeg-turbo/libjpeg-turbo/releases/download/3.0.3/libjpeg-turbo-3.0.3.tar.gz 343e789069fc7afbcdfe44dbba7dbbf45afa98a15150e079a38e60e44578865d
	download_ios_archive jsoncpp.tar.gz https://github.com/open-source-parsers/jsoncpp/archive/refs/tags/1.9.5.tar.gz f409856e5920c18d0c2fb85276e24ee607d2a09b5e7d5f0a371368903c275da2
	download_ios_archive libogg.tar.gz https://ftp.osuosl.org/pub/xiph/releases/ogg/libogg-1.3.5.tar.gz 0eb4b4b9420a0f51db142ba3f9c64b333f826532dc0f48c6410ae51f4799b664
	download_ios_archive libpng.tar.xz https://downloads.sourceforge.net/project/libpng/libpng16/1.6.43/libpng-1.6.43.tar.xz 6a5ca0652392a2d7c9db2ae5b40210843c0bbc081cbd410825ab00cc59f14a6c
	download_ios_archive libvorbis.tar.gz https://github.com/sfence/libvorbis/archive/refs/tags/v1.3.7_macos_apple_silicon.tar.gz 61dd22715136f13317326ea60f9c1345529fbc1bf84cab99d6b7a165bf86a609
	download_ios_archive luajit.tar.gz https://github.com/LuaJIT/LuaJIT/archive/f725e44cda8f359869bf8f92ce71787ddca45618.tar.gz 2b5514bd6a6573cb6111b43d013e952cbaf46762d14ebe26c872ddb80b5a84e0
	download_ios_archive zstd.tar.gz https://github.com/facebook/zstd/archive/refs/tags/v1.5.6.tar.gz 30f35f71c1203369dc979ecde0400ffea93c27391bfd2ac5a9715d2173d92ff7
	download_ios_archive sdl2.tar.gz https://github.com/libsdl-org/SDL/releases/download/release-2.32.0/SDL2-2.32.0.tar.gz 24b574f71c87a763f50704bbb630cbe38298d544a1f890f099a4696b1d6beba4
	#download_ios_archive sdl3.tar.gz https://github.com/libsdl-org/SDL/archive/refs/tags/release-3.2.2.tar.gz 24b574f71c87a763f50704bbb630cbe38298d544a1f890f099a4696b1d6beba4
	download_ios_archive curl.tar.gz https://github.com/curl/curl/releases/download/curl-8_11_0/curl-8.11.0.tar.gz 264537d90e58d2b09dddc50944baf3c38e7089151c8986715e2aaeaaf2b8118f


	#if [[ "$step" == *"curl"* ]]; then
		# extra dependencies
		#download_ios_dep libssh2.tar.gz https://github.com/libssh2/libssh2/releases/download/libssh2-1.11.0/libssh2-1.11.0.tar.gz 
		#download_ios_dep openssl.tar.gz https://github.com/openssl/openssl/releases/download/openssl-3.3.1/openssl-3.3.1.tar.gz
		#download_ios_dep curl.tar.bz2 https://curl.se/download/curl-8.9.1.tar.bz2 27e4b36550b676c42d1a533ade5b2b35ac7ca95e1998bd05cc34b5dfa3bdc9c0539ec7000481230b6431baa549e64da1b46b39d6ba1f112e37458d7b35948c2e
	#fi
}

untar_ios_deps() {
	arch=$1
	osver=$2

	rm -fr libpng-*
	rm -fr gettext-*
	rm -fr freetype-*
	rm -fr gmp-*
	rm -fr libjpeg-turbo-*
	rm -fr jsoncpp-*
	rm -fr libogg-*
	rm -fr libvorbis-*
	rm -fr LuaJIT-*
	rm -fr zstd-*
	rm -fr SDL2-*
	rm -fr SDL3-*
	rm -fr curl-*

	echo "Unarchiving sources..."
	tar -xf libpng.tar.xz
	tar -xf gettext.tar.gz
	tar -xf freetype.tar.xz
	tar -xf gmp.tar.xz
	tar -xf libjpeg-turbo.tar.gz
	tar -xf jsoncpp.tar.gz
	tar -xf libogg.tar.gz
	tar -xf libvorbis.tar.gz
	tar -xf luajit.tar.gz
	tar -xf zstd.tar.gz
	tar -xf sdl2.tar.gz
	tar -xf sdl3.tar.gz
	tar -xf curl.tar.gz

	#if [[ "$step" == *"curl"* ]]; then
		#rm -fr curl-*

		#tar -xf curl.tar.bz2
	#fi
	
	# remove also install dir, so everything has to be rebuilded
	rm -fr install
}

check_ios_file() {
	if [ ! -f "$1" ]; then
		echo "File $1 not found"
		exit 1
	fi
}

compile_ios_deps() {
	arch=$1
	osver=$2
	step=$3
	
	target_sysroot="/Applications/Xcode.app/Contents/Developer/Platforms/${arch}.platform/Developer/SDKs/${arch}${osver}.sdk"
	if [ ! -d "$target_sysroot" ]; then
		echo "Requested target sysroot SDK does not found ${arch}${osver}.sdk"
		exit 1
	fi
	host_sysroot="/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk"
	if [ ! -d "$host_sysroot" ]; then
		echo "Requested host sysroot SDK does not found MacOSX.sdk"
		exit 1
	fi

	mkdir -p install

	dir=$(pwd)

	#export IPHONEOS_DEPLOYMENT_TARGET=$osver
	export CMAKE_PREFIX_PATH=$dir/install
	export CPPFLAGS="-arch arm64"
	export CC="$(xcrun --sdk iphonesimulator --find clang) -isysroot $target_sysroot"
	#export CC="clang -arch arm64"
	#export CFLAGS="-arch arm64"
	export CXX="$(xcrun --sdk iphonesimulator --find clang++) -isysroot $target_sysroot"
	#export CXX="clang++ -arch arm64 -isysroot $sysroot"
	#export CXXFLAGS="-arch arm64 -isysroot $sysroot"
	export LDFLAGS="-arch arm64"
	#export SDKROOT=$sysroot
	HOST_CC="clang -isysroot $host_sysroot"
	hostdarwin="--host=arm64-apple-darwin"
	hostios="--host=arm64-apple-ios${osver}"
	hostdarwin_limit="--host=arm-apple-darwin"

	echo "arch=$arch" > env_log.txt
	echo "osver=$osver" >> env_log.txt
	echo "dir=$dir" >> env_log.txt
	echo "sysroot=$sysroot" >> env_log.txt
	echo "includecxx=$includecxx" >> env_log.txt
	echo "hostdarwin=$hostdarwin" >> env_log.txt
	echo "hostios=$hostios" >> env_log.txt
	echo "dir=$dir" >> env_log.txt
	echo "IPHONEOS_DEPLOYMENT_TARGET=$IPHONEOS_DEPLOYMENT_TARGET "\
				"CMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH CPPFLAGS='$CPPFLAGS' CC='$CC' CXX='$CXX' "\
				"LDFLAGS='$LDFLAGS' SDKROOT=$SDKROOT ls ." >> env_log.txt

	# We do not have to check $step for all and libs_all, in that case, dir is removed and recreated
	# So as default we build only not built deps

	# libpng
	check_file="$dir/install/lib/libpng.a"
	if [ ! -f "$check_file" ] || [[ "$step" == *"png"* ]]; then
		cd libpng-*
		echo "Configuring libpng..."
		./configure "--prefix=$dir/install" $hostdarwin 2>&1 | tee log_config.txt
		echo "Building libpng..."
		make -j$(sysctl -n hw.logicalcpu) 2>&1 | tee log_build.txt
		# make check 2>&1 | tee log_check.txt
		make install 2>&1 | tee log_install.txt
		check_ios_file $check_file
		cd $dir
	fi

	# freetype
	check_file="$dir/install/lib/libfreetype.a"
	if [ ! -f "$check_file" ] || [[ "$step" == *"freetype"* ]]; then
		cd freetype-*
		echo "Configuring freetype..."
		./configure "--prefix=${dir}/install" "LIBPNG_LIBS=-L${dir}/install/lib -lpng" \
								"LIBPNG_CFLAGS=-I${dir}/install/include" $hostdarwin \
								--with-harfbuzz=no --with-brotli=no --with-librsvg=no \
								"CC_BUILD=$HOST_CC" 2>&1 | tee log_config.txt
		echo "Building freetype..."
		make -j$(sysctl -n hw.logicalcpu) 2>&1 | tee log_build.txt
		make install 2>&1 | tee log_install.txt
		check_ios_file "$check_file"
		cd $dir
	fi

	# gettext
	check_file="$dir/install/lib/libintl.a"
	if [ ! -f "$check_file" ] || [[ "$step" == *"gettext"* ]]; then
		cd gettext-*
		echo "Configuring gettext..."
		./configure "--prefix=$dir/install" --disable-silent-rules --with-included-glib \
								--with-included-libcroco --with-included-libunistring --with-included-libxml \
								--with-emacs --disable-java --disable-csharp --without-git --without-cvs \
								--without-xz --with-included-gettext $hostdarwin 2>&1 | tee log_config.txt
		echo "Building gettext..."
		make -j$(sysctl -n hw.logicalcpu) 2>&1 | tee log_build.txt
		make install 2>&1 | tee log_install.txt
		check_ios_file "$check_file"
		cd $dir
	fi

	# gmp
	check_file="$dir/install/lib/libgmp.a"
	if [ ! -f "$check_file" ] || [[ "$step" == *"gmp"* ]]; then
		cd gmp-*
		echo "Configuring gmp..."
		# different Cellar location on Intel and Arm MacOS
		# --disable-assembly can be used for cross build
		assembly=
		if [[ "$(arch)" != "arm64" ]]; then
			assembly=--disable-assembly
		fi
		#./configure "--prefix=$dir/install" --with-pic M4=/usr/local/Cellar/m4/1.4.19/bin/m4
		CC_FOR_BUILD="$HOST_CC" \
		./configure "--prefix=$dir/install" --with-pic M4=/opt/homebrew/Cellar/m4/1.4.19/bin/m4 \
								$hostdarwin $assembly 2>&1 | tee log_config.txt
		echo "Building gmp..."
		make -j$(sysctl -n hw.logicalcpu) 2>&1 | tee log_build.txt
		make check 2>&1 | tee log_check.txt
		make install 2>&1 | tee log_install.txt
		check_ios_file "$check_file"
		cd $dir
	fi

	# libjpeg-turbo
	check_file="$dir/install/lib/libjpeg.a"
	if [ ! -f "$check_file" ] || [[ "$step" == *"jpeg"* ]]; then
		cd libjpeg-turbo-*
		logdir=$(pwd)
		#rm -fr build
		#mkdir build
		#cd build
		echo "Configuring libjpeg-turbo..."
		cmake . "-DCMAKE_INSTALL_PREFIX:PATH=$dir/install" \
						-DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_DEPLOYMENT_TARGET=$osver \
						-DCMAKE_OSX_ARCHITECTURES=arm64 -DCMAKE_OSX_SYSROOT=$target_sysroot \
						-DCMAKE_SYSTEM_PROCESSOR=arm64 \
						-DCMAKE_INSTALL_NAME_DIR=$dir/install/lib 2>&1 | tee "$logdir/log_config.txt"
		echo "Building libjpeg-turbo..."
		make -j$(sysctl -n hw.logicalcpu) 2>&1 | tee "$logdir/log_build.txt"
		make install "PREFIX=$dir/install" 2>&1 | tee "$logdir/log_install.txt"
		check_ios_file "$check_file"
		cd $dir
	fi

	# jsoncpp
	check_file="$dir/install/lib/libjsoncpp.a"
	if [ ! -f "$check_file" ] || [[ "$step" == *"json"* ]]; then
		cd jsoncpp-*
		logdir=$(pwd)
		rm -fr build
		mkdir build
		cd build
		echo "Configuring jsoncpp..."
		cmake .. "-DCMAKE_INSTALL_PREFIX:PATH=$dir/install" \
						-DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_DEPLOYMENT_TARGET=$osver \
						-DCMAKE_OSX_ARCHITECTURES=arm64 -DCMAKE_OSX_SYSROOT=$target_sysroot \
						-DJSONCPP_WITH_TESTS=OFF \
						-DCMAKE_INSTALL_NAME_DIR=$dir/install/lib 2>&1 | tee "$logdir/log_config.txt"
		echo "Building jsoncpp..."
		make -j$(sysctl -n hw.logicalcpu) 2>&1 | tee "$logdir/log_build.txt"
		make install 2>&1 | tee "$logdir/log_install.txt"
		check_ios_file "$check_file"
		cd $dir
	fi

	# libogg
	check_file="$dir/install/lib/libogg.a"
	if [ ! -f "$check_file" ] || [[ "$step" == *"ogg"* ]]; then
		cd libogg-*
		echo "Configuring libogg..."
		./configure "--prefix=$dir/install" $hostdarwin_limit 2>&1 | tee log_config.txt
		echo "Building libogg..."
		make -j$(sysctl -n hw.logicalcpu) 2>&1 | tee log_build.txt
		make install 2>&1 | tee log_install.txt
		check_ios_file "$check_file"
		cd $dir
	fi

	# libvorbis
	check_file="$dir/install/lib/libvorbis.a"
	if [ ! -f "$check_file" ] || [[ "$step" == *"vorbis"* ]]; then
		cd libvorbis-*
		echo "Configuring libvorbis..."
		./autogen.sh 2>&1 | tee log_autogen.txt
		OGG_LIBS="-L${dir}/install/lib -logg" OGG_CFLAGS="-I${dir}/install/include" ./configure "--prefix=$dir/install"	\
					$hostdarwin 2>&1 | tee log_config.txt
		echo "Building libvorbis..."
		make -j$(sysctl -n hw.logicalcpu) 2>&1 | tee log_build.txt
		make install 2>&1 | tee log_install.txt
		check_ios_file "$check_file"
		cd $dir
	fi

	# luajit
	check_file="$dir/install/lib/libluajit-5.1.a"
	if [ ! -f "$check_file" ] || [[ "$step" == *"luajit"* ]]; then
		cd LuaJIT-*
		echo "Building LuaJIT..."
		target_jit_flags="-arch arm64 -isysroot $target_sysroot -DLUAJIT_DISABLE_JIT"
		host_jit_flags="-arch arm64 -isysroot $host_sysroot -DLUAJIT_DISABLE_JIT"
		make -j$(sysctl -n hw.logicalcpu) "PREFIX=$dir/install" \
					"CC=$CC" \
					"HOST_CC=$HOST_CC" \
					"CFLAGS=$target_jit_flags" "HOST_CFLAGS=$host_jit_flags" \
					"TARGET_CFLAGS=$target_jit_flags" TARGET_SYS=iOS\
					2>&1 | tee log_build.txt
		make install \
					"CFLAGS=$jit_flags" "HOST_CFLAGS=$jit_flags" \
					"TARGET_CFLAGS=$jit_flags" TARGET_SYS=iOS\
					"PREFIX=$dir/install" 2>&1 | tee log_install.txt
		check_ios_file "$check_file"
		cd $dir
	fi

	# zstd
	check_file="$dir/install/lib/libzstd.a"
	if [ ! -f "$check_file" ] || [[ "$step" == *"zstd"* ]]; then
		cd zstd-*
		logdir=$(pwd)
		cd build/cmake
		echo "Configuring zstd..."
		cmake . "-DCMAKE_INSTALL_PREFIX:PATH=$dir/install" \
						-DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_DEPLOYMENT_TARGET=$osver \
						-DCMAKE_OSX_ARCHITECTURES=arm64 -DCMAKE_OSX_SYSROOT=$target_sysroot \
						-DCMAKE_INSTALL_NAME_DIR=$dir/install/lib 2>&1 | tee "$logdir/log_config.txt"
		echo "Building zstd..."
		make -j$(sysctl -n hw.logicalcpu) 2>&1 | tee "$logdir/log_build.txt"
		make install 2>&1 | tee "$logdir/log_install.txt"
		check_ios_file "$check_file"
		cd $dir
	fi
	
	# SDL2
	check_file="$dir/install/lib/libSDL2.a"
	if [ ! -f "$check_file" ] || [[ "$step" == *"SDL"* ]]; then
		cd SDL2-*
		logdir=$(pwd)
		rm -fr build
		mkdir build
		cd build
		echo "Configuring SDL2..."
		cmake .. "-DCMAKE_INSTALL_PREFIX:PATH=$dir/install" \
						-DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_DEPLOYMENT_TARGET=$osver \
						-DCMAKE_OSX_ARCHITECTURES=arm64 -DCMAKE_OSX_SYSROOT=$target_sysroot \
						-DSDL_OPENGL=0 -DSDL_OPENGLES=0 \
						-DCMAKE_EXE_LINKER_FLAGS="/Users/sfence/Desktop/minetest/angle/libGLESv2.a" \
						-DCMAKE_C_FLAGS="-I/Users/sfence/Desktop/minetest/angle/include" \
						-DCMAKE_INSTALL_NAME_DIR=$dir/install/lib 2>&1 | tee "$logdir/log_config.txt"
		echo "Building SDL2..."
		make -j$(sysctl -n hw.logicalcpu) 2>&1 | tee "$logdir/log_build.txt"
		make install 2>&1 | tee "$logdir/log_install.txt"
		check_ios_file "$check_file"
		cd $dir
	fi
	# SDL3
	: '
	check_file="$dir/install/lib/libSDL3.a"
	if [ ! -f "$check_file" ] || [[ "$step" == *"SDL"* ]]; then
		cd SDL3-*
		logdir=$(pwd)
		rm -fr build
		mkdir build
		cd build
		echo "Configuring SDL3..."
		cmake .. "-DCMAKE_INSTALL_PREFIX:PATH=$dir/install" \
						-DSDL_STATIC=ON -DSDL_SHARED=OFF \
						-DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_DEPLOYMENT_TARGET=$osver \
						-DCMAKE_OSX_ARCHITECTURES=arm64 -DCMAKE_OSX_SYSROOT=$target_sysroot \
						-DSDL_FRAMEWORK_OPENGLES=0 -DSDL_FRAMEWORK_UIKIT=0 -DSDL_VIDEO_DRIVER_UIKIT=0 \
						-DSDL_VIDEO_OPENGL_ES=0 -DSDL_VIDEO_RENDER_OGL_ES=0 \
						-DSDL_VIDEO_OPENGL_EGL=1 -DSDL_VIDEO_OPENGL_ES2=1 -DSDL_VIDEO_RENDER_OGL_ES2=1 \
						-DCMAKE_EXE_LINKER_FLAGS="/Users/sfence/Desktop/minetest/angle/libGLESv2.a" \
						-DCMAKE_C_FLAGS="-I/Users/sfence/Desktop/minetest/angle/include" \
						-DCMAKE_INSTALL_NAME_DIR=$dir/install/lib 2>&1 | tee "$logdir/log_config.txt"
		echo "Building SDL3..."
		make -j$(sysctl -n hw.logicalcpu) 2>&1 | tee "$logdir/log_build.txt"
		make install 2>&1 | tee "$logdir/log_install.txt"
		check_ios_file "$check_file"
		cd $dir
	fi'

	# curl
	check_file="$dir/install/lib/libcurl.a"
	if [ ! -f "$check_file" ] || [[ "$step" == *"curl"* ]]; then
		cd curl-*
		echo "Configuring curl..."
		./configure "--prefix=$dir/install" --host=arm-apple-darwin --with-secure-transport --enable-static \
				--disable-shared --disable-ftp --disable-imap --disable-pop3 --disable-smtp --disable-telnet \
				--disable-tftp --disable-ldap --disable-rtsp --disable-dict --disable-gopher --disable-smb \
				--disable-threaded-resolver --disable-pthreads --disable-verbose \
				--disable-manual --disable-unix-sockets --disable-sspi \
				--disable-tls-srp --disable-proxy --disable-alt-svc \
				--disable-hsts --disable-mqtt --disable-libcurl-option \
				--disable-cookies --disable-mime --disable-dateparse --disable-netrc \
				--disable-progress-meter --without-libpsl 2>&1 | tee "log_config.txt"
		echo "Building curl..."
		make -j$(sysctl -n hw.logicalcpu) 2>&1 | tee "log_build.txt"
		make install 2>&1 | tee "log_install.txt"
		check_ios_file "$check_file"
		cd $dir
	fi
}

