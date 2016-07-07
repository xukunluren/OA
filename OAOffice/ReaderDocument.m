//
//  ReaderDocument.m
//  OAOffice
//
//  Created by admin on 15/1/15.
//  Copyright (c) 2015年 DigitalOcean. All rights reserved.
//

#import "ReaderDocument.h"
#import "DocumentFolder.h"
#import "ReaderThumbCache.h"
#import "CGPDFDocument.h"
#import "AnnotationStore.h"
#import "ReaderThumbView.h"
#import "OAPDFCell.h"
#import <fcntl.h>

#import "MBProgressHUD.h"

@implementation ReaderDocument
{
    NSMutableIndexSet *_bookmarks;
    AnnotationStore *_annotations;
    NSNumber *_pageNumber;
}
#pragma mark Constants

#define kReaderDocument @"ReaderDocument"

#pragma mark Properties

@dynamic fileDate;
@dynamic fileId;
@dynamic fileLink;
@dynamic fileName;
@dynamic filePath;
@dynamic fileSize;
@dynamic fileTag;
@dynamic fileURL;
@dynamic guid;
@dynamic lastOpen;
@dynamic missiveType;
@dynamic pageCount;
@dynamic pageNumber;
@dynamic password;
@dynamic tagData;
@dynamic taskInfo;
@dynamic taskName;
@dynamic taskStartTime;
@dynamic thumbImage;
@dynamic urgencyLevel;
@dynamic fileOpen;
@dynamic folder;

@synthesize isChecked;
@synthesize bookmarks;
@synthesize imageDic;

@dynamic canEmail, canExport, canPrint;


#pragma mark ReaderDocument class methods

+ (NSString *)GUID
{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    
    CFStringRef theString = CFUUIDCreateString(NULL, theUUID);
    
    NSString *unique = [NSString stringWithString:(__bridge id)theString];
    
    CFRelease(theString); CFRelease(theUUID); // Cleanup CF objects
    
    return unique;
}

+ (NSString *)applicationPath
{
    static dispatch_once_t predicate = 0;
    
    static NSString *applicationPath = nil; // Application path string
    
    dispatch_once(&predicate, // Thread-safe create copy of the application path the first time it is needed
                  ^{
                      NSArray *documentsPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                      
                      applicationPath = [[[documentsPaths objectAtIndex:0] stringByDeletingLastPathComponent] copy]; // Strip "Documents"
                  });
    
    return applicationPath;
}

+ (NSString *)relativeFilePath:(NSString *)fullFilePath
{
    assert(fullFilePath != nil); // Ensure that the full file path is not nil
    
    NSString *applicationPath = [ReaderDocument applicationPath]; // Get the application path
    
    NSRange range = [fullFilePath rangeOfString:applicationPath]; // Look for the application path
    
    assert(range.location != NSNotFound); // Ensure that the application path is in the full file path
    
    return [fullFilePath stringByReplacingCharactersInRange:range withString:@""]; // Strip it out
}


#pragma mark ReaderDocument Core Data class methods

+ (NSArray *)allInMOC:(NSManagedObjectContext *)inMOC
{
    assert(inMOC != nil); // Check parameter
    
    NSFetchRequest *request = [NSFetchRequest new]; // Fetch request instance
    
    [request setEntity:[NSEntityDescription entityForName:kReaderDocument inManagedObjectContext:inMOC]];
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"fileName" ascending:YES];
    
    [request setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]]; // Sort order
    
    [request setReturnsObjectsAsFaults:YES]; [request setFetchBatchSize:32]; // Optimize fetch
    
    __autoreleasing NSError *error = nil; // Error information object
    
    NSArray *objectList = [inMOC executeFetchRequest:request error:&error];
    
    if (objectList == nil) { MyLog(@"%s %@", __FUNCTION__, error); assert(NO); }
    
    return objectList;
}

