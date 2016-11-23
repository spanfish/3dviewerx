//
//  AppDelegate.h
//  3DViewerX
//
//  Created by xiangwei wang on 2016/10/28.
//  Copyright © 2016年 xiangwei wang. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property(nonatomic, assign) float zoom;
@property(nonatomic, assign) float rotationx;
@property(nonatomic, assign) float rotationy;
@property(nonatomic, assign) float rotationz;
@end

