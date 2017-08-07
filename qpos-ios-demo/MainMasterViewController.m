
//
//  MainMasterViewController.m
//  qpos-ios-demo
//
//  Created by Robin on 11/19/13.
//  Copyright (c) 2013 Robin. All rights reserved.
//

#import "MainMasterViewController.h"
#import "MainDetailViewController.h"
#import "BTDeviceFinder.h"

typedef enum{
    allFlag,
    usrPreFlag ,
    txtEnterFlag
    
}kSourceFlag;

BOOL is2ModeBluetooth = YES;
BOOL isTestBluetooth = NO;
NSInteger   scanBluetoothTime = 15;
@interface MainMasterViewController ()<UITextFieldDelegate> {
    NSMutableArray *_objects;
}
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *txtField;
@end

@implementation MainMasterViewController{
    BTDeviceFinder *bt;
    NSTimer *mNSTimer;
    QPOSService *mQPOSService;
    NSString *searchKey;
    UIAlertView *mAlertView;
    NSString *sourceFlag;
}

@synthesize waitScanBT;

- (void)awakeFromNib
{
    [super awakeFromNib];
}



-(void)timerFired{
    NSArray *arr;
    if(is2ModeBluetooth){
        arr = [bt getAllOnlineQPosName2Mode];
    }
    //    else{
    //        arr = [bt getAllOnlineQPosNameNew];
    //    }
    NSLog(@"---------------------");
    NSLog(@"begin name count = %lu",(unsigned long)[arr count]);
    for (int i = 0; i < [arr count]; i++) {
        NSString *bluetoothAddress = [arr objectAtIndex:i];
        [self insertNewObject:bluetoothAddress];
    }
    [self.tableView reloadData];
    
    [waitScanBT stopAnimating];
    
}


-(void)waitScanLog{
    //waitScanBT = [[UIActivityIndicatorView new] initWithFrame:CGRectMake(140, 200, 30, 30)];
    
    [waitScanBT startAnimating];
}

-(void) sleepMs: (NSInteger)msec {
    NSTimeInterval sec = (msec / 1000.0f);
    [NSThread sleepForTimeInterval:sec];
}

-(void)scanBluetooth{
    _objects = nil;
    [self.tableView reloadData];
    //
    waitScanBT.hidesWhenStopped = YES;
    [waitScanBT startAnimating];
    
    //    [self insertNewObject:@"audioType"];
    
    if (bt == nil) {
        bt = [BTDeviceFinder new];
    }
    NSInteger delay = 0;
    if(is2ModeBluetooth){
        NSLog(@"蓝牙状态:%ld",(long)[bt getCBCentralManagerState]);
        [bt setBluetoothDelegate2Mode:self];
        if ([bt getCBCentralManagerState] == CBCentralManagerStateUnknown) {
            while ([bt getCBCentralManagerState]!= CBCentralManagerStatePoweredOn) {
                NSLog(@"Bluetooth state is not power on");
                [self sleepMs:10];
                if(delay++==10){
                    return;
                }
            }
        }
        [bt scanQPos2Mode:scanBluetoothTime];
    }
    
    
}

-(void)stopBluetooth{
    if(is2ModeBluetooth){
        [bt stopQPos2Mode];
    }
    
    [waitScanBT stopAnimating];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //查找此前有无内存偏好
    NSString *usrPre = [[NSUserDefaults standardUserDefaults]objectForKey:@"usrPreference"];
    if (usrPre == NULL || [usrPre  isEqual: @""]) {
        [[NSUserDefaults standardUserDefaults]setObject:[NSString stringWithFormat:@"%d",allFlag] forKey:@"sourceFlag"];
        [self scanBluetooth];
    }else{
        [[NSUserDefaults standardUserDefaults]setObject:[NSString stringWithFormat:@"%d",usrPreFlag]  forKey:@"sourceFlag"];
        [self scanBluetooth];
    }
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.txtField.delegate = self;
    self.txtField.keyboardType = UIKeyboardTypeDefault;
    self.txtField.returnKeyType = UIReturnKeySearch;
    
    
    //self.navigationItem.leftBarButtonItem = self.editButtonItem;
    //    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(scanBluetooth)];
    //
    //    addButton.title = @"Scan";
    //    self.navigationItem.rightBarButtonItem = addButton;
    //    self.navigationItem.rightBarButtonItem.title = @"Scan";
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"停止扫描" style:(UIBarButtonItemStyleDone) target:self action:@selector(stopBluetooth)];
    
    
}