+ (NSArray *)allInMOC:(NSManagedObjectContext *)inMOC withTag:(NSNumber *)tag
{
    assert(inMOC != nil); assert(tag != nil); // Check parameters
    
    NSFetchRequest *request = [NSFetchRequest new]; // Fetch request instance
    
    [request setEntity:[NSEntityDescription entityForName:kReaderDocument inManagedObjectContext:inMOC]];
    
    [request setPredicate:[NSPredicate predicateWithFormat:@"fileTag == %@", tag]]; // Matching file name
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"fileName" ascending:YES];
    
    [request setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]]; // Sort order
    
    [request setReturnsObjectsAsFaults:YES];
    [request setFetchBatchSize:32]; // Optimize fetch
    
    __autoreleasing NSError *error = nil; // Error information object
    
    NSArray *objectList = [inMOC executeFetchRequest:request error:&error];
    
    if (objectList == nil) { MyLog(@"%s %@", __FUNCTION__, error); assert(NO); }
    
    return objectList;
}

+ (NSArray *)allInMOC:(NSManagedObjectContext *)inMOC withName:(NSString *)name
{
    assert(inMOC != nil); assert(name != nil); // Check parameters
    
    NSFetchRequest *request = [NSFetchRequest new]; // Fetch request instance
    
    [request setEntity:[NSEntityDescription entityForName:kReaderDocument inManagedObjectContext:inMOC]];
    
    [request setPredicate:[NSPredicate predicateWithFormat:@"fileName == %@", name]]; // Matching file name
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"fileName" ascending:YES];
    
    [request setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]]; // Sort order
    
    [request setReturnsObjectsAsFaults:YES];
    [request setFetchBatchSize:32]; // Optimize fetch
    
    __autoreleasing NSError *error = nil; // Error information object
    
    NSArray *objectList = [inMOC executeFetchRequest:request error:&error];
    
    if (objectList == nil) { MyLog(@"%s %@", __FUNCTION__, error); assert(NO); }
    
    return objectList;
}

+ (NSArray *)allInMOC:(NSManagedObjectContext *)inMOC withFolder:(DocumentFolder *)object
{
    assert(inMOC != nil); assert(object != nil); // Check parameters
    
    NSPredicate *predicate = nil;
    NSSortDescriptor *sortDescriptor = nil;
    
    switch ([object.type integerValue]) // Document folder type
    {
        case DocumentFolderTypeUser: // User folder type
        {
            predicate = [NSPredicate predicateWithFormat:@"folder == %@", object]; // Folder
            sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"fileName" ascending:YES];
            break;
        }
            
        case DocumentFolderTypeDefault: // Default folder type
        {
            predicate = [NSPredicate predicateWithFormat:@"folder == %@", NULL]; // No folder
            sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"fileName" ascending:YES];
            break;
        }
            
        case DocumentFolderTypeRecent: // Recent folder type
        {
            NSDate *since = [NSDate dateWithTimeIntervalSinceReferenceDate:0.0];
            predicate = [NSPredicate predicateWithFormat:@"lastOpen > %@", since]; // Opened
            sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"lastOpen" ascending:NO];
            break;
        }
        default:
            break;
    }
    
    if (sortDescriptor) {
        NSFetchRequest *request = [NSFetchRequest new]; // Fetch request instance
        
        [request setEntity:[NSEntityDescription entityForName:kReaderDocument inManagedObjectContext:inMOC]];
        
        [request setPredicate:predicate];
        [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
        
        [request setReturnsObjectsAsFaults:YES];
        [request setFetchBatchSize:32]; // Optimize fetch request
        
        __autoreleasing NSError *error = nil; // Error information object
        
        NSArray *objectList = [inMOC executeFetchRequest:request error:&error];
        
        if (objectList == nil) { MyLog(@"%s %@", __FUNCTION__, error); assert(NO); }
        
        return objectList;
    }else{
        return nil;
    }
}

