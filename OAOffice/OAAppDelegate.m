//
//  OAAppDelegate.m
//  OAOffice
//
//  Created by admin on 14-7-24.
//  Copyright (c) 2014年 DigitalOcean. All rights reserved.
//

#import "OAAppDelegate.h"
#import <LocalAuthentication/LocalAuthentication.h>
#import "OAMasterViewController.h"
#import "OADetailViewController.h"
#import "ReaderDocument.h"
#import "AFNetworking.h"
#import "OACrashLog.h"
#import "UncaughtExceptionHandler.h"

@implementation OAAppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize locationManager = _locationManager;

//系统奔溃时处理的方法
- (void)installUncaughtExceptionHandler

{
    
    InstallUncaughtExceptionHandler();
    
}
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    
    [self installUncaughtExceptionHandler];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    // 1.初始化日志Plist
    [self initPlistFile];
    // 2.初始化位置定位，并开始定位
    [self initCoreLocation];
    // 3.初始化网络状态监听
    [self initNetworkMonitor];
    // 4.Crash日志记录并上传
    [OACrashLog LogInit];
    // 5.定时操作
    [self timerAction];
    
    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
    UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
    splitViewController.delegate = (id)navigationController.topViewController;
    
    UINavigationController *masterNavigationController = splitViewController.viewControllers[0];
    OAMasterViewController *masterController = (OAMasterViewController *)masterNavigationController.topViewController;
    masterController.managedObjectContext = self.managedObjectContext;
    
    UINavigationController *detailNavigationController = splitViewController.viewControllers[1];
    OADetailViewController *detailController = (OADetailViewController *)detailNavigationController.topViewController;
    detailController.managedObjectContext = self.managedObjectContext;
    
    return YES;
}



- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    MyLog(@"openURL:%@",url);
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    MyLog(@"applicationDidEnterBackground");
    if ([CLLocationManager significantLocationChangeMonitoringAvailable])
    {
        // Stop normal location updates and start significant location change updates for battery efficiency.
//        [_locationManager startUpdatingLocation];
    }
    else
    {
        NSLog(@"Significant location change monitoring is not available.");
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    MyLog(@"applicationWillEnterForeground");
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    MyLog(@"applicationDidBecomeActive");
    if ([CLLocationManager significantLocationChangeMonitoringAvailable])
    {
        // Stop significant location updates and start normal location updates again since the app is in the forefront.
//        [_locationManager startUpdatingLocation];
//        [_locationManager stopUpdatingLocation];
    }
    else
    {
        NSLog(@"Significant location change monitoring is not available.");
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification*)notification{
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"本地推送,下载完成！" message:notification.alertBody delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
//    [alert show];
//    [self showAlertTitle:@"您有新的公文需要批阅" message:notification.alertBody];
    // 图标上的数字减1
//    application.applicationIconBadgeNumber -= 1;
}

// Solve Problem: Snapshotting a view that has not been rendered results in an empty snapshot
- (NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
    return UIInterfaceOrientationMaskAll;
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            
            NSString *info = [NSString stringWithFormat:@"Error:saveContext Error In OAAppDelegate.m.%@",error.description];
            [OATools newLogWithInfo:info time:[OATools newStringDate] type:kLogErrorType];
            
            abort();
        } 
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"OAOffice" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"OAOffice.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        
        NSString *info = [NSString stringWithFormat:@"Error:persistentStoreCoordinator Error In OAAppDelegate.m.%@",error.description];
        [OATools newLogWithInfo:info time:[OATools newStringDate] type:kLogErrorType];
        
        abort();
    }    
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

#pragma mark - Init CoreLocation
- (void)initCoreLocation
{
    _locationManager = [[CLLocationManager alloc] init];//创建位置管理器
    
    _locationManager.delegate = self;
    
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;//kCLLocationAccuracyThreeKilometers;
    
    _locationManager.distanceFilter = 1000.0f;//1000000.0f;
    
    // 判断是否 iOS 8
    if([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [self.locationManager requestAlwaysAuthorization]; // 永久授权
        [self.locationManager requestWhenInUseAuthorization]; //使用中授权
    }
    [self.locationManager startUpdatingLocation];
}

#pragma mark - Monitor the Connecting With Server
- (void)initNetworkMonitor
{
    // Inner server network
    NSURL *baseURL = [NSURL URLWithString:kBaseURL];
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:baseURL];
    NSOperationQueue *operationQueue = manager.operationQueue;
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        MyLog(@"AFNetworkReachability: %@", AFStringFromNetworkReachabilityStatus(status));
        static AFNetworkReachabilityStatus lastStatus = 2;
        switch (status) {
                
            case AFNetworkReachabilityStatusReachableViaWWAN:
            case AFNetworkReachabilityStatusReachableViaWiFi:
            {
                [operationQueue setSuspended:NO];
                NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                [userDefaults setObject:@"OK" forKey:kNetConnect];
                [userDefaults synchronize];
                if (lastStatus == -1 || lastStatus == 0) {
                    [OATools showAlertTitle:@"提醒：" message:@"当前网络已连接，网络状态良好！"];
                }
                break;
            }
            case AFNetworkReachabilityStatusNotReachable:
            default:
            {
                [operationQueue setSuspended:YES];
                
                NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                [userDefaults setObject:@"Error" forKey:kNetConnect];
                [userDefaults synchronize];
                // AFNetworkReachabilityStatusReachableViaWWAN = 1,   // 3G 花钱
                //AFNetworkReachabilityStatusReachableViaWiFi = 2,   // 局域网络,不花钱
                if (lastStatus == 1 || lastStatus == 2) {
                    [OATools showAlertTitle:@"提醒：" message:@"当前网络不可用，请稍后重试！"];
                }
                break;
            }
        }
        lastStatus = status;
    }];
}

