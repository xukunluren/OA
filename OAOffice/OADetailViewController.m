//
//  OADetailViewController.m
//  OAOffice
//
//  Created by admin on 14-7-24.
//  Copyright (c) 2014年 DigitalOcean. All rights reserved.
//

#import "OAAppDelegate.h"
#import "OADetailViewController.h"
#import "OAMasterViewController.h"
#import "OALoginViewController.h"
#import "ReaderViewController.h"

#import "OAPDFCell.h"
#import "OAPDFHeader.h"
#import "OAPDFFlowLayout.h"

#import "MJRefresh.h"
#import "CoreDataManager.h"
#import "ReaderDocument.h"
#import "DoneMissive.h"
#import "AFNetworking.h"
#import "EAIntroView.h"

@interface OADetailViewController () <UIPopoverControllerDelegate, UIAlertViewDelegate, ReaderViewControllerDelegate, OALoginViewControllerDelegate, MasterToDetailDelegate,EAIntroDelegate>
{
    BOOL _judge;
    BOOL IsDowning;
    BOOL shouldReloadCollectionView;
    NSBlockOperation *blockOperation;
    
    ReaderDocument  *_openedDocument;
    ReaderDocument  *_deletedDocument;
    NSIndexPath     *_selectedIndexPath;
    
    NSNumber        *_editState;
    NSUInteger       _badgeNumber;
    
    NSDictionary    *_itemDic;
    
    UIView          *_nilItemsView;
    
    NSMutableArray  *_objectChanges;
    NSMutableArray  *_sectionChanges;
    
    BOOL _loginToSplitVC;
    BOOL _loginState;
}

// Non-UI Properties

@property (strong, nonatomic) UIPopoverController *masterPopoverController;
- (void)configureView;

@end

@implementation OADetailViewController

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        // Update the view.
        [self configureView];
    }

    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }
}

- (void)configureView
{
    // Update the user interface for the detail item.

    if (self.detailItem) {
//        self.detailDescriptionLabel.text = [[self.detailItem valueForKey:@"timeStamp"] description];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];


//    self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    // 1.初始化界面
    [self configureView];
    [self.collectionView reloadData];
    
    [self initNaviTitle];
    [self initNaviColor];
    [self initRightBtn];
    
    // 2. Init var
    _objectChanges   = [NSMutableArray array];
    _sectionChanges  = [NSMutableArray array];
    
    _openedDocument  = nil;
    _deletedDocument = nil;
//    _badgeNumber     = 0;//[UIApplication sharedApplication].applicationIconBadgeNumber;//0;
    
    _loginToSplitVC  = YES;
    _loginState      = NO;
    
    _editState       = @1;//初始化为1，表示非编辑状态
    _selectedIndexPath = nil;
    
    self.masterDelegate = (id)(OAMasterViewController *)[[self.splitViewController.viewControllers firstObject] topViewController];
    
    UIUserNotificationSettings* notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
    
    // 3. Init CollectionView
    [self initCollectionView];
    [self initNoItemView];
    
    // 4.集成刷新控件
    [self addHeader];
    [self addFooter];
    
    [self addNetworkObserver];
    [self addBecomeActiveObserver];
    
    // 5.获取最新的公文列表
//    [self getUnDoMission];
    
    // 后台定时操作:不用scheduled方式初始化的，需要手动addTimer:forMode: 将timer添加到一个runloop中。
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // 定时刷新获取最新公文
        [NSTimer scheduledTimerWithTimeInterval:kUnDoTimeInterval target:self selector:@selector(getUnDoMission) userInfo:nil repeats:YES];
        [NSTimer scheduledTimerWithTimeInterval:kDoneTimeTnterval target:self selector:@selector(getDoneMission) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] run];
    });
    
    [self.collectionView reloadData];
    
    // 8.Login
    [self presentLoginView];
}


//用来判断当前服务器是否能用，不能用的话切换到备用服务器

-(BOOL *)judgeTheUrl:(NSString *)longUrl
{
    //    NSDictionary *result;
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager.requestSerializer setTimeoutInterval:kLogTimeoutInterval];
    [manager POST:longUrl parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *resultDic = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableLeaves error:nil];
        if ([resultDic count]>0) {
            _judge = YES;
        }else
        {
            _judge = NO;
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        _judge = NO;
    }];
    return &(_judge);
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.collectionView reloadData];
}

#pragma mark - Init Methods Custom
- (void)initNaviTitle
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont boldSystemFontOfSize:20.0];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor]; // change this color
    self.navigationItem.titleView = label;
    label.text = NSLocalizedString(@"移动办公", @"title");
    [label sizeToFit];
}

- (void)initNaviColor
{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.navigationController.navigationBar.barTintColor = kThemeColor;
    self.navigationController.toolbar.barTintColor = kThemeColor;
    self.navigationController.view.tintColor = UIColor.whiteColor;
}

- (void)initRightBtn
{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(0, 0, 30, 30);
    [btn setImage:[UIImage imageNamed:@"User-Trash.png"] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(editItemClicked) forControlEvents:UIControlEventTouchUpInside];
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(clearOldData)];
    [btn addGestureRecognizer:longPress];
    UIBarButtonItem *rightNavBtn = [[UIBarButtonItem alloc] initWithCustomView:btn];
    
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlackTranslucent];
    [self.navigationItem setRightBarButtonItem:rightNavBtn];
}

- (void)initAfterLogin
{
    // 1.判断是否为新用户，若为新用户，删除已有文件（清空）
    [self newUserOldFileDelete];
    
    // 2.登录后，刷新新公文
    [self.collectionView headerBeginRefreshing];
    
    // 3.刷新获取新Task
    [self getUnDoMission];
    
    // 4.刷新已办公文
    [self getDoneMission];
    
    // 5.获取会签选择人员列表(每次登陆时都获取一次，保证最新列表)
    [OATools getAllUserToPlist];
}

- (void)initCollectionView
{
    // 0.创建自己的collectionView
    CGRect rect = self.view.bounds;
    rect.origin.y = 20;
    
    OAPDFFlowLayout *flowLayout = [[OAPDFFlowLayout alloc] init];
    self.collectionView = [[UICollectionView alloc] initWithFrame:rect collectionViewLayout:flowLayout];
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.collectionView.delegate    = self;
    self.collectionView.dataSource  = self;
    [self.view addSubview:self.collectionView];
    
    // observe changes on the collection view's layout so we can update our data source if needed
    [self.collectionView addObserver:self
                          forKeyPath:@"collectionViewLayout"
                             options:NSKeyValueObservingOptionNew
                             context:nil];
    self.collectionView.collectionViewLayout = flowLayout;
    
    // 1.注册cell要用到的xib/class
    [self.collectionView registerClass:[OAPDFCell   class] forCellWithReuseIdentifier:@"OAPDFCell"];
    [self.collectionView registerClass:[OAPDFHeader class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"OAPDFHeader"];
    
    // 2.设置collectionView永远支持垂直滚动(弹簧)
    self.collectionView.alwaysBounceVertical = YES;
    
    // 3.背景色
    //    self.collectionView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"BookShelfCell.png"]];
    self.collectionView.backgroundColor = [UIColor clearColor];
    
    // 4.单选
    self.collectionView.allowsSelection = YES;
    self.collectionView.allowsMultipleSelection = NO;
}

- (void)initNoItemView
{
    _nilItemsView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 130, 130+5+30)];
    
    UIImageView *iconView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 130, 130)];
    iconView.image = [UIImage imageNamed:@"Icon-130"];
    iconView.layer.masksToBounds = YES;
    iconView.layer.cornerRadius = iconView.bounds.size.height/2;
    iconView.layer.borderWidth = 3.0f;
    iconView.layer.borderColor = [[UIColor grayColor] CGColor];
    [_nilItemsView addSubview:iconView];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 135, 80, 30)];
    label.center = CGPointMake(iconView.center.x, iconView.center.y + iconView.frame.size.height * 0.5 + 5 + label.frame.size.height * 0.5);
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont systemFontOfSize:18.0f];
    label.textColor = [UIColor lightGrayColor];
    label.layer.borderWidth = 1.0f;
    label.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    label.layer.cornerRadius = 5;
    label.text = @"暂无文件";
    [_nilItemsView addSubview:label];
    _nilItemsView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    _nilItemsView.center = CGPointMake(self.view.center.x, self.view.center.y - 80);
    if ([[self.fetchedResultsController sections] count] == 0) {
        [self.collectionView addSubview:_nilItemsView];
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    _nilItemsView.center = CGPointMake(self.view.center.x, self.view.center.y - 80);
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingOperationDidFinishNotification object:nil];
}

