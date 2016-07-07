//
//  OAMasterViewController.m
//  OAOffice
//
//  Created by admin on 14-7-24.
//  Copyright (c) 2014年 DigitalOcean. All rights reserved.
//

#import "OAMasterViewController.h"
#import "OADetailViewController.h"
#import "OALoginViewController.h"
#import "DoneMissive.h"
#import "OADoneMissiveCell.h"
#import "INSSearchBar.h"
#import "OASearchBarVC.h"
#import "OACover.h"
#import "MJRefresh.h"
#import "Reachability.h"
#import "OAPersonalCenter.h"
#import "OASearchBarVC.h"

@interface OAMasterViewController ()<RefreashMasterDoneMission,UIAlertViewDelegate,INSSearchBarDelegate,SearchBarToMasterDelegate,UISearchBarDelegate,UISearchDisplayDelegate>
{
    INSSearchBar *_searchBar;
    NSString *_userName;
    OASearchBarVC *_searchResult;
    OACover *_cover;
    
    UIImage *_userImage;
    
    NSMutableArray *_dataSource;// 公文数据源
    
    Reachability *_baiduReachability;
    
    
    NSMutableArray *_dataArray;//数据源
    NSMutableArray *_resultArray;//
    NSMutableArray *_resultsData;//搜索结果数据
    NSMutableArray *_arrayOfi;//用来存储结果的序号
    UISearchBar *mySearchBar;
    UISearchDisplayController *mySearchDisplayController;
}
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath withNSSting:(NSString *)string;
//- (void)configureresultCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
@end

@implementation OAMasterViewController

- (void)awakeFromNib
{
    self.clearsSelectionOnViewWillAppear = NO;
    self.preferredContentSize = CGSizeMake(320.0, 600.0);
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
   
    
    self.detailViewController = (OADetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    self.masterToDeatilDelegate = (id)self.detailViewController;
    //数组的初始化，也可放在viewdidload函数里进行初始化
    _dataArray = [NSMutableArray array];
    _resultsData = [NSMutableArray array];
    _arrayOfi = [NSMutableArray array];
    [_dataArray removeAllObjects];
  [self initMysearchBarAndMysearchDisPlay];
    
    [self initNaviColor];
    [self initNaviTitle];
    [self initExitBar];
//    [self initSearchBar];
    
    [self addHeader];
    [self addFooter];
    
    [self netWorkReachability];
}





-(void)initMysearchBarAndMysearchDisPlay
{
    mySearchBar = [[UISearchBar alloc] init];
    mySearchBar.delegate = self;
    //    //设置选项
    //    [mySearchBar setScopeButtonTitles:[NSArray arrayWithObjects:@"First",@"Last",nil]];
    [mySearchBar setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [mySearchBar sizeToFit];
    mySearchBar.backgroundColor = RGBACOLOR(249,249,249,1);
    mySearchBar.backgroundImage = [self imageWithColor:[UIColor clearColor] size:mySearchBar.bounds.size];
//    mySearchBar.backgroundImage =
    //加入列表的header里面
    self.tableView.tableHeaderView = mySearchBar;
    
    mySearchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:mySearchBar contentsController:self];
    mySearchDisplayController.delegate = self;
    mySearchDisplayController.searchResultsDataSource = self;
    mySearchDisplayController.searchResultsDelegate = self;
}


//取消searchbar背景色
- (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size
{
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}




- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)insertNewObject:(id)sender
{
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    NSEntityDescription *entity = [[self.fetchedResultsController fetchRequest] entity];
    NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
    
    // If appropriate, configure the new managed object.
    // Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
    [newManagedObject setValue:[NSDate date] forKey:@"timeStamp"];
    
    // Save the context.
    NSError *error = nil;
    if (![context save:&error]) {
         // Replace this implementation with code to handle the error appropriately.
         // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}



#pragma mark - Init Methods
- (void)initNaviColor
{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.navigationController.navigationBar.barTintColor = kThemeColor;
    self.navigationController.toolbar.barTintColor = kThemeColor;
    self.navigationController.view.tintColor = UIColor.whiteColor;
}

- (void)initNaviTitle
{
    _userName = [[NSUserDefaults standardUserDefaults] objectForKey:kName];
    [self refreashMasterTitleWithName:_userName];
    
}

- (void)initExitAlert
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"您确认退出？" message:@"" delegate:self cancelButtonTitle:@"确认" otherButtonTitles:@"取消", nil];
    [alert show];

//    CGRect rect = self.splitViewController.view.frame;
//    CGRect mastrect = self.view.frame;
//    mastrect.origin.x = -100;
//    mastrect.origin.y = 100;
//    rect.origin.x = -100;
//    rect.origin.y = 100;
//    self.view.frame = mastrect;
//    self.splitViewController.view.frame = rect;
}

- (void)initSearchBar
{
    _searchBar = [[INSSearchBar alloc] initWithFrame:CGRectMake(0, 0, 38, 38.0)];
    _searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
    _searchBar.delegate = self;
    _searchBar.searchField.returnKeyType = UISearchBarIconSearch;
    UIBarButtonItem *searchBar = [[UIBarButtonItem alloc] initWithCustomView:_searchBar];
    self.navigationItem.rightBarButtonItem = searchBar;
}

- (void)initExitBar
{
//    UIImage *userImage = [self circleImage];
//    UIBarButtonItem *exitButton = [[UIBarButtonItem alloc] initWithImage:userImage style:UIBarButtonItemStyleDone target:self action:@selector(initExitAlert)];
    UIBarButtonItem *exitButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"User-Exit@2x.png"] style:UIBarButtonItemStyleDone target:self action:@selector(initExitAlert)];
    self.navigationItem.leftBarButtonItem = exitButton;
}
//圆形图片
//-(UIImage *)circleImage
//{
//    UIImage *userImage;
//    UIImageView *imageview = [[UIImageView alloc] init];
//    
//    imageview.frame = CGRectMake(0, 0, 35, 35);
//    
//    CGSize imageframe = CGSizeMake(30, 30);
//    UIImage *imagename = [self scaleFromImage:[UIImage imageNamed:@"User-Header@2x.png"] scaledToSize:imageframe];
//    
//    imageview.image = imagename;
//    
//    imageview.layer.masksToBounds = YES;
//    
//    imageview.layer.cornerRadius = imageview.bounds.size.width*0.5;
//    
//    imageview.layer.borderWidth=5.0;
//    
//    imageview.layer.borderColor = [UIColor whiteColor].CGColor;
//    userImage = imageview.image;
//    return userImage;
//
//}


