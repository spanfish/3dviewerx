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

@interface GLRenderer : NSObject
{
#if DEBUG

#endif
}

- (instancetype) initWithModel:(Model *)model;
- (void) resizeWithWidth:(GLuint)width AndHeight:(GLuint)height;
- (void) render;
- (void) dealloc;

@property(nonatomic, strong) Model *model;

@property(nonatomic, assign) int backgroundR;
@property(nonatomic, assign) int backgroundG;
@property(nonatomic, assign) int backgroundB;

@property(nonatomic, assign) int ambientR;
@property(nonatomic, assign) int ambientG;
@property(nonatomic, assign) int ambientB;

@property(nonatomic, assign) float zoom;
@property(nonatomic, assign) float rotationx;
@property(nonatomic, assign) float rotationy;
@property(nonatomic, assign) float rotationz;
@end
