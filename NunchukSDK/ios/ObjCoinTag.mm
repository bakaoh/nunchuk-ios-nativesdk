//
//  ObjCoinTag.m
//  nunchukSDK
//
//

#import <Foundation/Foundation.h>
#import "ObjCoinTag.h"
#import <extensions/ObjCoinTag+Extension.h>
#include <nunchuk.h>

@implementation ObjCoinTag {
}

- (instancetype)initWithCoinTag:(CoinTag *)tag {
    return [[ObjCoinTag alloc] initWithTagId:tag->get_id()
                                        name:[NSString stringWithUTF8String:tag->get_name().c_str()]
                                       color:[NSString stringWithUTF8String:tag->get_color().c_str()]];
}

- (instancetype _Nullable)initWithTagId:(int)tagId name:(NSString *_Nonnull)name color:(NSString *_Nonnull)color {
    ObjCoinTag *tag = [[ObjCoinTag alloc] init];
    tag.tagId = tagId;
    tag.name = name;
    tag.color = color;
    return tag;
}

@end

