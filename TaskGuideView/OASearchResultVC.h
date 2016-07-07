//
//  OASearchResultVC.h
//  OAOffice
//
//  Created by admin on 14/12/23.
//  Copyright (c) 2014年 DigitalOcean. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SearchResultSelectedDelegate <NSObject>

@required
- (void)selectedFromResult:(NSString *)user with:(NSString *)userName;

@end

@interface OASearchResultVC : UITableViewController

@property (nonatomic, copy) NSString *searchText;
@property (nonatomic, assign) id<SearchResultSelectedDelegate> delegate;

@end
