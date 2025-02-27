cmake_minimum_required (VERSION 3.2)

project (nunchukWalletSDK)
set(CMAKE_XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET "13.0")
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(IOS)

# Source files
set(SDK_SOURCES
  NunchukBridge.cpp
  ios/NunchukImp.mm
  ios/ObjSingleSigner.mm
  ios/ObjWallet.mm
  ios/ObjMasterSigner.mm
  ios/ObjDevice.mm
  ios/StringIntPair.m
  ios/ObjTransaction.mm
  ios/ObjUnspentOutput.mm
  ios/ObjNunchukMatrixEvent.mm
  ios/ObjRoomWallet.mm
  ios/ObjRoomTransaction.mm
  ios/ObjAppSettings.mm
  ios/NunchukLibUlti.mm
  ios/ObjPrimaryKey.mm
  ios/ObjTapsignerStatus.mm
  ios/ObjSatscardStatus.mm
  ios/ObjSatscardSlot.mm
  ios/ObjTapCardResult.mm
  ios/ObjBtcUri.mm
  ios/ObjAssistedWallet.m
  ios/ObjKeyInfo.m
  ios/ObjTapSignerKeyInfo.m
  ios/ObjRemoteTransaction.m
  ios/ObjAnalyzeQRResult.m
  ios/ObjCoinTag.mm
  ios/ObjCoinCollection.mm
  ios/ObjSignMessage.m
  ios/ObjDraftTransaction.m
  ios/ObjWalletData.m
  ios/ObjDraftRolloverTransaction.m
  ios/ObjBSMSData.m
  ios/ObjKeySetStatus.mm
  ios/ObjGroupMessage.mm
  ios/ObjGroupConfig.mm
  ios/ObjGroupWalletConfig.mm
  ios/ObjGroupSandbox.mm
)

set(PUBLIC_SDK_HEADERS
  ios/NunchukImp.h
  ios/NunchukAll.h
  ios/ObjSingleSigner.h
  ios/ObjNunchukMatrixEvent.h
  ios/ObjMasterSigner.h
  ios/ObjTransaction.h
  ios/StringIntPair.h
  ios/ObjUnspentOutput.h
  ios/ObjWallet.h
  ios/ObjDevice.h
  ios/ObjRoomWallet.h
  ios/ObjRoomTransaction.h 
  ios/ObjAppSettings.h
  ios/NunchukLibUlti.h
  ios/ObjPrimaryKey.h
  ios/ObjTapsignerStatus.h
  ios/ObjSatscardStatus.h
  ios/ObjSatscardSlot.h
  ios/ObjTapCardResult.h
  ios/ObjBtcUri.h
  ios/ObjAssistedWallet.h
  ios/ObjKeyInfo.h
  ios/ObjTapSignerKeyInfo.h
  ios/ObjRemoteTransaction.h
  ios/ObjAnalyzeQRResult.h
  ios/ObjCoinTag.h
  ios/ObjCoinCollection.h
  ios/ObjSignMessage.h
  ios/ObjDraftTransaction.h
  ios/ObjWalletData.h
  ios/ObjDraftRolloverTransaction.h
  ios/ObjBSMSData.h
  ios/ObjKeySetStatus.h
  ios/ObjGroupMessage.h
  ios/ObjGroupConfig.h
  ios/ObjGroupWalletConfig.h
  ios/ObjGroupSandbox.h
)

# Headers
set(SDK_HEADERS
  NunchukBridge.h
  extensions/ObjWalletLibrary.h
  extensions/ObjSingleSignerLibrary.h
  extensions/ObjMasterSignerLibrary.h
  extensions/ObjTransactionLibrary.h
  extensions/ObjUnspentOutputLibrary.h
  extensions/ObjNunchukMatrixEventLibrary.h
  extensions/ObjRoomWalletLibrary.h
  extensions/ObjRoomTransactionLibrary.h
  extensions/ObjAppSettings+Extension.h
  extensions/ObjPrimaryKey+Extension.h
  extensions/ObjTapsignerStatusLibrary.h
  extensions/ObjSatscardStatus+Extension.h
  extensions/ObjSatscardSlotLibrary.h
  extensions/ObjBtcUri+Extension.h
  extensions/ObjCoinTag+Extension.h
  extensions/ObjCoinCollection+Extension.h
  extensions/ObjKeySetStatus+Extension.h
  extensions/ObjGroupMessage+Extension.h
  extensions/ObjGroupWalletConfig+Extension.h
  extensions/ObjGroupSandbox+Extension.h
  ${PUBLIC_SDK_HEADERS}
)

