//
//  GLView.m
//  3DViewerX
//
//  Created by xiangwei wang on 2016/10/28.
//  Copyright © 2016年 xiangwei wang. All rights reserved.
//

#import "GLView.h"
#import "AppDelegate.h"

#define SUPPORT_RETINA_RESOLUTION 1

@interface GLView()

- (CVReturn) getFrameForTime:(const CVTimeStamp*)outputTime;
@end

// This is the renderer output callback function
static CVReturn MyDisplayLinkCallback(CVDisplayLinkRef displayLink,
                                      const CVTimeStamp* now,
                                      const CVTimeStamp* outputTime,
                                      CVOptionFlags flagsIn,
                                      CVOptionFlags* flagsOut,
                                      void* displayLinkContext)
{
    CVReturn result = [(__bridge GLView*)displayLinkContext getFrameForTime:outputTime];
    return result;
}

@implementation GLView

- (CVReturn) getFrameForTime:(const CVTimeStamp*)outputTime
{
    // There is no autorelease pool when this method is called
    // because it will be called from a background thread.
    // It's important to create one or app can leak objects.
    @autoreleasepool {
        [self drawView];
    }
    return kCVReturnSuccess;
}

+(NSOpenGLPixelFormat *) defaultPixelFormat
{
    NSOpenGLPixelFormatAttribute attrs[] =
    {
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFADepthSize, 24,
        // Must specify the 3.2 Core Profile to use OpenGL 3.2
        NSOpenGLPFAOpenGLProfile,
        NSOpenGLProfileVersion3_2Core,
        0
    };
    
    NSOpenGLPixelFormat *pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
    if (!pf)
    {
        NSLog(@"No OpenGL pixel format");
    }
    return pf;
}

-(id) initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if(self)
    {
        
    }
    return self;
}

-(void) awakeFromNib {
    [self registerForDraggedTypes:@[NSFilenamesPboardType]];
    [self initGL];
}
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    return NSDragOperationGeneric;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard *pboard = [sender draggingPasteboard];
    NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
    NSLog(@"files:%@", files);
    return YES;
}