- (UIImage*)scaleFromImage:(UIImage*)image scaledToSize:(CGSize)newSize
{
    CGSize imageSize = image.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    
    if (width <= newSize.width && height <= newSize.height){
        return image;
    }
    
    if (width == 0 || height == 0){
        return image;
    }
    
    CGFloat widthFactor = newSize.width / width;
    CGFloat heightFactor = newSize.height / height;
    CGFloat scaleFactor = (widthFactor<heightFactor?widthFactor:heightFactor);
    
    CGFloat scaledWidth = width * scaleFactor;
    CGFloat scaledHeight = height * scaleFactor;
    CGSize targetSize = CGSizeMake(scaledWidth,scaledHeight);
    
    UIGraphicsBeginImageContext(targetSize);
    [image drawInRect:CGRectMake(0,0,scaledWidth,scaledHeight)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

#pragma mark -   
- (void)netWorkReachability
{
//    _baiduReachability = [Reachability reachabilityWithHostName:kBaiduURL];
//    [_baiduReachability startNotifier];
//    
//    NetworkStatus netStatus = [_baiduReachability currentReachabilityStatus];
//    BOOL connectionRequired = [_baiduReachability connectionRequired];
//    MyLog(@"/nnetStatus:%ld,connected:%d",netStatus,connectionRequired);
//    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
}

//- (void)dealloc
//{
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
//}
//
///*!
// * Called by Reachability whenever status changes.
// */
//- (void)reachabilityChanged:(NSNotification *)note
//{
//    MyLog(@"/nreachabilityChanged");
//    Reachability* curReach = [note object];
//    NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
//    NetworkStatus netStatus = [_baiduReachability currentReachabilityStatus];
//    BOOL connectionRequired = [_baiduReachability connectionRequired];
//    
//    switch (netStatus)
//    {
//        case NotReachable:        {
//            /*
//             Minor interface detail- connectionRequired may return YES even when the host is unreachable. We cover that up here...
//             */
//            connectionRequired = NO;
//            MyLog(@"ReachabilityChanged:NotReachable/n");
//            break;
//        }
//            
//        case ReachableViaWWAN:        {
//            MyLog(@"ReachabilityChanged:ReachableViaWWAN/n");
//            break;
//        }
//        case ReachableViaWiFi:        {
//            MyLog(@"ReachabilityChanged:ReachableViaWiFi/n");
//            break;
//        }
//    }
//    
//}

#pragma mark Refreash TableView
- (void)addHeader
{
    __unsafe_unretained typeof(self) vc = self;
    // 添加下拉刷新头部控件
    [self.tableView addHeaderWithCallback:^{
        // 进入刷新状态就会回调这个Block
        [vc refreashTableViewWithPageSize:kPageSize pageNum:1];
  
       
        [vc.tableView reloadData];
        // 结束刷新
        [vc.tableView headerEndRefreshing];
    } dateKey:@"tableview"];
    // dateKey用于存储刷新时间，也可以不传值，可以保证不同界面拥有不同的刷新时间
}

- (void)addFooter
{
    __unsafe_unretained typeof(self) vc = self;
    // 添加上拉刷新尾部控件
    [self.tableView addFooterWithCallback:^{
        // 进入刷新状态就会回调这个Block
        [vc refreashTableViewWithPageSize:kPageSize pageNum:((int)[vc.tableView numberOfRowsInSection:0]/kPageSize+1)];
  
        [vc.tableView reloadData];
        // 结束刷新
        [vc.tableView footerEndRefreshing];
    }];
}


-(void)getAllDoneMissive
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *userName = [userDefaults objectForKey:kUserName];
    NSString *netConnect = [userDefaults objectForKey:kNetConnect];
    __block NSString *authorizationHeader = [userDefaults objectForKey:kAuthorizationHeader];
    // 用户名和密码非空和网络OK时，获取最新任务列表
    if (userName && [netConnect isEqualToString:@"OK"] && authorizationHeader) {
        NSString *serverURL = [[NSString stringWithFormat:@"%@api/ipad/getDoneMissive/%@/%d/%d",kBaseURL,userName,1000,1] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];//转码成UTF-8  否则可能会出现错
        
        NSLog(@"上海海洋大学%@",serverURL);
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager.requestSerializer setValue:authorizationHeader forHTTPHeaderField:@"Authorization"];
        [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"content-type"];
        manager.responseSerializer = [AFJSONResponseSerializer serializer];
        
        [manager GET:serverURL parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if (responseObject == nil) {
                return ;
            }
            // 3 解析返回的JSON数据
            NSData *responseData = [NSJSONSerialization dataWithJSONObject:responseObject options:NSJSONWritingPrettyPrinted error:nil];
            NSArray *result = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:nil];
           
            [_dataArray addObjectsFromArray:result];
             NSLog(@"----------%@,%lu",_dataArray,(unsigned long)_dataArray.count);
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSString *info = [NSString stringWithFormat:@"Error:Refreash history file failure Error!%@",error.description];
            [OATools newLogWithInfo:info time:[OATools newStringDate] type:kLogErrorType];
        }];
    }

}

