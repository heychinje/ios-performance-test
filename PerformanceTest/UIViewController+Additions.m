//
//  UIViewController+Additions.m
//  PerformanceTest
//
//  Created by Zheng, Haiqiang (Jason) on 2024/7/4.
//

#import "UIViewController+Additions.h"

@implementation UIViewController (Additions)

- (UIButton *)createButtonWithTitle:(NSString *)title
                           frame:(CGRect)frame
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.backgroundColor = [UIColor blueColor];
    button.layer.cornerRadius = 10;
    button.clipsToBounds = YES;
    button.frame = frame;
    return button;
}

- (void)addTitleLineWith:(NSString *)title
{
    // title label
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = title;
    titleLabel.textColor = [UIColor blackColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont boldSystemFontOfSize:20.0];
    [self.view addSubview:titleLabel];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [titleLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [titleLabel.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [titleLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:20],
        [titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-20]
    ]];
    
    // back button
    UIButton *backButton = [self createButtonWithTitle:@"Back" frame:CGRectMake(0, 0, 80, 40)];
    [backButton addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backButton];
    [NSLayoutConstraint activateConstraints:@[
        [backButton.topAnchor constraintEqualToAnchor:titleLabel.topAnchor],
        [backButton.bottomAnchor constraintEqualToAnchor:titleLabel.bottomAnchor],
        [backButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]
    ]];
}

- (void)back
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (float)getBodyTemperature {
    return 36.5; // For example purposes
}

- (float)getBatteryTemperature {
    return 30.0; // For example purposes
}

- (NSDictionary *)endRecordWithstartTime:(NSDate *)startTime
                           startBodyTemp:(float)startBodyTemp
                        startBatteryTemp:(float)startBatteryTemp
                                testType:(NSString *)testType
{
    NSDate *endTime = [NSDate date];
    float endBodyTemp = [self getBodyTemperature];
    float endBatteryTemp = [self getBatteryTemperature];
    
    NSDictionary *record = @{
        @"testType": testType,
        @"startTime": [self formatDate:startTime],
        @"endTime": [self formatDate:endTime],
        @"startBodyTemp": @(startBodyTemp),
        @"endBodyTemp": @(endBodyTemp),
        @"bodyTempDiff": @(endBodyTemp - startBodyTemp),
        @"startBatteryTemp": @(startBatteryTemp),
        @"endBatteryTemp": @(endBatteryTemp),
        @"batteryTempDiff": @(endBatteryTemp - startBatteryTemp)
    };
    
    return record;
}

- (NSString *)formatDate:(NSDate *)date {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss"];
    return [dateFormatter stringFromDate:date];
}


@end
