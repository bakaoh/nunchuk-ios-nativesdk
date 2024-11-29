//
//  ObjTapCardResult.h
//  nunchukSDK
//
//  Created by Hà Nguyễn Đức on 15/08/2022.
//

#import <Foundation/Foundation.h>
#import "ObjSatscardStatus.h"
#import "ObjTapsignerStatus.h"

@interface ObjTapCardResult : NSObject
@property(nonatomic, strong, nullable) ObjSatscardStatus *satscardStatus;
@property(nonatomic, strong, nullable) ObjTapsignerStatus *tapsignerStatus;
@property(nonatomic, assign) BOOL isTapsigner;
@property(nonatomic, assign) BOOL isPortal;
@end

