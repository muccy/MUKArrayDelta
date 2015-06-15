//
//  MUKArrayDeltaTests.m
//  MUKArrayDeltaTests
//
//  Created by Marco on 08/06/15.
//  Copyright (c) 2015 MUKit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <MUKArrayDelta/MUKArrayDelta.h>

@interface MUKArrayDeltaTests : XCTestCase
@end

@implementation MUKArrayDeltaTests

- (void)testInitialization {
    NSArray *const a = @[ @"a" ];
    NSArray *const b = @[ @"b" ];
    
    MUKArrayDelta *delta;
    XCTAssertNoThrow(delta = [[MUKArrayDelta alloc] initWithSourceArray:a destinationArray:b matchTest:nil]);
    
    XCTAssertEqualObjects(a, delta.sourceArray);
    XCTAssertEqualObjects(b, delta.destinationArray);
}

- (void)testEquality {
    NSArray *const a = @[ @"a" ];
    NSArray *const b = @[ @"a", @"b" ];
    NSArray *const c = @[ @"a", @"b", @"c" ];
    
    MUKArrayDelta *const deltaAB = [[MUKArrayDelta alloc] initWithSourceArray:a destinationArray:b matchTest:nil];
    MUKArrayDelta *const deltaAC = [[MUKArrayDelta alloc] initWithSourceArray:a destinationArray:c matchTest:nil];
    MUKArrayDelta *const deltaBC = [[MUKArrayDelta alloc] initWithSourceArray:a destinationArray:b matchTest:nil];
    MUKArrayDelta *const deltaAB2 = [[MUKArrayDelta alloc] initWithSourceArray:a destinationArray:b matchTest:nil];
    
    XCTAssertEqualObjects(deltaAB, deltaAB2);
    XCTAssert([deltaAB isEqualToArrayDelta:deltaAB2]);
    
    XCTAssertFalse([deltaAB isEqual:deltaAC]);
    XCTAssertFalse([deltaAB isEqualToArrayDelta:deltaAC]);
    
    XCTAssertFalse([deltaBC isEqual:deltaAC]);
    XCTAssertFalse([deltaBC isEqualToArrayDelta:deltaAC]);
}

- (void)testIdentity {
    NSArray *const a = @[ @"a" ];
    NSArray *const b = @[ @"a" ];
    MUKArrayDelta *const delta = [[MUKArrayDelta alloc] initWithSourceArray:a destinationArray:b matchTest:nil];
    
    NSSet *const equalMatches = [NSSet setWithObjects:EqualMatch(0, 0), nil];
    
    XCTAssertEqual(delta.insertedIndexes.count, 0);
    XCTAssertEqual(delta.deletedIndexes.count, 0);
    XCTAssertEqualObjects(delta.equalMatches, equalMatches);
    XCTAssertEqual(delta.changes.count, 0);
    XCTAssertEqual(delta.movements.count, 0);
}

- (void)testInsertion {
    NSArray *const a = @[ @"a" ];
    NSArray *const b = @[ @"a", @"b", @"c" ];
    MUKArrayDelta *const delta = [[MUKArrayDelta alloc] initWithSourceArray:a destinationArray:b matchTest:nil];
    
    NSSet *const equalMatches = [NSSet setWithObjects:EqualMatch(0, 0), nil];
    NSIndexSet *const indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 2)];
    
    XCTAssertEqualObjects(delta.insertedIndexes, indexSet);
    XCTAssertEqual(delta.deletedIndexes.count, 0);
    XCTAssertEqualObjects(delta.equalMatches, equalMatches);
    XCTAssertEqual(delta.changes.count, 0);
    XCTAssertEqual(delta.movements.count, 0);
}

