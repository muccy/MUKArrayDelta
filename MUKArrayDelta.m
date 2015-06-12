#import "MUKArrayDelta.h"

@implementation MUKArrayDeltaMatch

- (instancetype)initWithType:(MUKArrayDeltaMatchType)type sourceIndex:(NSUInteger)sourceIndex destinationIndex:(NSUInteger)destinationIndex
{
    self = [super init];
    if (self) {
        _type = type;
        _sourceIndex = sourceIndex;
        _destinationIndex = destinationIndex;
    }
    
    return self;
}

- (BOOL)isEqualToArrayDeltaMatch:(MUKArrayDeltaMatch *)match {
    return self.type == match.type && self.sourceIndex == match.sourceIndex && self.destinationIndex == match.destinationIndex;
}

- (instancetype)inverse {
    return [[[self class] alloc] initWithType:self.type sourceIndex:self.destinationIndex destinationIndex:self.sourceIndex];
}

#pragma mark Overrides

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    
    if ([object isKindOfClass:[self class]]) {
        return [self isEqualToArrayDeltaMatch:object];
    }
    
    return NO;
}

- (NSUInteger)hash {
    return 67829043 ^ self.type ^ self.sourceIndex ^ self.destinationIndex;
}

- (NSString *)description {
    NSString *typeDescription;
    switch (self.type) {
        case MUKArrayDeltaMatchTypeNone:
            typeDescription = @"No match";
            break;
            
        case MUKArrayDeltaMatchTypeChange:
            typeDescription = @"Change";
            break;
            
        case MUKArrayDeltaMatchTypeEqual:
            typeDescription = @"Equality";
            break;
            
        default:
            typeDescription = nil;
            break;
    }
    
    return [[super description] stringByAppendingFormat:@" %@ between %lu and %lu", typeDescription, (unsigned long)self.sourceIndex, (unsigned long)self.destinationIndex];
}

@end

#pragma mark -

@implementation MUKArrayDelta

- (instancetype)initWithSourceArray:(NSArray *)sourceArray destinationArray:(NSArray *)destinationArray matchTest:(MUKArrayDeltaMatchTest)matchTest
{
    self = [super init];
    if (self) {
        _sourceArray = [sourceArray copy];
        _destinationArray = [destinationArray copy];
        
        // Ensure a match test
        BOOL usesDefaultMatchTest = NO;
        if (!matchTest) {
            matchTest = [[self class] defaultMatchTest];
            usesDefaultMatchTest = YES;
        }
        
        NSMutableIndexSet *const availableDestinationIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, destinationArray.count)];
        NSMutableSet *changeMatches = [NSMutableSet set];
        NSMutableSet *equalMatches = [NSMutableSet set];
        NSMutableIndexSet *deletedIndexes = [NSMutableIndexSet indexSet];
        
        [sourceArray enumerateObjectsUsingBlock:^(id sourceObject, NSUInteger sourceIndex, BOOL *stop)
        {
            __block MUKArrayDeltaMatch *foundMatch = nil;
            
            [destinationArray enumerateObjectsAtIndexes:availableDestinationIndexes options:0 usingBlock:^(id destinationObject, NSUInteger destinationIndex, BOOL *stop)
            {
                MUKArrayDeltaMatchType const matchType = matchTest(sourceObject, destinationObject);
                
                switch (matchType) {
                    case MUKArrayDeltaMatchTypeChange:
                    case MUKArrayDeltaMatchTypeEqual:
                    {
                        foundMatch = [[MUKArrayDeltaMatch alloc] initWithType:matchType sourceIndex:sourceIndex destinationIndex:destinationIndex];
                        *stop = YES;
                        break;
                    }
  
                    case MUKArrayDeltaMatchTypeNone:
                    default:
                        break;
                } // switch
            }]; // destinationArray enumerateObjectsUsingBlock:
            
            if (foundMatch && foundMatch.type != MUKArrayDeltaMatchTypeNone) {
                // Mark as used
                [availableDestinationIndexes removeIndex:foundMatch.destinationIndex];
                
                switch (foundMatch.type) {
                    case MUKArrayDeltaMatchTypeChange:
                        [changeMatches addObject:foundMatch];
                        break;
                        
                    case MUKArrayDeltaMatchTypeEqual:
                        [equalMatches addObject:foundMatch];
                        break;
                        
                    default:
                        break;
                }
            }
            else {
                [deletedIndexes addIndex:sourceIndex];
            }
        }]; // sourceArray enumerateObjectsUsingBlock:
        
        _equalMatches = [equalMatches copy];
        _changes = [changeMatches copy];
        _deletedIndexes = [deletedIndexes copy];
        
        // Every index without a match from source array is an inserted index
        _insertedIndexes = [availableDestinationIndexes copy];
        [availableDestinationIndexes removeAllIndexes];
        
        // Find movements inside matches
        NSMutableSet *const movements = [NSMutableSet set];
        NSMutableSet *const allMatches = [NSMutableSet set];
        [allMatches unionSet:_equalMatches];
        [allMatches unionSet:_changes];
        
        [allMatches enumerateObjectsUsingBlock:^(MUKArrayDeltaMatch *match, BOOL *stop)
        {
            // First of all test simple case: same indexes means it isn't a movement
            if (match.sourceIndex == match.destinationIndex) {
                return;
            }
            
            // Check for counter movement
            if ([movements containsObject:[match inverse]]) {
                return;
            }
            
            // Then evaluate destination index to take into account insertions,
            // deletions and overtakes
            NSUInteger const insertionsBefore = [_insertedIndexes countOfIndexesInRange:NSMakeRange(0, match.destinationIndex)];
            NSUInteger const deletionsBefore = [_deletedIndexes countOfIndexesInRange:NSMakeRange(0, match.sourceIndex)];
            
            NSInteger offset = 0;
            for (MUKArrayDeltaMatch *anotherMatch in allMatches) {
                if (anotherMatch.sourceIndex != anotherMatch.destinationIndex &&
                    ![anotherMatch isEqualToArrayDeltaMatch:match])
                {
                    if (anotherMatch.sourceIndex > match.sourceIndex &&
                        anotherMatch.destinationIndex < match.destinationIndex)
                    {
                        // A following item is now before
                        offset--;
                    }
                    else if (anotherMatch.sourceIndex < match.sourceIndex &&
                             anotherMatch.destinationIndex > match.destinationIndex)
                    {
                        // A preceding item is now after
                        offset++;
                    }
                } // if
            } // for
            
            // Calculate temporary destination index after these movements
            NSUInteger const normalizedDestinationIndex = match.destinationIndex - insertionsBefore + deletionsBefore + offset;
            
            if (match.sourceIndex != normalizedDestinationIndex) {
                [movements addObject:match];
            }
        }]; // allMatches enumerateObjectsUsingBlock:
        
        _movements = [movements copy];
    }

    return self;
}