# Library
if(BUILD_SHARED)
  add_library (nunchukSDK SHARED ${SDK_SOURCES} ${SDK_HEADERS})
  message(STATUS "Building shared version...")
else()
  add_library (nunchukSDK STATIC ${SDK_SOURCES} ${SDK_HEADERS})
  message(STATUS "Building static version...")
endif()

set(ENABLE_HARDENING OFF)
add_subdirectory(libnunchuk)
target_link_libraries(nunchukSDK PUBLIC nunchuk)
add_dependencies(nunchukSDK event_core_static event_extra_static event_pthreads_static)
target_include_directories(nunchukSDK PUBLIC ${PROJECT_SOURCE_DIR})

set(SDK_STATIC_DEPENDENCIES "\
  $<TARGET_FILE:trezor-crypto>
  $<TARGET_FILE:ur-2>
  $<TARGET_FILE:nunchuk>
  $<TARGET_FILE:sqlcipher>
  $<TARGET_FILE:crc32c>
  $<TARGET_FILE:crc32c_arm64>
  $<TARGET_FILE:leveldb>
  $<TARGET_FILE:minisketch>
  $<TARGET_FILE:bitcoin_consensus>
  $<TARGET_FILE:bitcoin_common>
  $<TARGET_FILE:bitcoin_node>
  $<TARGET_FILE:bitcoin_crypto>
  $<TARGET_FILE:bitcoin_crypto_arm_shani>
  $<TARGET_FILE:univalue>
  $<TARGET_FILE:bitcoin_util>
  $<TARGET_FILE:secp256k1>
  $<TARGET_FILE:bitcoin_wallet>
  $<TARGET_FILE:embedded>
  $<TARGET_FILE:ur>
  $<TARGET_FILE:tap-protocol>
  $<TARGET_FILE:bitcoin-core>
  $<TARGET_FILE:bbqr-cpp>
  $<TARGET_FILE:zlibstatic>
  ${PROJECT_SOURCE_DIR}/libnunchuk/contrib/openssl/${PLATFORM}/lib/libcrypto.a
  ${PROJECT_SOURCE_DIR}/libnunchuk/contrib/openssl/${PLATFORM}/lib/libssl.a
  $<TARGET_FILE:event_core_static>
  $<TARGET_FILE:event_extra_static>
  $<TARGET_FILE:event_pthreads_static>
  "
)

set_target_properties(nunchukSDK PROPERTIES
    FRAMEWORK TRUE
    PUBLIC_HEADER "${PUBLIC_SDK_HEADERS}"
    XCODE_GENERATE_SCHEME TRUE
    MACOSX_FRAMEWORK_INFO_PLIST "${PROJECT_SOURCE_DIR}/Info.plist"
    XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "com.nunchuk.nunchuksdk"
    XCODE_ATTRIBUTE_CURRENT_PROJECT_VERSION "0.1"
    XCODE_ATTRIBUTE_DEVELOPMENT_TEAM ""
    XCODE_ATTRIBUTE_DEFINES_MODULE "YES"
    XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_ARC "YES"
    XCODE_ATTRIBUTE_BUILD_LIBRARY_FOR_DISTRIBUTION "YES"
    XCODE_ATTRIBUTE_GENERATE_MASTER_OBJECT_FILE "YES"
    #XCODE_ATTRIBUTE_INSTALL_PATH "@rpath"
    XCODE_ATTRIBUTE_PRELINK_LIBS ${SDK_STATIC_DEPENDENCIES}
)
