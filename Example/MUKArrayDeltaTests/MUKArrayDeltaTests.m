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

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testInitialization {
    NSArray *const a = @[ @"a" ];
    NSArray *const b = @[ @"b" ];
    
    MUKArrayDelta *delta;
    XCTAssertNoThrow(delta = [[MUKArrayDelta alloc] initWithSourceArray:a destinationArray:b matchTest:nil]);
    
    XCTAssertEqualObjects(a, delta.sourceArray);
    XCTAssertEqualObjects(b, delta.destinationArray);
}

- (void)testIdentity {
    NSArray *const a = @[ @"a" ];
    NSArray *const b = @[ @"a" ];
    MUKArrayDelta *const delta = [[MUKArrayDelta alloc] initWithSourceArray:a destinationArray:b matchTest:nil];
    
    XCTAssertEqual(delta.insertedIndexes.count, 0);
    XCTAssertEqual(delta.deletedIndexes.count, 0);
    XCTAssertEqual(delta.changedIndexes.count, 0);
    XCTAssertEqual(delta.movements.count, 0);
}

- (void)testInsertion {
    NSArray *const a = @[ @"a" ];
    NSArray *const b = @[ @"a", @"b", @"c" ];
    MUKArrayDelta *const delta = [[MUKArrayDelta alloc] initWithSourceArray:a destinationArray:b matchTest:nil];
    
    NSIndexSet *const indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 2)];
    XCTAssertEqualObjects(delta.insertedIndexes, indexSet);
    XCTAssertEqual(delta.deletedIndexes.count, 0);
    XCTAssertEqual(delta.changedIndexes.count, 0);
    XCTAssertEqual(delta.movements.count, 0);
}

- (void)testDeletion {
    NSArray *const a = @[ @"a", @"b", @"c" ];
    NSArray *const b = @[ @"a" ];
    MUKArrayDelta *const delta = [[MUKArrayDelta alloc] initWithSourceArray:a destinationArray:b matchTest:nil];
    
    NSIndexSet *const indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 2)];
    XCTAssertEqual(delta.insertedIndexes.count, 0);
    XCTAssertEqualObjects(delta.deletedIndexes, indexSet);
    XCTAssertEqual(delta.changedIndexes.count, 0);
    XCTAssertEqual(delta.movements.count, 0);
}

- (void)testChanges {
    NSArray *const a = @[ @"a", @"b", @"c", @"d" ];
    NSArray *const b = @[ @"a", @"b2", @"c2", @"d" ];
    
    MUKArrayDelta *const delta = [[MUKArrayDelta alloc] initWithSourceArray:a destinationArray:b matchTest:[[self class] stringPrefixMatchTest]];
    
    NSIndexSet *const indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 2)];
    XCTAssertEqual(delta.insertedIndexes.count, 0);
    XCTAssertEqual(delta.deletedIndexes.count, 0);
    XCTAssertEqualObjects(delta.changedIndexes, indexSet);
    XCTAssertEqual(delta.movements.count, 0);
}

- (void)testMovementEquality {
    MUKArrayDeltaMovement *const m1 = [[MUKArrayDeltaMovement alloc] initWithSourceIndex:0 destinationIndex:3];
    MUKArrayDeltaMovement *const m2 = [[MUKArrayDeltaMovement alloc] initWithSourceIndex:0 destinationIndex:3];
    XCTAssertEqualObjects(m1, m2);
    XCTAssert([m1 isEqualToArrayDeltaMovement:m2]);
    
    MUKArrayDeltaMovement *const m3 = [[MUKArrayDeltaMovement alloc] initWithSourceIndex:2 destinationIndex:3];
    XCTAssertFalse([m1 isEqual:m3]);
    XCTAssertFalse([m1 isEqualToArrayDeltaMovement:m3]);
}

- (void)testMovements {
    NSArray *const a = @[ @"a", @"b", @"c", @"d", @"e" ];
    NSArray *const b = @[ @"c", @"b", @"d", @"e", @"a" ];
    
    MUKArrayDelta *const delta = [[MUKArrayDelta alloc] initWithSourceArray:a destinationArray:b matchTest:nil];
    
    // 0 -> 4, 2 -> 0
    NSArray *const movements = @[ [[MUKArrayDeltaMovement alloc] initWithSourceIndex:0 destinationIndex:4], [[MUKArrayDeltaMovement alloc] initWithSourceIndex:2 destinationIndex:0] ];
    
    XCTAssertEqual(delta.insertedIndexes.count, 0);
    XCTAssertEqual(delta.deletedIndexes.count, 0);
    XCTAssertEqual(delta.changedIndexes.count, 0);
    XCTAssertEqual(delta.movements.count, movements.count);
    
    for (MUKArrayDeltaMovement *const movement in movements) {
        XCTAssert([delta.movements containsObject:movement]);
    } // for
}

