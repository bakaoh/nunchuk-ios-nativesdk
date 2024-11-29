//
//  ObjTransactionLibrary.h
//  nunchukWalletSDK
//
//  Created by congtung private on 13/05/2021.
//

#ifndef ObjTransactionLibrary_h
#define ObjTransactionLibrary_h
#include <nunchuk.h>
using namespace  nunchuk;

@interface ObjTransaction (Library)
- (instancetype _Nonnull ) initWithTransaction: (Transaction*_Nullable) transaction;
+ (NSString *_Nonnull)transactionStatusFrom:(TransactionStatus)status;
@end

#endif /* ObjTransactionLibrary_h */
