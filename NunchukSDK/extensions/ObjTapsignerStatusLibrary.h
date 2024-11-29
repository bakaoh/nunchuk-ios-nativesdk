//
//  ObjTapsignerStatusLibrary.h
//  nunchukSDK
//
//  Created by Hà Nguyễn Đức on 06/07/2022.
//

#ifndef ObjTapsignerStatusLibrary_h
#define ObjTapsignerStatusLibrary_h
#include <nunchuk.h>
using namespace nunchuk;

@interface ObjTapsignerStatus (Library)
- (instancetype _Nonnull)initWithTapsignerStatus:(TapsignerStatus*_Nullable)tapsignerStatus;
@end
#endif /* ObjTapsignerStatusLibrary_h */