- (void)initPlistFile
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *plistPath = [documentsDirectory stringByAppendingPathComponent:@"UserLog.plist"];
    NSString *userPlist = [documentsDirectory stringByAppendingPathComponent:@"UserGroup.plist"];
    NSString *userInfo  = [documentsDirectory stringByAppendingPathComponent:@"UserInfo.plist"];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:plistPath forKey:kPlistPath];
    [userDefaults setObject:userPlist forKey:kUserPlist];
    [userDefaults setObject:userInfo  forKey:kInfoPlist];
    
    NSString *deviceInfo = [NSString stringWithFormat:@"%@,%@,%@,%@",[[UIDevice currentDevice] name],[[UIDevice currentDevice] model],[[UIDevice currentDevice] systemName],[[UIDevice currentDevice] systemVersion]];
    [userDefaults setObject:deviceInfo forKey:kDeviceInfo];
    [userDefaults synchronize];
}

#pragma mark - CLLocationManagerDelegate
- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager
{
    MyLog(@"- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager");
}

- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager
{
    MyLog(@"- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager");
    [_locationManager stopUpdatingLocation];
    [_locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    MyLog(@"- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error");
}

#pragma mark - Timer Action
- (void)timerAction
{
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // 删除过期公文
        NSTimer *datedFileTimer = [NSTimer scheduledTimerWithTimeInterval:kDatedTimeInterval target:self selector:@selector(datedFileToDelete) userInfo:nil repeats:YES];
        // 定时提交日志
        NSTimer *logInfoTimer = [NSTimer scheduledTimerWithTimeInterval:kLogInfoSubmitTime target:self selector:@selector(submitLogInfoToServer) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:datedFileTimer forMode:NSDefaultRunLoopMode];
        [[NSRunLoop currentRunLoop] addTimer:logInfoTimer forMode:NSDefaultRunLoopMode];
//        [[NSRunLoop  currentRunLoop] run];
//    });
}

- (void)datedFileToDelete
{
    NSMutableArray *datedFileArray = [NSMutableArray array];
    NSArray *tag2Array =[ReaderDocument allInMOC:self.managedObjectContext withTag:@2];
    for (ReaderDocument *pdfFile in tag2Array) {
        // 当文件已批阅（tag＝2），且文件存在时间超时，且文件未打开
        if ((([[NSDate date] timeIntervalSinceDate:pdfFile.lastOpen] > kDatedTime)&& [pdfFile.fileOpen isEqualToNumber:@0])) {
            [datedFileArray addObject:pdfFile];
        }
    }
    if (([tag2Array count] > 0) && ([datedFileArray count] == [tag2Array count])) {
        if ([datedFileArray count] > 1) {
            NSMutableArray *newTag2Array = [NSMutableArray array];
            for (int i = 1; i < [datedFileArray count]; i++) {
                [newTag2Array addObject:[datedFileArray objectAtIndex:i]];
            }
            [ReaderDocument deleteInMOC:self.managedObjectContext array:newTag2Array];
        }
        [self performSelector:@selector(deleteLastTag2Object:) withObject:[datedFileArray objectAtIndex:0] afterDelay:5.0];
    }else{
        if ([datedFileArray count]>0) {
            [ReaderDocument deleteInMOC:self.managedObjectContext array:datedFileArray];
        }
    }
}

- (void)deleteLastTag2Object:(ReaderDocument *)lastObject
{
    [ReaderDocument deleteInMOC:self.managedObjectContext object:lastObject];
}

#pragma mark - Submit log to server
- (void)submitLogInfoToServer
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *plistPath = [userDefaults objectForKey:kPlistPath];
    
    // 将Plist日志内容存入词典docPlist中
    __block NSMutableDictionary *docPlist = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    // 日志词典中存在日志，则发送日志到服务器中
    if ([docPlist count] > 0) {
        // 清空Plist日志内容
        NSDictionary *nullDic  = [NSDictionary dictionary];
        [nullDic writeToFile:plistPath atomically:YES];
        
        NSString *submitLogURL = [NSString stringWithFormat:@"%@api/pad/log",kBaseURL];
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
        manager.requestSerializer  = [AFHTTPRequestSerializer  serializer];
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        NSEnumerator *enumerator = [docPlist keyEnumerator];
        id key;
        while ((key = [enumerator nextObject])) {
            /* code that uses the returned key */
            NSString *logMessage   = [[docPlist objectForKey:key] description];
            NSString *logIndex     = [[docPlist objectForKey:key] objectForKey:kLogType];
            if (logIndex) {
                NSDictionary *para     = [NSDictionary dictionaryWithObjectsAndKeys:logMessage,@"logMessage",logIndex,@"logIndex", nil];
                
                // 网络访问是异步的,回调是主线程的,因此程序员不用管在主线程更新UI的事情
                [manager POST:submitLogURL parameters:para success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    [docPlist removeObjectForKey:key];
                    //写入文件
                    [docPlist writeToFile:plistPath atomically:YES];
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    NSString *info = [NSString stringWithFormat:@"Error:Log submit Error In OAAppDelegate.m\n.%@",error.description];
                    [OATools newLogWithInfo:info time:[OATools newStringDate] type:kLogErrorType];
                }];
            }else{
                [docPlist removeObjectForKey:key];
                //写入文件
                [docPlist writeToFile:plistPath atomically:YES];
            }
        }
//        // 发送失败的重新存入Plist文件中
//        if ([docPlist count] > 0) {
//            NSMutableDictionary *newPlist = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
//            if ([newPlist count] > 0) {
//                for (NSDictionary *logDic in newPlist) {
//                    NSString *logTime = [logDic objectForKey:kLogTime];
//                    [docPlist setObject:logDic forKey:logTime];
//                }
//            }
//            //写入文件
//            [docPlist writeToFile:plistPath atomically:YES];
//        }
    }
}

