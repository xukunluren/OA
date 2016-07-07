//
//  AnnotationViewController.h
//	ThatPDF v0.3.1
//
//	Created by Brett van Zuiden.
//	Copyright © 2013 Ink. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ReaderDocument.h"
#import "Annotation.h"
#import "ReaderContentView.h"
#import <WacomDevice/WacomDeviceFramework.h>

extern NSString *const AnnotationViewControllerType_None;
extern NSString *const AnnotationViewControllerType_Sign;
extern NSString *const AnnotationViewControllerType_RedPen;
extern NSString *const AnnotationViewControllerType_Text;
extern NSString *const AnnotationViewControllerType_Erase;
extern NSString *const AnnotationViewControllerType_ESign;
extern NSString *const AnnotationViewControllerType_EPen;

@protocol TextKeyboardNotificationDelegate <NSObject>

@required
- (void)keyboardWillShow:(CGFloat )offset;
- (void)keyboardDidHidden:(CGFloat )offset;

@end

@interface AnnotationViewController : UIViewController<UIGestureRecognizerDelegate, UIPopoverControllerDelegate>

@property NSString *annotationType;
@property ReaderDocument *document;
@property NSInteger currentPage;
@property (nonatomic, assign) id<TextKeyboardNotificationDelegate> delegate;

- (id)initWithDocument:(ReaderDocument *)document;
- (BOOL)moveToPage:(int)page contentView:(ReaderContentView*) view;
- (void) hide;
- (void) clear;
- (void) undo;

- (AnnotationStore*) annotations;

- (UIImage *)getImageFromAnnotationsWithPage:(int)page;

@end