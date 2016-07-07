//
//  OASearchBarVC.h
//  OAOffice
//
//  Created by admin on 15/1/5.
//  Copyright (c) 2015年 DigitalOcean. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SearchBarToMasterDelegate <NSObject>

- (void)sendSearchBarResultWithDic:(NSDictionary *)result;

@end

@interface OASearchBarVC : UITableViewController

@property (nonatomic, copy) NSString *searchText;
@property (nonatomic, weak) id<SearchBarToMasterDelegate> searchBarDelegate;

@end
