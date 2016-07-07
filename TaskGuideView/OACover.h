//
//  OACover.h
//  OAOffice
//
//  Created by admin on 14/12/23.
//  Copyright (c) 2014年 DigitalOcean. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OACover : UIView
+ (id)cover;
+ (id)coverWithTarget:(id)target action:(SEL)action;

- (void)reset;
@end
