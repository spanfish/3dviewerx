//
//  GLView.h
//  3DViewerX
//
//  Created by xiangwei wang on 2016/10/28.
//  Copyright © 2016年 xiangwei wang. All rights reserved.
//


#import "GLRenderer.h"

#if IOS
#import <GLKit/GLKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif

@protocol GLViewDelegate <NSObject>


@end

#if IOS
@interface OpenGLView : GLKView
#else
@interface OpenGLView : NSOpenGLView
#endif
{
@private
#if IOS
    CADisplayLink *displayLink;
#else
    CVDisplayLinkRef displayLink;
#endif
    GLRenderer *_renderer;
}

@property(nonatomic, strong) Model *model;

-(GLRenderer*) renderer;
@end
