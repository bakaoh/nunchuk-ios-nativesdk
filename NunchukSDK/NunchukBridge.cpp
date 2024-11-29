#include "NunchukBridge.h"
#include <utils/loguru.hpp>

#include <vector>
#include <iostream>
#include <iomanip>
#include <regex>
#include <nunchuk.h>
#include <nunchukmatrix.h>
#include <nunchukmatriximpl.h>

#include <utils.h>

using namespace  nunchuk;

void NunchukManager::setupNunChukForAccount(const char* account, const char* passphrase, const char* deviceId, SendEventFunc sendEvent, AppSettings settings) {
    this->nu = MakeNunchukForAccount(settings, passphrase, account);
    this->nuMatrix = MakeNunchukMatrixForAccount(settings, passphrase, account, deviceId, sendEvent);
}

void NunchukManager::importConfig(std::string path) {
    auto wallet = this->nu->ImportWalletConfigFile(path);
}
std::vector<Device> NunchukManager::getDevices() {
    return this->nu->GetDevices();
}

std::string NunchukManager::generateMnemonic() {
    return Utils::GenerateMnemonic();
}

void NunchukManager::createNewMasterSigner(const char* name, Device& device) {
    auto master_signer = this->nu->CreateMasterSigner(
                                                      name, device, [](int percent) {
            // libnunchuk caches xpubs when adding a new master signer, so this method will take some time
            // Use this callback to check on the progress
            return true;
        });
}

std::vector<SingleSigner> NunchukManager::getSigners() {
    return this->nu->GetRemoteSigners();
}

std::vector<std::string> NunchukManager::exportCobo(const char* walletId) {
    return this->nu->ExportCoboWallet(walletId);
}
std::string NunchukManager::draftMultisigWallet(const char* name, int m, std::vector<SingleSigner> signers, const char* desc, const char* type, const char* addressType) {
    AddressType address_type = AddressType::ANY;
    if (strcmp(addressType, "NATIVE_SEGWIT") == 0) {
        address_type = AddressType::NATIVE_SEGWIT;
    }
        
    if (strcmp(addressType, "LEGACY") == 0) {
        address_type = AddressType::LEGACY;
    }
    
    if (strcmp(addressType, "NESTED_SEGWIT") == 0) {
        address_type = AddressType::NESTED_SEGWIT;
    }
    
    if (strcmp(addressType, "TAPROOT") == 0) {
        address_type = AddressType::TAPROOT;
    }
    
    WalletType wallet_type = WalletType::MULTI_SIG;
    
    if (strcmp(type, "SINGLE_SIG") == 0) {
        wallet_type = WalletType::SINGLE_SIG;
    }
    
    if (strcmp(type, "ESCROW") == 0) {
        wallet_type = WalletType::ESCROW;
    }
    // Create a multisig (2/2) wallet
    return this->nu->DraftWallet(name, m, signers.size(),
                                         signers, address_type, wallet_type == WalletType::ESCROW);
}
std::vector<Wallet> NunchukManager::getWallet() {
    return this->nu->GetWallets();
}
void NunchukManager::updateWalletName(const char* walletId, const char* name) {
    auto wallet = this->nu->GetWallet(walletId);
    wallet.set_name(name);
    this->nu->UpdateWallet(wallet);
}
bool NunchukManager::exportWallet(const char* walletId, const char* filePath, const char* format) {
    ExportFormat eFormat = ExportFormat::COLDCARD;
    if (strcmp(format, "COBO") == 0) {
        eFormat = ExportFormat::COBO;
    }
    if (strcmp(format, "BSMS") == 0) {
        eFormat = ExportFormat::BSMS;
    }
    if (strcmp(format, "DB") == 0) {
        eFormat = ExportFormat::DB;
    }
    return this->nu->ExportWallet(walletId, filePath, eFormat);
}
RoomWallet NunchukManager::getRoomWallet(const char* roomId) {
    return this->nuMatrix->GetRoomWallet(roomId);
}
