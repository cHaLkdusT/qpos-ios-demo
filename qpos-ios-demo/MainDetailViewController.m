//
//  MainDetailViewController.m
//  qpos-ios-demo
//
//  Created by Robin on 11/19/13.
//  Copyright (c) 2013 Robin. All rights reserved.
//
#import <MediaPlayer/MPMusicPlayerController.h>
#import "MainDetailViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import "Util.h"
#import "SGTLVDecode.h"

@interface MainDetailViewController ()
- (void)configureView;
@property (nonatomic,copy)NSString *terminalTime;
@property (weak, nonatomic) IBOutlet UILabel *updateProgressLab;
@property (nonatomic,copy)NSString *currencyCode;
@property (weak, nonatomic) IBOutlet UILabel *labSDK;
@property (weak, nonatomic) IBOutlet UIButton *btnStart;
@property (weak, nonatomic) IBOutlet UIButton *btnGetPosId;
@property (weak, nonatomic) IBOutlet UIButton *btnGetPosInfo;
@property (weak, nonatomic) IBOutlet UIButton *btnDisconnect;
@property (weak, nonatomic) IBOutlet UIButton *btnResetPos;
@property (weak, nonatomic) IBOutlet UIButton *btnIsCardExist;
@property (nonatomic,strong) NSData* apduStr;
@property (weak, nonatomic) IBOutlet UIButton *updateEMVapp1;
@property (weak, nonatomic) IBOutlet UIButton *updateEMVapp2;
@property (weak, nonatomic) IBOutlet UIButton *updateEMVapp3;
@property (weak, nonatomic) IBOutlet UIButton *updateEMVapp4;
@property (weak, nonatomic) IBOutlet UIButton *addAids;

@end

@implementation MainDetailViewController{
    QPOSService *pos;
    UIAlertView *mAlertView;
    UIActionSheet *mActionSheet;
    PosType     mPosType;
    dispatch_queue_t self_queue;
    TransactionType mTransType;
    NSString *msgStr;
    UIProgressView* progressView;
    NSTimer* appearTimer;
    float _updateProgress;
    
}

@synthesize bluetoothAddress;
@synthesize amount;
@synthesize cashbackAmount;

#pragma mart - sdk delegate

-(void)clearDisplay{
    self.textViewLog.text = @"";
}
-(NSString *)checkAmount:(NSString *)tradeAmount{
    NSString *rs = @"";
    NSInteger a = 0;
    
    NSLog(@"tradeAmount = %@",tradeAmount);
    if (tradeAmount==nil || [tradeAmount isEqualToString:@""]) {
        return rs;
    }
    
    
    if ([tradeAmount hasPrefix:@"0"]) {
        return rs;
    }
    
    if (![Util isPureInt:tradeAmount]) {
        return rs;
    }
    
    a = [tradeAmount length];
    if (a == 1) {
        rs = [@"0.0" stringByAppendingString:tradeAmount];
    }else if (a==2){
        rs = [@"0." stringByAppendingString:tradeAmount];
    }else if(a > 2){
        rs = [tradeAmount substringWithRange:NSMakeRange(0, a-2)];
        rs = [rs stringByAppendingString:@"."];
        rs = [rs stringByAppendingString: [tradeAmount substringWithRange:NSMakeRange(a-2,2)]];
    }
    NSLog(@"trade amount = %@",rs);
    return rs;
}

-(void) onQposIdResult: (NSDictionary*)posId{
    NSString *aStr = [@"posId:" stringByAppendingString:posId[@"posId"]];
    
    NSString *temp = [@"psamId:" stringByAppendingString:posId[@"psamId"]];
    aStr = [aStr stringByAppendingString:@"\n"];
    aStr = [aStr stringByAppendingString:temp];
    
    temp = [@"merchantId:" stringByAppendingString:posId[@"merchantId"]];
    aStr = [aStr stringByAppendingString:@"\n"];
    aStr = [aStr stringByAppendingString:temp];
    
    temp = [@"vendorCode:" stringByAppendingString:posId[@"vendorCode"]];
    aStr = [aStr stringByAppendingString:@"\n"];
    aStr = [aStr stringByAppendingString:temp];
    
    temp = [@"deviceNumber:" stringByAppendingString:posId[@"deviceNumber"]];
    aStr = [aStr stringByAppendingString:@"\n"];
    aStr = [aStr stringByAppendingString:temp];
    
    temp = [@"psamNo:" stringByAppendingString:posId[@"psamNo"]];
    aStr = [aStr stringByAppendingString:@"\n"];
    aStr = [aStr stringByAppendingString:temp];
    
    self.textViewLog.text = aStr;
    
   
    //    dispatch_async(dispatch_get_main_queue(),  ^{
    //        NSDateFormatter *dateFormatter = [NSDateFormatter new];
    //        [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    //        _terminalTime = [dateFormatter stringFromDate:[NSDate date]];
    //        mTransType = TransactionType_GOODS;
    //        _currencyCode = @"156";
    //        [pos doTrade:30];
    //    });
}

-(void) onRequestWaitingUser{
    self.textViewLog.text  =@"Please insert/swipe/tap card now.";
}
-(void) onDHError: (DHError)errorState{
    NSString *msg = @"";
    
    if(errorState ==DHError_TIMEOUT) {
        msg = @"Pos no response";
    } else if(errorState == DHError_DEVICE_RESET) {
        msg = @"Pos reset";
    } else if(errorState == DHError_UNKNOWN) {
        msg = @"Unknown error";
    } else if(errorState == DHError_DEVICE_BUSY) {
        msg = @"Pos Busy";
    } else if(errorState == DHError_INPUT_OUT_OF_RANGE) {
        msg = @"Input out of range.";
    } else if(errorState == DHError_INPUT_INVALID_FORMAT) {
        msg = @"Input invalid format.";
    } else if(errorState == DHError_INPUT_ZERO_VALUES) {
        msg = @"Input are zero values.";
    } else if(errorState == DHError_INPUT_INVALID) {
        msg = @"Input invalid.";
    } else if(errorState == DHError_CASHBACK_NOT_SUPPORTED) {
        msg = @"Cashback not supported.";
    } else if(errorState == DHError_CRC_ERROR) {
        msg = @"CRC Error.";
    } else if(errorState == DHError_COMM_ERROR) {
        msg = @"Communication Error.";
    }else if(errorState == DHError_MAC_ERROR){
        msg = @"MAC Error.";
    }else if(errorState == DHError_CMD_TIMEOUT){
        msg = @"CMD Timeout.";
    }else if(errorState == DHError_AMOUNT_OUT_OF_LIMIT){
        msg = @"Amount out of limit.";
    }
    
    self.textViewLog.text = msg;
    NSLog(@"onError = %@",msg);
}

- (IBAction)clearTradeLog:(id)sender {
    NSDictionary * doTradeLogDictionary = [pos syncDoTradeLogOperation:0 data:0];
    NSLog(@"%@",doTradeLogDictionary);
}

//开始执行start 按钮后返回的结果状态
-(void) onDoTradeResult: (DoTradeResult)result DecodeData:(NSDictionary*)decodeData{
    NSLog(@"onDoTradeResult?>> result %ld",(long)result);
    if (result == DoTradeResult_NONE) {
        self.textViewLog.text = @"No card detected. Please insert or swipe card again and press check card.";
        [pos doTrade:30];
    }else if (result==DoTradeResult_ICC) {
        self.textViewLog.text = @"ICC Card Inserted";
        [pos doEmvApp:EmvOption_START];
    }else if(result==DoTradeResult_NOT_ICC){
        self.textViewLog.text = @"Card Inserted (Not ICC)";
    }else if(result==DoTradeResult_MCR){
        //        [pos getCardNo]
        ;        NSLog(@"decodeData: %@",decodeData);
        NSString *formatID = [NSString stringWithFormat:@"Format ID: %@\n",decodeData[@"formatID"]] ;
        NSString *maskedPAN = [NSString stringWithFormat:@"Masked PAN: %@\n",decodeData[@"maskedPAN"]];
        NSString *expiryDate = [NSString stringWithFormat:@"Expiry Date: %@\n",decodeData[@"expiryDate"]];
        NSString *cardHolderName = [NSString stringWithFormat:@"Cardholder Name: %@\n",decodeData[@"cardholderName"]];
        //NSString *ksn = [NSString stringWithFormat:@"KSN: %@\n",decodeData[@"ksn"]];
        NSString *serviceCode = [NSString stringWithFormat:@"Service Code: %@\n",decodeData[@"serviceCode"]];
        //NSString *track1Length = [NSString stringWithFormat:@"Track 1 Length: %@\n",decodeData[@"track1Length"]];
        //NSString *track2Length = [NSString stringWithFormat:@"Track 2 Length: %@\n",decodeData[@"track2Length"]];
        //NSString *track3Length = [NSString stringWithFormat:@"Track 3 Length: %@\n",decodeData[@"track3Length"]];
        //NSString *encTracks = [NSString stringWithFormat:@"Encrypted Tracks: %@\n",decodeData[@"encTracks"]];
        NSString *encTrack1 = [NSString stringWithFormat:@"Encrypted Track 1: %@\n",decodeData[@"encTrack1"]];
        NSString *encTrack2 = [NSString stringWithFormat:@"Encrypted Track 2: %@\n",decodeData[@"encTrack2"]];
        NSString *encTrack3 = [NSString stringWithFormat:@"Encrypted Track 3: %@\n",decodeData[@"encTrack3"]];
        //NSString *partialTrack = [NSString stringWithFormat:@"Partial Track: %@",decodeData[@"partialTrack"]];
        NSString *pinKsn = [NSString stringWithFormat:@"PIN KSN: %@\n",decodeData[@"pinKsn"]];
        NSString *trackksn = [NSString stringWithFormat:@"Track KSN: %@\n",decodeData[@"trackksn"]];
        NSString *pinBlock = [NSString stringWithFormat:@"pinBlock: %@\n",decodeData[@"pinblock"]];
        NSString *encPAN = [NSString stringWithFormat:@"encPAN: %@\n",decodeData[@"encPAN"]];
        
        NSString *msg = [NSString stringWithFormat:@"Card Swiped:\n"];
        msg = [msg stringByAppendingString:formatID];
        msg = [msg stringByAppendingString:maskedPAN];
        msg = [msg stringByAppendingString:expiryDate];
        msg = [msg stringByAppendingString:cardHolderName];
        //msg = [msg stringByAppendingString:ksn];
        msg = [msg stringByAppendingString:pinKsn];
        msg = [msg stringByAppendingString:trackksn];
        msg = [msg stringByAppendingString:serviceCode];
        
        msg = [msg stringByAppendingString:encTrack1];
        msg = [msg stringByAppendingString:encTrack2];
        msg = [msg stringByAppendingString:encTrack3];
        msg = [msg stringByAppendingString:pinBlock];
        msg = [msg stringByAppendingString:encPAN];
        self.textViewLog.backgroundColor = [UIColor greenColor];
        [self playAudio];
        AudioServicesPlaySystemSound (kSystemSoundID_Vibrate);
        self.textViewLog.text = msg;
        self.lableAmount.text = @"";
        //        dispatch_async(dispatch_get_main_queue(),  ^{
        //            [pos calcMacDouble:@"12345678123456781234567812345678"];
        //         });
    }else if(result==DoTradeResult_NFC_OFFLINE || result == DoTradeResult_NFC_ONLINE){
        NSLog(@"decodeData: %@",decodeData);
        NSString *formatID = [NSString stringWithFormat:@"Format ID: %@\n",decodeData[@"formatID"]] ;
        NSString *maskedPAN = [NSString stringWithFormat:@"Masked PAN: %@\n",decodeData[@"maskedPAN"]];
        NSString *expiryDate = [NSString stringWithFormat:@"Expiry Date: %@\n",decodeData[@"expiryDate"]];
        NSString *cardHolderName = [NSString stringWithFormat:@"Cardholder Name: %@\n",decodeData[@"cardholderName"]];
        //NSString *ksn = [NSString stringWithFormat:@"KSN: %@\n",decodeData[@"ksn"]];
        NSString *serviceCode = [NSString stringWithFormat:@"Service Code: %@\n",decodeData[@"serviceCode"]];
        //NSString *track1Length = [NSString stringWithFormat:@"Track 1 Length: %@\n",decodeData[@"track1Length"]];
        //NSString *track2Length = [NSString stringWithFormat:@"Track 2 Length: %@\n",decodeData[@"track2Length"]];
        //NSString *track3Length = [NSString stringWithFormat:@"Track 3 Length: %@\n",decodeData[@"track3Length"]];
        //NSString *encTracks = [NSString stringWithFormat:@"Encrypted Tracks: %@\n",decodeData[@"encTracks"]];
        NSString *encTrack1 = [NSString stringWithFormat:@"Encrypted Track 1: %@\n",decodeData[@"encTrack1"]];
        NSString *encTrack2 = [NSString stringWithFormat:@"Encrypted Track 2: %@\n",decodeData[@"encTrack2"]];
        NSString *encTrack3 = [NSString stringWithFormat:@"Encrypted Track 3: %@\n",decodeData[@"encTrack3"]];
        //NSString *partialTrack = [NSString stringWithFormat:@"Partial Track: %@",decodeData[@"partialTrack"]];
        NSString *pinKsn = [NSString stringWithFormat:@"PIN KSN: %@\n",decodeData[@"pinKsn"]];
        NSString *trackksn = [NSString stringWithFormat:@"Track KSN: %@\n",decodeData[@"trackksn"]];
        NSString *pinBlock = [NSString stringWithFormat:@"pinBlock: %@\n",decodeData[@"pinblock"]];
        NSString *encPAN = [NSString stringWithFormat:@"encPAN: %@\n",decodeData[@"encPAN"]];
        
        NSString *msg = [NSString stringWithFormat:@"Tap Card:\n"];
        msg = [msg stringByAppendingString:formatID];
        msg = [msg stringByAppendingString:maskedPAN];
        msg = [msg stringByAppendingString:expiryDate];
        msg = [msg stringByAppendingString:cardHolderName];
        //msg = [msg stringByAppendingString:ksn];
        msg = [msg stringByAppendingString:pinKsn];
        msg = [msg stringByAppendingString:trackksn];
        msg = [msg stringByAppendingString:serviceCode];
        
        msg = [msg stringByAppendingString:encTrack1];
        msg = [msg stringByAppendingString:encTrack2];
        msg = [msg stringByAppendingString:encTrack3];
        msg = [msg stringByAppendingString:pinBlock];
        msg = [msg stringByAppendingString:encPAN];
        
        dispatch_async(dispatch_get_main_queue(),  ^{
            NSDictionary *mDic = [pos getNFCBatchData];
            NSString *tlv;
            if(mDic !=nil){
                tlv= [NSString stringWithFormat:@"NFCBatchData: %@\n",mDic[@"tlv"]];
            }else{
                tlv = @"";
            }
            
            self.textViewLog.backgroundColor = [UIColor greenColor];
            [self playAudio];
            AudioServicesPlaySystemSound (kSystemSoundID_Vibrate);
            self.textViewLog.text = [msg stringByAppendingString:tlv];
            self.lableAmount.text = @"";
        });
        
    }else if(result==DoTradeResult_NFC_DECLINED){
        self.textViewLog.text = @"Tap Card Declined";
    }else if (result==DoTradeResult_NO_RESPONSE){
        self.textViewLog.text = @"Check card no response";
    }else if(result==DoTradeResult_BAD_SWIPE){
        self.textViewLog.text = @"Bad Swipe. \nPlease swipe again and press check card.";
        
//        [pos doTrade:30];
    }else if(result==DoTradeResult_NO_UPDATE_WORK_KEY){
        self.textViewLog.text = @"device not update work key";
    }
    
}
- (void)playAudio
{
    if(![self.bluetoothAddress isEqualToString:@"audioType"]){
        
        SystemSoundID soundID;
        NSString *strSoundFile = [[NSBundle mainBundle] pathForResource:@"1801" ofType:@"wav"];
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:strSoundFile],&soundID);
        AudioServicesPlaySystemSound(soundID);
    }
}

