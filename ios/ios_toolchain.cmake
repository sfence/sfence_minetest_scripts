# Set the system name to iOS
set(CMAKE_SYSTEM_NAME iOS)

# Specify the target platform (OS, OS64, OS64COMBINED, etc.)
set(PLATFORM "OS64")

# Set the minimum iOS version
set(CMAKE_OSX_DEPLOYMENT_TARGET "${osver}")

# Specify the path to the iOS SDK
set(CMAKE_OSX_SYSROOT "${sdkroot}")

# Set the C and C++ compilers
set(CMAKE_C_COMPILER "clang")
set(CMAKE_CXX_COMPILER "clang++")

# Set the architecture (arm64 for iOS devices)
set(CMAKE_OSX_ARCHITECTURES "arm64")

# Set the find root path to include the sysroot
set(CMAKE_FIND_ROOT_PATH "${CMAKE_OSX_SYSROOT}")

# Configure the find root path mode
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

