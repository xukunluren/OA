//
//  OAButton+Download.h
//  OAOffice
//
//  Created by admin on 15/1/13.
//  Copyright (c) 2015年 DigitalOcean. All rights reserved.
//

#import <UIKit/UIKit.h>

#define ICON_BUTTON_SCALE 0.85

@class OAButton_Download;

@protocol OAButton_DownloadDelegate <NSObject>
@optional
- (void) buttonIsEmpty: (OAButton_Download *)button;
@end

@interface OAButton_Download : UIButton

//Properties
@property (nonatomic, assign) BOOL emptyButtonPressing;

//Data 
@property (nonatomic, assign) float fillPercent;

@property (assign) IBOutlet id<OAButton_DownloadDelegate> delegate;

- (void)setFillPercent: (float) percent;

- (void)configureButtonWithHightlightedShadowAndZoom: (BOOL)shadowAndZoom;

//Targets
- (void) configureToSelected: (BOOL) selected;
- (void) keepHighLighted: (BOOL) keepHighlighted;

@end
