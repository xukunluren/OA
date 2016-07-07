//
//  OALoginViewController.h
//  OAOffice
//
//  Created by admin on 14-8-11.
//  Copyright (c) 2014年 DigitalOcean. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OALoginViewController;
@protocol OALoginViewControllerDelegate <NSObject>

- (void)dismissOALoginViewController:(OALoginViewController *)viewController;

@end

@interface OALoginViewController : UIViewController
@property (retain, nonatomic) UIImageView *bgImageView;
@property (retain, nonatomic) UIButton *loginBtn;
@property (retain, nonatomic) UIButton *loginThumb;
@property BOOL isTouchID;

@property (weak, nonatomic) id<OALoginViewControllerDelegate> delegate;

- (IBAction)loginPressed:(id)sender;
- (IBAction)loginThumbPressed:(id)sender;

@end