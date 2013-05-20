//
//  ADVX500DistinguishedName.h
//  ADVcertificator
//
//  Created by Daniel Cerutti on 22/01/13.
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
#import "ADVASN1.h"

typedef NS_OPTIONS(NSUInteger, ADVX500DistinguishedNameFlags) {
    X500FormatNone = 0,
    X500FormatUseSemiColumns = 2,
    X500FormatDoNotUsePlusSign = 4,
    X500FormatDoNotUseQuotes = 8,
    X500FormatUseCommas = 0x10,
    X500FormatUseNewLines = 0x20
};

/// Represents an X500 distinguished name (like the subject or the issuer of a certificate)

@interface ADVX500DistinguishedName : NSObject

///---------------------------------------------------------
/// @name Creating an initializing an ADVX500DistinguishedName

/// Creates a ADVX500DistinguishedName instance from an ADVASN1 object
/// @param asn1 An ADVASN1 object representing an distinguished name
+(ADVX500DistinguishedName *)distinguishedNameFromASN1:(ADVASN1 *)asn1;

/// Initialize a ADVX500DistinguishedName instance from an ADVASN1 object
/// @param asn1 An ADVASN1 object representing an distinguished name
-(id)initFromASN1:(ADVASN1 *)asn1;

///---------------------------------------------------------
/// @name Reading properties

/// Get the binary encoding of this ADVX500DistinguishedName
-(NSData *)rawData;

/// Get the name of this ADVX500DistinguishedName in comma delimited form
@property (strong, nonatomic) NSString *name;

/// Get the name of this ADVX500DistinguishedName in the specified format
///
/// @param flags Specifies the desired formatting as a combination of one or more of the following flags
///
/// - X500FormatUseSemiColumns: Uses semi-columns as the field deliminator.
/// - X500FormatUseCommas: Uses commas ast he field deliminator.
/// - X500FormatUseNewLines: Each field is in a separate text line
-(NSString *)formattedName:(ADVX500DistinguishedNameFlags)flags;

/// Get the text of the common name (CN) field.
-(NSString *)getCommonName;

@end
