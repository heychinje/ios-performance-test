//
//  MainUIViewController.m
//  PerformanceTest
//
//  Created by Zheng, Haiqiang (Jason) on 2024/7/3.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "MainUIViewController.h"
#import "UIViewController+Additions.h"
#import "OpenGLES/OpenGLUIViewController.h"
#import "Metal/MetalUIViewController.h"
#import "DriveMotion/DriveMotionViewController.h"
#import "APM/APMViewController.h"
#import "PerformanceTest-Swift.h"

@interface MainUIViewController() <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *testRecords;

// Background task properties
@property (nonatomic, strong) UISwitch *backgroundTaskSwitch;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong) NSTimer *backgroundTimer;

@end

@implementation MainUIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGFloat buttonWidth = [UIScreen mainScreen].bounds.size.width - 100 * 2;
    
    // Background task switch
    UILabel *backgroundLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 40, 200, 30)];
    backgroundLabel.text = @"Keep running in background";
    backgroundLabel.font = [UIFont systemFontOfSize:16];
    [self.view addSubview:backgroundLabel];
    
    self.backgroundTaskSwitch = [[UISwitch alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 70, 40, 50, 30)];
    [self.backgroundTaskSwitch addTarget:self action:@selector(backgroundTaskSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    
    // Set default state to ON
    [self.backgroundTaskSwitch setOn:YES animated:NO];
    
    [self.view addSubview:self.backgroundTaskSwitch];
    
    UIButton *glButton = [self createButtonWithTitle:@"OpenGL" frame:CGRectMake(100, 80, buttonWidth, 40)];
    UIButton *mtButton = [self createButtonWithTitle:@"Metal" frame:CGRectMake(100, 130, buttonWidth, 40)];
    UIButton *dmButton = [self createButtonWithTitle:@"DriveMotion" frame:CGRectMake(100, 180, buttonWidth, 40)];
    UIButton *apmButton = [self createButtonWithTitle:@"APM" frame:CGRectMake(100, 230, buttonWidth, 40)];
    UIButton *gpsButton = [self createButtonWithTitle:@"GPS" frame:CGRectMake(100, 280, buttonWidth, 40)];
    UIButton *videoButton = [self createButtonWithTitle:@"Video" frame:CGRectMake(100, 330, buttonWidth, 40)];
    UIButton *phoneCallButton = [self createButtonWithTitle:@"PhoneCall" frame:CGRectMake(100, 380, buttonWidth, 40)];
    [glButton addTarget:self action:@selector(toOpenGLPage) forControlEvents:UIControlEventTouchUpInside];
    [mtButton addTarget:self action:@selector(toMetalPage) forControlEvents:UIControlEventTouchUpInside];
    [dmButton addTarget:self action:@selector(toDriveMotionPage) forControlEvents:UIControlEventTouchUpInside];
    [apmButton addTarget:self action:@selector(toAPMPage) forControlEvents:UIControlEventTouchUpInside];
    [gpsButton addTarget:self action:@selector(toGpsPage) forControlEvents:UIControlEventTouchUpInside];
    [videoButton addTarget:self action:@selector(toVideoPage) forControlEvents:UIControlEventTouchUpInside];
    [phoneCallButton addTarget:self action:@selector(toPhoneCallPage) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:glButton];
    [self.view addSubview:mtButton];
    [self.view addSubview:dmButton];
    [self.view addSubview:apmButton];
    [self.view addSubview:gpsButton];
    [self.view addSubview:videoButton];
    [self.view addSubview:phoneCallButton];
    
    CGFloat tableWidth = [UIScreen mainScreen].bounds.size.width;
    self.view.backgroundColor = [UIColor whiteColor];
    self.testRecords = [NSMutableArray array];
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 140, tableWidth, 400) style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 100;
//    [self.view addSubview:self.tableView];
    
    // Setup audio session for background playback
    [self setupAudioSession];
    
    // Create audio player since switch is ON by default
    [self createSilentAudioPlayer];
    
    // Listen for app lifecycle notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopBackgroundTask];
}

#pragma mark - Audio Session Setup

- (void)setupAudioSession {
    NSError *error = nil;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    // Set audio session category to allow background playback
    [audioSession setCategory:AVAudioSessionCategoryPlayback
                  withOptions:AVAudioSessionCategoryOptionMixWithOthers
                        error:&error];
    
    if (error) {
        NSLog(@"Error setting audio session category: %@", error.localizedDescription);
    }
    
    // Activate the audio session
    [audioSession setActive:YES error:&error];
    
    if (error) {
        NSLog(@"Error activating audio session: %@", error.localizedDescription);
    }
}

