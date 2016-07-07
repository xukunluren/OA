//
//  OAProgressPie.m
//  OAOffice
//
//  Created by admin on 14-8-10.
//  Copyright (c) 2014年 DigitalOcean. All rights reserved.
//

#import "OAProgressPie.h"
#import "OAProgressLayer.h"

const NSTimeInterval OAProgressLayerDefaultAnimationDuration = 0.25;

@interface OAProgressPie()
- (void) _initIVars;
@end

@implementation OAProgressPie

@synthesize animationDuration = _animationDuration;

+ (Class) layerClass
{
    return [OAProgressLayer class];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self _initIVars];
    }
    return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self) {
        [self _initIVars];
    }
    return self;
}

- (void) _initIVars
{
    _animationDuration = OAProgressLayerDefaultAnimationDuration;
    self.backgroundColor = [UIColor clearColor];
    self.opaque = NO;
    self.tintColor = kPDFThumbBGColor;//[UIColor whiteColor];//kThemeColor;//[UIColor colorWithRed:0.2 green:0.45 blue:0.8 alpha:1.0];
    self.trackColor = [UIColor clearColor];//[UIColor lightGrayColor];//
    
    // On Retina displays, the layer must have its resolution doubled so it does not look blocky.
    self.layer.contentsScale = [UIScreen mainScreen].scale;
}


- (float) progress
{
    OAProgressLayer *layer = (OAProgressLayer *)self.layer;
    return layer.progress;
}

- (void) setProgress:(float)progress
{
    BOOL growing = progress > self.progress;
    [self setProgress:progress animated:growing];
}

- (void) setProgress:(float)progress animated:(BOOL)animated
{
    // Coerce the value
    if(progress < 0.0f)
        progress = 0.0f;
    else if(progress > 1.0f)
        progress = 1.0f;
    
    // Apply to the layer
    OAProgressLayer *layer = (OAProgressLayer *)self.layer;
    if(animated)
    {
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"progress"];
        animation.duration = self.animationDuration;
        animation.fromValue = [NSNumber numberWithFloat:layer.progress];
        animation.toValue = [NSNumber numberWithFloat:progress];
        [layer addAnimation:animation forKey:@"progressAnimation"];
        
        layer.progress = progress;
    }
    
    else {
        layer.progress = progress;
        [layer setNeedsDisplay];
    }
}

- (UIColor *)tintColor
{
    OAProgressLayer *layer = (OAProgressLayer *)self.layer;
    return layer.tintColor;
}
- (void) setTintColor:(UIColor *)tintColor
{
    OAProgressLayer *layer = (OAProgressLayer *)self.layer;
    layer.tintColor = tintColor;
    [layer setNeedsDisplay];
}

- (UIColor *)trackColor
{
    OAProgressLayer *layer = (OAProgressLayer *)self.layer;
    return layer.trackColor;
}

- (void) setTrackColor:(UIColor *)trackColor
{
    OAProgressLayer *layer = (OAProgressLayer *)self.layer;
    layer.trackColor = trackColor;
    [layer setNeedsDisplay];
}


- (float) startAngle
{
    OAProgressLayer *layer = (OAProgressLayer *)self.layer;
    return layer.startAngle;
}

- (void) setStartAngle:(float)startAngle
{
    OAProgressLayer *layer = (OAProgressLayer *)self.layer;
    layer.startAngle = startAngle;
    [layer setNeedsDisplay];
}


@end