+ (ReaderDocument *)insertInMOC:(NSManagedObjectContext *)inMOC name:(NSString *)name path:(NSString *)path
{
    assert(inMOC != nil); assert(name != nil); assert(path != nil); // Check parameters
    ReaderDocument *object = [NSEntityDescription insertNewObjectForEntityForName:kReaderDocument inManagedObjectContext:inMOC];
    
    if ((object != nil) && ([object isMemberOfClass:[ReaderDocument class]])) // We have a valid ReaderDocument object
    {
        object.fileName = name; // Document file name
        
        object.guid = [ReaderDocument GUID]; // Document GUID
        
        object.pageNumber = [NSNumber numberWithInteger:1]; // Start on page 1
        
        object.filePath = [ReaderDocument relativeFilePath:path]; // Relative path to file
        
        object.fileURL = [path stringByAppendingPathComponent:object.fileName];
        
        NSString *fullPath = [path stringByAppendingPathComponent:name];
        NSFileManager* fileMngr = [[NSFileManager alloc]init];
        NSDictionary* attributes = [fileMngr attributesOfItemAtPath:fullPath error:nil];
        
        object.fileDate = (NSDate *)[attributes objectForKey:NSFileCreationDate]; // File date
        
        object.lastOpen = object.fileDate; // Last opened ,start file Date
        
        object.fileSize = (NSNumber *)[attributes objectForKey:NSFileSize];// File size
        
        object.fileTag = @1;//
        // 3. 获取并保存，该文件的首页缩略图
        if ([object fileExistsAndValid:object.fileURL]) {
            UIImage *thumbImage = [OATools imageFromPDFWithDocumentRef:object.fileURL withPageNum:1 withSize:1.0];
            object.thumbImage = UIImagePNGRepresentation(thumbImage);
        }
        
    }
    NSError *error = nil;
    if ([inMOC save:&error]) {
        return object;
    }else{
        MyLog(@"%s %@", __FUNCTION__, error); assert(NO);
        return nil;
    }
}

+ (ReaderDocument *)initOneInMOC:(NSManagedObjectContext *)inMOC name:(NSString *)name tag:(NSNumber *)tag
{
    assert(inMOC != nil); assert(name != nil); // Check parameters
    ReaderDocument *object = [NSEntityDescription insertNewObjectForEntityForName:kReaderDocument inManagedObjectContext:inMOC];
    
    if ((object != nil) && ([object isMemberOfClass:[ReaderDocument class]])) // We have a valid ReaderDocument object
    {
        object.fileName = name; // Document file name
        
        object.guid = [ReaderDocument GUID]; // Document GUID
        
        //初始化时，默认新建公文时间为lastOpen时间，ComplementInMOC中会进一步补充；
        object.lastOpen = [NSDate date];
        
        object.fileTag = tag;
        
        object.fileURL = nil;
        
        object.fileOpen = @0;//默认未打开阅读
    }
    NSError *error = nil;
    if ([inMOC save:&error]) {
        return object;
    }else{
        NSString *info = [NSString stringWithFormat:@"Error:New OAPDFCell initOneInMOC ERROR./n%@",error.description];
        [OATools newLogWithInfo:info time:[OATools newStringDate] type:kLogErrorType];
        MyLog(@"%s %@", __FUNCTION__, error); assert(NO);
        return nil;
    }
}

+ (void)complementInMOC:(NSManagedObjectContext *)inMOC object:(ReaderDocument *)reader path:(NSString *)path
{
    assert(inMOC != nil); assert(reader != nil); assert(path != nil); // Check parameters
    // 1. 实例化一个查询(Fetch)请求
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kOAPDFDocument];
    
    // 2. 条件查询，通过谓词来实现的
    request.predicate = [NSPredicate predicateWithFormat:@"guid == %@", reader.guid];
    // 在谓词中CONTAINS类似于数据库的 LIKE '%王%'
    //    request.predicate = [NSPredicate predicateWithFormat:@"phoneNo CONTAINS '1'"];
    // 如果要通过key path查询字段，需要使用%K
    //    request.predicate = [NSPredicate predicateWithFormat:@"%K CONTAINS '1'", @"phoneNo"];
    // 直接查询字表中的条件
    
    // 3. 让_context执行查询数据
    NSArray *array = [inMOC executeFetchRequest:request error:nil];
    for (ReaderDocument *object in array) {
        
        object.pageNumber = [NSNumber numberWithInteger:1]; // Start on page 1
        
        object.filePath = [ReaderDocument relativeFilePath:path]; // Relative path to file
        
        //        object.fileURL = [path stringByAppendingPathComponent:object.fileName];
        object.fileURL = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.pdf",object.fileId]];
        //        MyLog(@"fileURL:%@",object.fileURL);
        
        NSFileManager* fileMngr = [[NSFileManager alloc]init];
        NSDictionary* attributes = [fileMngr attributesOfItemAtPath:object.fileURL error:nil];
        
        object.fileDate = (NSDate *)[attributes objectForKey:NSFileCreationDate]; // File date
        
        object.lastOpen = [NSDate date]; // Last opened ,start file Date
        
        object.fileSize = (NSNumber *)[attributes objectForKey:NSFileSize];// File size
        
        // 3. 获取并保存，该文件的首页缩略图
        if ([object fileExistsAndValid:object.fileURL]) {
            UIImage *thumbImage = [OATools imageFromPDFWithDocumentRef:object.fileURL withPageNum:1 withSize:1.0];
            object.thumbImage = UIImagePNGRepresentation(thumbImage);
        }
        MyLog(@"%@",object.fileName);
        
        break;
    }
    // 4. 通知_context修改数据是否成功
    NSError *error = nil;
    if ([inMOC save:&error]) {
        MyLog(@"Complement:补充成功\n");
    }else{
        NSString *info = [NSString stringWithFormat:@"Error:complementInMOC ERROR.%@",error.description];
        [OATools newLogWithInfo:info time:[OATools newStringDate] type:kLogErrorType];
        MyLog(@"%s %@", __FUNCTION__, error); assert(NO);
    }
}

