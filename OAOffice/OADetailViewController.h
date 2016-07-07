//
//  OADetailViewController.h
//  OAOffice
//
//  Created by admin on 14-7-24.
//  Copyright (c) 2014年 DigitalOcean. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@protocol RefreashMasterDoneMission <NSObject>

- (void)insertNewDoneMissionWithObject:(id)object;
- (void)refreashMasterTitleWithName:(NSString *)name;
- (void)refreashMasterTableView;
- (void)refreashMasterTableViewWithID:(NSString *)objectID;
//-(void)insertAllNewDoneMission:(id)object;
@end

@interface OADetailViewController : UIViewController <UISplitViewControllerDelegate ,UICollectionViewDataSource ,UICollectionViewDelegate ,NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) id detailItem;
@property (strong, nonatomic) UICollectionView *collectionView;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

//@property 

@property (weak,   nonatomic) id<RefreashMasterDoneMission> masterDelegate;

@end