#pragma mark - Some base Mehtods
- (void)presentLoginView
{
    _loginState = NO;
    if (self.masterPopoverController) {
        [self.masterPopoverController dismissPopoverAnimated:NO];
    }
    OALoginViewController *newLoginVC = [[OALoginViewController alloc] initWithNibName:@"OALoginViewController" bundle:nil];
    newLoginVC.delegate = self;
    newLoginVC.isTouchID = YES;
    [self.splitViewController presentViewController:newLoginVC animated:NO completion:nil];
}

- (void)editItemClicked
{
    // 编辑模式，可删除公文
    if ([_editState isEqualToNumber:@1]) {
        _editState = @2;
    }else{
        _editState = @1;
    }
    [self.collectionView reloadData];
}

- (BOOL)connected
{
    return [AFNetworkReachabilityManager sharedManager].reachable;
}

- (void)newUserOldFileDelete
{
    // 1.新用户，原用户文件全删除
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSLog(@"公文中心进行修改%@", [userDefaults objectForKey:kNewUser]);
   
    if ([[userDefaults objectForKey:kNewUser] isEqualToString:@"YES"]) {
        [userDefaults setValue:@"NO" forKey:kNewUser];
        [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
        // 2.
//        [self showIntroWithCrossDissolve];
        // 3.清除老用户公文
        [self clearOldData];
    }
    //清除已办公文列表
    [self removeObjectsWithPredicate:@"missiveAddr CONTAINS '.pdf'" withEntityName:kOADoneMissive];
}

- (void)clearOldData
{
    // 1.清除老用户公文
    [self removeObjectsWithPredicate:@"fileName CONTAINS '.pdf'" withEntityName:kOAPDFDocument];
    
    // 2.应用角标归零
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    
    // 3.Master title 显示用户名
    [self.masterDelegate refreashMasterTitleWithName:[[NSUserDefaults standardUserDefaults] objectForKey:kName]];
    
    // 4.collectionView 刷新数据
    [self.collectionView reloadData];
}

- (void)showIntroWithCrossDissolve {
    EAIntroPage *page1 = [EAIntroPage page];
    page1.title = @"欢迎使用移动办公iPad客户端";
    page1.desc = @"1、主页功能";
    page1.bgImage = [UIImage imageNamed:@"1"];
    page1.titleImage = [UIImage imageNamed:@"original"];
    
    EAIntroPage *page2 = [EAIntroPage page];
    page2.title = @"2";
    page2.desc = @"Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore.";
    page2.bgImage = [UIImage imageNamed:@"2"];
    page2.titleImage = [UIImage imageNamed:@"supportcat"];
    
    EAIntroPage *page3 = [EAIntroPage page];
    page3.title = @"This is page 3";
    page3.desc = @"Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem.";
    page3.bgImage = [UIImage imageNamed:@"3"];
    page3.titleImage = [UIImage imageNamed:@"femalecodertocat"];
    
    EAIntroView *intro = [[EAIntroView alloc] initWithFrame:self.view.bounds andPages:@[page1,page2,page3]];
    intro.autoresizesSubviews = YES;
    intro.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    [intro setDelegate:self];
    [intro showInView:self.splitViewController.view animateDuration:0.0];
}

- (void)introDidFinish {
    NSLog(@"Intro callback");
}

- (BOOL)searchObjectsWithPredicate:(NSString *)predicate withEntityName:(NSString *)entity
{
    // 1. 实例化查询请求
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entity];
    
    // 2. 设置谓词条件
    //    request.predicate = [NSPredicate predicateWithFormat:@"name = '张老头'"];
    request.predicate = [NSPredicate predicateWithFormat:predicate];
    
    // 3. 由上下文查询数据
    NSArray *result = [self.managedObjectContext executeFetchRequest:request error:nil];
    
    // 4. 通知_context保存数据
    NSError *error;
    if ([self.managedObjectContext save:&error]) {
        if ([result count] > 0) {
            return NO;// 有搜索结果，返回NO
        }
    } else {
        
    }
    return YES;// 没有搜索结果，返回YES
}

- (void)removeObjectsWithPredicate:(NSString *)predicate withEntityName:(NSString *)entity
{
    // 1. 实例化查询请求
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entity];
    
    // 2. 设置谓词条件
    //    request.predicate = [NSPredicate predicateWithFormat:@"name = '张老头'"];
    request.predicate = [NSPredicate predicateWithFormat:predicate];
    
    // 3. 由上下文查询数据
    NSArray *result = [self.managedObjectContext executeFetchRequest:request error:nil];
    
    // 4. 输出结果
     NSLog(@"公文中心进行修改---%@", entity);
    if ([entity isEqualToString:kOAPDFDocument]) {
        for (ReaderDocument *object in result) {
            if ([object.fileTag isEqualToNumber:@1]) {
                [self cancelNotificationWithObject:object.fileName andKey:object.guid];
            }
            // 删除一条记录
            [self.managedObjectContext deleteObject:object];
            
//            NSError *error;
//            // Sign pdf的文件路径filePath,删除该文件;
//            if ([object fileExistsAndValid:object.fileURL]) {
//                [[[NSFileManager alloc]init] removeItemAtURL:[NSURL fileURLWithPath:object.fileURL] error:&error];
//                MyLog(@"Pdf Delete Error:%@",error.description);
//            }
//            // Sign png的文件路径pngPath,删除该文件;
//            NSString *pngPath = [kDocumentPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png",object.fileId]];
//            if ([[[NSFileManager alloc]init] fileExistsAtPath:pngPath]) {
//                [[[NSFileManager alloc]init] removeItemAtPath:pngPath error:&error];
//                MyLog(@"Png Delete Error:%@",error.description);
//            }
        }
        
        // 删除所有的PDF及签写的PNG图片
        NSArray *contents = [[NSFileManager new] contentsOfDirectoryAtPath:kDocumentPath error:NULL];
        NSEnumerator *e = [contents objectEnumerator];
        NSString *filename;
        while ((filename = [e nextObject])) {
            if ([[filename pathExtension] isEqualToString:@"pdf"] || [[filename pathExtension] isEqualToString:@"png"]) {
                [[NSFileManager new] removeItemAtPath:[kDocumentPath stringByAppendingPathComponent:filename] error:NULL];
            }
        }
        
        [self showNilItemView];
    }else if ([entity isEqualToString:kOADoneMissive]){
        for (DoneMissive *missive in result) {
            [self.managedObjectContext deleteObject:missive];
        }
    }
    
    // 5. 通知_context保存数据
    NSError *error;
    if ([self.managedObjectContext save:&error]) {
        NSString *info = [NSString stringWithFormat:@"OK:user data clear OK! In OADetailViewController.m"];
        [OATools newLogWithInfo:info time:[OATools newStringDate] type:kLogInfoType];
    } else {
        NSString *info = [NSString stringWithFormat:@"Error:user data clear Error! In OADetailViewController.m.%@",error.description];
        [OATools newLogWithInfo:info time:[OATools newStringDate] type:kLogErrorType];
    }
}

