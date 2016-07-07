//
//  DocumentFolder.h
//  OAOffice
//
//  Created by admin on 14-8-5.
//  Copyright (c) 2014年 DigitalOcean. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ReaderDocument;

typedef enum
{
	DocumentFolderTypeUser = 0,
	DocumentFolderTypeDefault = 1,
	DocumentFolderTypeRecent = 2,
    DocumentFolderTypeSamples = 3
}	DocumentFolderType;

@interface DocumentFolder : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSSet *documents;
@property (nonatomic, assign, readwrite) BOOL isChecked;

+ (NSArray *)allInMOC:(NSManagedObjectContext *)inMOC;
+ (BOOL)existsInMOC:(NSManagedObjectContext *)inMOC name:(NSString *)string;
+ (BOOL)existsInMOC:(NSManagedObjectContext *)inMOC type:(DocumentFolderType)kind;
+ (DocumentFolder *)folderInMOC:(NSManagedObjectContext *)inMOC type:(DocumentFolderType)kind;
+ (DocumentFolder *)insertInMOC:(NSManagedObjectContext *)inMOC name:(NSString *)string type:(DocumentFolderType)kind;
+ (void)renameInMOC:(NSManagedObjectContext *)inMOC objectID:(NSManagedObjectID *)objectID name:(NSString *)string;
+ (void)deleteInMOC:(NSManagedObjectContext *)inMOC objectID:(NSManagedObjectID *)objectID;

extern NSString *const DocumentFolderAddedNotification;
extern NSString *const DocumentFolderRenamedNotification;
extern NSString *const DocumentFolderDeletedNotification;
extern NSString *const DocumentFolderNotificationObjectID;
extern NSString *const DocumentFoldersDeletedNotification;

@end

@interface DocumentFolder (CoreDataGeneratedAccessors)

- (void)addDocumentsObject:(ReaderDocument *)value;
- (void)removeDocumentsObject:(ReaderDocument *)value;
- (void)addDocuments:(NSSet *)value;
- (void)removeDocuments:(NSSet *)value;

@end