- (void)testDeletion {
    NSArray *const a = @[ @"a", @"b", @"c" ];
    NSArray *const b = @[ @"a" ];
    MUKArrayDelta *const delta = [[MUKArrayDelta alloc] initWithSourceArray:a destinationArray:b matchTest:nil];
    
    NSSet *const equalMatches = [NSSet setWithObjects:EqualMatch(0, 0), nil];
    NSIndexSet *const indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 2)];
    
    XCTAssertEqual(delta.insertedIndexes.count, 0);
    XCTAssertEqualObjects(delta.deletedIndexes, indexSet);
    XCTAssertEqualObjects(delta.equalMatches, equalMatches);
    XCTAssertEqual(delta.changes.count, 0);
    XCTAssertEqual(delta.movements.count, 0);
}

- (void)testChanges {
    NSArray *const a = @[ @"a", @"b", @"c", @"d" ];
    NSArray *const b = @[ @"a", @"b2", @"c2", @"d" ];
    
    MUKArrayDelta *const delta = [[MUKArrayDelta alloc] initWithSourceArray:a destinationArray:b matchTest:[[self class] stringPrefixMatchTest]];
    
    NSSet *const equalMatches = [NSSet setWithObjects:EqualMatch(0, 0), EqualMatch(3, 3), nil];
    NSSet *const changeMatches = [NSSet setWithObjects:ChangeMatch(1, 1), ChangeMatch(2, 2), nil];
    
    XCTAssertEqual(delta.insertedIndexes.count, 0);
    XCTAssertEqual(delta.deletedIndexes.count, 0);
    XCTAssertEqualObjects(delta.equalMatches, equalMatches);
    XCTAssertEqualObjects(delta.changes, changeMatches);
    XCTAssertEqual(delta.movements.count, 0);
}

- (void)testMatchEquality {
    MUKArrayDeltaMatch *const m1 = [[MUKArrayDeltaMatch alloc] initWithType:MUKArrayDeltaMatchTypeEqual sourceIndex:0 destinationIndex:3];
    MUKArrayDeltaMatch *const m2 = [[MUKArrayDeltaMatch alloc] initWithType:MUKArrayDeltaMatchTypeEqual sourceIndex:0 destinationIndex:3];
    XCTAssertEqualObjects(m1, m2);
    XCTAssert([m1 isEqualToArrayDeltaMatch:m2]);
    
    MUKArrayDeltaMatch *const m3 = [[MUKArrayDeltaMatch alloc] initWithType:MUKArrayDeltaMatchTypeChange sourceIndex:0 destinationIndex:3];
    XCTAssertFalse([m1 isEqual:m3]);
    XCTAssertFalse([m1 isEqualToArrayDeltaMatch:m3]);
    
    MUKArrayDeltaMatch *const m4 = [[MUKArrayDeltaMatch alloc] initWithType:MUKArrayDeltaMatchTypeEqual sourceIndex:1 destinationIndex:3];
    XCTAssertFalse([m1 isEqual:m4]);
    XCTAssertFalse([m1 isEqualToArrayDeltaMatch:m4]);
}

- (void)testMovements {
    NSArray *const a = @[ @"a", @"b", @"c", @"d", @"e" ];
    NSArray *const b = @[ @"c", @"b", @"d", @"e", @"a" ];
    
    MUKArrayDelta *const delta = [[MUKArrayDelta alloc] initWithSourceArray:a destinationArray:b matchTest:nil];
    
    NSSet *const equalMatches = [NSSet setWithObjects:EqualMatch(0, 4), EqualMatch(1, 1), EqualMatch(2, 0), EqualMatch(3, 2), EqualMatch(4, 3), nil];
    
    // 0 -> 4, 2 -> 0
    NSSet *const movements = [NSSet setWithObjects:EqualMatch(0, 4), EqualMatch(2, 0), nil];
    
    XCTAssertEqual(delta.insertedIndexes.count, 0);
    XCTAssertEqual(delta.deletedIndexes.count, 0);
    XCTAssertEqualObjects(delta.equalMatches, equalMatches);
    XCTAssertEqual(delta.changes.count, 0);
    XCTAssertEqualObjects(delta.movements, movements);
}