- (void)deletePDFWithObject:(ReaderDocument *)reader
{
    [self.collectionView performBatchUpdates:^{
        [self performSelectorInBackground:@selector(documentDeleteInMOCWithTheDeleteDocument:) withObject:reader];
    }
                                  completion:^(BOOL finished) {
                                      _deletedDocument = nil;
                                      
                                      MyLog(@"Delete guid:%@ OK!\n",reader.guid);
                                      NSString *info = [NSString stringWithFormat:@"OK:Dated File:%@ Delete OK!",reader.fileName];
                                      [OATools newLogWithInfo:info time:[OATools newStringDate] type:kLogInfoType];
                                  }];
    
    if ([[self.fetchedResultsController sections] count] == 0) {
        [self.collectionView addSubview:_nilItemsView];
    }
}

#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.image = [UIImage imageNamed:@"User-Home.png"];
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}


#pragma mark - UICollectionViewDataSource methods

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return [[self.fetchedResultsController sections] count];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    OAPDFHeader *header = nil;
    if (kind == UICollectionElementKindSectionHeader) {
        header = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"OAPDFHeader" forIndexPath:indexPath];
        id <NSFetchedResultsSectionInfo> sectionInfo = [[[self fetchedResultsController] sections] objectAtIndex:[indexPath section]];
        switch ([sectionInfo name].intValue) {
            case 1:
                [[header titleLabel] setText:@"最新文件"];
                break;
                
            case 2:
                [[header titleLabel] setText:@"已签文件"];
                break;
                
            default:
                break;
        }
    }
    return header;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    if (0 == section) {
        [UIApplication sharedApplication].applicationIconBadgeNumber = [sectionInfo numberOfObjects];
    }
    return [sectionInfo numberOfObjects];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    
    // 1. 声明静态标识
    static NSString* oaPDFCellIdentifier = @"OAPDFCell";
    
    // 2. 启用重用机制
    OAPDFCell *cell = (OAPDFCell *)[collectionView dequeueReusableCellWithReuseIdentifier:oaPDFCellIdentifier forIndexPath:indexPath];
    
    // 3.
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGesture:)];
    //设置长按时间
    longPressGesture.minimumPressDuration = 0.5;
    [cell addGestureRecognizer:longPressGesture];
    
    // 4.
    ReaderDocument *object = (ReaderDocument *)[self.fetchedResultsController objectAtIndexPath:indexPath];
//    cell.document = object;
    
    // 5.

    cell.titleLabel.text = [[object valueForKey:kFileName] stringByDeletingPathExtension];
//    NSString *titleStr = [cell.titleLabel.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
//    CGSize titleSize = [titleStr sizeWithAttributes:@{NSFontAttributeName: cell.titleLabel.font}];
//    if (titleSize.width <= cell.titleLabel.frame.size.width) {
//        cell.titleLabel.center = CGPointMake(cell.titleLabel.center.x,cell.titleLabel.center.y + 20);
//    }
    
    // 6.编辑状态
    [cell.deleteBtn addTarget:self action:@selector(pdfCellDelete:) forControlEvents:UIControlEventTouchUpInside];
    if ([_editState isEqualToNumber:@2]) {
        cell.deleteBtn.hidden = NO;
    }else{
        cell.deleteBtn.hidden = YES;
    }
    
    // 7. Tag 标签(未签有标签)
//    if ([object.fileTag isEqualToNumber:@1]) {
        if ([object.urgencyLevel isEqualToString:@"急"]) {
            cell.tagView.image = [UIImage imageNamed:@"File-Urgent.png"];
        }else if ([object.urgencyLevel isEqualToString:@"加急"])
        {
            cell.tagView.image = [UIImage imageNamed:@"File-V-Urgent.png"];
        }else{
            cell.tagView.image = [UIImage imageNamed:@"File-Common.png"];
        }
//    }
    
    UIImage *thumbImage = [UIImage imageWithData:[object valueForKey:kFileThumbImage]];
    if (!thumbImage) {
        cell.pdfThumbView.image = [UIImage imageNamed:@"File-Download.png"];
        cell.dateLabel.hidden = YES;
        cell.missiveType.hidden = YES;
        cell.isDownLoading = YES;
        //是否还在下载的标志
        IsDowning = YES;
        if (!cell.isDownLoading) {
            cell.pdfThumbView.layer.borderWidth = 0.0f;
        }
    }else{
        cell.pdfThumbView.image = thumbImage;
        //
        cell.isDownLoading = NO;
        // 文件下载完成，框选状态取消
        cell.pdfThumbView.layer.borderWidth = 0.0f;
        cell.pValue.hidden = YES;
        cell.pView.hidden = YES;
        //是否还在下载的标志
        IsDowning = NO;
        
        // 8.zzz表示时区，zzz可以删除，这样返回的日期字符将不包含时区信息。
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
        cell.dateLabel.text = [dateFormatter stringFromDate:[object valueForKey:kTaskStartTime]];
        cell.dateLabel.hidden = NO;
        // 显示公文类型
        cell.missiveType.hidden = NO;
        NSString *type = [object valueForKey:@"missiveType"];
        if ([type isEqualToString:@"missiveReceive"]) {
            cell.missiveType.text = @"收   文";
            cell.missiveType.textColor = kReceiveColor;
            cell.missiveType.layer.borderColor = [kReceiveColor CGColor];
        }else if ([type isEqualToString:@"missivePublish"]){
            cell.missiveType.text = @"发   文";
            cell.missiveType.textColor = kPublishColor;
            cell.missiveType.layer.borderColor = [kPublishColor CGColor];
        }else if ([type isEqualToString:@"missiveSign"]){
            cell.missiveType.text = @"签   报";
            cell.missiveType.textColor = kSignColor;
            cell.missiveType.layer.borderColor = [kSignColor CGColor];
        }else if ([type isEqualToString:@"faxCablePublish"]){
            cell.missiveType.text = @"传   真";
        }else{
            cell.missiveType.text = @"";
        }
    }
    return cell;
}
#pragma mark - UICollectionView Delegate methods
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    


        OAPDFCell *cell = (OAPDFCell *)[collectionView cellForItemAtIndexPath:indexPath];
    if(cell.isDownLoading){
        
              NSString *text = cell.titleLabel.text;
        NSLog(@"gopngwenzhengzai xiazaizhong");
      
        [OATools showAlertTitle:[NSString stringWithFormat:@"公文：%@",text] message:@"正在下载中，请稍等..."];
    }else
    
         {
   
    // 非编辑状态，执行；编辑状态，不执行；
    if ([_editState isEqualToNumber:@1]) {
        OAPDFCell *cell = (OAPDFCell *)[collectionView cellForItemAtIndexPath:indexPath];
        ReaderDocument *object = (ReaderDocument *)[self.fetchedResultsController objectAtIndexPath:indexPath];

        // 判断当前文件是否已下载；
        if(object.fileURL && [object fileExistsAndValid:object.fileURL])
        {
            ReaderViewController *readerVC = [[ReaderViewController alloc] initWithReaderDocument:object];
            readerVC.delegate = self;
            readerVC.modalPresentationStyle = UIModalPresentationFullScreen;
            readerVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

            [self presentViewController:readerVC animated:YES completion:^{
                // 阅后即删除操作
                _selectedIndexPath = indexPath;
                _openedDocument = object;
            }];
        }else{
            if (!cell.isDownLoading) {
                cell.isDownLoading = YES;
                NSString *info = [NSString stringWithFormat:@"Error:File-%@-（Un download）taped，begining download. In OADetailViewController.m",object.fileName];
                [OATools newLogWithInfo:info time:[OATools newStringDate] type:kLogErrorType];
                
                // 下载
                dispatch_async(dispatch_get_global_queue(0, 0), ^{
                    [self downFileWithUrl:object.fileLink readerDocument:object];
                });
            }else{
                [OATools showAlertTitle:[NSString stringWithFormat:@"公文:%@",cell.titleLabel.text] message:@"正在下载..."];
            }
        }
    }else{
        // 取消编辑状态
        [self editItemClicked];
    }
         }
   
}


