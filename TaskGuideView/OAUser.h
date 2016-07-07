//
//  OAUser.h
//  OAOffice
//
//  Created by admin on 14/12/23.
//  Copyright (c) 2014年 DigitalOcean. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAUser : NSObject

@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *userName;
@property (nonatomic, copy) NSString *groupName;

@end
