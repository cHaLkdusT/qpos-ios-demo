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
    NSInteger length = [Util  byteArrayToInt:[Util HexStringToByteArray:@"0231"]];
    NSString * tlvStr = [tlv substringWithRange:NSMakeRange(4, length*2)];
    
    NSDictionary *value = [SGTLVDecode decodeWithString:tlvStr];
    NSLog(@"maskedPan == %@",[[value valueForKey:@"C4"] valueForKey:@"value"]);
   
    
    NSString *a = @"5F200F46554C4C2046554E4354494F4E414C4F07A00000000310105F24032012319F160F4243544553542031323334353637389F21031107149A031710139F02060000000000129F03060000000000009F34031F03009F120D4352454449544F4445564953419F0607A00000000310105F300202019F4E0F616263640000000000000000000000C408476173FFFFFF0010C00AFFFF000000BB81200008C28201908BEA221E6DACB7EE262AD3E308E7A2DBE2D2AC5374F689E7F9946C9C8E09042A22B159F3629CB2A8AED0F41740C64848C02DF345ACBD8FBB8032BC5D7D8BF4D001453529479FFB61019B4A20F111D2AADA27808C54E291B3606DC1ABE3B9DF74BAA5B9453FDDC10AA6F6290178D32C3BE002B2995DEB40479BC994AAE111BD6C6BA41FE5ACA0A2ED0E5700F6FC9E12359B1B3B9D2512A14C932D80FB80AB0C834DB64E9D44D43752D554A4FCBC7A8933B98D9FAC8C3D76323931AE9E3FE6B9EE6FCE10F0890744D670BEF570D8C7BCF3D50386365283CC67ADEE5E59A003CD86B0A77FA5B3A2EF785AE50D33C448DEE34B11205593F140DA1CC71A0D2E01F65319A874974A020B43A3BAA3AE25AFC0980D1CB81053F99114382BAA1467B39E4006F16DA9BC9B6397E64D38340B5E2A91EE7DD57227079738D420AD9DC35927889BFCA51B4FE6B87AEBF801A13A04A8369CE854B7F9292E9AE57C46BCFFB6EF71418397B59EADFD2EA11BCD17A6F34136B17F667124FE1E44958C7B2E46FEC88D86C6CA0409BEF1432B0245329127DADC06737769706531";
    
//    NSString * a = @"5F2013415320424153494320564953412044454249544F07A00000000310105F24032212319F160F4243544553542031323334353637389F21031052219A031710139F02060000000095209F03060000000000009F34031E03009F120A564953412044454249549F0607A00000000310105F300202019F4E0F616263640000000000000000000000C408476173FFFFFF0211C00AFFFF9876543210E00293C28201A07036AA43A8CA3C410F718C8A8D8D717CA4B0027FA69C80B3A089125CDCE7388D8E439EC1A1EE1A62061126156E504FAD8189FCEA3AEEE0A4A9C940713C5E8D5D1A702C6C90924237D2475D5E11AFCE759E1CBC7B2C954F84FA34E7AC6A9A0663348C162EDA4B4509F57ADFB8A2EEB424EC1562A8A516831ADD0E71B326DEB5227D0A57F458626EFDA8F9AE160D07431A358CDCAB06EE0599AF4043D736DBA200F853EA0659AFAA79EFADBC91697CEFD5075239327B6502E0BFFBEFA01F49490C3A7388B08641723C896FEC7030B1D4D821FAE33DE983C213333741BC79DC325B28354CF8E893A8E9ECBFEBBF045F42A3617A3E7517258813E44F58DC463392DF93C06AF140281C97646C5B9BE1E98934CB6D0EFCBBD0A9B3730ECE2FC9D2552859F2F21B72906C0CD04340BA0F47467F9DF4BA09E81F8328FBB004C1768A1DD5243F6E5BE292D1B0EB58D5B5C07C2EECA530FCC31CBE213D37E9BDE3462F3E92499538CAEC189AA8563295DF3CC2DB0D0B921F199666102CB85485FD10DBE79745318346AE0FF98FBCF0CFFC7183EFEB90089601471BD9EDFE989B037EC3DDAD";
    
      NSLog(@"onRequestOnlineProcess = %@",[[QPOSService sharedInstance] anlysEmvIccData:a]);
    
    
    
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
//        [pos doTrade:30];
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
        
        NSString *forDigitalPrefix = [tlv substringToIndex:4];
        NSInteger dataLength1 = [[forDigitalPrefix substringToIndex:2] intValue]*256;
        NSInteger dataLength2 = [[forDigitalPrefix substringWithRange:NSMakeRange(2, 1)]intValue] *16;
        NSInteger dataLength3 = [[forDigitalPrefix substringWithRange:NSMakeRange(3, 1)]intValue] ;
        NSInteger dataLength = dataLength1 + dataLength2 + dataLength3;
        
        NSString *onLineToolData = [tlv substringWithRange:NSMakeRange(4, dataLength*2)];
        NSLog(@"onlineToolData = %@",onLineToolData);
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
   /* [pos doUpdateIPEKOperation:@"00" tracksn:@"FFFF000000BB81200000" trackipek:@"F24B13AC6F579B929FBBFE58BC2A0647" trackipekCheckValue:@"CDF80B70C3BBCDDC" emvksn:@"FFFF000000BB81200000" emvipek:@"F24B13AC6F579B929FBBFE58BC2A0647" emvipekcheckvalue:@"CDF80B70C3BBCDDC" pinksn:@"FFFF000000BB81200000" pinipek:@"F24B13AC6F579B929FBBFE58BC2A0647" pinipekcheckValue:@"CDF80B70C3BBCDDC" block:^(BOOL isSuccess, NSString *stateStr) {
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
    
    NSDictionary * doTradeLogDictionary = [pos syncDoTradeLogOperation:2 data:0];
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


@end

