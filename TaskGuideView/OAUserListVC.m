//
//  OAUserListVC.m
//  OAOffice
//
//  Created by admin on 14/12/23.
//  Copyright (c) 2014年 DigitalOcean. All rights reserved.
//

#import "OAUserListVC.h"
#import "OASearchResultVC.h"
#import "OACover.h"
#import "OAUser.h"

#define kSearchH 44

@interface OAUserListVC () <UITableViewDataSource,UITableViewDelegate,UISearchBarDelegate,SearchResultSelectedDelegate>
{
    UITableView *_tableView;
    OACover *_cover;
    
    OASearchResultVC *_searchResult;
    UISearchBar *_searchBar;
    NSString *_selectedUser;
}
@end

@implementation OAUserListVC

@synthesize userArray = _userArray;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    // 0.初始化
    [self initNaviColor];
    [self initRightBtn];
    _selectedUser = nil;
    
    // 1.添加搜索框
    [self addSearchBar];
    
    // 2.添加TableView
    [self addTableView];
    
    // 3.加载数据
    [self loadUsersData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Nav Color
- (void)initNaviColor
{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.navigationController.navigationBar.barTintColor = kThemeColor;
    self.navigationController.toolbar.barTintColor = kThemeColor;
    self.navigationController.view.tintColor = UIColor.whiteColor;
    self.title = @"请先选择公文下步处理人员";
}

- (void)initRightBtn
{
    UIBarButtonItem *rightNavBtn = [[UIBarButtonItem alloc] initWithTitle:
                                    NSLocalizedString(@"确定", @"OK") style:UIBarButtonItemStyleBordered target:
                                    self action:@selector(selectUserOk)];
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlackTranslucent];
    [self.navigationItem setRightBarButtonItem:rightNavBtn];
}

- (void)selectUserOk
{
    if (_selectedUser) {
//        [self.delegate selectUser:_selectedUser];
        [self dismissViewControllerAnimated:YES completion:^{
            [self.delegate selectUser:_selectedUser];
        }];
    }else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提醒" message:@"请先选择下一步公文处理人员" delegate:self cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
        [alert show];
    }
}

#pragma mark - 添加搜索框
- (void)addSearchBar
{
    UISearchBar *search = [[UISearchBar alloc] init];
    search.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    search.frame = CGRectMake(0, kSearchH, self.view.frame.size.width, kSearchH);
    search.delegate = self;
    search.placeholder = @"请输入用户名或拼音";
    [self.view addSubview:search];
    _searchBar = search;
}

#pragma mark - 添加TableView

- (void)addTableView
{
    UITableView *tableView = [[UITableView alloc] init];
    CGFloat h = self.view.frame.size.height - kSearchH - kSearchH;
    tableView.frame = CGRectMake(0, kSearchH + kSearchH, self.view.frame.size.width, h);
    tableView.dataSource = self;
    tableView.delegate   = self;
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth |UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:tableView];
    _tableView = tableView;
}

#pragma mark - 加载数据
- (void)loadUsersData
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *plistPath = [userDefaults objectForKey:kUserPlist];
    _userArray = [[NSMutableArray alloc] initWithContentsOfFile:plistPath];
    if ([_userArray count]<=0) {
        NSArray *key = [NSArray arrayWithObjects:@"id",@"name",@"userName",@"groupName", nil];
        NSDictionary *dic1 = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"1",@"刘刻福",@"liukefu",@"分局领导", nil] forKeys:key];
        NSDictionary *dic2 = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"2",@"周振华",@"zhouzhenhua",@"分局领导", nil] forKeys:key];
        NSDictionary *dic3 = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"3",@"苏诚",@"sucheng",@"分局领导", nil] forKeys:key];
        NSDictionary *dic4 = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"4",@"叶娜",@"yena",@"分局领导", nil] forKeys:key];
        
        _userArray = [NSMutableArray arrayWithObjects:dic1,dic2,dic3,dic4, nil];
    }
}

#pragma mark - 搜索框代理方法
#pragma mark 监听搜索框的文字改变
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if (searchText.length == 0) {
        // 隐藏搜索界面
        [_searchResult.view removeFromSuperview];
    } else {
        // 显示搜索界面
        if (_searchResult == nil) {
            _searchResult = [[OASearchResultVC alloc] init];
            _searchResult.view.frame = _cover.frame;
            _searchResult.delegate = self;
            _searchResult.view.autoresizingMask = _cover.autoresizingMask;
            [self addChildViewController:_searchResult];
        }
        _searchResult.searchText = searchText;
        [self.view addSubview:_searchResult.view];
    }
}

#pragma mark 搜索框开始编辑（开始聚焦）
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    // 1.显示取消按钮
    [searchBar setShowsCancelButton:YES animated:YES];
    
    // 2.显示遮盖（蒙板）
    if (_cover == nil) {
        _cover = [OACover coverWithTarget:self action:@selector(coverClick)];
    }
    _cover.frame = _tableView.frame;
    [self.view addSubview:_cover];
    _cover.alpha = 0.0;
    [UIView animateWithDuration:0.3 animations:^{
        [_cover reset];
    }];
}

#pragma mark 当退出搜索框的键盘时（失去焦点）
- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [self coverClick];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self coverClick];
}


#pragma mark 监听点击遮盖
- (void)coverClick
{
    // 1.移除遮盖
    [UIView animateWithDuration:0.3 animations:^{
        _cover.alpha = 0.0;
    } completion:^(BOOL finished) {
        [_cover removeFromSuperview];
    }];
    
    // 2.隐藏取消按钮
    [_searchBar setShowsCancelButton:NO animated:YES];
    
    // 3.退出键盘
    [_searchBar resignFirstResponder];
}

#pragma mark - 数据源方法
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _userArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    cell.selectionStyle         = UITableViewCellSelectionStyleBlue;
    cell.accessoryType          = UITableViewCellAccessoryCheckmark;
    cell.imageView.image = [UIImage imageNamed:@"User-Header"];
    cell.textLabel.text         = [_userArray[indexPath.row] objectForKey:@"name"];
    cell.detailTextLabel.font   = [UIFont systemFontOfSize:14];
    cell.detailTextLabel.text   = [_userArray[indexPath.row] objectForKey:@"groupName"];
    
    return cell;
}

#pragma mark - tableView 代理方法
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _selectedUser = [_userArray[indexPath.row] objectForKey:@"userName"];
    self.title = [NSString stringWithFormat:@"您选择了:%@ 处理",[_userArray[indexPath.row] objectForKey:@"name"]];
}

#pragma mark - SearchResultDelegate
- (void)selectedFromResult:(NSString *)name with:(NSString *)userName
{
    _selectedUser = userName;
    self.title = [NSString stringWithFormat:@"您选择了:%@ 处理",name];
}

@end
