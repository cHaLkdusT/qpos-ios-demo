//
//  MainMasterViewController.h
//  qpos-ios-demo
//
//  Created by Robin on 11/19/13.
//  Copyright (c) 2013 Robin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BTDeviceFinder.h"
#import "QPOSService.h"

@class BTDeviceFinder;

@interface MainMasterViewController : UIViewController<BluetoothDelegate2Mode,QPOSServiceListener,UITableViewDelegate,UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *waitScanBT;
@property (weak, nonatomic) IBOutlet UIView *suspendView;


@end
