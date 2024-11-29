//
//  ObjMasterSignerLibrary.h
//  nunchukWalletSDK
//
//  Created by congtung private on 03/05/2021.
//

#ifndef ObjMasterSignerLibrary_h
#define ObjMasterSignerLibrary_h

#include <nunchuk.h>
using namespace  nunchuk;

@interface ObjMasterSigner (Library)
- (instancetype _Nonnull) initWithMasterSigner: (MasterSigner*_Nullable) masterSigner;
@end
#endif /* ObjMasterSignerLibrary_h */
