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
    [modeButton addTarget:self action:@selector(toggleMode) forControlEvents:UIControlEventTouchUpInside];
    [startButton addTarget:self action:@selector(start) forControlEvents:UIControlEventTouchUpInside];
    [stopButton addTarget:self action:@selector(stop) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:modeButton];
    [self.view addSubview:startButton];
    [self.view addSubview:stopButton];
    
    self.modeButton = modeButton;
    self.startButton = startButton;
    self.stopButton = stopButton;
}

- (void)toggleMode
{
    [self.dmMgr modeToggle];
    [self.modeButton setTitle:[NSString stringWithFormat:@"Current mode: %@", self.dmMgr.getModeString] forState:UIControlStateNormal];
}

- (void)start
{
    if (![self.dmMgr isInitialized]) {
        TNDriveDetectionMode mode = self.dmMgr.getCurrentMode;
        if (mode == TNDriveDetectionModeAuto) {
            [self.dmMgr startAutoMode];
        } else {
            [self.dmMgr startManuelMode];
        }
    }
}

- (void)stop
{
    if ([self.dmMgr isInitialized]) {
        TNDriveDetectionMode mode = self.dmMgr.getCurrentMode;
        if (mode == TNDriveDetectionModeAuto) {
            [self.dmMgr stopAutoMode];
        } else {
            [self.dmMgr stopManuelMode];
        }
    }
}

@end
