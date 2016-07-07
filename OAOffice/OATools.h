//
//  OATools.h
//  OAOffice
//
//  Created by admin on 15/1/10.
//  Copyright (c) 2015年 DigitalOcean. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface OATools : NSObject

// 新增日志记录
+ (void)newLogWithInfo:(NSString *)info time:(NSString *)currentDate type:(NSString *)logType;

// 词典日志信息转字符串
+ (NSString *)dictionaryToJson:(NSDictionary *)dic;

// 字符串日志信息转词典
+ (NSDictionary *)jsonStrToDictionary:(NSString *)jsonStr;

// 获取选择会签用户列表
+ (void)getAllUserToPlist;

// 警告提示，定时取消
+ (void)showAlertTitle:(NSString *)title message:(NSString *)message;
// 警告定时取消
+ (void)timerFireMethod:(NSTimer*)theTimer;

// 获取PDF文件的缩略图
+ (UIImage *)imageFromPDFWithDocumentRef:(NSString *)fileURL withPageNum:(int )pageNum withSize:(CGFloat )size;

// 获取当前日期，设置日期格式
+ (NSString *)newStringDate;

@end
