//
//  HandPositionTableViewController.m
//  WacomStylusDemoApp
//
//  Created by minion on 11/14/14.
//  Copyright (c) 2014 Wacom. All rights reserved.
//

#import "HandPositionTableViewController.h"

@interface HandPositionTableViewController ()

@property (retain) NSDictionary *handPositionList;
@property (retain) NSArray *handKeyList;


@end

@implementation HandPositionTableViewController
{
	UITableView * mHandPositionTable;
}

////////////////////////////////////////////////////////////////////////////////

-(id)init
{

	self = [super initWithNibName:nil bundle:nil];
		
	if(self)
	{
		self.handPositionList = [[NSDictionary alloc] initWithObjectsAndKeys:
											 [NSNumber numberWithInt:eh_Right], @"右手握笔－正常",
											 [NSNumber numberWithInt:eh_RightUpward], @"右手握笔－偏上",
											 [NSNumber numberWithInt:eh_RightDownward], @"右手握笔－偏下",
											 [NSNumber numberWithInt:eh_Left], @"左手握笔－正常",
											 [NSNumber numberWithInt:eh_LeftUpward], @"左手握笔－偏上",
											 [NSNumber numberWithInt:eh_LeftDownward], @"左手握笔－偏下",
											  nil];
//		self.handKeyList = [self.handPositionList allKeys];
        self.handKeyList = [NSArray arrayWithObjects:@"右手握笔－正常",@"右手握笔－偏上",@"右手握笔－偏下",@"左手握笔－正常",@"左手握笔－偏上",@"左手握笔－偏下", nil];
	}
	
	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	if(mHandPositionTable == nil)
	{
		CGRect positionTableFrame = CGRectMake(0., 0., 280., 320.);
		[[self view] setFrame:positionTableFrame];

		mHandPositionTable = [[UITableView alloc] initWithFrame:positionTableFrame style:UITableViewStylePlain];
		[mHandPositionTable setDataSource:self];
		[mHandPositionTable setDelegate:self];
	}
	[self.view addSubview:mHandPositionTable];
	[mHandPositionTable setEditing:NO];
	[mHandPositionTable setBounces:NO];

}

////////////////////////////////////////////////////////////////////////////////

- (void) viewWillAppear:(BOOL)animated
{
	
	[mHandPositionTable setRowHeight:50.0];
	
	[mHandPositionTable reloadData];
	[self.view setNeedsDisplay];
	
	[super viewWillAppear:animated];
}

////////////////////////////////////////////////////////////////////////////////

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

////////////////////////////////////////////////////////////////////////////////

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

////////////////////////////////////////////////////////////////////////////////

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
    return [self.handKeyList count];
}

////////////////////////////////////////////////////////////////////////////////

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	UITableViewCell * cell = [[UITableViewCell alloc] init];
	NSString *key = [self.handKeyList objectAtIndex:indexPath.row];
	
	 cell.textLabel.text = key;
	
	int handedness = [[self.handPositionList objectForKey:key] intValue];
	
	if(handedness == [[TouchManager GetTouchManager] getHandedness])
	{
		[tableView
		 selectRowAtIndexPath:indexPath
		 animated:TRUE
		 scrollPosition:UITableViewScrollPositionNone
		 ];
		
		[[tableView delegate]
		 tableView:tableView
		 didSelectRowAtIndexPath:indexPath
		 ];
		
	}
	
    return cell;
}

////////////////////////////////////////////////////////////////////////////////

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	
	NSString *key = [self.handKeyList objectAtIndex:indexPath.row];
	
	int handedness = [[self.handPositionList objectForKey:key] intValue];
	
	
	[[TouchManager GetTouchManager] setHandedness:handedness];
	
}

////////////////////////////////////////////////////////////////////////////////

/// for releasing the hand position table
- (void)dealloc
{
}

@end
