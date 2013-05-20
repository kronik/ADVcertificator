//
//  ADVNSData-Base64.h
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

/// Add base64 encoding/decoding methods to NSData
@interface NSData(ADVBase64)

/// initialize a NSData from a base64 encoded string
///
/// @param base64String a base64 string
-(id)initWithBase64String:(NSString *)base64String;

/// encode this NSData instance data in base64
///
/// @returns a string with the base64 encoded data
-(NSString *)getBase64String;

@end
