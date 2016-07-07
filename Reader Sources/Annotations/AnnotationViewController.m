//
//  AnnotationViewController.m
//	ThatPDF v0.3.1
//
//	Created by Brett van Zuiden.
//	Copyright © 2013 Ink. All rights reserved.
//

#import "AnnotationViewController.h"
#import "OAWacomStylusVC.h"

NSString *const AnnotationViewControllerType_None   = @"None";
NSString *const AnnotationViewControllerType_Sign   = @"Sign";
NSString *const AnnotationViewControllerType_RedPen = @"RedPen";
NSString *const AnnotationViewControllerType_Erase  = @"Erase";
NSString *const AnnotationViewControllerType_Text   = @"Text";
NSString *const AnnotationViewControllerType_ESign  = @"ESign";
NSString *const AnnotationViewControllerType_EPen   = @"EPen";

int const ANNOTATION_IMAGE_TAG = 431;
CGFloat const TEXT_FIELD_WIDTH = 200;
CGFloat const TEXT_FIELD_HEIGHT= 25;
CGFloat const RED_LINE_WIDTH   = 2.0;
CGFloat const BLACK_LINE_WIDTH = 1.0;
CGFloat const ERASE_LINE_WIDTH = 50.0;
CGFloat const ESIGN_IMAGE_HEIGHT = 40.0;

@interface AnnotationViewController () <UITextViewDelegate,WacomStylusUseDelegate>

@end

@implementation AnnotationViewController
{
    CGPoint lastPoint;
    CGPoint currentPoint;
    
    UIImageView *imageView;
    UIView *pageView;
    CGColorRef annotationColor;
    CGColorRef signColor;
    CGColorRef eraseColor;
    
    NSString *_annotationType;
    AnnotationStore *annotationStore;
    
    //We need both because of the UIBezierPath nonsense
    NSMutableArray *currentPaths;
    CGMutablePathRef currPath;
    CGMutablePathRef basePath;
    
    BOOL didMove;
    CGPoint lastContactPoint1, lastContactPoint2;
    
    UITextField *textField;
    UIView *eraseView;
    UITextView *_textView;
    UIImageView *_eSignImage;
    UIImageView *_ePenImage;
    
    BOOL keyBoardShow;
    CGFloat keyBoardOffset;
    CGFloat keyBoardHideOffset;
}
@dynamic annotationType;
@synthesize delegate;

- (id) initWithDocument:(ReaderDocument *)readerDocument
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.annotationType = AnnotationViewControllerType_None;
        self.document       = readerDocument;
        
        annotationColor = [UIColor redColor].CGColor;
        signColor       = [UIColor blackColor].CGColor;
        eraseColor      = [UIColor clearColor].CGColor;
        
        self.currentPage= 0;
        imageView       = [[UIImageView alloc] initWithImage:nil];
        imageView.frame = CGRectMake(0,0,100,100); //so we don't error out
        currentPaths    = [NSMutableArray array];
        
        annotationStore = [[AnnotationStore alloc] initWithPageCount:[readerDocument.pageCount intValue]];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.view.userInteractionEnabled = ![self.annotationType isEqualToString:AnnotationViewControllerType_None];
    self.view.opaque = NO;
    self.view.backgroundColor = [UIColor clearColor];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(observerKeyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(observerKeyboardWasHidden:) name:UIKeyboardDidHideNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[WacomManager getManager] deregisterForNotifications:self];
}

- (UIImageView*) createImageView {
    UIImageView *temp = [[UIImageView alloc] initWithImage:nil];
    temp.frame = pageView.frame;
    temp.tag = ANNOTATION_IMAGE_TAG;
    return temp;
}

- (UITextField*) createTextField {
    UITextField *temp = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, TEXT_FIELD_WIDTH, TEXT_FIELD_HEIGHT)];
    temp.font = [UIFont systemFontOfSize:10.0f];
    temp.hidden = YES;
    temp.backgroundColor = [UIColor clearColor];
    temp.borderStyle = UITextBorderStyleLine;
    
    return temp;
}

