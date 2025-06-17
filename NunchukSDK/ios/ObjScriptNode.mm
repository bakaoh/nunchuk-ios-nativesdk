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
        _type = SCRIPT_NODE_NONE;
        _subs = @[];
        _keys = @[];
        _data = [NSData data];
        _k = 0;
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
        switch (nodeType) {
            case ScriptNode::Type::NONE:
                _type = SCRIPT_NODE_NONE;
                break;
            case ScriptNode::Type::PK:
                _type = SCRIPT_NODE_PK;
                break;
            case ScriptNode::Type::OLDER:
                _type = SCRIPT_NODE_OLDER;
                break;
            case ScriptNode::Type::AFTER:
                _type = SCRIPT_NODE_AFTER;
                break;
            case ScriptNode::Type::HASH160:
                _type = SCRIPT_NODE_HASH160;
                break;
            case ScriptNode::Type::HASH256:
                _type = SCRIPT_NODE_HASH256;
                break;
            case ScriptNode::Type::RIPEMD160:
                _type = SCRIPT_NODE_RIPEMD160;
                break;
            case ScriptNode::Type::SHA256:
                _type = SCRIPT_NODE_SHA256;
                break;
            case ScriptNode::Type::AND:
                _type = SCRIPT_NODE_AND;
                break;
            case ScriptNode::Type::OR:
                _type = SCRIPT_NODE_OR;
                break;
            case ScriptNode::Type::ANDOR:
                _type = SCRIPT_NODE_ANDOR;
                break;
            case ScriptNode::Type::THRESH:
                _type = SCRIPT_NODE_THRESH;
                break;
            case ScriptNode::Type::MULTI:
                _type = SCRIPT_NODE_MULTI;
                break;
            case ScriptNode::Type::OR_TAPROOT:
                _type = SCRIPT_NODE_OR_TAPROOT;
                break;
            default:
                _type = SCRIPT_NODE_NONE;
                break;
        }
        
        // Set the keys
        std::vector<std::string> nodeKeys = node.get_keys();
        NSMutableArray *keysArray = [NSMutableArray arrayWithCapacity:nodeKeys.size()];
        for (const std::string &key : nodeKeys) {
            [keysArray addObject:[NSString stringWithUTF8String:key.c_str()]];
        }
        _keys = [keysArray copy];
        
        // Set the data
        const std::vector<unsigned char>& nodeData = node.get_data();
        _data = [NSData dataWithBytes:nodeData.data() length:nodeData.size()];
        
        // Set the threshold (k value)
        _k= node.get_k();
        
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
        case SCRIPT_NODE_NONE:
            return @"NONE";
        case SCRIPT_NODE_PK:
            return @"PK";
        case SCRIPT_NODE_OLDER:
            return @"OLDER";
        case SCRIPT_NODE_AFTER:
            return @"AFTER";
        case SCRIPT_NODE_HASH160:
            return @"HASH160";
        case SCRIPT_NODE_HASH256:
            return @"HASH256";
        case SCRIPT_NODE_RIPEMD160:
            return @"RIPEMD160";
        case SCRIPT_NODE_SHA256:
            return @"SHA256";
        case SCRIPT_NODE_AND:
            return @"AND";
        case SCRIPT_NODE_OR:
            return @"OR";
        case SCRIPT_NODE_ANDOR:
            return @"ANDOR";
        case SCRIPT_NODE_THRESH:
            return @"THRESH";
        case SCRIPT_NODE_MULTI:
            return @"MULTI";
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

- (NSData *)getData {
    return _data;
}

- (uint32_t)getK {
    return _k;
}

@end
