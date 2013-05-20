//
//  ADVASN1.m
//  ADVcertificator
//
//  Created by Daniel Cerutti on 1/17/13.
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

#import "ADVASN1.h"
#import "ADVOid.h"
#import "ADVNSFileHandleExtension.h"
#import "ADVLog.h"
#include "xlocale.h"

typedef NS_ENUM(int, ASN1DecodeStatus) {
    ASN1DecodeStatusOk = 0,
    ASN1DecodeStatusInvalidLength = 1,
    ASN1DecodeStatusUnsupportedTag = 2
};

#define ASN1ClassMask   0xc0
#define ASN1ConstructedMask 0x20
#define ASN1TagMask 0x1f
#define ASN1LongTagPrefix 31

@interface ADVASN1()

@property (readwrite,strong,nonatomic) NSData *rawData;

@property (readwrite,strong, nonatomic) NSData *value;
@property (readwrite, nonatomic) Byte tag;
@property (strong, nonatomic) NSMutableArray *elementList;

@end


@implementation ADVASN1

@synthesize rawData = _rawData;
@synthesize tag = _tag;
@synthesize value = _value;
@synthesize elementList = _elementList;


#pragma mark Class methods

+(ADVASN1 *)ASN1WithData:(NSData *)data;
{
    return [[ADVASN1 alloc] initWithData:data];
}

#pragma mark Initialization

-(id)initWithData:(NSData *)data
{
    self = [super init];
    if (self == nil)
        return self;
    
    NSUInteger dataLength = data.length;
    if (dataLength < 2)
        return nil;
    
    const Byte * bytes = (const Byte *)data.bytes;
    NSUInteger pos = 0;
    self.tag = bytes[pos++];
    if (self.type == ASN1LongTagPrefix)
    {
        NSLog(@"ASN1 tag >= 31 are not supported in this version");
        return nil;
    }
    NSUInteger length = [self decodeLength:bytes positionRef:&pos dataLength:dataLength];
    if (length == NSUIntegerMax)
    {
        NSLog(@"Invalid length decoding tag:%02x pos:%08lx", self.tag, (unsigned long)pos);
        return nil;
    }
    if (length > (dataLength - pos))
    {
        NSLog(@"Length too large for tag:%02x pos:%08lx length:%lu", self.tag, (unsigned long)pos, (unsigned long)length);
        return nil;
    }
    
    self.rawData = data;
    if (length != 0)
    {
        self.value = [data subdataWithRange:NSMakeRange(pos, length)];
        if (self.isConstructed)
        {
            ASN1DecodeStatus status = [self decode:data startPos:pos elementLength:length];
            if (status != ASN1DecodeStatusOk)
                return nil;
        }
        return self;
    }
    return self;
}

-(id)initWithTag:(Byte)tag value:(NSData *)value
{
    self = [super init];
    if (self == nil)
        return self;
    
    self.tag = tag;
    self.value = value;
    return self;
}

-(id)initWithTag:(ASN1Tag)type isConstructed:(BOOL)isConstructed class:(ASN1Class)class value:(NSData *)value
{
    if (type >= 31)
        return nil; // long ASN1 tag not supported
    Byte tag = type | class | (isConstructed ? ASN1ConstructedMask : 0);
    return [self initWithTag:tag value:value];
}


#pragma mark Property accessors

-(ASN1Class)class
{
    return self.tag & ASN1ClassMask;
}

-(BOOL)isConstructed
{
    return (self.tag & ASN1ConstructedMask) == ASN1ConstructedMask;
}

-(ASN1Tag)type
{
    return self.tag & ASN1TagMask;
}

-(BOOL)booleanValue
{
    //TODO: how should we handle invalid type or value for scalar types?
    if (self.isConstructed || self.class != ASN1ClassUniversal || self.type != ASN1TagBoolean)
    {
        return NO;
    }
    if (self.value.length != 1)
        return NO;
    return ((const Byte *)self.value.bytes)[0] != 0;
}