- (void)longPressGesture:(id)sender
{
    UILongPressGestureRecognizer *longPress = sender;
    if (longPress.state == UIGestureRecognizerStateBegan)
    {
        CGPoint point = [longPress locationInView:self.collectionView];
        OAPDFCell *cell = (OAPDFCell *)[self.collectionView cellForItemAtIndexPath:[self.collectionView indexPathForItemAtPoint:point]];
        cell.deleteBtn.hidden = NO;
    }
}

#pragma mark - UICollectionViewLayout
- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *attr = [self.collectionView layoutAttributesForItemAtIndexPath:indexPath];
    
    attr.transform = CGAffineTransformRotate(CGAffineTransformMakeScale(0.2, 0.2), M_PI);
    attr.center    = CGPointMake(CGRectGetMidX(self.collectionView.bounds), CGRectGetMaxY(self.collectionView.bounds));
    
    return attr;
}

- (UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *attributes = [self.collectionView layoutAttributesForItemAtIndexPath:indexPath];
    return attributes;
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:kOAPDFDocument inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:30];
    
    // Set the predicate @"age < 60 && name LIKE '*五'"];
//    NSUserDefaults *userDefaultes = [NSUserDefaults standardUserDefaults];
//    NSString *userName = [userDefaultes objectForKey:kUserName];
//    NSString *password = [userDefaultes objectForKey:kPassword];
//    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"userName = %@ && password = %@",userName,password]];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey:kFileTag ascending:YES];
    NSSortDescriptor *sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey:kTaskStartTime ascending:NO];
//    NSArray *sortDescriptors = @[sortDescriptor2];
    NSArray *sortDescriptors = @[sortDescriptor1,sortDescriptor2];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:kFileTag cacheName:@"Home"];
//    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Home"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
	    MyLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return _fetchedResultsController;
}

//- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
//           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
//{
//    NSMutableDictionary *change = [NSMutableDictionary new];
//    
//    switch((NSUInteger)type) {
//        case NSFetchedResultsChangeInsert:
//            change[@(type)] = @(sectionIndex);
//            break;
//        case NSFetchedResultsChangeDelete:
//            change[@(type)] = @(sectionIndex);
//            break;
//    }
//    MyLog(@"didChangeSection Section: %li Type: %@", (unsigned long)sectionIndex, type == NSFetchedResultsChangeDelete ? @"Delete" : @"Insert");
//    
//    [_sectionChanges addObject:change];
//}
//
//- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
//       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
//      newIndexPath:(NSIndexPath *)newIndexPath
//{
//    
//    NSMutableDictionary *change = [NSMutableDictionary new];
//    switch(type)
//    {
//        case NSFetchedResultsChangeInsert:
//            change[@(type)] = newIndexPath;
//            break;
//        case NSFetchedResultsChangeDelete:
//            change[@(type)] = indexPath;
//            break;
//        case NSFetchedResultsChangeUpdate:
//            change[@(type)] = indexPath;
//            break;
//        case NSFetchedResultsChangeMove:
//            change[@(type)] = @[indexPath, newIndexPath];
//            break;
//    }
//    
//    MyLog(@"didChangeObject IndexPath: %li,%li Type: %@", (long)indexPath.section,(long)indexPath.row, type == NSFetchedResultsChangeDelete ? @"Delete" : @"Other");
//    
//    [_objectChanges addObject:change];
//}
//
//- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
//{
//    MyLog(@"controllerDidChangeContent sectionChanges: %li", (unsigned long)[_sectionChanges count]);
//    
//    [self.collectionView performBatchUpdates:^{
//        
//        if ([_sectionChanges count] > 0)
//        {
//            MyLog(@"BEFORE performBatchUpdates for Sections");
//            
//            //        @try {
//            
//            
//            
//            for (NSDictionary *change in _sectionChanges)
//            {
//                [change enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id obj, BOOL *stop) {
//                    
//                    NSFetchedResultsChangeType type = [key unsignedIntegerValue];
//                    switch ((NSUInteger)type)
//                    {
//                        case NSFetchedResultsChangeInsert:
//                            [self.collectionView insertSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
//                            break;
//                        case NSFetchedResultsChangeDelete:
//                            MyLog(@"BEFORE deleteSections");
//                            NSUInteger toDeleteSection = [obj unsignedIntegerValue];
//                            [self.collectionView deleteSections:[NSIndexSet indexSetWithIndex:toDeleteSection]];
//                            MyLog(@"AFTER deleteSections");
//                            break;
//                        case NSFetchedResultsChangeUpdate:
//                            [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
//                            break;
//                    }
//                }];
//            }
//            
//            //        }
//            //        @catch (NSException *exception) {
//            //            MyLog(@"Exception caught");
//            //            //MyLog(@"Exception caught: %@", exception.description);
//            //            //[self.collectionView reloadData];
//            //        }
//            
//            MyLog(@"AFTER performBatchUpdates for Sections");
//        }
//        
//        
//        MyLog(@"controllerDidChangeContent objectChanges: %li sectionChanges: %li", (unsigned long)[_objectChanges count], (unsigned long)[_sectionChanges count]);
//        
//        if ([_objectChanges count] > 0) {
//            
//            MyLog(@"[_objectChanges count] > 0 && [_sectionChanges count] == 0)");
//            
//            //        if ([self shouldReloadCollectionViewToPreventKnownIssue] || self.collectionView.window == nil) {
//            //            // This is to prevent a bug in UICollectionView from occurring.
//            //            // The bug presents itself when inserting the first object or deleting the last object in a collection view.
//            //            // http://stackoverflow.com/questions/12611292/uicollectionview-assertion-failure
//            //            // This code should be removed once the bug has been fixed, it is tracked in OpenRadar
//            //            // http://openradar.appspot.com/12954582
//            //            [self.collectionView reloadData];
//            //
//            //            MyLog(@"CV reloadData");
//            //
//            //        } else {
//            
//            MyLog(@"BEGIN performBatchUpdates for Objects");
//            
//            [self.collectionView performBatchUpdates:^{
//                
//                for (NSDictionary *change in _objectChanges) {
//                    
//                    [change enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id obj, BOOL *stop) {
//                        
//                        NSFetchedResultsChangeType type = [key unsignedIntegerValue];
//                        switch (type)
//                        {
//                            case NSFetchedResultsChangeInsert:
//                                [self.collectionView insertItemsAtIndexPaths:@[obj]];
//                                break;
//                            case NSFetchedResultsChangeDelete:
//                                [self.collectionView deleteItemsAtIndexPaths:@[obj]];
//                                break;
//                            case NSFetchedResultsChangeUpdate:
//                                [self.collectionView reloadItemsAtIndexPaths:@[obj]];
//                                break;
//                            case NSFetchedResultsChangeMove:
//                                [self.collectionView moveItemAtIndexPath:obj[0] toIndexPath:obj[1]];
//                                break;
//                        } // switch
//                        
//                    }]; // enumerate blocks
//                    
//                } // for
//                
//            } completion:nil]; // performBatchUpdates
//        } // if objectchange
//        
//    } completion:^(BOOL finished){
//        MyLog(@"completion finished");
//    }];
//    
//    [_sectionChanges removeAllObjects];
//    [_objectChanges removeAllObjects];
//}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    __weak UICollectionView *collectionView = self.collectionView;
    switch (type) {
        case NSFetchedResultsChangeInsert: {
            [blockOperation addExecutionBlock:^{
                [collectionView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]];
            }];
            break;
        }
            
        case NSFetchedResultsChangeDelete: {
            [blockOperation addExecutionBlock:^{
                if ([collectionView numberOfItemsInSection:sectionIndex] == 0) {
                    [collectionView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]];
                }
            }];
            break;
        }
            
        case NSFetchedResultsChangeUpdate: {
            [blockOperation addExecutionBlock:^{
                [collectionView reloadSections:[NSIndexSet indexSetWithIndex:sectionIndex]];
            }];
            break;
        }
            
        default:
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    __weak UICollectionView *collectionView = self.collectionView;
    switch (type) {
        case NSFetchedResultsChangeInsert: {
            if ([self.collectionView numberOfSections] > 0) {
                if ([self.collectionView numberOfItemsInSection:indexPath.section] == 0) {
                    shouldReloadCollectionView = YES;
                } else {
                    [blockOperation addExecutionBlock:^{
                        [collectionView insertItemsAtIndexPaths:@[newIndexPath]];
                    }];
                }
            } else {
                shouldReloadCollectionView = YES;
            }
            break;
        }
            
        case NSFetchedResultsChangeDelete: {
            if ([self.collectionView numberOfSections] > 0){
            if ([self.collectionView numberOfItemsInSection:indexPath.section] == 1) {
                shouldReloadCollectionView = YES;
            } else {
                [blockOperation addExecutionBlock:^{
                    [collectionView deleteItemsAtIndexPaths:@[indexPath]];
                }];
            }
            }
            break;
        }
            
        case NSFetchedResultsChangeUpdate: {
            [blockOperation addExecutionBlock:^{
                [collectionView reloadItemsAtIndexPaths:@[indexPath]];
            }];
            break;
        }
            
        case NSFetchedResultsChangeMove: {
            [blockOperation addExecutionBlock:^{
                [collectionView moveItemAtIndexPath:indexPath toIndexPath:newIndexPath];
            }];
            break;
        }
            
        default:
            break;
    }
}


- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    shouldReloadCollectionView = NO;
    blockOperation = [NSBlockOperation new];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    // Checks if we should reload the collection view to fix a bug @ http://openradar.appspot.com/12954582
//    if (shouldReloadCollectionView) {
//        [self.collectionView reloadData];
//    } else {
//        [self.collectionView performBatchUpdates:^{
//            [blockOperation start];
//        } completion:^(BOOL finished) {
//        }];
//    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.collectionView reloadData];
    });
}

#pragma mark - OAPDFCellDown and Delete

- (void)pdfCellDelete:(UIButton *)sender
{
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:(OAPDFCell *)sender.superview.superview];
    _deletedDocument  = (ReaderDocument *)[self.fetchedResultsController objectAtIndexPath:indexPath];;
    _selectedIndexPath= indexPath;
    NSString *pdfName = [[_deletedDocument valueForKey:kFileName] stringByDeletingPathExtension];
    
    NSString *message = [NSString stringWithFormat:@"删除文件:%@",pdfName];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提醒" message:message delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    [alertView show];
}

- (void)documentDeleteInMOCWithTheDeleteDocument:(ReaderDocument *)reader
{
    [ReaderDocument deleteInMOC:self.managedObjectContext object:reader];
}

#pragma mark - ReaderViewControllerDelegate methods

- (void)dismissReaderViewController:(ReaderViewController *)viewController withDocument:(ReaderDocument *)document withTag:(NSNumber *)tag animated:(BOOL)animated
{
    [self dismissViewControllerAnimated:animated completion:^{
        //4. 正在打开的文件为空；
        document.fileOpen = @0;
        _openedDocument = nil;
        // tag = 0 表示没有对文件进行签发，主动（点击退出按钮）退出到主页面
        if ([tag isEqualToNumber:@0]) {
            // 1. 更新文件标签
            // fileTag = @1 标签初始化
            // fileTag = @2 标签 文件已签发
            
            // 刷新数据
            [self getUnDoMission];
        }else if([tag isEqualToNumber:@1]){
            // 3. 取消该公文本地通知
            [self cancelNotificationWithObject:document.fileName andKey:document.guid];
            
//            [self performSelector:@selector(fileToDelete) withObject:nil afterDelay:3.0];
            
        }else{
            [self presentLoginView];
        }
    }];
}

#pragma mark - OALoginViewControllerDelegate methods
- (void)dismissOALoginViewController:(OALoginViewController *)viewController
{
    _loginToSplitVC = YES;
    _loginState     = YES;
    [self initAfterLogin];
    [self dismissViewControllerAnimated:NO completion:^{
    }];
}

#pragma mark - UIAlertView Delegate 右顶角删除按钮提示
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0: // 取消
            break;
        case 1: // 确认
        {
            if ([_deletedDocument.fileTag isEqualToNumber:@1]) {
                [self cancelNotificationWithObject:_deletedDocument.fileName andKey:_deletedDocument.guid];
            }
            // 删除公文
            [self deletePDFWithObject:_deletedDocument];
            // 当一个文件被删除成功后，取消编辑（删除）模式
//            [self editItemClicked];
        }
            break;
       
        default:
            break;
    }
}

