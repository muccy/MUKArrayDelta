//
//  MUKArrayDelta.m
//  
//
//  Created by Marco on 08/06/15.
//
//

#import "MUKArrayDelta.h"

@implementation MUKArrayDeltaMovement

- (instancetype)initWithSourceIndex:(NSUInteger)sourceIndex destinationIndex:(NSUInteger)destinationIndex
{
    self = [super init];
    if (self) {
        _sourceIndex = sourceIndex;
        _destinationIndex = destinationIndex;
    }
    
    return self;
}

@end


@implementation MUKArrayDelta

- (instancetype)initWithSourceArray:(NSArray *)sourceArray destinationArray:(NSArray *)destinationArray
{
    self = [super init];
    if (self) {
        _sourceArray = [sourceArray copy];
        _destinationArray = [destinationArray copy];
    }

    return self;
}

@end
