//
//  UIViewController+Additions.h
//  PerformanceTest
//
//  Created by Zheng, Haiqiang (Jason) on 2024/7/4.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (Additions)
- (UIButton *)createButtonWithTitle:(NSString *)title
                              frame:(CGRect)frame;

- (void)addTitleLineWith:(NSString *)title;

- (void)back;

- (float)getBodyTemperature;

- (float)getBatteryTemperature;

- (NSDictionary *)endRecordWithstartTime:(NSDate *)startTime
                           startBodyTemp:(float)startBodyTemp
                        startBatteryTemp:(float)startBatteryTemp
                                testType:(NSString *)testType;

- (NSString *)formatDate:(NSDate *)date;
@end

NS_ASSUME_NONNULL_END
