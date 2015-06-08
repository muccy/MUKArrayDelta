//
//  MUKArrayDelta.h
//  
//
//  Created by Marco on 08/06/15.
//
//

#import <Foundation/Foundation.h>

@interface MUKArrayDelta : NSObject
@property (nonatomic, copy, readonly) NSArray *sourceArray;
@property (nonatomic, copy, readonly) NSArray *destinationArray;

@property (nonatomic, readonly) NSIndexSet *insertedIndexes;
@property (nonatomic, readonly) NSIndexSet *deletedIndexes;
@property (nonatomic, readonly) NSIndexSet *changedIndexes;
@property (nonatomic, readonly) NSArray *movements;

- (instancetype)initWithSourceArray:(NSArray *)sourceArray destinationArray:(NSArray *)destinationArray;
@end


@interface MUKArrayDeltaMovement : NSObject
@property (nonatomic, readonly) NSUInteger sourceIndex;
@property (nonatomic, readonly) NSUInteger destinationIndex;
@end
