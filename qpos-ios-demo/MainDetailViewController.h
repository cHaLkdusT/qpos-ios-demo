//
//  MainDetailViewController.h
//  qpos-ios-demo
//
//  Created by Robin on 11/19/13.
//  Copyright (c) 2013 Robin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QPOSService.h"

@class QPOSService;
@class Util;

@interface MainDetailViewController : UIViewController<QPOSServiceListener,UIActionSheetDelegate>

//接收前一页面传来的数据
@property (strong, nonatomic) id detailItem;

@property (nonatomic)NSString *bluetoothAddress;
@property (nonatomic)NSString *amount;
@property (nonatomic)NSString *cashbackAmount;


@property (weak, nonatomic) IBOutlet UITextView *textViewLog;
@property (weak, nonatomic) IBOutlet UILabel *lableAmount;

//@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@end
