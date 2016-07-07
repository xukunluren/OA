//
//  OAMasterViewController.h
//  OAOffice
//
//  Created by admin on 14-7-24.
//  Copyright (c) 2014年 DigitalOcean. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OADetailViewController;

#import <CoreData/CoreData.h>

@protocol MasterToDetailDelegate <NSObject>

- (void)exitToLoginVC;
- (void)downloadDoneMissiveWithObject:(NSObject *)missive;
- (void)cellDoneMissiveWithNSDictory:(NSDictionary *)missive;

@end

@protocol MasterToSearchDelegate <NSObject>

- (void)searchWithText:(NSString *)text;

@end


@interface OAMasterViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) OADetailViewController *detailViewController;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (weak,   nonatomic) id<MasterToDetailDelegate> masterToDeatilDelegate;
@property (weak,   nonatomic) id<MasterToSearchDelegate> masterToSearchDelegate;

@end
