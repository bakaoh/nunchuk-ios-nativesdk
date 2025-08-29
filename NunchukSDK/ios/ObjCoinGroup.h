//
//  ObjCoinGroup.h
//  example-ios
//
//

#import "ObjUnspentOutput.h"

@interface ObjCoinGroup : NSObject

@property(nonatomic, strong, nonnull) NSArray<ObjUnspentOutput *> *coins;
@property(nonatomic, assign) long long timeFrom;
@property(nonatomic, assign) long long timeTo;

@end