-(NSDate *)dateValue
{
    if (self.isConstructed || self.class != ASN1ClassUniversal)
        return nil;
    if (self.type != ASN1TagUTCTime && self.type != ASN1TagGeneralizedTime)
        return nil;
    
    // Allocate 3 more characters: 2 leading character to add 2 first digits of year if missing and null terminator
    unsigned long dateStringBufferLength = self.value.length + 3;
    char *dateStringBuffer = malloc(dateStringBufferLength * sizeof(char));
    if (dateStringBuffer == NULL)
        return nil;
    dateStringBuffer[dateStringBufferLength - 1] = 0;
    
    char *dateString = &dateStringBuffer[2];
    [self.value getBytes:dateString length:self.value.length];
    
    struct tm tdate;
    memset(&tdate, 0, sizeof(tdate));
    
    switch (self.value.length)
    {
        case 13:
            // RFC3280: 4.1.2.5.1  UTCTime
            // WARNING: strptime will interpret a YY less than 69 as 20YY while
            // the standard specifies that an YY less than 50 should be interpreted as 20YY
            {
                int year;
                sscanf(dateString, "%2d", &year);
                if (year >= 50)
                    memcpy(dateStringBuffer, "19", 2);
                else
                    memcpy(dateStringBuffer, "20", 2);
                strptime_l(dateStringBuffer, "%Y%m%d%H%M%SZ", &tdate, NULL);
            }
            break;
        case 15:
            // GeneralizedTime
            strptime_l(dateString, "%Y%m%d%H%M%SZ", &tdate, NULL);
            break;
        case 11:
            // illegal format supported for compatibility
            strptime_l(dateString, "%y%m%d%H%MZ", &tdate, NULL);
            break;
        case 17:
            // another illegal format (990630000000+1000) again supported for compatibility
            {
                int year;
                sscanf(dateString, "%2d", &year);
                if (year >= 50)
                    memcpy(dateStringBuffer, "19", 2);
                else
                    memcpy(dateStringBuffer, "20", 2);
                strptime_l(dateStringBuffer, "%Y%m%d%H%M%S%z", &tdate, NULL);
            }
            break;
        default:
            return nil;
    }
    free (dateStringBuffer);
    
    NSTimeInterval ti = timegm(&tdate);
    return [NSDate dateWithTimeIntervalSince1970:ti];
}

-(NSString *)oidValue
{
    if (self.isConstructed || self.class != ASN1ClassUniversal || self.type != ASN1TagObjectIdentifier)
        return nil;
    
    Byte *bytes = (Byte *)self.value.bytes;
    NSUInteger length = self.value.length;
    
    Byte o1 = bytes[0] / 40;
    Byte o2 = bytes[0] % 40;
    NSMutableString *oid = [[NSMutableString alloc] initWithFormat:@"%u.%u", o1, o2];

    NSUInteger value = 0;
    for (int index = 1; index < length; index++)
    {
        value = (value << 7) + (bytes[index] & 0x7f);
        if ((bytes[index] & 0x80) == 0)
        {
            [oid appendFormat:@".%lu", (unsigned long)value];
            value = 0;
        }
    }
    return oid;
}

-(NSString *)stringValue
{
    if (self.isConstructed || self.class != ASN1ClassUniversal)
        return nil;
    
    NSString *stringValue = nil;
    switch (self.type)
    {
        case ASN1TagBMPString:
            stringValue = [[NSString alloc] initWithData:self.value encoding:NSUTF16StringEncoding];
            break;
        case ASN1TagNumericString:
        case ASN1TagPrintableString:
        case ASN1TagIA5String:
        case ASN1TagVideotexString:
            stringValue = [[NSString alloc] initWithData:self.value encoding:NSASCIIStringEncoding];
            break;
        case ASN1TagUTF8String:
        case ASN1TagT61String:
        case ASN1TagGraphicString:
        case ASN1TagGeneralString:
        case ASN1TagCharacterString:
            stringValue = [[NSString alloc] initWithData:self.value encoding:NSUTF8StringEncoding];
            break;
        case ASN1TagUniversalString:
            stringValue = [[NSString alloc] initWithData:self.value encoding:NSUTF32StringEncoding];
            break;
        default:
            break;
    }
    return stringValue;
}