#pragma mark - MasterToDetail Delegate
- (void)exitToLoginVC
{
    [self presentLoginView];
}

-(void)cellDoneMissiveWithNSDictory:(NSDictionary *)missive
{
//    NSLog(@"你好%@",missive);
//    NSString *missiveTitle = [missive valueForKey:kMissiveTitle];
//    NSLog(@"%@",missiveTitle);

    NSString *predicate = [NSString stringWithFormat:@"fileId = '%@'",[missive valueForKey:kTaskId]];
    NSString *fileName  = [NSString stringWithFormat:@"%@.pdf",[missive valueForKey:kMissiveTitle]];
    if ([self searchObjectsWithPredicate:predicate withEntityName:kOAPDFDocument]) {
        ReaderDocument *object  = [ReaderDocument initOneInMOC:self.managedObjectContext name:fileName tag:@2];
        NSLog(@"%@",object);
        NSNumberFormatter* numberFormatter = [[NSNumberFormatter alloc] init];
        NSNumber *file = [missive valueForKey:kTaskId];
        NSString *fileid = [numberFormatter stringFromNumber:file];
        object.fileId           = fileid;
        object.missiveType      = [[missive valueForKey:kMissiveAddr] componentsSeparatedByString:@"/"][2];
        object.urgencyLevel     = [missive valueForKey:kUrgentLevel];
        object.taskName         = [missive valueForKey:kTaskName];
        object.fileLink         = [NSString stringWithFormat:@"%@%@",kBaseURL,[missive valueForKey:kMissiveAddr]];
        NSString *taskStartT = [missive valueForKey:kMissiveDoneTime];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSDate *taskstartTime = [dateFormatter dateFromString:taskStartT];
        object.taskStartTime    = taskstartTime;
        assert(object != nil); // Object insert failure should never happen
        
        [self hideNilItemView];
        
        [self.collectionView reloadData];
        
        // 3.公文后台下载文件
        NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:object];
        OAPDFCell *cell = (OAPDFCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        cell.isDownLoading = YES;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self downFileWithUrl:object.fileLink readerDocument:object];
        });
    }else{
        [OATools showAlertTitle:@"提示" message:@"您选择的公文已在列表中！"];
    }


}

- (void)downloadDoneMissiveWithObject:(NSManagedObject *)missive
{
    
    NSString *predicate = [NSString stringWithFormat:@"fileId = '%@'",[missive valueForKey:kTaskId]];
    NSString *fileName  = [NSString stringWithFormat:@"%@.pdf",[missive valueForKey:kMissiveTitle]];
    if ([self searchObjectsWithPredicate:predicate withEntityName:kOAPDFDocument]) {
        ReaderDocument *object  = [ReaderDocument initOneInMOC:self.managedObjectContext name:fileName tag:@2];
        object.fileId           = [missive valueForKey:kTaskId];
        object.missiveType      = [[missive valueForKey:kMissiveAddr] componentsSeparatedByString:@"/"][2];
        object.urgencyLevel     = [missive valueForKey:kUrgentLevel];
        object.taskName         = [missive valueForKey:kTaskName];
        object.fileLink         = [NSString stringWithFormat:@"%@%@",kBaseURL,[missive valueForKey:kMissiveAddr]];
        object.taskStartTime    = [missive valueForKey:kMissiveDoneTime];
        assert(object != nil); // Object insert failure should never happen
        
        [self hideNilItemView];
        
        [self.collectionView reloadData];
        
        // 3.公文后台下载文件
        NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:object];
        OAPDFCell *cell = (OAPDFCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        cell.isDownLoading = YES;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self downFileWithUrl:object.fileLink readerDocument:object];
        });
    }else{
        [OATools showAlertTitle:@"提示" message:@"您选择的公文已在列表中！"];
    }
}

#pragma mark - NSKeyValueObserving methods
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"collectionViewLayout"]) {
        // reset values
        
        [self.collectionView reloadData];
    }
}

#pragma mark - MJRefresh
- (void)addHeader
{
    __unsafe_unretained typeof(self) vc = self;
    // 添加下拉刷新头部控件
    [self.collectionView addHeaderWithCallback:^{
        // 进入刷新状态就会回调这个Block
        [vc getUnDoMission];
        if ([vc.collectionView numberOfSections] == 0) {
            [vc showNilItemView];
        }else{
            [vc hideNilItemView];
        }
        
        // 模拟延迟加载数据，因此2秒后才调用（真实开发中，可以移除这段gcd代码）
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [vc.collectionView reloadData];
            // 结束刷新
            [vc.collectionView headerEndRefreshing];
        });
    } dateKey:@"collection"];
    // dateKey用于存储刷新时间，也可以不传值，可以保证不同界面拥有不同的刷新时间
    [self.collectionView headerBeginRefreshing];
}

- (void)addFooter
{
    __unsafe_unretained typeof(self) vc = self;
    // 添加上拉刷新尾部控件
    [self.collectionView addFooterWithCallback:^{
        // 进入刷新状态就会回调这个Block
        [vc getUnDoMission];
        
        if ([vc.collectionView numberOfSections] == 0) {
            [vc showNilItemView];
        }else{
            [vc hideNilItemView];
        }
        
        // 模拟延迟加载数据，因此2秒后才调用（真实开发中，可以移除这段gcd代码）
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [vc.collectionView reloadData];
            // 结束刷新
            [vc.collectionView footerEndRefreshing];
        });
    }];
}

#pragma mark - DownLoad pdf with url

