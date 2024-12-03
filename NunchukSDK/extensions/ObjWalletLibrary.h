//
//  ObjWalletLibrary.h
//  example-ios
//
//  Created by congtung private on 26/03/2021.
//

#ifndef ObjWalletLibrary_h
#define ObjWalletLibrary_h
#include <nunchuk.h>
using namespace  nunchuk;
@interface ObjWallet (Library)
- (instancetype _Nonnull )initWithWallet:(Wallet *_Nullable)wallet ;
@end
#endif /* ObjWalletLibrary_h */
