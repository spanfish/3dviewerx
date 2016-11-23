//
//  IntegerTransformer.m
//  3DViewerX
//
//  Created by Xiangwei Wang on 10/28/16.
//  Copyright © 2016 xiangwei wang. All rights reserved.
//

#import "IntegerTransformer.h"

@implementation IntegerTransformer
+ (Class)transformedValueClass
{
    return [NSNumber class];
}

- (id)transformedValue:(id)value
{
    if (value == nil) return [NSNumber numberWithInteger:0];
    if([value respondsToSelector:@selector(intValue)])
    {
        int i = [value intValue];
        return [NSNumber numberWithInteger:i];
    }
    
    return [NSNumber numberWithInteger:0];
}
@end
