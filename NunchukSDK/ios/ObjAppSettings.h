//
//  ObjAppSettings.h
//  nunchukSDK
//
//  Created by Thai Nguyen on 10/10/21.
//

typedef enum ChainTypeEnum {
    MAIN,
    TESTNET,
    REGTEST,
    SIGNET
} ChainTypeEnum;

typedef enum BackendTypeEnum {
    ELECTRUM,
    CORERPC
} BackendTypeEnum;

@interface ObjAppSettings: NSObject
    
@property (assign, nonatomic) ChainTypeEnum chain;
@property (assign, nonatomic) BackendTypeEnum backend;
@property (strong, nonatomic, nonnull) NSArray *mainnetServers;
@property (strong, nonatomic, nullable) NSArray *testnetServers;
@property (strong, nonatomic, nullable) NSArray *signetServers;
@property (assign, nonatomic) BOOL isProxyEnabled;
@property (strong, nonatomic, nullable) NSString *proxyHost;
@property (assign, nonatomic) NSInteger proxyPort;
@property (strong, nonatomic, nullable) NSString *proxyUsername;
@property (strong, nonatomic, nullable) NSString *proxyPassword;
@property (strong, nonatomic, nullable) NSString *certificateFile;
@property (strong, nonatomic, nullable) NSString *coreRPCHost;
@property (assign, nonatomic) NSInteger coreRPCPort;
@property (strong, nonatomic, nullable) NSString *coreRPCUsername;
@property (strong, nonatomic, nullable) NSString *corePRCPassword;
@property (strong, nonatomic, nullable) NSString *hwiPath;
@property (strong, nonatomic, nullable) NSString *storagePath;

@end
