//
//  OATools.m
//  OAOffice
//
//  Created by admin on 15/1/10.
//  Copyright (c) 2015年 DigitalOcean. All rights reserved.
//

#import "OATools.h"
#import "AFNetworking.h"

@implementation OATools

#pragma mark - Add log info to plist
+ (void)newLogWithInfo:(NSString *)info time:(NSString *)currentDate type:(NSString *)logType
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *userName   = [userDefaults objectForKey:kUserName];
        NSString *deviceUUID = [userDefaults objectForKey:kDeviceInfo];
        NSString *plistPath  = [userDefaults objectForKey:kPlistPath];
        NSDictionary *logDic = [NSDictionary dictionaryWithObjectsAndKeys:userName,kUserName,deviceUUID,kDeviceInfo,currentDate,kLogTime,info,kLogInfo,logType,kLogType, nil];
        MyLog(@"logDic:%@",logDic);
        NSMutableDictionary *docPlist = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
        if (!docPlist) {
            docPlist = [NSMutableDictionary dictionary];
        }
        [docPlist setObject:logDic forKey:[NSString stringWithFormat:@"%@,%d",currentDate,arc4random_uniform(255)]];
        //写入文件
        [docPlist writeToFile:plistPath atomically:YES];
    });
}

+ (NSString *)dictionaryToJson:(NSDictionary *)dic
{
    NSError *parseError = nil;
    NSData  *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&parseError];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

+ (NSDictionary *)jsonStrToDictionary:(NSString *)jsonStr
{
    NSError *parseError = nil;
    NSData *jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    return [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&parseError];
}

#pragma mark - AllUserList
+ (void)getAllUserToPlist
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *plistPath = [userDefaults objectForKey:kUserPlist];
        __block NSMutableArray *docPlist = [[NSMutableArray alloc] initWithContentsOfFile:plistPath];
        if (!docPlist) {
            docPlist = [NSMutableArray array];
            
            NSString *authorizationHeader = [userDefaults objectForKey:kAuthorizationHeader];
            NSString *serverURL = [[NSString stringWithFormat:@"%@",kUserURL] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];//转码成UTF-8  否则可能会出现错
            AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
            [manager.requestSerializer setValue:authorizationHeader forHTTPHeaderField:@"Authorization"];
            [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"content-type"];
            manager.responseSerializer = [AFJSONResponseSerializer serializer];
            
            [manager GET:serverURL parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                //解析返回的JSON数据
                NSData *responseData = [NSJSONSerialization dataWithJSONObject:responseObject options:NSJSONWritingPrettyPrinted error:nil];
                NSArray *result = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:nil];
                docPlist = [NSMutableArray arrayWithArray:result];
                //写入文件
                [docPlist writeToFile:plistPath atomically:YES];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSString *info = [NSString stringWithFormat:@"Error:获取最新用户组人员信息失败错误.%@",error.description];
                [OATools newLogWithInfo:info time:[OATools newStringDate] type:kLogErrorType];
            }];
        }
    });
}

#pragma mark Alert View Methods
+ (void)timerFireMethod:(NSTimer*)theTimer//弹出框
{
    UIAlertView *promptAlert = (UIAlertView *)[theTimer userInfo];
    [promptAlert dismissWithClickedButtonIndex:0 animated:NO];
    promptAlert = NULL;
}

+ (void)showAlertTitle:(NSString *)title message:(NSString *)message
{   //时间
    UIAlertView *promptAlert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    [NSTimer scheduledTimerWithTimeInterval:2.5f
                                     target:self
                                   selector:@selector(timerFireMethod:)
                                   userInfo:promptAlert
                                    repeats:YES];
    [promptAlert show];
}

#pragma mark - PDF thumbView  Get pdf thumb view
+ (UIImage *)imageFromPDFWithDocumentRef:(NSString *)fileURL withPageNum:(int )pageNum withSize:(CGFloat )size
{
    NSURL *url = [NSURL fileURLWithPath:fileURL];
    CFURLRef docURLRef = (__bridge CFURLRef)url; // File URL
    CGPDFDocumentRef documentRef = CGPDFDocumentCreateWithURL(docURLRef);
    
    CGPDFPageRef pageRef = CGPDFDocumentGetPage(documentRef, pageNum);
    CGRect pageRect = CGPDFPageGetBoxRect(pageRef, kCGPDFCropBox);
    
    UIGraphicsBeginImageContextWithOptions(pageRect.size, NO, size);//0：默认跟随设备的Retain－2，1:1倍，2:2倍，8:8倍图片大小
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetRGBFillColor(context, 1.0f, 1.0f, 1.0f, 1.0f);// White
    CGContextFillRect(context, CGContextGetClipBoundingBox(context)); // Fill
    
    CGContextTranslateCTM(context, CGRectGetMinX(pageRect),CGRectGetMaxY(pageRect));
    CGContextScaleCTM(context, 1.0f, -1.0f);
    
    CGContextTranslateCTM(context, -(pageRect.origin.x), -(pageRect.origin.y));
    @try {
         CGContextDrawPDFPage(context, pageRef);
    }
    @catch (NSException *exception) {
        NSLog(@"%@",exception);
    }
    @finally {
        
        
    }
   
    
    UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGPDFDocumentRelease(documentRef);
    
    //    CGFloat height = kOAPDFCellHeight - 40;
    //    CGFloat width = (pageRect.size.width/pageRect.size.height) * height;
    //    finalImage = [self OriginImage:finalImage scaleToSize:CGSizeMake(width * 2, height * 2)];
    return finalImage;
}

// 修改图片的尺寸
-(UIImage *)OriginImage:(UIImage *)image scaleToSize:(CGSize)size
{
    UIGraphicsBeginImageContext(size);  //size 为CGSize类型，即你所需要的图片尺寸
    
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return scaledImage;   //返回的就是已经改变的图片
}

// 获取当前日期，设置日期格式
+ (NSString *)newStringDate
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy/MM/dd hh:mm:ss"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"Asia/Shanghai"]];
    
    return [dateFormatter stringFromDate:[NSDate date]];
}

@end