- (void)testComboInsertionDeletion {
    NSArray *const a = @[ @"a" ];
    NSArray *const b = @[ @"b", @"c" ];
    MUKArrayDelta *const delta = [[MUKArrayDelta alloc] initWithSourceArray:a destinationArray:b matchTest:nil];
    
    NSIndexSet *const insertedIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)];
    NSIndexSet *const deletedIndexes = [NSIndexSet indexSetWithIndex:0];
    
    XCTAssertEqualObjects(delta.insertedIndexes, insertedIndexes);
    XCTAssertEqualObjects(delta.deletedIndexes, deletedIndexes);
    XCTAssertEqual(delta.changedIndexes.count, 0);
    XCTAssertEqual(delta.movements.count, 0);
}

- (void)testComboInsertionChange {
    NSArray *const a = @[ @"a" ];
    NSArray *const b = @[ @"a1", @"b" ];
    MUKArrayDelta *const delta = [[MUKArrayDelta alloc] initWithSourceArray:a destinationArray:b matchTest:[[self class] stringPrefixMatchTest]];
    
    NSIndexSet *const insertedIndexes = [NSIndexSet indexSetWithIndex:1];
    NSIndexSet *const changedIndexes = [NSIndexSet indexSetWithIndex:0];
    
    XCTAssertEqualObjects(delta.insertedIndexes, insertedIndexes);
    XCTAssertEqual(delta.deletedIndexes.count, 0);
    XCTAssertEqualObjects(delta.changedIndexes, changedIndexes);
    XCTAssertEqual(delta.movements.count, 0);
}

- (void)testComboInsertionMovement {
    NSArray *const a = @[ @"a", @"b", @"c" ];
    NSArray *const b = @[ @"b", @"a", @"d", @"c", @"e" ];
    MUKArrayDelta *const delta = [[MUKArrayDelta alloc] initWithSourceArray:a destinationArray:b matchTest:[[self class] stringPrefixMatchTest]];
    
    // 0 -> 1
    MUKArrayDeltaMovement *const movement = [[MUKArrayDeltaMovement alloc] initWithSourceIndex:0 destinationIndex:1];
    
    // Inserted at index 2 (which moves c to 3) and 4
    NSMutableIndexSet *const insertedIndexes = [NSMutableIndexSet indexSetWithIndex:2];
    [insertedIndexes addIndex:4];
    
    XCTAssertEqualObjects(delta.insertedIndexes, insertedIndexes);
    XCTAssertEqual(delta.deletedIndexes.count, 0);
    XCTAssertEqual(delta.changedIndexes.count, 0);
    XCTAssertEqual(delta.movements.count, 1);
    XCTAssert([delta.movements containsObject:movement]);
}

- (void)testComboDeletionChange {
    NSArray *const a = @[ @"a", @"b" ];
    NSArray *const b = @[ @"b1" ];
    MUKArrayDelta *const delta = [[MUKArrayDelta alloc] initWithSourceArray:a destinationArray:b matchTest:[[self class] stringPrefixMatchTest]];
    
    NSIndexSet *const deletedIndexes = [NSIndexSet indexSetWithIndex:0];
    NSIndexSet *const changedIndexes = [NSIndexSet indexSetWithIndex:1];
    
    XCTAssertEqual(delta.insertedIndexes.count, 0);
    XCTAssertEqualObjects(delta.deletedIndexes, deletedIndexes);
    XCTAssertEqualObjects(delta.changedIndexes, changedIndexes);
    XCTAssertEqual(delta.movements.count, 0);
}

- (void)testComboDeletionMovement {
    NSArray *const a = @[ @"a", @"b", @"c", @"d" ];
    NSArray *const b = @[ @"d", @"c" ];
    MUKArrayDelta *const delta = [[MUKArrayDelta alloc] initWithSourceArray:a destinationArray:b matchTest:[[self class] stringPrefixMatchTest]];
    
    // 2 -> 1
    MUKArrayDeltaMovement *const movement = [[MUKArrayDeltaMovement alloc] initWithSourceIndex:2 destinationIndex:1];
    
    // Removed 0 and 1
    NSMutableIndexSet *const deletedIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)];
    
    XCTAssertEqual(delta.insertedIndexes.count, 0);
    XCTAssertEqualObjects(delta.deletedIndexes, deletedIndexes);
    XCTAssertEqual(delta.changedIndexes.count, 0);
    XCTAssertEqual(delta.movements.count, 1);
    XCTAssert([delta.movements containsObject:movement]);
}

- (void)testComboChangeMovement {
    NSArray *const a = @[ @"a", @"b", @"c", @"d" ];
    NSArray *const b = @[ @"a", @"c1", @"b1", @"d1" ];
    MUKArrayDelta *const delta = [[MUKArrayDelta alloc] initWithSourceArray:a destinationArray:b matchTest:[[self class] stringPrefixMatchTest]];
    
    // 1 -> 2
    MUKArrayDeltaMovement *const movement = [[MUKArrayDeltaMovement alloc] initWithSourceIndex:1 destinationIndex:2];
    NSIndexSet *const changedIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 3)];
    
    XCTAssertEqual(delta.insertedIndexes.count, 0);
    XCTAssertEqual(delta.deletedIndexes.count, 0);
    XCTAssertEqualObjects(delta.changedIndexes, changedIndexes);
    XCTAssertEqual(delta.movements.count, 1);
    XCTAssert([delta.movements containsObject:movement]);
}

