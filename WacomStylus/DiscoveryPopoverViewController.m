/*!--------------------------------------------------------------------------------------------------

 FILE NAME

 DisoveryPopoverViewController.m

 Abstract: implementation file for the discovery popover controller


 COPYRIGHT
 Copyright WACOM Technology, Inc. 2012-2014
 All rights reserved.

 --------------------––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––-––-----*/

#import "DiscoveryPopoverViewController.h"

@interface DiscoveryPopoverViewController ()

@end

@implementation DiscoveryPopoverViewController
{
	NSMutableArray * mDevices;
	UITableView * mDiscoveryTable;
}



////////////////////////////////////////////////////////////////////////////////

/// initializes the class with a nib, but mainly initializes the mDevices variable.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self)
	{
		mDevices = nil;
		// Custom initialization
	}
	return self;
}


////////////////////////////////////////////////////////////////////////////////

/// notification method once the view has loaded used to initialize and update the
/// discovery table.
- (void)viewDidLoad
{
	[super viewDidLoad];
	CGRect discoveryTableFrame = CGRectMake(0., 0., 280., 320.);
	[[self view] setFrame:discoveryTableFrame];
	if(mDiscoveryTable == nil)
	{
		mDiscoveryTable = [[UITableView alloc] initWithFrame:discoveryTableFrame style:UITableViewStylePlain];
		[mDiscoveryTable setDataSource:self];
		[mDiscoveryTable setDelegate:self];
	}
	[self.view addSubview:mDiscoveryTable];
	[mDiscoveryTable setEditing:NO];
	[mDiscoveryTable setBounces:NO];
}


////////////////////////////////////////////////////////////////////////////////

/// notification method used to get a list of the devices detected by the Wacom SDK and put them
/// into the table.
- (void) viewWillAppear:(BOOL)animated
{
	mDevices = [[[WacomManager getManager] getDevices] mutableCopy];
	if([mDevices count] == 0)
		[mDiscoveryTable setRowHeight:320.0];
	else
		[mDiscoveryTable setRowHeight:50.0];

	[self updateTable];
	[super viewWillAppear:animated];
}


////////////////////////////////////////////////////////////////////////////////

/// notification method used to stop device discovery and clear our the device list.
- (void) viewDidDisappear:(BOOL)animated
{
	[[WacomManager getManager] stopDeviceDiscovery];
	mDevices = nil;
	[super viewDidDisappear:animated];
}


////////////////////////////////////////////////////////////////////////////////

/// table data source delegate method to tell how many columns are in the table
/// there is only one.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}


////////////////////////////////////////////////////////////////////////////////

/// table data source method to retreive the contents of a specific cell.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(mDevices.count != 0)
	{
		WacomDevice * selectedDevice = mDevices[[indexPath indexAtPosition:1]];
		if([selectedDevice isCurrentlyConnected])
		{
			[[WacomManager getManager] deselectDevice:selectedDevice];
			[mDevices removeObjectAtIndex:[indexPath indexAtPosition:1]];
            [self.ePenDelegate ePenConnectedChangeState:YES];
		}
		else
        {
            [[WacomManager getManager] selectDevice:selectedDevice];
            [self.ePenDelegate ePenConnectedChangeState:NO];
        }
	}
}


////////////////////////////////////////////////////////////////////////////////

/// table data source method to retreive the contents of a specific cell.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (mDevices.count == 0)
	{
		[mDiscoveryTable setRowHeight:320.0];
		return 1; // Our Help message.
	}
	else
	{
		[mDiscoveryTable setRowHeight:50.0];
		return mDevices.count;
	}
}


////////////////////////////////////////////////////////////////////////////////

/// table data source method to retreive the contents of a specific cell.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell * cell = [[UITableViewCell alloc] init];

	if(mDevices.count == 0)
	{
//		[[cell textLabel] setLineBreakMode:NSLineBreakByWordWrapping];
//		[[cell textLabel] setText:@"连接提示：\n1、点击手中签字笔按钮\n2、选择签字笔"];
//		cell.textLabel.numberOfLines= 0;
        cell.imageView.image = [UIImage imageNamed:@"OATips-EPen"];
	}
	else
	{
		WacomDevice * selectedDevice = mDevices[[indexPath indexAtPosition:1]];
		[[cell textLabel] setText:[selectedDevice getName]];
		if([selectedDevice isCurrentlyConnected] == YES)
		{
            [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
            [self.ePenDelegate ePenConnectedChangeState:NO];
		}
	}
	return cell;
}


////////////////////////////////////////////////////////////////////////////////

/// method for updating the contents of the table view when requested
-(void) updateTable
{
	[mDiscoveryTable reloadData];
	[self.view setNeedsDisplay];

}


////////////////////////////////////////////////////////////////////////////////

/// a method for adding devices to the internal device list if it is not already there.
-(void)addDeviceToList:(WacomDevice *)device
{
	//if the device list has not been allocated return
	if(mDevices == nil)
		return;

	//if we are not in discovery mode return
	if(![[WacomManager getManager] isDiscoveryInProgress])
		return;

	//if we already have the device in our list return
	for(WacomDevice * listDevice in mDevices)
	{
		if([device getPeripheral] == [listDevice getPeripheral])
			return;
	}

	//add the device to our internal list
	[mDevices addObject:device];
}


////////////////////////////////////////////////////////////////////////////////

/// a method for adding a device to the device list, then invoking on the main thread
/// to have the UI update.
-(void)addDevice:(WacomDevice *)device
{
	[self addDeviceToList:device];
	[self performSelectorOnMainThread:@selector(updateTable)
								  withObject:nil
							  waitUntilDone:YES];

}


////////////////////////////////////////////////////////////////////////////////

/// a method for removing a device to the device list if it exists
-(void)removeDeviceFromList:(WacomDevice *)device
{

	// if the device list has been allocated
	if(mDevices == nil)
		return;

	//if the device is in the list remove it.
	for(WacomDevice * listedDevice in mDevices )
	{
		if([listedDevice getPeripheral] == [device getPeripheral])
			[mDevices removeObject:listedDevice];
	}

	return;
}


////////////////////////////////////////////////////////////////////////////////

/// a method for removing a device from the device list, then invoking on the main thread
/// to have the UI update.
-(void)removeDevice:(WacomDevice *)device
{
	[self removeDeviceFromList:device];
	[self performSelectorOnMainThread:@selector(updateTable)
								  withObject:nil
							  waitUntilDone:YES];
}


////////////////////////////////////////////////////////////////////////////////

/// add the device to the list if it is not already in it, then forces an update of
/// the devices table in the UI by calling the update method on the main thread.
-(void)updateDevices:(WacomDevice *)device
{
	[self addDeviceToList:device];
	[self performSelectorOnMainThread:@selector(updateTable)
								  withObject:nil
							  waitUntilDone:YES];
}


////////////////////////////////////////////////////////////////////////////////

/// notification method for when there is a low memory situation.
- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}


////////////////////////////////////////////////////////////////////////////////

/// for releaseing the table of discovered devices.
- (void)dealloc {
}
@end
