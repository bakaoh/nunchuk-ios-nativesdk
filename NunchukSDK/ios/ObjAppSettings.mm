//
//  ObjAppSettings.m
//  nunchukSDK
//
//  Created by Thai Nguyen on 10/14/21.
//

#import <Foundation/Foundation.h>
#import "ObjAppSettings.h"
#include "NunchukBridge.h"
#include <vector>

@implementation ObjAppSettings

- (instancetype)initWithAppSetting: (AppSettings *)settings {
    if (settings == NULL) { return nil;}
    ObjAppSettings *appSettings = [ObjAppSettings new];
    
    appSettings.hwiPath = [NSString stringWithUTF8String: settings->get_hwi_path().c_str()];
    appSettings.storagePath = [NSString stringWithUTF8String: settings->get_storage_path().c_str()];
    
    auto chain = settings->get_chain();
    if (chain == Chain::MAIN) {
        appSettings.chain = MAIN;
    } else if (chain == Chain::TESTNET) {
        appSettings.chain = TESTNET;
    } else if (chain == Chain::REGTEST) {
        appSettings.chain = REGTEST;
    } else if (chain == Chain::SIGNET) {
        appSettings.chain = SIGNET;
    }
    
    auto backend = settings->get_backend_type();
    if (backend == BackendType::ELECTRUM) {
        appSettings.backend = ELECTRUM;
    } else if (backend == BackendType::ELECTRUM) {
        appSettings.backend = ELECTRUM;
    }
    
    NSMutableArray *mainnetServers = [NSMutableArray new];
    for (auto &server: settings->get_mainnet_servers()) {
        [mainnetServers addObject:[NSString stringWithUTF8String: server.c_str()]];
    }
    appSettings.mainnetServers = [NSArray arrayWithArray:mainnetServers];
    
    NSMutableArray *testnetServers = [NSMutableArray new];
    for (auto &server: settings->get_testnet_servers()) {
        [testnetServers addObject:[NSString stringWithUTF8String: server.c_str()]];
    }
    appSettings.testnetServers = [NSArray arrayWithArray:testnetServers];
    
    NSMutableArray *signetServers = [NSMutableArray new];
    for (auto &server: settings->get_signet_servers()) {
        [signetServers addObject:[NSString stringWithUTF8String: server.c_str()]];
    }
    appSettings.signetServers = [NSArray arrayWithArray:signetServers];
    
    appSettings.isProxyEnabled = settings->use_proxy();
    appSettings.proxyHost = [NSString stringWithUTF8String: settings->get_proxy_host().c_str()];
    appSettings.proxyPort = settings->get_proxy_port();
    appSettings.proxyUsername = [NSString stringWithUTF8String: settings->get_proxy_username().c_str()];
    appSettings.proxyPassword = [NSString stringWithUTF8String: settings->get_proxy_password().c_str()];
    
    appSettings.certificateFile = [NSString stringWithUTF8String: settings->get_certificate_file().c_str()];
    
    appSettings.coreRPCHost = [NSString stringWithUTF8String: settings->get_corerpc_host().c_str()];
    appSettings.coreRPCPort = settings->get_corerpc_port();
    appSettings.coreRPCUsername = [NSString stringWithUTF8String: settings->get_corerpc_username().c_str()];
    appSettings.corePRCPassword = [NSString stringWithUTF8String: settings->get_corerpc_password().c_str()];
    
    return appSettings;
}

@end
