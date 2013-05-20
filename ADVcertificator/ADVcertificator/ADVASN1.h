//
//  ADVASN1.h
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

#import <Foundation/Foundation.h>

typedef NS_ENUM(int, ASN1Tag) {
    ASN1TagBoolean = 1,
    ASN1TagInteger = 2,
    ASN1TagBitString = 3,
    ASN1TagOctetString = 4,
    ASN1TagNull = 5,
    ASN1TagObjectIdentifier = 6,
    ASN1TagObjectDescriptor = 7,
    ASN1TagExternal = 8,
    ASN1TagReal = 9,
    ASN1TagEnumerated = 10,
    ASN1TagEmbeddedPDV = 11,
    ASN1TagUTF8String = 12,
    ASN1TagRelativeOID = 13,
    ASN1TagSequence = 16,
    ASN1TagSet = 17,
    ASN1TagNumericString = 18,
    ASN1TagPrintableString = 19,
    ASN1TagT61String = 20,
    ASN1TagVideotexString = 21,
    ASN1TagIA5String = 22,
    ASN1TagUTCTime = 23,
    ASN1TagGeneralizedTime = 24,
    ASN1TagGraphicString = 25,
    ASN1TagVisibleString = 26,
    ASN1TagGeneralString = 27,
    ASN1TagUniversalString = 28,
    ASN1TagCharacterString = 29,
    ASN1TagBMPString = 30 // Unicode string
};

typedef NS_ENUM(int, ASN1Class) {
    ASN1ClassUniversal = 0x00,
    ASN1ClassApplication = 0x40,
    ASN1ClassContext = 0x80,
    ASN1ClassPrivate = 0xc0
};

/**
 A simple ASN1 parser which supports the subset used for certificates
 */
@interface ADVASN1 : NSObject

/// @name Creating an initializing an ADVASN1
///
/// constructs an ADVASN1 instance by parsing the providing ASN1 data which must be in DER form
/// @param data the ASN1 encoded data as an NSData instance
+(ADVASN1 *)ASN1WithData:(NSData *)data;


/// initialize an ADVASN1 instance by parsing the providing ASN1 data which must be in DER form
/// @param data the ASN1 encoded data as an NSData instance
-(id)initWithData:(NSData *)data;

/// initialize an ADVASN1 instance with the provided tag and value
/// @param tag the ASN1 tag value (only tag type 0-30 which are encoded as a single byte is supported
/// @param value the ASN1 encoded value for this item
-(id)initWithTag:(Byte)tag value:(NSData *)value;

/// initialize an ADVASN1 instance with the provided tag and value
/// @param type the ASN1Tag value (only tag type 0-30 which are encoded as a single byte is supported
/// @param isConstructed YES if it is a composite type
/// @param class The ASN1 class
/// @param value the ASN1 encoded value for this item
-(id)initWithTag:(ASN1Tag)type isConstructed:(BOOL)isConstructed class:(ASN1Class)class value:(NSData *)value;

/// @name Getting properties and values
///
/// The raw ASN1 encoded content
@property (readonly, strong, nonatomic) NSData *rawData;

/// The ASN1 tag class
-(ASN1Class)class;

/// Returns YES if the item is constructed (contains subitems)
-(BOOL)isConstructed;

/// The ASN1 tag type value
-(ASN1Tag)type;

/// The binary value of the element
@property (readonly, strong, nonatomic) NSData *value;


-(BOOL)booleanValue;

/// the value converted to a NSDate for type ASN1TagUTCTime and ASN1TagGeneralizedTime
///
/// returns nil if the value is not a valid time
-(NSDate *)dateValue;

/// the value converted to an object identifier string for type ASN1TagObjectIdentifier
///
/// returns nil if the value is not an object identifier type
-(NSString *)oidValue;

/// the value converted to a NSString for all string types
///
/// returns nil if the value is not a string type
-(NSString *)stringValue;

/// @name Accessing and building constructed ASN1 item
///
/// Adds an ASN1 to this item which must be an ASN1 constructed item
///
/// @param asn1 the ASN1 subitem to add to this item.
-(void)addItem:(ADVASN1 *)asn1;

/// Get the number of items in this item. Always 0 for non constructed type.
-(NSUInteger)itemCount;

/// returns the specified item
///
/// @param index the index of the item to return
-(ADVASN1 *)getItem:(NSUInteger)index;

/// @name Dumping the content
///
/// Write a text representation of the ASN1 data to the specified NSFileHandle.
///
/// @param file a NSFileHandle to write to.
-(void)dump:(NSFileHandle *)file;


@end
