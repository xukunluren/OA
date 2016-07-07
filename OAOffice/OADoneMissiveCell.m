//
//  OADoneMissiveCell.m
//  OAOffice
//
//  Created by admin on 15/1/4.
//  Copyright (c) 2015年 DigitalOcean. All rights reserved.
//

#import "OADoneMissiveCell.h"

@implementation OADoneMissiveCell

- (void)awakeFromNib {
    // Initialization code
    self.missiveType.clipsToBounds = YES;
    self.missiveType.layer.cornerRadius = 5;
    
    [self.missiveDownloadBtn configureButtonWithHightlightedShadowAndZoom:YES];
    [self.missiveDownloadBtn setEmptyButtonPressing:YES];
    self.missiveDownloadBtn.delegate = self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - OAButton Delegate
- (void)buttonIsEmpty:(OAButton_Download *)button
{
    [self.missiveDownloadBtn setFillPercent:1.0];
}
@end
