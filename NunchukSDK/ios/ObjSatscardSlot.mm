//
//  ObjSatscardSlot.m
//  nunchukSDK
//
//  Created by Hà Nguyễn Đức on 31/07/2022.
//

#import "ObjSatscardSlot.h"
#import <extensions/ObjSatscardSlotLibrary.h>
#import <extensions/ObjUnspentOutputLibrary.h>

@implementation ObjSatscardSlot
- (instancetype)initWithSatscardSlot:(SatscardSlot *)satscardSlot {
    ObjSatscardSlot *slot = [[ObjSatscardSlot alloc] init];
    slot.index = satscardSlot->get_index();
    switch (satscardSlot->get_status()) {
        case nunchuk::SatscardSlot::Status::UNUSED:
            slot.status = UNUSED;
            break;
        case nunchuk::SatscardSlot::Status::SEALED:
            slot.status = SEALED;
            break;
        case nunchuk::SatscardSlot::Status::UNSEALED:
            slot.status = UNSEALED;
            break;
    }
    slot.address = [NSString stringWithUTF8String:satscardSlot->get_address().c_str()];
    int64_t balance = satscardSlot->get_balance();
    slot.balance = balance > 0 ? balance : 0;
    slot.isConfirmed = satscardSlot->is_confirmed();
    NSMutableArray *arrayUtxos = [NSMutableArray new];
    auto utxos = satscardSlot->get_utxos();
    for (auto& utxo: utxos) {
        [arrayUtxos addObject:[[ObjUnspentOutput alloc] initWithUnspentOutput:&utxo]];
    }
    slot.utxos = arrayUtxos;
    
    slot.privateKey = [self convertFromVector:satscardSlot->get_privkey()];
    slot.publicKey = [self convertFromVector:satscardSlot->get_pubkey()];
    slot.chainCode = [self convertFromVector:satscardSlot->get_chain_code()];
    slot.masterPrivateKey = [self convertFromVector:satscardSlot->get_master_privkey()];
    return slot;
}

- (SatscardSlot)toSatscardSlot {
    auto slot = SatscardSlot();
    slot.set_index(self.index);
    switch (self.status) {
        case UNSEALED:
            slot.set_status(nunchuk::SatscardSlot::Status::UNSEALED);
            break;
        case SEALED:
            slot.set_status(nunchuk::SatscardSlot::Status::SEALED);
            break;
        case UNUSED:
            slot.set_status(nunchuk::SatscardSlot::Status::UNUSED);
            break;
    }
    slot.set_address([self.address UTF8String]);
    slot.set_balance(self.balance);
    slot.set_confirmed(self.isConfirmed);
    slot.set_privkey([self convertDataToVector:self.privateKey]);
    slot.set_pubkey([self convertDataToVector:self.publicKey]);
    slot.set_chain_code([self convertDataToVector:self.chainCode]);
    slot.set_master_privkey([self convertDataToVector:self.masterPrivateKey]);
    std::vector<UnspentOutput> utxos;
    for (ObjUnspentOutput *utxo in self.utxos) {
        utxos.push_back([utxo convertToC]);
    }
    slot.set_utxos(utxos);
    return slot;
}

- (NSData *)convertFromVector:(const std::vector<unsigned char>&)vector {
    return [[NSData alloc] initWithBytes:vector.data() length:sizeof(unsigned char) * vector.size()];
}

- (std::vector<unsigned char>)convertDataToVector:(NSData *)input {
    const unsigned char *dataArray = (unsigned char *)input.bytes;
    const size_t count = input.length / sizeof(unsigned char);
    std::vector<unsigned char> responseBytes(dataArray, dataArray + count);
    return responseBytes;
}
@end
