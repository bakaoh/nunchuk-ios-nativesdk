//
//  ObjDraftRolloverTransaction.m
//  nunchukSDK
//
//  Created by congtung private on 02/03/2021.
//

#import <Foundation/Foundation.h>
#import "ObjDraftRolloverTransaction.h"

@implementation ObjDraftRolloverTransaction {
}

- (instancetype _Nullable)initWithTransaction:(ObjTransaction *_Nonnull)transaction tagIds:(NSArray *_Nonnull)tagIds collectionIds:(NSArray *_Nonnull)collectionIds {
    ObjDraftRolloverTransaction *tx = [ObjDraftRolloverTransaction new];
    tx.transaction = transaction;
    tx.tagIds = tagIds;
    tx.collectionIds = collectionIds;
    return tx;
}

@end

