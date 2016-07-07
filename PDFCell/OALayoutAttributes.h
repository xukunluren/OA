//
//  OALayoutAttributes.h
//  OAOffice
//
//  Created by admin on 14-8-20.
//  Copyright (c) 2014年 DigitalOcean. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OALayoutAttributes : UICollectionViewLayoutAttributes

// whether header view (ConferenceHeader class) should align label left or center (default = left)
@property (nonatomic, assign) NSTextAlignment headerTextAlignment;

// shadow opacity for the shadow on the photo in SpeakerCell (default = 0.5)
@property (nonatomic, assign) CGFloat shadowOpacity;

@end
