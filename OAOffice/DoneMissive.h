//
//  DoneMissive.h
//  OAOffice
//
//  Created by admin on 15/2/2.
//  Copyright (c) 2015年 DigitalOcean. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface DoneMissive : NSManagedObject

@property (nonatomic, retain) NSString * missiveAddr;
@property (nonatomic, retain) NSDate * missiveDoneTime;
@property (nonatomic, retain) NSString * missiveId;
@property (nonatomic, retain) NSString * missiveTitle;
@property (nonatomic, retain) NSString * taskId;
@property (nonatomic, retain) NSString * taskName;
@property (nonatomic, retain) NSString * urgentLevel;

@end
