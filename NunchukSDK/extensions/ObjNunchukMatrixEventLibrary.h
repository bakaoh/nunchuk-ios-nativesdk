//
//  ObjMasterSignerLibrary.h
//  nunchukWalletSDK
//
//  Created by congtung private on 03/05/2021.
//

#ifndef ObjNunchukMatrixEventLibrary_h
#define ObjNunchukMatrixEventLibrary_h

#include <nunchukmatrix.h>
using namespace  nunchuk;

@interface ObjNunchukMatrixEvent (Library)
- (instancetype _Nonnull) initWithMatrixEvent: (NunchukMatrixEvent) event;
- (NunchukMatrixEvent) getNunchukEvent;
@end
#endif /* ObjMasterSignerLibrary_h */
