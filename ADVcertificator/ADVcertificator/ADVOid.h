//
//  ADVOid.h
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

/// Represents an object identifier
///
@interface ADVOid : NSObject

/// Create an ADVOid object from an object identifier string
/// @param oidString An object identifier string (like "2.5.4.3")
+(ADVOid *)oidFromOidString:(NSString *)oidString;

/// Initialize an ADVOid object from an object identifier string
/// @param oidString An object identifier string (like "2.5.4.3")
-(id)initFromOidString:(NSString *)oidString;

/// Get or set the descriptive name of the OID
@property (strong, nonatomic) NSString *friendlyName;

/// Get or set the OID string
@property (strong, nonatomic) NSString *value;

@end
