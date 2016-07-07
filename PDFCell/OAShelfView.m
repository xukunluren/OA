//
//  OAShelfView.m
//  OAOffice
//
//  Created by admin on 14-7-31.
//  Copyright (c) 2014年 DigitalOcean. All rights reserved.
//

#import "OAShelfView.h"

const NSString *kShelfViewKind = @"ShelfView";

@implementation OAShelfView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
//        UIImageView *imageView=[[UIImageView alloc] initWithFrame:frame];
//        imageView.image = [UIImage imageNamed:@"BookShelfCell.png"];
//        [self addSubview:imageView];
        
        [self setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"ShelfCellBG"]]];
//        self.layer.shadowOpacity = 0.5;
//        self.layer.shadowOffset = CGSizeMake(0,5);
    }
    return self;
}

- (void)layoutSubviews
{
//    CGRect shadowBounds = CGRectMake(0, -5, self.bounds.size.width, self.bounds.size.height + 5);
//    self.layer.shadowPath = [UIBezierPath bezierPathWithRect:shadowBounds].CGPath;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

+ (NSString *)kind
{
    return (NSString *)kShelfViewKind;
}

@end
