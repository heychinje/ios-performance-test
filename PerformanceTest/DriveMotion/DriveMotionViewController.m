//
//  DriveMotionViewController.m
//  PerformanceTest
//
//  Created by Zheng, Haiqiang (Jason) on 2024/7/26.
//

#import <CoreLocation/CoreLocation.h>
#import "DriveMotionViewController.h"
#import "UIViewController+Additions.h"
#import "PerformanceTest-Swift.h"

@interface DriveMotionViewController ()
@property (nonatomic, strong) DriveMotionManager *dmMgr;
@property (nonatomic, strong) UIButton *modeButton;
@property (nonatomic, strong) UIButton *startButton;
@property (nonatomic, strong) UIButton *stopButton;
@property (nonatomic, strong) UILabel *statusLabel;
@end

@implementation DriveMotionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.dmMgr = [[DriveMotionManager alloc]init];
    
    CLLocationManager *lMgr = [[CLLocationManager alloc] init];
    [lMgr requestAlwaysAuthorization];
    
    CGFloat buttonWidth = [UIScreen mainScreen].bounds.size.width - 100 * 2;
    
    UIButton *modeButton = [self createButtonWithTitle:[NSString stringWithFormat:@"Current mode: %@", self.dmMgr.getModeString] frame:CGRectMake(100, 40, buttonWidth, 40)];
    UIButton *startButton = [self createButtonWithTitle:@"Start" frame:CGRectMake(100, 90, buttonWidth, 40)];
    UIButton *stopButton = [self createButtonWithTitle:@"Stop" frame:CGRectMake(100, 140, buttonWidth, 40)];
    UIButton *initManuelModeButton = [self createButtonWithTitle:@"Init Manuel" frame:CGRectMake(100, 190, buttonWidth, 40)];
    UIButton *deinitManuelModeButton = [self createButtonWithTitle:@"Deinit Manuel" frame:CGRectMake(100, 240, buttonWidth, 40)];
    UILabel *statusLabel = [[UILabel alloc] init];
    statusLabel.text = @"Press the mode button to change DM mode and press start button to start DM.";
    statusLabel.font = [UIFont systemFontOfSize:17];
    statusLabel.textAlignment = NSTextAlignmentLeft;
    statusLabel.lineBreakMode = NSLineBreakByCharWrapping;
    statusLabel.numberOfLines = 3;
    
    [modeButton addTarget:self action:@selector(toggleMode) forControlEvents:UIControlEventTouchUpInside];
    [startButton addTarget:self action:@selector(start) forControlEvents:UIControlEventTouchUpInside];
    [stopButton addTarget:self action:@selector(stop) forControlEvents:UIControlEventTouchUpInside];
    [initManuelModeButton addTarget:self action:@selector(initManuel) forControlEvents:UIControlEventTouchUpInside];
    [deinitManuelModeButton addTarget:self action:@selector(deinitManuel) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:modeButton];
    [self.view addSubview:startButton];
    [self.view addSubview:stopButton];
    [self.view addSubview:initManuelModeButton];
    [self.view addSubview:deinitManuelModeButton];
    
    statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:statusLabel];
    [NSLayoutConstraint activateConstraints:@[
        [statusLabel.topAnchor constraintGreaterThanOrEqualToAnchor:deinitManuelModeButton.bottomAnchor constant:10],
        [statusLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor],
        [statusLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor]
    ]];
    
    self.modeButton = modeButton;
    self.startButton = startButton;
    self.stopButton = stopButton;
    self.statusLabel = statusLabel;
}

- (void)toggleMode
{
    [self.dmMgr modeToggleOnCompleteion:^(NSString * errMsg, BOOL result) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __weak DriveMotionViewController *weakself = self;
            [weakself.modeButton setTitle:[NSString stringWithFormat:@"Current mode: %@", self.dmMgr.getModeString] forState:UIControlStateNormal];
            weakself.statusLabel.text = [NSString stringWithFormat:@"%s: %@", result == YES ? "[SUCCESS]" : "[FAILED]", errMsg];
        });
    }];
}

- (void)start
{
    [self.dmMgr startOnCompleteion:^(NSString * errMsg, BOOL result) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __weak DriveMotionViewController *weakself = self;
            weakself.statusLabel.text = [NSString stringWithFormat:@"%s: %@", result == YES ? "[SUCCESS]" : "[FAILED]", errMsg];
        });
    }];
}

- (void)stop
{
    [self.dmMgr stopOnCompleteion:^(NSString * errMsg, BOOL result) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __weak DriveMotionViewController *weakself = self;
            weakself.statusLabel.text = [NSString stringWithFormat:@"%s: %@", result == YES ? "[SUCCESS]" : "[FAILED]", errMsg];
        });
    }];
}

- (void)initManuel
{
    [self.dmMgr initManuelOnCompleteion:^(NSString * errMsg, BOOL result) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __weak DriveMotionViewController *weakself = self;
            weakself.statusLabel.text = [NSString stringWithFormat:@"%s: %@", result == YES ? "[SUCCESS]" : "[FAILED]", errMsg];
        });
    }];
}

- (void)deinitManuel
{
    [self.dmMgr deinitManuelOnCompleteion:^(NSString * errMsg, BOOL result) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __weak DriveMotionViewController *weakself = self;
            weakself.statusLabel.text = [NSString stringWithFormat:@"%s: %@", result == YES ? "[SUCCESS]" : "[FAILED]", errMsg];
        });
    }];
}

- (void)dealloc
{
    self.dmMgr = nil;
}

@end