- (void)refreashTableViewWithPageSize:(int)pageSize pageNum:(int)pageNum
{
//    [_dataArray removeAllObjects];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *userName = [userDefaults objectForKey:kUserName];
    NSString *netConnect = [userDefaults objectForKey:kNetConnect];
    __block NSString *authorizationHeader = [userDefaults objectForKey:kAuthorizationHeader];
    // 用户名和密码非空和网络OK时，获取最新任务列表
    if (userName && [netConnect isEqualToString:@"OK"] && authorizationHeader) {
        NSString *serverURL = [[NSString stringWithFormat:@"%@api/ipad/getDoneMissive/%@/%d/%d",kBaseURL,userName,pageSize,pageNum] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];//转码成UTF-8  否则可能会出现错
        
        NSLog(@"上海海洋大学%@",serverURL);
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager.requestSerializer setValue:authorizationHeader forHTTPHeaderField:@"Authorization"];
        [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"content-type"];
        manager.responseSerializer = [AFJSONResponseSerializer serializer];
        
        [manager GET:serverURL parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if (responseObject == nil) {
                return ;
            }
            // 3 解析返回的JSON数据
            NSData *responseData = [NSJSONSerialization dataWithJSONObject:responseObject options:NSJSONWritingPrettyPrinted error:nil];
            NSArray *result = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:nil];
            _resultArray = [NSMutableArray arrayWithArray:result];
        
//            NSLog(@"001%@",_dataArray);
            for (NSDictionary *dic in result) {
                
//                NSString *title = [dic objectForKey:kMissiveTitle];
//                NSLog(@"002%@",title);
////                NSLog(@"002%lu",(unsigned long)_dataArray.count);
//                for (NSString *st in _dataArray) {
//                    if ([title isEqualToString:st]) {
//                        NSLog(@"chongfu");
//                    }else{
//                    [_dataArray addObject:title];
//                    }
//                }
//                
                
                [self insertNewDoneMissionWithObject:dic];
//
            }
//             NSLog(@"0001%@",_dataArray);
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSString *info = [NSString stringWithFormat:@"Error:Refreash history file failure Error!%@",error.description];
            [OATools newLogWithInfo:info time:[OATools newStringDate] type:kLogErrorType];
        }];
    }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == mySearchDisplayController.searchResultsTableView) {
        NSLog(@"nihaooooooo");
    }
