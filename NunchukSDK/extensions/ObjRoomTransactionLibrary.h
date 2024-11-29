//
//  ObjRoomTransactionLibrary.h
//  nunchukWalletSDK
//
//  Created by Ha Nguyen Duc on 2021/10/07.
//

#ifndef ObjRoomTransactionLibrary_h
#define ObjRoomTransactionLibrary_h

#include <nunchukmatrix.h>

using namespace nunchuk;
@interface ObjRoomTransaction (Library)
- (instancetype _Nullable)initWithRoomTransaction: (RoomTransaction *_Nullable)roomTransaction;
@end
#endif /* ObjRoomTransactionLibrary_h */