//输入金额
-(void) onRequestSetAmount{
    
    NSString *msg = @"";
    mAlertView = [[UIAlertView new]
                  initWithTitle:@"Please set amount"
                  message:msg
                  delegate:self
                  cancelButtonTitle:@"Confirm"
                  otherButtonTitles:@"Cancel",
                  nil ];
    [mAlertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [mAlertView show];
    msgStr = @"Please set amount";
}
//
-(void) onRequestSelectEmvApp: (NSArray*)appList{
    //NSString *resultStr = @"";
    
    mActionSheet = [[UIActionSheet new] initWithTitle:@"Please select app" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil, nil];
    
    for (int i=0 ; i<[appList count] ; i++){
        NSString *emvApp = [appList objectAtIndex:i];
        [mActionSheet addButtonWithTitle:emvApp];
        
        //resultStr = [NSString stringWithFormat:@"%@[%@] ", resultStr,emvApp];
    }
    [mActionSheet addButtonWithTitle:@"Cancel"];
    [mActionSheet setCancelButtonIndex:[appList count]];
    [mActionSheet showInView:[UIApplication sharedApplication].keyWindow];
    
    //NSLog(@"resultStr: %@",resultStr);
    
}
-(void) onRequestFinalConfirm{
    
    NSLog(@"onRequestFinalConfirm-------amount = %@",amount);
    NSString *msg = [NSString stringWithFormat:@"Amount: $%@",self.amount];
    mAlertView = [[UIAlertView new]
                  initWithTitle:@"Confirm amount"
                  message:msg
                  delegate:self
                  cancelButtonTitle:@"Confirm"
                  otherButtonTitles:@"Cancel",
                  nil ];
    [mAlertView show];
    msgStr = @"Confirm amount";
}
-(void) onQposInfoResult: (NSDictionary*)posInfoData{
    NSLog(@"onQposInfoResult: %@",posInfoData);
    NSString *aStr = @"Bootloader Version: ";
    aStr = [aStr stringByAppendingString:posInfoData[@"bootloaderVersion"]];
    
    aStr = [aStr stringByAppendingString:@"\n"];
    aStr = [aStr stringByAppendingString:@"Firmware Version: "];
    aStr = [aStr stringByAppendingString:posInfoData[@"firmwareVersion"]];
    
    aStr = [aStr stringByAppendingString:@"\n"];
    aStr = [aStr stringByAppendingString:@"Hardware Version: "];
    aStr = [aStr stringByAppendingString:posInfoData[@"hardwareVersion"]];
    
    
    NSString *batteryPercentage = posInfoData[@"batteryPercentage"];
    if (batteryPercentage==nil || [@"" isEqualToString:batteryPercentage]) {
        aStr = [aStr stringByAppendingString:@"\n"];
        aStr = [aStr stringByAppendingString:@"Battery Level: "];
        aStr = [aStr stringByAppendingString:posInfoData[@"batteryLevel"]];
        
    }else{
        aStr = [aStr stringByAppendingString:@"\n"];
        aStr = [aStr stringByAppendingString:@"Battery Percentage: "];
        aStr = [aStr stringByAppendingString:posInfoData[@"batteryPercentage"]];
    }
    aStr = [aStr stringByAppendingString:@"\n"];
    aStr = [aStr stringByAppendingString:@"Charge: "];
    aStr = [aStr stringByAppendingString:posInfoData[@"isCharging"]];
    
    aStr = [aStr stringByAppendingString:@"\n"];
    aStr = [aStr stringByAppendingString:@"USB: "];
    aStr = [aStr stringByAppendingString:posInfoData[@"isUsbConnected"]];
    
    aStr = [aStr stringByAppendingString:@"\n"];
    aStr = [aStr stringByAppendingString:@"Track 1 Supported: "];
    aStr = [aStr stringByAppendingString:posInfoData[@"isSupportedTrack1"]];
    
    aStr = [aStr stringByAppendingString:@"\n"];
    aStr = [aStr stringByAppendingString:@"Track 2 Supported: "];
    aStr = [aStr stringByAppendingString:posInfoData[@"isSupportedTrack2"]];
    
    aStr = [aStr stringByAppendingString:@"\n"];
    aStr = [aStr stringByAppendingString:@"Track 3 Supported: "];
    aStr = [aStr stringByAppendingString:posInfoData[@"isSupportedTrack3"]];
    
    aStr = [aStr stringByAppendingString:@"\n"];
    aStr = [aStr stringByAppendingString:@"updateWorkKeyFlag: "];
    aStr = [aStr stringByAppendingString:posInfoData[@"updateWorkKeyFlag"]];
    
    self.textViewLog.text = aStr;
}
-(void) onRequestTime{
    //    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    //    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    //    NSString *terminalTime = [dateFormatter stringFromDate:[NSDate date]];
    [pos sendTime:_terminalTime];
    
}
-(void) onRequestIsServerConnected{
    
    
    NSString *msg = @"Replied connected.";
    msgStr = @"Online process requested.";
    
    [self conductEventByMsg:msgStr];
    
    //    mAlertView = [[UIAlertView new]
    //                  initWithTitle:@"Online process requested."
    //                  message:msg
    //                  delegate:self
    //                  cancelButtonTitle:@"Confirm"
    //                  otherButtonTitles:nil,
    //                  nil ];
    
    //    [mAlertView show];
    
    
}

//Request data to server
-(void) onPinKeyTDESResult:(NSString *)encPin{
    NSLog(@"onPinKeyTDESResult: %@",encPin);
    NSString *msg = @"Replied success.";
    
    msgStr = @"Request data to server.";
    [self conductEventByMsg:msgStr];
    
    //        mAlertView = [[UIAlertView new]
    //                      initWithTitle:@"Request data to server."
    //                      message:msg
    //                      delegate:self
    //                      cancelButtonTitle:@"Confirm"
    //                      otherButtonTitles:nil,
    //                      nil ];
    //        [mAlertView show];
    
}

//回调成功的alert
-(void) onRequestOnlineProcess: (NSString*) tlv{
//    NSInteger length = [Util  byteArrayToInt:[Util HexStringToByteArray:@"0231"]];
//    NSString * tlvStr = [tlv substringWithRange:NSMakeRange(4, length*2)];
//    
//    NSDictionary *dictionaryTLV = [SGTLVDecode decodeWithString:tlvStr];
//    NSLog(@"maskedPan == %@",[[dictionaryTLV valueForKey:@"C4"] valueForKey:@"value"]);

    
//    NSDictionary *dict = [pos getICCTag:0 tagCount:1 tagArrStr:@"5F20"];
    
  
//      NSDictionary *dict9F06 = [pos getICCTag:0 tagCount:1 tagArrStr:@"9F06"];
    NSDictionary *dict5F2A = [pos getICCTag:0 tagCount:1 tagArrStr:@"5F2A"];
    NSDictionary *DF5F36 = [pos getICCTag:0 tagCount:1 tagArrStr:@"5F36"];
    NSDictionary *DF9F01= [pos getICCTag:0 tagCount:1 tagArrStr:@"9F01"];
    NSDictionary *dict9F06 = [pos getICCTag:0 tagCount:1 tagArrStr:@"9F06"];
    NSDictionary *dict9F09 = [pos getICCTag:0 tagCount:1 tagArrStr:@"9F09"];
    NSDictionary *DF9F15 = [pos getICCTag:0 tagCount:1 tagArrStr:@"9F15"];
    NSDictionary *DF9F1B= [pos getICCTag:0 tagCount:1 tagArrStr:@"9F1B"];
    NSDictionary *dict9F1C = [pos getICCTag:0 tagCount:1 tagArrStr:@"9F1C"];
    NSDictionary *dict9F1E = [pos getICCTag:0 tagCount:1 tagArrStr:@"9F1E"];
    NSDictionary *DF9F33 = [pos getICCTag:0 tagCount:1 tagArrStr:@"9F33"];
    NSDictionary *DF9F35= [pos getICCTag:0 tagCount:1 tagArrStr:@"9F35"];
    NSDictionary *dict9F39 = [pos getICCTag:0 tagCount:1 tagArrStr:@"9F39"];
    NSDictionary *dict9F3C = [pos getICCTag:0 tagCount:1 tagArrStr:@"9F3C"];
    NSDictionary *DF9F3D = [pos getICCTag:0 tagCount:1 tagArrStr:@"9F3D"];
    NSDictionary *DF9F40 = [pos getICCTag:0 tagCount:1 tagArrStr:@"9F40"];
    NSDictionary *dict9F4E = [pos getICCTag:0 tagCount:1 tagArrStr:@"9F4E"];
    NSDictionary *dict9F66 = [pos getICCTag:0 tagCount:1 tagArrStr:@"9F66"];
    NSDictionary *DF9F73 = [pos getICCTag:0 tagCount:1 tagArrStr:@"9F73"];
    NSDictionary *DF9F7B = [pos getICCTag:0 tagCount:1 tagArrStr:@"9F7B"];
//
    
    NSArray *arr = @[dict5F2A,DF5F36,DF9F01,dict9F06,dict9F09,DF9F1B,DF9F15,dict9F1E,dict9F1C,dict9F66,DF9F33,dict9F39,dict9F3C,DF9F3D,DF9F40,dict9F4E,dict9F66,DF9F73,DF9F7B,DF9F35];
//    NSString *a = @"5F200F46554C4C2046554E4354494F4E414C4F07A00000000310105F24032012319F160F4243544553542031323334353637389F21031107149A031710139F02060000000000129F03060000000000009F34031F03009F120D4352454449544F4445564953419F0607A00000000310105F300202019F4E0F616263640000000000000000000000C408476173FFFFFF0010C00AFFFF000000BB81200008C28201908BEA221E6DACB7EE262AD3E308E7A2DBE2D2AC5374F689E7F9946C9C8E09042A22B159F3629CB2A8AED0F41740C64848C02DF345ACBD8FBB8032BC5D7D8BF4D001453529479FFB61019B4A20F111D2AADA27808C54E291B3606DC1ABE3B9DF74BAA5B9453FDDC10AA6F6290178D32C3BE002B2995DEB40479BC994AAE111BD6C6BA41FE5ACA0A2ED0E5700F6FC9E12359B1B3B9D2512A14C932D80FB80AB0C834DB64E9D44D43752D554A4FCBC7A8933B98D9FAC8C3D76323931AE9E3FE6B9EE6FCE10F0890744D670BEF570D8C7BCF3D50386365283CC67ADEE5E59A003CD86B0A77FA5B3A2EF785AE50D33C448DEE34B11205593F140DA1CC71A0D2E01F65319A874974A020B43A3BAA3AE25AFC0980D1CB81053F99114382BAA1467B39E4006F16DA9BC9B6397E64D38340B5E2A91EE7DD57227079738D420AD9DC35927889BFCA51B4FE6B87AEBF801A13A04A8369CE854B7F9292E9AE57C46BCFFB6EF71418397B59EADFD2EA11BCD17A6F34136B17F667124FE1E44958C7B2E46FEC88D86C6CA0409BEF1432B0245329127DADC06737769706531";
    
    NSString * ab = @"5F2013415320424153494320564953412044454249544F07A00000000310105F24032212319F160F4243544553542031323334353637389F21031124289A031710139F02060000000095209F03060000000000009F34031E03009F120A564953412044454249549F0607A00000000310105F300202019F4E0F616263640000000000000000000000C408476173FFFFFF0211C00AFFFF9876543210E00294C28201A0717B8A5AA7513EDC5B5D46C2001B2A07DC0A7C9538466E910AA9A056531C3082F826BBF6C72059A933F6E4D15807D030D10BC33B897F1F1E80E775D339742EF61AABC1CAA6365AA839F22E5F5109180418E3CDF07BABE68784FEEA0B643A67AAA3EC4E7E2A1435262261814B4380E229FC95E28DFEA3501E5F317E02A440A6A611F51705F0E655E114EC6F1151B63869147DD53BE715F0E4C93AE952E9151E789ABD95DC8B47A3667A8125F26CAF55F83520AA2A62697483F3572C0CC0900022351A7D4150EBDFB706FDE243B858C2AF98507218DD19D26EA779CF7889DAE19324F818944BA3B7051440C74C5CA3DAD01FD9AD61D04413DF740C2C9237893A956CD884FEDDC060ED24D017D44964DB41BCDF6A8C4A52B348478D8F04C068A3162B7749EB8D76716A98FD06B369B96C15097E0654959AE1CD35BE6ABFF080CD6A2B07CA8CB057F48AFF22476192B9C16E9A8E4F1CDE43B3BE51CAB3438FF9F9E066B368962C49991D154CB1A239E3BD6B94BBAF09FD65574597B45964F898DBFED7F5044C523543236945F0973AA28AE6E3F5EDB4B21F770E8D9FBA60F6BDA9E5";
//     NSLog(@"maskedPan == %@",[[dictionaryTLV valueForKey:@"C4"] valueForKey:@"value"]);
//
////    NSString * a = @"5F2013415320424153494320564953412044454249544F07A00000000310105F24032212319F160F4243544553542031323334353637389F21031052219A031710139F02060000000095209F03060000000000009F34031E03009F120A564953412044454249549F0607A00000000310105F300202019F4E0F616263640000000000000000000000C408476173FFFFFF0211C00AFFFF9876543210E00293C28201A07036AA43A8CA3C410F718C8A8D8D717CA4B0027FA69C80B3A089125CDCE7388D8E439EC1A1EE1A62061126156E504FAD8189FCEA3AEEE0A4A9C940713C5E8D5D1A702C6C90924237D2475D5E11AFCE759E1CBC7B2C954F84FA34E7AC6A9A0663348C162EDA4B4509F57ADFB8A2EEB424EC1562A8A516831ADD0E71B326DEB5227D0A57F458626EFDA8F9AE160D07431A358CDCAB06EE0599AF4043D736DBA200F853EA0659AFAA79EFADBC91697CEFD5075239327B6502E0BFFBEFA01F49490C3A7388B08641723C896FEC7030B1D4D821FAE33DE983C213333741BC79DC325B28354CF8E893A8E9ECBFEBBF045F42A3617A3E7517258813E44F58DC463392DF93C06AF140281C97646C5B9BE1E98934CB6D0EFCBBD0A9B3730ECE2FC9D2552859F2F21B72906C0CD04340BA0F47467F9DF4BA09E81F8328FBB004C1768A1DD5243F6E5BE292D1B0EB58D5B5C07C2EECA530FCC31CBE213D37E9BDE3462F3E92499538CAEC189AA8563295DF3CC2DB0D0B921F199666102CB85485FD10DBE79745318346AE0FF98FBCF0CFFC7183EFEB90089601471BD9EDFE989B037EC3DDAD";
//    
//      NSLog(@"onRequestOnlineProcess = %@",[[QPOSService sharedInstance] anlysEmvIccData:a]);
    
    
    
    //    [self claMac];
         //[self batchSendAPDU];
    //    [pos calcMacDouble_all:@"12345678123456781234567812345678" keyIndex:0 delay:5];
    //    [pos pinKey_TDES_all:0 pin:@"1122334455667788" delay:5];
    
    
   // NSDictionary *dict = [pos getICCTag:0 tagCount:1 tagArrStr:@"5F20"];

//    NSDictionary *dict9f01 = [pos getICCTag:0 tagCount:1 tagArrStr:@"9f01"];
//    NSLog(@"dict9f01 = %@",dict9f01);
//    NSDictionary *dict9f15 = [pos getICCTag:0 tagCount:1 tagArrStr:@"9f15"];
//    NSLog(@"dict9f15 = %@",dict9f15);
//    NSDictionary *dict9f45 = [pos getICCTag:0 tagCount:1 tagArrStr:@"9f45"];
//    NSLog(@"dict9f45 = %@",dict9f45);
//    NSDictionary *dict9f1c = [pos getICCTag:0 tagCount:1 tagArrStr:@"9f1c"];
//    NSLog(@"dict9f1c = %@",dict9f1c);
//    NSString *msg = nil;
//    if ([pos getQuickEMV]) {
//        msg = @"isQuickEMV";
//        msgStr = @"Request data to server.";
//        [self conductEventByMsg:msgStr];
//        
//    }else{
        NSString* msg = @"Replied success.";
        msgStr = @"Request data to server.";
        mAlertView = [[UIAlertView new]
                      initWithTitle:@"Request data to server."
                      message:msg
                      delegate:self
                      cancelButtonTitle:@"Confirm"
                      otherButtonTitles:nil,
                      nil ];
        [mAlertView show];
//    }
//
    
    
}
-(void) onRequestTransactionResult: (TransactionResult)transactionResult{
    
    NSString *messageTextView = @"";
    if (transactionResult==TransactionResult_APPROVED) {
        NSString *message = [NSString stringWithFormat:@"Approved\nAmount: $%@\n",amount];
        
        if([cashbackAmount isEqualToString:@""]) {
            message = [message stringByAppendingString:@"Cashback: $"];
            message = [message stringByAppendingString:cashbackAmount];
        }
        messageTextView = message;
        self.textViewLog.backgroundColor = [UIColor greenColor];
        [self playAudio];
    }else if(transactionResult == TransactionResult_TERMINATED) {
        [self clearDisplay];
        messageTextView = @"Terminated";
    } else if(transactionResult == TransactionResult_DECLINED) {
        messageTextView = @"Declined";
        
    } else if(transactionResult == TransactionResult_CANCEL) {
        [self clearDisplay];
        messageTextView = @"Cancel";
    } else if(transactionResult == TransactionResult_CAPK_FAIL) {
        [self clearDisplay];
        messageTextView = @"Fail (CAPK fail)";
    } else if(transactionResult == TransactionResult_NOT_ICC) {
        [self clearDisplay];
        messageTextView = @"Fail (Not ICC card)";
    } else if(transactionResult == TransactionResult_SELECT_APP_FAIL) {
        [self clearDisplay];
        messageTextView = @"Fail (App fail)";
    } else if(transactionResult == TransactionResult_DEVICE_ERROR) {
        [self clearDisplay];
        messageTextView = @"Pos Error";
    } else if(transactionResult == TransactionResult_CARD_NOT_SUPPORTED) {
        [self clearDisplay];
        messageTextView = @"Card not support";
    } else if(transactionResult == TransactionResult_MISSING_MANDATORY_DATA) {
        [self clearDisplay];
        messageTextView = @"Missing mandatory data";
    } else if(transactionResult == TransactionResult_CARD_BLOCKED_OR_NO_EMV_APPS) {
        [self clearDisplay];
        messageTextView = @"Card blocked or no EMV apps";
    } else if(transactionResult == TransactionResult_INVALID_ICC_DATA) {
        [self clearDisplay];
        messageTextView = @"Invalid ICC data";
    }else if(transactionResult == TransactionResult_NFC_TERMINATED) {
        [self clearDisplay];
        messageTextView = @"NFC Terminated";
    }
    
    mAlertView = [[UIAlertView new]
                  initWithTitle:@"Transaction Result"
                  message:messageTextView
                  delegate:self
                  cancelButtonTitle:@"Confirm"
                  otherButtonTitles:nil,
                  nil ];
    [mAlertView show];
    self.amount = @"";
    self.cashbackAmount = @"";
    self.lableAmount.text = @"";
}
-(void) onRequestTransactionLog: (NSString*)tlv{
    NSLog(@"onTransactionLog %@",tlv);
}
-(void) onRequestBatchData: (NSString*)tlv{
    NSLog(@"onBatchData %@",tlv);
    tlv = [@"batch data:\n" stringByAppendingString:tlv];
    self.textViewLog.text = tlv;
}

-(void) onReturnReversalData: (NSString*)tlv{
    NSLog(@"onReversalData %@",tlv);
    tlv = [@"reversal data:\n" stringByAppendingString:tlv];
    self.textViewLog.text = tlv;
}

//pos 连接成功的回调
-(void) onRequestQposConnected{
    NSLog(@"onRequestQposConnected");
    if ([self.bluetoothAddress  isEqual: @"audioType"]) {
        self.textViewLog.text = @"AudioType connected.";
//        [self sleepMs:1000];
//        [pos doTrade:30];
    }else{
        self.textViewLog.text = @"Bluetooth connected.";
//        [self sleepMs:1000];
//        [pos getQPosInfo];
    }
    
}
//pos  连接失败的回调
-(void) onRequestQposDisconnected{
    NSLog(@"onRequestQposDisconnected");
    self.textViewLog.text = @"pos disconnected.";
    
}
//没有创建连接的回调
-(void) onRequestNoQposDetected{
    NSLog(@"onRequestNoQposDetected");
    self.textViewLog.text = @"No pos detected.";
    
}

-(void) onRequestDisplay: (Display)displayMsg{
    NSString *msg = @"";
    if (displayMsg==Display_CLEAR_DISPLAY_MSG) {
        msg = @"";
    }else if(displayMsg==Display_PLEASE_WAIT){
        msg = @"Please wait...";
    }else if(displayMsg==Display_REMOVE_CARD){
        msg = @"Please remove card";
    }else if (displayMsg==Display_TRY_ANOTHER_INTERFACE){
        msg = @"Please try another interface";
    }else if (displayMsg == Display_TRANSACTION_TERMINATED){
        msg = @"Terminated";
    }else if (displayMsg == Display_PIN_OK){
        msg = @"Pin ok";
    }else if (displayMsg == Display_INPUT_PIN_ING){
        msg = @"please input pin on pos";
    }else if (displayMsg == Display_MAG_TO_ICC_TRADE){
        msg = @"please insert chip card on pos";
    }else if (displayMsg == Display_INPUT_OFFLINE_PIN_ONLY){
        msg = @"input offline pin only";
    }else if(displayMsg == Display_CARD_REMOVED){
        msg = @"Card Removed";
    }
    self.textViewLog.text = msg;
}
-(void) onReturnGetPinResult:(NSDictionary*)decodeData{
    NSString *aStr = @"pinKsn: ";
    aStr = [aStr stringByAppendingString:decodeData[@"pinKsn"]];
    
    aStr = [aStr stringByAppendingString:@"\n"];
    aStr = [aStr stringByAppendingString:@"pinBlock: "];
    aStr = [aStr stringByAppendingString:decodeData[@"pinBlock"]];
    
    self.textViewLog.text = aStr;
}

//add icc apdu 2014-03-11
-(void) onReturnPowerOnIccResult:(BOOL) isSuccess  KSN:(NSString *) ksn ATR:(NSString *)atr ATRLen:(NSInteger)atrLen{
    if (isSuccess) {
        NSString *aStr = @"Power on ICC Success\nksn: ";
        aStr = [aStr stringByAppendingString:ksn];
        
        aStr = [aStr stringByAppendingString:@"\natr: "];
        aStr = [aStr stringByAppendingString:atr];
        aStr = [aStr stringByAppendingString:@"\natrLen: "];
        aStr = [aStr stringByAppendingString:[NSString stringWithFormat:@"%ld",(long)atrLen]];
        self.textViewLog.text = aStr;
        
    }else{
        self.textViewLog.text = @"Power on ICC Failed";
    }
}
-(void) onReturnPowerOffIccResult:(BOOL) isSuccess{
    if (isSuccess) {
        self.textViewLog.text = @"Power off ICC Success";
    }else{
        self.textViewLog.text = @"Power off ICC Failed";
    }
}
-(void) onReturnApduResult:(BOOL)isSuccess APDU:(NSString *)apdu APDU_Len:(NSInteger) apduLen{
    if (isSuccess) {
        NSString *aStr = @"APDU Result: ";
        aStr = [aStr stringByAppendingString:apdu];
        self.textViewLog.text = aStr;
    }else{
        self.textViewLog.text = @"APDU Failed";
    }
}

//add set the sleep time 2014-03-25
-(void)onReturnSetSleepTimeResult:(BOOL)isSuccess{
    if (isSuccess) {
        self.textViewLog.text = @"Set sleep time Success";
    }else{
        self.textViewLog.text = @"Set sleep time Failed";
    }
}

//add 2014-04-11
-(void)onReturnCustomConfigResult:(BOOL)isSuccess config:(NSString*)resutl{
    
    if(isSuccess){
        self.textViewLog.text = @"Success";
    }else{
        self.textViewLog.text =  @"Failed";
    }
    NSLog(@"result: %@",resutl);
}


-(void) onRequestGetCardNoResult:(NSString *)result{
    self.textViewLog.text = result;
    [pos pinKey_TDES_all:0 Pan:@"6217850800011191689" Pin:@"1111" TimeOut:5];
}


-(void) onRequestPinEntry{
    NSLog(@"onRequestPinEntry");
    NSString *msg = @"";
    mAlertView = [[UIAlertView new]
                  initWithTitle:@"Please set pin"
                  message:msg
                  delegate:self
                  cancelButtonTitle:@"Confirm"
                  otherButtonTitles:@"Cancel",
                  nil ];
    [mAlertView setAlertViewStyle:UIAlertViewStyleSecureTextInput];
    //UIAlertViewStylePlainTextInput
    [mAlertView show];
    
    msgStr = @"Please set pin";
    
}
- (IBAction)getTradeCount:(id)sender {
    NSDictionary *a = [pos syncDoTradeLogOperation:1 data:0];
    self.textViewLog.text = [a valueForKey:@"log"];
}


-(void) onReturnSetMasterKeyResult: (BOOL)isSuccess{
    if(isSuccess){
        self.textViewLog.text = @"Success";
    }else{
        self.textViewLog.text =  @"Failed";
    }
    //    NSLog(@"result: %@",resutl);
}
- (IBAction)getOnLineToolData:(id)sender {
    // NSLog(@"onRequestOnlineProcess tlv == %@",tlv);
        NSString *  tlv = @"02395F201A4153204241534943204D415354455243415244204352454449544F07A00000000410105F24032212319F160F4243544553542031323334353637389F21031259499A031709269F02060000000120019F03060000000000009F34031E03009F120A4D4153544552434152449F0607A00000000410105F300202019F4E0F616263640000000000000000000000C408541333FFFFFF0200C00AFFFF9876543210E00122C28201905579A827D8F268CFB98E0387C116674B9B6B9EA17A96D8C8F6CBE558FD48D1E8C3B85BE300473170931AB52ADF97A974764C52592723389052C9D4538CD45FD9E154C18D6C0EA4920AC75698EC458BC3396027FDD244D8D98775E8B381C339F41CF8608C2C1BA55E463737F9D77BF8E4696CF0047210F0464B296494AEB13365A7B363E95493D3F56FF231A4C773F5CE0288F231F251DAC6BEF85633B9B5A10369ABAE9730644E3E7F48E352A23EFC040DAF52E8F2D8C044A70070A65272B446F72FD3FF0807CFB8CC4F2E945F7265CDCDA04FD89EE6C1AB031F0EEFEF0C4E18BC0EBE3F5BCA1805151E7F7BDEBC2E382AA84308F19684D7F0B0DB22C2C7B8EDA1B0A4B6B15AD9496CCCF1831109E44A3C26E255F890DB8FDE8C854DC5A895564A4F4C06B4C882E709E7037C07EBDDB2829AFCFA30851D398334961555BDE2A47DAC51FBA599422447865FDFB6CD9BEF3F417B5F33267470F04FA13AB731E22B2BBE4FE8FDCACBED694B41A0EA5640597A1BBA5132976DB3B3E218B8B9C74A6CB88D0E8CEA4DF8FA8CE60F779F37BF0F054D31313238";
        
//        NSString *forDigitalPrefix = [tlv substringToIndex:4];
//        NSInteger dataLength1 = [[forDigitalPrefix substringToIndex:2] intValue]*256;
//        NSInteger dataLength2 = [[forDigitalPrefix substringWithRange:NSMakeRange(2, 1)]intValue] *16;
//        NSInteger dataLength3 = [[forDigitalPrefix substringWithRange:NSMakeRange(3, 1)]intValue] ;
//        NSInteger dataLength = dataLength1 + dataLength2 + dataLength3;
//        
//        NSString *onLineToolData = [tlv substringWithRange:NSMakeRange(4, dataLength*2)];
//        NSLog(@"onlineToolData = %@",onLineToolData);
}

-(void) onRequestUpdateWorkKeyResult:(UpdateInformationResult)updateInformationResult
{
    NSLog(@"onRequestUpdateWorkKeyResult %ld",(long)updateInformationResult);
    if (updateInformationResult==UpdateInformationResult_UPDATE_SUCCESS) {
        self.textViewLog.text = @"Success";
    }else if(updateInformationResult==UpdateInformationResult_UPDATE_FAIL){
        self.textViewLog.text =  @"Failed";
    }else if(updateInformationResult==UpdateInformationResult_UPDATE_PACKET_LEN_ERROR){
        self.textViewLog.text =  @"Packet len error";
    }
    else if(updateInformationResult==UpdateInformationResult_UPDATE_PACKET_VEFIRY_ERROR){
        self.textViewLog.text =  @"Packet vefiry error";
    }
    
}

-(void) onReturnBatchSendAPDUResult:(NSDictionary *)apduResponses{
    NSLog(@"onBatchApduResponseReceived - apduResponses: %@", apduResponses);
    
    NSArray *keys = [apduResponses allKeys];
    for (NSString *key in keys) {
        _textViewLog.text = [NSString stringWithFormat:@"%@%d:%@\n", _textViewLog.text, [key intValue], [apduResponses objectForKey:key]];
    }
}

-(void) onReturniccCashBack: (NSDictionary*)result{
    NSString *aStr = [@"serviceCode:" stringByAppendingString:result[@"serviceCode"]];
    aStr = [aStr stringByAppendingString:@"\n"];
    NSString *temp = [@"trackblock:" stringByAppendingString:result[@"trackblock"]];
    aStr = [aStr stringByAppendingString:temp];
    self.textViewLog.text = aStr;
    
}

-(void) onLcdShowCustomDisplay: (BOOL)isSuccess{
    if(isSuccess){
        self.textViewLog.text = @"Success";
    }else{
        self.textViewLog.text =  @"Failed";
    }
}

-(void)onRequestCalculateMac:(NSString *)calMacString{
    self.textViewLog.text =calMacString;
    NSLog(@"onRequestCalculateMac %@",calMacString);
    //    NSData *aa = [Util stringFormatTAscii:calMacString];
    //    NSLog(@"aaaaa: %@",[Util byteArray2Hex:aa]);
    NSString *msg = @"Replied success.";
    msgStr = @"Request data to server";
    [self conductEventByMsg:msgStr];
    //    mAlertView = [[UIAlertView new]
    //                  initWithTitle:@"Request data to server."
    //                  message:msg
    //                  delegate:self
    //                  cancelButtonTitle:@"Confirm"
    //                  otherButtonTitles:nil,
    //                  nil ];
    //    [mAlertView show];
}


-(void) onDownloadRsaPublicKeyResult:(NSDictionary *)result{
    NSLog(@"onDownloadRsaPublicKeyResult %@",result);
}

-(void) onGetPosComm:(NSInteger)mode amount:(NSString *)amt posId:(NSString*)aPosId{
    if(mode == 1){
        [pos doTrade:30];
    }
}

- (IBAction)testAlertView:(id)sender {
    //    NSString *msg = @"Replied success.";
    //    mAlertView = [[UIAlertView new]
    //                  initWithTitle:@"Request data to server."
    //                  message:msg
    //                  delegate:self
    //                  cancelButtonTitle:@"Confirm"
    //                  otherButtonTitles:nil,
    //                  nil ];
    //    [mAlertView show];
    
    msgStr = @"Request data to server.";
    [self conductEventByMsg:msgStr];
}

-(void) onEmvICCExceptionData: (NSString*)tlv{
    
}

#pragma mark - UIAlertView
#pragma mark 改写原有的confrim 绑定的方法

-(void)conductEventByMsg:(NSString *)msg{
    
    
    if ([msg isEqualToString:@"Online process requested."]){
        [pos isServerConnected:YES];
        
    }else if ([msg isEqualToString:@"Request data to server."]){
        if ([pos getQuickEMV]) {
            [pos sendOnlineProcessResult:@"8A023030"];
        }else{
            [pos sendOnlineProcessResult:@"8A023030"];
        }
      
        
    }else if ([msg isEqualToString:@"Transaction Result"]){
        
    }
    
    
}

-(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    NSString *aTitle = msgStr;
    NSLog(@"alertView.title = %@",aTitle);
    if ([aTitle isEqualToString:@"Please set amount"]) {
        if (buttonIndex==0) {
            UITextField *textFieldAmount =  [alertView textFieldAtIndex:0];
            NSString *inputAmount = [textFieldAmount text];
            NSLog(@"textFieldAmount = %@",inputAmount);
            
            self.lableAmount.text = [NSString stringWithFormat:@"$%@", [self checkAmount:inputAmount]];
            [pos setAmount:inputAmount aAmountDescribe:@"Cashback" currency:_currencyCode transactionType:mTransType];
            
            self.amount = [NSString stringWithFormat:@"%@", [self checkAmount:inputAmount]];
            self.cashbackAmount = @"Cashback";
            
            
        }else{
            [pos cancelSetAmount];
        }
        
    }else if ([aTitle isEqualToString:@"Confirm amount"]){
        if (buttonIndex==0) {
            [pos finalConfirm:YES];
        }else{
            [pos finalConfirm:NO];
        }
        
    }else if ([aTitle isEqualToString:@"Online process requested."]){
        [pos isServerConnected:YES];
        
    }else if ([aTitle isEqualToString:@"Request data to server."]){

        [pos sendOnlineProcessResult:@"8A023030"];

    }else if ([aTitle isEqualToString:@"Transaction Result"]){
        
    }else if ([aTitle isEqualToString:@"Please set pin"]) {
        if (buttonIndex==0) {
            UITextField *textFieldAmount =  [alertView textFieldAtIndex:0];
            NSString *pinStr = [textFieldAmount text];
            NSLog(@"pinStr = %@",pinStr);
            [pos sendPinEntryResult:pinStr];
        }else{
            [pos cancelPinEntry];
        }
    }
    [self hideAlertView];
    
}
- (void)willPresentAlertView:(UIAlertView *)alertView {
    //NSLog(@"willPresentAlertView");
}

- (void)hideAlertView{
    NSLog(@"hideAlertView");
    [mAlertView dismissWithClickedButtonIndex:0 animated:YES];
    
    //mAlertView = nil;
}


#pragma mark - UIActionSheet
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    NSString *aTitle = msgStr;
    NSInteger cancelIndex = actionSheet.cancelButtonIndex;
    NSLog(@"selectEmvApp cancelIndex = %d , index = %d",cancelIndex,buttonIndex);
    if ([aTitle isEqualToString:@"Please select app"]){
        if (buttonIndex==cancelIndex) {
            [pos cancelSelectEmvApp];
        }else{
            [pos selectEmvApp:buttonIndex];
        }
        
    }
    [mActionSheet dismissWithClickedButtonIndex:0 animated:YES];
    //mActionSheet = nil;
    
}