- (void)testInverseMovements {
    NSArray *const a = @[ @"a", @"b", @"c" ];
    NSArray *const b = @[ @"c", @"b", @"a" ];
    
    MUKArrayDelta *const delta = [[MUKArrayDelta alloc] initWithSourceArray:a destinationArray:b matchTest:nil];
    
    NSSet *const equalMatches = [NSSet setWithObjects:EqualMatch(0, 2), EqualMatch(1, 1), EqualMatch(2, 0), nil];
    
    // 0 -> 2, 2 -> 0
    NSSet *const movements = [NSSet setWithObjects:EqualMatch(0, 2), EqualMatch(2, 0), nil];
    
    XCTAssertEqual(delta.insertedIndexes.count, 0);
    XCTAssertEqual(delta.deletedIndexes.count, 0);
    XCTAssertEqualObjects(delta.equalMatches, equalMatches);
    XCTAssertEqual(delta.changes.count, 0);
    XCTAssertEqualObjects(delta.movements, movements);
}

- (void)testInverseMovements2 {
    NSArray *const a = @[ @"a", @"b", @"c" ];
    NSArray *const b = @[ @"b", @"a", @"c" ];
    
    MUKArrayDelta *const delta = [[MUKArrayDelta alloc] initWithSourceArray:a destinationArray:b matchTest:nil];
    
    NSSet *const equalMatches = [NSSet setWithObjects:EqualMatch(0, 1), EqualMatch(1, 0), EqualMatch(2, 2), nil];
    
    // 0 -> 1
    NSSet *const movements = [NSSet setWithObjects:EqualMatch(0, 1), nil];
    
    XCTAssertEqual(delta.insertedIndexes.count, 0);
    XCTAssertEqual(delta.deletedIndexes.count, 0);
    XCTAssertEqualObjects(delta.equalMatches, equalMatches);
    XCTAssertEqual(delta.changes.count, 0);
    XCTAssertEqualObjects(delta.movements, movements);
}

- (void)testComboInsertionDeletion {
    NSArray *const a = @[ @"a" ];
    NSArray *const b = @[ @"b", @"c" ];
    MUKArrayDelta *const delta = [[MUKArrayDelta alloc] initWithSourceArray:a destinationArray:b matchTest:nil];
    
    NSIndexSet *const insertedIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)];
    NSIndexSet *const deletedIndexes = [NSIndexSet indexSetWithIndex:0];
    
    XCTAssertEqualObjects(delta.insertedIndexes, insertedIndexes);
    XCTAssertEqualObjects(delta.deletedIndexes, deletedIndexes);
    XCTAssertEqual(delta.equalMatches.count, 0);
    XCTAssertEqual(delta.changes.count, 0);
    XCTAssertEqual(delta.movements.count, 0);
}

- (void)testComboInsertionChange {
    NSArray *const a = @[ @"a" ];
    NSArray *const b = @[ @"a1", @"b" ];
    MUKArrayDelta *const delta = [[MUKArrayDelta alloc] initWithSourceArray:a destinationArray:b matchTest:[[self class] stringPrefixMatchTest]];
    
    NSIndexSet *const insertedIndexes = [NSIndexSet indexSetWithIndex:1];
    NSSet *const changes = [NSSet setWithObjects:ChangeMatch(0, 0), nil];
    
    XCTAssertEqualObjects(delta.insertedIndexes, insertedIndexes);
    XCTAssertEqual(delta.deletedIndexes.count, 0);
    XCTAssertEqual(delta.equalMatches.count, 0);
    XCTAssertEqualObjects(delta.changes, changes);
    XCTAssertEqual(delta.movements.count, 0);
}

