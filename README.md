## Initialize Submodules
``` bash
git submodule update --init --recursive --filter=blob:none
```

## Fetch, Patch, Build Bitcoin and Libnunchuk Dependencies
Run the following script (only once).

This script will fetch all Bitcoin dependencies, including Boost, Libevent, etc., and patch various source files.

``` bash
export IOS_SDK_VERSION=18.1.sdk # Your ios sdk version
bash ./install_dep.sh
```

## Generate Xcode project
``` bash
cd NunchukSDK
cmake -B build -G Xcode -DCMAKE_TOOLCHAIN_FILE=./ios.toolchain.cmake -DPLATFORM=OS64 -DCMAKE_WARN_DEPRECATED=FALSE
```

## Build SDK
``` bash
cd build # cd NunchukSDK/build
xcodebuild -sdk iphoneos -arch arm64 -scheme nunchukSDK -configuration Release
```

## Open with Xcode
- Open build/nunchukWalletSDK.xcodeproj
- Set the active scheme to nunchukSDK > Any iOS Device
