//
//  MainUIViewController.m
//  PerformanceTest
//
//  Created by Zheng, Haiqiang (Jason) on 2024/7/3.
//

#import <Foundation/Foundation.h>
#import "MainUIViewController.h"
#import "UIViewController+Additions.h"
#import "OpenGLES/OpenGLUIViewController.h"
#import "Metal/MetalUIViewController.h"
#import "DriveMotion/DriveMotionViewController.h"
#import "APM/APMViewController.h"

@interface MainUIViewController() <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *testRecords;

@end

@implementation MainUIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGFloat buttonWidth = [UIScreen mainScreen].bounds.size.width - 100 * 2;
    
    UIButton *glButton = [self createButtonWithTitle:@"OpenGL" frame:CGRectMake(100, 40, buttonWidth, 40)];
    UIButton *mtButton = [self createButtonWithTitle:@"Metal" frame:CGRectMake(100, 90, buttonWidth, 40)];
    UIButton *dmButton = [self createButtonWithTitle:@"DriveMotion" frame:CGRectMake(100, 140, buttonWidth, 40)];
    UIButton *apmButton = [self createButtonWithTitle:@"APM" frame:CGRectMake(100, 190, buttonWidth, 40)];
    [glButton addTarget:self action:@selector(toOpenGLPage) forControlEvents:UIControlEventTouchUpInside];
    [mtButton addTarget:self action:@selector(toMetalPage) forControlEvents:UIControlEventTouchUpInside];
    [dmButton addTarget:self action:@selector(toDriveMotionPage) forControlEvents:UIControlEventTouchUpInside];
    [apmButton addTarget:self action:@selector(toAPMPage) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:glButton];
    [self.view addSubview:mtButton];
    [self.view addSubview:dmButton];
    [self.view addSubview:apmButton];
    
    CGFloat tableWidth = [UIScreen mainScreen].bounds.size.width;
    self.view.backgroundColor = [UIColor whiteColor];
    self.testRecords = [NSMutableArray array];
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 140, tableWidth, 400) style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 100;
//    [self.view addSubview:self.tableView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.tableView reloadData];
}

- (void)toOpenGLPage
{
    OpenGLUIViewController *vc = [OpenGLUIViewController new];
    vc.testRecords = self.testRecords;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)toMetalPage
{
    MetalUIViewController *vc = [MetalUIViewController new];
    vc.testRecords = self.testRecords;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)toDriveMotionPage
{
    DriveMotionViewController *vc = [DriveMotionViewController new];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)toAPMPage
{
    APMViewController *vc = [APMViewController new];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.testRecords.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    }
    NSDictionary *record = self.testRecords[indexPath.row];
    NSString *lineTitle = [NSString stringWithFormat:@"Test %ld: %@", (long)indexPath.row + 1, record[@"testType"]];
    NSString *lineDetail = [NSString stringWithFormat:
                            @"Time: %@ -> %@ \nBody Temp: %@ -> %@(%@) \nBattery Temp: %@ -> %@(%@)",
                            record[@"startTime"],
                            record[@"endTime"],
                            record[@"startBodyTemp"],
                            record[@"endBodyTemp"],
                            record[@"bodyTempDiff"],
                            record[@"startBatteryTemp"],
                            record[@"endBatteryTemp"],
                            record[@"batteryTempDiff"]
    ];
    cell.detailTextLabel.numberOfLines = 0;
    cell.textLabel.text = lineTitle;
    cell.detailTextLabel.text = lineDetail;
    return cell;
}
@end