-(void)onPinKeyTDESResult:(NSString *)encPin{
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
}

- (void)insertNewObject:(id)sender
{
    
    if (!_objects) {
        _objects = [[NSMutableArray alloc] init];
    }
    
    if(sender !=nil){
        [_objects insertObject:sender atIndex:0];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        if (_objects.count > 1) {
            [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            
        }
        [self.tableView reloadData];
        
    }
    
    
}

#pragma mark txtfield
-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    self.txtField = textField;
    searchKey = textField.text;
    if (searchKey != NULL && ![searchKey  isEqual: @""]) {
        //去搜索
        [[NSUserDefaults standardUserDefaults]setObject:[NSString stringWithFormat:@"%d",txtEnterFlag] forKey:@"sourceFlag"];
        //存储用户偏好
        [[NSUserDefaults standardUserDefaults]setObject:searchKey forKey:@"usrPreference"];
        [self scanBluetooth];
        
    }else{
        
        //提醒用户设置用户偏好
    }
    return true;
}
-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    [self.view endEditing:YES];
    return YES;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyBoardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyBoardWillHide:) name:UIKeyboardWillHideNotification object:nil];}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyBoardWillHide:) name:@"keyBoardWillHide"  object:nil];
}
#pragma mark 键盘显示与隐藏
-(void)keyBoardWillShow:(NSNotification *)notification{
    // 获取用户信息
    NSDictionary *userInfo = [NSDictionary dictionaryWithDictionary:notification.userInfo];
    // 获取键盘高度
    CGRect keyBoardBounds  = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat keyBoardHeight = keyBoardBounds.size.height;
    // 获取键盘动画时间
    CGFloat animationTime  = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    
    // 定义好动作
    void (^animation)(void) = ^void(void) {
        self.suspendView.transform = CGAffineTransformMakeTranslation(0, - keyBoardHeight);
    };
    
    if (animationTime > 0) {
        [UIView animateWithDuration:animationTime animations:animation];
    } else {
        animation();
    }
    
    
    
}
#pragma mark 点击收起键盘
- (IBAction)resignFirstResponder:(id)sender {
    [self.txtField resignFirstResponder];
}
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.txtField resignFirstResponder];
}
-(void)keyBoardWillHide:(NSNotification *)notification{
    // 获取用户信息
    NSDictionary *userInfo = [NSDictionary dictionaryWithDictionary:notification.userInfo];
    // 获取键盘动画时间
    CGFloat animationTime  = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    
    // 定义好动作
    void (^animation)(void) = ^void(void) {
        self.suspendView.transform = CGAffineTransformIdentity;
    };
    
    if (animationTime > 0) {
        [UIView animateWithDuration:animationTime animations:animation];
    } else {
        animation();
    }
}
- (IBAction)showAllDevices:(id)sender {
    [[NSUserDefaults standardUserDefaults]setObject:[NSString stringWithFormat:@"%d",allFlag] forKey:@"sourceFlag"];
    
    [self scanBluetooth];
}

#pragma mark ---自定义键盘


#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    id object = _objects[indexPath.row];
    cell.textLabel.text = [object description];
    return cell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    //TODO Edit
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_objects removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSLog(@"+++prepareForSegue ");
    [self stopBluetooth];
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        id object = _objects[indexPath.row];
        [[segue destinationViewController] setDetailItem:object];
    }
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if(animated){
//        [self scanBluetooth];
    }
}

-(void)viewDidDisappear:(BOOL)animated{
    NSLog(@"main  master viewDidDisappear");
}

