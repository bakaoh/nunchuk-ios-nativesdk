cmake_minimum_required (VERSION 3.2)

project (nunchukWalletSDK)
set(CMAKE_XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET "13.0")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++20")

set(IOS)

# Source files
set(SOURCES
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
)

# Headers
set(HEADERS
  NunchukBridge.h
  ios/NunchukImp.h
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
)

# Boost
include_directories("${PROJECT_SOURCE_DIR}/libnunchuk/contrib/bitcoin/depends/ios/include")

# Library
if(BUILD_SHARED)
  add_library (nunchukSDK SHARED ${SOURCES} ${HEADERS})
  message(STATUS "Building shared version...")
else()
  add_library (nunchukSDK STATIC ${SOURCES} ${HEADERS})
  message(STATUS "Building static version...")
endif()

set(BUILD_CLI FALSE)
set(CMAKE_CXX_LINK_PIE_SUPPORTED TRUE)
add_subdirectory(libnunchuk)
target_link_libraries(nunchukSDK PUBLIC nunchuk)

set_target_properties(nunchukSDK PROPERTIES
    FRAMEWORK TRUE
    MACOSX_FRAMEWORK_INFO_PLIST "${PROJECT_SOURCE_DIR}/Info.plist"
    XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "com.nunchuk.nunchuksdk"
    XCODE_ATTRIBUTE_CURRENT_PROJECT_VERSION "0.1"
    XCODE_ATTRIBUTE_DEVELOPMENT_TEAM ""
    XCODE_ATTRIBUTE_DEFINES_MODULE "YES"
    XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_ARC "YES"
)
