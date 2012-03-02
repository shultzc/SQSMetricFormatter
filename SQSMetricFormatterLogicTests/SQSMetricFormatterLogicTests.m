//
//  SQSMetricFormatterLogicTests.m
//  SQSMetricFormatterLogicTests
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

#import "SQSMetricFormatterLogicTests.h"
#import "NSDecimalNumber+NSDecimalNumber_SQSDecimalNumber.h"

@interface SQSMetricFormatterLogicTests() {
@private
    SQSMetricFormatter *_gramFormatter;
}

- (void)_resetFormatter;

@end

@implementation SQSMetricFormatterLogicTests

- (void)_resetFormatter
{
    [_gramFormatter setUsesMetricPrefixes:YES];
    [_gramFormatter setPowersToIgnore:nil];
}

- (void)setUp
{
    [super setUp];
    _gramFormatter = [[SQSMetricFormatter alloc] initWithBaseUnitAbbreviation:@"g"];
    [self _resetFormatter];
}

- (void)tearDown
{
    [_gramFormatter release];
    [super tearDown];
}

- (void)testClaSQSMethodInstantiation
{
    SQSMetricFormatter *testFormatter = [SQSMetricFormatter formatterWithBaseUnitAbbreviation:@"g"];
    STAssertNotNil(testFormatter, @"Formatter should be non-nil");
    NSString *abbrev1 = [testFormatter baseUnitAbbreviation];
    NSString *abbrev2 = [_gramFormatter baseUnitAbbreviation];
    STAssertEqualObjects(abbrev1, abbrev2, @"Formatter unit abbreviations do not match");
}

- (void)testNonFractionConversion
{
    [self _resetFormatter];
    NSNumber *integerInput = [NSNumber numberWithInt:1220];
    NSDecimalNumber *doubleInputFraction = [NSDecimalNumber decimalNumberWithString:@"1220.0221"];
        
    NSString *unlabeledIntString = [integerInput stringValue];
    NSString *unlabeledDblFracString = [doubleInputFraction stringValue];
    
    NSString *baseLabeledIntStringNoSpace = [unlabeledIntString stringByAppendingString:@"g"];
    NSString *baseLabeledIntStringSpace = [unlabeledIntString stringByAppendingString:@" g"];
    NSString *baseLabeledIntStringFourSpace = [unlabeledIntString stringByAppendingString:@"    g"];   
    
    NSString *baseLabeledDblFracStringNoSpace = [unlabeledDblFracString stringByAppendingString:@"g"];
    NSString *baseLabeledDblFracStringSpace = [unlabeledDblFracString stringByAppendingString:@" g"];
    NSString *baseLabeledDblFracStringFourSpace = [unlabeledDblFracString stringByAppendingString:@"    g"];
    
    NSNumber *baseLabeledIntNumberResultNoSpace, *baseLabeledIntNumberResultSpace, *baseLabeledIntNumberResultFourSpace;
    
    baseLabeledIntNumberResultNoSpace = [_gramFormatter numberFromString:baseLabeledIntStringNoSpace];
    baseLabeledIntNumberResultSpace = [_gramFormatter numberFromString:baseLabeledIntStringSpace];
    baseLabeledIntNumberResultFourSpace = [_gramFormatter numberFromString:baseLabeledIntStringFourSpace];
    
    STAssertEqualObjects(baseLabeledIntNumberResultNoSpace, integerInput, @"Incorrect integer conversion result");
    STAssertEqualObjects(baseLabeledIntNumberResultSpace, integerInput, @"Incorrect integer conversion result");
    STAssertEqualObjects(baseLabeledIntNumberResultFourSpace, integerInput, @"Incorrect integer conversion result");
    
    NSNumber *baseLabeledDblFracNumberResultNoSpace, *baseLabeledDblFracNumberResultSpace, *baseLabeledDblFracNumberResultFourSpace;
    
    baseLabeledDblFracNumberResultNoSpace = [_gramFormatter numberFromString:baseLabeledDblFracStringNoSpace];
    baseLabeledDblFracNumberResultSpace = [_gramFormatter numberFromString:baseLabeledDblFracStringSpace];
    baseLabeledDblFracNumberResultFourSpace = [_gramFormatter numberFromString:baseLabeledDblFracStringFourSpace];
    
    STAssertEqualObjects(baseLabeledDblFracNumberResultNoSpace, doubleInputFraction, @"Incorrect double conversion result");
    STAssertEqualObjects(baseLabeledDblFracNumberResultSpace, doubleInputFraction, @"Incorrect double conversion result");
    STAssertEqualObjects(baseLabeledDblFracNumberResultFourSpace, doubleInputFraction, @"Incorrect double conversion result");
}

- (void)testFractionConversion
{
    [self _resetFormatter];
    NSNumber *input = [NSNumber numberWithDouble:0.0275];
    NSString *output = [_gramFormatter stringForObjectValue:input];
    STAssertTrue([output isEqualToString:@"2.75 cg"], @"Incorrect fraction conversion result");
}

- (void)testNil
{
    [self _resetFormatter];
    NSString *result = [_gramFormatter stringFromNumber:nil];
    STAssertNil(result, @"Nil number should return nil string");
}

- (void)testRespectsPrefixProperty
{
    [self _resetFormatter];
    
    NSNumber *input = [NSNumber numberWithFloat:1234.56f];
    
    [_gramFormatter setUsesMetricPrefixes:YES];
    NSString *stringWithPrefix = [_gramFormatter stringForObjectValue:input];
    STAssertEqualObjects(stringWithPrefix, @"1.23456 kg", @"Prefixed string does not match expected value");
    
    [_gramFormatter setUsesMetricPrefixes:NO];
    NSString *stringWithoutPrefix = [_gramFormatter stringForObjectValue:input];
    STAssertEqualObjects(stringWithoutPrefix, @"1234.56 g", @"Non-prefixed string does not match expected value");
}

- (void)testIgnoresMinorPrefixes
{
    [self _resetFormatter];
    
    NSNumber *input = [NSNumber numberWithInt:123];
    NSString *expectedOutputNoIgnore = @"1.23 hg";
    NSString *expectedOutputIgnore = @".123 kg";
    
    NSString *actualOutputNoIgnore = [_gramFormatter stringFromNumber:input];
    STAssertEqualObjects(actualOutputNoIgnore, expectedOutputNoIgnore, @"String not ignoring minor prefixes does not match expected string");
    
    [_gramFormatter setIgnoresStandardIgnorablePowers:YES];
    NSString *actualOutputIgnore = [_gramFormatter stringFromNumber:input];
    STAssertEqualObjects(actualOutputIgnore, expectedOutputIgnore, @"String ignoring minor prefixes does not match expected string");
}

- (void)testHandlingOfZero
{
    [self _resetFormatter];
    
    NSNumber *zero = [NSNumber numberWithInt:0];
    NSString *expectedOutput = @"0 g";
    NSString *actualOutput = [_gramFormatter stringFromNumber:zero];
    STAssertEqualObjects(actualOutput, expectedOutput, @"Zero formatting produces unexpected results");
}


@end