-(void)onBluetoothNameNew:(NSString *)bluetoothName{
    NSLog(@"+++onBluetoothNameNew %@",bluetoothName);
    [self insertNewObject:bluetoothName];
}

-(void)finishScanQPosNew{
    //    [self timerFired];
    [self stopBluetooth];
}


-(void)onBluetoothName2Mode:(NSString *)bluetoothName{
    NSLog(@"+++onBluetoothName2Mode %@",bluetoothName);
    
    dispatch_async(dispatch_get_main_queue(),  ^{
        if(isTestBluetooth){
            if ([bluetoothName hasPrefix:@"QPOS0100000073"]) {
                [self stopBluetooth];
                
                [self connectionPOS:bluetoothName];
            }
        }else{
            
//            if ([bluetoothName hasPrefix:@"MPOS"] ||[bluetoothName hasPrefix:@"QPOS"]) {
                sourceFlag = [[NSUserDefaults standardUserDefaults]objectForKey:@"sourceFlag"];
                //如果是初次进入app ,判断此前是否有用户偏好
                if ([sourceFlag intValue] == allFlag) {
                    
                    [self insertNewObject:bluetoothName];
                    
                }
                if ([sourceFlag intValue] == usrPreFlag) {
                    
                    NSString *prefix = [[NSUserDefaults standardUserDefaults]objectForKey:@"usrPreference"];
                    if (prefix != NULL && ![prefix  isEqual: @""]) {
                        if ([bluetoothName rangeOfString:prefix].location != NSNotFound) {
                            
                            [self insertNewObject:bluetoothName];
                            
                        }
                    }
                    
                    
                }if ([sourceFlag intValue] == txtEnterFlag) {
                    
                    //如果用户另外输入了关键字，加载关键字查找出来的设备
                    NSString *prefix = self.txtField.text;
                    if ([bluetoothName rangeOfString:prefix].location != NSNotFound ) {
                        
                        [self insertNewObject:bluetoothName];
                    }
                    
                }
            }
            
            
            
//        }
    });
}

-(void)finishScanQPos2Mode{
    dispatch_async(dispatch_get_main_queue(),  ^{
        [self stopBluetooth];
    });
}

-(void)bluetoothIsPowerOff2Mode{
    dispatch_async(dispatch_get_main_queue(),  ^{
        NSLog(@"+++bluetoothIsPowerOff2Mode");
        //        [bt setBluetoothDelegate2Mode:nil];
        [self stopBluetooth];
        //        bt = nil;
    });
    
}

-(void)bluetoothIsPowerOn2Mode{
    dispatch_async(dispatch_get_main_queue(),  ^{
        NSLog(@"+++bluetoothIsPowerOn2Mode");
    });
    
}

-(void)bluetoothUnauthorized2Mode{
    dispatch_async(dispatch_get_main_queue(),  ^{
        NSLog(@"+++bluetoothUnauthorized2Mode");
        [waitScanBT stopAnimating];
    });
}

///////////////////////////TEST//////////////////////////////////////////////
-(void)initQposs{
    
    if (nil == mQPOSService) {
        mQPOSService = [QPOSService sharedInstance];
    }
    
    [mQPOSService setDelegate:self];
    
    //    self_queue = dispatch_queue_create("demo.queue", NULL);
    //    [pos setQueue:self_queue];
    
    [mQPOSService setQueue:nil];
    
    [mQPOSService setPosType:PosType_BLUETOOTH_2mode];
}

- (void)connectionPOS:(NSString *)bluetoothAddress{
    
    [self initQposs];
    [mQPOSService connectBT:bluetoothAddress];
    NSLog(@"---------------------");
    
}

-(void) onRequestQposConnected{
    NSLog(@">>>>>>>>>>>>>>>>>>>>>>>>>onRequestQposConnected");
    
}
-(void) onRequestQposDisconnected{
    NSLog(@">>>>>>>>>>>>>>>>>>>>>>>>>onRequestQposDisconnected");
    
}
-(void) onRequestNoQposDetected{
    NSLog(@">>>>>>>>>>>>>>>>>>>>>>>>>onRequestNoQposDetected");
    
}

@end


