//
//  ReaderAnnotateToolbar.m
//	ThatPDF v0.3.1
//
//	Created by Brett van Zuiden.
//	Copyright © 2013 Ink. All rights reserved.
//

#import "ReaderAnnotateToolbar.h"

#pragma mark Constants

#define BUTTON_X 8.0f
#define BUTTON_Y 8.0f
#define BUTTON_SPACE 8.0f
#define BUTTON_HEIGHT 32.0f

//#define DONE_BUTTON_WIDTH 56.0f
//#define CANCEL_BUTTON_WIDTH 56.0f
#define DONE_BUTTON_WIDTH       40.0f
#define CANCEL_BUTTON_WIDTH     40.0f
#define RED_PEN_BUTTON_WIDTH    40.0f
#define SIGN_BUTTON_WIDTH       40.0f
#define TEXT_BUTTON_WIDTH       40.0f
#define ERASE_BUTTON_WIDTH      40.0f
#define ESign_BUTTON_WIDTH      40.0f
#define EPen_BUTTON_WIDTH       40.0f

#define UNDO_BUTTON_WIDTH       40.0f

#define TITLE_HEIGHT 28.0f

@implementation ReaderAnnotateToolbar {
    UIButton *signButton;
    UIButton *redPenButton;
    UIButton *textButton;
    UIButton *eraseButton;
    UIButton *eSignButton;
    UIButton *undoButton;
    UIButton *ePenButton;
    
    UIImage *buttonH;
    UIImage *buttonN;
}

#pragma mark Properties

@synthesize delegate;
@synthesize titleLabel;

#pragma mark ReaderAnnotateToolbar instance methods

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
		CGFloat viewWidth = self.bounds.size.width;
        
		UIImage *imageH = [UIImage imageNamed:@"Reader-Button-H"];
		UIImage *imageN = [UIImage imageNamed:@"Reader-Button-N"];
        
		buttonH = [imageH stretchableImageWithLeftCapWidth:5 topCapHeight:0];
		buttonN = [imageN stretchableImageWithLeftCapWidth:5 topCapHeight:0];
        
		CGFloat titleX = BUTTON_X;
        CGFloat titleWidth = (viewWidth - (titleX + titleX));
        
		CGFloat leftButtonX = BUTTON_X; // Left button start X position
        
		UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
		cancelButton.frame = CGRectMake(leftButtonX, BUTTON_Y, CANCEL_BUTTON_WIDTH, BUTTON_HEIGHT);
