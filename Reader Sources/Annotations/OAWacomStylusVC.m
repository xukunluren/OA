//
//  OAWacomStylusVC.m
//  OAOffice
//
//  Created by admin on 15/1/19.
//  Copyright (c) 2015年 DigitalOcean. All rights reserved.
//

#import "OAWacomStylusVC.h"
#import "drawingView.h"
#import "DiscoveryPopoverViewController.h"
#import "HandPositionTableViewController.h"

#define BATTERY_PERCENTAGE_SEGMENT 2
@interface OAWacomStylusVC ()<EPenConnectDelegate>
{
    UIButton *ConnectButton;
    DiscoveryPopoverViewController *mDiscoveredTable;
    UIPopoverController *mPopoverController;
    HandPositionTableViewController *mHandPositionController;
    UIPopoverController *mHandPositionPopoverController;
    UIImage *savedImage;
    UIImageView *savedImageView;
}
@end

@implementation OAWacomStylusVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.navigationController.navigationBar.barTintColor = kThemeColor;
    self.navigationController.toolbar.barTintColor = kThemeColor;
    self.navigationController.view.tintColor = UIColor.whiteColor;
    
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBtn.frame = CGRectMake(0, 0, 32, 32);
    [closeBtn setImage:[UIImage imageNamed:@"Reader-Back.png"] forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(dismissToReaderViewController) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:closeBtn];
    
    [[WacomManager getManager] registerForNotifications:self];
    
    self.HandednessControl = [UIButton buttonWithType:UIButtonTypeCustom];
    self.HandednessControl.frame = CGRectMake(0, 0, 40, 40);
//    [self.HandednessControl setImage:[UIImage imageNamed:@"Reader-Handedness"] forState:UIControlStateNormal];
    [self.HandednessControl setImage:[UIImage imageNamed:@"Reader-Complete"] forState:UIControlStateNormal];
//    [self.HandednessControl addTarget:self action:@selector(displayHandPositions:) forControlEvents:UIControlEventTouchUpInside];
    [self.HandednessControl addTarget:self action:@selector(saveImageToImageView) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.HandednessControl];
    