+ (void)refreashInMOC:(NSManagedObjectContext *)inMOC object:(ReaderDocument *)reader
{
    assert(inMOC != nil); assert(reader != nil); // Check parameters
    // 1. 实例化一个查询(Fetch)请求
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kOAPDFDocument];
    MyLog(@"reader.guid:%@",reader.guid);
    // 2. 条件查询，通过谓词来实现的
    request.predicate = [NSPredicate predicateWithFormat:@"guid == %@", reader.guid];
    // 在谓词中CONTAINS类似于数据库的 LIKE '%王%'
    //    request.predicate = [NSPredicate predicateWithFormat:@"phoneNo CONTAINS '1'"];
    // 如果要通过key path查询字段，需要使用%K
    //    request.predicate = [NSPredicate predicateWithFormat:@"%K CONTAINS '1'", @"phoneNo"];
    // 直接查询字表中的条件
    
    // 3. 让_context执行查询数据
    NSArray *array = [inMOC executeFetchRequest:request error:nil];
    for (ReaderDocument *object in array) {
        object.fileTag = @2;
        
//        NSFileManager* fileMngr = [[NSFileManager alloc]init];
//        NSDictionary* attributes = [fileMngr attributesOfItemAtPath:object.fileURL error:nil];
//        object.fileDate = (NSDate *)[attributes objectForKey:NSFileCreationDate]; // File date
        
        object.lastOpen = [NSDate date];//(NSDate *)[attributes objectForKey:NSFileModificationDate]; // Last opened ,start file Date
        
//        object.fileSize = (NSNumber *)[attributes objectForKey:NSFileSize];// File size
//        
//        // 3. 获取并保存，该文件的首页缩略图
//        if ([object fileExistsAndValid:object.fileURL]) {
//            UIImage *thumbImage = [OATools imageFromPDFWithDocumentRef:object.fileURL withPageNum:1 withSize:1.0];
//            object.thumbImage = UIImagePNGRepresentation(thumbImage);
//        }
        
        break;
    }
    // 4. 通知_context修改数据是否成功
    NSError *error = nil;
    if ([inMOC save:&error]) {
        MyLog(@"Refreash:修改成功");
    }else{
        NSString *info = [NSString stringWithFormat:@"Error:refreashInMOC ERROR.%@",error.description];
        [OATools newLogWithInfo:info time:[OATools newStringDate] type:kLogErrorType];
        MyLog(@"%s %@", __FUNCTION__, error); assert(NO);
    }
}


