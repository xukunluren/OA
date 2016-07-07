//
//  HandPositionTableViewController.h
//  WacomStylusDemoApp
//
//  Created by minion on 11/14/14.
//  Copyright (c) 2014 Wacom. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WacomDevice/WacomDeviceFramework.h>

@interface HandPositionTableViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
{
	IBOutlet UIView *handPositionPopoverView;
}

@end
