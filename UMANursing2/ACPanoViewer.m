//
//  ACPanoViewer.m
//  ACPanoramaViewer
//
//  Created by Andrew J Cavanagh on 2/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACPanoViewer.h"

@interface ACPanoViewer ()
{
    CGPoint lastMovementPosition;
    CGPoint currentMovementPosition;
    GLKMatrix4 modelViewMatrix;
    GLKMatrix4 projectionMatrix;
    GLKMatrix4 modelMatrix;
    GLKMatrix4 viewMatrix;
    GLfloat tempXRotation;
    GLfloat tempYRotation;
}
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKSkyboxEffect *skyboxEffect;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *doneButton;
@end

@implementation ACPanoViewer

#pragma mark - OPENGLES Methods

- (void)setupGL
{
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    tempXRotation = 0;
    tempYRotation = 0;
    
    [EAGLContext setCurrentContext:self.context];
    self.skyboxEffect = [[GLKSkyboxEffect alloc] init];
    glEnable(GL_DEPTH_TEST);
    
    __block NSError *error;
    NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:GLKTextureLoaderOriginBottomLeft];
    
    NSArray *cubeMapFileNames = [NSArray arrayWithObjects:
                                 [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%@0001", self.panoKey] ofType:@"tif"],
                                 [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%@0003", self.panoKey] ofType:@"tif"],
                                 [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%@0005", self.panoKey] ofType:@"tif"],
                                 [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%@0004", self.panoKey] ofType:@"tif"],
                                 [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%@0000", self.panoKey] ofType:@"tif"],
                                 [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%@0002", self.panoKey] ofType:@"tif"],
                                 nil];
    
    GLKTextureInfo *cubemap = [GLKTextureLoader cubeMapWithContentsOfFiles:cubeMapFileNames options:options error:&error];
    self.skyboxEffect.textureCubeMap.name = cubemap.name;
    
    glBindVertexArrayOES(0);
    
    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 100.0f);
    
    GLKMatrix4 yRotations = GLKMatrix4MakeYRotation(0);
    GLKMatrix4 xRotations = GLKMatrix4MakeXRotation(0);
    modelMatrix = GLKMatrix4Multiply(xRotations, yRotations);
    viewMatrix = GLKMatrix4MakeLookAt(0, 0, 0, 90, 0, 1, 0, -1, 0);
    modelViewMatrix = GLKMatrix4Multiply(viewMatrix, modelMatrix);
    
    [self configureProjectionMatrix];
    
    [self setPaused:NO];
}

- (void)update
{
    self.skyboxEffect.transform.projectionMatrix = projectionMatrix;
    self.skyboxEffect.transform.modelviewMatrix = modelViewMatrix;
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    [self.skyboxEffect prepareToDraw];
    [self.skyboxEffect draw];
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];    
    self.skyboxEffect = nil;

    glDeleteVertexArraysOES(0, 0);
}

#pragma mark - touch methods

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{    
    if ([[event allTouches] count] == 1)
    {
        lastMovementPosition = [[touches anyObject] locationInView:self.view];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
{ 
    if ([[event allTouches] count] == 1)
    {
        currentMovementPosition = [[touches anyObject] locationInView:self.view];
        [self rotateViewFromScreenDisplacementInX:(currentMovementPosition.x - lastMovementPosition.x) inY:(currentMovementPosition.y - lastMovementPosition.y)];
        lastMovementPosition = currentMovementPosition;
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event 
{
	lastMovementPosition = [[touches anyObject] locationInView:self.view];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event 
{
	lastMovementPosition = [[touches anyObject] locationInView:self.view];
}

- (void)rotateViewFromScreenDisplacementInX:(float)xRotation inY:(float)yRotation;
{
    tempYRotation -= GLKMathDegreesToRadians(xRotation);
    tempXRotation -= GLKMathDegreesToRadians(yRotation);
    
    if (tempXRotation > 10)
    {
        tempXRotation = 10;
    }
    
    if (tempXRotation < -10)
    {
        tempXRotation = -10;
    }
    GLKMatrix4 yRotations = GLKMatrix4MakeYRotation(-tempYRotation * 0.15);
    GLKMatrix4 xRotations = GLKMatrix4MakeZRotation(-tempXRotation * 0.15);
    modelMatrix = GLKMatrix4Multiply(xRotations, yRotations);
    viewMatrix = GLKMatrix4MakeLookAt(0, 0, 0, 90, 0, 1, 0, -1, 0);
    
    modelViewMatrix = GLKMatrix4Multiply(viewMatrix, modelMatrix);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.doneButton setTarget:self];
    [self.doneButton setAction:@selector(stop)];
    [self.view setBackgroundColor:[UIColor scrollViewTexturedBackgroundColor]];
    [self.navigationController.navigationBar setTranslucent:YES];
    [self setupGL];
}

- (void)stop
{
    [self tearDownGL];
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
	self.context = nil;
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidUnload
{
    [self tearDownGL];
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
	self.context = nil;
    
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self configureProjectionMatrix];
}

- (void)configureProjectionMatrix
{
    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 100.0f);
}

@end
