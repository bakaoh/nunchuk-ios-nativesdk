#pragma once 
#include <nunchuk.h>
#include <nunchukmatrix.h>
using namespace  nunchuk;

class NunchukManager {
public:
    std::unique_ptr<Nunchuk> nu;
    std::unique_ptr<NunchukMatrix> nuMatrix;
    std::vector<Wallet> wallets;
    std::string path;
    void setupNunChukForAccount(const char* account, const char* passphrase, const char* deviceId, SendEventFunc sendFunc, AppSettings settings);
    std::vector<Device> getDevices();
    void updateWalletName(const char* walletId, const char* name);
    void createNewMasterSigner(const char* name, Device& device);
    Wallet createMultisigWallet(const char* name, int m, std::vector<SingleSigner> signers, const char* desc, const char* type, const char* addressType);
    std::string draftMultisigWallet(const char* name, int m, std::vector<SingleSigner> signers, const char* desc, const char* type, const char* addressType);
    bool exportWallet(const char* walletId, const char* filePath, const char* format);
    void importConfig(std::string path);
    MasterSigner createSoftwareSigner(std::string& raw_name, std::string& mnemonic, std::string& passphrase, std::function<bool(int)> progress);
    std::vector<std::string> exportCobo(const char* walletId);
    std::vector<SingleSigner> getSigners();
    std::vector<Wallet> getWallet();
    std::string generateMnemonic();
    RoomWallet getRoomWallet(const char* roomId);
};
