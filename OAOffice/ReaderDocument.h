//
//  ReaderDocument.h
//  OAOffice
//
//  Created by admin on 15/1/15.
//  Copyright (c) 2015年 DigitalOcean. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "AnnotationStore.h"

@class DocumentFolder;

@interface ReaderDocument : NSManagedObject

@property (nonatomic, retain) NSDate * fileDate;
@property (nonatomic, retain) NSString * fileId;
@property (nonatomic, retain) NSString * fileLink;
@property (nonatomic, retain) NSString * fileName;
@property (nonatomic, retain) NSString * filePath;
@property (nonatomic, retain) NSNumber * fileSize;
@property (nonatomic, retain) NSNumber * fileTag;
@property (nonatomic, retain) NSString * fileURL;
@property (nonatomic, retain) NSString * guid;
@property (nonatomic, retain) NSDate * lastOpen;
@property (nonatomic, retain) NSString * missiveType;
@property (nonatomic, retain) NSNumber * pageCount;
@property (nonatomic, retain) NSNumber * pageNumber;
@property (nonatomic, retain) NSString * password;
@property (nonatomic, retain) NSData * tagData;
@property (nonatomic, retain) NSData * taskInfo;
@property (nonatomic, retain) NSString * taskName;
@property (nonatomic, retain) NSDate * taskStartTime;
@property (nonatomic, retain) NSData * thumbImage;
@property (nonatomic, retain) NSString * urgencyLevel;
@property (nonatomic, retain) NSNumber * fileOpen;
@property (nonatomic, retain) DocumentFolder *folder;

@property (nonatomic, strong, readonly)  NSMutableIndexSet *bookmarks;
@property (nonatomic, assign, readwrite) BOOL isChecked;
@property (nonatomic, strong) NSMutableDictionary *imageDic;

@property (nonatomic, readonly) BOOL canEmail;
@property (nonatomic, readonly) BOOL canExport;
@property (nonatomic, readonly) BOOL canPrint;


+ (NSArray *)allInMOC:(NSManagedObjectContext *)inMOC;
+ (NSArray *)allInMOC:(NSManagedObjectContext *)inMOC withName:(NSString *)name;
+ (NSArray *)allInMOC:(NSManagedObjectContext *)inMOC withTag:(NSNumber *)tag;
+ (NSArray *)allInMOC:(NSManagedObjectContext *)inMOC withFolder:(DocumentFolder *)object;
+ (ReaderDocument *)insertInMOC:(NSManagedObjectContext *)inMOC name:(NSString *)name path:(NSString *)path;
+ (ReaderDocument *)initOneInMOC:(NSManagedObjectContext *)inMOC name:(NSString *)name tag:(NSNumber *)tag;
+ (void)complementInMOC:(NSManagedObjectContext *)inMOC object:(ReaderDocument *)reader path:(NSString *)path;
+ (void)refreashInMOC:(NSManagedObjectContext *)inMOC object:(ReaderDocument *)reader;
+ (void)renameInMOC:(NSManagedObjectContext *)inMOC object:(ReaderDocument *)object name:(NSString *)string;
+ (void)deleteInMOC:(NSManagedObjectContext *)inMOC object:(ReaderDocument *)object;// fm:(NSFileManager *)fm;
+ (void)deleteInMOC:(NSManagedObjectContext *)inMOC array:(NSMutableArray *)array;
+ (BOOL)existsInMOC:(NSManagedObjectContext *)inMOC guid:(NSString *)guid;

+ (NSURL*) urlForAnnotatedDocument:(ReaderDocument *)document;

- (void)updateObjectProperties;
- (void)saveReaderDocument;
- (void)saveReaderDocumentWithAnnotations;
- (BOOL)fileExistsAndValid:(NSString *)fileURL;
- (AnnotationStore*) annotations;


//extern NSString *const ReaderDocumentAddedNotification;
extern NSString *const ReaderDocumentRenamedNotification;
//extern NSString *const ReaderDocumentDeletedNotification;
extern NSString *const ReaderDocumentNotificationObjectID;

@end
