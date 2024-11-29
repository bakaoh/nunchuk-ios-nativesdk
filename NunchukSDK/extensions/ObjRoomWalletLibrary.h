//
//  ObjRoomWalletLibrary.h
//  nunchukSDK
//
//  Created by Ha Nguyen Duc on 2021/08/31.
//

#ifndef ObjRoomWalletLibrary_h
#define ObjRoomWalletLibrary_h

#include <nunchukmatrix.h>

using namespace nunchuk;
@interface ObjRoomWallet (Library)
- (instancetype _Nullable)initWithRoomWallet: (RoomWallet *_Nullable) roomWallet;
@end
#endif /* ObjRoomWalletLibrary_h */
