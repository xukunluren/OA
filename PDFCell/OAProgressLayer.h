//
//  OAProgressLayer.h
//  OAOffice
//
//  Created by admin on 14-8-10.
//  Copyright (c) 2014年 DigitalOcean. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface OAProgressLayer : CALayer

@property (nonatomic, assign) float progress;

@property (nonatomic, assign) float startAngle;
@property (nonatomic, retain) UIColor *tintColor;
@property (nonatomic, retain) UIColor *trackColor;

@end