+ (void)renameInMOC:(NSManagedObjectContext *)inMOC object:(ReaderDocument *)object name:(NSString *)string
{
    assert(inMOC != nil); assert(object != nil); assert(string != nil); // Check parameters
    
    NSString *applicationPath = [ReaderDocument applicationPath]; // Application path
    
    NSString *fullPath = [applicationPath stringByAppendingPathComponent:object.filePath];
    
    NSString *oldFilePath = [fullPath stringByAppendingPathComponent:object.fileName];
    
    NSString *newFilePath = [fullPath stringByAppendingPathComponent:string];
    
    __autoreleasing NSError *error = nil; // Error information object
    
    NSFileManager *fileManager = [NSFileManager new]; // File manager instance
    
    BOOL status = [fileManager moveItemAtPath:oldFilePath toPath:newFilePath error:&error];
    
    if (status == YES) // Check rename status
    {
        object.fileURL = nil; // Clear file URL
        
        object.fileName = string; // New file name
        
        if ([inMOC hasChanges] == YES) // Save changes
        {
            if ([inMOC save:&error] == YES) // Did save changes
            {
                NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
                
                NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[object objectID] forKey:ReaderDocumentNotificationObjectID];
                
                [notificationCenter postNotificationName:ReaderDocumentRenamedNotification object:nil userInfo:userInfo];
            }
            else // Log any errors
            {
                MyLog(@"%s %@", __FUNCTION__, error); assert(NO);
            }
        }
    }
    else // Rename failed
    {
        MyLog(@"%s %@", __FUNCTION__, error);
    }
}

+ (void)deleteInMOC:(NSManagedObjectContext *)inMOC object:(ReaderDocument *)object// fm:(NSFileManager *)fm
{
    assert(inMOC != nil); assert(object != nil); //assert(fm != nil); // Check parameters
    
    [ReaderThumbCache removeThumbCacheWithGUID:object.guid]; // Delete the thumb cache
    MyLog(@"PDF:%@ Delete... Object",object.fileName);
    [inMOC deleteObject:object];
    // Sign pdf的文件路径filePath,删除该文件;
    //    if ([object fileExistsAndValid:object.fileURL]) {
    if ([[NSFileManager new] fileExistsAtPath:object.fileURL]) {
        [[NSFileManager new] removeItemAtURL:[NSURL fileURLWithPath:object.fileURL] error:nil];
    }
    // Sign png的文件路径pngPath,删除该文件;
    NSString *pngPath = [kDocumentPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png",object.fileId]];
    if ([[NSFileManager new] fileExistsAtPath:pngPath]) {
        [[NSFileManager new] removeItemAtPath:pngPath error:nil];
    }
    
    // 注释掉以下代码，以前的CoreData数据删除不一致问题消失了，有待继续消化，找到更好的方法。
    //    NSError *error = nil;
    //    if ([inMOC save:&error]) {
    //        MyLog(@"删除成功");
    //    } else {
    //        MyLog(@"删除失败：%s %@", __FUNCTION__, error); assert(NO);
    //    }
}

+ (void)deleteInMOC:(NSManagedObjectContext *)inMOC array:(NSMutableArray *)array
{
    assert(inMOC != nil);
    for (ReaderDocument *object in array) {
        [ReaderThumbCache removeThumbCacheWithGUID:object.guid]; // Delete the thumb cache
        MyLog(@"PDF:%@ Delete...Array",object.fileName);
        [inMOC deleteObject:object];
        NSError *error;
        // Sign pdf的文件路径filePath,删除该文件;
        if ([[NSFileManager new] fileExistsAtPath:object.fileURL]) {
            [[NSFileManager new] removeItemAtURL:[NSURL fileURLWithPath:object.fileURL] error:&error];
            MyLog(@"Pdf Delete Error:%@",error.description);
        }
        // Sign png的文件路径pngPath,删除该文件;
        NSString *pngPath = [kDocumentPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png",object.fileId]];
        if ([[NSFileManager new] fileExistsAtPath:pngPath]) {
            [[NSFileManager new] removeItemAtPath:pngPath error:&error];
            MyLog(@"Png Delete Error:%@",error.description);
        }
    }
    NSError *error = nil;
    if ([inMOC save:&error]) {
        MyLog(@"删除成功");
    } else {
        MyLog(@"删除失败：%s %@", __FUNCTION__, error); assert(NO);
    }
}

+ (BOOL)existsInMOC:(NSManagedObjectContext *)inMOC guid:(NSString *)guid
{
    assert(inMOC != nil); assert(guid != nil); // Check parameters
    
    NSFetchRequest *request = [NSFetchRequest new]; // Fetch request instance
    
    [request setEntity:[NSEntityDescription entityForName:kReaderDocument inManagedObjectContext:inMOC]];
    
    //    [request setPredicate:[NSPredicate predicateWithFormat:@"fileName == %@", string]]; // Name predicate
    [request setPredicate:[NSPredicate predicateWithFormat:@"guid == %@", guid]]; // Name predicate
    
    __autoreleasing NSError *error = nil; // Error information object
    
    NSUInteger count = [inMOC countForFetchRequest:request error:&error];
    
    if (error != nil) { MyLog(@"%s %@", __FUNCTION__, error); assert(NO); }
    
    return ((count > 0) ? YES : NO);
}

#pragma mark ReaderDocument Core Data instance methods

- (NSMutableIndexSet *)bookmarks
{
    if (_bookmarks == nil) // Create on first access
    {
        if (self.tagData != nil) // Unarchive tag (bookmarks) data
        {
            NSIndexSet *set = [NSKeyedUnarchiver unarchiveObjectWithData:self.tagData];
            
            if ((set != nil) && [set isKindOfClass:[NSIndexSet class]]) // Validate
            {
                _bookmarks = [set mutableCopy]; // Mutable copy of index set
            }
        }
        
        if (_bookmarks == nil) // Create bookmarks set
        {
            _bookmarks = [NSMutableIndexSet new];
        }
    }
    
    return _bookmarks;
}

- (void)updateObjectProperties
{
    NSURL *url = [NSURL fileURLWithPath:self.fileURL];
    CFURLRef docURLRef = (__bridge CFURLRef)url; // File URL
    
    CGPDFDocumentRef thePDFDocRef = CGPDFDocumentCreateWithURL(docURLRef);
    
    if (thePDFDocRef != NULL) // Get the number of pages in the document
    {
        NSInteger pageCount = CGPDFDocumentGetNumberOfPages(thePDFDocRef);
        
        _annotations = [[AnnotationStore alloc] initWithPageCount:(int)pageCount];
        
        self.pageCount = [NSNumber numberWithInteger:pageCount];
        
        CGPDFDocumentRelease(thePDFDocRef); // Cleanup
    }
    
    NSString *fullFilePath = self.fileURL; // Full file path
    
    NSFileManager *fileManager = [NSFileManager new]; // File manager instance
    
    NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:fullFilePath error:NULL];
    
    self.fileDate = [fileAttributes objectForKey:NSFileModificationDate]; // File date
    
    self.fileSize = [fileAttributes objectForKey:NSFileSize]; // File size
}

- (void)saveReaderDocument
{
    if (_bookmarks != nil) // Archive bookmarks (tag) data
    {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:_bookmarks];
        
        if ([self.tagData isEqualToData:data] == NO)
            self.tagData = data;
    }
    
    NSManagedObjectContext *saveMOC = self.managedObjectContext;
    
    if (saveMOC != nil) // Save managed object context
    {
        if ([saveMOC hasChanges] == YES) // Save changes
        {
            __autoreleasing NSError *error = nil; // Error information object
            
            if ([saveMOC save:&error] == NO) // Log any errors
            {
                MyLog(@"%s %@", __FUNCTION__, error);
                assert(NO);
            }
        }
    }
}