- (void)downFileWithUrl:(NSString *)linkUrl readerDocument:(ReaderDocument *)readerPDF
{
    // 0.判断网络是否连接
    if ([self connected]) {
        // 1.设置对应Cell的下载状态
        __block ReaderDocument *object = readerPDF;
        dispatch_async(dispatch_get_main_queue(), ^{
            // 1.设置对应Cell的下载状态
            NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:object];
            OAPDFCell *cell = (OAPDFCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
            cell.isDownLoading = YES;
            cell.pView.hidden  = NO;
            cell.pValue.hidden = NO;
        });
        
        // 2.设置下载请求
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:linkUrl]];
        
        NSString *cacheDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *filePath = [cacheDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.pdf",object.fileId]];
        
        // 3.检查文件是否已经下载了一部分
        unsigned long long downloadedBytes = 0;
        if ([[[NSFileManager alloc]init] fileExistsAtPath:filePath]) {
            //获取已下载的文件长度
            downloadedBytes = [self fileSizeForPath:filePath];
            if (downloadedBytes > 0) {
                NSMutableURLRequest *mutableURLRequest = [request mutableCopy];
                NSString *requestRange = [NSString stringWithFormat:@"bytes=%llu-", downloadedBytes];
                [mutableURLRequest setValue:requestRange forHTTPHeaderField:@"Range"];
                request = mutableURLRequest;
            }
        }
        // 4.不使用缓存，避免断点续传出现问题
        [[NSURLCache sharedURLCache] removeCachedResponseForRequest:request];
        MyLog(@"PDF:%@,Downloading...",object.fileName);
        
        // 5.下载请求
        AFURLConnectionOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        //下载路径
        operation.outputStream = [NSOutputStream outputStreamToFileAtPath:filePath append:YES];
        //下载进度回调
        [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:object];
                OAPDFCell *cell = (OAPDFCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
                float i = (float)totalBytesRead / totalBytesExpectedToRead;
                NSLog(@"%f",i);
                cell.pView.hidden = NO;
                cell.pValue.hidden = NO;
                cell.pView.progress = (float)totalBytesRead / totalBytesExpectedToRead;
                cell.pValue.text = [NSString stringWithFormat:@"%2.0f%%",((float)totalBytesRead / totalBytesExpectedToRead) * 100];
            });
        }];
        //成功和失败回调
        [operation setCompletionBlock:^{
            // 1. 隐藏Cell的view
            NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:object];
            OAPDFCell *cell = (OAPDFCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
            cell.pView.hidden = YES;
            cell.pValue.hidden = YES;
            cell.pValue.text = @"0%";
            cell.isDownLoading = NO;
            // 2.文件下载成功
            NSString *existFileURL = [cacheDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.pdf",object.fileId]];
            if ([object fileExistsAndValid:existFileURL]) {
                MyLog(@"PDF:%@,下载成功...",object.fileName);
                // 3. 补全－公文（ReaderDocument）信息
                [ReaderDocument complementInMOC:self.managedObjectContext object:object path:cacheDirectory];
                // 4. 本地推送新公文信息
                if ([object.fileTag isEqualToNumber:@1]) {
                    NSLog(@"推送");
//                    [self createNotificationWithObject:object.fileName andKey:object.guid];
                }
            }else{
                //
                cell.pValue.hidden = NO;
                cell.pValue.text = @"公文不存在!";
                
                NSString *info = [NSString stringWithFormat:@"Error:Download file,File not exist Error, in OADetailViewController.m%@",linkUrl];
                [OATools newLogWithInfo:info time:[OATools newStringDate] type:kLogErrorType];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.collectionView reloadData];
            });
        }];
        [operation start];
    }else{
        NSString *info = [NSString stringWithFormat:@"Error:File is downloading，network interrupt Error.%@",linkUrl];
        [OATools newLogWithInfo:info time:[OATools newStringDate] type:kLogErrorType];
    }
}

//获取已下载的文件大小
- (unsigned long long)fileSizeForPath:(NSString *)path
{
    signed long long fileSize = 0;
    NSFileManager *fileManager = [NSFileManager new]; // default is not thread safe
    if ([fileManager fileExistsAtPath:path]) {
        NSError *error = nil;
        NSDictionary *fileDict = [fileManager attributesOfItemAtPath:path error:&error];
        if (!error && fileDict) {
            fileSize = [fileDict fileSize];
        }
    }
    return fileSize;
}

#pragma mark - Local Notification
- (void)createNotificationWithObject:(NSString *)objectName andKey:(NSString *)keyGUID
{
    // 创建一个本地推送
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    //设置10秒之后
    NSDate *pushDate = [NSDate dateWithTimeIntervalSinceNow:0.1];
    if (notification != nil) {
        // 设置推送时间
        notification.fireDate = pushDate;
        // 设置时区
        notification.timeZone = [NSTimeZone defaultTimeZone];
        // 设置重复间隔
        notification.repeatInterval = kCFCalendarUnitDay;
        // 推送声音
        notification.soundName = UILocalNotificationDefaultSoundName;
        // 推送内容
        notification.alertBody = [NSString stringWithFormat:@"您有新的公文：%@",objectName];
        // 推送时小图标的设置，
        notification.alertLaunchImage=[[NSBundle mainBundle] pathForResource:@"Icon-Small" ofType:@"png"];
        // 显示在icon上的红色圈中的数子
//        _badgeNumber++;
//        [UIApplication sharedApplication].applicationIconBadgeNumber = _badgeNumber;
        
        NSDictionary *info = [NSDictionary dictionaryWithObject:objectName forKey:keyGUID];
        notification.userInfo = info;
        // 添加推送到UIApplication
        UIApplication *app = [UIApplication sharedApplication];
        // 计划本地推送
        [app scheduleLocalNotification:notification];
        // 即时推送
//        [app presentLocalNotificationNow:notification];
    }
}