-(NSData *)rawData
{
    if (_rawData != nil)
        return _rawData;
    
    // Construct the encoded data
    NSMutableData *encodedData = [[NSMutableData alloc] init];

    if (self.isConstructed)
    {
        NSMutableData *value = [[NSMutableData alloc] init];
        for (ADVASN1 *element in self.elementList)
        {
            [value appendData:element.rawData];
        }
        self.value = [value copy];
    }

    [encodedData appendBytes:&_tag length:1];
    if (self.value.length < 128)
    {
        Byte length = self.value.length;
        [encodedData appendBytes:&length length:1];
    }
    else
    {
        Byte encodedLength[sizeof(NSUInteger) + 1];
        NSUInteger length = self.value.length;
        int pos = sizeof(NSUInteger);
        while (length != 0)
        {
            encodedLength[pos] = length & 0xff;
            length /= 256;
            pos--;
        }
        encodedLength[pos] = (sizeof(NSUInteger) - pos) | 0x80;
        [encodedData appendBytes:&encodedLength[pos] length:(sizeof(NSUInteger) - pos + 1)];
    }
    [encodedData appendBytes:self.value.bytes length:self.value.length];

    return [encodedData copy];
}


#pragma mark child items access

-(void)internalAddItem:(ADVASN1 *)asn1
{
    if (self.elementList == nil)
        self.elementList = [NSMutableArray arrayWithCapacity:1];
    [self.elementList addObject:asn1];
}


-(void)addItem:(ADVASN1 *)asn1
{
    [self internalAddItem:asn1];
    // Invalidate rawdata so it will be reevaluated when requested
    self.rawData = nil;
    self.value = nil;
}

-(NSUInteger)itemCount
{
    if (self.elementList != nil)
        return self.elementList.count;
    return 0;
}

-(ADVASN1 *)getItem:(NSUInteger)index
{
    return self.elementList[index];
}

#pragma mark internal parsing methods

// returns NSUIntegerMax if we find an invalid length
-(NSUInteger)decodeLength:(const Byte *)bytes positionRef:(NSUInteger *)posRef dataLength:(NSUInteger)dataLength
{
    if (*posRef >= dataLength)
        return NSUIntegerMax;
    
    NSUInteger length = bytes[(*posRef)++];
    unsigned lengthlen = 0;
    if (length > 0x80)
    {   // composed length
        lengthlen = length & 0x7f;
        if ((lengthlen + (*posRef)) > dataLength)
        {
            // ERROR
            return NSUIntegerMax;
        }
        length = 0;
        for (int i = 0; i < lengthlen; i++)
        {
            Byte lengthByte = bytes[(*posRef)++];
            
            // check to avoid arithmetic overflow
            if (length >= ((NSUIntegerMax - lengthByte) / 256))
                return NSUIntegerMax;
            
            length = length * 256 + lengthByte;
        }
    }
    else if (length == 0x80)
    {   // the indefinite form is not supported
        NSLog(@"ASN1 indefinite form is not supported");
        return NSUIntegerMax;
    }
    return length;
    
}

