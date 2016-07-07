//
//  OASearchResultVC.m
//  OAOffice
//
//  Created by admin on 14/12/23.
//  Copyright (c) 2014年 DigitalOcean. All rights reserved.
//

#import "OASearchResultVC.h"
#import "PinYin4Objc.h"
#import "OAUser.h"

@interface OASearchResultVC ()
{
    NSMutableArray *_resultUsers; // 放着所有搜索到的用户
}
@end

@implementation OASearchResultVC

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _resultUsers = [NSMutableArray array];
}

- (void)setSearchText:(NSString *)searchText
{
    _searchText = searchText;
    
    // 1.清除之前的搜索结果
    [_resultUsers removeAllObjects];
    
    // 2.筛选城市
    HanyuPinyinOutputFormat *fmt = [[HanyuPinyinOutputFormat alloc] init];
    fmt.caseType = CaseTypeUppercase;
    fmt.toneType = ToneTypeWithoutTone;
    fmt.vCharType = VCharTypeWithUUnicode;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *plistPath = [userDefaults objectForKey:kUserPlist];
    NSMutableArray *_userArray = [[NSMutableArray alloc] initWithContentsOfFile:plistPath];
    if ([_userArray count]<=0) {
        NSArray *key = [NSArray arrayWithObjects:@"id",@"name",@"userName",@"groupName", nil];
        NSDictionary *dic1 = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"1",@"刘刻福",@"liukefu",@"分局领导", nil] forKeys:key];
        NSDictionary *dic2 = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"2",@"周振华",@"zhouzhenhua",@"分局领导", nil] forKeys:key];
        NSDictionary *dic3 = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"3",@"苏诚",@"sucheng",@"分局领导", nil] forKeys:key];
        NSDictionary *dic4 = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"4",@"叶娜",@"yena",@"分局领导", nil] forKeys:key];
        
        _userArray = [NSMutableArray arrayWithObjects:dic1,dic2,dic3,dic4, nil];
    }
    [_userArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
//    }]

//    [_userArray enumerateKeysAndObjectsUsingBlock:^(NSString *key, OAUser *obj, BOOL *stop) {
        // bei#jing
        // beij
        
        // SHI#JIA#ZHUANG
        // 1.拼音
        NSString *pinyin = [PinyinHelper toHanyuPinyinStringWithNSString:[obj objectForKey:@"name"] withHanyuPinyinOutputFormat:fmt withNSString:@"#"];
        
        // 2.拼音首字母
        NSArray *words = [pinyin componentsSeparatedByString:@"#"];
        NSMutableString *pinyinHeader = [NSMutableString string];
        for (NSString *word in words) {
            [pinyinHeader appendString:[word substringToIndex:1]];
        }
        
        // 去掉所有的#
        pinyin = [pinyin stringByReplacingOccurrencesOfString:@"#" withString:@""];
        
        // 3.城市名中包含了搜索条件
        // 拼音中包含了搜索条件
        // 拼音首字母中包含了搜索条件
        if (([[obj objectForKey:@"name"] rangeOfString:searchText].length != 0) ||
            ([pinyin rangeOfString:searchText.uppercaseString].length != 0)||
            ([pinyinHeader rangeOfString:searchText.uppercaseString].length != 0))
        {
            // 说明城市名中包含了搜索条件
            [_resultUsers addObject:obj];
        }
    }];
    
    // 3.刷新表格
    [self.tableView reloadData];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [NSString stringWithFormat:@"共%lu个搜索结果", (unsigned long)_resultUsers.count];
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _resultUsers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    cell.selectionStyle         = UITableViewCellSelectionStyleDefault;
    cell.accessoryType  = UITableViewCellAccessoryCheckmark;
    cell.imageView.image = [UIImage imageNamed:@"User-Header"];
    cell.textLabel.text = [_resultUsers[indexPath.row] objectForKey:@"name"];
    cell.detailTextLabel.font   = [UIFont systemFontOfSize:14];
    cell.detailTextLabel.text = [_resultUsers[indexPath.row] objectForKey:@"groupName"];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.delegate selectedFromResult:[_resultUsers[indexPath.row] objectForKey:@"name"] with:[_resultUsers[indexPath.row] objectForKey:@"userName"]];
}

@end