- (UITextView *) createTextView {
    UITextView *temp = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, TEXT_FIELD_WIDTH, TEXT_FIELD_HEIGHT)];
    temp.textColor = [UIColor blackColor];//设置textview里面的字体颜色
    temp.font = [UIFont fontWithName:kFontName size:kFontSize];
    temp.backgroundColor = [UIColor clearColor];//设置它的背景颜色
    temp.returnKeyType = UIReturnKeyDefault;//返回键的类型
    temp.scrollEnabled = NO;//是否可以拖动
    temp.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    [temp.layer setCornerRadius:10];
    temp.text = @"  ";
    temp.hidden = YES;
    temp.delegate = self;
    return temp;
}

- (UIView *) createEraseView{
    UIView *temp = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ERASE_LINE_WIDTH, ERASE_LINE_WIDTH)];
    temp.backgroundColor = [UIColor clearColor];
    temp.hidden = YES;
    temp.layer.borderColor = [[UIColor blackColor] CGColor];
    temp.layer.cornerRadius = ERASE_LINE_WIDTH * 0.5;
    temp.layer.borderWidth = 0.0;
    return temp;
}

- (UIImageView *)createESignImageView{
    UIImage *userEsignImage = nil;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *base64Img = [userDefaults objectForKey:kESignImage];
    if(base64Img.length > 0){
        NSData *signData = [[NSData alloc] initWithBase64EncodedString:base64Img options:0];
        userEsignImage = [UIImage imageWithData:signData];
    }

    // 初始化用户的签名图片
    if (userEsignImage) {
        UIImageView *eSignImageView = [[UIImageView alloc] initWithImage:userEsignImage];
        CGRect newFrame = eSignImageView.frame;
        newFrame.size.height = ESIGN_IMAGE_HEIGHT;//签名图片指定高度
        newFrame.size.width = newFrame.size.height * eSignImageView.frame.size.width / eSignImageView.frame.size.height;
        eSignImageView.frame = newFrame;
        eSignImageView.contentMode = UIViewContentModeScaleAspectFit;
        eSignImageView.hidden = YES;
        
        return eSignImageView;
    }else{
        return nil;
    }
}

- (BOOL) moveToPage:(int)page contentView:(ReaderContentView*) view {
    if (page != self.currentPage || !pageView) {
        [self finishCurrentAnnotation];
        
        self.currentPage = page;
        pageView = (UIView *)view.theContentPage;
        
        imageView = nil;
        imageView = [self createImageView];
        [pageView addSubview:imageView];
        
        [self refreshDrawing];
        return YES;
    }else{
        return NO;
    }
}

- (void) clear{
    //Setting up a blank image to start from. This displays the current drawing
    imageView.image     = nil;
    _textView.text      = @"";
    _textView.hidden    = YES;
    _eSignImage.hidden  = YES;
    _ePenImage.hidden   = YES;
    _textView           = nil;
    _eSignImage         = nil;
    _ePenImage          = nil;
    currPath            = nil;
    [currentPaths removeAllObjects];
    [annotationStore empty];
}

- (NSString*) annotationType {
    return _annotationType;
}

- (void) setAnnotationType:(NSString *)annotationType {
    if (![self.annotationType isEqualToString:AnnotationViewControllerType_None]) {
        //Close current annotation
        [self finishCurrentAnnotation];
    }
    _annotationType = annotationType;
    [self refreshDrawing];
    self.view.userInteractionEnabled = ![self.annotationType isEqualToString:AnnotationViewControllerType_None];
    
    if ([self.annotationType isEqualToString:AnnotationViewControllerType_Text]) {
        _textView = [self createTextView];
        [pageView addSubview:_textView];
    }else if ([self.annotationType isEqualToString:AnnotationViewControllerType_ESign]){
        _eSignImage = [self createESignImageView];
        [pageView addSubview:_eSignImage];
    }else if ([self.annotationType isEqualToString:AnnotationViewControllerType_EPen]){
        
    }
}