- (void)testComboInsertionDeletionChange {
    NSArray *const a = @[ @"a", @"b", @"c" ];
    NSArray *const b = @[ @"c1", @"d" ];
    MUKArrayDelta *const delta = [[MUKArrayDelta alloc] initWithSourceArray:a destinationArray:b matchTest:[[self class] stringPrefixMatchTest]];
    
    NSIndexSet *const insertedIndexes = [NSIndexSet indexSetWithIndex:1];
    NSIndexSet *const deletedIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)];
    NSIndexSet *const changedIndexes = [NSIndexSet indexSetWithIndex:2];
    
    XCTAssertEqualObjects(delta.insertedIndexes, insertedIndexes);
    XCTAssertEqualObjects(delta.deletedIndexes, deletedIndexes);
    XCTAssertEqualObjects(delta.changedIndexes, changedIndexes);
    XCTAssertEqual(delta.movements.count, 0);
}

- (void)testComboInsertionDeletionMovement {
    NSArray *const a = @[ @"a", @"b", @"c", @"d" ];
    NSArray *const b = @[ @"a", @"c", @"b", @"e" ];
    MUKArrayDelta *const delta = [[MUKArrayDelta alloc] initWithSourceArray:a destinationArray:b matchTest:nil];
    
    // 1 -> 2
    MUKArrayDeltaMovement *const movement = [[MUKArrayDeltaMovement alloc] initWithSourceIndex:1 destinationIndex:2];
    
    NSIndexSet *const insertedIndexes = [NSIndexSet indexSetWithIndex:3];
    NSIndexSet *const deletedIndexes = [NSIndexSet indexSetWithIndex:3];
    
    XCTAssertEqualObjects(delta.insertedIndexes, insertedIndexes);
    XCTAssertEqualObjects(delta.deletedIndexes, deletedIndexes);
    XCTAssertEqual(delta.changedIndexes.count, 0);
    XCTAssertEqual(delta.movements.count, 1);
    XCTAssert([delta.movements containsObject:movement]);
}

- (void)testComboDeletionChangeMovement {
    NSArray *const a = @[ @"a", @"b", @"c", @"d", @"e", @"f" ];
    NSArray *const b = @[ @"a1", @"c", @"b", @"f1", @"e" ];
    MUKArrayDelta *const delta = [[MUKArrayDelta alloc] initWithSourceArray:a destinationArray:b matchTest:[[self class] stringPrefixMatchTest]];
    
    // 1 -> 2, 5 -> 3
    MUKArrayDeltaMovement *const m1 = [[MUKArrayDeltaMovement alloc] initWithSourceIndex:1 destinationIndex:2];
    MUKArrayDeltaMovement *const m2 = [[MUKArrayDeltaMovement alloc] initWithSourceIndex:5 destinationIndex:3];
    
    NSIndexSet *const deletedIndexes = [NSIndexSet indexSetWithIndex:3];
    NSMutableIndexSet *const changedIndexes = [NSMutableIndexSet indexSetWithIndex:0];
    [changedIndexes addIndex:5];
    
    XCTAssertEqual(delta.insertedIndexes.count, 0);
    XCTAssertEqualObjects(delta.deletedIndexes, deletedIndexes);
    XCTAssertEqualObjects(delta.changedIndexes, changedIndexes);
    XCTAssertEqual(delta.movements.count, 2);
    XCTAssert([delta.movements containsObject:m1]);
    XCTAssert([delta.movements containsObject:m2]);
}

- (void)testComboInsertionDeletionChangeMovement {
    NSArray *const a = @[ @"a", @"b", @"c", @"d", @"e", @"f" ];
    NSArray *const b = @[ @"a1", @"c", @"b", @"g", @"e", @"h", @"f1" ];
    MUKArrayDelta *const delta = [[MUKArrayDelta alloc] initWithSourceArray:a destinationArray:b matchTest:[[self class] stringPrefixMatchTest]];
    
    // 1 -> 2
    MUKArrayDeltaMovement *const m1 = [[MUKArrayDeltaMovement alloc] initWithSourceIndex:1 destinationIndex:2];
    
    NSMutableIndexSet *const insertedIndexes = [NSMutableIndexSet indexSetWithIndex:3];
    [insertedIndexes addIndex:5];
    NSIndexSet *const deletedIndexes = [NSIndexSet indexSetWithIndex:3];
    NSMutableIndexSet *const changedIndexes = [NSMutableIndexSet indexSetWithIndex:0];
    [changedIndexes addIndex:5];
    
    XCTAssertEqualObjects(delta.insertedIndexes, insertedIndexes);
    XCTAssertEqualObjects(delta.deletedIndexes, deletedIndexes);
    XCTAssertEqualObjects(delta.changedIndexes, changedIndexes);
    XCTAssertEqual(delta.movements.count, 1);
    XCTAssert([delta.movements containsObject:m1]);
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

@end
