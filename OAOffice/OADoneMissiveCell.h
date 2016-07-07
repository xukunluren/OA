//
//  OADoneMissiveCell.h
//  OAOffice
//
//  Created by admin on 15/1/4.
//  Copyright (c) 2015年 DigitalOcean. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OAButton+Download.h"

@interface OADoneMissiveCell : UITableViewCell<OAButton_DownloadDelegate>

@property (retain, nonatomic) NSString *missiveAddr;
@property (weak, nonatomic) IBOutlet UILabel *missiveType;
@property (weak, nonatomic) IBOutlet UILabel *missiveTitle;
@property (weak, nonatomic) IBOutlet UILabel *missiveDoneTime;
@property (weak, nonatomic) IBOutlet UILabel *missiveTaskName;
@property (weak, nonatomic) IBOutlet OAButton_Download *missiveDownloadBtn;

@end