- (void)saveReaderDocumentWithAnnotations {
    NSURL *annotatedDocURL = [ReaderDocument urlForAnnotatedDocument:self];
    [[[NSFileManager alloc] init] replaceItemAtURL:[NSURL fileURLWithPath:self.fileURL] withItemAtURL:annotatedDocURL backupItemName:nil options:0 resultingItemURL:nil error:nil];
    [self saveReaderDocument];
}

// 判断PDF文件存在并有效
- (BOOL)fileExistsAndValid:(NSString *)fileURL
{
    BOOL state = NO; // Status
    
    if (self.isDeleted == NO) // Not deleted
    {
        NSString *filePath = fileURL; // Path
        
        const char *path = [filePath fileSystemRepresentation];
        
        int fd = open(path, O_RDONLY); // Open the file
        
        if (fd > 0) // We have a valid file descriptor
        {
            const char sig[1024]; // File signature buffer
            
            ssize_t len = read(fd, (void *)&sig, sizeof(sig));
            
            state = (strnstr(sig, "%PDF", len) != NULL);
            
            close(fd); // Close the file
        }
    }
    
    return state;
}

- (void)willTurnIntoFault
{
    _bookmarks = nil; self.isChecked = NO;
}

#pragma mark Annotations code
- (AnnotationStore*) annotations {
    if (!_annotations) {
        _annotations = [[AnnotationStore alloc] initWithPageCount:[self.pageCount intValue]];
    }
    return _annotations;
}