- (void)testComboInsertionMovement {
    NSArray *const a = @[ @"a", @"b", @"c" ];
    NSArray *const b = @[ @"b", @"a", @"d", @"c", @"e" ];
    MUKArrayDelta *const delta = [[MUKArrayDelta alloc] initWithSourceArray:a destinationArray:b matchTest:nil];
    
    NSSet *const equalMatches = [NSSet setWithObjects:EqualMatch(0, 1), EqualMatch(1, 0), EqualMatch(2, 3), nil];
    
    // 0 -> 1
    NSSet *const movements = [NSSet setWithObjects:EqualMatch(0, 1), nil];
    
    // Inserted at index 2 (which moves c to 3) and 4
    NSMutableIndexSet *const insertedIndexes = [NSMutableIndexSet indexSetWithIndex:2];
    [insertedIndexes addIndex:4];
    
    XCTAssertEqualObjects(delta.insertedIndexes, insertedIndexes);
    XCTAssertEqual(delta.deletedIndexes.count, 0);
    XCTAssertEqualObjects(delta.equalMatches, equalMatches);
    XCTAssertEqual(delta.changes.count, 0);
    XCTAssertEqualObjects(delta.movements, movements);
}

- (void)testComboDeletionChange {
    NSArray *const a = @[ @"a", @"b" ];
    NSArray *const b = @[ @"b1" ];
    MUKArrayDelta *const delta = [[MUKArrayDelta alloc] initWithSourceArray:a destinationArray:b matchTest:[[self class] stringPrefixMatchTest]];
    
    NSIndexSet *const deletedIndexes = [NSIndexSet indexSetWithIndex:0];
    NSSet *const changes = [NSSet setWithObjects:ChangeMatch(1, 0), nil];
    
    XCTAssertEqual(delta.insertedIndexes.count, 0);
    XCTAssertEqualObjects(delta.deletedIndexes, deletedIndexes);
    XCTAssertEqual(delta.equalMatches.count, 0);
    XCTAssertEqualObjects(delta.changes, changes);
    XCTAssertEqual(delta.movements.count, 0);
}

- (void)testComboDeletionMovement {
    NSArray *const a = @[ @"a", @"b", @"c", @"d" ];
    NSArray *const b = @[ @"d", @"c" ];
    MUKArrayDelta *const delta = [[MUKArrayDelta alloc] initWithSourceArray:a destinationArray:b matchTest:nil];
    
    NSSet *const equalMatches = [NSSet setWithObjects:EqualMatch(2, 1), EqualMatch(3, 0), nil];
    
    // 2 -> 1
    NSSet *const movements = [NSSet setWithObjects:EqualMatch(2, 1), nil];
    
    // Removed 0 and 1
    NSMutableIndexSet *const deletedIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)];
    
    XCTAssertEqual(delta.insertedIndexes.count, 0);
    XCTAssertEqualObjects(delta.deletedIndexes, deletedIndexes);
    XCTAssertEqualObjects(delta.equalMatches, equalMatches);
    XCTAssertEqual(delta.changes.count, 0);
    XCTAssertEqualObjects(delta.movements, movements);
}

- (void)testComboChangeMovement {
    NSArray *const a = @[ @"a", @"b", @"c", @"d" ];
    NSArray *const b = @[ @"a", @"c1", @"b1", @"d1" ];
    MUKArrayDelta *const delta = [[MUKArrayDelta alloc] initWithSourceArray:a destinationArray:b matchTest:[[self class] stringPrefixMatchTest]];
    
    NSSet *const equalMatches = [NSSet setWithObjects:EqualMatch(0, 0), nil];
    NSSet *const changes = [NSSet setWithObjects:ChangeMatch(1, 2), ChangeMatch(2, 1), ChangeMatch(3, 3), nil];
    
    // 1 -> 2
    NSSet *const movements = [NSSet setWithObjects:ChangeMatch(1, 2), nil];
    
    XCTAssertEqual(delta.insertedIndexes.count, 0);
    XCTAssertEqual(delta.deletedIndexes.count, 0);
    XCTAssertEqualObjects(delta.equalMatches, equalMatches);
    XCTAssertEqualObjects(delta.changes, changes);
    XCTAssertEqualObjects(delta.movements, movements);
}