/*
 -(void)actionSheetCancel:(UIActionSheet *)actionSheet{
 NSLog(@"actionSheetCancel");
 }
 -(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
 NSLog(@"didDismissWithButtonIndex buttonIndex = %d",buttonIndex);
 }
 -(void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonInde{
 NSLog(@"willDismissWithButtonIndex buttonInde = %d",buttonInde);
 }
 
 */

#pragma mark - start do trade


- (void)si_one{
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *dateTimeString = [dateFormatter stringFromDate:[NSDate date]];
    
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    [dataDict setObject:[NSArray arrayWithObjects:@"FE", dateTimeString, @"00A404000FA0000003334355502D4D4F42494C45", nil] forKey:[NSNumber numberWithInt:1]];
    [dataDict setObject:[NSArray arrayWithObjects:@"FE", dateTimeString, @"80E0000000", nil] forKey:[NSNumber numberWithInt:2]];
    [dataDict setObject:[NSArray arrayWithObjects:@"FE", dateTimeString, @"00D68100404AC0680CDECDF183C0F8435ED4A34F15FE9DF64F7E289A05C0F8435ED4A34F15C0F8435ED4A34F15C0F8435ED4A34F15C0F8435ED4A34F15C0F8435ED4A34F15", nil] forKey:[NSNumber numberWithInt:3]];
    
    [dataDict setObject:[NSArray arrayWithObjects:@"FE", dateTimeString, @"00D682001076DAA738F81683570100FFFFFFFFFFFF", nil] forKey:[NSNumber numberWithInt:4]];//保存csn
    
    [dataDict setObject:[NSArray arrayWithObjects:@"FE", dateTimeString, @"00D683000101", nil] forKey:[NSNumber numberWithInt:5]];
    
    [dataDict setObject:[NSArray arrayWithObjects:@"FE", dateTimeString, @"0084000008", nil] forKey:[NSNumber numberWithInt:6]];//取随机数
    [pos VIPOSBatchSendAPDU:dataDict];
    
}

- (void)si_two{
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *dateTimeString = [dateFormatter stringFromDate:[NSDate date]];
    
    
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    [dataDict setObject:[NSArray arrayWithObjects:@"FE", dateTimeString, @"84F402201C1F4FECEB810743F78902013E8763064AC8D95EC3422ADCE00A8B9C1C", nil] forKey:[NSNumber numberWithInt:1]];
    [dataDict setObject:[NSArray arrayWithObjects:@"FE", dateTimeString, @"84F401131C0438BDAA7CB3FF42EFBAA5D10E195E0A404836BDC78DEEBC4B5DA53D", nil] forKey:[NSNumber numberWithInt:2]];
    [dataDict setObject:[NSArray arrayWithObjects:@"FE", dateTimeString, @"84F401141CE20D6208E563CF318B7F5DB2D3C61B373C2654551DC451D52AE3314D", nil] forKey:[NSNumber numberWithInt:3]];
    
    [dataDict setObject:[NSArray arrayWithObjects:@"FE", dateTimeString, @"84F401151CD40BAAB2B507C12925CF6958F1CD9902CF35590A9DBD8F99F386BC12", nil] forKey:[NSNumber numberWithInt:4]];
    
    [dataDict setObject:[NSArray arrayWithObjects:@"FE", dateTimeString, @"84F401161C98CE71278C7060083530B7B61B27B8997936B1907209EDEAB5DF0C80", nil] forKey:[NSNumber numberWithInt:5]];
    
    //    [dataDict setObject:[NSArray arrayWithObjects:@"FE", dateTimeString, @"84F401171CAE6DD1EFB70D1818F272F21B08DAACAB6BD70DED617328AFCF6FF0E8", nil] forKey:[NSNumber numberWithInt:6]];
    
    [dataDict setObject:[NSArray arrayWithObjects:@"FE", dateTimeString, @"8026000000", nil] forKey:[NSNumber numberWithInt:6]];
    [pos VIPOSBatchSendAPDU:dataDict];
    
}

-(void)apduExample{
    NSString *dateTimeString = @"20140517162926";
    [pos doTrade:dateTimeString delay:60];
}

-(void)claMac{
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *dateTimeString = [dateFormatter stringFromDate:[NSDate date]];
    
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    [dataDict setObject:[NSArray arrayWithObjects:@"15", @"20140517162926", @"3230313430373032313135353337204444424532413846313333324631393339453439413334304333373142433838203239353141324444353430363441453443314433303130323230303030303046203130303030313031303134303232383030353233800000", nil] forKey:[NSNumber numberWithInt:1]];
    
    [dataDict setObject:[NSArray arrayWithObjects:@"13", @"20140704093650", @"3132333435363738393033333333300030303030303030313139393736333933302E353500000000", nil] forKey:[NSNumber numberWithInt:2]];
    
    NSDictionary *a = [pos synVIPOSBatchSendAPDU:dataDict];
    NSLog(@"claMac--------- %@",a);
}