- (void) finishCurrentAnnotation {
    Annotation* annotation = [self getCurrentAnnotation];
    if (annotation) {
        [annotationStore addAnnotation:annotation toPage:(int)self.currentPage];
        
        if ([self.annotationType isEqualToString:AnnotationViewControllerType_Text]) {
            [_textView removeFromSuperview];
            _textView = nil;
        }else if ([self.annotationType isEqualToString:AnnotationViewControllerType_ESign]){
            [_eSignImage removeFromSuperview];
            _eSignImage = nil;
        }else if ([self.annotationType isEqualToString:AnnotationViewControllerType_EPen]){
            [_ePenImage removeFromSuperview];
            _ePenImage = nil;
        }
    }
    
#pragma mark -TODO basePath release 待解决
    if (basePath) {
        // 释放该path
//        CGPathRelease(basePath);
//        basePath = nil;
    }
    [currentPaths removeAllObjects];
    currPath = nil;
}

- (AnnotationStore *) annotations {
    [self finishCurrentAnnotation];
    return annotationStore;
}

- (Annotation *) getCurrentAnnotation {
    //输入打字状态
    if ([self.annotationType isEqualToString:AnnotationViewControllerType_Text]) {
        [_textView resignFirstResponder];
        [_textView setHidden:YES];
        if (_textView.text.length>0 && _textView.frame.origin.x>0 && _textView.frame.origin.y>0) {
            return [TextAnnotation textAnnotationWithText:_textView.text inRect:_textView.frame withFont:_textView.font];
        }else{
            return nil;
        }
    } else if ([self.annotationType isEqualToString:AnnotationViewControllerType_ESign]) { //电子签名图片状态
        if (_eSignImage.frame.origin.x>0 && _eSignImage.frame.origin.y>10) {
            return [ImageAnnotation imageAnnotationWithImage:[_eSignImage.image CGImage] inRect:[_eSignImage frame] withDate:YES];
        }else{
            return nil;
        }
    } else if ([self.annotationType isEqualToString:AnnotationViewControllerType_EPen]) { //电子笔签写图片状态
        if (_ePenImage.frame.origin.x>0 && _ePenImage.frame.origin.y>10) {
            return [ImageAnnotation imageAnnotationWithImage:[_ePenImage.image CGImage] inRect:[_ePenImage frame] withDate:NO];
        }else{
            return nil;
        }
    } else if ([self.annotationType isEqualToString:AnnotationViewControllerType_Sign] || [self.annotationType isEqualToString:AnnotationViewControllerType_RedPen] || [self.annotationType isEqualToString:AnnotationViewControllerType_Erase]){//绘制状态（红笔、黑笔、橡皮擦除）
        if (!currPath && [currentPaths count] == 0) {
            return nil;
        }else{
            //    CGMutablePathRef basePath = CGPathCreateMutable();
            basePath = CGPathCreateMutable();
            for (UIBezierPath *bpath in currentPaths) {
                bpath.miterLimit = -10;
                CGPathAddPath(basePath, NULL, bpath.CGPath);
            }
            CGPathAddPath(basePath, NULL, currPath);
            
            if ([self.annotationType isEqualToString:AnnotationViewControllerType_RedPen]) {
                PathAnnotation *pathAnnotation = [PathAnnotation pathAnnotationWithPath:basePath color:annotationColor lineWidth:RED_LINE_WIDTH fill:NO];
                return pathAnnotation;
            }
            if ([self.annotationType isEqualToString:AnnotationViewControllerType_Sign]) {
                PathAnnotation *pathAnnotation = [PathAnnotation pathAnnotationWithPath:basePath color:signColor lineWidth:BLACK_LINE_WIDTH fill:NO];
                return pathAnnotation;
            }
            if ([self.annotationType isEqualToString:AnnotationViewControllerType_Erase]) {
                PathAnnotation *pathAnnotation = [PathAnnotation pathAnnotationWithPath:basePath color:eraseColor lineWidth:ERASE_LINE_WIDTH fill:NO];
                return pathAnnotation;
            }
            
            // 释放该path
            CGPathRelease(basePath);
            return nil;
        }
    }else{
        return nil;
    }
    return nil;
}

- (void) hide {
    [self.view removeFromSuperview];
}