- (void)testComboInsertionDeletionChange {
    NSArray *const a = @[ @"a", @"b", @"c" ];
    NSArray *const b = @[ @"c1", @"d" ];
    MUKArrayDelta *const delta = [[MUKArrayDelta alloc] initWithSourceArray:a destinationArray:b matchTest:[[self class] stringPrefixMatchTest]];
    
    NSIndexSet *const insertedIndexes = [NSIndexSet indexSetWithIndex:1];
    NSIndexSet *const deletedIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)];
    NSSet *const changes = [NSSet setWithObjects:ChangeMatch(2, 0), nil];
    
    XCTAssertEqualObjects(delta.insertedIndexes, insertedIndexes);
    XCTAssertEqualObjects(delta.deletedIndexes, deletedIndexes);
    XCTAssertEqual(delta.equalMatches.count, 0);
    XCTAssertEqualObjects(delta.changes, changes);
    XCTAssertEqual(delta.movements.count, 0);
}

- (void)testComboInsertionDeletionMovement {
    NSArray *const a = @[ @"a", @"b", @"c", @"d" ];
    NSArray *const b = @[ @"a", @"c", @"b", @"e" ];
    MUKArrayDelta *const delta = [[MUKArrayDelta alloc] initWithSourceArray:a destinationArray:b matchTest:nil];
    
    NSSet *const equalMatches = [NSSet setWithObjects:EqualMatch(0, 0), EqualMatch(1, 2), EqualMatch(2, 1), nil];
    
    // 1 -> 2
    NSSet *const movements = [NSSet setWithObjects:EqualMatch(1, 2), nil];
    
    NSIndexSet *const insertedIndexes = [NSIndexSet indexSetWithIndex:3];
    NSIndexSet *const deletedIndexes = [NSIndexSet indexSetWithIndex:3];
    
    XCTAssertEqualObjects(delta.insertedIndexes, insertedIndexes);
    XCTAssertEqualObjects(delta.deletedIndexes, deletedIndexes);
    XCTAssertEqualObjects(delta.equalMatches, equalMatches);
    XCTAssertEqual(delta.changes.count, 0);
    XCTAssertEqualObjects(delta.movements, movements);
}

- (void)testComboDeletionChangeMovement {
    NSArray *const a = @[ @"a", @"b", @"c", @"d", @"e", @"f" ];
    NSArray *const b = @[ @"a1", @"c", @"b", @"f1", @"e" ];
    MUKArrayDelta *const delta = [[MUKArrayDelta alloc] initWithSourceArray:a destinationArray:b matchTest:[[self class] stringPrefixMatchTest]];
    
    NSSet *const equalMatches = [NSSet setWithObjects:EqualMatch(1, 2), EqualMatch(2, 1), EqualMatch(4, 4), nil];
    NSSet *const changes = [NSSet setWithObjects:ChangeMatch(0, 0), ChangeMatch(5, 3), nil];
    
    // 1 -> 2, 5 -> 3
    NSSet *const movements = [NSSet setWithObjects:EqualMatch(1, 2), ChangeMatch(5, 3), nil];
    
    NSIndexSet *const deletedIndexes = [NSIndexSet indexSetWithIndex:3];
    NSMutableIndexSet *const changedIndexes = [NSMutableIndexSet indexSetWithIndex:0];
    [changedIndexes addIndex:5];
    
    XCTAssertEqual(delta.insertedIndexes.count, 0);
    XCTAssertEqualObjects(delta.deletedIndexes, deletedIndexes);
    XCTAssertEqualObjects(delta.equalMatches, equalMatches);
    XCTAssertEqualObjects(delta.changes, changes);
    XCTAssertEqualObjects(delta.movements, movements);
}

