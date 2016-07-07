//
//  OACrashLog.m
//  OAOffice
//
//  Created by admin on 14/11/17.
//  Copyright (c) 2014年 DigitalOcean. All rights reserved.
//

#import "OACrashLog.h"
#import <libkern/OSAtomic.h>
#import <execinfo.h>

NSString *const ExceptionName = @"UncaughtException";
NSString *const SignalKey = @"SignalKey";
NSString *const AddressesKey = @"AddressesKey";

const NSInteger SkipAddressCount = 4;
const NSInteger ReportAddressCount = 5;


static void handleRootException(NSException *exception);//系统崩溃回调函数
static NSString *const LogDirectoryString = @"com.OAOffice.yxGuo.errorLog";

@interface OACrashLog()

/**
 *  对未能捕获异常的处理
 *
 *  @param signal
 */
static void mySignalHandler(int signal);
/**
 *  未能捕获的异常处理
 *
 *  @param exception 异常
 */
static void handleUncaughtException(NSException *exception);

/**
 *  获取崩溃栈信息存入数组
 *
 *  @return 崩溃栈错误信息数组
 */
static NSArray *getBacktrace();


/**
 *  获取日志保存的文件夹路径
 *
 *  @return 路径
 */
static NSString *getLogDirectory();

/**
 *  获取日志需要保存的文件路径
 *
 *  @return 路径
 */
static NSString *getLogFilePath();

/**
 *  写入文件
 *
 *  @param logString 崩溃信息
 */
static void logToFile(NSString *logString);


/**
 *  上传崩溃文件到服务器
 */
static void uploadLogFile();
static void uploadLogFileWithPath(NSString *path);

@end

@implementation OACrashLog


+(void)LogInit
{
    NSSetUncaughtExceptionHandler(handleRootException);
    
    //未能捕获的异常
    signal(SIGABRT, mySignalHandler);
    signal(SIGILL, mySignalHandler);
    signal(SIGSEGV, mySignalHandler);
    signal(SIGFPE, mySignalHandler);
    signal(SIGBUS, mySignalHandler);
    signal(SIGPIPE, mySignalHandler);
    
    uploadLogFile();
}



static void handleRootException( NSException* exception )
{
    NSString *name = [exception name];
    NSString *reason = [exception reason];
    NSArray *symbols = [exception callStackSymbols];
    NSMutableString *strSymbols = [[NSMutableString alloc]init];
    for (NSString *item in symbols){
        [strSymbols appendString:item];
        [strSymbols appendString:@"\r\n"];
    }
    
    NSString *errorInfo = [NSString stringWithFormat:@" *** Terminating app due to uncaught exception %@ , reason: %@  \r\n  *** First throw call stack: \r\n(\r\n  %@\r\n)", name, reason, strSymbols];
    
    logToFile(errorInfo);
    
}

static void mySignalHandler(int signal){
    
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc]init];
    NSArray *callStack = getBacktrace();
    
    userInfo[SignalKey] = @(signal);   //设置异常值
    userInfo[AddressesKey] = callStack;   //设置地址值
    
    NSException *exception = [NSException exceptionWithName:ExceptionName reason:[NSString stringWithFormat:@"Signal %d was raised.",signal] userInfo:userInfo];
    
    handleUncaughtException(exception);
    
}


static void handleUncaughtException(NSException *exception){
    
    NSString *name = [exception name];
    NSString *reason = [exception reason];
    NSArray *symbols = [[exception userInfo]objectForKey:AddressesKey];
    NSMutableString *strSymbols = [[NSMutableString alloc]init];
    for (NSString *item in symbols){
        [strSymbols appendString:item];
        [strSymbols appendString:@"\r\n"];
    }
    
//    NSString *errorInfo = [NSString stringWithFormat:@" *** Terminating app due to uncaught exception %@ , reason: %@  \r\n  *** First throw call stack: \r\n(\r\n  %@\r\n)", name, reason, strSymbols];
    NSString *errorInfo = [NSString stringWithFormat:@" *** Terminating app due to uncaught exception %@ , reason: %@", name, reason];
    
    logToFile(errorInfo);
}




static NSArray *getBacktrace(){
    void *callstack[128];
    int frames = backtrace(callstack, 128);
    char **strs = backtrace_symbols(callstack, frames);
    int i;
    NSMutableArray *backtrace = [NSMutableArray arrayWithCapacity:frames];
    for (i = SkipAddressCount;i < SkipAddressCount +ReportAddressCount;i++){
        [backtrace addObject:[NSString stringWithUTF8String:strs[i]]];
    }
    free(strs);
    return backtrace;
}



static NSString *getLogDirectory(){
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    documentsDirectory = [documentsDirectory stringByAppendingPathComponent:LogDirectoryString];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir;
    if ( !([fileManager fileExistsAtPath:documentsDirectory isDirectory:&isDir] && isDir ) ){
        [fileManager createDirectoryAtPath:documentsDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return documentsDirectory;
}


static NSString *getLogFilePath(){
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd_HH:mm:ss"];
    NSString *currentDateStr = [dateFormatter stringFromDate:[NSDate date]];
    
    NSString *t = [NSString stringWithFormat:@"%@/error_%@.txt",getLogDirectory(),currentDateStr];
    
    return t;
}



static void logToFile(NSString *logString){
    
    FILE *file = NULL;
    file = fopen([getLogFilePath() UTF8String],"w");
    if (nil == file) {
        return;
    }
    
    const char *ch = [logString UTF8String];
    int writeResult = fputs(ch,file);
    if (writeResult == EOF) {
#if DEBUG
        NSLog(@"log write file failed.");
#endif
    }
    fclose(file);
    file = NULL;
}


static void uploadLogFile(){
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSArray* array = [fileManager contentsOfDirectoryAtPath:getLogDirectory() error:nil];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        dispatch_apply([array count], dispatch_get_global_queue(0, 0), ^(size_t i) {
            NSString *fullPath = [getLogDirectory() stringByAppendingPathComponent:[array objectAtIndex:i]];
            if (![fullPath hasSuffix:@".txt"]) {
                return ;
            }
            BOOL isDir;
            if ( !([fileManager fileExistsAtPath:fullPath isDirectory:&isDir] && isDir) ){
                uploadLogFileWithPath(fullPath);
            }
        });
    });
    
}

static void uploadLogFileWithPath(NSString *path){
    //通过指定的路径读取文本内容
    NSError *error = nil;
    NSString *info = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    NSString *logInfo = [NSString stringWithFormat:@"Error:Crash Log Info In OACrashLog.m%@",info];

    MyLog(@"Crash : %@",logInfo);
    [OATools newLogWithInfo:logInfo time:[OATools newStringDate] type:kLogErrorType];
    // 删除Crash日志文件
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:path error:NULL];
    //if success
    //    NSFileManager *fileManager = [NSFileManager defaultManager];
    //    [fileManager removeItemAtPath:path error:NULL];
    //
}

@end
