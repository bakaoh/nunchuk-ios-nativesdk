//
//  ObjAnalyzeQRResult.h
//  nunchukSDK
//
//  Created by Chinh IT. Phung Van on 23/02/2023.
//

@interface ObjAnalyzeQRResult: NSObject
@property(nonatomic) BOOL isSuccess;
@property(nonatomic) BOOL isFailure;
@property(nonatomic) BOOL isComplete;
@property(nonatomic, assign) double estimatedPercentComplete;
@property(nonatomic, assign) NSInteger processedPartsCount;
@property(nonatomic, assign) NSInteger expectedPartCount;

@end

