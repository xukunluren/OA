//
//  OAProgressPie.h
//  OAOffice
//
//  Created by admin on 14-8-10.
//  Copyright (c) 2014年 DigitalOcean. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAProgressPie : UIView<UIAppearanceContainer>

@property (nonatomic, assign) float progress;   // 0 .. 1
@property (nonatomic, assign) float startAngle; // 0..2π
@property (nonatomic, retain) UIColor *tintColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, retain) UIColor *trackColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, assign) CFTimeInterval animationDuration;

- (void) setProgress:(float)progress animated:(BOOL)animated;

@end