//    return [[self.fetchedResultsController sections] count];
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == mySearchDisplayController.searchResultsTableView) {
        return _resultsData.count;
    }else{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 66;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
//    [_dataArray removeAllObjects];
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    static NSString *cellIdentifier = @"OADoneMissiveCell";
    OADoneMissiveCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle]loadNibNamed:@"OADoneMissiveCell" owner:self options:nil];
        if ([[nib objectAtIndex:0] isKindOfClass:[OADoneMissiveCell class]]) {
            cell = [nib objectAtIndex:0];
        }
    }
//    while ([cell.contentView.subviews lastObject] != nil) {
//        [(UIView *)[cell.contentView.subviews lastObject] removeFromSuperview];
//    }
    
   
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if (tableView == mySearchDisplayController.searchResultsTableView)
    {
       
        [self configureCell:cell atIndexPath:indexPath withNSSting:@"1"];

    }
    else
    {
        
        [self configureCell:cell atIndexPath:indexPath withNSSting:@"2"];
        
            }

   
 
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}


//禁用在cell上滑动进行删除cell的操作
-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
        
        NSError *error = nil;
        if (![context save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }   
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // The table view should not be re-orderable.
    return YES;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (0 == section) {
        UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 20)];
        view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"TableViewHeaderBG"]];
        UILabel *headTitle = [[UILabel alloc] initWithFrame:CGRectMake(15, 5, 200, 20)];
        if(tableView == mySearchDisplayController.searchResultsTableView)
        {
        headTitle.text = @"您的搜索结果如下";
        }else{
            headTitle.text = @"您的已办公文";}
        [view addSubview:headTitle];
        return view;
    }else{
        return nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSManagedObject *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
    self.detailViewController.detailItem = object;
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DoneMissive" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:50];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"missiveDoneTime" ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"用户名"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
	     // Replace this implementation with code to handle the error appropriately.
	     // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return _fetchedResultsController;
}    

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
        default:
            ;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

/*
// Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed. 
 
 - (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    // In the simplest, most efficient, case, reload the table view.
    [self.tableView reloadData];
}
 */