-(void) setModel:(Model *)model
{
    _model = model;
    
    if(!model) {
        return;
    }
    _renderer = [[GLRenderer alloc] initWithModel:model];
    
//    [_renderer bind:@"backgroundR" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.backgroundR" options:nil];
//    [_renderer bind:@"backgroundG" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.backgroundG" options:nil];
//    [_renderer bind:@"backgroundB" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.backgroundB" options:nil];
    
    [_renderer bind:@"ambientR" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.ambientR" options:nil];
    [_renderer bind:@"ambientG" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.ambientG" options:nil];
    [_renderer bind:@"ambientB" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.ambientB" options:nil];

    AppDelegate *appDelegate = [NSApplication sharedApplication].delegate;
    [_renderer bind:@"zoom" toObject:appDelegate withKeyPath:@"zoom" options:nil];
    [_renderer bind:@"rotationx" toObject:appDelegate withKeyPath:@"rotationx" options:nil];
    [_renderer bind:@"rotationy" toObject:appDelegate withKeyPath:@"rotationy" options:nil];
    [_renderer bind:@"rotationz" toObject:appDelegate withKeyPath:@"rotationz" options:nil];
    
    // Create a display link capable of being used with all active displays
    CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
    
    // Set the renderer output callback function
    CVDisplayLinkSetOutputCallback(displayLink, &MyDisplayLinkCallback, (__bridge void*)self);
    
    // Set the display link for the current renderer
    CGLContextObj cglContext = [[self openGLContext] CGLContextObj];
    CGLPixelFormatObj cglPixelFormat = [[self pixelFormat] CGLPixelFormatObj];
    CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink, cglContext, cglPixelFormat);
    
    // Activate the display link
    CVDisplayLinkStart(displayLink);
    
    // Register to be notified when the window closes so we can stop the displaylink
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(windowWillClose:)
                                                 name:NSWindowWillCloseNotification
                                               object:[self window]];
    [self reshape];
}

-(void) initGL
{
    NSOpenGLPixelFormat *pf = [GLView defaultPixelFormat];
    
    NSOpenGLContext* context = [[NSOpenGLContext alloc] initWithFormat:pf shareContext:nil];
    
    CGLEnable([context CGLContextObj], kCGLCECrashOnRemovedFunctions);
    
    [self setPixelFormat:pf];
    [self setOpenGLContext:context];
    
    // SUPPORT_RETINA_RESOLUTION
    [self setWantsBestResolutionOpenGLSurface:YES];
    
    // The reshape function may have changed the thread to which our OpenGL
    // context is attached before prepareOpenGL and initGL are called.  So call
    // makeCurrentContext to ensure that our OpenGL context current to this
    // thread (i.e. makeCurrentContext directs all OpenGL calls on this thread
    // to [self openGLContext])
    [[self openGLContext] makeCurrentContext];
    
    // Synchronize buffer swaps with vertical refresh rate
    GLint swapInt = 1;
    [[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
}
//
//This method is called only once after the OpenGL context is made the current context.
//Subclasses that implement this method can use it to configure the Open GL state in preparation for drawing.
//- (void) prepareOpenGL
//{
    //[super prepareOpenGL];
    
    // Make all the OpenGL calls to setup rendering
    //  and build the necessary rendering objects
    //[self initGL];
//}

- (void) windowWillClose:(NSNotification*)notification
{
    // Stop the display link when the window is closing because default
    // OpenGL render buffers will be destroyed.  If display link continues to
    // fire without renderbuffers, OpenGL draw calls will set errors.
    
    CVDisplayLinkStop(displayLink);
}

- (void)reshape
{
    [super reshape];
    
    // We draw on a secondary thread through the display link. However, when
    // resizing the view, -drawRect is called on the main thread.
    // Add a mutex around to avoid the threads accessing the context
    // simultaneously when resizing.
    CGLLockContext([[self openGLContext] CGLContextObj]);
    
    // Get the view size in Points
    NSRect viewRectPoints = [self bounds];
    
#if SUPPORT_RETINA_RESOLUTION
    
    // Rendering at retina resolutions will reduce aliasing, but at the potential
    // cost of framerate and battery life due to the GPU needing to render more
    // pixels.
    
    // Any calculations the renderer does which use pixel dimentions, must be
    // in "retina" space.  [NSView convertRectToBacking] converts point sizes
    // to pixel sizes.  Thus the renderer gets the size in pixels, not points,
    // so that it can set it's viewport and perform and other pixel based
    // calculations appropriately.
    // viewRectPixels will be larger than viewRectPoints for retina displays.
    // viewRectPixels will be the same as viewRectPoints for non-retina displays
    NSRect viewRectPixels = [self convertRectToBacking:viewRectPoints];
    
#else //if !SUPPORT_RETINA_RESOLUTION
    
    // App will typically render faster and use less power rendering at
    // non-retina resolutions since the GPU needs to render less pixels.
    // There is the cost of more aliasing, but it will be no-worse than
    // on a Mac without a retina display.
    
    // Points:Pixels is always 1:1 when not supporting retina resolutions
    NSRect viewRectPixels = viewRectPoints;
    
#endif // !SUPPORT_RETINA_RESOLUTION
    
    // Set the new dimensions in our renderer
    [_renderer resizeWithWidth:viewRectPixels.size.width
                     AndHeight:viewRectPixels.size.height];
    
    CGLUnlockContext([[self openGLContext] CGLContextObj]);
}


- (void)renewGState
{
    // Called whenever graphics state updated (such as window resize)
    
    // OpenGL rendering is not synchronous with other rendering on the OSX.
    // Therefore, call disableScreenUpdatesUntilFlush so the window server
    // doesn't render non-OpenGL content in the window asynchronously from
    // OpenGL content, which could cause flickering.  (non-OpenGL content
    // includes the title bar and drawing done by the app with other APIs)
    [[self window] disableScreenUpdatesUntilFlush];
    
    [super renewGState];
}

- (void) drawRect: (NSRect) theRect
{
    // Called during resize operations
    
    // Avoid flickering during resize by drawiing
    [self drawView];
}

- (void) drawView {
    if(!_renderer) {
        return;
    }
    [[self openGLContext] makeCurrentContext];
    
    // We draw on a secondary thread through the display link
    // When resizing the view, -reshape is called automatically on the main
    // thread. Add a mutex around to avoid the threads accessing the context
    // simultaneously when resizing
    CGLLockContext([[self openGLContext] CGLContextObj]);
    
    [_renderer render];
    
    CGLFlushDrawable([[self openGLContext] CGLContextObj]);
    CGLUnlockContext([[self openGLContext] CGLContextObj]);
}

- (void) dealloc
{
    // Stop the display link BEFORE releasing anything in the view
    // otherwise the display link thread may call into the view and crash
    // when it encounters something that has been release
    CVDisplayLinkStop(displayLink);
    
    CVDisplayLinkRelease(displayLink);
}

-(NSArray<NSString *>*) exposedBindings
{
    return @[@"backgrundR"];
}

-(GLRenderer*) renderer {
    return _renderer;
}
@end
