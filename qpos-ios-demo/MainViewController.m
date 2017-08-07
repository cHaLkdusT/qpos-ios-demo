//
//  MainViewController.m
//  qpos-ios-demo
//
//  Created by dspread-mac on 2017/5/19.
//  Copyright © 2017年 Robin. All rights reserved.
//

#import "MainViewController.h"

@interface MainViewController ()
@property (weak, nonatomic) IBOutlet UIButton *btAudioType;
@property (weak, nonatomic) IBOutlet UIButton *btBlueTooth;

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.btAudioType.layer.cornerRadius = 10;
    self.btBlueTooth.layer.cornerRadius = 10;
    // Do any additional setup after loading the view.
}
- (IBAction)AudioType:(id)sender {
    [self performSegueWithIdentifier:@"AudioTypeDetail" sender:sender];
}
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    NSLog(@"+++prepareForSegue ");
   
    if ([[segue identifier] isEqualToString:@"AudioTypeDetail"]) {

       
    }
}
- (IBAction)blueTooth:(id)sender {
    [self performSegueWithIdentifier:@"BlueToothDetail" sender:sender];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
