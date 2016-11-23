//
//  GLView.h
//  3DViewerX
//
//  Created by xiangwei wang on 2016/10/28.
//  Copyright © 2016年 xiangwei wang. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GLRenderer.h"

@protocol GLViewDelegate <NSObject>


@end

@interface GLView : NSOpenGLView
{
@private
    CVDisplayLinkRef displayLink;
    GLRenderer *_renderer;
}

@property(nonatomic, strong) Model *model;

-(GLRenderer*) renderer;
@end