//-(void)configureresultCell:(OADoneMissiveCell *)cell atIndexPath:(NSIndexPath *)indexPath
//{
////    NSLog(@"+++++++++%@",indexPath);
////    NSLog(@"------------%ld",(long)indexPath.row);
//    NSDictionary *dic = _resultArray[2];
//    NSString *mis = [dic objectForKey:kMissiveTitle];
//    NSLog(@"%@",mis);
//
//    for (int i=0; i<_resultsData.count; i++) {
////        NSLog(@"++++++++%@",_arrayOfi);
//        NSString *num1 = _arrayOfi[i];
//        NSInteger num = [num1 integerValue];
//        NSIndexPath *path = [NSIndexPath indexPathForRow:num inSection:0];
//        NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:path];
//        
////        NSString *missivetitle = [object valueForKey:kMissiveTitle];
//
////        NSString *resultTitle = _resultsData[i];
////        if ([missivetitle isEqualToString:resultTitle]) {
////            NSLog(@"%@ == %@",missivetitle,resultTitle);
//            cell.missiveTitle.text = [object valueForKey:kMissiveTitle];
//            cell.missiveTaskName.text = [object valueForKey:kTaskName];
//            cell.missiveAddr = [object valueForKey:kMissiveAddr];
//            
//            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//            [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
//            cell.missiveDoneTime.text = [dateFormatter stringFromDate:[object valueForKey:kMissiveDoneTime]];
//            
//            NSString *type = [cell.missiveAddr componentsSeparatedByString:@"/"][2];
//            if ([type isEqualToString:@"missivePublish"]) {
//                cell.missiveType.text = @"发文";
//                cell.missiveType.backgroundColor = kPublishColor;
//            }else if ([type isEqualToString:@"missiveReceive"]){
//                cell.missiveType.text = @"收文";
//                cell.missiveType.backgroundColor = kReceiveColor;
//            }else if ([type isEqualToString:@"missiveSign"]){
//                cell.missiveType.text = @"签报";
//                cell.missiveType.backgroundColor = kSignColor;
//            }else if ([type isEqualToString:@"faxCablePublish"]){
//                cell.missiveType.text = @"传真";
//            }
//            [cell.missiveDownloadBtn addTarget:self action:@selector(cellMissiveFileDownload:) forControlEvents:UIControlEventTouchUpInside];
//
//            
//        }
//
//    }
//    
//    


-(void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"不用的方法");
}
- (void)configureCell:(OADoneMissiveCell *)cell atIndexPath:(NSIndexPath *)indexPath withNSSting:(NSString *)viewname
{


    if ([viewname isEqualToString:@"1"]) {
        //在此处设置搜索结果
        NSDictionary *object = [_resultsData objectAtIndex:indexPath.row];
        NSString *missivetitle = [object valueForKey:kMissiveTitle];
        cell.missiveTitle.text = missivetitle;
        cell.missiveTaskName.text = [object valueForKey:kTaskName];
        cell.missiveAddr = [object valueForKey:kMissiveAddr];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSString *donetime = [object valueForKey:kMissiveDoneTime];
        NSLog(@"时间===%@",donetime);
        cell.missiveDoneTime.text = donetime;
   
        
        NSString *type = [cell.missiveAddr componentsSeparatedByString:@"/"][2];
        if ([type isEqualToString:@"missivePublish"]) {
            cell.missiveType.text = @"发文";
            cell.missiveType.backgroundColor = kPublishColor;
        }else if ([type isEqualToString:@"missiveReceive"]){
            cell.missiveType.text = @"收文";
            cell.missiveType.backgroundColor = kReceiveColor;
        }else if ([type isEqualToString:@"missiveSign"]){
            cell.missiveType.text = @"签报";
            cell.missiveType.backgroundColor = kSignColor;
        }else if ([type isEqualToString:@"faxCablePublish"]){
            cell.missiveType.text = @"传真";
        }
[cell.missiveDownloadBtn addTarget:self action:@selector(cellDoneMissiveFileDownload:) forControlEvents:UIControlEventTouchUpInside];
        
    }else{
     NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
     NSString *missivetitle = [object valueForKey:kMissiveTitle];
  
    cell.missiveTitle.text = missivetitle;
    cell.missiveTaskName.text = [object valueForKey:kTaskName];
    cell.missiveAddr = [object valueForKey:kMissiveAddr];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    cell.missiveDoneTime.text = [dateFormatter stringFromDate:[object valueForKey:kMissiveDoneTime]];
    
    NSString *type = [cell.missiveAddr componentsSeparatedByString:@"/"][2];
    if ([type isEqualToString:@"missivePublish"]) {
        cell.missiveType.text = @"发文";
        cell.missiveType.backgroundColor = kPublishColor;
    }else if ([type isEqualToString:@"missiveReceive"]){
        cell.missiveType.text = @"收文";
        cell.missiveType.backgroundColor = kReceiveColor;
    }else if ([type isEqualToString:@"missiveSign"]){
        cell.missiveType.text = @"签报";
        cell.missiveType.backgroundColor = kSignColor;
    }else if ([type isEqualToString:@"faxCablePublish"]){
        cell.missiveType.text = @"传真";
    }
    
   
    [cell.missiveDownloadBtn addTarget:self action:@selector(cellMissiveFileDownload:) forControlEvents:UIControlEventTouchUpInside];
    }
    
}

