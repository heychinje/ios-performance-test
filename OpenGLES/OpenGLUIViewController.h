//
//  OpenGLUIViewController.h
//  PerformanceTest
//
//  Created by Zheng, Haiqiang (Jason) on 2024/7/4.
//


#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <GLKit/GLKit.h>

@interface OpenGLUIViewController : GLKViewController
@property (nonatomic, strong) NSMutableArray *testRecords;
@end
