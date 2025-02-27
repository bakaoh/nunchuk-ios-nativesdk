//
//  ObjGroupConfig.h
//  nunchukSDK
//
//  Created by macbook on 11/1/25.
//

@interface ObjGroupConfig : NSObject

@property (nonatomic, assign) int total;
@property (nonatomic, assign) int remain;
@property (nonatomic, strong) NSDictionary<NSString*, NSNumber*>* addressKeyLimits;
@property (nonatomic, strong) NSArray *retentionDaysOptions;

@end
