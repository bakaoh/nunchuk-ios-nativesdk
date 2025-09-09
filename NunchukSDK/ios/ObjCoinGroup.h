//
//  ObjCoinGroup.h
//  example-ios
//
//

#import "ObjUnspentOutput.h"

@interface ObjCoinGroup : NSObject

@property(nonatomic, strong, nonnull) NSArray<ObjUnspentOutput *> *coins;
@property(nonatomic, assign) UInt64 timeFrom;
@property(nonatomic, assign) UInt64 timeTo;

@end

