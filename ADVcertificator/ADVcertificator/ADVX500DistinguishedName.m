//
//  ADVX500DistinguishedName.m
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

#import "ADVX500DistinguishedName.h"
#import "ADVOid.h"
#import "ADVLog.h"



@interface ADVX500DistinguishedName()

@property (strong, nonatomic) ADVASN1 *asn1;
@property (strong, nonatomic) NSString *commonName;

@end



@implementation ADVX500DistinguishedName

@synthesize asn1 = _asn1;
@synthesize name = _name;

+(ADVX500DistinguishedName *)distinguishedNameFromASN1:(ADVASN1 *)asn1
{
    return [[ADVX500DistinguishedName alloc] initFromASN1:asn1];
}

-(id)initFromASN1:(ADVASN1 *)asn1
{
    self = [super init];
    if (self == nil)
        return self;
    

    self.asn1 = asn1;
    self.name = [self formattedName:X500FormatUseCommas];
    
    return self;
}

-(NSData *)rawData
{
    return self.asn1.rawData;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"ADVX500DistinguishedName: %@", self.name];
}

-(NSString *)formattedName:(ADVX500DistinguishedNameFlags)flags
{
    if (!self.asn1.isConstructed)
        return nil;
    
    NSString *separator;
    BOOL useQuotes = (flags & X500FormatDoNotUseQuotes) == 0;
    if ((flags & X500FormatUseSemiColumns) != 0)
        separator = @"; ";
    else if ((flags & X500FormatUseCommas) != 0)
        separator = @", ";
    else if ((flags & X500FormatUseNewLines) != 0)
        separator = @"\n";
    else
        separator = @", "; // default
    
    NSMutableString* name = [[NSMutableString alloc] init];
    for (NSUInteger i = 0; i < self.asn1.itemCount; i++)
    {
        ADVASN1 *entry = [self.asn1 getItem:i];
        [self appendEntry:name entry:entry quotes:useQuotes];
        if (i < (self.asn1.itemCount - 1))
            [name appendString:separator];
    }
    
    return name;
}

-(NSString *)getCommonName
{
    return self.commonName;
}


-(NSString *)getShortOidName:(NSString *)oidName
{
    static NSDictionary *oidShortNames;
    
    
    if (oidName == nil)
        return oidName;
    if (oidShortNames == nil)
    {
        oidShortNames = [NSDictionary dictionaryWithObjectsAndKeys:
                         @"C",  @"countryName",
                         @"O",  @"organizationName",
                         @"OU", @"organizationalUnitName",
                         @"CN", @"commonName",
                         @"L",  @"localityName",
                         @"ST", @"stateOrProvinceName",
                         @"STREET", @"streetAddress",
                         @"SN", @"surName",
                         @"T",  @"title",
                         @"G",  @"givenName",
                         @"I",  @"initials",
                         @"DC", @"domainComponent",
                         @"UID", @"userid",
                         nil];
    }
    NSString *shortName = [oidShortNames objectForKey:oidName];
    if (shortName == nil)
        return oidName;
    return shortName;
    
}


-(void)appendEntry:(NSMutableString *)name entry:(ADVASN1 *)asn1Entry quotes:(BOOL)useQuotes
{
    // multiple subentry are valid
    for (NSUInteger i = 0; i < asn1Entry.itemCount; i++)
    {
        ADVASN1 *asn1Pair = [asn1Entry getItem:i];
        
        if (asn1Pair.itemCount < 2)
        {
            NSLog(@"Invalid entry encountered in distinguished name. tag:%u itemCount:%lu", asn1Entry.type, (unsigned long)asn1Entry.itemCount);
            return;
        }
        ADVASN1 *asn1Oid = [asn1Pair getItem:0];
        ADVASN1 *asn1Value = [asn1Pair getItem:1];
        
        if (asn1Oid.class != ASN1ClassUniversal || asn1Oid.type != ASN1TagObjectIdentifier)
        {
            NSLog(@"Invalid entry encountered in distinguished name");
            return;
        }
        
        ADVOid *oid = [ADVOid oidFromOidString:asn1Oid.oidValue];
        NSString *oidName = [self getShortOidName:oid.friendlyName];
        if (oidName.length == 0)
            oidName = [NSString stringWithFormat:@"OID.%@", oid.value];
        
        NSString *stringValue;
        switch (asn1Value.type)
        {
            case ASN1TagBMPString:
                stringValue = [[NSString alloc] initWithData:asn1Value.value encoding:NSUTF16StringEncoding];
                break;
            case ASN1TagPrintableString:
                stringValue = [[NSString alloc] initWithData:asn1Value.value encoding:NSASCIIStringEncoding];
                break;
            case ASN1TagUTF8String:
                stringValue = [[NSString alloc] initWithData:asn1Value.value encoding:NSUTF8StringEncoding];
                break;
            default:
                stringValue = [[NSString alloc] initWithData:asn1Value.value encoding:NSUTF8StringEncoding];
                break;
        }

        [name appendFormat:@"%@=%@", oidName, stringValue];
        
        if ([oidName isEqualToString:@"CN"])
            self.commonName = stringValue;
    }
}


@end
