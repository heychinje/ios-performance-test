//
//  OpenGLUIViewController.m
//  PerformanceTest
//
//  Created by Zheng, Haiqiang (Jason) on 2024/7/4.
//
#import <GLKit/GLKit.h>
#import "OpenGLUIViewController.h"
#import "UIViewController+Additions.h"
#import <OpenGLES/ES2/gl.h>
#import "GLESUtils.h"
#import "GLESMath.h"

@interface OpenGLUIViewController ()
@property (nonatomic , strong) EAGLContext* myContext;
@property (nonatomic , strong) CAEAGLLayer* myEagLayer;
@property (nonatomic , assign) GLuint       myProgram;
@property (nonatomic , assign) GLuint       myVertices;
@property (nonatomic , assign) GLuint       texture;
@property (nonatomic , assign) GLuint myColorRenderBuffer;
@property (nonatomic , assign) GLuint myColorFrameBuffer;
@property (nonatomic , strong) CADisplayLink* displayLink;

@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, assign) float startBodyTemp;
@property (nonatomic, assign) float startBatteryTemp;

@end

GLfloat attrArr[] =
{
    // position               // colors
    -0.5f,  0.5f,  0.0f,      0.5f, 1.0f, 0.0f, //left-up
     0.5f,  0.5f,  0.0f,      1.0f, 0.0f, 0.0f, //right-up
    -0.5f, -0.5f,  0.0f,      0.3f, 0.0f, 1.0f, //left-down
     0.5f, -0.5f,  0.0f,      0.0f, 1.0f, 0.0f, //right-down
     0.0f,  0.0f,  1.0f,      1.0f, 1.0f, 1.0f, //front
};

GLuint indices[] =
{
    0, 3, 2,
    0, 1, 3,
    0, 2, 4,
    0, 4, 1,
    2, 3, 4,
    1, 4, 3,
};

@implementation OpenGLUIViewController

{
    float xDegree;
    float yDegree;
    float zDegree;
}

- (void)viewDidLoad
{
    self.startTime = [NSDate date];
    self.startBodyTemp = [self getBodyTemperature];
    self.startBatteryTemp = [self getBatteryTemperature];
    
    UILabel *msgLabel = [[UILabel alloc] initWithFrame:CGRectMake(100, 0, 400, 60)];
    msgLabel.text = @"OpenGLES Testing";
    msgLabel.textColor = UIColor.whiteColor;
    [self.view addSubview:msgLabel];
    
    [self setupLayer];
    [self setupContext];
    [self destoryRenderAndFrameBuffer];
    [self setupRenderBuffer];
    [self setupFrameBuffer];
    [self setupTexture];
    [self setupLink];
}

- (void)setupLink
{
    CADisplayLink *displayLink = [UIScreen.mainScreen displayLinkWithTarget:self selector:@selector(update)];
    displayLink.preferredFramesPerSecond = 120;
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    self.displayLink = displayLink;
}

- (void)setupTexture
{
    CGImageRef img = [UIImage imageNamed:@"opengl-es"].CGImage;
    size_t w = CGImageGetWidth(img);
    size_t h = CGImageGetHeight(img);
    GLubyte *imgData = calloc(w * h * 4, sizeof(img));
    CGContextRef imgContext = CGBitmapContextCreate(
                                                    imgData,
                                                    w,
                                                    h,
                                                    8,
                                                    w * 4,
                                                    CGImageGetColorSpace(img),
                                                    kCGImageAlphaPremultipliedLast
                                                    );
    
    CGContextDrawImage(imgContext, CGRectMake(0, 0, w, h), img);
    CGContextRelease(imgContext);
    
    GLuint texture;
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)w, (GLsizei)h, 0, GL_RGBA, GL_UNSIGNED_BYTE, imgData);
    
    free(imgData);
    self.texture = texture;
}

- (void)update
{
    xDegree += 1;
    yDegree += 2;
    zDegree += 3;
    [self render];
}