#pragma mark - Other Methods
// kOADoneMissive 唯一标示是MissiveId，不是TaskId，DB真坑；一个公文流程中只保存最新的已办公文，中间办理的内容被丢弃了。
- (BOOL)searchWithPredicate:(NSString *)predicate withTaskId:(NSString *)taskId
{
    // 1. 实例化查询请求
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kOADoneMissive];
    
    // 2. 设置谓词条件
    request.predicate = [NSPredicate predicateWithFormat:predicate];
    
    // 3. 由上下文查询数据
    NSArray *result = [self.managedObjectContext executeFetchRequest:request error:nil];
    for (DoneMissive *object in result) {
        if (![object.taskId isEqualToString:taskId]) {
            [[self.fetchedResultsController managedObjectContext] deleteObject:object];
            return NO;
        }
    }
    if ([result count] > 0) {
        return YES;
    }else{
        return NO;
    }
}


-(void)cellDoneMissiveFileDownload:(UIButton *)sender
{
    OADoneMissiveCell *downloadCell = (OADoneMissiveCell *)sender.superview.superview;
    NSIndexPath *indexPath = [self.searchDisplayController.searchResultsTableView indexPathForCell:downloadCell];
    NSLog(@"点击按钮下载事件%ld",(long)indexPath.row);
    
    NSDictionary *object = [_resultsData objectAtIndex:indexPath.row];
    
    [downloadCell.missiveDownloadBtn setImage:[UIImage imageNamed:@"User-Downloading"] forState:UIControlStateNormal];
    [downloadCell.missiveDownloadBtn configureToSelected:YES];
    [downloadCell.missiveDownloadBtn keepHighLighted:YES];
    
    [self.masterToDeatilDelegate cellDoneMissiveWithNSDictory:object];
}
- (void)cellMissiveFileDownload:(UIButton *)sender
{
    OADoneMissiveCell *downloadCell = (OADoneMissiveCell *)sender.superview.superview;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:downloadCell];
    NSLog(@"点击按钮下载事件111%ld",(long)indexPath.row);
    NSManagedObject *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
    
    [downloadCell.missiveDownloadBtn setImage:[UIImage imageNamed:@"User-Downloading"] forState:UIControlStateNormal];
    [downloadCell.missiveDownloadBtn configureToSelected:YES];
    [downloadCell.missiveDownloadBtn keepHighLighted:YES];

    [self.masterToDeatilDelegate downloadDoneMissiveWithObject:object];
}

#pragma mark - SearchBarToMasterDelegate
- (void)sendSearchBarResultWithDic:(NSDictionary *)result
{
    [self.masterToDeatilDelegate downloadDoneMissiveWithObject:result];
}

#pragma mark - UIAlertView Delegate 右顶角按钮提示
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0: // 确认
        {
            // 跳转到登录界面；
            [self.masterToDeatilDelegate exitToLoginVC];
        }
            break;
        case 1: // 取消
            break;
        default:
            break;
    }
}