- (BOOL)isEqualToArrayDelta:(MUKArrayDelta *)arrayDelta {
    BOOL const sameSourceArray = (!self.sourceArray && !arrayDelta.sourceArray) || [self.sourceArray isEqualToArray:arrayDelta.sourceArray];
    BOOL const sameDestinationArray = (!self.destinationArray && !arrayDelta.destinationArray) || [self.destinationArray isEqualToArray:arrayDelta.destinationArray];
    BOOL const sameInsertedIndexes = (!self.insertedIndexes && !arrayDelta.insertedIndexes) || [self.insertedIndexes isEqualToIndexSet:arrayDelta.insertedIndexes];
    BOOL const sameDeletedIndexes = (!self.deletedIndexes && !arrayDelta.deletedIndexes) || [self.deletedIndexes isEqualToIndexSet:arrayDelta.deletedIndexes];
    BOOL const sameEqualMatches = (!self.equalMatches && !arrayDelta.equalMatches) || [self.equalMatches isEqualToSet:arrayDelta.equalMatches];
    BOOL const sameChanges = (!self.changes && !arrayDelta.changes) || [self.changes isEqualToSet:arrayDelta.changes];
    BOOL const sameMovements = (!self.movements && !arrayDelta.movements) || [self.movements isEqualToSet:arrayDelta.movements];
    
    return sameSourceArray && sameDestinationArray && sameInsertedIndexes && sameDeletedIndexes && sameEqualMatches && sameChanges && sameMovements;
}

#pragma mark Overrides

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    
    if ([object isKindOfClass:[self class]]) {
        return [self isEqualToArrayDelta:object];
    }
    
    return NO;
}

- (NSUInteger)hash {
    return 984236 ^ [self.sourceArray hash] ^ [self.destinationArray hash] ^ [self.insertedIndexes hash] ^ [self.deletedIndexes hash] ^ [self.equalMatches hash] ^ [self.changes hash] ^ [self.movements hash];
}

#pragma mark Private

+ (MUKArrayDeltaMatchTest)defaultMatchTest {
    return ^(id obj1, id obj2) {
        if ([obj1 isEqual:obj2]) {
            return MUKArrayDeltaMatchTypeEqual;
        }
        
        return MUKArrayDeltaMatchTypeNone;
    };
}

@end
