//
//  ObjSatscardSlotLibrary.h
//  nunchukWalletSDK
//
//  Created by Hà Nguyễn Đức on 31/07/2022.
//

#ifndef ObjSatscardSlotLibrary_h
#define ObjSatscardSlotLibrary_h
#include <nunchuk.h>
using namespace nunchuk;

@interface ObjSatscardSlot (Library)
- (instancetype _Nonnull)initWithSatscardSlot:(SatscardSlot*_Nonnull)satscardSlot;
- (SatscardSlot)toSatscardSlot;
@end
#endif /* ObjSatscardSlotLibrary_h */