- (void)createSilentAudioPlayer {
    // Create a silent audio file data (1 second of silence)
    NSMutableData *audioData = [NSMutableData data];
    
    // WAV file header for 1 second of silence (44100 Hz, 16-bit, mono)
    const char wavHeader[] = {
        'R', 'I', 'F', 'F',  // ChunkID
        0x24, 0x08, 0x00, 0x00,  // ChunkSize (36 + data size)
        'W', 'A', 'V', 'E',  // Format
        'f', 'm', 't', ' ',  // Subchunk1ID
        0x10, 0x00, 0x00, 0x00,  // Subchunk1Size (16 for PCM)
        0x01, 0x00,  // AudioFormat (PCM)
        0x01, 0x00,  // NumChannels (mono)
        0x44, 0xAC, 0x00, 0x00,  // SampleRate (44100)
        0x88, 0x58, 0x01, 0x00,  // ByteRate (44100 * 1 * 16/8)
        0x02, 0x00,  // BlockAlign (1 * 16/8)
        0x10, 0x00,  // BitsPerSample (16)
        'd', 'a', 't', 'a',  // Subchunk2ID
        0x00, 0x08, 0x00, 0x00   // Subchunk2Size (data size)
    };
    
    [audioData appendBytes:wavHeader length:sizeof(wavHeader)];
    
    // Add 1 second of silence (44100 samples * 2 bytes = 88200 bytes)
    NSUInteger silenceLength = 88200;
    char *silenceBuffer = calloc(silenceLength, 1);
    [audioData appendBytes:silenceBuffer length:silenceLength];
    free(silenceBuffer);
    
    NSError *error = nil;
    self.audioPlayer = [[AVAudioPlayer alloc] initWithData:audioData error:&error];
    
    if (error) {
        NSLog(@"Error creating audio player: %@", error.localizedDescription);
        return;
    }
    
    // Set to loop indefinitely
    self.audioPlayer.numberOfLoops = -1;
    self.audioPlayer.volume = 0.0; // Silent
    [self.audioPlayer prepareToPlay];
}

#pragma mark - Background Task Methods

- (void)backgroundTaskSwitchChanged:(UISwitch *)sender {
    NSLog(@"Background task switch changed to: %@", sender.isOn ? @"ON" : @"OFF");
    
    if (sender.isOn) {
        [self startBackgroundTask];
    } else {
        [self stopBackgroundTask];
    }
}

- (void)startBackgroundTask {
    NSLog(@"Starting background task...");
    
    // Create and prepare silent audio player
    [self createSilentAudioPlayer];
}

- (void)stopBackgroundTask {
    NSLog(@"Stopping background task...");
    
    // Stop audio player
    if (self.audioPlayer) {
        [self.audioPlayer stop];
        self.audioPlayer = nil;
    }
    
    // Stop timer
    if (self.backgroundTimer) {
        [self.backgroundTimer invalidate];
        self.backgroundTimer = nil;
    }
    
    // Deactivate audio session
    NSError *error = nil;
    [[AVAudioSession sharedInstance] setActive:NO error:&error];
    if (error) {
        NSLog(@"Error deactivating audio session: %@", error.localizedDescription);
    }
}

- (void)performBackgroundTask {
    // Simulate some background work
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"background tasks start ...");
        [NSThread sleepForTimeInterval:3.0];
        NSLog(@"background tasks stop!");
    });
}

#pragma mark - App Lifecycle Methods

- (void)appDidEnterBackground:(NSNotification *)notification {
    NSLog(@"App entered background");
    NSLog(@"Background switch is ON: %@", self.backgroundTaskSwitch.isOn ? @"YES" : @"NO");
    NSLog(@"Audio player exists: %@", self.audioPlayer ? @"YES" : @"NO");
    
    if (self.backgroundTaskSwitch.isOn) {
        if (self.audioPlayer) {
            // Start playing silent audio to keep app alive
            BOOL playResult = [self.audioPlayer play];
            NSLog(@"Started playing silent audio in background: %@", playResult ? @"SUCCESS" : @"FAILED");
            
            // Start background timer for periodic task
            self.backgroundTimer = [NSTimer scheduledTimerWithTimeInterval:10.0
                                                                    target:self
                                                                  selector:@selector(performBackgroundTask)
                                                                  userInfo:nil
                                                                   repeats:YES];
            NSLog(@"Background timer created");
            
            // Also fire immediately
            [self performBackgroundTask];
        } else {
            NSLog(@"Audio player not available, creating now...");
            [self createSilentAudioPlayer];
            if (self.audioPlayer) {
                BOOL playResult = [self.audioPlayer play];
                NSLog(@"Created and started audio player: %@", playResult ? @"SUCCESS" : @"FAILED");
                
                // Start background timer for periodic task
                self.backgroundTimer = [NSTimer scheduledTimerWithTimeInterval:10.0
                                                                        target:self
                                                                      selector:@selector(performBackgroundTask)
                                                                      userInfo:nil
                                                                       repeats:YES];
                NSLog(@"Background timer created");
                
                // Also fire immediately
                [self performBackgroundTask];
            }
        }
    } else {
        NSLog(@"Background task switch is OFF, not starting background tasks");
    }
}

- (void)appWillEnterForeground:(NSNotification *)notification {
    NSLog(@"App will enter foreground");
    
    // Stop playing audio when returning to foreground
    if (self.audioPlayer && self.audioPlayer.isPlaying) {
        [self.audioPlayer pause];
        NSLog(@"Paused silent audio when entering foreground");
    }
    
    // Stop timer when returning to foreground
    if (self.backgroundTimer) {
        [self.backgroundTimer invalidate];
        self.backgroundTimer = nil;
        NSLog(@"Stopped background timer when entering foreground");
    }
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
    [self pushViewController:[DriveMotionViewController class]];
}

- (void)toAPMPage
{
    [self pushViewController:[APMViewController class]];
}

- (void)toGpsPage
{
    [self pushViewController:[GpsUIViewController class]];
}

- (void)toVideoPage
{
    [self pushViewController:[AVPlayerUIViewController class]];
}

- (void)toPhoneCallPage
{
    [self pushViewController:[PhoneCallViewController class]];
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