-(void)batchSendAPDU{
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *dateTimeString = [dateFormatter stringFromDate:[NSDate date]];
    
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    [dataDict setObject:[NSArray arrayWithObjects:@"13", @"20140704093650", @"3132333435363738393033333333300030303030303030313139393736333933302E353500000000", nil] forKey:[NSNumber numberWithInt:1]];
    
    NSDictionary *b = [pos synVIPOSBatchSendAPDU:dataDict];
    NSLog(@"batchSendAPDU--------- %@",b);
}

-(void)updateWorkKey:(NSInteger)keyIndex{
    NSString * pik = @"89EEF94D28AA2DC189EEF94D28AA2DC1";
    NSString * pikCheck = @"82E13665B4624DF5";
    
    pik = @"89EEF94D28AA2DC189EEF94D28AA2DC1";
    pikCheck = @"82E13665B4624DF5";
    
    NSString * trk = @"89EEF94D28AA2DC189EEF94D28AA2DC1";
    NSString * trkCheck = @"82E13665B4624DF5";
    
    NSString * mak = @"89EEF94D28AA2DC189EEF94D28AA2DC1";
    NSString * makCheck = @"82E13665B4624DF5";
    [pos udpateWorkKey:pik pinKeyCheck:pikCheck trackKey:trk trackKeyCheck:trkCheck macKey:mak macKeyCheck:makCheck keyIndex:keyIndex];
}

-(void)setMasterKey:(NSInteger)keyIndex{
    NSString *pik = @"89EEF94D28AA2DC189EEF94D28AA2DC1";//111111111111111111111111
    NSString *pikCheck = @"82E13665B4624DF5";
    
    pik = @"F679786E2411E3DEF679786E2411E3DE";//33333333333333333333333333333
    pikCheck = @"ADC67D8473BF2F06";
    [pos setMasterKey:pik checkValue:pikCheck keyIndex:keyIndex];
}

-(void)UpdateEmvCfg{
    NSString *emvAppCfg = [Util byteArray2Hex:[self readLine:@"kernel_app_"]];
    NSString *emvCapkCfg = [Util byteArray2Hex:[self readLine:@"capk_"]];
    
    [pos updateEmvConfig:emvAppCfg emvCapk:emvCapkCfg];
}
- (IBAction)updateEmvCfg:(id)sender {
//    NSString *emvAppCfg = [Util byteArray2Hex:[self readLine:@"kernel_app_"]];
//    NSString *emvCapkCfg = [Util byteArray2Hex:[self readLine:@"capk_"]];
//    
//    [pos updateEmvConfig:emvAppCfg emvCapk:emvCapkCfg];
    NSString *emvAppCfg = @"0000000000000000000000000000000000000000000000000000f4f0f0faaffe8000010f00000000753000000000c350000000009c400000000003e8b6000000000003e8012260d8c8ff80f0300100000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fc50a820000400000000f850a8f8001432000013880000000000f4f0f0faaffe8000010f00000000753000000000c350000000009c400000000003e8b6000000000003e8012260d8c8ff80f03001a0000003330101000000000000000000070020050012345678901234424354455354203132333435363738616263640000000000000000000000015600015600015638333230314943434e4c2d475037333003039f37040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009f0802000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010e0000fc78fcf8f00010000000fc78fcf8f01432000013880000000000f4f0f0faaffe8000010f00000000753000000000c350000000009c400000000003e8b6000000000003e8012260d8c8ff80f03001a0000003330101060000000000000000080020050012345678901234424354455354203132333435363738616263640000000000000000000000015600015600015638333230314943434e4c2d475037333003039f37040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009f0802000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010e0000fc78fcf8f00010000000fc78fcf8f01432000013880000000000f4f0f0faaffe8000010f00000000753000000000c350000000009c400000000003e8b6000000000003e8012260d8c8ff80f03001a0000003330101030000000000000000080020050012345678901234424354455354203132333435363738616263640000000000000000000000015600015600015638333230314943434e4c2d475037333003039f37040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009f0802000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010e0000fc78fcf8f00010000000fc78fcf8f01432000013880000000000f4f0f0faaffe8000010f00000000753000000000c350000000009c400000000003e8b6000000000003e8012260d8c8ff80f03001a0000003330101020000000000000000080020050012345678901234424354455354203132333435363738616263640000000000000000000000015600015600015638333230314943434e4c2d475037333003039f37040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009f0802000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010e0000fc78fcf8f00010000000fc78fcf8f01432000013880000000000f4f0f0faaffe8000010f00000000753000000000c350000000009c400000000003e8b6000000000003e8012260d8c8ff80f03001a0000003330101010000000000000000080020050012345678901234424354455354203132333435363738616263640000000000000000000000015600015600015638333230314943434e4c2d475037333003039f37040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009f0802000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010e0000";
    // pos.readEmvAppConfig();
    
    NSString *emvCapkCfg = @"a3767abd1b6aa69d7f3fbf28c092de9ed1e658ba5f0909af7a1ccd907373b7210fdeb16287ba8e78e1529f443976fd27f991ec67d95e5f4e96b127cab2396a94d6e45cda44ca4c4867570d6b07542f8d4bf9ff97975db9891515e66f525d2b3cbeb6d662bfb6c3f338e93b02142bfc44173a3764c56aadd202075b26dc2f9f7d7ae74bd7d00fd05ee430032663d27a5700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009000000303bb335a8549a03b87ab089d006f60852e4b806020211231a00000033302010100000000b0627dee87864f9c18c13b9a1f025448bf13c58380c91f4ceba9f9bcb214ff8414e9b59d6aba10f941c7331768f47b2127907d857fa39aaf8ce02045dd01619d689ee731c551159be7eb2d51a372ff56b556e5cb2fde36e23073a44ca215d6c26ca68847b388e39520e0026e62294b557d6470440ca0aefc9438c923aec9b2098d6d3a1af5e8b1de36f4b53040109d89b77cafaf70c26c601abdf59eec0fdc8a99089140cd2e817e335175b03b7aa33d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b000000387f0cd7c0e86f38f89a66f8c47071a8b88586f2620211231a00000033303010100000000bc853e6b5365e89e7ee9317c94b02d0abb0dbd91c05a224a2554aa29ed9fcb9d86eb9ccbb322a57811f86188aac7351c72bd9ef196c5a01acef7a4eb0d2ad63d9e6ac2e7836547cb1595c68bcbafd0f6728760f3a7ca7b97301b7e0220184efc4f653008d93ce098c0d93b45201096d1adff4cf1f9fc02af759da27cd6dfd6d789b099f16f378b6100334e63f3d35f3251a5ec78693731f5233519cdb380f5ab8c0f02728e91d469abd0eae0d93b1cc66ce127b29c7d77441a49d09fca5d6d9762fc74c31bb506c8bae3c79ad6c2578775b95956b5370d1d0519e37906b384736233251e8f09ad79dfbe2c6abfadac8e4d8624318c27daf1f8000003f527081cf371dd7e1fd4fa414a665036e0f5e6e520211231a00000033304010100000000b61645edfd5498fb246444037a0fa18c0f101ebd8efa54573ce6e6a7fbf63ed21d66340852b0211cf5eef6a1cd989f66af21a8eb19dbd8dbc3706d135363a0d683d046304f5a836bc1bc632821afe7a2f75da3c50ac74c545a754562204137169663cfcc0b06e67e2109eba41bc67ff20cc8ac80d7b6ee1a95465b3b2657533ea56d92d539e5064360ea4850fed2d1bf000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000090000003ee23b616c95c02652ad18860e48787c079e8e85a20301231a00000033308010100000000eb374dfc5a96b71d2863875eda2eafb96b1b439d3ece0b1826a2672eeefa7990286776f8bd989a15141a75c384dfc14fef9243aab32707659be9e4797a247c2f0b6d99372f384af62fe23bc54bcdc57a9acd1d5585c303f201ef4e8b806afb809db1a3db1cd112ac884f164a67b99c7d6e5a8a6df1d3cae6d7ed3d5be725b2de4ade23fa679bf4eb15a93d8a6e29c7ffa1a70de2e54f593d908a3bf9ebbd760bbfdc8db8b54497e6c5be0e4a4dac29e5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b0000003a075306eab0045baf72cdd33b3b678779de1f52720301231a00000033309010100000000b2ab1b6e9ac55a75adfd5bbc34490e53c4c3381f34e60e7fac21cc2b26dd34462b64a6fae2495ed1dd383b8138bea100ff9b7a111817e7b9869a9742b19e5c9dac56f8b8827f11b05a08eccf9e8d5e85b0f7cfa644eff3e9b796688f38e006deb21e101c01028903a06023ac5aab8635f8e307a53ac742bdce6a283f585f48ef00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000003c88be6b2417c4f941c9371ea35a377158767e4e320301231a0000003330a010100000000cf9fdf46b356378e9af311b0f981b21a1f22f250fb11f55c958709e3c7241918293483289eae688a094c02c344e2999f315a72841f489e24b1ba0056cfab3b479d0e826452375dcdbb67e97ec2aa66f4601d774feaef775accc621bfeb65fb0053fc5f392aa5e1d4c41a4de9ffdfdf1327c4bb874f1f63a599ee3902fe95e729fd78d4234dc7e6cf1ababaa3f6db29b7f05d1d901d2e76a606a8cbffffecbd918fa2d278bdb43b0434f5d45134be1c2781d157d501ff43e5f1c470967cd57ce53b64d82974c8275937c5d8502a1252a8a5d6088a259b694f98648d9af2cb0efd9d943c69f896d49fa39702162acb5af29b90bade005bc157f8000003bd331f9996a490b33c13441066a09ad3feb5f66c20301231a0000003330b010100000000cf9fdf46b356378e9af311b0f981b21a1f22f250fb11f55c958709e3c7241918293483289eae688a094c02c344e2999f315a72841f489e24b1ba0056cfab3b479d0e826452375dcdbb67e97ec2aa66f4601d774feaef775accc621bfeb65fb0053fc5f392aa5e1d4c41a4de9ffdfdf1327c4bb874f1f63a599ee3902fe95e729fd78d4234dc7e6cf1ababaa3f6db29b7f05d1d901d2e76a606a8cbffffecbd918fa2d278bdb43b0434f5d45134be1c2781d157d501ff43e5f1c470967cd57ce53b64d82974c8275937c5d8502a1252a8a5d6088a259b694f98648d9af2cb0efd9d943c69f896d49fa39702162acb5af29b90bade005bc157f8000003c9dbfa54a4ac5c7c947d4c8b5b08d90d0319541520301231a0000003330c010100000000";
    // pos.readEmvCapkConfig();
    //[pos updateEmvConfig:emvAppCfg emvCapk:emvCapkCfg];
    self.textViewLog.text = @"updateemvcfg";
    
}

-(void)testDoTradeNFC{
    
    mTransType = TransactionType_GOODS;
    _currencyCode = @"156";
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    _terminalTime = [dateFormatter stringFromDate:[NSDate date]];
    
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    [dataDict setObject:[NSString stringWithFormat:@"%d",30] forKey:@"timeout"];
    [dataDict setObject:[NSString stringWithFormat:@"%ld",(long)mTransType] forKey:@"transactionType"];
    [dataDict setObject:_terminalTime forKey:@"TransactionTime"];
    [dataDict setObject:[NSString stringWithFormat:@"%d",0] forKey:@"keyIndex"];
    [dataDict setObject:[NSString stringWithFormat:@"%ld",(long)CardTradeMode_SWIPE_TAP_INSERT_CARD] forKey:@"cardTradeMode"];
    [dataDict setObject:[@"0" stringByAppendingString:_currencyCode] forKey:@"currencyCode"];
    [dataDict setObject:@"000139" forKey:@"random"];
    [dataDict setObject:@"1234567890123456" forKey:@"extraData"];
    [dataDict setObject:@"" forKey:@"customDisplayString"];
    [pos doTradeAll:dataDict];
}

//开始 start 按钮事件
- (IBAction)doTrade:(id)sender {
    self.textViewLog.backgroundColor = [UIColor whiteColor];
    self.textViewLog.text = @"Starting...";
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    _terminalTime = [dateFormatter stringFromDate:[NSDate date]];
    mTransType = TransactionType_GOODS;
    _currencyCode = @"704";
   // [pos doCheckCard:30 keyIndex:0];
    [pos setCardTradeMode:CardTradeMode_SWIPE_TAP_INSERT_CARD];
    __weak typeof(self)weakself = self;
    [pos setIsQuickEMV:true block:^(BOOL isSuccess, NSString *stateStr) {
        if (isSuccess) {
            weakself.textViewLog.text = @"set quick emv success";
        }
    }];
    [pos doTrade:30 batchID:@"swipe1"];
    
    //    [pos setCardTradeMode:CardTradeMode_UNALLOWED_LOW_TRADE];
    //[pos doTrade:30];
    /*[pos doUpdateIPEKOperation:@"00" tracksn:@"FFFF000000BB81200000" trackipek:@"F24B13AC6F579B929FBBFE58BC2A0647" trackipekCheckValue:@"CDF80B70C3BBCDDC" emvksn:@"FFFF000000BB81200000" emvipek:@"F24B13AC6F579B929FBBFE58BC2A0647" emvipekcheckvalue:@"CDF80B70C3BBCDDC" pinksn:@"FFFF000000BB81200000" pinipek:@"F24B13AC6F579B929FBBFE58BC2A0647" pinipekcheckValue:@"CDF80B70C3BBCDDC" block:^(BOOL isSuccess, NSString *stateStr) {
        if (isSuccess) {
            self.textViewLog.text = stateStr;
        }
        
        
    }];*/
    //    [pos connectBT:bluetoothAddress];
    //    [self testDoTradeNFC];
    //test demo
    //    [pos cbc_mac_cn_all:24 atype:0 otype:0 data:@"536E04870E6EB939492B782291EE4EF5" delay:5 withResultBlock:^(NSString *str) {
    //        NSLog(@"str: %@",str);
    //    }];
    
    //    [self UpdateEmvCfg];
    //    pos.doTrade("20140517162926", "000139", "1234567890123456", 0, 30);
    //    [pos doTrade:@"20140517162926" randomStr:@"000139" TradeExtraString:@"1234567890123456" keyIndex:0 delay:30];
    
    //    NSString *key = @"536E04870E6EB939492B782291EE4EF5";
    //    NSString *checkValue = @"5427AC35904502AF";
    //    [pos setMasterKey:key checkValue:checkValue];
    //    [pos setMasterKey:key checkValue:checkValue keyIndex:2];
    //    [pos setMasterKey:key checkValue:checkValue keyIndex:1 delay:5];
    //    [pos udpateWorkKey:key pinKeyCheck:checkValue trackKey:key trackKeyCheck:checkValue macKey:key macKeyCheck:checkValue keyIndex:1 delay:5];
    //    NSString *aStr= @"ffeeddccbbaa00998877665544332211";
    //    [pos saveUserData:0 userData:aStr];
    //    [self batchSendAPDU];
    
    //    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    //    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    //    NSString *dateTimeString = [dateFormatter stringFromDate:[NSDate date]];
    //    [pos setPinPadFlag:NO];
    //    [pos doTrade:dateTimeString delay:30];
    
    //    [pos downloadRsaPublicKey:@"A000000333" keyIndex:@"01" keyModule:@"91FE8E7814C8E0BF879C0ECCBD082F18C88DE26537522FE6F4D5A8037256C668B42E020BDB8C9E73D1B856C3E478308FD48F0C8FD3FEE4341C004BDD4EAEF895861F6E708CA935E72E05ADAF9157840288B30D94020254A3B02A477F47B707060E6BA5DFE7AA64AA1CEB01A0F627909A73C9E4ECABD05DCA2184E997D4B0D8C1" keyExponent:@"010001" delay:10];
    
}

- (IBAction)getPosInfo:(id)sender {
    self.textViewLog.backgroundColor = [UIColor yellowColor];
    self.textViewLog.text = @"starting...";
    [pos getQPosInfo];
    
    
}

- (IBAction)resetpos:(id)sender {
    self.textViewLog.backgroundColor = [UIColor whiteColor];
    self.textViewLog.text = @"reset pos ... ";
    [pos resetPosStatus];
    self.textViewLog.text = @"reset pos success!";
}


- (IBAction)getInputAmount:(id)sender {
    //self.textViewLog.backgroundColor = [UIColor whiteColor];
    [pos syncDoTradeLogOperation:0 data:0];
    //self.textViewLog.text = @"Starting...";
//  [pos getInputAmountWithSymbol:@"" len:3 customerDisplay:@"customer" delay:30 block:^(BOOL isSuccess, NSString *amountStr) {
//     if (isSuccess) {
//         float a = [amountStr floatValue];
//         float b = a/100;
//         NSString *ab = [[NSString stringWithFormat:@"%lf",b] substringToIndex:4] ;
//         self.textViewLog.text = ab;
//     }
//  }];
//    
    
    
    //    [pos resetPosStatus];
    
    //    NSString *a = [Util byteArray2Hex:[Util stringFormatTAscii:@"622526XXXXXX5453"] ];
    //    [pos getPin:1 keyIndex:0 maxLen:6 typeFace:@"Pls Input Pin" cardNo:a data:@"" delay:30 withResultBlock:^(BOOL isSuccess, NSDictionary *result) {
    //        NSLog(@"result: %@",result);
    //    }];
    
    

    
    
}
- (IBAction)isCardExist:(id)sender {
    self.textViewLog.backgroundColor = [UIColor whiteColor];
    self.textViewLog.text = @"Starting...";
    
    [pos isCardExist:5 withResultBlock:^(BOOL res) {
        if (res) {
            NSLog(@"isCardExist %d",res);
            self.textViewLog.text = @"1";
            
        }else{
            self.textViewLog.text = @"0";
        }
        
    }];
}


- (NSData*)readLine:(NSString*)name
{
    NSString* file = [[NSBundle mainBundle]pathForResource:name ofType:@".asc"];
    NSFileManager* Manager = [NSFileManager defaultManager];
    NSData* data = [[NSData alloc] init];
    data = [Manager contentsAtPath:file];
    return data;
}


