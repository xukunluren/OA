//
//  OACover.m
//  OAOffice
//
//  Created by admin on 14/12/23.
//  Copyright (c) 2014年 DigitalOcean. All rights reserved.
//

#import "OACover.h"

#define kAlpha 0.6

@implementation OACover

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // 1.背景色
        self.backgroundColor = [UIColor blackColor];
        
        // 2.自动伸缩
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        
        // 3.透明度
        self.alpha = kAlpha;
    }
    return self;
}

- (void)reset
{
    self.alpha = kAlpha;
}

+ (id)cover
{
    return [[self alloc] init];
}

+ (id)coverWithTarget:(id)target action:(SEL)action
{
    OACover *cover = [self cover];
    
    [cover addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:target action:action]];
    
    return cover;
}

@end