//    NSArray *segmentArray2 = [NSArray arrayWithObjects:NSLocalizedString(@"选笔", @"pen"),NSLocalizedString(@"清除", @"clear"),NSLocalizedString(@"触控-关",@"touch"),NSLocalizedString(@"电量", @""), nil];
    NSArray *segmentArray2 = [NSArray arrayWithObjects:NSLocalizedString(@"选笔", @"pen"),NSLocalizedString(@"清除", @"clear"),NSLocalizedString(@"电量", @""), nil];
    self.toolBar = [[UISegmentedControl alloc] initWithItems:segmentArray2];
    self.toolBar.frame = CGRectMake(0, 0, 200, 32);
    self.toolBar.momentary = YES;
    [self.toolBar addTarget:self action:@selector(SegControlPerformAction:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = self.toolBar;
    
    [_toolBar setTitle:@"电量" forSegmentAtIndex:BATTERY_PERCENTAGE_SEGMENT];
    [[TouchManager GetTouchManager] setTouchRejectionEnabled:YES];//初始化为打开
    [[TouchManager GetTouchManager] setHandedness:eh_RightDownward];
    [[TouchManager GetTouchManager] setTimingOffset:65000];
    
    self.dV = [[drawingView alloc] initWithFrame:self.view.frame];
    self.dV.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
//    [self.view insertSubview:self.dV atIndex:1];
    [self.view addSubview:self.dV];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dismissToReaderViewController
{
    [self dismissViewControllerAnimated:YES completion:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DocumentsSetAnnotationModeOffNotification" object:nil];
    }];
}

#pragma mark - ImageView
- (void)saveImageToImageView
{
    [self setImageViewWithImage:[_dV cropTransparencyFromImage:[_dV glToUIImage]]];
    if (_dV.isDraw && savedImageView) {
        [self dismissViewControllerAnimated:YES completion:^{
            [self.wacomStylusDelegate dismissViewControllerWithImage:savedImageView];
        }];
    }else
    {
        [self dismissToReaderViewController];
    }
    
}

- (void)setImageViewWithImage:(UIImage *)image
{
//    [self.dV removeFromSuperview];
//    self.dV = nil;
    
    savedImageView = [[UIImageView alloc] initWithImage:image];
//    savedImageView.layer.borderWidth = 2.0;
//    savedImageView.layer.borderColor = [kThemeColor CGColor];
//    UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc]
//                                                        initWithTarget:self
//                                                        action:@selector(handlePinch:)];
//    [savedImageView addGestureRecognizer:pinchGestureRecognizer];
//    UIRotationGestureRecognizer *rotateRecognizer = [[UIRotationGestureRecognizer alloc]
//                                                     initWithTarget:self
//                                                     action:@selector(handleRotate:)];
//    [savedImageView addGestureRecognizer:rotateRecognizer];
//    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc]
//                                             initWithTarget:self
//                                             action:@selector(handlePan:)];
//    [savedImageView addGestureRecognizer:panRecognizer];
//    
//    savedImageView.center = self.view.center;
//    [savedImageView setUserInteractionEnabled:YES];
//    [self.view addSubview:savedImageView];
}

#pragma mark - Gesture
- (void) handlePinch:(UIPinchGestureRecognizer*) recognizer
{
    recognizer.view.transform = CGAffineTransformScale(recognizer.view.transform, recognizer.scale, recognizer.scale);
    recognizer.scale = 1;
}

- (void) handleRotate:(UIRotationGestureRecognizer*) recognizer
{
    recognizer.view.transform = CGAffineTransformRotate(recognizer.view.transform, recognizer.rotation);
    recognizer.rotation = 0;
}
- (void)handlePan:(UIPanGestureRecognizer *)recognizer
{
    [self.view bringSubviewToFront:savedImageView];
    CGPoint location = [recognizer locationInView:self.view];
    recognizer.view.center = CGPointMake(location.x,  location.y);
}


////////////////////////////////////////////////////////////////////////////////
// Function:showPopover
// Notes: registers for discovery related callbacks and sets up the window to show discovery
// status and results.
- (void)showPopover:(UIView *)sender
{
    if(mDiscoveredTable == nil)
    {
        mDiscoveredTable = [[DiscoveryPopoverViewController alloc] init];
    }
    
    //allocates and sizes the window.
    if(!mPopoverController)
    {
        mDiscoveredTable.ePenDelegate = (id)self;
        mPopoverController =  [[UIPopoverController alloc] initWithContentViewController:mDiscoveredTable];
        mPopoverController.popoverContentSize = CGSizeMake(280., 320.);
        mPopoverController.delegate = self;
    }
    
    // initiates discovery
    [[WacomManager getManager] startDeviceDiscovery];
    
    // shows the discovery popover.
    [mPopoverController presentPopoverFromRect:sender.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    
}

////////////////////////////////////////////////////////////////////////////////
// Function: dealloc
// Notes: clears out all the allocations that have been made.
- (void)dealloc {
    [[WacomManager getManager] deregisterForNotifications:self];
}



//////////// - EPenConnectDelegate
////////////////////////////////////////////////////////
// Function: toggleTouchRejection
// Notes: enables or disables touch rejection based on the previous state.
-(void) toggleTouchRejection:(BOOL)state
{
//    NSString *message   = nil;
//    NSString *title     = NSLocalizedString(@"触感屏蔽", @"Touch Rejection");
//    if (!state) {
//        state = [TouchManager GetTouchManager].touchRejectionEnabled;
//    }
//    if(state == YES)
//    {
//        [TouchManager GetTouchManager].touchRejectionEnabled = NO;
//        [self.toolBar setTitle:@"触控-关" forSegmentAtIndex:2];
//    }
//    else
//    {
//        [TouchManager GetTouchManager].touchRejectionEnabled = YES;
//        [self.toolBar setTitle:@"触控-开" forSegmentAtIndex:2];
//    }
}



////////////////////////////////////////////////////////////////////////////////
// Function: toggleTouchRejection
// Notes: enables or disables touch rejection based on the previous state.
-(IBAction)showPrivacyMessage:(UIButton *)sender
{
    NSString *message   = nil;
    NSString *title     = @"Privacy Info";
    
    message = @"This app does not collect information about its users. Only previous pairings are stored and they are stored locally. This app does not phone home.";
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
    
}



////////////////////////////////////////////////////////////////////////////////
// Function: displayHandPositions
// displays UI to allow user to set the hand position used while drawing with the
// stylus
- (void)displayHandPositions:(UIButton*)sender
{
    if(mHandPositionController == nil)
    {
        mHandPositionController = [[HandPositionTableViewController alloc] init];
    }
    
    //allocates and sizes the window.
    if(!mHandPositionPopoverController)
    {
        mHandPositionPopoverController =  [[UIPopoverController alloc] initWithContentViewController:mHandPositionController];
        mHandPositionPopoverController.popoverContentSize = CGSizeMake(280., 320.);
        mHandPositionPopoverController.delegate = self;
    }
    
    // shows the discovery popover.
    [mHandPositionPopoverController presentPopoverFromRect:sender.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    
}



////////////////////////////////////////////////////////////////////////////////
// Function: SegControlSetHandedness
// Notes: controls pairing, toggles touch rejection, and erases the screen when the
// segmented control is clicked.
- (IBAction)SegControlSetHandedness:(UISegmentedControl *)sender
{
    
    switch(sender.selectedSegmentIndex)
    {
        case 0:
            // Initiates the pairing mode popover.
            [[TouchManager GetTouchManager] setHandedness:eh_Left];
            break;
        case 1:
            // Clears the screen
            [[TouchManager GetTouchManager] setHandedness:eh_Right];
            break;
        default:
            break;
    };
    
}




////////////////////////////////////////////////////////////////////////////////
// Function: SegControlPerformAction
// Notes: controls pairing, toggles touch rejection, and erases the screen when the
// segmented control is clicked.
- (IBAction)SegControlPerformAction:(UISegmentedControl *)sender
{
    
    switch(sender.selectedSegmentIndex)
    {
        case 0:
            // Initiates the pairing mode popover.
            [self showPopover:sender];
            break;
        case 1:
            // Clears the screen
            if (_dV.superview) {
                [_dV erase];
            }else{
                if (savedImageView.superview) {
                    [savedImageView removeFromSuperview];
                }
//                self.dV = [[drawingView alloc] initWithFrame:self.view.frame];
//                self.dV.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
//                [self.view insertSubview:self.dV atIndex:1];
            }
            break;
        case 2:
            // Toggles touch rejection on and off.
//            [self toggleTouchRejection:nil];
            break;
        case 4:
            // Save Image
//            [self setImageViewWithImage:[_dV cropTransparencyFromImage:[_dV glToUIImage]]];
            
            break;
        default:
            break;
    };
    
}



////////////////////////////////////////////////////////////////////////////////
// Function:deviceDiscovered
// Notes: just add the device to the discovered table. demonstrates signal strength
-(void) deviceDiscovered:(WacomDevice *)device
{
    //	NSLog(@"signal strength %i", [device getSignalStrength]);
    [mDiscoveredTable addDevice:device];
}



////////////////////////////////////////////////////////////////////////////////
// Function:deviceConnected
// Notes: update the device table then dismiss the popover.
-(void) deviceConnected:(WacomDevice *)device
{
    [mDiscoveredTable updateDevices:device];
}



////////////////////////////////////////////////////////////////////////////////
// Function:deviceDisconnected
// Notes: remove the device then dismiss the popover
-(void)deviceDisconnected:(WacomDevice *)device
{
    [mDiscoveredTable removeDevice:device];
    [_toolBar setTitle:@"" forSegmentAtIndex:BATTERY_PERCENTAGE_SEGMENT];
    
}



////////////////////////////////////////////////////////////////////////////////
// Function: discoveryStatePoweredOff
// Notes: if the power is off, it pops a warning dialog.
-(void)discoveryStatePoweredOff
{
    NSString *title     = NSLocalizedString(@"蓝牙开关", @"Bluetooth Power");//@"Bluetooth Power"
    NSString *message   = NSLocalizedString(@"请在设置中打开蓝牙", @"You must turn on Bluetooth in Settings");//@"You must turn on Bluetooth in Settings";
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:NSLocalizedString(@"好的", @"OK") otherButtonTitles:nil];
    [alertView show];
}



////////////////////////////////////////////////////////////////////////////////
// Function:stylusEvent
// Notes: update the battery status segment in the tool bar.
-(void)stylusEvent:(WacomStylusEvent *)stylusEvent
{
    switch ([stylusEvent getType])
    {
        case eStylusEventType_BatteryLevelChanged:
            [_toolBar setTitle:[NSString stringWithFormat:@"%lu%%", [stylusEvent getBatteryLevel] ] forSegmentAtIndex:BATTERY_PERCENTAGE_SEGMENT];
        default:
            break;
    }
}

#pragma mark - EPenConnectDelegate
- (void)ePenConnectedChangeState:(BOOL)state
{
    [self toggleTouchRejection:state];
}
@end
