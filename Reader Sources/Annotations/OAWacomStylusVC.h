//
//  OAWacomStlusVC.h
//  OAOffice
//
//  Created by admin on 15/1/19.
//  Copyright (c) 2015年 DigitalOcean. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GLKit/GLKView.h"
#import "drawingView.h"
#import <WacomDevice/WacomDeviceFramework.h>

@class OAWacomStylusVC;
@protocol WacomStylusUseDelegate <NSObject>

- (void)dismissViewControllerWithImage:(UIImageView *)signImageView;

@end

@interface OAWacomStylusVC : UIViewController <UIPopoverControllerDelegate, WacomDiscoveryCallback, WacomStylusEventCallback>

@property (retain, nonatomic) UIImageView *pdfThumbBGV;
@property (retain, nonatomic) UIImage *pdfThumbImage;
@property (strong, nonatomic) UIButton *HandednessControl;
@property (retain, nonatomic) UISegmentedControl *toolBar;
@property (retain, nonatomic) drawingView *dV;
@property (assign, nonatomic) id<WacomStylusUseDelegate> wacomStylusDelegate;
//@property (retain, nonatomic) IBOutlet GLKView *glview;

- (void)SegControlPerformAction:(id)sender;
- (void)showPrivacyMessage:(UIButton *)sender;
- (void)displayHandPositions:(UIButton*)sender;

//WacomDiscoveryCallback

///notification method for when a device is connected.
- (void) deviceConnected:(WacomDevice *)device;

///notification method for when a device is disconnected.
- (void) deviceDisconnected:(WacomDevice *)device;

///notification method for when a device is discovered.
- (void) deviceDiscovered:(WacomDevice *)device;


///notification method for when device discovery is not possible because bluetooth is powered off.
///this allows one to pop up a warning dialog to let the user know to turn on bluetooth.
- (void) discoveryStatePoweredOff;

//WacomStylusEventCallback
///notification method for when a new stylus event is ready.
-(void)stylusEvent:(WacomStylusEvent *)stylusEvent;

@end
