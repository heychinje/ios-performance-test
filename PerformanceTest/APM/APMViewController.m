//
//  APMViewController.m
//  PerformanceTest
//
//  Created by Zheng, Haiqiang (Jason) on 2024/7/26.
//

#import "APMViewController.h"
#import "UIViewController+Additions.h"
#import "PerformanceTest-Swift.h"
#import "CPU/CpuDumper.h"


@interface APMViewController ()

@end


@implementation APMViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGFloat buttonWidth = [UIScreen mainScreen].bounds.size.width - 100 * 2;
    
    UIButton *cpuButton = [self createButtonWithTitle:@"CPU" frame:CGRectMake(100, 40, buttonWidth, 40)];
    [cpuButton addTarget:self action:@selector(cpu) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:cpuButton];
}

- (void)cpu
{
    [CpuDumper cpuUsage];
}



@end
