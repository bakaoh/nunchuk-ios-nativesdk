#!/bin/bash

set -e

export IOS_SDK_PATH=$(xcrun --sdk iphoneos --show-sdk-path) 
export SIMULATOR_SDK_PATH=$(xcrun --sdk iphonesimulator --show-sdk-path)
export XCODE_PATH=$(xcode-select --print-path)

echo "Using IOS_SDK_PATH=${IOS_SDK_PATH}"
echo "Using XCODE_PATH=${XCODE_PATH}"

if [ -z "$IOS_SDK_VERSION" ]; then
  echo "export the IOS_SDK_VERSION environment variable"
  echo "eg. export IOS_SDK_VERSION=18.1.sdk"
  exit 1
fi

num_jobs=4
if [ -f /proc/cpuinfo ]; then
   num_jobs=$(grep ^processor /proc/cpuinfo | wc -l)
fi

patchFile() {
  patch=$1
  dest=$2
  echo "Patching file $dest using patch $patch"
  cmp -s $patch $dest || cp $patch $dest
}

applyBitcoinDependsPatches() {
  echo "Patching bitcoin dependencies"
  patchFile ./patches/libevent.mk ./NunchukSDK/libnunchuk/contrib/bitcoin/depends/packages/libevent.mk
  patchFile ./patches/boost.mk ./NunchukSDK/libnunchuk/contrib/bitcoin/depends/packages/boost.mk
  patchFile ./patches/ios.mk ./NunchukSDK/libnunchuk/contrib/bitcoin/depends/hosts/ios.mk
  patchFile ./patches/Makefile ./NunchukSDK/libnunchuk/contrib/bitcoin/depends/Makefile
  patchFile ./patches/ProcessConfigurations.cmake ./NunchukSDK/libnunchuk/contrib/bitcoin/cmake/module/ProcessConfigurations.cmake
  patchFile ./patches/AddBoostIfNeeded.cmake ./NunchukSDK/libnunchuk/contrib/bitcoin/cmake/module/AddBoostIfNeeded.cmake
  patchFile ./patches/FindLibevent.cmake ./NunchukSDK/libnunchuk/contrib/bitcoin/cmake/module/FindLibevent.cmake
}

installBitcoinDeps() {
  target=$1

  echo "-------------------------------------------------------------------------------"
  echo "                     Installing deps for $target                          "
  echo "-------------------------------------------------------------------------------"
  make HOST=$target NO_QT=1 NO_ZMQ=1 NO_QR=1 NO_UPNP=1 NO_SQLITE=1 NO_BDB=1 NO_USDT=1 -j $num_jobs
}

applyBitcoinDependsPatches
pushd ./NunchukSDK/libnunchuk/contrib/bitcoin/depends || exit
installBitcoinDeps ios
popd || exit

installOpenSSL() {
  target=$1
  sdk=$2
  platform=$3
  echo "-------------------------------------------------------------------------------"
  echo "                    Installing OpenSSL for $abi $target                        "
  echo "-------------------------------------------------------------------------------"

  export CROSS_TOP="${sdk%/SDKs/*}"
  export CROSS_SDK="${platform}${IOS_SDK_VERSION}"
  export BUILD_TOOL="${CROSS_TOP}/usr/bin"
  export SDK_PATH=$sdk

  echo "Building for: $platform"
  echo "Using SDK_PATH: $SDK_PATH"
  echo "Using CROSS_TOP: $CROSS_TOP"
  echo "Using CROSS_SDK: $CROSS_SDK"
  echo "Using BUILD_TOOL: $BUILD_TOOL"

  ./Configure iphoneos-cross no-shared no-dso no-hw no-engine -mios-version-min=13.0 --prefix="$PWD/$target"
  make clean
  make -j $num_jobs
  make install_dev
}

pushd ./NunchukSDK/libnunchuk/contrib/openssl || exit
installOpenSSL OS64 $IOS_SDK_PATH iPhoneOS 
#installOpenSSL SIMULATOR64 $SIMULATOR_SDK_PATH iPhoneSimulator
popd || exit

patchBitcoin() {
  echo "Patching bitcoin source"
  patchFile ./patches/netif.cpp ./NunchukSDK/libnunchuk/contrib/bitcoin/src/common/netif.cpp
}

patchZlib() {
  echo "Patching zlib"
  patchFile ./patches/gzwrite.c ./NunchukSDK/libnunchuk/contrib/bbqr-cpp/contrib/zlib/gzwrite.c
  patchFile ./patches/gzread.c ./NunchukSDK/libnunchuk/contrib/bbqr-cpp/contrib/zlib/gzread.c
  patchFile ./patches/gzlib.c ./NunchukSDK/libnunchuk/contrib/bbqr-cpp/contrib/zlib/gzlib.c
}

patchBitcoin
patchZlib

echo "done"
