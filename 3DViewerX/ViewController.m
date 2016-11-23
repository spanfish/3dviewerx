//
//  ViewController.m
//  3DViewerX
//
//  Created by xiangwei wang on 2016/10/28.
//  Copyright © 2016年 xiangwei wang. All rights reserved.
//

#import "ViewController.h"
#import "Define.h"
#import "GLView.h"
#import "GLRenderer.h"
#import "SettingWindowController.h"
#import "TransformWindowController.h"

@interface ViewController()
{
    SettingWindowController *_settingController;
    TransformWindowController *_transformController;
    Model *_model;
    GLRenderer *_renderer;
}
@property(nonatomic, assign) BOOL modelReady;
@property(nonatomic, weak) IBOutlet NSProgressIndicator *indicator;
@property(nonatomic, weak) IBOutlet GLView *glView;

@end

static void *ModelReadyContext = &ModelReadyContext;

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

-(void) loadModel:(NSString *) path
{
    [_indicator setUsesThreadedAnimation:YES];
    [_indicator startAnimation:nil];

    [self setModelReady:NO];
    //////////////////////////////
    // Load our character model //
    //////////////////////////////
    _model = [[Model alloc] initWithPath:path delegate:self];
    //[_model addObserver:self forKeyPath:@"ready" options:NSKeyValueObservingOptionNew context:ModelReadyContext];
}

//-(IBAction)settingClicked:(id)sender
//{
//    if (_settingController == nil) {
//        _settingController = [[SettingWindowController alloc] init];
//    }
//    
//    [_settingController.window orderFront:self];
//}
//
//-(IBAction)transformClicked:(id)sender
//{
//    if (_transformController == nil) {
//        _transformController = [[TransformWindowController alloc] init];
//    }
//    
//    [_transformController.window orderFront:self];
//}

#pragma mark - Model delegate
-(void) modelDidFinishedWithError:(NSError *) error {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self glViewModelChanged:_model];
    });
}

-(void) modelDidProcessed:(NSString *) process {
    
}

#pragma mark -
-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if(context == ModelReadyContext) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self glViewModelChanged:(Model *) object];
        });
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)setRepresentedObject:(id)representedObject
{
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (IBAction)zoom:(id)sender
{
    NSMagnificationGestureRecognizer * recognizer = sender;
    NSLog(@"magnification:%f", recognizer.magnification);
    _renderer.zoom += recognizer.magnification/10;
    _renderer.zoom = MIN(_renderer.zoom, 10);
    _renderer.zoom = MAX(_renderer.zoom, 0.1);
}

-(void) setModelReady:(BOOL)modelReady {
    _modelReady = modelReady;
    [[[NSApp mainWindow] toolbar] validateVisibleItems];
}
-(void) glViewModelChanged:(Model *) model {
    [self setModelReady:[model ready]];
    [self.glView setModel:_model];
    if(model) {
        _renderer = [self.glView renderer];
    } else {
        _renderer = nil;
    }
}

#pragma mark - Toolbar
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if([menuItem.identifier isEqualToString:OPEN_MENU_IDENTIFIER]) {
        return YES;
    } else if([menuItem.identifier isEqualToString:SNAPSHOT_MENU_IDENTIFIER]) {
        return _modelReady;
    }
    return [menuItem isEnabled];
}

-(BOOL) validateToolbarItem:(NSToolbarItem *)item {
    if([item.itemIdentifier isEqualToString:OPEN_MENU_IDENTIFIER]) {
        return YES;
    } else if([item.itemIdentifier isEqualToString:SNAPSHOT_MENU_IDENTIFIER]) {
        return _modelReady;
    }
    return [item isEnabled];
}

-(IBAction)openDocument:(id)sender {
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    panel.canChooseFiles = YES;
    panel.canChooseDirectories = YES;
    panel.allowsMultipleSelection = NO;
    [panel setAllowedFileTypes:@[@"obj"]];
    [panel beginWithCompletionHandler:^(NSInteger result) {
        if(result == NSFileHandlingPanelOKButton) {
            NSURL*  theModel = [[panel URLs] objectAtIndex:0];
            if(_model) {
                _model.delegate = nil;
                _model = nil;
            }
            [self glViewModelChanged:nil];
            [self loadModel:[theModel path]];
        }
    }];
}

-(IBAction)saveSnapshot:(id)sender {
}
@end
