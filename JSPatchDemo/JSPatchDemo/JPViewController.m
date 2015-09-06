//
//  JPViewController.m
//  JSPatch
//
//  Created by bang on 15/5/2.
//  Copyright (c) 2015年 bang. All rights reserved.
//

#import "JPViewController.h"

@implementation JPViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _testString = @"inited test string";
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 100, [UIScreen mainScreen].bounds.size.width, 50)];
    [btn setTitle:@"Push JPTableViewController" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(handleBtn:) forControlEvents:UIControlEventTouchUpInside];
    [btn setBackgroundColor:[UIColor grayColor]];
    [self.view addSubview:btn];
}

- (void)handleBtn:(id)sender
{
    _testString = @"handleBtn test string";
    NSLog(@"%@", _testString);
}

- (void)testFunction
{
    NSLog(@"testFunction");
}

- (void)viewDidDisappear:(BOOL)animated
{
    NSLog(@"viewDidDisappear");
}
@end

