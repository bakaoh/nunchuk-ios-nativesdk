//
//  ObjCoinCollection.m
//  nunchukSDK
//
//  Created by congtung private on 02/03/2021.
//

#import <Foundation/Foundation.h>
#import "ObjCoinCollection.h"
#import <extensions/ObjCoinCollection+Extension.h>

@implementation ObjCoinCollection {
}

- (instancetype)initWithCoinCollection:(CoinCollection *)collection {
    int collectionId = collection->get_id();
    NSString *name = [NSString stringWithUTF8String:collection->get_name().c_str()];
    bool autoLockEnabled = collection->is_auto_lock();
    NSMutableArray *addCoinsWithTagIds = [NSMutableArray new];
    BOOL addCoinsWithoutTagEnabled = NO;
    auto tagIds = collection->get_add_coins_with_tag();
    for (auto tagId: tagIds) {
        if (tagId == -1) {
            addCoinsWithoutTagEnabled = YES;
        } else {
            [addCoinsWithTagIds addObject:[NSNumber numberWithInt:tagId]];
        }
    }
    return [[ObjCoinCollection alloc] initWithCollectionId:collectionId name:name autoLockEnabled:autoLockEnabled addCoinsWithTagIds:addCoinsWithTagIds addCoinsWithoutTagEnabled: addCoinsWithoutTagEnabled];
}

- (instancetype)initWithCollectionId:(int)collectionId name:(NSString *)name {
    ObjCoinCollection *collection = [[ObjCoinCollection alloc] init];
    collection.collectionId = collectionId;
    collection.name = name;
    collection.autoLockEnabled = NO;
    collection.addCoinsWithTagIds = [NSArray new];
    collection.addCoinsWithoutTagEnabled = NO;
    return collection;
}

- (instancetype)initWithCollectionId:(int)collectionId name:(NSString *)name autoLockEnabled:(bool)autoLockEnabled addCoinsWithTagIds:(NSArray *)addCoinsWithTagIds addCoinsWithoutTagEnabled:(BOOL)addCoinsWithoutTagEnabled {
    ObjCoinCollection *collection = [[ObjCoinCollection alloc] init];
    collection.collectionId = collectionId;
    collection.name = name;
    collection.autoLockEnabled = autoLockEnabled;
    collection.addCoinsWithTagIds = addCoinsWithTagIds;
    collection.addCoinsWithoutTagEnabled = addCoinsWithoutTagEnabled;
    return collection;
}

@end

