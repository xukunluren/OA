//
//  OAPDFCell.m
//  OAOffice
//
//  Created by admin on 14-7-24.
//  Copyright (c) 2014年 DigitalOcean. All rights reserved.
//

#import "OAPDFCell.h"

@implementation OAPDFCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // 1.
        self.contentView.backgroundColor = [UIColor clearColor];
        
        // 2. 添加PDF缩略图－pdfThumbView
        CGFloat thumbHeight = frame.size.height - kOAPDFCellTitleHeight - 20; // - 40.0f
        CGFloat thumbWidth  = thumbHeight * (596 / 842.0);//210/297
        CGRect  thumbFrame  = CGRectMake(0, 0, thumbWidth, thumbHeight);
        self.pdfThumbView = [[UIImageView alloc] initWithFrame:thumbFrame];
        self.pdfThumbView.center = CGPointMake(frame.size.width / 2.0, thumbHeight / 2.0 + 10);
        self.pdfThumbView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.pdfThumbView.backgroundColor = kPDFThumbBGColor;
        self.pdfThumbView.contentMode = UIViewContentModeScaleAspectFill;
        [self.contentView addSubview:self.pdfThumbView];
        
        // 3. 添加PDF批阅标签－tagView 初始为隐藏
        CGFloat tagX = self.pdfThumbView.frame.origin.x;
        CGFloat tagY = self.pdfThumbView.frame.origin.y;
        CGRect tagFrame = CGRectMake(tagX, tagY, kTagViewWidth, kTagViewHeight); //65.0f,68.0f
        self.tagView = [[UIImageView alloc] initWithFrame:tagFrame];
        self.tagView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.tagView.contentMode = UIViewContentModeScaleAspectFit;
        
        [self.contentView addSubview:self.tagView];
        
        // 4. 添加PDF文件名－titleLabel
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, kOAPDFCellWidth*0.9, kLABEL_HEIGHT*2)]; //20.0f
        self.titleLabel.center = CGPointMake(frame.size.width * 0.5, frame.size.height - 33);
        self.titleLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.font = [UIFont boldSystemFontOfSize:14.0f];
        self.titleLabel.textColor = [UIColor blackColor];
        self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        self.titleLabel.numberOfLines = 2;
        [self.titleLabel.layer setMasksToBounds:YES];
        [self.titleLabel.layer setCornerRadius:5.0f];
        
        [self.contentView addSubview:self.titleLabel];
        
        // 5. 添加PDF文件日期－dateLabel
        self.dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, frame.size.width * 0.8, kLABEL_HEIGHT)];
        self.dateLabel.center = CGPointMake(frame.size.width * 0.5, frame.size.height - 10);
        self.dateLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        self.dateLabel.textAlignment = NSTextAlignmentCenter;
        self.dateLabel.font = [UIFont boldSystemFontOfSize:12.0f];
        self.dateLabel.textColor = [UIColor grayColor];
        
        [self.contentView addSubview:self.dateLabel];
        
        // 6. 初始化ProgressPie and Label value
        CGFloat pieRadius = self.pdfThumbView.frame.size.width - 5;
        self.pView = [[OAProgressPie alloc] initWithFrame:CGRectMake(0, 0, pieRadius, pieRadius)];
        self.pView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.pView.center = self.pdfThumbView.center;
        
        [self.contentView addSubview:self.pView];
        
        // 7. 初始化Pie value label
        self.pValue = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frame.size.width * 0.8, kLABEL_HEIGHT)];
        self.pValue.center = CGPointMake(frame.size.width * 0.5, frame.size.height * 0.5 + 50);
        self.pValue.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.pValue.textAlignment = NSTextAlignmentCenter;
        self.pValue.font = [UIFont systemFontOfSize:18.0f];
        self.pValue.textColor = [UIColor whiteColor];
        
        [self.contentView addSubview:self.pValue];
        
        // 8. 添加删除按钮－deleteBtn
        self.deleteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        CGFloat deleteBtnX = self.pdfThumbView.frame.origin.x + self.pdfThumbView.frame.size.width - 16;
        CGFloat deleteBtnY = self.pdfThumbView.frame.origin.y - 14;
        self.deleteBtn.frame = CGRectMake(deleteBtnX, deleteBtnY, 32, 32);
        self.deleteBtn.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self.deleteBtn setImage:[UIImage imageNamed:@"File-Delete.png"] forState:UIControlStateNormal];
        self.deleteBtn.hidden = YES; // 默认为隐藏YES
        
        [self.contentView addSubview:self.deleteBtn];
        
        // 9. 初始化indexPath isDownLoading
        self.isDownLoading = NO;
        
//        self.contentView.layer.borderWidth = 1.0f;
//        self.contentView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
        
        // 10. 添加流程类型
        self.missiveType = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, frame.size.width * 0.6, 40)];
        self.missiveType.center = CGPointMake(frame.size.width * 0.5, 90);
        self.missiveType.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        self.missiveType.textAlignment = NSTextAlignmentCenter;
        self.missiveType.font = [UIFont boldSystemFontOfSize:28.0f];
        self.missiveType.backgroundColor = [UIColor whiteColor];
        self.missiveType.layer.masksToBounds = YES;
        self.missiveType.layer.cornerRadius = 5.0;
        self.missiveType.layer.borderWidth = 2.0;
        self.missiveType.hidden = YES;
        
        [self.contentView addSubview:self.missiveType];
        
        // 11.
        self.cover = [[UIView alloc] initWithFrame:self.frame];
        [self.contentView addSubview:self.cover];
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
