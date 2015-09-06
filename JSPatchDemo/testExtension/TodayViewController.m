//
//  TodayViewController.m
//  testExtension
//
//  Created by joyce on 15/7/17.
//  Copyright (c) 2015年 bang. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>
#import <Foundation/NSExtensionContext.h>

@interface TodayViewController () <NCWidgetProviding>

@end

@implementation TodayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    UIButton* button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 200, 40)];
    button.backgroundColor = [UIColor greenColor];
    [button setTitle:@"event 1 happend" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (void)buttonClicked:(id) sender
{
    NSLog(@"buttonClicked");
    NSURL *pjURL = [ NSURL URLWithString : @"AppUrlType://jspatch" ];
    [ self . extensionContext openURL :pjURL completionHandler : nil ];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    // Perform any setup necessary in order to update the view.
    
    // If an error is encountered, use NCUpdateResultFailed
    // If there's no update required, use NCUpdateResultNoData
    // If there's an update, use NCUpdateResultNewData

    completionHandler(NCUpdateResultNewData);
}

@end
