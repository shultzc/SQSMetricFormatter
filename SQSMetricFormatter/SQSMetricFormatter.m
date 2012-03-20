//
//  SQSMetricFormatter.m
//  SQSMetricFormatter
//
//  Created by Conrad Shultz on 11/19/11.
//  Copyright (c) 2011-2012 Synthetiq Solutions LLC. All rights reserved.
//

/*
 Copyright (c) 2011-2012, Synthetiq Solutions LLC.
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 * Neither the name of the Synthetiq Solutions LLC nor the
 names of its contributors may be used to endorse or promote products
 derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL SYNTHETIQ SOLUTIONS LLC BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "SQSMetricFormatter.h"
#import "NSDecimalNumber+NSDecimalNumber_SQSDecimalNumber.h"

@interface SQSMetricFormatter () {
@private
    NSDictionary *_prefixesByPower;
    NSDictionary *_powersByPrefix;
}

- (void)_doInitialSetup;

- (NSInteger)_maxPrefixValue;
- (NSInteger)_minPrefixValue;

- (NSDictionary *)_usablePrefixesByPower;

- (NSDecimalNumber *)_decimalNumberForString:(NSString *)string;

@end

@implementation SQSMetricFormatter

@synthesize baseUnitAbbreviation = _baseUnitAbbreviation;
@synthesize usesMetricPrefixes = _usesMetricPrefixes;
@synthesize ignoresStandardIgnorablePowers = _ignoresStandardIgnorablePowers;
@synthesize powersToIgnore = _powersToIgnore;

#pragma mark -
#pragma mark Initialization/deallocation

- (id)initWithBaseUnitAbbreviation:(NSString *)unitAbbreviation
{
    self = [super init];
    if (self) {
        [self _doInitialSetup];
        _baseUnitAbbreviation = [unitAbbreviation copy];
    }
    return self;
}

+ (id)formatterWithBaseUnitAbbreviation:(NSString *)unitAbbreviation
{
    return [[[[self class] alloc] initWithBaseUnitAbbreviation:unitAbbreviation] autorelease];
}

- (void)awakeFromNib
{
    [self _doInitialSetup];
}

- (void)dealloc
{
    [_powersByPrefix release];
    [_prefixesByPower release];
    [_baseUnitAbbreviation release];
    [super dealloc];
}

#pragma mark -
#pragma mark Custom methods

+ (NSArray *)standardPowersToIgnore
{
    return [NSArray arrayWithObjects:
            [NSNumber numberWithInt:-1],
            [NSNumber numberWithInt:1],
            [NSNumber numberWithInt:2], 
            nil];
}

- (void)_doInitialSetup
{   
    // Used to map strings to object values
    _powersByPrefix = [[NSDictionary alloc] initWithObjectsAndKeys:
                       [NSNumber numberWithInteger:-1], @"d",
                       [NSNumber numberWithInteger:-2], @"c",
                       [NSNumber numberWithInteger:-3], @"m",
                       [NSNumber numberWithInteger:-6], @"μ", 
                       [NSNumber numberWithInteger:-6], @"mc",
                       [NSNumber numberWithInteger:-6], @"µ",
                       [NSNumber numberWithInteger:-9], @"n",
                       [NSNumber numberWithInteger:-12], @"p",
                       [NSNumber numberWithInteger:-15], @"f",
                       [NSNumber numberWithInteger:-18], @"a",
                       [NSNumber numberWithInteger:-21], @"z",
                       [NSNumber numberWithInteger:-24], @"y",
                       [NSNumber numberWithInteger:0], @"",
                       [NSNumber numberWithInteger:1], @"da",
                       [NSNumber numberWithInteger:2], @"h",
                       [NSNumber numberWithInteger:3], @"k",
                       [NSNumber numberWithInteger:6], @"M",
                       [NSNumber numberWithInteger:9], @"G",
                       [NSNumber numberWithInteger:12], @"T",
                       [NSNumber numberWithInteger:15], @"P",
                       [NSNumber numberWithInteger:18], @"E",
                       [NSNumber numberWithInteger:21], @"Z",
                       [NSNumber numberWithInteger:24], @"Y",
                       nil];
    
    // Used to map object values to *unambiguous* strings
    _prefixesByPower = [[NSDictionary alloc] initWithObjectsAndKeys:
                        @"d", [NSNumber numberWithInteger:-1],
                        @"c", [NSNumber numberWithInteger:-2],
                        @"m", [NSNumber numberWithInteger:-3],
                        @"µ", [NSNumber numberWithInteger:-6],
                        @"n", [NSNumber numberWithInteger:-9],
                        @"p", [NSNumber numberWithInteger:-12],
                        @"f", [NSNumber numberWithInteger:-15],
                        @"a", [NSNumber numberWithInteger:-18],
                        @"z", [NSNumber numberWithInteger:-21],
                        @"y", [NSNumber numberWithInteger:-24],
                        @"", [NSNumber numberWithInteger:0],
                        @"da", [NSNumber numberWithInteger:1],
                        @"h", [NSNumber numberWithInteger:2],
                        @"k", [NSNumber numberWithInteger:3],
                        @"M", [NSNumber numberWithInteger:6],
                        @"G", [NSNumber numberWithInteger:9],
                        @"T", [NSNumber numberWithInteger:12],
                        @"P", [NSNumber numberWithInteger:15],
                        @"E", [NSNumber numberWithInteger:18],
                        @"Z", [NSNumber numberWithInteger:21],
                        @"Y", [NSNumber numberWithInteger:24],
                        nil];

    // NSUIntegerMax does not work
    [self setMaximumFractionDigits:1000];
    [self setMaximumIntegerDigits:1000];
    
    _usesMetricPrefixes = YES;
    
    // Work around an API bug that sets default to NO, contrary to documentation
    [self setGeneratesDecimalNumbers:YES];
}

- (NSInteger)_maxPrefixValue
{
    static NSInteger maxValue = NSIntegerMax;
    if (maxValue == NSIntegerMax) {
        NSArray *prefixes = [_prefixesByPower allKeys];
        NSExpression *expr = [NSExpression expressionForKeyPath:@"@max.self"];
        NSNumber *max = [expr expressionValueWithObject:prefixes context:nil];
        maxValue = [max integerValue];
    }

    return maxValue;
}

- (NSInteger)_minPrefixValue
{
    static NSInteger minValue = NSIntegerMax;
    if (minValue == NSIntegerMax) {
        NSArray *prefixes = [_prefixesByPower allKeys];
        NSExpression *expr = [NSExpression expressionForKeyPath:@"@min.self"];
        NSNumber *min = [expr expressionValueWithObject:prefixes context:nil];
        minValue = [min integerValue];
    }
    return minValue;
}

- (NSDictionary *)_usablePrefixesByPower
{
    NSMutableDictionary *usablePrefixes = [_prefixesByPower mutableCopy];
    [usablePrefixes removeObjectsForKeys:[self powersToIgnore]];
    return [usablePrefixes autorelease];
}

- (NSDecimalNumber *)_decimalNumberForString:(NSString *)string
{
    NSDecimalNumber *numericValue = nil;
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceCharacterSet];
    NSString *realString = [string stringByTrimmingCharactersInSet:whitespace];
    if ([realString length]) {
        NSScanner *scanner = [NSScanner scannerWithString:realString];
        [scanner setCharactersToBeSkipped:nil];
        NSDecimal numericPortion;
        if ([scanner scanDecimal:&numericPortion]) {
            numericValue = [NSDecimalNumber decimalNumberWithDecimal:numericPortion];
            [scanner scanCharactersFromSet:whitespace intoString:nil];
            if (! [scanner isAtEnd]) {
                NSString *abbrev = [self baseUnitAbbreviation];
                NSString *residue = [realString substringFromIndex:[scanner scanLocation]];
                NSNumber *multiplier = nil;
                if ([residue hasSuffix:abbrev]) {
                    residue = [residue substringToIndex:([residue length] - [abbrev length])];
                    if ([residue length] > 0) {
                        multiplier = [_powersByPrefix objectForKey:residue];
                        if (multiplier == nil) {
                            numericValue = nil;
                        }
                    }
                }
                else {
                    multiplier = [_powersByPrefix objectForKey:residue];
                    if (multiplier == nil) {
                        numericValue = nil;
                    }
                }
                if (multiplier != nil) {
                    numericValue = [numericValue decimalNumberByMultiplyingByPowerOf10:[multiplier shortValue]];
                }
            }
        }
    }
    return numericValue;
}

#pragma mark -
#pragma mark Getters/setters

- (void)setIgnoresStandardIgnorablePowers:(BOOL)shouldIgnore
{
    if (shouldIgnore) {
        [self setPowersToIgnore:[[self class] standardPowersToIgnore]];
    }
    else {
        [self setPowersToIgnore:nil];
    }
    _ignoresStandardIgnorablePowers = shouldIgnore;
}

#pragma mark -
#pragma mark Superclass methods

- (NSString *)stringForObjectValue:(id)obj
{
    if (obj == nil) {
        return nil;
    }
    NSDecimalNumber *decimalObj = [NSDecimalNumber decimalNumberWithNumber:obj];
    BOOL isNegative = [decimalObj isNegative];
    
    NSString *stringWithoutLabel;
    NSString *prefix = @"";
    NSString *abbrev = [self baseUnitAbbreviation];
    
    if ([self usesMetricPrefixes] && ! [decimalObj isEqualToNumber:[NSDecimalNumber zero]]) {
        if (isNegative) {
            decimalObj = [decimalObj decimalNumberByNegation];
        }
        
        // decimalObj is now guaranteed to be > 0
        NSDecimalNumber *normalizedDecimal;
        if ([decimalObj compare:[NSDecimalNumber one]] == NSOrderedAscending) {
            // 1 / decimalObj
            normalizedDecimal = [[NSDecimalNumber one] decimalNumberByDividingBy:decimalObj];
        }
        else {
            normalizedDecimal = decimalObj;
        }
        NSInteger power;
        if (normalizedDecimal != decimalObj) {
            power = - (NSInteger)ceil(log10([normalizedDecimal doubleValue]));
        }
        else {
            power = (NSInteger)floor(log10([normalizedDecimal doubleValue]));
        }
        NSDictionary *usablePrefixes = [self _usablePrefixesByPower];
        if (! [usablePrefixes objectForKey:[NSNumber numberWithInteger:power]]) {
            NSInteger minPrefixValue = [self _minPrefixValue];
            NSInteger maxPrefixValue = [self _maxPrefixValue];
            NSInteger i, j;
            for (i = power; i <= maxPrefixValue; i++) {
                if ([usablePrefixes objectForKey:[NSNumber numberWithInteger:i]]) {
                    break;
                }
            }
            i = fmin(i, maxPrefixValue);
            for (j = power; j >= minPrefixValue; j--) {
                if ([usablePrefixes objectForKey:[NSNumber numberWithInteger:j]]) {
                    break;
                }
            }
            j = fmax(j, minPrefixValue);
            // Find the closest usable power to the ideal power
            power = (NSInteger)((fabs(power - i) < fabs(power - j)) ? i : j);
        }
        prefix = [_prefixesByPower objectForKey:[NSNumber numberWithInteger:power]];
        decimalObj = [decimalObj decimalNumberByMultiplyingByPowerOf10:-(short)power];
        if (isNegative) {
            decimalObj = [decimalObj decimalNumberByNegation];
        }
    }
    stringWithoutLabel = [super stringForObjectValue:decimalObj];
    
    return [NSString stringWithFormat:@"%@ %@%@", stringWithoutLabel, prefix, abbrev];
}

- (BOOL)getObjectValue:(id *)obj 
             forString:(NSString *)string 
                 range:(NSRange *)rangep
                 error:(NSError **)error
{
    NSDecimalNumber *d = [self _decimalNumberForString:string];
    NSString *realString = [d stringValue];
    if (realString == nil) {
        realString = @"";
    }
    return [super getObjectValue:obj
                       forString:realString
                           range:nil
                           error:error];
}

- (BOOL)isPartialStringValid:(NSString *)partialString
            newEditingString:(NSString **)newString
            errorDescription:(NSString **)error
{
    if (partialString == nil || [partialString isEqualToString:@""]) {
        return YES;
    }
    else {
        return ([self _decimalNumberForString:partialString] != nil);
    }
}


@end
