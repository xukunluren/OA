//
//  OAUserListVC.h
//  OAOffice
//
//  Created by admin on 14/12/23.
//  Copyright (c) 2014年 DigitalOcean. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol UserListSelectedDelegate <NSObject>

@required
- (void)selectUser:(NSString *)userName;

@end

@interface OAUserListVC : UIViewController

@property (nonatomic, strong) NSMutableArray *userArray;
@property (nonatomic, assign) id<UserListSelectedDelegate> delegate;

@end