+ (NSURL*) urlForAnnotatedDocument:(ReaderDocument *)document
{
    CGPDFDocumentRef doc = CGPDFDocumentCreateUsingUrl((__bridge CFURLRef)[NSURL fileURLWithPath:document.fileURL], document.password);
    
    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingString:@"annotated.pdf"];
    //CGRectZero means the default page size is 8.5x11
    //We don't care about the default anyway, because we set each page to be a specific size
    UIGraphicsBeginPDFContextToFile(tempPath, CGRectZero, nil);
    
    //Iterate over each page - 1-based indexing (obnoxious...)
    int pages = [document.pageCount intValue];
    for (int i = 1; i <= pages; i++)
    {
        CGPDFPageRef page = CGPDFDocumentGetPage (doc, i); // grab page i of the PDF
        CGRect bounds = [ReaderDocument boundsForPDFPage:page];
        
        //Create a new page
        UIGraphicsBeginPDFPageWithInfo(bounds, nil);
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        // flip context so page is right way up
        CGContextTranslateCTM(context, 0, bounds.size.height);
        CGContextScaleCTM(context, 1.0, -1.0);
        CGContextDrawPDFPage (context, page); // draw the page into graphics context
        
        //Annotations
        NSArray *annotations = [document.annotations annotationsForPage:i];
        if ([annotations count] > 0)
        {
            MyLog(@"Writing %lu annotations", (unsigned long)[annotations count]);
            //Flip back right-side up
            CGContextScaleCTM(context, 1.0, -1.0);
            CGContextTranslateCTM(context, 0, -bounds.size.height);
            
            for (Annotation *anno in annotations)
            {
                [anno drawInContext:context];
            }
        }
    }
    // TODO Some Error
    UIGraphicsEndPDFContext();
    CGPDFDocumentRelease(doc);
    return [NSURL fileURLWithPath:tempPath];
}

+ (CGRect) boundsForPDFPage:(CGPDFPageRef) page{
    CGRect cropBoxRect = CGPDFPageGetBoxRect(page, kCGPDFCropBox);
    CGRect mediaBoxRect = CGPDFPageGetBoxRect(page, kCGPDFMediaBox);
    CGRect effectiveRect = CGRectIntersection(cropBoxRect, mediaBoxRect);
    
    int pageAngle = CGPDFPageGetRotationAngle(page); // Angle
    
    float pageWidth, pageHeight, pageOffsetX, pageOffsetY;
    switch (pageAngle) // Page rotation angle (in degrees)
    {
        default: // Default case
        case 0: case 180: // 0 and 180 degrees
        {
            pageWidth = effectiveRect.size.width;
            pageHeight = effectiveRect.size.height;
            pageOffsetX = effectiveRect.origin.x;
            pageOffsetY = effectiveRect.origin.y;
            break;
        }
            
        case 90: case 270: // 90 and 270 degrees
        {
            pageWidth = effectiveRect.size.height;
            pageHeight = effectiveRect.size.width;
            pageOffsetX = effectiveRect.origin.y;
            pageOffsetY = effectiveRect.origin.x;
            break;
        }
    }
    
    return CGRectMake(pageOffsetX, pageOffsetY, pageWidth, pageHeight);
}

- (BOOL)canEmail
{
    return NO;
}

- (BOOL)canExport
{
    return NO;
}

- (BOOL)canPrint
{
    return NO;
}

#pragma mark Notification name strings

//NSString *const ReaderDocumentAddedNotification = @"ReaderDocumentAddedNotification";
NSString *const ReaderDocumentRenamedNotification = @"ReaderDocumentRenamedNotification";
//NSString *const ReaderDocumentDeletedNotification = @"ReaderDocumentDeletedNotification";
NSString *const ReaderDocumentNotificationObjectID = @"ReaderDocumentNotificationObjectID";

@end
