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
    
    MUKArrayDelta *const delta = [[MUKArrayDelta alloc] initWithSourceArray:a destinationArray:b matchTest:^MUKArrayDeltaMatchType(NSString *object1, NSString *object2)
    {
        if ([object1 isEqualToString:object2]) {
            return MUKArrayDeltaMatchTypeEqual;
        }
        else if ([[object1 substringToIndex:1] isEqualToString:[object2 substringToIndex:1]])
        {
            return MUKArrayDeltaMatchTypeChange;
        }
        
        return MUKArrayDeltaMatchTypeNone;
    }];
    
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

@end