- (void)cancelNotificationWithObject:(NSString *)objectName andKey:(NSString *)keyGUID
{
    // 获得 UIApplication
    UIApplication *app = [UIApplication sharedApplication];
    //获取本地推送数组
    NSArray *localArray = [app scheduledLocalNotifications];
    for (UILocalNotification *localNotification in localArray) {
        NSDictionary *dict = localNotification.userInfo;
        NSString *inKey = [[dict objectForKey:keyGUID] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        if ([inKey isEqualToString:objectName]) {
            [app cancelLocalNotification:localNotification];
            break;
        }
    }
}

- (BOOL)existNotificationWithObject:(NSString *)objectName andKey:(NSString *)keyGUID
{
    // 获得UIApplication
    UIApplication *app = [UIApplication sharedApplication];
    // 获取本地推送数组
    NSArray *localArray = [app scheduledLocalNotifications];
    for (UILocalNotification *localNotification in localArray) {
        NSDictionary *dict = localNotification.userInfo;
        NSString *inKey = [[dict objectForKey:keyGUID] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        if ([inKey isEqualToString:objectName]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - HTTP request with AFNetwork

- (void)getUnDoMission
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *userName = [userDefaults objectForKey:kUserName];
    NSString *netConnect = [userDefaults objectForKey:kNetConnect];
    __block NSString *authorizationHeader = [userDefaults objectForKey:kAuthorizationHeader];
    // 用户名和密码非空和网络OK时，获取最新任务列表
    if (userName && [netConnect isEqualToString:@"OK"] && authorizationHeader) {
        NSString *serverURL = [[NSString stringWithFormat:@"%@%@",kTaskURL,userName] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];//转码成UTF-8  否则可能会出现错
        NSMutableArray *newMission = [NSMutableArray array];
        
        NSLog(@"未办公文%@",serverURL);
        
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager.requestSerializer setValue:authorizationHeader forHTTPHeaderField:@"Authorization"];
        [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"content-type"];
        manager.responseSerializer = [AFJSONResponseSerializer serializer];
//        [self judgeTheUrl:serverURL];
        [manager GET:serverURL parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            MyLog(@"getUnDoMission:%@",[OATools newStringDate]);
            if (responseObject == nil) {
                return ;
            }
            
            // 3 解析返回的JSON数据
            NSData *responseData = [NSJSONSerialization dataWithJSONObject:responseObject options:NSJSONWritingPrettyPrinted error:nil];
            NSDictionary *result = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:nil];
            // 获取未办公文到词典中，与最新公文列表对比，
            NSMutableDictionary *unReadDic = [NSMutableDictionary dictionary];
            NSArray *unReadArray = [ReaderDocument allInMOC:self.managedObjectContext withTag:@1];
            if ([unReadArray count] > 0) {
                [self hideNilItemView];
            }
            for (ReaderDocument *pdf in unReadArray) {
                if (pdf.taskInfo) {
                    NSDictionary *taskInfoDic = [NSJSONSerialization JSONObjectWithData:pdf.taskInfo options:NSJSONReadingMutableLeaves error:nil];
                    [unReadDic setObject:pdf forKey:[taskInfoDic objectForKey:@"id"]];
                }
                if (![self existNotificationWithObject:pdf.fileName andKey:pdf.guid]) {
                    NSLog(@"推送");
//                    [self createNotificationWithObject:pdf.fileName andKey:pdf.guid];
                }
            }
            
            for (int i = 0; i < [(NSArray *)result count]; i++)
            {
                // 1.判断文件中是否已存在该公文
                NSDictionary *taskInfoDic = (NSDictionary *)[(NSArray *)result objectAtIndex:i];
                NSString *isPadDealMissive = [taskInfoDic objectForKey:@"isPadDealMissive"];
                NSLog(@"%@",isPadDealMissive);
                NSString *missiveTitle = [taskInfoDic objectForKey:@"missiveTitle"];
                if (![unReadDic objectForKey:[taskInfoDic objectForKey:@"id"]] && [isPadDealMissive isEqualToString:@"yes"] && ![missiveTitle isKindOfClass:[NSNull class]] && ([missiveTitle length]>0))
                {
                    // 公文名非空，下载公文；
                    // 3.新建公文；
                    NSString *fileName = [NSString stringWithFormat:@"%@.pdf",missiveTitle];
                    ReaderDocument *object  = [ReaderDocument initOneInMOC:self.managedObjectContext name:fileName tag:@1];
                    assert(object != nil); // Object insert failure should never happen
                    object.taskInfo         = [NSJSONSerialization dataWithJSONObject:taskInfoDic options:NSJSONWritingPrettyPrinted error:nil];
                    object.fileLink         = [NSString stringWithFormat:@"%@download/pdf/%@/%@/%@.pdf",kBaseURL,[taskInfoDic objectForKey:@"missiveType"],[taskInfoDic objectForKey:@"processInstanceId"],[taskInfoDic objectForKey:@"lastTaskId"]];
                    object.fileId           = [NSString stringWithFormat:@"%@",[taskInfoDic objectForKey:@"id"]];
                    object.urgencyLevel     = [taskInfoDic objectForKey:@"urgencyLevel"];
                    object.missiveType      = [taskInfoDic objectForKey:@"missiveType"];
                    object.taskName         = [taskInfoDic objectForKey:@"name"];
                    
                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                    NSDate *taskStartTime   = [dateFormatter dateFromString:[taskInfoDic valueForKey:kTaskStartTime]];
                    object.taskStartTime    = taskStartTime;
                    
                    [newMission addObject:object];
                    
                    // 有公文的时候，_nilItemsView隐藏
                    [self hideNilItemView];
                }else
                {
                    [unReadDic removeObjectForKey:[taskInfoDic objectForKey:@"id"]];
                }
            }
            // 本地未办公文 相比：最新公文列表单中，本地存在一些（PC端已处理但pad端未处理），本地未办公文改为已办公文
            if ([unReadDic count] > 0) {
                for (NSString *key in unReadDic) {
                    ReaderDocument *pdf = [unReadDic objectForKey:key];
                    // pdf.tag = 2 公文处理掉
                    [ReaderDocument refreashInMOC:self.managedObjectContext object:pdf];
                    // 取消该本地通知
                    [self cancelNotificationWithObject:pdf.fileName andKey:pdf.guid];
                    //
                    [self getDoneMissionWithPageSize:15 pageNum:1];
                }
            }
            
            [self.collectionView reloadData];
            if ([newMission count] > 0) {
                for (ReaderDocument *object in newMission) {
                    // 3.公文后台下载文件
                    dispatch_async(dispatch_get_global_queue(0, 0), ^{
                        [self downFileWithUrl:object.fileLink readerDocument:object];
                    });
                }
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSString *info = [NSString stringWithFormat:@"Error:Get the new File failer Error.%@",error.description];
            [OATools newLogWithInfo:info time:[OATools newStringDate] type:kLogErrorType];
            
            NSString *errorFailingURLKey = [[error.userInfo objectForKey:@"NSErrorFailingURLKey"] absoluteString];
            NSRange range = [errorFailingURLKey rangeOfString:@"login"];
            if (range.length > 0) {
                if (authorizationHeader) {
                    [OATools showAlertTitle:@"提醒" message:@"用户验证信息已过期，请重新登录。"];
                }else{
                    [OATools showAlertTitle:@"提醒" message:@"首次登陆，请输入用户名和密码登录。"];
                }
                
                //将上述数据全部存储到NSUserDefaults中
                NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                [userDefaults removeObjectForKey:kAuthorizationHeader];
                [userDefaults synchronize];
                
                NSString *info = [NSString stringWithFormat:@"Error:User Authoration dated! Prease reLogin.%@",error.description];
                [OATools newLogWithInfo:info time:[OATools newStringDate] type:kLogErrorType];
            }
        }];
    }
}

- (void)getDoneMission
{
    if (_loginState) {
        [self getDoneMissionWithPageSize:10 pageNum:1];
    }
}


- (void)getDoneMissionWithPageSize:(int)pageSize pageNum:(int)pageNum
{
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *userName = [userDefaults objectForKey:kUserName];
    NSString *netConnect = [userDefaults objectForKey:kNetConnect];
    __block NSString *authorizationHeader = [userDefaults objectForKey:kAuthorizationHeader];
    // 用户名和密码非空和网络OK时，获取最新任务列表
    if (userName && [netConnect isEqualToString:@"OK"] && authorizationHeader) {
        NSString *serverURL = [[NSString stringWithFormat:@"%@api/ipad/getDoneMissive/%@/%d/%d",kBaseURL,userName,pageSize,pageNum] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];//转码成UTF-8  否则可能会出现错
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
            for (NSDictionary *dic in result) {
                [self.masterDelegate insertNewDoneMissionWithObject:dic];
            }
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSString *info = [NSString stringWithFormat:@"Error:Get the newest File Failer Error.%@",error.description];
            [OATools newLogWithInfo:info time:[OATools newStringDate] type:kLogErrorType];
        }];
    }
}

#pragma mark - Notification for AFNetworkingOperationDidFinishNotification && UIApplicationDidEnterBackgroundNotification
- (void)addNetworkObserver
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(HTTPOperationDidFinish:)
                                                 name:AFNetworkingOperationDidFinishNotification
                                               object:nil];
}

- (void)HTTPOperationDidFinish:(NSNotification *)notification
{
    static NSError *oldError = nil;
    AFHTTPRequestOperation *operation = (AFHTTPRequestOperation *)[notification object];
    if (![operation isKindOfClass:[AFHTTPRequestOperation class]]) {
        oldError = nil;
        return;
    }
    if (operation.error != oldError && !oldError) {
        oldError = operation.error;
        [OATools showAlertTitle:@"服务器连接状态：" message:@"已断开"];
    }
}

- (void)addBecomeActiveObserver
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)didEnterBackground
{
    _loginToSplitVC = NO;
}

- (void)didBecomeActive
{
    if (!_loginToSplitVC) {
        [self presentLoginView];
    }
}

#pragma mark - No Document Show nilItemView
- (void)showNilItemView
{
    // 有公文的时候，_nilItemsView隐藏
    if (!_nilItemsView.superview) {
        [self.collectionView addSubview:_nilItemsView];
    }
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}

- (void)hideNilItemView
{
    // 没有公文的时候，_nilItemsView显示
    if (_nilItemsView.superview) {
        [_nilItemsView removeFromSuperview];
    }
}

@end
