//
//  ObjWalletLibrary.h
//  example-ios
//
//  Created by congtung private on 26/03/2021.
//

#ifndef ObjUnspentOutputLibrary_h
#define ObjUnspentOutputLibrary_h
#include <nunchuk.h>
using namespace  nunchuk;
@interface ObjUnspentOutput (Library)
- (instancetype _Nonnull)initWithUnspentOutput:(UnspentOutput *_Nullable)output;
- (UnspentOutput) convertToC;
@end
#endif /* ObjWalletLibrary_h */