- (void)render {
    glClearColor(0, 0.0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    CGFloat scale = 3;
    CGRect rect = self.view.bounds;
    glViewport(-140, -140, rect.size.width * scale, rect.size.height * scale);
    NSString* vertFile = [[NSBundle mainBundle] pathForResource:@"Vertex" ofType:@"glsl"];
    NSString* fragFile = [[NSBundle mainBundle] pathForResource:@"Fragment" ofType:@"glsl"];
    
    if (self.myProgram) {
//        if (![self validate:self.myProgram]) {
//            NSLog(@"Failed to validate program: %d", self.myProgram);
//        }
        glDeleteProgram(self.myProgram);
        self.myProgram = 0;
    }
    self.myProgram = [self loadShaders:vertFile frag:fragFile];
    
    glLinkProgram(self.myProgram);
    GLint linkSuccess;
    glGetProgramiv(self.myProgram, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(self.myProgram, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"error%@", messageString);

        return ;
    }
    else {
        glUseProgram(self.myProgram);
    }
    
    if (self.myVertices == 0) {
        glGenBuffers(1, &_myVertices);
    }

    glBindBuffer(GL_ARRAY_BUFFER, _myVertices);
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, _myVertices);
    
    GLuint position = glGetAttribLocation(self.myProgram, "position");
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 6, NULL);
    glEnableVertexAttribArray(position);
    
    GLuint positionColor = glGetAttribLocation(self.myProgram, "positionColor");
    glVertexAttribPointer(positionColor, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 6, (float *)NULL + 3);
    glEnableVertexAttribArray(positionColor);
    
//    GLuint texCoord = glGetAttribLocation(self.myProgram, "texCoord");
//    glVertexAttribPointer(texCoord, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 8, (float *)NULL + 6);
//    glEnableVertexAttribArray(texCoord);
    
    GLuint projectionMatrixSlot = glGetUniformLocation(self.myProgram, "projectionMatrix");
    GLuint modelViewMatrixSlot = glGetUniformLocation(self.myProgram, "modelViewMatrix");
    
    float width = self.view.frame.size.width;
    float height = self.view.frame.size.height;
    

    KSMatrix4 _projectionMatrix;
    ksMatrixLoadIdentity(&_projectionMatrix);
    float aspect = width / height; //长宽比
    
    ksPerspective(&_projectionMatrix, 30.0, aspect, 5.0f, 20.0f); //透视变换，视角30°
    
    //设置glsl里面的投影矩阵
    glUniformMatrix4fv(projectionMatrixSlot, 1, GL_FALSE, (GLfloat*)&_projectionMatrix.m[0][0]);
    
    glEnable(GL_CULL_FACE);
    
    
    KSMatrix4 _modelViewMatrix;
    ksMatrixLoadIdentity(&_modelViewMatrix);
    
    //平移
    ksTranslate(&_modelViewMatrix, 0.0, 0.0, -10.0);
    KSMatrix4 _rotationMatrix;
    ksMatrixLoadIdentity(&_rotationMatrix);
    
    //旋转
    ksRotate(&_rotationMatrix, xDegree, 1.0, 0.0, 0.0); //绕X轴
    ksRotate(&_rotationMatrix, yDegree, 0.0, 1.0, 0.0); //绕Y轴
    ksRotate(&_rotationMatrix, zDegree, 0.0, 0.0, 1.0); //绕Z轴
    
    //把变换矩阵相乘，注意先后顺序
    ksMatrixMultiply(&_modelViewMatrix, &_rotationMatrix, &_modelViewMatrix);
    
    // Load the model-view matrix
    glUniformMatrix4fv(modelViewMatrixSlot, 1, GL_FALSE, (GLfloat*)&_modelViewMatrix.m[0][0]);
    
    // load texture
