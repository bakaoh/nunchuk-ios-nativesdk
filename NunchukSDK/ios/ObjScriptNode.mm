//
//  ObjScriptNode.mm
//  nunchukSDK
//
//  Created on 10/3/2023.
//

#import "ObjScriptNode.h"
#include <nunchuk.h>

using namespace nunchuk;

@interface ObjScriptNode()
@end

@implementation ObjScriptNode

- (instancetype)init {
    self = [super init];
    if (self) {
        _id = @[];
        _type = SCRIPT_NODE_UNKNOWN;
        _subs = @[];
        _keys = @[];
        _threshold = 0;
        _lockTime = 0;
    }
    return self;
}

- (void)dealloc {
}

#pragma mark - Extension Methods

- (instancetype _Nullable)initWithScriptNode:(const ScriptNode &)node {
    self = [super init];
    if (self) {
        // Extract data without storing the ScriptNode object itself
        // Set the ID
        const std::vector<size_t>& nodeId = node.get_id();
        NSMutableArray *idArray = [NSMutableArray arrayWithCapacity:nodeId.size()];
        for (size_t idValue : nodeId) {
            [idArray addObject:[NSString stringWithFormat:@"%zu", idValue]];
        }
        _id = [idArray copy];
        
        // Set the type
        auto nodeType = node.get_type();
        if (nodeType == ScriptNode::Type::PK) {
            _type = SCRIPT_NODE_PK;
        } else if (nodeType == ScriptNode::Type::MULTI) {
            _type = SCRIPT_NODE_MULTI;
        } else if (nodeType == ScriptNode::Type::AND) {
            _type = SCRIPT_NODE_AND;
        } else if (nodeType == ScriptNode::Type::OR) {
            _type = SCRIPT_NODE_OR;
        } else if (nodeType == ScriptNode::Type::THRESH) {
            _type = SCRIPT_NODE_THRESH;
        } else if (nodeType == ScriptNode::Type::OLDER || 
                  nodeType == ScriptNode::Type::AFTER) {
            _type = SCRIPT_NODE_TIMEBASED;
        } else {
            _type = SCRIPT_NODE_UNKNOWN;
        }
        
        // Set the keys
        std::vector<std::string> nodeKeys = node.get_keys();
        NSMutableArray *keysArray = [NSMutableArray arrayWithCapacity:nodeKeys.size()];
        for (const std::string &key : nodeKeys) {
            [keysArray addObject:[NSString stringWithUTF8String:key.c_str()]];
        }
        _keys = [keysArray copy];
        
        // Set the threshold
        _threshold = (int)node.get_k();
        
        // Set default lockTime
        _lockTime = 0;
        
        // Process sub-nodes recursively, accessing C++ objects only by reference
        const std::vector<ScriptNode>& nodeSubs = node.get_subs();
        NSMutableArray *subsArray = [NSMutableArray arrayWithCapacity:nodeSubs.size()];
        
        // Process each sub-node by reference
        for (const ScriptNode& subNode : nodeSubs) {
            ObjScriptNode *subObjNode = [[ObjScriptNode alloc] initWithScriptNode:subNode];
            if (subObjNode) {
                [subsArray addObject:subObjNode];
            }
        }
        
        _subs = [subsArray copy];
    }
    return self;
}

#pragma mark - Public Methods

+ (NSString *)typeToString:(ScriptNodeType)type {
    switch (type) {
        case SCRIPT_NODE_PK:
            return @"PK";
        case SCRIPT_NODE_MULTI:
            return @"MULTI";
        case SCRIPT_NODE_AND:
            return @"AND";
        case SCRIPT_NODE_OR:
            return @"OR";
        case SCRIPT_NODE_THRESH:
            return @"THRESH";
        case SCRIPT_NODE_TIMEBASED:
            return @"TIMEBASED";
        default:
            return @"UNKNOWN";
    }
}

- (ScriptNodeType)getType {
    return _type;
}

- (NSArray<NSString *> *)getId {
    return _id;
}

- (NSArray<ObjScriptNode *> *)getSubs {
    return _subs;
}

- (NSArray<NSString *> *)getKeys {
    return _keys;
}

- (int)getThreshold {
    return _threshold;
}

- (int)getLockTime {
    return _lockTime;
}

@end
