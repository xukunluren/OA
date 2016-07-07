//
//  OALayoutAttributes.m
//  OAOffice
//
//  Created by admin on 14-8-20.
//  Copyright (c) 2014年 DigitalOcean. All rights reserved.
//

#import "OALayoutAttributes.h"

@implementation OALayoutAttributes

- (id)init
{
    self = [super init];
    if (self) {
        _headerTextAlignment = NSTextAlignmentLeft;
        _shadowOpacity = 0.5;
    }
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    OALayoutAttributes *newAttributes = [super copyWithZone:zone];
    newAttributes.headerTextAlignment = self.headerTextAlignment;
    newAttributes.shadowOpacity = self.shadowOpacity;
    return newAttributes;
}

/*+ (instancetype)layoutAttributesForCellWithIndexPath:(NSIndexPath *)indexPath
 {
 ConferenceLayoutAttributes *attributes = [[ConferenceLayoutAttributes alloc] init];
 attributes->_representedElementCategory = UICollectionElementCategoryCell;
 return attributes;
 }
 
 + (instancetype)layoutAttributesForDecorationViewOfKind:(NSString *)decorationViewKind withIndexPath:(NSIndexPath*)indexPath
 {
 ConferenceLayoutAttributes *attributes = [[ConferenceLayoutAttributes alloc] init];
 return attributes;
 }
 
 + (instancetype)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind withIndexPath:(NSIndexPath *)indexPath
 {
 ConferenceLayoutAttributes *attributes = [[ConferenceLayoutAttributes alloc] init];
 return attributes;
 }*/


@end
