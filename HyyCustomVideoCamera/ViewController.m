//
//  ViewController.m
//  HyyCustomVideoCamera
//
//  Created by 胡阳阳 on 17/3/13.
//  Copyright © 2017年 胡阳阳. All rights reserved.
//

#import "ViewController.h"
#import "VideoCameraView.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect frame = [[UIScreen mainScreen] bounds];
    VideoCameraView *view = [[VideoCameraView alloc] initWithFrame:frame];
    [self.view addSubview:view];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