- (void) undo {
    //Immediate path
    if (currPath != nil) {
        currPath = nil;
    } else if ([currentPaths count] > 0) {
        //if we have a current path, undo it
        [currentPaths removeLastObject];
    } else {
        //pop from store
        [annotationStore undoAnnotationOnPage:(int)self.currentPage];
    }
    
    [self refreshDrawing];
}

- (void) refreshDrawing {
    UIGraphicsBeginImageContextWithOptions(pageView.frame.size, NO, 0);//1.5f
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    if (currentContext) {
        //Draw previous paths
        [annotationStore drawAnnotationsForPage:(int)self.currentPage inContext:currentContext];
        
//        if ([self.annotationType isEqualToString:AnnotationViewControllerType_Sign]) {
        if ([self.annotationType isEqualToString:AnnotationViewControllerType_Text]) {
        
            if (_textView.text.length > 0 && (_textView.frame.origin.x>0 && _textView.frame.origin.y>0)) {
                UIGraphicsPushContext(currentContext);
                CGContextSetTextMatrix(currentContext, CGAffineTransformMake(1.0,0.0, 0.0, -1.0, 0.0, 0.0));
                CGContextSetTextDrawingMode(currentContext, kCGTextFill);
                CGContextSetFillColorWithColor(currentContext, [[UIColor blackColor] CGColor]);
                CGRect newTextFrame = _textView.frame;
                newTextFrame.origin.x += 5;
                newTextFrame.origin.y += 7.22;
                
                @try {
//                    [_textView.text drawInRect:newTextFrame withAttributes:@{NSFontAttributeName:_textView.font}];
                    [_textView.text drawInRect:newTextFrame withAttributes:nil];
                }
                @catch (NSException *exception) {
                    NSLog(@"%@",exception);
                }
                @finally {
                    
                    
                }
                
                
                UIGraphicsPopContext();
            }
        }
        if (_eSignImage.frame.origin.x>0 && _eSignImage.frame.origin.y >0) {
            CGContextSaveGState(currentContext);
            CGContextTranslateCTM(currentContext, _eSignImage.frame.origin.x, _eSignImage.frame.origin.y);
            CGContextTranslateCTM(currentContext, 0, _eSignImage.frame.size.height);
            CGContextScaleCTM(currentContext, 1.0, -1.0);
            CGContextTranslateCTM(currentContext, -_eSignImage.frame.origin.x, -_eSignImage.frame.origin.y);
            CGContextDrawImage(currentContext, _eSignImage.frame, _eSignImage.image.CGImage);
            CGContextRestoreGState(currentContext);
            
            // Add Date
           
                UIGraphicsPushContext(currentContext);
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:@"yyyy/M/d"];
                [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
                NSString *dateTime = [dateFormatter stringFromDate:[NSDate date]];
            
                CGRect dateFrame = CGRectMake(_eSignImage.frame.origin.x + _eSignImage.frame.size.width + 1, _eSignImage.frame.origin.y + ESIGN_IMAGE_HEIGHT - 10, 80, 10);
            
                CGContextSetRGBFillColor (currentContext,  1, 1, 1, 1.0);//设置填充颜色
            @try {
               
                
                [dateTime drawWithRect:dateFrame options:NSStringDrawingUsesLineFragmentOrigin attributes:nil context:nil];
                
//                [dateTime drawInRect:dateFrame withAttributes:@{NSFontAttributeName:[UIFont fontWithName:kFontName size:8.0]}];
            }
            @catch (NSException *exception) {
                NSLog(@"%@",exception);
            }
            @finally {
            }
            UIGraphicsPopContext();
            
        }
        if (_ePenImage.frame.origin.x>0 && _ePenImage.frame.origin.y >0) {
            CGContextSaveGState(currentContext);
            CGContextTranslateCTM(currentContext, _ePenImage.frame.origin.x, _ePenImage.frame.origin.y);
            CGContextTranslateCTM(currentContext, 0, _ePenImage.frame.size.height);
            CGContextScaleCTM(currentContext, 1.0, -1.0);
            CGContextTranslateCTM(currentContext, -_ePenImage.frame.origin.x, -_ePenImage.frame.origin.y);
            CGContextDrawImage(currentContext, _ePenImage.frame, _ePenImage.image.CGImage);
            CGContextRestoreGState(currentContext);
        }
//        if ([currentPaths count] > 0) {
            CGContextSetShouldAntialias(currentContext, YES);
            CGContextSetAllowsAntialiasing(currentContext, YES);
            CGContextSetLineJoin(currentContext, kCGLineJoinRound);//线条拐角
            CGContextSetLineCap(currentContext, kCGLineCapRound);//终点处理
            //set the miter limit for the joins of connected lines in a graphics context
            CGContextSetMiterLimit(currentContext, 2.0);
            
            if ([self.annotationType isEqualToString:AnnotationViewControllerType_RedPen]) {
                //Setup style
                CGContextSetBlendMode(currentContext, kCGBlendModeNormal);
                CGContextSetLineWidth(currentContext, RED_LINE_WIDTH);
                CGContextSetStrokeColorWithColor(currentContext, annotationColor);
            }
            if ([self.annotationType isEqualToString:AnnotationViewControllerType_Sign]) {
                //Setup style
                CGContextSetBlendMode(currentContext, kCGBlendModeNormal);
                CGContextSetLineWidth(currentContext, BLACK_LINE_WIDTH);
                CGContextSetStrokeColorWithColor(currentContext, signColor);
            }
            if ([self.annotationType isEqualToString:AnnotationViewControllerType_Erase]) {
                //Setup style
                CGContextSetBlendMode(currentContext, kCGBlendModeClear);
                CGContextSetLineWidth(currentContext, ERASE_LINE_WIDTH);
                //CGContextSetStrokeColorWithColor(currentContext, eraseColor);
            }
            CGContextBeginPath(currentContext);
            
            //Draw Paths
            for (UIBezierPath *path in currentPaths) {
                CGContextAddPath(currentContext, path.CGPath);
            }
            
            CGContextAddPath(currentContext, currPath);
            
            //paint a line along the current path
            CGContextStrokePath(currentContext);
//        }
        
        //Saving
        imageView.image = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    lastPoint = [touch locationInView:pageView];
    
    lastContactPoint1 = [touch previousLocationInView:pageView];
    lastContactPoint2 = [touch previousLocationInView:pageView];
    
    if ([self.annotationType isEqualToString:AnnotationViewControllerType_Text]) {
        if (_textView.hidden) {
            _textView.layer.borderWidth = 1;
            _textView.hidden = NO;
            [_textView becomeFirstResponder];
        }
        if ([_textView pointInside:[touch locationInView:_textView] withEvent:nil]) {
            [_textView becomeFirstResponder];
            
        } else {
//            _textView.center = lastPoint;
            CGRect textFrame = _textView.frame;
            textFrame.origin = CGPointMake(lastPoint.x - TEXT_FIELD_HEIGHT*1.5, lastPoint.y - TEXT_FIELD_HEIGHT);
            _textView.frame = textFrame;
        }
        if ([touch locationInView:self.view].y + _textView.frame.size.height + keyBoardOffset > self.view.frame.size.height && !keyBoardShow) {
            [self.delegate keyboardWillShow:keyBoardOffset];
            keyBoardShow = YES;
        }
        
    }else if ([self.annotationType isEqualToString:AnnotationViewControllerType_ESign]) {
        _eSignImage.alpha = 1.0;
        _eSignImage.hidden = NO;
        _eSignImage.center = lastPoint;
    }else if ([self.annotationType isEqualToString:AnnotationViewControllerType_EPen]) {
        _ePenImage.alpha = 1.0;
//        _ePenImage.hidden = NO;
        _ePenImage.center = lastPoint;
    }else {
        if ([self.annotationType isEqualToString:AnnotationViewControllerType_Erase]) {
            eraseView.center = CGPointMake(lastPoint.x, lastPoint.y);
            eraseView.hidden = NO;
            [UIView animateWithDuration:1.0 animations:^{
                eraseView.layer.borderWidth = 2.0;
            } completion:^(BOOL finished) {
            }];
        }
        if (currPath) {
            [currentPaths addObject:[UIBezierPath bezierPathWithCGPath:currPath]];
        }
        currPath = CGPathCreateMutable();
        CGPathMoveToPoint(currPath, NULL, lastPoint.x, lastPoint.y);
    }
    
    didMove = NO;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    didMove = YES;
    UITouch *touch = [touches anyObject];
    //save previous contact locations
    lastContactPoint2 = lastContactPoint1;
    lastContactPoint1 = [touch previousLocationInView:pageView];
    
    //save current location
    currentPoint = [touch locationInView:pageView];
    
    if ([self.annotationType isEqualToString:AnnotationViewControllerType_Text]) {
//        _textView.center = lastContactPoint1;
        CGRect textFrame = _textView.frame;
        textFrame.origin = CGPointMake(lastPoint.x - TEXT_FIELD_HEIGHT*1.5, lastPoint.y - TEXT_FIELD_HEIGHT);
        _textView.frame = textFrame;
        
        if ([[UIDevice currentDevice] orientation] == 3 || [[UIDevice currentDevice] orientation] == 4) {
            keyBoardOffset = 216 + 94 + 30;
        }else
        {
            keyBoardOffset = 216 + 94;
        }
        // keyboard 弹出，视图上移
        if ([_textView isFirstResponder] && ([touch locationInView:self.view].y + _textView.frame.size.height + keyBoardOffset > [UIScreen mainScreen].bounds.size.height) && !keyBoardShow) {
            keyBoardHideOffset = keyBoardOffset;
            [self.delegate keyboardWillShow:keyBoardOffset];
            keyBoardShow = YES;
        }else{
            if ( ([touch locationInView:self.view].y + _textView.frame.size.height + keyBoardOffset < [UIScreen mainScreen].bounds.size.height) && keyBoardShow) {
                [self.delegate keyboardDidHidden:keyBoardHideOffset];
                keyBoardShow = NO;
            }
        }
    } else if ([self.annotationType isEqualToString:AnnotationViewControllerType_ESign]) {
        _eSignImage.center = lastContactPoint1;
    }else if ([self.annotationType isEqualToString:AnnotationViewControllerType_EPen]) {
        if ([touches count] == 1) {
            _ePenImage.center = lastContactPoint1;
        }
    }else {
        if ([self.annotationType isEqualToString:AnnotationViewControllerType_Erase]) {
            eraseView.center = CGPointMake(currentPoint.x, currentPoint.y);
        }
        
        //find mid points to be used for quadratic bezier curve
        CGPoint midPoint1 = [self midPoint:lastContactPoint1 withPoint:lastContactPoint2];
        CGPoint midPoint2 = [self midPoint:currentPoint withPoint:lastContactPoint1];
        
        //Update path
        //begin a new new subpath at this point
        CGPathAddLineToPoint(currPath, NULL, midPoint1.x, midPoint1.y);
        CGPathAddQuadCurveToPoint(currPath, NULL, lastContactPoint1.x, lastContactPoint1.y, midPoint2.x, midPoint2.y);
        [self refreshDrawing];
    }
    
    lastPoint = currentPoint;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    if ([self.annotationType isEqualToString:AnnotationViewControllerType_Text]) {
        if (_textView.frame.origin.x <0) {
            _textView.hidden = YES;
        }
        [self refreshDrawing];
        return;
    }
    if ([self.annotationType isEqualToString:AnnotationViewControllerType_ESign]) {
        _eSignImage.alpha = 0.0;
        [self refreshDrawing];
        return;
    }
    if ([self.annotationType isEqualToString:AnnotationViewControllerType_EPen]) {
        _ePenImage.alpha = 0.0;
        [self refreshDrawing];
        return;
    }
    if ([self.annotationType isEqualToString:AnnotationViewControllerType_Erase]) {
        [UIView animateWithDuration:1.0 animations:^{
            eraseView.layer.borderWidth = 0.1;
        } completion:^(BOOL finished) {
            eraseView.hidden = YES;
        }];
    }

    if (!didMove && ![self.annotationType isEqualToString:AnnotationViewControllerType_EPen]) {
        currentPoint = [touch locationInView:pageView];
        CGFloat penSize = [self.annotationType isEqualToString:AnnotationViewControllerType_Sign] ? BLACK_LINE_WIDTH : RED_LINE_WIDTH ;
        // One/Single point touch
        CGPathAddEllipseInRect(currPath, NULL, CGRectMake(currentPoint.x - penSize * 0.5, currentPoint.y - penSize * 0.5, penSize, penSize));
        [self refreshDrawing];
    }
    didMove = NO;
}

- (void)didReceiveMemoryWarning
{
#ifdef DEBUG
	NSLog(@"%s", __FUNCTION__);
#endif
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIImage *)getImageFromAnnotationsWithPage:(int)page
{
    UIGraphicsBeginImageContextWithOptions(pageView.frame.size, NO, 8.0f);//1.5f //保存时，调高像素比例；
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    MyLog(@"PageNum:%d. PageView Size:%@",page,NSStringFromCGSize(pageView.frame.size));
    
    //Draw previous paths
    [annotationStore drawAnnotationsForPage:page inContext:currentContext];
    
    //Saving
    UIImage *annotationImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return annotationImage;
}

//calculate midpoint between two points
- (CGPoint) midPoint:(CGPoint )p0 withPoint: (CGPoint) p1 {
    return (CGPoint) {
        (p0.x + p1.x) / 2.0,
        (p0.y + p1.y) / 2.0
    };
}

#pragma mark - UITextView Delegate
- (void)textViewDidChange:(UITextView *)textView
{
    // 获取原来的 frame
    CGRect tmpRect = _textView.frame;
    NSString *content = textView.text;
    NSArray *lineArray = [content componentsSeparatedByString:@"\n"];
    tmpRect.size.height = TEXT_FIELD_HEIGHT + _textView.font.pointSize*([lineArray count]-1);
    CGFloat maxWidth = TEXT_FIELD_WIDTH;
    for (NSString *str in lineArray) {
        CGFloat strWidth = [str sizeWithAttributes:@{NSFontAttributeName:textView.font}].width + 10;
        if (strWidth > maxWidth) {
            maxWidth = strWidth;
        }
    }
    if (maxWidth > TEXT_FIELD_WIDTH) {
        tmpRect.size.width = maxWidth;
    }
    if (maxWidth + tmpRect.origin.x > self.view.frame.size.width) {
        tmpRect.size.width = self.view.frame.size.width - tmpRect.origin.x - 100;
    }
    _textView.frame = tmpRect;
}

#pragma mark - WacomStylus Delegate
- (void)dismissViewControllerWithImage:(UIImageView *)signImageView
{
    if ([self.annotationType isEqualToString:AnnotationViewControllerType_EPen]) {
//        _eHandImage = signImageView;
//        CGFloat height = 35;
//        CGFloat width  = height * signImageView.frame.size.width / signImageView.frame.size.height;
        CGFloat height = signImageView.frame.size.height / 4.0;
        CGFloat width  = signImageView.frame.size.width / 4.0;
        _ePenImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        _ePenImage.image = signImageView.image;
        _ePenImage.center = pageView.center;
        [pageView addSubview:_ePenImage];
    }
}

#pragma mark - Keyboard will show with Text
- (void)observerKeyboardWillShow:(NSNotification *)notification
{
//    NSDictionary *info = [notification userInfo];
//    NSValue *value = [info objectForKey:UIKeyboardFrameBeginUserInfoKey];
//    CGSize keyboardSize = [value CGRectValue].size;
//    
//    CGFloat keyboardOffset = self.view.frame.size.height - _textView.frame.origin.y - _textView.frame.size.height - keyboardSize.height;
//    NSLog(@"keyBoard:%f,y:%f,height:%f,offset:%f", keyboardSize.height,_textView.frame.origin.y,_textView.frame.size.height,keyboardOffset);  //216
//    if (keyboardOffset > 0) {
//        [self.delegate keyboardWillShow: keyboardOffset];
//    }
}

- (void)observerKeyboardWasHidden:(NSNotification *)notification
{
    if (keyBoardShow) {
        [self.delegate keyboardDidHidden: keyBoardHideOffset];
        keyBoardShow = NO;
    }
}
@end