-(void)testUpdatePosFirmware{
    NSData *data = [self readLine:@"A27CAYC"];//read a14upgrader.asc
    [[QPOSService sharedInstance] updatePosFirmware:data address:self.bluetoothAddress];
}

-(void) onUpdatePosFirmwareResult:(UpdateInformationResult)updateInformationResult{
    NSLog(@"%ld",(long)updateInformationResult);
   
    if (updateInformationResult==UpdateInformationResult_UPDATE_SUCCESS) {
        self.textViewLog.text = @"Success";
    }else if(updateInformationResult==UpdateInformationResult_UPDATE_FAIL){
        self.textViewLog.text =  @"Failed";
    }else if(updateInformationResult==UpdateInformationResult_UPDATE_PACKET_LEN_ERROR){
        self.textViewLog.text =  @"Packet len error";
    }
    else if(updateInformationResult==UpdateInformationResult_UPDATE_PACKET_VEFIRY_ERROR){
        self.textViewLog.text =  @"Packer vefiry error";
    }else{
        self.textViewLog.text = @"firmware updating...";
    }

}

-(void)calcMacDouble:(NSString *)cal{
    NSData *aa =  [Util ecb:[Util HexStringToByteArray:cal]];
    NSLog(@"aa = %@",aa);
    [pos calcMacDouble_all:[Util byteArray2Hex:aa] keyIndex:0 delay:10];
}

-(void)calcMacSingle:(NSString *)cal{
    NSData *aa =  [Util ecb:[Util HexStringToByteArray:cal]];
    NSLog(@"aa = %@",aa);
    [pos calcMacSingle_all:[Util byteArray2Hex:aa] delay:10];
}

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        // Update the view.
        [self configureView];
    }
}

- (void)configureView
{
    // Update the user interface for the detail item.
    if (self.detailItem) {
        NSString *aStr = [self.detailItem description];
        self.bluetoothAddress = aStr;
        /*if (pos==nil) {
         pos = [[QPOSService new] initWithBlueTooth:nil BlueToothAddr:self.bluetoothAddress PosEventListener:self];
         }
         */
        //self.detailDescriptionLabel.text = aStr;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self configureView];
    self.btnDisconnect.layer.cornerRadius = 10;
    self.btnStart.layer.cornerRadius = 10;
    self.btnGetPosId.layer.cornerRadius = 10;
    self.btnGetPosInfo.layer.cornerRadius = 10;
    self.btnResetPos.layer.cornerRadius = 10;
    self.btnIsCardExist.layer.cornerRadius = 10;
    if (nil == pos) {
        pos = [QPOSService sharedInstance];
    }
    
    [pos setDelegate:self];
    self.labSDK.text =[@"V" stringByAppendingString:[pos getSdkVersion]];
    
    //    self_queue = dispatch_queue_create("demo.queue", NULL);
    //    [pos setQueue:self_queue];
    
    [pos setQueue:nil];
    if (_detailItem == nil || [_detailItem  isEqual: @""]) {
        self.bluetoothAddress = @"audioType";
    }
    if([self.bluetoothAddress isEqualToString:@"audioType"]){
        [self.btnDisconnect setHidden:YES];
        
        mPosType = PosType_AUDIO;
        [pos setPosType:PosType_AUDIO];
        [pos startAudio];
        MPMusicPlayerController *mpc = [MPMusicPlayerController applicationMusicPlayer];
        mpc.volume = .7;
    }else{
        //        mPosType = PosType_BLUETOOTH;
        //        [pos setPosType:PosType_BLUETOOTH];
        
        //        mPosType = PosType_BLUETOOTH_new;
        //        [pos setPosType:PosType_BLUETOOTH_new];
        
        mPosType = PosType_BLUETOOTH_2mode;
        [pos setPosType:PosType_BLUETOOTH_2mode];
        
        self.textViewLog.text = @"connecting bluetooth...";
        [pos connectBT:self.bluetoothAddress];
        [pos setBTAutoDetecting:true];
    }
    
    
}
- (IBAction)powerOnIcc:(id)sender {
    [pos powerOnIcc];
}
- (IBAction)sendApdu:(id)sender {
    
    //__weak typeof(self) weakSelf = self;
    /*[pos sendApdu:@"00A404000CA00000024300130000000101" block:^(BOOL isSuccess, NSData *result) {
        if (isSuccess) {
            weakSelf.textViewLog.text = [Util byteArray2Hex:result];
            weakSelf.apduStr = result;
        }
        
     }];*/
    
//    NSData *apduData = [pos sycnSendApdu:@"00A404000CA00000024300130000000101"];
//    NSLog(@"%@",apduData);
//    NSData *apduData2 = [pos sycnSendApdu:@"00A404000CA00000024300130000000102"];
 
    
    
   
    
}

// 十六进制转换为普通字符串
+ (NSString *)stringFromHexString:(NSString *)hexString { //
    
    char *myBuffer = (char *)malloc((int)[hexString length] / 2 + 1);
    bzero(myBuffer, [hexString length] / 2 + 1);
    for (int i = 0; i < [hexString length] - 1; i += 2) {
        unsigned int anInt;
        NSString * hexCharStr = [hexString substringWithRange:NSMakeRange(i, 2)];
        NSScanner * scanner = [[NSScanner alloc] initWithString:hexCharStr];
        [scanner scanHexInt:&anInt];
        myBuffer[i / 2] = (char)anInt;
    }
    NSString *unicodeString = [NSString stringWithCString:myBuffer encoding:4];
    NSLog(@"------字符串=======%@",unicodeString);
    return unicodeString; 
    
    
}

-(void) sleepMs: (NSInteger)msec {
    NSTimeInterval sec = (msec / 1000.0f);
    [NSThread sleepForTimeInterval:sec];
}
- (IBAction)setQuickEmv:(id)sender {
     __weak typeof(self)weakself = self;
    [pos setIsQuickEMV:false block:^(BOOL isSuccess, NSString *stateStr) {
        if (isSuccess) {
            weakself.textViewLog.text = stateStr;
        }
    }];
    
}

- (IBAction)updateA27CAYC:(id)sender {
    [self testUpdatePosFirmware];
    self.textViewLog.text = @"firmware updating...";
    [self updateProgress];
    appearTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(progressMethod) userInfo:nil repeats:YES];
}

- (IBAction)updateA19K:(id)sender {
    NSData *data = [self readLine:@"A19K"];//read a14upgrader.asc
    [[QPOSService sharedInstance] updatePosFirmware:data address:self.bluetoothAddress];
    self.textViewLog.text = @"firmware updating...";
    [self updateProgress];
    appearTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(progressMethod) userInfo:nil repeats:YES];
}
-(void)progressMethod{
    dispatch_async(dispatch_get_main_queue(),  ^{
        self_queue = dispatch_queue_create("updateProgress",DISPATCH_QUEUE_CONCURRENT);
        dispatch_sync(self_queue, ^{
            NSInteger updateProgress =  [self getProgress];
            NSString *str = [NSString stringWithFormat:@"%ld",(long)updateProgress];
            float floatString = [str floatValue]/100;
            if(floatString >0&& floatString< 1 ) {
                [progressView setProgress:floatString animated:YES];
                self.updateProgressLab.text = [NSString stringWithFormat:@"progress: %.0f %s",floatString*100,"%"];
            }if (floatString == 1.0) {
                [progressView setTrackTintColor:[UIColor greenColor]];
                [progressView setProgressTintColor:[UIColor greenColor]];
                self.updateProgressLab.text = @"100%";
            }
            
        });
        
    });
    
}
- (IBAction)getQposID:(id)sender {
    [pos getQPosId];
}
-(void)updateProgress{
    //初始化
    progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    progressView.frame = (CGRect){150,110,160,50};
    progressView.trackTintColor = [UIColor blackColor];
    progressView.progress = 0.0;
    progressView.progressTintColor = [UIColor greenColor];
    progressView.progressImage = [UIImage imageNamed:@""];
    [self.view addSubview:progressView];
    
}

-(NSInteger)getProgress{
    return [pos getUpdateProgress];
}



- (IBAction)getTradeLog:(id)sender {
        __weak typeof(self)weakself = self;
        
//        [pos doTradeLogOperation:2 data:0 block:^(BOOL isSuccess,NSInteger markType, NSDictionary *stateStr) {
//            if (isSuccess) {
//                if (markType == 0) {
//                    NSLog(@"decodeData: %@",stateStr);
//                    NSString *formatID = [NSString stringWithFormat:@"Format ID: %@\n",stateStr[@"formatID"]] ;
//                    NSString *maskedPAN = [NSString stringWithFormat:@"Masked PAN: %@\n",stateStr[@"maskedPAN"]];
//                    NSString *expiryDate = [NSString stringWithFormat:@"Expiry Date: %@\n",stateStr[@"expiryDate"]];
//                    NSString *cardHolderName = [NSString stringWithFormat:@"Cardholder Name: %@\n",stateStr[@"cardholderName"]];
//                    //NSString *ksn = [NSString stringWithFormat:@"KSN: %@\n",decodeData[@"ksn"]];
//                    NSString *serviceCode = [NSString stringWithFormat:@"Service Code: %@\n",stateStr[@"serviceCode"]];
//                    //NSString *track1Length = [NSString stringWithFormat:@"Track 1 Length: %@\n",decodeData[@"track1Length"]];
//                    //NSString *track2Length = [NSString stringWithFormat:@"Track 2 Length: %@\n",decodeData[@"track2Length"]];
//                    //NSString *track3Length = [NSString stringWithFormat:@"Track 3 Length: %@\n",decodeData[@"track3Length"]];
//                    //NSString *encTracks = [NSString stringWithFormat:@"Encrypted Tracks: %@\n",decodeData[@"encTracks"]];
//                    NSString *encTrack1 = [NSString stringWithFormat:@"Encrypted Track 1: %@\n",stateStr[@"encTrack1"]];
//                    NSString *encTrack2 = [NSString stringWithFormat:@"Encrypted Track 2: %@\n",stateStr[@"encTrack2"]];
//                    NSString *encTrack3 = [NSString stringWithFormat:@"Encrypted Track 3: %@\n",stateStr[@"encTrack3"]];
//                    //NSString *partialTrack = [NSString stringWithFormat:@"Partial Track: %@",decodeData[@"partialTrack"]];
//                    NSString *pinKsn = [NSString stringWithFormat:@"PIN KSN: %@\n",stateStr[@"pinKsn"]];
//                    NSString *trackksn = [NSString stringWithFormat:@"Track KSN: %@\n",stateStr[@"trackksn"]];
//                    NSString *pinBlock = [NSString stringWithFormat:@"pinBlock: %@\n",stateStr[@"pinblock"]];
//                    NSString *encPAN = [NSString stringWithFormat:@"encPAN: %@\n",stateStr[@"encPAN"]];
//                    
//                    NSString *msg = [NSString stringWithFormat:@"Card Swiped:\n"];
//                    msg = [msg stringByAppendingString:formatID];
//                    msg = [msg stringByAppendingString:maskedPAN];
//                    msg = [msg stringByAppendingString:expiryDate];
//                    msg = [msg stringByAppendingString:cardHolderName];
//                    //msg = [msg stringByAppendingString:ksn];
//                    msg = [msg stringByAppendingString:pinKsn];
//                    msg = [msg stringByAppendingString:trackksn];
//                    msg = [msg stringByAppendingString:serviceCode];
//                    
//                    msg = [msg stringByAppendingString:encTrack1];
//                    msg = [msg stringByAppendingString:encTrack2];
//                    msg = [msg stringByAppendingString:encTrack3];
//                    msg = [msg stringByAppendingString:pinBlock];
//                    msg = [msg stringByAppendingString:encPAN];
//                    NSLog(@"******%@",msg);
//                    weakself.textViewLog.text = msg;
//                    weakself.textViewLog.backgroundColor = [UIColor greenColor];
//                }else if(markType == 03) {
//                    NSLog(@"decodeData: %@",stateStr);
//                    NSString *formatID = [NSString stringWithFormat:@"Format ID: %@\n",stateStr[@"formatID"]] ;
//                    NSString *maskedPAN = [NSString stringWithFormat:@"Masked PAN: %@\n",stateStr[@"maskedPAN"]];
//                    NSString *expiryDate = [NSString stringWithFormat:@"Expiry Date: %@\n",stateStr[@"expiryDate"]];
//                    NSString *cardHolderName = [NSString stringWithFormat:@"Cardholder Name: %@\n",stateStr[@"cardholderName"]];
//                    //NSString *ksn = [NSString stringWithFormat:@"KSN: %@\n",decodeData[@"ksn"]];
//                    NSString *serviceCode = [NSString stringWithFormat:@"Service Code: %@\n",stateStr[@"serviceCode"]];
//                    //NSString *track1Length = [NSString stringWithFormat:@"Track 1 Length: %@\n",decodeData[@"track1Length"]];
//                    //NSString *track2Length = [NSString stringWithFormat:@"Track 2 Length: %@\n",decodeData[@"track2Length"]];
//                    //NSString *track3Length = [NSString stringWithFormat:@"Track 3 Length: %@\n",decodeData[@"track3Length"]];
//                    //NSString *encTracks = [NSString stringWithFormat:@"Encrypted Tracks: %@\n",decodeData[@"encTracks"]];
//                    NSString *encTrack1 = [NSString stringWithFormat:@"Encrypted Track 1: %@\n",stateStr[@"encTrack1"]];
//                    NSString *encTrack2 = [NSString stringWithFormat:@"Encrypted Track 2: %@\n",stateStr[@"encTrack2"]];
//                    NSString *encTrack3 = [NSString stringWithFormat:@"Encrypted Track 3: %@\n",stateStr[@"encTrack3"]];
//                    //NSString *partialTrack = [NSString stringWithFormat:@"Partial Track: %@",decodeData[@"partialTrack"]];
//                    NSString *pinKsn = [NSString stringWithFormat:@"PIN KSN: %@\n",stateStr[@"pinKsn"]];
//                    NSString *trackksn = [NSString stringWithFormat:@"Track KSN: %@\n",stateStr[@"trackksn"]];
//                    NSString *pinBlock = [NSString stringWithFormat:@"pinBlock: %@\n",stateStr[@"pinblock"]];
//                    NSString *encPAN = [NSString stringWithFormat:@"encPAN: %@\n",stateStr[@"encPAN"]];
//                    
//                    NSString *msg = [NSString stringWithFormat:@"Tap Card:\n"];
//                    msg = [msg stringByAppendingString:formatID];
//                    msg = [msg stringByAppendingString:maskedPAN];
//                    msg = [msg stringByAppendingString:expiryDate];
//                    msg = [msg stringByAppendingString:cardHolderName];
//                    //msg = [msg stringByAppendingString:ksn];
//                    msg = [msg stringByAppendingString:pinKsn];
//                    msg = [msg stringByAppendingString:trackksn];
//                    msg = [msg stringByAppendingString:serviceCode];
//                    
//                    msg = [msg stringByAppendingString:encTrack1];
//                    msg = [msg stringByAppendingString:encTrack2];
//                    msg = [msg stringByAppendingString:encTrack3];
//                    msg = [msg stringByAppendingString:pinBlock];
//                    msg = [msg stringByAppendingString:encPAN];
//                    weakself.textViewLog.text = msg;
//                    weakself.textViewLog.backgroundColor = [UIColor greenColor];
//                }else{
//                    
//                    
//                    NSString * data = [stateStr valueForKey:@"log"];
//                    weakself.textViewLog.text = data;
//                    weakself.textViewLog.backgroundColor = [UIColor greenColor];
//                    
//                }
//                
//            }
//        }];
    
    NSDictionary * doTradeLogDictionary = [pos syncDoTradeLogOperation:2 data:2];
    NSLog(@"%@",doTradeLogDictionary);
    //[pos doTrade:30];
    //  NSLog(@"doTradeLogDictionary = %@",doTradeLogDictionary);
   
};

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)viewDidDisappear:(BOOL)animated{
    
    if (mPosType == PosType_AUDIO) {
        NSLog(@"viewDidDisappear stop audio");
        //        [pos resetPosStatus];
        [pos stopAudio];
    }else if(mPosType == PosType_BLUETOOTH || mPosType == PosType_BLUETOOTH_new || mPosType == PosType_BLUETOOTH_2mode){
        NSLog(@"viewDidDisappear disconnect buluetooth");
        [pos disconnectBT];
    }
    
}

typedef NS_ENUM(NSInteger, MSG_PRO) {
    MSG_DOTRADE,
};

