//
//  UncaughtExceptionHandler.h
//  OAOffice
//
//  Created by admin on 15/6/18.
//  Copyright (c) 2015年 DigitalOcean. All rights reserved.
//系统奔溃时处理的方法     2015／06／18xk

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UncaughtExceptionHandler : NSObject
{
    BOOL dismissed;
}

@end

void InstallUncaughtExceptionHandler();