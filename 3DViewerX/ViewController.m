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
        float r = [[NSUserDefaults standardUserDefaults] floatForKey:@"BackgroundColor.R"];
        float g = [[NSUserDefaults standardUserDefaults] floatForKey:@"BackgroundColor.G"];
        float b = [[NSUserDefaults standardUserDefaults] floatForKey:@"BackgroundColor.B"];
        [_renderer setBackgroundR:r];
        [_renderer setBackgroundG:g];
        [_renderer setBackgroundB:b];
    } else {
        _renderer = nil;
    }
}

#pragma mark - Toolbar, Menu Validation
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if([menuItem.identifier isEqualToString:OPEN_MENU_IDENTIFIER]) {
        return YES;
    } else if([menuItem.identifier isEqualToString:SNAPSHOT_MENU_IDENTIFIER]) {
        return _modelReady;
    } else if([menuItem.identifier isEqualToString:BACKCOLOR_MENU_IDENTIFIER]) {
        return _modelReady;
    }
    return [menuItem isEnabled];
}

-(BOOL) validateToolbarItem:(NSToolbarItem *)item {
    if([item.itemIdentifier isEqualToString:OPEN_MENU_IDENTIFIER]) {
        return YES;
    } else if([item.itemIdentifier isEqualToString:SNAPSHOT_MENU_IDENTIFIER]) {
        return _modelReady;
    } else if([item.itemIdentifier isEqualToString:BACKCOLOR_MENU_IDENTIFIER]) {
        return _modelReady;
    }
    return [item isEnabled];
}

#pragma mark - Toolbar Event
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
    [_indicator startAnimation:self];
    [self performSelectorOnMainThread:@selector(renderAsImage) withObject:nil waitUntilDone:NO];
}

-(IBAction)chooseBackgroundColor:(id)sender {
    NSColorPanel *panel = [NSColorPanel sharedColorPanel];
    [panel setTarget:self];
    [panel setAction:@selector(colorUpdate:)];
    [panel orderFront:self];
}

#pragma mark -
-(void) renderAsImage {
    NSString *message = @"Snapshot generated";
    NSString *info = @"The snapshot was saved to your desktop";
    NSImage *image = [_renderer image];
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCGImage:[image CGImageForProposedRect:NULL context:NULL hints:NULL]];
    NSData *data = [rep representationUsingType:NSJPEGFileType properties:@{}];
    if(data) {
        NSArray * paths = NSSearchPathForDirectoriesInDomains (NSDesktopDirectory, NSUserDomainMask, YES);
        NSString * desktopPath = [paths objectAtIndex:0];
        NSString *fileName = [[_model.path lastPathComponent] stringByDeletingPathExtension];
        NSString *filePath = [[desktopPath stringByAppendingPathComponent:fileName] stringByAppendingPathExtension:@"jpg"];
        if([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        }
        [data writeToFile:filePath atomically:YES];
    }
    if(!image || !data) {
        message = @"Failure";
        info = @"Unable to generate a snapshot";
    }
    
    NSAlert *alertSheet = [[NSAlert alloc] init];
    [alertSheet addButtonWithTitle:@"OK"];
    [alertSheet setMessageText:message];
    [alertSheet setInformativeText:info];
    [alertSheet setAlertStyle:NSInformationalAlertStyle];
    [alertSheet beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSModalResponse returnCode) {
        
    }];
    [_indicator stopAnimation:self];
}

-(void)colorUpdate:(NSColorPanel*)colorPanel{
    NSColor* theColor = colorPanel.color;
    [[NSUserDefaults standardUserDefaults] setFloat:theColor.redComponent forKey:@"BackgroundColor.R"];
    [[NSUserDefaults standardUserDefaults] setFloat:theColor.greenComponent forKey:@"BackgroundColor.G"];
    [[NSUserDefaults standardUserDefaults] setFloat:theColor.blueComponent forKey:@"BackgroundColor.B"];
    
    [_renderer setBackgroundR:theColor.redComponent];
    [_renderer setBackgroundG:theColor.greenComponent];
    [_renderer setBackgroundB:theColor.blueComponent];
}
@end