-(void)appMsg:(MSG_PRO)index{
    switch (index) {
        case MSG_DOTRADE:
        {
            
            dispatch_async(dispatch_get_main_queue(),  ^{
                [pos doTrade:30];
            });
        }
            break;
            
        default:
            break;
    }
}
- (IBAction)clearAllAIDs:(id)sender {
    NSArray * arr = @[];
    NSMutableArray *mArr = [[NSMutableArray alloc]initWithArray:arr];
    [pos updateEmvAPP:EMVOperation_clear data:mArr  block:^(BOOL isSuccess, NSString *stateStr) {
        if (isSuccess) {
           
            self.textViewLog.text = stateStr;
            self.textViewLog.backgroundColor = [UIColor greenColor];
            [self.updateEMVapp2 setEnabled:YES];
        }else{
            self.textViewLog.text = @"clear aids fail";
        }
    }];
}
- (IBAction)addACertainAID:(id)sender {
    
    NSMutableDictionary * emvAppDict = [pos getEMVAPPDict];
#pragma mark aid1
    NSString *AID1 = @"A0000006351010";
    NSString * n1  =[[emvAppDict valueForKey:@"Application_Identifier_AID_terminal"] stringByAppendingString:[self getEMVStr:AID1]];
    NSString * n2  = [[emvAppDict valueForKey:@"TAC_Default"] stringByAppendingString:[self getEMVStr:@"FCF8FCF800"]];
    NSString * n3  = [[emvAppDict valueForKey:@"TAC_Online"] stringByAppendingString:[self getEMVStr:@"FCF8FCF800"]];
    NSString * n4  = [[emvAppDict valueForKey:@"TAC_Denial"] stringByAppendingString:[self getEMVStr:@"0000000000"]];
    NSString * n5  = [[emvAppDict valueForKey:@"Target_Percentage_to_be_Used_for_Random_Selection"] stringByAppendingString:[self getEMVStr:@"00"]];
    NSString * n6 = [[emvAppDict valueForKey:@"Maximum_Target_Percentage_to_be_used_for_Biased_Random_Selection"] stringByAppendingString:[self getEMVStr:@"00"]];
    NSString * n7  = [[emvAppDict valueForKey:@"Threshold_Value_BiasedRandom_Selection"] stringByAppendingString:[self getEMVStr:[self getHexFromIntStr:@"999999"]]];
    NSString * n8  = [[emvAppDict valueForKey:@"Terminal_Floor_Limit"] stringByAppendingString:[self getEMVStr:@"00000000"]];
    NSString * n9 = [[emvAppDict valueForKey:@"Application_Version_Number"] stringByAppendingString:[self getEMVStr:@"0096"]];
    NSString * n10  = [[emvAppDict valueForKey:@"Point_of_Service_POS_EntryMode"] stringByAppendingString:[self getEMVStr:@"05"]];
    NSString * n11  = [[emvAppDict valueForKey:@"Acquirer_Identifier"] stringByAppendingString:[self getEMVStr:@"000000008080"]];
    NSString * n12 = [[emvAppDict valueForKey:@"Merchant_Category_Code"] stringByAppendingString:[self getEMVStr:@"1234"]];
    NSString * merchantID = @"BCTEST 12345678";
    NSString * n13  = [[emvAppDict valueForKey:@"Merchant_Identifier"] stringByAppendingString:[self getEMVStr:[self getHexFromStr:merchantID]]];
    NSString* MerchantNameAndLocation = @"abcd";
    NSString * n14  = [[emvAppDict valueForKey:@"Merchant_Name_and_Location"] stringByAppendingString:[self getEMVStr:[[self getHexFromStr:MerchantNameAndLocation] stringByAppendingString:@"0000000000000000000000"]]];
    
    NSString * n15  = [[emvAppDict valueForKey:@"Transaction_Currency_Code"] stringByAppendingString:[self getEMVStr:@"0608"]];
    NSString * n16 = [[emvAppDict valueForKey:@"Transaction_Currency_Exponent"] stringByAppendingString:[self getEMVStr:@"02"]];
    NSString * n17  = [[emvAppDict valueForKey:@"Transaction_Reference_Currency_Code"] stringByAppendingString:[self getEMVStr:@"0608"]];
    NSString * n18 = [[emvAppDict valueForKey:@"Transaction_Reference_Currency_Exponent"] stringByAppendingString:[self getEMVStr:@"02"]];
    NSString * n19  = [[emvAppDict valueForKey:@"Terminal_Country_Code"] stringByAppendingString:[self getEMVStr:@"0608"]];
    NSString * n20 = [[emvAppDict valueForKey:@"Interface_Device_IFD_Serial_Number"] stringByAppendingString:[self getEMVStr:[self getHexFromStr:@"83201ICC"]]];
    NSString * n21 = [[emvAppDict valueForKey:@"Terminal_Identification"] stringByAppendingString:[self getEMVStr:[self getHexFromStr:@"NL-GP730"]]];
    NSString * n22  = [[emvAppDict valueForKey:@"Default_DDOL"] stringByAppendingString:[self getEMVStr:@"9f3704"]];
    NSString * n23 = [[emvAppDict valueForKey:@"Default_Tdol"] stringByAppendingString:[self getEMVStr:@"9F1A0295059A039C01"]];
    NSString * n24  = [[emvAppDict valueForKey:@"Application_Selection_Indicator"] stringByAppendingString:[self getEMVStr:@"01"]];
    //    NSString * n25  =[AID1  stringByAppendingString:[[emvCapkDict valueForKey:@"Contactless_CVM_Required_limit"] stringByAppendingString:[self getEMVStr:@"00000019999928"]]];
    
#pragma mark aid2
    NSString *AID2 = @"A0000000044010";
    NSString * o1  =[[emvAppDict valueForKey:@"Application_Identifier_AID_terminal"] stringByAppendingString:[self getEMVStr:AID2]];
    NSString * o2 =[[emvAppDict valueForKey:@"TAC_Default"] stringByAppendingString:[self getEMVStr:@"FC5080A000"]];
    NSString * o3  =[[emvAppDict valueForKey:@"TAC_Online"] stringByAppendingString:[self getEMVStr:@"FC5080F800"]];
    NSString * o4  =[[emvAppDict valueForKey:@"TAC_Denial"] stringByAppendingString:[self getEMVStr:@"0000000000"]];
    NSString * o5 =[[emvAppDict valueForKey:@"Target_Percentage_to_be_Used_for_Random_Selection"] stringByAppendingString:[self getEMVStr:@"00"]];
    NSString * o6  =[[emvAppDict valueForKey:@"Maximum_Target_Percentage_to_be_used_for_Biased_Random_Selection"] stringByAppendingString:[self getEMVStr:@"00"]];
    NSString * o7  =[[emvAppDict valueForKey:@"Threshold_Value_BiasedRandom_Selection"] stringByAppendingString:[self getEMVStr:[self getHexFromIntStr:@"999999"]]];
    NSString * o8  =[[emvAppDict valueForKey:@"Terminal_Floor_Limit"] stringByAppendingString:[self getEMVStr:@"00000000"]];
    NSString * o9 =[[emvAppDict valueForKey:@"Application_Version_Number"] stringByAppendingString:[self getEMVStr:@"0002"]];
    NSString * o10 =[[emvAppDict valueForKey:@"Point_of_Service_POS_EntryMode"] stringByAppendingString:[self getEMVStr:@"05"]];
    NSString * o11  =[[emvAppDict valueForKey:@"Acquirer_Identifier"] stringByAppendingString:[self getEMVStr:@"000000008080"]];
    NSString * o12 =[[emvAppDict valueForKey:@"Merchant_Category_Code"] stringByAppendingString:[self getEMVStr:@"1234"]];
    NSString * o13  =[[emvAppDict valueForKey:@"Merchant_Identifier"] stringByAppendingString:[self getEMVStr:[self getHexFromStr: @"BCTEST 12345678"]]];
    NSString * o14  =[[emvAppDict valueForKey:@"Merchant_Name_and_Location"] stringByAppendingString:[self getEMVStr:[[self getHexFromStr:@"abcd"] stringByAppendingString:@"0000000000000000000000"]]];
    NSString * o15  = [[emvAppDict valueForKey:@"Transaction_Currency_Code"] stringByAppendingString:[self getEMVStr:@"0608"]];
    NSString * o16 = [[emvAppDict valueForKey:@"Transaction_Currency_Exponent"] stringByAppendingString:[self getEMVStr:@"02"]];
    NSString * o17  = [[emvAppDict valueForKey:@"Transaction_Reference_Currency_Code"] stringByAppendingString:[self getEMVStr:@"0608"]];
    NSString * o18 = [[emvAppDict valueForKey:@"Transaction_Reference_Currency_Exponent"] stringByAppendingString:[self getEMVStr:@"02"]];
    NSString * o19  = [[emvAppDict valueForKey:@"Terminal_Country_Code"] stringByAppendingString:[self getEMVStr:@"0608"]];
    NSString * o20  = [[emvAppDict valueForKey:@"Interface_Device_IFD_Serial_Number"] stringByAppendingString:[self getEMVStr:[self getHexFromStr:@"83201ICC"]]];
    NSString * o21 =[[emvAppDict valueForKey:@"Terminal_Identification"] stringByAppendingString:[self getEMVStr:[self getHexFromStr:@"NL-GP730"]]];
    NSString * o22  =[[emvAppDict valueForKey:@"Default_DDOL"] stringByAppendingString:[self getEMVStr:@"9f3704"]];
    NSString * o23 =[[emvAppDict valueForKey:@"Default_Tdol"] stringByAppendingString:[self getEMVStr:@"9F1A0295059A039C01"]];
    NSString * o24  =[[emvAppDict valueForKey:@"Application_Selection_Indicator"] stringByAppendingString:[self getEMVStr:@"01"]];
    
    
    
#pragma mark aid3
    NSString *AID3 = @"A0000000031010";
    NSString * p1  = [[emvAppDict valueForKey:@"Application_Identifier_AID_terminal"] stringByAppendingString:[self getEMVStr:AID3]];
    NSString * p2  = [[emvAppDict valueForKey:@"TAC_Default"] stringByAppendingString:[self getEMVStr:@"DC4000A800"]];
    NSString * p3  = [[emvAppDict valueForKey:@"TAC_Online"] stringByAppendingString:[self getEMVStr:@"DC4004F800"]];
    NSString * p4  = [[emvAppDict valueForKey:@"TAC_Denial"] stringByAppendingString:[self getEMVStr:@"0010000000"]];
    NSString * p5  = [[emvAppDict valueForKey:@"Target_Percentage_to_be_Used_for_Random_Selection"] stringByAppendingString:[self getEMVStr:@"00"]];
    NSString * p6  = [[emvAppDict valueForKey:@"Maximum_Target_Percentage_to_be_used_for_Biased_Random_Selection"] stringByAppendingString:[self getEMVStr:@"00"]];
    NSString * p7  = [[emvAppDict valueForKey:@"Threshold_Value_BiasedRandom_Selection"] stringByAppendingString:[self getEMVStr:[self getHexFromIntStr:@"500"]]];
    NSString * p8  = [[emvAppDict valueForKey:@"Terminal_Floor_Limit"] stringByAppendingString:[self getEMVStr:@"00000000"]];
    NSString * p9  = [[emvAppDict valueForKey:@"Application_Version_Number"] stringByAppendingString:[self getEMVStr:@"008C"]];
    NSString * p10 = [[emvAppDict valueForKey:@"Point_of_Service_POS_EntryMode"] stringByAppendingString:[self getEMVStr:@"05"]];
    NSString * p11  = [[emvAppDict valueForKey:@"Acquirer_Identifier"] stringByAppendingString:[self getEMVStr:@"001234567890"]];
    NSString * p12  = [[emvAppDict valueForKey:@"Merchant_Category_Code"] stringByAppendingString:[self getEMVStr:@"1234"]];
    NSString * p13  = [[emvAppDict valueForKey:@"Merchant_Identifier"] stringByAppendingString:[self getEMVStr:[self getHexFromStr:@"BCTEST 12345678"]]];
    
    NSString * p14  = [[emvAppDict valueForKey:@"Merchant_Name_and_Location"] stringByAppendingString:[self getEMVStr:[[self getHexFromStr:@"abcd"] stringByAppendingString:@"0000000000000000000000"]]];
    NSString * p15  = [[emvAppDict valueForKey:@"Transaction_Currency_Code"] stringByAppendingString:[self getEMVStr:@"0608"]];
    NSString * p16 = [[emvAppDict valueForKey:@"Transaction_Currency_Exponent"] stringByAppendingString:[self getEMVStr:@"00"]];
    NSString * p17  = [[emvAppDict valueForKey:@"Transaction_Reference_Currency_Code"] stringByAppendingString:[self getEMVStr:@"0608"]];
    NSString * p18 = [[emvAppDict valueForKey:@"Transaction_Reference_Currency_Exponent"] stringByAppendingString:[self getEMVStr:@"00"]];
    NSString * p19  = [[emvAppDict valueForKey:@"Terminal_Country_Code"] stringByAppendingString:[self getEMVStr:@"0608"]];
    NSString * p20  = [[emvAppDict valueForKey:@"Interface_Device_IFD_Serial_Number"] stringByAppendingString:[self getEMVStr:[self getHexFromStr:@"83201ICC"]]];
    NSString * p21 = [[emvAppDict valueForKey:@"Terminal_Identification"] stringByAppendingString:[self getEMVStr:[self getHexFromStr:@"NL-GP730"]]];
    NSString * p22  = [[emvAppDict valueForKey:@"Default_DDOL"] stringByAppendingString:[self getEMVStr:@"9f3704"]];
    NSString * p23 = [[emvAppDict valueForKey:@"Default_Tdol"] stringByAppendingString:[self getEMVStr:@"9F1A0295059A039C01"]];
    NSString * p24  = [[emvAppDict valueForKey:@"Application_Selection_Indicator"] stringByAppendingString:[self getEMVStr:@"01"]];
    
#pragma mark aid4
    NSString *AID4 = @"A0000000032010";
    NSString * q1  = [[emvAppDict valueForKey:@"Application_Identifier_AID_terminal"] stringByAppendingString:[self getEMVStr:AID4]];
    NSString * q2 = [[emvAppDict valueForKey:@"TAC_Default"] stringByAppendingString:[self getEMVStr:@"DC4000A800"]];
    NSString * q3  = [[emvAppDict valueForKey:@"TAC_Online"] stringByAppendingString:[self getEMVStr:@"DC4004F800"]];
    NSString * q4  = [[emvAppDict valueForKey:@"TAC_Denial"] stringByAppendingString:[self getEMVStr:@"0010000000"]];
    NSString * q5  = [[emvAppDict valueForKey:@"Target_Percentage_to_be_Used_for_Random_Selection"] stringByAppendingString:[self getEMVStr:@"00"]];
    NSString * q6  = [[emvAppDict valueForKey:@"Maximum_Target_Percentage_to_be_used_for_Biased_Random_Selection"] stringByAppendingString:[self getEMVStr:@"00"]];
    NSString * q7  = [[emvAppDict valueForKey:@"Threshold_Value_BiasedRandom_Selection"] stringByAppendingString:[self getEMVStr:[self getHexFromIntStr:@"500"]]];
    NSString * q8  = [[emvAppDict valueForKey:@"Terminal_Floor_Limit"] stringByAppendingString:[self getEMVStr:@"00000000"]];
    NSString * q9  = [[emvAppDict valueForKey:@"Application_Version_Number"] stringByAppendingString:[self getEMVStr:@"008C"]];
    NSString * q10 = [[emvAppDict valueForKey:@"Point_of_Service_POS_EntryMode"] stringByAppendingString:[self getEMVStr:@"05"]];
    NSString * q11  = [[emvAppDict valueForKey:@"Acquirer_Identifier"] stringByAppendingString:[self getEMVStr:@"001234567890"]];
    NSString * q12  = [[emvAppDict valueForKey:@"Merchant_Category_Code"] stringByAppendingString:[self getEMVStr:@"1234"]];
    NSString * merchantID4 = @"BCTEST 12345678";
    NSString * q13  = [[emvAppDict valueForKey:@"Merchant_Identifier"] stringByAppendingString:[self getEMVStr:[self getHexFromStr:merchantID4]]];
    NSString* MerchantNameAndLocation4 = @"abcd";
    
    NSString * q14  = [[emvAppDict valueForKey:@"Merchant_Name_and_Location"] stringByAppendingString:[self getEMVStr: [[self getHexFromStr:MerchantNameAndLocation4] stringByAppendingString:@"0000000000000000000000"]]];
    NSString * q15  = [[emvAppDict valueForKey:@"Transaction_Currency_Code"] stringByAppendingString:[self getEMVStr:@"0608"]];
    NSString * q16 = [[emvAppDict valueForKey:@"Transaction_Currency_Exponent"] stringByAppendingString:[self getEMVStr:@"00"]];
    NSString * q17  = [[emvAppDict valueForKey:@"Transaction_Reference_Currency_Code"] stringByAppendingString:[self getEMVStr:@"0608"]];
    NSString * q18 = [[emvAppDict valueForKey:@"Transaction_Reference_Currency_Exponent"] stringByAppendingString:[self getEMVStr:@"00"]];
    NSString * q19  = [[emvAppDict valueForKey:@"Terminal_Country_Code"] stringByAppendingString:[self getEMVStr:@"0608"]];
    NSString * q20  = [[emvAppDict valueForKey:@"Interface_Device_IFD_Serial_Number"] stringByAppendingString:[self getEMVStr:[self getHexFromStr:@"83201ICC"]]];
    NSString * q21 = [[emvAppDict valueForKey:@"Terminal_Identification"] stringByAppendingString:[self getEMVStr:[self getHexFromStr:@"NL-GP730"]]];
    NSString * q22  = [[emvAppDict valueForKey:@"Default_DDOL"] stringByAppendingString:[self getEMVStr:@"9f3704"]];
    NSString * q23 = [[emvAppDict valueForKey:@"Default_Tdol"] stringByAppendingString:[self getEMVStr:@"9F1A0295059A039C01"]];
    NSString * q24  = [[emvAppDict valueForKey:@"Application_Selection_Indicator"] stringByAppendingString:[self getEMVStr:@"01"]];
    
#pragma mark aid5
    NSString *AID5 = @"A0000000033010";
    NSString * r1  =  [[emvAppDict valueForKey:@"Application_Identifier_AID_terminal"] stringByAppendingString:[self getEMVStr:AID5]];
    NSString * r2  =  [[emvAppDict valueForKey:@"TAC_Default"] stringByAppendingString:[self getEMVStr:@"DC4000A800"]];
    NSString * r3  =  [[emvAppDict valueForKey:@"TAC_Online"] stringByAppendingString:[self getEMVStr:@"DC4004F800"]];
    NSString * r4  =  [[emvAppDict valueForKey:@"TAC_Denial"] stringByAppendingString:[self getEMVStr:@"0010000000"]];
    NSString * r5  =  [[emvAppDict valueForKey:@"Target_Percentage_to_be_Used_for_Random_Selection"] stringByAppendingString:[self getEMVStr:@"00"]];
    NSString * r6  =  [[emvAppDict valueForKey:@"Maximum_Target_Percentage_to_be_used_for_Biased_Random_Selection"] stringByAppendingString:[self getEMVStr:@"00"]];
    NSString * r7  =  [[emvAppDict valueForKey:@"Threshold_Value_BiasedRandom_Selection"] stringByAppendingString:[self getEMVStr:[self getHexFromIntStr:@"500"]]];
    NSString * r8  =  [[emvAppDict valueForKey:@"Terminal_Floor_Limit"] stringByAppendingString:[self getEMVStr:@"00000000"]];
    NSString * r9  =  [[emvAppDict valueForKey:@"Application_Version_Number"] stringByAppendingString:[self getEMVStr:@"008C"]];
    NSString * r10  =  [[emvAppDict valueForKey:@"Point_of_Service_POS_EntryMode"] stringByAppendingString:[self getEMVStr:@"05"]];
    NSString * r11  =  [[emvAppDict valueForKey:@"Acquirer_Identifier"] stringByAppendingString:[self getEMVStr:@"001234567890"]];
    NSString * r12  =  [[emvAppDict valueForKey:@"Merchant_Category_Code"] stringByAppendingString:[self getEMVStr:@"1234"]];
    NSString * r13  =  [[emvAppDict valueForKey:@"Merchant_Identifier"] stringByAppendingString:[self getEMVStr:[self getHexFromStr:@"BCTEST 12345678"]]];
    
    NSString * r14  =  [[emvAppDict valueForKey:@"Merchant_Name_and_Location"] stringByAppendingString:[self getEMVStr:[[self getHexFromStr:@"abcd"] stringByAppendingString:@"0000000000000000000000"]]];
    NSString * r15  =  [[emvAppDict valueForKey:@"Transaction_Currency_Code"] stringByAppendingString:[self getEMVStr:@"0608"]];
    NSString * r16 =  [[emvAppDict valueForKey:@"Transaction_Currency_Exponent"] stringByAppendingString:[self getEMVStr:@"00"]];
    NSString * r17  =  [[emvAppDict valueForKey:@"Transaction_Reference_Currency_Code"] stringByAppendingString:[self getEMVStr:@"0608"]];
    NSString * r18 =  [[emvAppDict valueForKey:@"Transaction_Reference_Currency_Exponent"] stringByAppendingString:[self getEMVStr:@"00"]];
    NSString * r19  =  [[emvAppDict valueForKey:@"Terminal_Country_Code"] stringByAppendingString:[self getEMVStr:@"0608"]];
    NSString * r20  =  [[emvAppDict valueForKey:@"Interface_Device_IFD_Serial_Number"] stringByAppendingString:[self getEMVStr:[self getHexFromStr:@"83201ICC"]]];
    NSString * r21 =  [[emvAppDict valueForKey:@"Terminal_Identification"] stringByAppendingString:[self getEMVStr:[self getHexFromStr:@"NL-GP730"]]];
    NSString * r22  =  [[emvAppDict valueForKey:@"Default_DDOL"] stringByAppendingString:[self getEMVStr:@"9f3704"]];
    NSString * r23 =  [[emvAppDict valueForKey:@"Default_Tdol"] stringByAppendingString:[self getEMVStr:@"9F1A0295059A039C01"]];
    NSString * r24  =  [[emvAppDict valueForKey:@"Application_Selection_Indicator"] stringByAppendingString:[self getEMVStr:@"01"]];
    
    
    
#pragma mark aid6
    NSString *AID6 = @"A0000000041010";
    NSString * s1  = [[emvAppDict valueForKey:@"Application_Identifier_AID_terminal"] stringByAppendingString:[self getEMVStr:AID6]];
    NSString * s2  = [[emvAppDict valueForKey:@"TAC_Default"] stringByAppendingString:[self getEMVStr:@"FC50BC2000"]];
    NSString * s3  = [[emvAppDict valueForKey:@"TAC_Online"] stringByAppendingString:[self getEMVStr:@"FC50BCF800"]];
    NSString * s4  = [[emvAppDict valueForKey:@"TAC_Denial"] stringByAppendingString:[self getEMVStr:@"0000000000"]];
    NSString * s5  = [[emvAppDict valueForKey:@"Target_Percentage_to_be_Used_for_Random_Selection"] stringByAppendingString:[self getEMVStr:@"00"]];
    NSString * s6  = [[emvAppDict valueForKey:@"Maximum_Target_Percentage_to_be_used_for_Biased_Random_Selection"] stringByAppendingString:[self getEMVStr:@"00"]];
    NSString * s7  = [[emvAppDict valueForKey:@"Threshold_Value_BiasedRandom_Selection"] stringByAppendingString:[self getEMVStr:[self getHexFromIntStr:@"5000"]]];
    NSString * s8  = [[emvAppDict valueForKey:@"Terminal_Floor_Limit"] stringByAppendingString:[self getEMVStr:@"00000000"]];
    NSString * s9  = [[emvAppDict valueForKey:@"Application_Version_Number"] stringByAppendingString:[self getEMVStr:@"0002"]];
    NSString * s10  = [[emvAppDict valueForKey:@"Point_of_Service_POS_EntryMode"] stringByAppendingString:[self getEMVStr:@"05"]];
    NSString * s11  = [[emvAppDict valueForKey:@"Acquirer_Identifier"] stringByAppendingString:[self getEMVStr:@"001234567890"]];
    NSString * s12  = [[emvAppDict valueForKey:@"Merchant_Category_Code"] stringByAppendingString:[self getEMVStr:@"1234"]];
    
    NSString * s13  = [[emvAppDict valueForKey:@"Merchant_Identifier"] stringByAppendingString:[self getEMVStr:[self getHexFromStr:@"BCTEST 12345678"]]];
    
    NSString * s14  = [[emvAppDict valueForKey:@"Merchant_Name_and_Location"] stringByAppendingString:[self getEMVStr:[[self getHexFromStr:@"abcd"] stringByAppendingString:@"0000000000000000000000"]]];
    NSString * s15  = [[emvAppDict valueForKey:@"Transaction_Currency_Code"] stringByAppendingString:[self getEMVStr:@"0608"]];
    NSString * s16 = [[emvAppDict valueForKey:@"Transaction_Currency_Exponent"] stringByAppendingString:[self getEMVStr:@"00"]];
    NSString * s17  = [[emvAppDict valueForKey:@"Transaction_Reference_Currency_Code"] stringByAppendingString:[self getEMVStr:@"0608"]];
    NSString * s18 = [[emvAppDict valueForKey:@"Transaction_Reference_Currency_Exponent"] stringByAppendingString:[self getEMVStr:@"00"]];
    NSString * s19  = [[emvAppDict valueForKey:@"Terminal_Country_Code"] stringByAppendingString:[self getEMVStr:@"0608"]];
    NSString * s20 = [[emvAppDict valueForKey:@"Interface_Device_IFD_Serial_Number"] stringByAppendingString:[self getEMVStr:[self getHexFromStr:@"83201ICC"]]];
    NSString * s21 = [[emvAppDict valueForKey:@"Terminal_Identification"] stringByAppendingString:[self getEMVStr:[self getHexFromStr:@"NL-GP730"]]];
    NSString * s22 = [[emvAppDict valueForKey:@"Default_DDOL"] stringByAppendingString:[self getEMVStr:@"9f3704"]];
    NSString * s23 = [[emvAppDict valueForKey:@"Default_Tdol"] stringByAppendingString:[self getEMVStr:@"9F02065F2A029A039C0195059F3704"]];
    NSString * s24  = [[emvAppDict valueForKey:@"Application_Selection_Indicator"] stringByAppendingString:[self getEMVStr:@"01"]];
    
#pragma mark aid7
    
    NSString *AID7 = @"A00000002501";
    NSString * t1  = [[emvAppDict valueForKey:@"Application_Identifier_AID_terminal"] stringByAppendingString:[self getEMVStr:AID7]];
    NSString * t2  = [[emvAppDict valueForKey:@"TAC_Default"] stringByAppendingString:[self getEMVStr:@"CC00008000"]];
    NSString * t3 = [[emvAppDict valueForKey:@"TAC_Online"] stringByAppendingString:[self getEMVStr:@"CC00008000"]];
    NSString * t4 = [[emvAppDict valueForKey:@"TAC_Denial"] stringByAppendingString:[self getEMVStr:@"0000000000"]];
    NSString * t5  = [[emvAppDict valueForKey:@"Target_Percentage_to_be_Used_for_Random_Selection"] stringByAppendingString:[self getEMVStr:@"00"]];
    NSString * t6  = [[emvAppDict valueForKey:@"Maximum_Target_Percentage_to_be_used_for_Biased_Random_Selection"] stringByAppendingString:[self getEMVStr:@"00"]];
    NSString * t7  = [[emvAppDict valueForKey:@"Threshold_Value_BiasedRandom_Selection"] stringByAppendingString:[self getEMVStr:[self getHexFromIntStr:@"5000"]]];
    NSString * t8 = [[emvAppDict valueForKey:@"Terminal_Floor_Limit"] stringByAppendingString:[self getEMVStr:@"00000000"]];
    NSString * t9 = [[emvAppDict valueForKey:@"Application_Version_Number"] stringByAppendingString:[self getEMVStr:@"0001"]];
    NSString * t10  = [[emvAppDict valueForKey:@"Point_of_Service_POS_EntryMode"] stringByAppendingString:[self getEMVStr:@"05"]];
    NSString * t11  = [[emvAppDict valueForKey:@"Acquirer_Identifier"] stringByAppendingString:[self getEMVStr:@"001234567890"]];
    NSString * t12 = [[emvAppDict valueForKey:@"Merchant_Category_Code"] stringByAppendingString:[self getEMVStr:@"1234"]];
    
    NSString * t13  = [[emvAppDict valueForKey:@"Merchant_Identifier"] stringByAppendingString:[self getEMVStr:[self getHexFromStr:@"BCTEST 12345678"]]];
    
    NSString * t14  = [[emvAppDict valueForKey:@"Merchant_Name_and_Location"] stringByAppendingString:[self getEMVStr:[[self getHexFromStr:@"abcd"] stringByAppendingString:@"0000000000000000000000"]]];
    NSString * t15  = [[emvAppDict valueForKey:@"Transaction_Currency_Code"] stringByAppendingString:[self getEMVStr:@"0608"]];
    NSString * t16 = [[emvAppDict valueForKey:@"Transaction_Currency_Exponent"] stringByAppendingString:[self getEMVStr:@"00"]];
    NSString * t17  = [[emvAppDict valueForKey:@"Transaction_Reference_Currency_Code"] stringByAppendingString:[self getEMVStr:@"0608"]];
    NSString * t18 = [[emvAppDict valueForKey:@"Transaction_Reference_Currency_Exponent"] stringByAppendingString:[self getEMVStr:@"00"]];
    NSString * t19 = [[emvAppDict valueForKey:@"Terminal_Country_Code"] stringByAppendingString:[self getEMVStr:@"0608"]];
    NSString * t20  = [[emvAppDict valueForKey:@"Interface_Device_IFD_Serial_Number"] stringByAppendingString:[self getEMVStr:[self getHexFromStr:@"83201ICC"]]];
    NSString * t21 = [[emvAppDict valueForKey:@"Terminal_Identification"] stringByAppendingString:[self getEMVStr:[self getHexFromStr:@"NL-GP730"]]];
    NSString * t22  = [[emvAppDict valueForKey:@"Default_DDOL"] stringByAppendingString:[self getEMVStr:@"9f3704"]];
    NSString * t23 = [[emvAppDict valueForKey:@"Default_Tdol"] stringByAppendingString:[self getEMVStr:@"9F1A0295059A039C01"]];
    NSString * t24  = [[emvAppDict valueForKey:@"Application_Selection_Indicator"] stringByAppendingString:[self getEMVStr:@"01"]];
    
    
#pragma mark aid8
    NSString *AID8 = @"A0000000651010";
    NSString * u1  = [[emvAppDict valueForKey:@"Application_Identifier_AID_terminal"] stringByAppendingString:[self getEMVStr:AID8]];
    NSString * u2 = [[emvAppDict valueForKey:@"TAC_Default"] stringByAppendingString:[self getEMVStr:@"FFFFFFFFFF"]];
    NSString * u3 = [[emvAppDict valueForKey:@"TAC_Online"] stringByAppendingString:[self getEMVStr:@"FFFFFFFFFF"]];
    NSString * u4  = [[emvAppDict valueForKey:@"TAC_Denial"] stringByAppendingString:[self getEMVStr:@"0010000000"]];
    NSString * u5  = [[emvAppDict valueForKey:@"Target_Percentage_to_be_Used_for_Random_Selection"] stringByAppendingString:[self getEMVStr:@"00"]];
    NSString * u6  = [[emvAppDict valueForKey:@"Maximum_Target_Percentage_to_be_used_for_Biased_Random_Selection"] stringByAppendingString:[self getEMVStr:@"00"]];
    NSString * u7  = [[emvAppDict valueForKey:@"Threshold_Value_BiasedRandom_Selection"] stringByAppendingString:[self getEMVStr:[self getHexFromIntStr:@"5000"]]];
    NSString * u8  = [[emvAppDict valueForKey:@"Terminal_Floor_Limit"] stringByAppendingString:[self getEMVStr:@"00000000"]];
    NSString * u9  = [[emvAppDict valueForKey:@"Application_Version_Number"] stringByAppendingString:[self getEMVStr:@"0200"]];
    NSString * u10  = [[emvAppDict valueForKey:@"Point_of_Service_POS_EntryMode"] stringByAppendingString:[self getEMVStr:@"05"]];
    NSString * u11  = [[emvAppDict valueForKey:@"Acquirer_Identifier"] stringByAppendingString:[self getEMVStr:@"001234567890"]];
    NSString * u12  = [[emvAppDict valueForKey:@"Merchant_Category_Code"] stringByAppendingString:[self getEMVStr:@"1234"]];
    NSString * merchantID8 = @"BCTEST 12345678";
    NSString * u13  = [[emvAppDict valueForKey:@"Merchant_Identifier"] stringByAppendingString:[self getEMVStr:[self getHexFromStr:merchantID8]]];
    NSString* MerchantNameAndLocation8 = @"abcd";
    
    NSString * u14  = [[emvAppDict valueForKey:@"Merchant_Name_and_Location"] stringByAppendingString:[self getEMVStr:[[self getHexFromStr:MerchantNameAndLocation8] stringByAppendingString:@"0000000000000000000000"]]];
    NSString * u15  = [[emvAppDict valueForKey:@"Transaction_Currency_Code"] stringByAppendingString:[self getEMVStr:@"0608"]];
    NSString * u16 = [[emvAppDict valueForKey:@"Transaction_Currency_Exponent"] stringByAppendingString:[self getEMVStr:@"00"]];
    NSString * u17  = [[emvAppDict valueForKey:@"Transaction_Reference_Currency_Code"] stringByAppendingString:[self getEMVStr:@"0608"]];
    NSString * u18 = [[emvAppDict valueForKey:@"Transaction_Reference_Currency_Exponent"] stringByAppendingString:[self getEMVStr:@"00"]];
    NSString * u19  = [[emvAppDict valueForKey:@"Terminal_Country_Code"] stringByAppendingString:[self getEMVStr:@"0608"]];
    NSString * u20  = [[emvAppDict valueForKey:@"Interface_Device_IFD_Serial_Number"] stringByAppendingString:[self getEMVStr:[self getHexFromStr:@"83201ICC"]]];
    NSString * u21 = [[emvAppDict valueForKey:@"Terminal_Identification"] stringByAppendingString:[self getEMVStr:[self getHexFromStr:@"NL-GP730"]]];
    NSString * u22  = [[emvAppDict valueForKey:@"Default_DDOL"] stringByAppendingString:[self getEMVStr:@"9f3704"]];
    NSString * u23 = [[emvAppDict valueForKey:@"Default_Tdol"] stringByAppendingString:[self getEMVStr:@"9F1A0295059A039C01"]];
    NSString * u24  = [[emvAppDict valueForKey:@"Application_Selection_Indicator"] stringByAppendingString:[self getEMVStr:@"01"]];
    
    
#pragma mark aid9
    NSString *AID9 = @"A0000001523010";
    NSString * v1  = [[emvAppDict valueForKey:@"Application_Identifier_AID_terminal"] stringByAppendingString:[self getEMVStr:AID9]];
    NSString * v2 = [[emvAppDict valueForKey:@"TAC_Default"] stringByAppendingString:[self getEMVStr:@"FFFFFFFFFF"]];
    NSString * v3  = [[emvAppDict valueForKey:@"TAC_Online"] stringByAppendingString:[self getEMVStr:@"FFFFFFFFFF"]];
    NSString * v4  = [[emvAppDict valueForKey:@"TAC_Denial"] stringByAppendingString:[self getEMVStr:@"0010000000"]];
    NSString * v5  = [[emvAppDict valueForKey:@"Target_Percentage_to_be_Used_for_Random_Selection"] stringByAppendingString:[self getEMVStr:@"00"]];
    NSString * v6  = [[emvAppDict valueForKey:@"Maximum_Target_Percentage_to_be_used_for_Biased_Random_Selection"] stringByAppendingString:[self getEMVStr:@"00"]];
    NSString * v7  = [[emvAppDict valueForKey:@"Threshold_Value_BiasedRandom_Selection"] stringByAppendingString:[self getEMVStr:[self getHexFromIntStr:@"5000"]]];
    NSString * v8  = [[emvAppDict valueForKey:@"Terminal_Floor_Limit"] stringByAppendingString:[self getEMVStr:@"00000000"]];
    NSString * v9  = [[emvAppDict valueForKey:@"Application_Version_Number"] stringByAppendingString:[self getEMVStr:@"0001"]];
    NSString * v10  = [[emvAppDict valueForKey:@"Point_of_Service_POS_EntryMode"] stringByAppendingString:[self getEMVStr:@"05"]];
    NSString * v11 = [[emvAppDict valueForKey:@"Acquirer_Identifier"] stringByAppendingString:[self getEMVStr:@"001234567890"]];
    NSString * v12  = [[emvAppDict valueForKey:@"Merchant_Category_Code"] stringByAppendingString:[self getEMVStr:@"1234"]];
    NSString * v13  = [[emvAppDict valueForKey:@"Merchant_Identifier"] stringByAppendingString:[self getEMVStr:[self getHexFromStr:@"BCTEST 12345678"]]];
    NSString * v14  = [[emvAppDict valueForKey:@"Merchant_Name_and_Location"] stringByAppendingString:[self getEMVStr:[self getHexFromStr:@"abcd"]]];
    NSString * v15  = [[emvAppDict valueForKey:@"Transaction_Currency_Code"] stringByAppendingString:[self getEMVStr:@"0608"]];
    NSString * v16 = [[emvAppDict valueForKey:@"Transaction_Currency_Exponent"] stringByAppendingString:[self getEMVStr:@"00"]];
    NSString * v17  = [[emvAppDict valueForKey:@"Transaction_Reference_Currency_Code"] stringByAppendingString:[self getEMVStr:@"0608"]];
    NSString * v18 = [[emvAppDict valueForKey:@"Transaction_Reference_Currency_Exponent"] stringByAppendingString:[self getEMVStr:@"00"]];
    NSString * v19  = [[emvAppDict valueForKey:@"Terminal_Country_Code"] stringByAppendingString:[self getEMVStr:@"0608"]];
    NSString * v20  = [[emvAppDict valueForKey:@"Interface_Device_IFD_Serial_Number"] stringByAppendingString:[self getEMVStr:[self getHexFromStr:@"83201ICC"]]];
    NSString * v21 = [[emvAppDict valueForKey:@"Terminal_Identification"] stringByAppendingString:[self getEMVStr:[self getHexFromStr:@"NL-GP730"]]];
    NSString * v22  = [[emvAppDict valueForKey:@"Default_DDOL"] stringByAppendingString:[self getEMVStr:@"9f3704"]];
    NSString * v23 = [[emvAppDict valueForKey:@"Default_Tdol"] stringByAppendingString:[self getEMVStr:@"9F1A0295059A039C01"]];
    NSString * v24  = [[emvAppDict valueForKey:@"Application_Selection_Indicator"] stringByAppendingString:[self getEMVStr:@"01"]];
    
#pragma mark --aid 10
    NSString *AID10 = @"A0000003330101";
    NSString * w1  =  [[emvAppDict valueForKey:@"Application_Identifier_AID_terminal"] stringByAppendingString:[self getEMVStr:AID10]];
    NSString * w2  =  [[emvAppDict valueForKey:@"TAC_Default"] stringByAppendingString:[self getEMVStr:@"0000000000"]];
    NSString * w3 =  [[emvAppDict valueForKey:@"TAC_Online"] stringByAppendingString:[self getEMVStr:@"0000000000"]];
    NSString * w4  =  [[emvAppDict valueForKey:@"TAC_Denial"] stringByAppendingString:[self getEMVStr:@"0000000000"]];
    NSString * w5 =  [[emvAppDict valueForKey:@"Target_Percentage_to_be_Used_for_Random_Selection"] stringByAppendingString:[self getEMVStr:@"00"]];
    NSString * w6 =  [[emvAppDict valueForKey:@"Maximum_Target_Percentage_to_be_used_for_Biased_Random_Selection"] stringByAppendingString:[self getEMVStr:@"00"]];
    NSString * w7  =  [[emvAppDict valueForKey:@"Threshold_Value_BiasedRandom_Selection"] stringByAppendingString:[self getEMVStr:[self getHexFromIntStr:@"5000"]]];
    NSString * w8  =  [[emvAppDict valueForKey:@"Terminal_Floor_Limit"] stringByAppendingString:[self getEMVStr:@"00000000"]];
    NSString * w9  =  [[emvAppDict valueForKey:@"Application_Version_Number"] stringByAppendingString:[self getEMVStr:@"008C"]];
    NSString * w10  =  [[emvAppDict valueForKey:@"Point_of_Service_POS_EntryMode"] stringByAppendingString:[self getEMVStr:@"05"]];
    NSString * w11  =  [[emvAppDict valueForKey:@"Acquirer_Identifier"] stringByAppendingString:[self getEMVStr:@"001234567890"]];
    NSString * w12 =  [[emvAppDict valueForKey:@"Merchant_Category_Code"] stringByAppendingString:[self getEMVStr:@"1234"]];
    NSString * w13  =  [[emvAppDict valueForKey:@"Merchant_Identifier"] stringByAppendingString:[self getEMVStr:[self getHexFromStr:@"BCTEST 12345678"]]];
    
    NSString * w14  =  [[emvAppDict valueForKey:@"Merchant_Name_and_Location"] stringByAppendingString:[self getEMVStr:[[self getHexFromStr:@"abcd"] stringByAppendingString:@"0000000000000000000000"]]];
    NSString * w15  =  [[emvAppDict valueForKey:@"Transaction_Currency_Code"] stringByAppendingString:[self getEMVStr:@"0156"]];
    NSString * w16 =  [[emvAppDict valueForKey:@"Transaction_Currency_Exponent"] stringByAppendingString:[self getEMVStr:@"00"]];
    NSString * w17  =  [[emvAppDict valueForKey:@"Transaction_Reference_Currency_Code"] stringByAppendingString:[self getEMVStr:@"0156"]];
    NSString * w18 =  [[emvAppDict valueForKey:@"Transaction_Reference_Currency_Exponent"] stringByAppendingString:[self getEMVStr:@"00"]];
    NSString * w19  =  [[emvAppDict valueForKey:@"Terminal_Country_Code"] stringByAppendingString:[self getEMVStr:@"0156"]];
    NSString * w20  =  [[emvAppDict valueForKey:@"Interface_Device_IFD_Serial_Number"] stringByAppendingString:[self getEMVStr:[self getHexFromStr:@"83201ICC"]]];
    NSString * w21 =  [[emvAppDict valueForKey:@"Terminal_Identification"] stringByAppendingString:[self getEMVStr:[self getHexFromStr:@"NL-GP730"]]];
    NSString * w22  =  [[emvAppDict valueForKey:@"Default_DDOL"] stringByAppendingString:[self getEMVStr:@"9F37049F47018F019F3201"]];
    NSString * w23 =  [[emvAppDict valueForKey:@"Default_Tdol"] stringByAppendingString:[self getEMVStr:@"9F0802"]];
    NSString * w24  =  [[emvAppDict valueForKey:@"Application_Selection_Indicator"] stringByAppendingString:[self getEMVStr:@"01"]];
    
    
#pragma mark aid11
    NSString *AID11 = @"A0000005241010";
    NSString *x1  = [[emvAppDict valueForKey:@"Application_Identifier_AID_terminal"] stringByAppendingString:[self getEMVStr:AID11]];
    NSString * x2  = [[emvAppDict valueForKey:@"TAC_Default"] stringByAppendingString:[self getEMVStr:@"FFFFFFFFFF"]];
    NSString * x3  = [[emvAppDict valueForKey:@"TAC_Online"] stringByAppendingString:[self getEMVStr:@"FFFFFFFFFF"]];
    NSString * x4  = [[emvAppDict valueForKey:@"TAC_Denial"] stringByAppendingString:[self getEMVStr:@"0010000000"]];
    NSString * x5  = [[emvAppDict valueForKey:@"Target_Percentage_to_be_Used_for_Random_Selection"] stringByAppendingString:[self getEMVStr:@"00"]];
    NSString * x6  = [[emvAppDict valueForKey:@"Maximum_Target_Percentage_to_be_used_for_Biased_Random_Selection"] stringByAppendingString:[self getEMVStr:@"00"]];
    NSString * x7  = [[emvAppDict valueForKey:@"Threshold_Value_BiasedRandom_Selection"] stringByAppendingString:[self getEMVStr:[self getHexFromIntStr:@"5000"]]];
    NSString * x8  = [[emvAppDict valueForKey:@"Terminal_Floor_Limit"] stringByAppendingString:[self getEMVStr:@"00000000"]];
    NSString * x9  = [[emvAppDict valueForKey:@"Application_Version_Number"] stringByAppendingString:[self getEMVStr:@"0064"]];
    NSString * x10  = [[emvAppDict valueForKey:@"Point_of_Service_POS_EntryMode"] stringByAppendingString:[self getEMVStr:@"05"]];
    NSString * x11  = [[emvAppDict valueForKey:@"Acquirer_Identifier"] stringByAppendingString:[self getEMVStr:@"001234567890"]];
    NSString * x12  = [[emvAppDict valueForKey:@"Merchant_Category_Code"] stringByAppendingString:[self getEMVStr:@"1234"]];
    NSString * x13  = [[emvAppDict valueForKey:@"Merchant_Identifier"] stringByAppendingString:[self getEMVStr:[self getHexFromStr: @"BCTEST 12345678"]]];
    NSString * x14  = [[emvAppDict valueForKey:@"Merchant_Name_and_Location"] stringByAppendingString:[self getEMVStr:[[self getHexFromStr:@"abcd"] stringByAppendingString:@"0000000000000000000000"]]];
    NSString * x15  = [[emvAppDict valueForKey:@"Transaction_Currency_Code"] stringByAppendingString:[self getEMVStr:@"0608"]];
    NSString * x16 = [[emvAppDict valueForKey:@"Transaction_Currency_Exponent"] stringByAppendingString:[self getEMVStr:@"00"]];
    NSString * x17  = [[emvAppDict valueForKey:@"Transaction_Reference_Currency_Code"] stringByAppendingString:[self getEMVStr:@"0608"]];
    NSString * x18 = [[emvAppDict valueForKey:@"Transaction_Reference_Currency_Exponent"] stringByAppendingString:[self getEMVStr:@"00"]];
    NSString * x19  = [[emvAppDict valueForKey:@"Terminal_Country_Code"] stringByAppendingString:[self getEMVStr:@"0608"]];
    NSString * x20  = [[emvAppDict valueForKey:@"Interface_Device_IFD_Serial_Number"] stringByAppendingString:[self getEMVStr:[self getHexFromStr:@"83201ICC"]]];
    NSString * x21 = [[emvAppDict valueForKey:@"Terminal_Identification"] stringByAppendingString:[self getEMVStr:[self getHexFromStr:@"NL-GP730"]]];
    NSString * x22  = [[emvAppDict valueForKey:@"Default_DDOL"] stringByAppendingString:[self getEMVStr:@"9f3704"]];
    NSString * x23 = [[emvAppDict valueForKey:@"Default_Tdol"] stringByAppendingString:[self getEMVStr:@"9F1A0295059A039C01"]];
    NSString * x24  = [[emvAppDict valueForKey:@"Application_Selection_Indicator"] stringByAppendingString:[self getEMVStr:@"01"]];
    
#pragma parameters
    NSArray *defaultAIDConfigArr = @[@"9F061000000000000000000000000000000000"];
    NSArray *certainAIDConfigArr1 = @[n1,n2,n3,n4,n5,n6,n7,n8,n9,n10,n11,n12,n13,n14,n15,n16,n17,n18,n19,n20,n21,n22,n23,n24];
    NSArray *certainAIDConfigArr2 = @[o1,o2,o3,o4,o5,o6,o7,o8,o9,o10,o11,o12,o13,o14,o15,o16,o17,o18,o19,o20,o21,o22,o23,o24];
    NSArray *certainAIDConfigArr3 = @[p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,p21,p22,p23,p24];
    NSArray *certainAIDConfigArr4 = @[q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,q13,q14,q15,q16,q17,q18,q19,q20,q21,q22,q23,q24];
    NSArray *certainAIDConfigArr5 = @[r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12,r13,r14,r15,r16,r17,r18,r19,r20,r21,r22,r23,r24];
    
    NSArray *certainAIDConfigArr6 = @[s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13,s14,s15,s16,s17,s18,s19,s20,s21,s22,s23,s24];
    NSArray *certainAIDConfigArr7 = @[t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13,t14,t15,t16,t17,t18,t19,t20,t21,t22,t23,t24];
    
    NSArray *certainAIDConfigArr8 = @[u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19,u20,u21,u22,u23,u24];
    NSArray *certainAIDConfigArr9 = @[v1,v2,v3,v4,v5,v6,v7,v8,v9,v10,v11,v12,v13,v14,v15,v16,v17,v18,v19,v20,v21,v22,v23,v24];
    NSArray *certainAIDConfigArr10 = @[w1,w2,w3,w4,w5,w6,w7,w8,w9,w10,w11,w12,w13,w14,w15,w16,w17,w18,w19,w20,w21,w22,w23,w24];
    NSArray *certainAIDConfigArr11 = @[x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15,x16,x17,x18,x19,x20,x21,x22,x23,x24];
    
    
//    NSArray *totalArray = @[defaultAIDConfigArr,certainAIDConfigArr1,certainAIDConfigArr2,certainAIDConfigArr3,certainAIDConfigArr4,certainAIDConfigArr5,certainAIDConfigArr6,certainAIDConfigArr7,certainAIDConfigArr8,certainAIDConfigArr9,certainAIDConfigArr10,certainAIDConfigArr11];
    
        [pos updateEmvAPP:EMVOperation_add data:defaultAIDConfigArr block:^(BOOL isSuccess, NSString *stateStr) {
            if (isSuccess) {
                self.textViewLog.text = stateStr;
                self.textViewLog.backgroundColor = [UIColor greenColor];
                [self.updateEMVapp2 setEnabled:YES];
            }else{
                self.textViewLog.text =@"add aid %d fail";
            }
        }];

}
- (IBAction)updateAID:(id)sender {
#pragma mark -- update certain aid app
    
    NSMutableDictionary * emvCapkDict = [pos getEMVAPPDict];
#pragma  ark --update common config
//    NSString *aid = @"A0000003330101";
    NSString * a  =[[emvCapkDict valueForKey:@"ICS"] stringByAppendingString:[self getEMVStr:@"F4F0F0FAAFFE8000"]];
    NSString * b  =[[emvCapkDict valueForKey:@"Terminal_type"] stringByAppendingString:[self getEMVStr:@"22"]];
    NSString * c =[[emvCapkDict valueForKey:@"Terminal_Capabilities"] stringByAppendingString:[self getEMVStr:@"60B8C8"]];
    NSString * d  =[[emvCapkDict valueForKey:@"Additional_Terminal_Capabilities"] stringByAppendingString:[self getEMVStr:@"F000F0A001"]];
    NSString * e  =[[emvCapkDict valueForKey:@"status"] stringByAppendingString:[self getEMVStr:@"01"]];
    NSString * f  =[[emvCapkDict valueForKey:@"Electronic_cash_Terminal_Transaction_Limit"] stringByAppendingString:[self getEMVStr:@"000000500000"]];
    NSString * g  = [[emvCapkDict valueForKey:@"terminal_contactless_offline_floor_limit"] stringByAppendingString:[self getEMVStr:@"000000000000"]];
    NSString * h  =[[emvCapkDict valueForKey:@"terminal_contactless_transaction_limit"] stringByAppendingString:[self getEMVStr:@"000000200001"]];
    NSString * i  =[[emvCapkDict valueForKey:@"terminal_execute_cvm_limit"] stringByAppendingString:[self getEMVStr:@"000000199999"]];
    NSString * j  =[[emvCapkDict valueForKey:@"Terminal_Floor_Limit"] stringByAppendingString:[self getEMVStr:@"00000000"]];
    NSString * k  =[[emvCapkDict valueForKey:@"Identity_of_each_limit_exist"] stringByAppendingString:[self getEMVStr:@"0F"]];
    NSString * l  =[[emvCapkDict valueForKey:@"terminal_status_check"] stringByAppendingString:[self getEMVStr:@"01"]];
    NSString * m  =[[emvCapkDict valueForKey:@"Terminal_Default_Transaction_Qualifiers"] stringByAppendingString:[self getEMVStr:@"36C04000"]];
    
   
    NSArray *defaultConfigArr = @[a,b,c,d,e,f,g,h,i,j,k,l,m];

    [pos updateEmvAPP:EMVOperation_update data:defaultConfigArr  block:^(BOOL isSuccess, NSString *stateStr) {
        if (isSuccess) {
                self.textViewLog.text = stateStr;
            self.textViewLog.backgroundColor = [UIColor greenColor];
        }else{
            self.textViewLog.text = @"update default config fail";
        }
    }];
    
}
- (IBAction)getAidList:(id)sender {
    NSMutableArray *mData = [[NSMutableArray alloc]init];
    [pos updateEmvAPP:EMVOperation_getList data:mData  block:^(BOOL isSuccess, NSString *stateStr) {
        if (isSuccess) {
            self.textViewLog.text = stateStr;
            self.textViewLog.backgroundColor = [UIColor greenColor];
            [self.updateEMVapp2 setEnabled:YES];
        }else{
            self.textViewLog.text = @"get aid list fail";
        }
    }];
    
}
- (IBAction)readACertainAID:(id)sender {
    NSArray * data1 = @[@"9F0607A0000006351010"];
    NSArray * data2 = @[@"9F0607A0000000044010"];
    NSArray * data3 = @[@"9F0607A0000000031010"];
    NSArray * data4 = @[@"9F0607A0000000032010"];
    NSArray * data5 = @[@"9F0607A0000000033010"];
    NSArray * data6 = @[@"9F0607A0000000041010"];
    NSArray * data7 = @[@"9F0606A00000002501"];
    NSArray * data8 = @[@"9F0607A0000005241010"];
    NSArray * data9 = @[@"9F0607A0000000651010"];
    NSArray * data10 = @[@"9F0607A0000001523010"];
    NSArray * data11 = @[@"9F0607A0000003330101"];
    
    
    [pos updateEmvAPP:EMVOperation_quickemv data:data11  block:^(BOOL isSuccess, NSString *stateStr) {
        if (isSuccess) {
            self.textViewLog.text = stateStr;
            self.textViewLog.backgroundColor = [UIColor greenColor];
            [self.updateEMVapp2 setEnabled:YES];
        }
    }];
    
}

