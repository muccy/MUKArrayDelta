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

@end
