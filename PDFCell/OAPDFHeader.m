//
//  OAPDFHeader.m
//  OAOffice
//
//  Created by admin on 14-7-30.
//  Copyright (c) 2014年 DigitalOcean. All rights reserved.
//

#import "OAPDFHeader.h"

@implementation OAPDFHeader

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 0, frame.size.width * 0.7, frame.size.height)];
        self.titleLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        self.titleLabel.textAlignment = NSTextAlignmentLeft;
        self.titleLabel.font = [UIFont boldSystemFontOfSize:18.0f];
//        self.titleLabel.backgroundColor = [UIColor grayColor];
        self.titleLabel.textColor = [UIColor blackColor];
        [self addSubview:self.titleLabel];
        
        self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