- (NSString *)getHexFromIntStr:(NSString *)tmpidStr
{
    NSInteger tmpid = [tmpidStr intValue];
    NSString *nLetterValue;
    NSString *str =@"";
    int ttmpig;
    for (int i = 0; i<9; i++) {
        ttmpig=tmpid%16;
        tmpid=tmpid/16;
        switch (ttmpig)
        {
            case 10:
                nLetterValue =@"A";break;
            case 11:
                nLetterValue =@"B";break;
            case 12:
                nLetterValue =@"C";break;
            case 13:
                nLetterValue =@"D";break;
            case 14:
                nLetterValue =@"E";break;
            case 15:
                nLetterValue =@"F";break;
            default:
                nLetterValue = [NSString stringWithFormat:@"%u",ttmpig];
        }
        str = [nLetterValue stringByAppendingString:str];
        if (tmpid == 0) {
            break;
        }
    }
    //不够一个字节凑0
    if(str.length == 1){
        return [NSString stringWithFormat:@"0%@",str];
    }else{
        if ([str length]<8) {
            if ([str length] == (8-1)) {
                str = [@"0" stringByAppendingString:str];
            }else if ([str length] == (8-2)){
                str = [@"00" stringByAppendingString:str];
            }else if  ([str length] == (8-3)){
                str = [@"000" stringByAppendingString:str];
            }
            else if ([str length] == (8-4)) {
                str = [@"0000" stringByAppendingString:str];
            } else if([str length] == (8-5)){
                str = [@"00000" stringByAppendingString:str];
            }else if([str length] == (8-6)){
                str = [@"000000" stringByAppendingString:str];
            }
        }
        return str;
    }
}

-(NSString* )getEMVStr:(NSString *)emvStr{
    NSInteger emvLen = 0;
    if (emvStr != NULL &&![emvStr  isEqual: @""]) {
        if ([emvStr length]%2 != 0) {
            emvStr = [@"0" stringByAppendingString:emvStr];
        }
        emvLen = [emvStr length]/2;
    }else{
        NSLog(@"init emv app config str could not be empty");
        return nil;
    }
    NSData *emvLenData = [Util IntToHex:emvLen];
    NSString *totalStr = [[[Util byteArray2Hex:emvLenData] substringFromIndex:2] stringByAppendingString:emvStr];
    return totalStr;
}

-(NSString *)getHexFromStr:(NSString *)str{
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    NSString *hex = [Util byteArray2Hex:data];
    return hex ;
}

@end

