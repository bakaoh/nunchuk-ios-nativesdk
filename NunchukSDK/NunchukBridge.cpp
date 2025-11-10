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

std::vector<Wallet> NunchukManager::getWallet() {
    return this->nu->GetWallets();
}
void NunchukManager::updateWalletName(const char* walletId, const char* name) {
    auto wallet = this->nu->GetWallet(walletId);
    wallet.set_name(name);
    this->nu->UpdateWallet(wallet);
}

RoomWallet NunchukManager::getRoomWallet(const char* roomId) {
    return this->nuMatrix->GetRoomWallet(roomId);
}