#pragma mark - OAMasterDelegate
- (void)insertNewDoneMissionWithObject:(NSDictionary *)object
{
    
////    //得到公文标题的名称，以便放入数组中
//    NSString *missivetitle = [object objectForKey:kMissiveTitle];
//    NSLog(@"002%@",missivetitle);
//
//        
//    for (int i=0; i<_dataArray.count; i++) {
//        if ([missivetitle isEqualToString:_dataArray[i]] ) {
//            [_dataArray addObject:missivetitle];
//        }
//        
//    }
//    NSLog(@"003%@",_dataArray);
//
    
    
    NSString *missiveId = [[object objectForKey:kMissiveAddr] componentsSeparatedByString:@"/"][3];
    NSString *taskId    = [NSString stringWithFormat:@"%@",[object objectForKey:kTaskId]];
    NSString *predicate = [NSString stringWithFormat:@"missiveId = '%@'",missiveId];
    
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    NSEntityDescription *entity = [[self.fetchedResultsController fetchRequest] entity];
    
    if (![self searchWithPredicate:predicate withTaskId:taskId]) {
        NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
        
        // If appropriate, configure the new managed object.
        // Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
        
        [newManagedObject setValue:taskId forKey:kTaskId];
        [newManagedObject setValue:[object objectForKey:kTaskName] forKey:kTaskName];
        [newManagedObject setValue:[object objectForKey:kMissiveTitle] forKey:kMissiveTitle];
        [newManagedObject setValue:[object objectForKey:kMissiveAddr] forKey:kMissiveAddr];
        [newManagedObject setValue:[object objectForKey:@"urgency"] forKey:kUrgentLevel];
        [newManagedObject setValue:missiveId forKey:kMissiveId];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSDate *missiveDoneTime = [dateFormatter dateFromString:[object valueForKey:kMissiveDoneTime]];
        [newManagedObject setValue:missiveDoneTime forKey:kMissiveDoneTime];
        
        
        // Save the context.
        NSError *error = nil;
        if (![context save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

- (void)refreashMasterTitleWithName:(NSString *)name
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont boldSystemFontOfSize:20.0];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor]; // change this color
    label.text = NSLocalizedString(name, @"title");
    [label sizeToFit];
    _userName = name;
    self.navigationItem.titleView = label;
}

- (void)refreashMasterTableView
{

    [self.tableView reloadData];
}

- (void)refreashMasterTableViewWithID:(NSString *)objectID
{
    
//    [downloadCell.missiveDownloadBtn setImage:[UIImage imageNamed:@"User-Download"] forState:UIControlStateNormal];
}

#pragma mark - search bar delegate

- (CGRect)destinationFrameForSearchBar:(INSSearchBar *)searchBar
{
    [searchBar.searchField setFrame:CGRectMake(15, 4.0, self.tableView.frame.size.width - 30, 28)];
    return CGRectMake(20.0, 20, CGRectGetWidth(self.tableView.bounds) - 35.0, 34.0);
}

- (void)searchBar:(INSSearchBar *)searchBar willStartTransitioningToState:(INSSearchBarState)destinationState
{
    if (destinationState == 1) {
        [self refreashMasterTitleWithName:@""];
        self.navigationItem.leftBarButtonItem = nil;
        // 1.显示取消按钮
//        [_searchBar setShowsCancelButton:YES animated:YES];
        
        // 2.显示遮盖（蒙板）
        if (_cover == nil) {
            _cover = [OACover coverWithTarget:self action:@selector(coverClick)];
        }
        _cover.frame = self.tableView.frame;
        [self.view addSubview:_cover];
        _cover.alpha = 0.0;
        [UIView animateWithDuration:0.3 animations:^{
            [_cover reset];
        }];
    }else{
        [self coverClick];
        [self initExitBar];
        [self initNaviTitle];
    }
}

- (void)searchBar:(INSSearchBar *)searchBar didEndTransitioningFromState:(INSSearchBarState)previousState
{
    if(previousState != INSSearchBarStateNormal){
        
    }
}

- (void)searchBarDidTapReturn:(INSSearchBar *)searchBar
{
    if (searchBar.searchField.text.length > 0) {
        [self.masterToSearchDelegate searchWithText:searchBar.searchField.text];
    }
}

- (void)searchBarTextDidChange:(INSSearchBar *)searchBar
{
    if (searchBar.searchField.text.length == 0) {
        // 隐藏搜索界面
        [_searchResult.view removeFromSuperview];
    } else {
        // 显示搜索界面
        if (_searchResult == nil) {
            _searchResult = [[OASearchBarVC alloc] init];
            _searchResult.view.frame = _cover.frame;
            _searchResult.searchBarDelegate = self;
            _searchResult.view.autoresizingMask = _cover.autoresizingMask;
            [self addChildViewController:_searchResult];
            self.masterToSearchDelegate = (id)_searchResult;
//            [self.masterToSearchDelegate searchWithText:searchBar.searchField.text];
        }
//        _searchResult.searchText = searchText;
//        [self.masterToSearchDelegate searchWithText:searchBar.searchField.text];
        
        if (!_searchResult.view.superview) {
            [self.view addSubview:_searchResult.view];
        }
    }
}




//searchBar开始编辑时改变取消按钮的文字
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    [_dataArray removeAllObjects];
    [self getAllDoneMissive];
    
    
    NSLog(@"004");
    
    mySearchBar.showsCancelButton = YES;
    
    NSArray *subViews;
    
    if (is_IOS_7) {
        subViews = [(mySearchBar.subviews[0]) subviews];
    }
    else {
        subViews = mySearchBar.subviews;
    }
    
    for (id view in subViews) {
        if ([view isKindOfClass:[UIButton class]]) {
            UIButton* cancelbutton = (UIButton* )view;
            [cancelbutton setTitle:@"取消" forState:UIControlStateNormal];
            break;
        }
    }
}

