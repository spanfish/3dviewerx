//
//  GLRenderer.h
//  3DViewerX
//
//  Created by xiangwei wang on 2016/10/28.
//  Copyright © 2016年 xiangwei wang. All rights reserved.
//
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl3.h>
#import <OpenGL/glext.h>

#import <Foundation/Foundation.h>

#import "Model.h"

typedef enum : NSUInteger {
    RENDER_AS_TRANGLES,
    RENDER_AS_DOTS,
} RenderType;

@interface GLRenderer : NSObject
{
    RenderType _renderType;
}

- (instancetype) initWithModel:(Model *)model;
- (void) resizeWithWidth:(GLuint)width AndHeight:(GLuint)height;
- (void) render;
- (void) dealloc;

@property(nonatomic, strong) Model *model;

@property(nonatomic, assign) float backgroundR;
@property(nonatomic, assign) float backgroundG;
@property(nonatomic, assign) float backgroundB;
@property(nonatomic, assign) BOOL showMaterial;

@property(nonatomic, assign) float ambientR;
@property(nonatomic, assign) float ambientG;
@property(nonatomic, assign) float ambientB;

@property(nonatomic, assign) float lightR;
@property(nonatomic, assign) float lightG;
@property(nonatomic, assign) float lightB;

@property(nonatomic, assign) float zoom;
@property(nonatomic, assign) float rotationx;
@property(nonatomic, assign) float rotationy;
@property(nonatomic, assign) float rotationz;

-(NSImage *) image;
-(void) renderAs:(RenderType) renderType;
@end