//    glActiveTexture(GL_TEXTURE0);
//    glBindTexture(GL_TEXTURE_2D, self.texture);
//    GLuint textureUniform = glGetUniformLocation(self.myProgram, "texture");
//    glUniform1i(textureUniform, 0);
    
    glDrawElements(GL_TRIANGLES, sizeof(indices) / sizeof(indices[0]), GL_UNSIGNED_INT, indices);
    
    [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
}

- (GLuint)loadShaders:(NSString *)vert frag:(NSString *)frag {
    GLuint verShader, fragShader;
    GLint program = glCreateProgram();
    
    [self compileShader:&verShader type:GL_VERTEX_SHADER file:vert];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:frag];
    
    glAttachShader(program, verShader);
    glAttachShader(program, fragShader);
    
    
    // Free up no longer needed shader resources
    glDeleteShader(verShader);
    glDeleteShader(fragShader);
    
    return program;
}

- (BOOL)validate:(GLuint)_programId {
    GLint logLength, status;
    
    glValidateProgram(_programId);
    glGetProgramiv(_programId, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(_programId, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(_programId, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    return YES;
}

- (void)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file {
    NSString* content = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    const GLchar* source = (GLchar *)[content UTF8String];
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
    // Check for compile errors
    GLint compileSuccess;
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(*shader, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@ shader compilation error: %@", (type == GL_VERTEX_SHADER ? @"Vertex" : @"Fragment"), messageString);
        glDeleteShader(*shader);
    }
}

- (void)setupLayer
{
    self.myEagLayer = (CAEAGLLayer*) self.view.layer;
    [self.view setContentScaleFactor:[[UIScreen mainScreen] scale]];
    
    // CALayer 默认是透明的，必须将它设为不透明才能让其可见
    self.myEagLayer.opaque = YES;
    
    // 设置描绘属性，在这里设置不维持渲染内容以及颜色格式为 RGBA8
    self.myEagLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
}


- (void)setupContext {
    // 指定 OpenGL 渲染 API 的版本，在这里我们使用 OpenGL ES 2.0
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    EAGLContext* context = [[EAGLContext alloc] initWithAPI:api];
    if (!context) {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        exit(1);
    }
    
    // 设置为当前上下文
    if (![EAGLContext setCurrentContext:context]) {
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
    self.myContext = context;
}

- (void)setupRenderBuffer {
    GLuint buffer;
    glGenRenderbuffers(1, &buffer);
    self.myColorRenderBuffer = buffer;
    glBindRenderbuffer(GL_RENDERBUFFER, self.myColorRenderBuffer);
    // 为 color renderbuffer 分配存储空间
    [self.myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myEagLayer];
}


- (void)setupFrameBuffer {
    GLuint buffer;
    glGenFramebuffers(1, &buffer);
    self.myColorFrameBuffer = buffer;
    // 设置为当前 framebuffer
    glBindFramebuffer(GL_FRAMEBUFFER, self.myColorRenderBuffer);
    // 将 _colorRenderBuffer 装配到 GL_COLOR_ATTACHMENT0 这个装配点上
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER, self.myColorRenderBuffer);
}


- (void)destoryRenderAndFrameBuffer
{
    glDeleteFramebuffers(1, &_myColorFrameBuffer);
    self.myColorFrameBuffer = 0;
    glDeleteRenderbuffers(1, &_myColorRenderBuffer);
    self.myColorRenderBuffer = 0;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.displayLink invalidate];
    self.displayLink = nil;
    
    [self destoryRenderAndFrameBuffer];
    
    if (self.myProgram != 0) {
        glDeleteProgram(self.myProgram);
        self.myProgram = 0;
    }
    
    if ([EAGLContext currentContext] == self.myContext) {
        [EAGLContext setCurrentContext:nil];
    }
    self.myContext = nil;
    
    NSDictionary *record = [self endRecordWithstartTime:self.startTime
                                          startBodyTemp:self.startBodyTemp
                                       startBatteryTemp:self.startBatteryTemp
                                               testType:@"OpenGLES"];
    
    [self.testRecords addObject:record];
}
@end