-(ASN1DecodeStatus)decode:(NSData *)data startPos:(NSUInteger)pos elementLength:(NSUInteger)elementLength
{
    NSUInteger lastPos = pos + elementLength - 1;
    assert(lastPos < data.length);
    
    const Byte * bytes = (const Byte *)data.bytes;
    
    // minimum is 2 bytes (tag and zero length)
    while (pos < lastPos)
    {
        NSUInteger startElementPos = pos;
        Byte tag = bytes[pos++];
        if (self.type == ASN1LongTagPrefix)
        {
            NSLog(@"ASN1 tag >= 31 are not supported in this version");
            return ASN1DecodeStatusUnsupportedTag;
        }
        long length = [self decodeLength:bytes positionRef:&pos dataLength:(lastPos + 1)];
        if (length == NSUIntegerMax)
        {
            NSLog(@"Invalid length decoding tag:%02x pos:%08lx", tag, (unsigned long)pos);
            return ASN1DecodeStatusInvalidLength;
        }
        if (length > (lastPos + 1 - pos))
        {
            NSLog(@"Length too large for Tag:%02x pos:%08lx length:%lu", tag, (unsigned long)pos, (unsigned long)length);
            return ASN1DecodeStatusInvalidLength;
        }
        
        if (tag != 0)
        {
            NSData *elementData = [data subdataWithRange:NSMakeRange(startElementPos, length - startElementPos + pos)];
            NSData *value = [data subdataWithRange:NSMakeRange(pos, length)];
            ADVASN1 *element = [[ADVASN1 alloc] initWithTag:tag value:value];
            element.rawData = elementData;
            [self internalAddItem:element];
            
            if (element.isConstructed)
            {
                ASN1DecodeStatus status = [element decode:data startPos:pos elementLength:length];
                if (status != ASN1DecodeStatusOk)
                    return status;
            }
        }
        pos += length;
    }
    return ASN1DecodeStatusOk;
}

#pragma mark debugging and dump

-(void)dump:(NSFileHandle *)file withIndent:(int)indent
{
    static const char* typeNames[] = {
        "EOC",
        "Boolean",
        "Integer",
        "BitString",
        "OctetString",
        "Null",
        "ObjectIdentifier",
        "Object Descriptor",
        "External",
        "Real",
        "Enumerated",
        "Embedded PDV",
        "UTF8String",  // 12
        "Relative-OID",
        "14",
        "15",
        "Sequence",
        "Set",
        "NumericString",
        "PrintableString",
        "T61String",
        "VideotexString",
        "IA5String",
        "UTCTime",
        "GeneralizedTime",
        "GraphicString",
        "VisibleString",
        "GeneralString",
        "UniversalString",
        "CHARACTER STRING",
        "BMPString"
    };
    
    if (self.class == ASN1ClassUniversal)
        [file writeLine:@"%*stag: %02x (%s)", indent, "", self.tag, typeNames[self.type]];
    else
        [file writeLine:@"%*stag: %02x", indent, "", self.tag];
    if (self.elementList != nil)
    {
        for (ADVASN1 *asn1 in self.elementList)
        {
            [asn1 dump:file withIndent:(indent + 2)];
        }
    }
    else
    {
        NSMutableString *value;
        
        if (self.class == ASN1ClassUniversal && (self.type == ASN1TagPrintableString || self.type == ASN1TagUTCTime || self.type == ASN1TagGeneralizedTime))
        {
            value = [[NSMutableString alloc] initWithData:self.value encoding:NSASCIIStringEncoding];
            [file writeLine:@"%*svalue: \"%@\"", indent, "", value];
        }
        else if (self.class == ASN1ClassUniversal && self.type == ASN1TagObjectIdentifier)
        {
            ADVOid* oid = [ADVOid oidFromOidString:self.oidValue];
            [file writeLine:@"%*svalue: %@", indent, "", oid.friendlyName];
        }
        else
        {
            const Byte* bytes = self.value.bytes;
            for (int hexRow = 0; hexRow < ((self.value.length + 15) / 16); hexRow++)
            {
                value = [[NSMutableString alloc] init];
                for (int hexCol = 0; hexCol < 16 && hexCol < (self.value.length - hexRow * 16); hexCol++)
                {
                    [value appendFormat:@" %02x", bytes[hexCol + hexRow * 16]];
                }
                if (hexRow == 0)
                    [file writeLine:@"%*svalue:%@", indent, "", value];
                else
                    [file writeLine:@"%*s%@", indent + 6, "", value];
            }
        }
    }
    
}


-(void)dump:(NSFileHandle *)file
{
    [self dump:file withIndent:0];
}

@end