//        [cancelButton setTitle:NSLocalizedString(@"取消", @"button") forState:UIControlStateNormal];
        [cancelButton setImage:[UIImage imageNamed:@"Reader-Cancel"] forState:UIControlStateNormal];
		[cancelButton setTitleColor:[UIColor colorWithWhite:1.0f alpha:1.0f] forState:UIControlStateNormal];
		[cancelButton setTitleColor:[UIColor colorWithWhite:0.0f alpha:0.5f] forState:UIControlStateHighlighted];
      [cancelButton setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
//      [cancelButton setTitle:@"取消" forState:UIControlStateNormal];
        cancelButton.layer.cornerRadius = 5;
        cancelButton.clipsToBounds = YES;
//        cancelButton.layer.borderColor = [UIColor whiteColor].CGColor;
//        cancelButton.layer.borderWidth = 1;
		[cancelButton addTarget:self action:@selector(cancelButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
		[cancelButton setBackgroundImage:buttonH forState:UIControlStateHighlighted];
		[cancelButton setBackgroundImage:buttonN forState:UIControlStateNormal];
		cancelButton.titleLabel.font = [UIFont systemFontOfSize:20.0f];
		cancelButton.autoresizingMask = UIViewAutoresizingNone;
		cancelButton.exclusiveTouch = YES;
        
		[self addSubview:cancelButton];
        
        leftButtonX += (CANCEL_BUTTON_WIDTH + BUTTON_SPACE);
        
		titleX += (CANCEL_BUTTON_WIDTH + BUTTON_SPACE);
        titleWidth -= (CANCEL_BUTTON_WIDTH + BUTTON_SPACE);
        
        //Give the undo some padding
//        titleX += BUTTON_SPACE * 2;
//        leftButtonX += BUTTON_SPACE * 2;
        
        undoButton = [UIButton buttonWithType:UIButtonTypeCustom];
		undoButton.frame = CGRectMake(leftButtonX, BUTTON_Y, UNDO_BUTTON_WIDTH, BUTTON_HEIGHT);
//        [undoButton setTitle:NSLocalizedString(@"撤销", @"button") forState:UIControlStateNormal];
        [undoButton setImage:[UIImage imageNamed:@"Reader-Reply"] forState:UIControlStateNormal];
        [undoButton setTitleColor:[UIColor colorWithWhite:1.0f alpha:1.0f] forState:UIControlStateNormal];
		[undoButton setTitleColor:[UIColor colorWithWhite:0.0f alpha:0.5f] forState:UIControlStateHighlighted];
		[undoButton addTarget:self action:@selector(undoButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
//        [undoButton setTitle:@"重签" forState:UIControlStateNormal];
        undoButton.layer.cornerRadius = 5;
        undoButton.clipsToBounds = YES;
//        undoButton.layer.borderColor = [UIColor whiteColor].CGColor;
//        undoButton.layer.borderWidth = 1;
        
		[undoButton setBackgroundImage:buttonH forState:UIControlStateHighlighted];
		[undoButton setBackgroundImage:buttonN forState:UIControlStateNormal];
		undoButton.titleLabel.font = [UIFont systemFontOfSize:20.0f];
		undoButton.autoresizingMask = UIViewAutoresizingNone;
		undoButton.exclusiveTouch = YES;
        //Default enabled because we don't manage state yet
        //undoButton.enabled = NO;
        
		[self addSubview:undoButton];
        leftButtonX += (UNDO_BUTTON_WIDTH + BUTTON_SPACE);
        
        
        // 撤销功能
//        undoButton = [UIButton buttonWithType:UIButtonTypeCustom];
//		undoButton.frame = CGRectMake(leftButtonX, BUTTON_Y, UNDO_BUTTON_WIDTH, BUTTON_HEIGHT);
////        [undoButton setTitle:NSLocalizedString(@"撤销", @"button") forState:UIControlStateNormal];
//        [undoButton setImage:[UIImage imageNamed:@"Reader-Reply"] forState:UIControlStateNormal];
//        [undoButton setTitleColor:[UIColor colorWithWhite:1.0f alpha:1.0f] forState:UIControlStateNormal];
//		[undoButton setTitleColor:[UIColor colorWithWhite:0.0f alpha:0.5f] forState:UIControlStateHighlighted];
//		[undoButton addTarget:self action:@selector(undoButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
//        [undoButton setTitle:@"撤销" forState:UIControlStateNormal];
//        undoButton.layer.cornerRadius = 5;
//        undoButton.clipsToBounds = YES;
//        undoButton.layer.borderColor = [UIColor whiteColor].CGColor;
//        undoButton.layer.borderWidth = 1;
//        
//        
//		[undoButton setBackgroundImage:buttonH forState:UIControlStateHighlighted];
//		[undoButton setBackgroundImage:buttonN forState:UIControlStateNormal];
//		undoButton.titleLabel.font = [UIFont systemFontOfSize:20.0f];
//		undoButton.autoresizingMask = UIViewAutoresizingNone;
//		undoButton.exclusiveTouch = YES;
//        //Default enabled because we don't manage state yet
//        //undoButton.enabled = NO;
//        
//		[self addSubview:undoButton];
//        leftButtonX += (UNDO_BUTTON_WIDTH + BUTTON_SPACE);
        
        
//        rightButtonX -= (RED_PEN_BUTTON_WIDTH + BUTTON_SPACE);
        
//        // 擦除功能
//        eraseButton = [UIButton buttonWithType:UIButtonTypeCustom];
//        
//        eraseButton.frame = CGRectMake(leftButtonX, BUTTON_Y, ERASE_BUTTON_WIDTH, BUTTON_HEIGHT);
//        [eraseButton setImage:[UIImage imageNamed:@"Reader-Erase"] forState:UIControlStateNormal];
//        [eraseButton addTarget:self action:@selector(eraseButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
//        
//        [eraseButton setTitle:@"擦除" forState:UIControlStateNormal];
//        eraseButton.layer.cornerRadius = 5;
//        eraseButton.clipsToBounds = YES;
//        eraseButton.layer.borderColor = [UIColor whiteColor].CGColor;
//        eraseButton.layer.borderWidth = 1;
//        eraseButton.titleLabel.font = [UIFont systemFontOfSize:20.0f];
//        
//        [eraseButton setTitleColor:[UIColor colorWithWhite:1.0f alpha:1.0f] forState:UIControlStateNormal];
//		[eraseButton setTitleColor:[UIColor colorWithWhite:0.0f alpha:0.5f] forState:UIControlStateHighlighted];
//        eraseButton.autoresizingMask = UIViewAutoresizingNone;
//        eraseButton.exclusiveTouch = YES;
//        
//        [self addSubview:eraseButton];
//        titleWidth -= (ERASE_BUTTON_WIDTH + BUTTON_SPACE);
        
//        // 功能
//        eSignButton = [UIButton buttonWithType:UIButtonTypeCustom];
//        
//        eSignButton.frame = CGRectMake(leftButtonX, BUTTON_Y, ESign_BUTTON_WIDTH, BUTTON_HEIGHT);
//        [eSignButton setImage:[UIImage imageNamed:@"Reader-ESign"] forState:UIControlStateNormal];
//        [eSignButton addTarget:self action:@selector(eSignButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
//        
////        [eSignButton setTitle:@"" forState:UIControlStateNormal];
//        eSignButton.layer.cornerRadius = 5;
//        eSignButton.clipsToBounds = YES;
////        eSignButton.layer.borderColor = [UIColor whiteColor].CGColor;
////        eSignButton.layer.borderWidth = 1;
//        eSignButton.titleLabel.font = [UIFont systemFontOfSize:20.0f];
//        
//        [eSignButton setTitleColor:[UIColor colorWithWhite:1.0f alpha:1.0f] forState:UIControlStateNormal];
//        [eSignButton setTitleColor:[UIColor colorWithWhite:0.0f alpha:0.5f] forState:UIControlStateHighlighted];
//        eSignButton.autoresizingMask = UIViewAutoresizingNone;
//        eSignButton.exclusiveTouch = YES;
//        
//        [self addSubview:eSignButton];
//        titleWidth -= (ESign_BUTTON_WIDTH + BUTTON_SPACE);
        
        
        
        
        //right side
        CGFloat rightButtonX = viewWidth; // Right button start X position
        
        rightButtonX -= (DONE_BUTTON_WIDTH + BUTTON_SPACE);
        
        UIButton *doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        doneButton.frame = CGRectMake(rightButtonX, BUTTON_Y, DONE_BUTTON_WIDTH, BUTTON_HEIGHT);
//        [doneButton setTitle:NSLocalizedString(@"完成", @"button") forState:UIControlStateNormal];
        [doneButton setImage:[UIImage imageNamed:@"Reader-Complete"] forState:UIControlStateNormal];
		[doneButton setTitleColor:[UIColor colorWithWhite:1.0f alpha:1.0f] forState:UIControlStateNormal];
		[doneButton setTitleColor:[UIColor colorWithWhite:0.0f alpha:0.5f] forState:UIControlStateHighlighted];
		[doneButton addTarget:self action:@selector(doneButtonAnnotateTapped:) forControlEvents:UIControlEventTouchUpInside];
        
//        [doneButton setTitle:@"保存" forState:UIControlStateNormal];
        doneButton.layer.cornerRadius = 5;
        doneButton.clipsToBounds = YES;
//        doneButton.layer.borderColor = [UIColor whiteColor].CGColor;
//        doneButton.layer.borderWidth = 1;
        
		[doneButton setBackgroundImage:buttonH forState:UIControlStateHighlighted];
		[doneButton setBackgroundImage:buttonN forState:UIControlStateNormal];
		doneButton.titleLabel.font = [UIFont systemFontOfSize:20.0f];
        
        doneButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        doneButton.exclusiveTouch = YES;
        
        [self addSubview:doneButton];
        titleWidth -= (DONE_BUTTON_WIDTH + BUTTON_SPACE);
        
        rightButtonX -= (SIGN_BUTTON_WIDTH + BUTTON_SPACE);
        
        signButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        signButton.frame = CGRectMake(rightButtonX, BUTTON_Y, SIGN_BUTTON_WIDTH, BUTTON_HEIGHT);
        [signButton setImage:[UIImage imageNamed:@"Reader-Sign"] forState:UIControlStateNormal];
//        [signButton setImage:[UIImage imageNamed:@"Reader-Sign-Selected"] forState:UIControlStateSelected];
        [signButton addTarget:self action:@selector(signButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        
//        [signButton setTitle:@"黑笔" forState:UIControlStateNormal];
        signButton.layer.cornerRadius = 5;
        signButton.clipsToBounds = YES;
//        signButton.layer.borderColor = [UIColor whiteColor].CGColor;
//        signButton.layer.borderWidth = 1;
        signButton.titleLabel.font = [UIFont systemFontOfSize:20.0f];
        
        [signButton setBackgroundImage:buttonH forState:UIControlStateHighlighted];
        [signButton setBackgroundImage:buttonN forState:UIControlStateNormal];
        [signButton setTitleColor:[UIColor colorWithWhite:1.0f alpha:1.0f] forState:UIControlStateNormal];
		[signButton setTitleColor:[UIColor colorWithWhite:0.0f alpha:0.5f] forState:UIControlStateHighlighted];
        
        signButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        signButton.exclusiveTouch = YES;
        
        [self addSubview:signButton];
        titleWidth   -= (SIGN_BUTTON_WIDTH + BUTTON_SPACE);
        rightButtonX -= (SIGN_BUTTON_WIDTH + BUTTON_SPACE);
        // 红笔签写
//        rightButtonX -= (RED_PEN_BUTTON_WIDTH + BUTTON_SPACE);
//        
//        redPenButton = [UIButton buttonWithType:UIButtonTypeCustom];
//        
//        redPenButton.frame = CGRectMake(rightButtonX, BUTTON_Y, RED_PEN_BUTTON_WIDTH, BUTTON_HEIGHT);
//        [redPenButton setImage:[UIImage imageNamed:@"Reader-RedPen"] forState:UIControlStateNormal];
////        [redPenButton setImage:[UIImage imageNamed:@"Reader-RedPen-Selected"] forState:UIControlStateNormal];
//        [redPenButton addTarget:self action:@selector(redPenButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
//        
//        [redPenButton setTitle:@"红笔" forState:UIControlStateNormal];
//        redPenButton.layer.cornerRadius = 5;
//        redPenButton.clipsToBounds = YES;
//        redPenButton.layer.borderColor = [UIColor whiteColor].CGColor;
//        redPenButton.layer.borderWidth = 1;
//        redPenButton.titleLabel.font = [UIFont systemFontOfSize:20.0f];
//        
////        [redPenButton setBackgroundImage:buttonH forState:UIControlStateHighlighted];
////        [redPenButton setBackgroundImage:buttonN forState:UIControlStateNormal];
//        [redPenButton setTitleColor:[UIColor colorWithWhite:1.0f alpha:1.0f] forState:UIControlStateNormal];
//		[redPenButton setTitleColor:[UIColor colorWithWhite:0.0f alpha:0.5f] forState:UIControlStateHighlighted];
//        redPenButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
//        redPenButton.exclusiveTouch = YES;
//        
//        [self addSubview:redPenButton];
//        titleWidth -= (RED_PEN_BUTTON_WIDTH + BUTTON_SPACE);
//        rightButtonX -= (RED_PEN_BUTTON_WIDTH + BUTTON_SPACE);
        
        textButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        textButton.frame = CGRectMake(rightButtonX, BUTTON_Y, TEXT_BUTTON_WIDTH, BUTTON_HEIGHT);
        [textButton setImage:[UIImage imageNamed:@"Reader-Text"] forState:UIControlStateNormal];
        [textButton addTarget:self action:@selector(textButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        
//        [textButton setTitle:@"标注" forState:UIControlStateNormal];
        textButton.layer.cornerRadius = 5;
        textButton.clipsToBounds = YES;
//        textButton.layer.borderColor = [UIColor whiteColor].CGColor;
//        textButton.layer.borderWidth = 1;
        textButton.titleLabel.font = [UIFont systemFontOfSize:20.0f];
        
        [textButton setBackgroundImage:buttonH forState:UIControlStateHighlighted];
        [textButton setBackgroundImage:buttonN forState:UIControlStateNormal];
        [textButton setTitleColor:[UIColor colorWithWhite:1.0f alpha:1.0f] forState:UIControlStateNormal];
		[textButton setTitleColor:[UIColor colorWithWhite:0.0f alpha:0.5f] forState:UIControlStateHighlighted];
        textButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        textButton.exclusiveTouch = YES;
        
        [self addSubview:textButton];
        titleWidth   -= (TEXT_BUTTON_WIDTH + BUTTON_SPACE);
        rightButtonX -= (TEXT_BUTTON_WIDTH + BUTTON_SPACE);
        
        // 电子签名图片添加功能
        eSignButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        eSignButton.frame = CGRectMake(rightButtonX, BUTTON_Y, ESign_BUTTON_WIDTH, BUTTON_HEIGHT);
        [eSignButton setImage:[UIImage imageNamed:@"Reader-ESign"] forState:UIControlStateNormal];
        [eSignButton addTarget:self action:@selector(eSignButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        //        [eSignButton setTitle:@"" forState:UIControlStateNormal];
        eSignButton.layer.cornerRadius = 5;
        eSignButton.clipsToBounds = YES;
        //        eSignButton.layer.borderColor = [UIColor whiteColor].CGColor;
        //        eSignButton.layer.borderWidth = 1;
        eSignButton.titleLabel.font = [UIFont systemFontOfSize:20.0f];
        
        [eSignButton setTitleColor:[UIColor colorWithWhite:1.0f alpha:1.0f] forState:UIControlStateNormal];
        [eSignButton setTitleColor:[UIColor colorWithWhite:0.0f alpha:0.5f] forState:UIControlStateHighlighted];
        eSignButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        eSignButton.exclusiveTouch = YES;

        [self addSubview:eSignButton];
        titleWidth   -= (ESign_BUTTON_WIDTH + BUTTON_SPACE);
        rightButtonX -= (ESign_BUTTON_WIDTH + BUTTON_SPACE);
        
        // 电子笔功能
        ePenButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        ePenButton.frame = CGRectMake(rightButtonX, BUTTON_Y, EPen_BUTTON_WIDTH, BUTTON_HEIGHT);
        [ePenButton setImage:[UIImage imageNamed:@"Reader-EPen"] forState:UIControlStateNormal];
        [ePenButton addTarget:self action:@selector(ePenButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
//        [eSignButton setTitle:@"" forState:UIControlStateNormal];
        ePenButton.layer.cornerRadius = 5;
        ePenButton.clipsToBounds = YES;
//        eSignButton.layer.borderColor = [UIColor whiteColor].CGColor;
//        eSignButton.layer.borderWidth = 1;
//        ePenButton.titleLabel.font = [UIFont systemFontOfSize:20.0f];
        [ePenButton setTitleColor:[UIColor colorWithWhite:1.0f alpha:1.0f] forState:UIControlStateNormal];
        [ePenButton setTitleColor:[UIColor colorWithWhite:0.0f alpha:0.5f] forState:UIControlStateHighlighted];
        ePenButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        ePenButton.exclusiveTouch = YES;
       //        占时去掉手写笔的功能      
//        [self addSubview:ePenButton];
        titleWidth   -= (EPen_BUTTON_WIDTH + BUTTON_SPACE);
        rightButtonX -= (EPen_BUTTON_WIDTH + BUTTON_SPACE);
        
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
		{
			CGRect titleRect = CGRectMake(titleX, BUTTON_Y, titleWidth, TITLE_HEIGHT);
            
			self.titleLabel = [[UILabel alloc] initWithFrame:titleRect];
            
			self.titleLabel.textAlignment = NSTextAlignmentCenter;
			self.titleLabel.font = [UIFont systemFontOfSize:24.0f];//19.0f
			self.titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
			self.titleLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
			self.titleLabel.textColor = [UIColor colorWithWhite:1.0f alpha:1.0f];
			self.titleLabel.shadowColor = [UIColor colorWithWhite:0.65f alpha:1.0f];
			self.titleLabel.backgroundColor = [UIColor clearColor];
			self.titleLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
			self.titleLabel.adjustsFontSizeToFitWidth = YES;
			self.titleLabel.minimumScaleFactor = 14.0f/19.f;
//			titleLabel.text = @"添加批注";//@"Add annotations";
            self.titleLabel.center = CGPointMake(self.bounds.size.width * 0.5, self.bounds.origin.y + self.bounds.size.height * 0.5);
            
			[self addSubview:self.titleLabel];
		}
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)hideToolbar
{
	if (self.hidden == NO)
	{
		[UIView animateWithDuration:0.25 delay:0.0
                            options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction
                         animations:^(void)
         {
             self.alpha = 0.0f;
         }
                         completion:^(BOOL finished)
         {
             self.hidden = YES;
         }
         ];
	}
}

- (void)showToolbar
{
	if (self.hidden == YES)
	{        
		[UIView animateWithDuration:0.25 delay:0.0
                            options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction
                         animations:^(void)
         {
             self.hidden = NO;
             self.alpha = 1.0f;
         }
                         completion:NULL
         ];
	}
}

- (void)setUndoButtonState:(BOOL)state {
    undoButton.enabled = state;
}

- (void)setSignButtonState:(BOOL)state {
    UIImage *image = (state ? buttonH : buttonN);
    [signButton setBackgroundImage:image forState:UIControlStateNormal];
    
    if (state) {
        [signButton setImage:[UIImage imageNamed:@"Reader-Sign-Selected"] forState:UIControlStateNormal];
        [redPenButton setImage:[UIImage imageNamed:@"Reader-RedPen"] forState:UIControlStateNormal];
        [eraseButton setImage:[UIImage imageNamed:@"Reader-Erase"] forState:UIControlStateNormal];
        [textButton setImage:[UIImage imageNamed:@"Reader-Text"] forState:UIControlStateNormal];
        [eSignButton setImage:[UIImage imageNamed:@"Reader-ESign"] forState:UIControlStateNormal];
        
        signButton.backgroundColor = [UIColor whiteColor];
        redPenButton.backgroundColor = [UIColor clearColor];
        eraseButton.backgroundColor = [UIColor clearColor];
        textButton.backgroundColor = [UIColor clearColor];
        eSignButton.backgroundColor = [UIColor clearColor];
    }else
    {
        [signButton setImage:[UIImage imageNamed:@"Reader-Sign"] forState:UIControlStateNormal];
        signButton.backgroundColor = [UIColor clearColor];
    }
}

- (void)setRedPenButtonState:(BOOL)state {
    UIImage *image = (state ? buttonH : buttonN);
    [redPenButton setBackgroundImage:image forState:UIControlStateNormal];
    
    if (state) {
        [redPenButton setImage:[UIImage imageNamed:@"Reader-RedPen-Selected"] forState:UIControlStateNormal];
        [signButton setImage:[UIImage imageNamed:@"Reader-Sign"] forState:UIControlStateNormal];
        [eraseButton setImage:[UIImage imageNamed:@"Reader-Erase"] forState:UIControlStateNormal];
        [textButton setImage:[UIImage imageNamed:@"Reader-Text"] forState:UIControlStateNormal];
        [eSignButton setImage:[UIImage imageNamed:@"Reader-ESign"] forState:UIControlStateNormal];
        
        signButton.backgroundColor = [UIColor clearColor];
        redPenButton.backgroundColor = [UIColor whiteColor];
        eraseButton.backgroundColor = [UIColor clearColor];
        textButton.backgroundColor = [UIColor clearColor];
        eSignButton.backgroundColor = [UIColor clearColor];
    }else
    {
        [redPenButton setImage:[UIImage imageNamed:@"Reader-RedPen"] forState:UIControlStateNormal];
        redPenButton.backgroundColor = [UIColor clearColor];
    }
}

- (void)setTextButtonState:(BOOL)state {
    UIImage *image = (state ? buttonH : buttonN);
    [textButton setBackgroundImage:image forState:UIControlStateNormal];
    if (state) {
        [textButton setImage:[UIImage imageNamed:@"Reader-Text-Selected"] forState:UIControlStateNormal];
        [signButton setImage:[UIImage imageNamed:@"Reader-Sign"] forState:UIControlStateNormal];
        [eraseButton setImage:[UIImage imageNamed:@"Reader-Erase"] forState:UIControlStateNormal];
        [redPenButton setImage:[UIImage imageNamed:@"Reader-RedPen"] forState:UIControlStateNormal];
        [eSignButton setImage:[UIImage imageNamed:@"Reader-ESign"] forState:UIControlStateNormal];
        
        signButton.backgroundColor = [UIColor clearColor];
        redPenButton.backgroundColor = [UIColor clearColor];
        eraseButton.backgroundColor = [UIColor clearColor];
        textButton.backgroundColor = [UIColor whiteColor];
        eSignButton.backgroundColor = [UIColor clearColor];
    }else{
        [textButton setImage:[UIImage imageNamed:@"Reader-Text"] forState:UIControlStateNormal];
        textButton.backgroundColor = [UIColor clearColor];
    }
    
}

- (void)setESignButtonState:(BOOL)state {
    UIImage *image = (state ? buttonH : buttonN);
    [eSignButton setBackgroundImage:image forState:UIControlStateNormal];
    if (state) {
        [eSignButton setImage:[UIImage imageNamed:@"Reader-ESign-Selected"] forState:UIControlStateNormal];
        [signButton setImage:[UIImage imageNamed:@"Reader-Sign"] forState:UIControlStateNormal];
        [eraseButton setImage:[UIImage imageNamed:@"Reader-Erase"] forState:UIControlStateNormal];
        [redPenButton setImage:[UIImage imageNamed:@"Reader-RedPen"] forState:UIControlStateNormal];
        [textButton setImage:[UIImage imageNamed:@"Reader-Text"] forState:UIControlStateNormal];
        
        signButton.backgroundColor = [UIColor clearColor];
        redPenButton.backgroundColor = [UIColor clearColor];
        eraseButton.backgroundColor = [UIColor clearColor];
        textButton.backgroundColor = [UIColor clearColor];
        eSignButton.backgroundColor = [UIColor whiteColor];
    }else{
        [eSignButton setImage:[UIImage imageNamed:@"Reader-ESign"] forState:UIControlStateNormal];
        eSignButton.backgroundColor = [UIColor clearColor];
    }
    
}

- (void)setEraseButtonState:(BOOL)state
{
    UIImage *image = (state ? buttonH : buttonN);
    [eraseButton setBackgroundImage:image forState:UIControlStateNormal];
    
    if (state) {
        [eraseButton setImage:[UIImage imageNamed:@"Reader-Erase-Selected"] forState:UIControlStateNormal];
        [redPenButton setImage:[UIImage imageNamed:@"Reader-RedPen"] forState:UIControlStateNormal];
        [signButton setImage:[UIImage imageNamed:@"Reader-Sign"] forState:UIControlStateNormal];
        [textButton setImage:[UIImage imageNamed:@"Reader-Text"] forState:UIControlStateNormal];
        [eSignButton setImage:[UIImage imageNamed:@"Reader-ESign"] forState:UIControlStateNormal];
        
        signButton.backgroundColor = [UIColor clearColor];
        redPenButton.backgroundColor = [UIColor clearColor];
        eraseButton.backgroundColor = [UIColor whiteColor];
        textButton.backgroundColor = [UIColor clearColor];
        eSignButton.backgroundColor = [UIColor clearColor];
    }else
    {
        [eraseButton setImage:[UIImage imageNamed:@"Reader-Erase"] forState:UIControlStateNormal];
        eraseButton.backgroundColor = [UIColor clearColor];
    }
}

- (void)setEPenButtonState:(BOOL)state
{
    UIImage *image = (state ? buttonH : buttonN);
    [ePenButton setBackgroundImage:image forState:UIControlStateNormal];
    
    if (state) {
        [ePenButton setImage:[UIImage imageNamed:@"Reader-EPen-Selected"] forState:UIControlStateNormal];
        [eraseButton setImage:[UIImage imageNamed:@"Reader-Erase"] forState:UIControlStateNormal];
        [redPenButton setImage:[UIImage imageNamed:@"Reader-RedPen"] forState:UIControlStateNormal];
        [signButton setImage:[UIImage imageNamed:@"Reader-Sign"] forState:UIControlStateNormal];
        [textButton setImage:[UIImage imageNamed:@"Reader-Text"] forState:UIControlStateNormal];
        [eSignButton setImage:[UIImage imageNamed:@"Reader-ESign"] forState:UIControlStateNormal];
        
        signButton.backgroundColor = [UIColor clearColor];
        redPenButton.backgroundColor = [UIColor clearColor];
        eraseButton.backgroundColor = [UIColor clearColor];
        textButton.backgroundColor = [UIColor clearColor];
        eSignButton.backgroundColor = [UIColor clearColor];
        ePenButton.backgroundColor = [UIColor whiteColor];
    }else
    {
        [ePenButton setImage:[UIImage imageNamed:@"Reader-EPen"] forState:UIControlStateNormal];
        ePenButton.backgroundColor = [UIColor clearColor];
    }
}

#pragma mark UIButton action methods

- (void)doneButtonAnnotateTapped:(UIButton *)button
{
	[delegate tappedInAnnotateToolbar:self doneButton:button];
}

- (void)cancelButtonTapped:(UIButton *)button
{
	[delegate tappedInAnnotateToolbar:self cancelButton:button];
}

- (void)undoButtonTapped:(UIButton *)button
{
	[delegate tappedInAnnotateToolbar:self undoButton:button];
}

- (void)signButtonTapped:(UIButton *)button
{
	[delegate tappedInAnnotateToolbar:self signButton:button];
}

- (void)redPenButtonTapped:(UIButton *)button
{
	[delegate tappedInAnnotateToolbar:self redPenButton:button];
}

- (void)textButtonTapped:(UIButton *)button
{
	[delegate tappedInAnnotateToolbar:self textButton:button];
}

- (void)eraseButtonTapped:(UIButton *)button
{
	[delegate tappedInAnnotateToolbar:self eraseButton:button];
}

- (void)eSignButtonTapped:(UIButton *)button
{
    [delegate tappedInAnnotateToolbar:self eSignButton:button];
}

- (void)ePenButtonTapped:(UIButton *)button
{
    [delegate tappedInAnnotateToolbar:self ePenButton:button];
}
@end