- (void)testComboInsertionDeletionChangeMovement {
    NSArray *const a = @[ @"a", @"b", @"c", @"d", @"e", @"f" ];
    NSArray *const b = @[ @"a1", @"c", @"b", @"g", @"e", @"h", @"f1" ];
    MUKArrayDelta *const delta = [[MUKArrayDelta alloc] initWithSourceArray:a destinationArray:b matchTest:[[self class] stringPrefixMatchTest]];
    
    NSSet *const equalMatches = [NSSet setWithObjects:EqualMatch(1, 2), EqualMatch(2, 1), EqualMatch(4, 4), nil];
    NSSet *const changes = [NSSet setWithObjects:ChangeMatch(0, 0), ChangeMatch(5, 6), nil];
    
    // 1 -> 2
    NSSet *const movements = [NSSet setWithObjects:EqualMatch(1, 2), nil];
    
    NSMutableIndexSet *const insertedIndexes = [NSMutableIndexSet indexSetWithIndex:3];
    [insertedIndexes addIndex:5];
    NSIndexSet *const deletedIndexes = [NSIndexSet indexSetWithIndex:3];
    NSMutableIndexSet *const changedIndexes = [NSMutableIndexSet indexSetWithIndex:0];
    [changedIndexes addIndex:5];
    
    XCTAssertEqualObjects(delta.insertedIndexes, insertedIndexes);
    XCTAssertEqualObjects(delta.deletedIndexes, deletedIndexes);
    XCTAssertEqualObjects(delta.equalMatches, equalMatches);
    XCTAssertEqualObjects(delta.changes, changes);
    XCTAssertEqualObjects(delta.movements, movements);
}

- (void)testIntermediateDestinationIndexForMovement {
    NSArray *a = @[ @"a", @"b", @"c", @"d" ];
    NSArray *b = @[ @"d", @"c" ];
    MUKArrayDelta *delta = [[MUKArrayDelta alloc] initWithSourceArray:a destinationArray:b matchTest:nil];
    XCTAssertEqual([delta intermediateDestinationIndexForMovement:EqualMatch(2, 1)], 0);
    XCTAssertEqual([delta intermediateDestinationIndexForMovement:EqualMatch(3, 0)], 0);
    
    a = @[ @"a", @"b", @"c" ];
    b = @[ @"b", @"a", @"d", @"c", @"e" ];
    delta = [[MUKArrayDelta alloc] initWithSourceArray:a destinationArray:b matchTest:nil];
    XCTAssertEqual([delta intermediateDestinationIndexForMovement:EqualMatch(0, 1)], 0);
    XCTAssertEqual([delta intermediateDestinationIndexForMovement:EqualMatch(1, 0)], 0);
    XCTAssertEqual([delta intermediateDestinationIndexForMovement:EqualMatch(2, 3)], 3);
}

#pragma mark - Private

+ (MUKArrayDeltaMatchTest)stringPrefixMatchTest {
    return ^MUKArrayDeltaMatchType(NSString *object1, NSString *object2)
    {
        if ([object1 isEqualToString:object2]) {
            return MUKArrayDeltaMatchTypeEqual;
        }
        else if ([[object1 substringToIndex:1] isEqualToString:[object2 substringToIndex:1]])
        {
            return MUKArrayDeltaMatchTypeChange;
        }
        
        return MUKArrayDeltaMatchTypeNone;
    };
}

static inline MUKArrayDeltaMatch * EqualMatch(NSUInteger src, NSUInteger dst) {
    return [[MUKArrayDeltaMatch alloc] initWithType:MUKArrayDeltaMatchTypeEqual sourceIndex:src destinationIndex:dst];
}

static inline MUKArrayDeltaMatch * ChangeMatch(NSUInteger src, NSUInteger dst) {
    return [[MUKArrayDeltaMatch alloc] initWithType:MUKArrayDeltaMatchTypeChange sourceIndex:src destinationIndex:dst];
}

@end