@end

//2015-01-27 15:53:53.983 OAOffice[1395:601449] applicationDidBecomeActive
//2015-01-27 15:53:54.103 OAOffice[1395:601449] Touch ID is available.
//2015-01-27 15:53:54.103 OAOffice[1395:601449] Reachability Flag Status: -R ------- networkStatusForFlags
//2015-01-27 15:53:54.104 OAOffice[1395:601449] reachabilityChanged::::::::::::::YES
//2015-01-27 15:53:54.104 OAOffice[1395:601449] Reachability: Reachable via WiFi
//2015-01-27 15:53:54.104 OAOffice[1395:601449] Baidu Connect:1
//2015-01-27 15:53:54.180 OAOffice[1395:601449] Unbalanced calls to begin/end appearance transitions for <UISplitViewController: 0x13750e270>.
//2015-01-27 15:53:55.132 OAOffice[1395:601449] getUnDoMission:2015-01-27 07:53:55 +0000
//2015-01-27 15:54:03.853 OAOffice[1395:601521] Authentication failed: Touch ID authentication cancelled
//2015-01-27 15:54:03.884 OAOffice[1395:601449] applicationDidBecomeActive
//2015-01-27 15:54:13.328 OAOffice[1395:601449] applicationDidBecomeActive
//2015-01-27 15:54:17.596 OAOffice[1395:601449] Reachability: Not Reachable
//2015-01-27 15:54:17.598 OAOffice[1395:601449] Baidu Connect:1
//2015-01-27 15:54:17.630 OAOffice[1395:601449] Reachability Flag Status: -- ------- networkStatusForFlags
//2015-01-27 15:54:17.631 OAOffice[1395:601449] reachabilityChanged::::::::::::::NO
//2015-01-27 15:54:27.646 OAOffice[1395:601449] - (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
//2015-01-27 15:54:38.421 OAOffice[1395:601449] applicationDidBecomeActive
//2015-01-27 15:54:40.610 OAOffice[1395:601449] Reachability: Reachable via WiFi
//2015-01-27 15:54:40.612 OAOffice[1395:601449] Baidu Connect:0
//2015-01-27 15:54:41.945 OAOffice[1395:601449] Reachability Flag Status: -R ------- networkStatusForFlags
//2015-01-27 15:54:41.946 OAOffice[1395:601449] reachabilityChanged::::::::::::::YES
//2015-01-27 15:54:54.958 OAOffice[1395:601449] getUnDoMission:2015-01-27 07:54:54 +0000
//2015-01-27 15:55:02.803 OAOffice[1395:601449] - (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
//2015-01-27 15:55:03.483 OAOffice[1395:601449] applicationDidBecomeActive
//2015-01-27 15:55:07.969 OAOffice[1395:601449] Reachability: Not Reachable
//2015-01-27 15:55:07.970 OAOffice[1395:601449] Baidu Connect:1
//2015-01-27 15:55:08.074 OAOffice[1395:601449] Reachability Flag Status: -- ------- networkStatusForFlags
//2015-01-27 15:55:08.074 OAOffice[1395:601449] reachabilityChanged::::::::::::::NO

