//
//  OpenGL01ViewController.m
//  PerformanceTest
//
//  Created by Zheng, Haiqiang (Jason) on 2024/7/7.
//

#import "OpenGL_1_VC.h"
#import <GLKit/GLKit.h>

@interface OpenGL_1_VC ()

@end

GLfloat vertex[] = {
    0.0f, 0.0f, 0.0f
};

@implementation OpenGL_1_VC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)setUpConfigWithFrame:(CGRect)frame {
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    GLKView *glkView = [[GLKView alloc] initWithFrame:frame];
    glkView.context = context;
    glkView.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    [EAGLContext setCurrentContext:context];
}


@end
