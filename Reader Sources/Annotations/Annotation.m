//
//  Annotation.m
//	ThatPDF v0.3.1
//
//	Created by Brett van Zuiden.
//	Copyright © 2013 Ink. All rights reserved.
//

#import "Annotation.h"

@class Annotation;
@class CustomAnnotation;
@class TextAnnotation;
@class PathAnnotation;
@class ImageAnnotation;

@implementation Annotation

- (void) drawInContext:(CGContextRef) context {
    //Overridden
}

@end

@implementation CustomAnnotation
@synthesize block;
+ (id) customAnnotationWithBlock:(CustomAnnotationDrawingBlock)block {
    CustomAnnotation *ca = [[CustomAnnotation alloc] init];
    ca.block = block;
    return ca;
}

- (void) drawInContext:(CGContextRef)context {
    self.block(context);
}

@end;

@implementation TextAnnotation
@synthesize text;
@synthesize rect;
@synthesize font;

+ (id) textAnnotationWithText:(NSString *)text inRect:(CGRect)rect withFont:(UIFont*)font {
    TextAnnotation *ta = [[TextAnnotation alloc] init];
    ta.text = [text copy];
    ta.rect = rect;
    ta.font = font;
    return ta;
}

- (void) drawInContext:(CGContextRef)context {
    UIGraphicsPushContext(context);
    CGContextSetTextMatrix(context, CGAffineTransformMake(1.0,0.0, 0.0, -1.0, 0.0, 0.0));
    CGContextSetTextDrawingMode(context, kCGTextFill); // This is the default
    CGContextSetFillColorWithColor(context, [[UIColor blackColor] CGColor]);
    
    CGRect newTextFrame = self.rect;// 绘制text时，没有InSet边框，所以要改变其Frame才能与实际的坐标相同
    newTextFrame.origin.x += 5;
    newTextFrame.origin.y += 7.22;
//    CGFloat x = self.rect.origin.x;
//    CGFloat y = self.rect.origin.y + self.font.pointSize;
    [self.text drawInRect:newTextFrame withAttributes:@{NSFontAttributeName:self.font}];
    UIGraphicsPopContext();
}

@end

@implementation PathAnnotation
+ (id) pathAnnotationWithPath:(CGPathRef)path color:(CGColorRef)color fill:(BOOL)fill{
    return [PathAnnotation pathAnnotationWithPath:path color:color lineWidth:3.0 fill:fill];
}

+ (id) pathAnnotationWithPath:(CGPathRef)path color:(CGColorRef)color lineWidth:(CGFloat)width fill:(BOOL)fill {
    PathAnnotation *pa = [[PathAnnotation alloc] init];
    pa.path = CGPathRetain(path);//path;CGPathRetain(path)
    pa.color = color;
    pa.lineWidth = width;
    pa.fill = fill;
    return pa;
}

- (void) drawInContext:(CGContextRef)context {
    if (self.fill) {
        CGContextSetFillColorWithColor(context, self.color);
        CGContextFillPath(context);
    } else {
        if ([[UIColor colorWithCGColor:self.color] isEqual:[UIColor clearColor]]) {
            CGContextSetBlendMode(context, kCGBlendModeClear);
        }else
        {
            CGContextSetBlendMode(context, kCGBlendModeNormal);
            CGContextSetStrokeColorWithColor(context, self.color);
        }
        CGContextSetShouldAntialias(context, YES);
        CGContextSetAllowsAntialiasing(context, YES);
        CGContextSetLineJoin(context, kCGLineJoinRound);
        CGContextSetLineCap(context, kCGLineCapRound);
        CGContextSetMiterLimit(context, 2.0);
        
        CGContextSetLineWidth(context, self.lineWidth);
        //CGContextSetStrokeColorWithColor(context, self.color);
        CGContextAddPath(context, self.path);
        CGContextStrokePath(context);
    }
}
@end

@implementation ImageAnnotation

+ (id)imageAnnotationWithImage:(CGImageRef)imageRef inRect:(CGRect)rect withDate:(BOOL)hasDate {
    ImageAnnotation *im = [[ImageAnnotation alloc] init];
    im.imageRef = CGImageCreateCopy(imageRef);;//Crash: imageRef in future date will be released ,and app will be crashed;
    im.rect = rect;
    im.hasDate = hasDate;
    return im;
}

- (void) drawInContext:(CGContextRef)context
{
    CGContextSaveGState(context);
    
    CGContextTranslateCTM(context, self.rect.origin.x, self.rect.origin.y);
    CGContextTranslateCTM(context, 0, self.rect.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextTranslateCTM(context, -self.rect.origin.x, -self.rect.origin.y);
    CGContextDrawImage(context, self.rect, self.imageRef);
    
    CGContextRestoreGState(context);
    
    if (self.hasDate) {
        // Add Date
        UIGraphicsPushContext(context);
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy/M/d"];
        [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
        NSString *dateTime = [dateFormatter stringFromDate:[NSDate date]];
        CGRect dateFrame = CGRectMake(self.rect.origin.x + self.rect.size.width + 1, self.rect.origin.y + self.rect.size.height - 10, 80, 10);
        
        CGContextSetTextMatrix(context, CGAffineTransformMake(1.0,0.0, 0.0, -1.0, 0.0, 0.0));
        CGContextSetTextDrawingMode(context, kCGTextFill);
        CGContextSetFillColorWithColor(context, [[UIColor blackColor] CGColor]);
        @try {
                 [dateTime drawInRect:dateFrame withAttributes:nil ];
        }
        @catch (NSException *exception) {
            NSLog(@"%@",exception);
        }
        @finally {
            
            
        }
   
        UIGraphicsPopContext();
    }
}

@end