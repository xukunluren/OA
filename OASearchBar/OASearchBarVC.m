//
//  OASearchBarVC.m
//  OAOffice
//
//  Created by admin on 15/1/5.
//  Copyright (c) 2015年 DigitalOcean. All rights reserved.
//

#import "OASearchBarVC.h"
#import "OADoneMissiveCell.h"
#import "OAMasterViewController.h"

@interface OASearchBarVC ()<MasterToSearchDelegate>
{
    NSMutableArray *_resultDocuments;
}
@end

@implementation OASearchBarVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    _resultDocuments = [NSMutableArray array];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark - Table view data source
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [NSString stringWithFormat:@"共%lu个搜索结果", (unsigned long)_resultDocuments.count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return _resultDocuments.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    // Configure the cell...
    static NSString *cellIdentifier = @"OADoneMissiveCell";
    OADoneMissiveCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle]loadNibNamed:@"OADoneMissiveCell" owner:self options:nil];
        if ([[nib objectAtIndex:0] isKindOfClass:[OADoneMissiveCell class]]) {
            cell = [nib objectAtIndex:0];
        }
    }
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)configureCell:(OADoneMissiveCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    
    //////
    NSDictionary *object = [_resultDocuments objectAtIndex:indexPath.row];
    cell.missiveTitle.text = [object valueForKey:kMissiveTitle];
    cell.missiveTaskName.text = [object valueForKey:kTaskName];
    cell.missiveAddr = [object valueForKey:kMissiveAddr];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    cell.missiveDoneTime.text = [dateFormatter stringFromDate:[object valueForKey:kMissiveDoneTime]];
    
    NSString *type = [cell.missiveAddr componentsSeparatedByString:@"/"][2];
    cell.missiveType.clipsToBounds = YES;
    cell.missiveType.layer.cornerRadius = 5;
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
        cell.missiveType.text = @"传真电报";
    }
    [cell.missiveDownloadBtn addTarget:self action:@selector(cellMissiveFileDownload:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)cellMissiveFileDownload:(UIButton *)sender
{
    OADoneMissiveCell *downloadCell = (OADoneMissiveCell *)sender.superview.superview;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:downloadCell];
    NSDictionary *object = [_resultDocuments objectAtIndex:indexPath.row];
    [self.searchBarDelegate sendSearchBarResultWithDic:object];
}

#pragma mark - MasterToSearchDelegate
- (void)searchWithText:(NSString *)text
{
    [_resultDocuments removeAllObjects];
    NSString *netConnect = [[NSUserDefaults standardUserDefaults] objectForKey:kNetConnect];
    if ([netConnect isEqualToString:@"OK"]) {
        NSString *serverURL = [[NSString stringWithFormat:@"%@api/fullSearch/search",kBaseURL] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];//转码成UTF-8  否则可能会出现错
        NSLog(@"搜素结果%@",serverURL);
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager.requestSerializer setValue:[[NSUserDefaults standardUserDefaults] objectForKey:kAuthorizationHeader] forHTTPHeaderField:@"Authorization"];
        [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"content-type"];
        manager.responseSerializer = [AFJSONResponseSerializer serializer];
        
        [manager GET:serverURL parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if (responseObject == nil) {
                return ;
            }
            // 3 解析返回的JSON数据
            NSData *responseData = [NSJSONSerialization dataWithJSONObject:responseObject options:NSJSONWritingPrettyPrinted error:nil];
            NSDictionary *result = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:nil];
            for (NSDictionary *dic in result)
            {
                MyLog(@"Search Result:%@",dic);
                [_resultDocuments addObject:dic];
            }
            [self.tableView reloadData];
            MyLog(@"Search:%@",result);
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            MyLog(@"Search Error:%@",error.description);
        }];
    }
}

@end
