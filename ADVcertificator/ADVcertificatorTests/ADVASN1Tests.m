//
//  ADVASN1Tests.m
//  ADVcertificatorTests
//
//  Created by Daniel Cerutti on 29/01/13.
//  Copyright (c) 2013 ADVTOOLS. All rights reserved.
//
//  This file is part of ADVcertificator.
//
//  ADVcertificator is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ADVcertificator is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ADVcertificator.  If not, see <http://www.gnu.org/licenses/>.

#import "ADVASN1Tests.h"
#import "ADVASN1.h"

@implementation ADVASN1Tests

int hexdigitValue(unichar ch)
{
    if (ch >= '0' && ch <= '9')
        return ch - '0';
    if (ch >= 'A' && ch <= 'F')
        return ch - 'A' + 10;
    if (ch >= 'a' && ch <= 'f')
        return ch - 'a' + 10;
    return -1;
}


-(NSData *)dataFromHexString:(NSString *)hexString
{
    NSMutableData *data = [[NSMutableData alloc] init];
    for (NSUInteger index = 0; index < (hexString.length - 1); )
    {
        unichar ch1 = [hexString characterAtIndex:index++];
        if (ch1 >= 256)
            break;
        if (isspace(ch1) || ch1 == ':')
            continue;
        
        int val1 = hexdigitValue(ch1);
        int val2 = hexdigitValue([hexString characterAtIndex:index++]);
        if (val1 < 0 || val2 < 0)
            break;
        Byte val = val1 * 16 + val2;
        [data appendBytes:&val length:1];
    }
    return data;
}


-(void)testBooleanItem
{
    ADVASN1 *asn1 = [ADVASN1 ASN1WithData:[self dataFromHexString:@"01 01 ff"]];
    
    STAssertNotNil(asn1, @"ADVASN1 ASN1WithData should return a non nil value when parsing valid data");
    STAssertEquals(asn1.type, ASN1TagBoolean, @"Expecting a boolean type");
    STAssertEquals(asn1.value.length, (NSUInteger)1, @"Boolean should be one byte");
    STAssertEquals(((const Byte *)asn1.value.bytes)[0] , (Byte)0xff, @"Expected True value = 0xff");
}


-(void)testOIDItem
{
    ADVASN1 *asn1 = [ADVASN1 ASN1WithData:[self dataFromHexString:@"06 03 55 04 03"]];
    
    STAssertNotNil(asn1, @"ADVASN1 ASN1WithData should return a non nil value when parsing valid data");
    STAssertEquals(asn1.type, ASN1TagObjectIdentifier, @"Expecting a OID type");
    STAssertEqualObjects(asn1.oidValue, @"2.5.4.3", @"Incorrect oid string returned");
    
}

-(void)testStringItem
{
    ADVASN1 *asn1 = [ADVASN1 ASN1WithData:[self dataFromHexString:@"13 08 414456544F4F4C53"]];
    
    STAssertNotNil(asn1, @"ADVASN1 ASN1WithData should return a non nil value when parsing valid data");
    STAssertEquals(asn1.type, ASN1TagPrintableString, @"Expecting a PrintableString type");
    STAssertEqualObjects(asn1.stringValue, @"ADVTOOLS", @"Incorrect string returned");
    
    asn1 = [ADVASN1 ASN1WithData:[self dataFromHexString:@"14 09 44 65 76 20 73 c3 a0 72 6c"]];
    
    STAssertNotNil(asn1, @"ADVASN1 ASN1WithData should return a non nil value when parsing valid data");
    STAssertEquals(asn1.type, ASN1TagT61String, @"Expecting a T61String type");
    STAssertEqualObjects(asn1.stringValue, @"Dev sàrl", @"Incorrect string returned");

}

-(void)testDateItem
{
    ADVASN1 *asn1 = [ADVASN1 ASN1WithData:[self dataFromHexString:@"17 0D 3031 3031 3031 3030 3030 3030 5A"]];
    
    STAssertNotNil(asn1, @"ADVASN1 ASN1WithData should return a non nil value when parsing valid data");
    STAssertEquals(asn1.type, ASN1TagUTCTime, @"Expecting a UTCTime type");
    STAssertEqualObjects(asn1.dateValue, [NSDate dateWithTimeIntervalSince1970:NSTimeIntervalSince1970], @"Incorrect date returned");
}

-(void)testInitWithTag
{
    ADVASN1 *asn1 = [[ADVASN1 alloc] initWithTag:0x13 value:[self dataFromHexString:@"414456544F4F4C53"]];
    STAssertNotNil(asn1, @"ADVASN1 initWithTag should return a non nil value");
    STAssertEquals(asn1.type, ASN1TagPrintableString, @"Expecting a PrintableString type");
    STAssertEqualObjects(asn1.stringValue, @"ADVTOOLS", @"Incorrect string returned");
}


-(void)testRawData
{
    ADVASN1 *asn1 = [[ADVASN1 alloc] initWithTag:ASN1TagSet isConstructed:YES class:ASN1ClassUniversal value:nil];
    
    
    ADVASN1 *asn1Sequence = [[ADVASN1 alloc] initWithTag:ASN1TagSequence isConstructed:YES class:ASN1ClassUniversal value:nil];
    
    ADVASN1 *asn1Item = [[ADVASN1 alloc] initWithTag:ASN1TagObjectIdentifier isConstructed:NO class:ASN1ClassUniversal
                                              value:[self dataFromHexString:@"55 04 06"]];
    [asn1Sequence addItem:asn1Item];
    asn1Item = [[ADVASN1 alloc] initWithTag:ASN1TagPrintableString isConstructed:NO class:ASN1ClassUniversal
                                               value:[self dataFromHexString:@"43 48"]];
    [asn1Sequence addItem:asn1Item];
    [asn1 addItem:asn1Sequence];
    
    
    NSData* rawData = [self dataFromHexString:@"31 0B 30 09 06 03 55 04 06 13 02 43 48"];
    
    STAssertEqualObjects(asn1.rawData, rawData, @"Incorrect rawData returned");
    
}

@end
