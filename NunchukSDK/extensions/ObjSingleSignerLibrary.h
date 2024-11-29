//
//  ObjSingleSignerLibrary.h
//  example-ios
//
//  Created by congtung private on 26/03/2021.
//

#ifndef ObjSingleSignerLibrary_h
#define ObjSingleSignerLibrary_h
#include <nunchuk.h>
using namespace  nunchuk;

@interface ObjSingleSigner (Library)
- (instancetype _Nonnull ) initWithSigner: (SingleSigner*_Nullable)signer;
@end
#endif /* ObjWalletLibrary_h */