-(BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    
    NSLog(@"005");
    //準備搜尋前，把上面調整的TableView調整回全屏幕的狀態
    [UIView animateWithDuration:1.0 animations:^{
        self.tableView.frame = CGRectMake(0, 20, 320, SCREEN_HEIGHT-20);
    }];
    
    return YES;
}

-(BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar
{
    NSLog(@"006");
    //搜尋結束後，恢復原狀
    [UIView animateWithDuration:1.0 animations:^{
        self.tableView.frame = CGRectMake(0, is_IOS_7?64:44, 320, SCREEN_HEIGHT-64);
    }];
    
    return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller

shouldReloadTableForSearchString:(NSString *)searchString

{
    NSLog(@"007");
    //一旦SearchBar輸入內容有變化，則執行這個方法，詢問要不要重裝searchResultTableView的數據
    
    // Return YES to cause the search result table view to be reloaded.
    
    [self filterContentForSearchText:searchString
                               scope:[mySearchBar scopeButtonTitles][mySearchBar.selectedScopeButtonIndex]];
    
    return YES;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller

shouldReloadTableForSearchScope:(NSInteger)searchOption

{
    NSLog(@"008");
    //如果设置了选项，当Scope Button选项有變化的时候，則執行這個方法，詢問要不要重裝searchResultTableView的數據
    
    // Return YES to cause the search result table view to be reloaded.
    
    [self filterContentForSearchText:mySearchBar.text
                               scope:mySearchBar.scopeButtonTitles[searchOption]];
    
    return YES;
}

//源字符串内容是否包含或等于要搜索的字符串内容
-(void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{

//    NSLog(@"009%@",_dataArray);
    NSMutableArray *tempResults = [NSMutableArray array];
    NSUInteger searchOptions = NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch;
    
    for (int i = 0; i < _dataArray.count; i++) {
//        NSString *storeString = _dataArray[i];
        NSDictionary *dictory = _dataArray[i];
        NSString *missivetitle = [dictory objectForKey:kMissiveTitle];
        NSString *donetime = [dictory objectForKey:kMissiveDoneTime];
        NSString *missiveadre = [dictory valueForKey:kMissiveAddr];
        NSString *missivetype;
        NSString *type = [missiveadre componentsSeparatedByString:@"/"][2];
        if ([type isEqualToString:@"missivePublish"]) {
           missivetype = @"发文";
    
        }else if ([type isEqualToString:@"missiveReceive"]){
            missivetype = @"收文";
         
        }else if ([type isEqualToString:@"missiveSign"]){
          missivetype = @"签报";
         
        }else if ([type isEqualToString:@"faxCablePublish"]){
           missivetype = @"传真";
        }
        NSString *storeString = [NSString stringWithFormat:@"%@,%@,%@,",missivetype, missivetitle,donetime];
      
        NSRange storeRange = NSMakeRange(0, storeString.length);
        NSRange foundRange = [storeString rangeOfString:searchText options:searchOptions range:storeRange];
        if (foundRange.length) {
//            [tempResults addObject:storeString];
            [tempResults addObject:dictory];
            
//            NSLog(@"i = %d",i);
//            NSString *x = [NSString stringWithFormat:@"%d",i];
//            [_arrayOfi addObject:x];
        }
    }
//    NSLog(@"x==%@",_arrayOfi);
    NSLog(@"0101--%@,%lu",tempResults,(unsigned long)tempResults.count);
    [_resultsData removeAllObjects];
    [_resultsData addObjectsFromArray:tempResults];
    NSLog(@"010---%@",_resultsData);
    //需要将_resultsData数组类型转换成
}


#pragma mark 监听点击遮盖
- (void)coverClick
{
    // 1.移除遮盖
    [UIView animateWithDuration:0.3 animations:^{
        _cover.alpha = 0.0;
    } completion:^(BOOL finished) {
        [_cover removeFromSuperview];
        [_searchBar hideSearchBar:nil];
    }];
    
    // 2.隐藏取消按钮
//    [_searchBar setShowsCancelButton:NO animated:YES];
    
    // 3.退出键盘
    [_searchBar resignFirstResponder];
}

@end
