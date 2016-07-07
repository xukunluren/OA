//
//  OAPDFCell.h
//  OAOffice
//
//  Created by admin on 14-7-24.
//  Copyright (c) 2014年 DigitalOcean. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OAProgressPie.h"

@interface OAPDFCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *pdfThumbView;
@property (nonatomic, strong) UIView *cover;
@property (nonatomic, strong) UIView *content;
@property (nonatomic, strong) UIImageView *tagView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UIButton *deleteBtn;
@property (nonatomic, strong) OAProgressPie *pView;
@property (nonatomic, strong) UILabel *pValue;
@property (nonatomic, strong) UILabel *missiveType;

@property BOOL isDownLoading;
@property float progressValue;

@end