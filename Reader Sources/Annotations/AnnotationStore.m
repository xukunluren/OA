//
//  AnnotationStore.m
//	ThatPDF v0.3.1
//
//	Created by Brett van Zuiden.
//	Copyright © 2013 Ink. All rights reserved.
//
// Stores information about annotations on a document

#import "AnnotationStore.h"
#import "Annotation.h"

@implementation AnnotationStore {
    //Array (by page number) of arrays (annotations for that page - each page is a queue (most recent at end)
    NSArray *annotations;
}


- (id)initWithPageCount:(int)page_count {
    NSMutableArray *tmp = [NSMutableArray arrayWithCapacity:page_count];
    for (int i = 0; i < page_count; i++) {
        [tmp addObject:[NSMutableArray array]];
    }
    annotations = [NSArray arrayWithArray:tmp];
    return self;
}

- (void) addAnnotation:(Annotation*)annotation toPage:(int)page {
    NSMutableArray *pageAnnotations = [annotations objectAtIndex:(page-1)];
    //Each page is a queue, first annotation at 0
    [pageAnnotations addObject:annotation];
//    [[annotations objectAtIndex:(page-1)] addObject:annotation];
}

- (void) addPath:(CGPathRef)path withColor:(CGColorRef)color lineWidth:(CGFloat)width fill:(BOOL)fill toPage:(int)page {
    [self addAnnotation:[PathAnnotation pathAnnotationWithPath:path color:color lineWidth:width fill:fill] toPage:page];
}

- (void) addPath:(CGPathRef)path withColor:(CGColorRef)color fill:(BOOL)fill toPage:(int)page {
    [self addAnnotation:[PathAnnotation pathAnnotationWithPath:path color:color fill:fill] toPage:page];
}

- (void) addText:(NSString*)text inRect:(CGRect)rect withFont:(UIFont*)font toPage:(int)page {
    [self addAnnotation:[TextAnnotation textAnnotationWithText:text inRect:rect withFont:font] toPage:page];
}

- (void) addCustomAnnotationWithBlock:(CustomAnnotationDrawingBlock)block toPage:(int)page {
    [self addAnnotation:[CustomAnnotation customAnnotationWithBlock:block] toPage:page];
}

- (void) addImage:(CGImageRef)imageRef inRect:(CGRect)rect withDate:(BOOL)hasDate toPage:(int)page {
    [self addAnnotation:[ImageAnnotation imageAnnotationWithImage:imageRef inRect:rect withDate:hasDate] toPage:page];
}

- (void) addAnnotations:(AnnotationStore *)newAnnotations {
    int count = (int)[annotations count];
    for (int page = 1; page <= count; page++) {
        NSMutableArray *pageAnnotations = [annotations objectAtIndex:(page - 1)];
        NSArray *onePageAnnotation = [newAnnotations annotationsForPage:page];
        if ([onePageAnnotation count] > 0) {
            [pageAnnotations addObjectsFromArray:onePageAnnotation];
        }
    }
}

- (void) undoAnnotationOnPage:(int)page {
    if (page - 1 >= [annotations count]) {
        return;
    }
    
    NSMutableArray* pageAnnotations = [annotations objectAtIndex:(page-1)];
    if ([pageAnnotations count] > 0) {
        [pageAnnotations removeLastObject];
    }
}

- (void)empty {
    int count = (int)[annotations count];
    NSMutableArray *tmp = [NSMutableArray arrayWithCapacity:count];
    for (int i = 0; i < count; i++) {
        [tmp addObject:[NSMutableArray array]];
    }
    annotations = [NSArray arrayWithArray:tmp];
}

- (NSArray*) annotationsForPage:(int )page {
    if (page - 1 >= [annotations count]) {
//        NSLog(@"We wanted index %d but only have %lu items", page - 1 , (unsigned long)[annotations count]);
        return [NSArray array];
    }
    return [annotations objectAtIndex:(page-1)];
}

- (void) drawAnnotationsForPage:(int)page inContext:(CGContextRef) context {
    NSArray *pageAnnotations = [self annotationsForPage:page];
    if (!pageAnnotations) {
        return;
    }
    for (Annotation *anno in pageAnnotations) {
        [anno drawInContext:context];
    }
}

@end
