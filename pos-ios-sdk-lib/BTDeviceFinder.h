//
//  BTDeviceFinder.h
//  Test
//
//  Created by wangxu on 13-11-8.
//  Copyright (c) 2013年 XiaoLonghui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

//@protocol BluetoothDelegateNew<NSObject>
//
//@optional
//-(void)onBluetoothNameNew:(NSString *)bluetoothName;
//-(void)finishScanQPosNew;
//@end

@protocol BluetoothDelegate2Mode<NSObject>

@optional
-(void)onBluetoothName2Mode:(NSString *)bluetoothName;
-(void)finishScanQPos2Mode;
-(void)bluetoothIsPowerOff2Mode;
-(void)bluetoothIsPowerOn2Mode;
@end



@interface BTDeviceFinder : NSObject

//new bluetooth sdk
//-(void)scanQPosNew: (NSInteger)timeout;
//-(NSArray*)getAllOnlineQPosNameNew;
//-(void)stopQPosNew;
//-(void)setBluetoothDelegateNew:(id<BluetoothDelegateNew>)aDelegate;


//bluetooth 2Mode
-(void)scanQPos2Mode: (NSInteger)timeout;
-(NSArray*)getAllOnlineQPosName2Mode;
-(void)stopQPos2Mode;
-(void)setBluetoothDelegate2Mode:(id<BluetoothDelegate2Mode>)aDelegate;
-(CBCentralManagerState)getCBCentralManagerState;

@end





