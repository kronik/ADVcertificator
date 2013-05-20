//
//  ADVOid.m
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

#import "ADVOid.h"
#import "ADVLog.h"

@implementation ADVOid

@synthesize friendlyName = _friendlyName;
@synthesize value = _value;


+(ADVOid *)oidFromOidString:(NSString *)oidString
{
    return [[ADVOid alloc] initFromOidString:oidString];
}

-(id)initFromOidString:(NSString *)oidString
{
    self = [super init];
    if (self == nil)
        return nil;
    
    self.value = oidString;
    self.friendlyName = [self getName:self.value];
    return self;
}

// Returns the descriptive name for a given object identifier string
// if no descriptive name is availabel returns the provided object identifier string
-(NSString *)getName:(NSString *)oidString
{
    static NSDictionary *oidNames = nil;
    
    if (oidNames == nil)
    {
        oidNames = [NSDictionary dictionaryWithObjectsAndKeys:
                    @"dsa",                     @"1.2.840.10040.4.1",
                    @"dsa-with-sha1",           @"1.2.840.10040.4.3",
                    // pkcs-1
                    @"rsaEncryption",           @"1.2.840.113549.1.1.1",
                    @"md2WithRSAEncryption",    @"1.2.840.113549.1.1.2",
                    @"md4WithRSAEncryption",    @"1.2.840.113549.1.1.3",
                    @"md5WithRSAEncryption",    @"1.2.840.113549.1.1.4",
                    @"sha1withRSAEncryption",   @"1.2.840.113549.1.1.5",
                    @"sha256WithRSAEncryption", @"1.2.840.113549.1.1.11",
                    @"sha384WithRSAEncryption", @"1.2.840.113549.1.1.12",
                    @"sha512WithRSAEncryption", @"1.2.840.113549.1.1.13",
                    @"sha224WithRSAEncryption", @"1.2.840.113549.1.1.14",
                    // pkcs-7
                    @"pkcs-7 data",             @"1.2.840.113549.1.7.1",
                    // pkcs-9
                    @"emailAddress",            @"1.2.840.113549.1.9.1",
                    @"contentType",             @"1.2.840.113549.1.9.3",
                    @"messageDigest",           @"1.2.840.113549.1.9.4",
                    @"signingTime",             @"1.2.840.113549.1.9.5",
                    // digestAlgorithm
                    @"md2",                     @"1.2.840.113549.2.2",
                    @"md4",                     @"1.2.840.113549.2.4",
                    @"md5",                     @"1.2.840.113549.2.5",
                    @"hmacWithSHA1",            @"1.2.840.113549.2.7",
                    @"hmacWithSHA224",          @"1.2.840.113549.2.8",
                    @"hmacWithSHA384",          @"1.2.840.113549.2.9",
                    @"hmacWithSHA256",          @"1.2.840.113549.2.10",
                    @"hmacWithSHA512",          @"1.2.840.113549.2.11",
                    // encryptionAlgorithms
                    @"rc4",                     @"1.2.840.113549.3.4",
                    @"des-ede3-cbc",            @"1.2.840.113549.3.7",
                    // pkix
                    @"Authority Information Access", @"1.3.6.1.5.5.7.1.1",
                    // algorithms
                    @"sha1",                    @"1.3.14.3.2.26",
                    @"sha11withRSASignature",   @"1.3.14.3.2.29",
                    // itu data pss ucl(rfc1274) pilot pilotAttributeType
                    @"userid",                  @"0.9.2342.19200300.100.1.1",
                    @"domainComponent",         @"0.9.2342.19200300.100.1.25",
                    // attributeTypes
                    @"commonName",              @"2.5.4.3",
                    @"surName",                 @"2.5.4.4",
                    @"serialNumber",            @"2.5.4.5",
                    @"countryName",             @"2.5.4.6",
                    @"localityName",            @"2.5.4.7",
                    @"stateOrProvinceName",     @"2.5.4.8",
                    @"streetAddress",           @"2.5.4.9",
                    @"organizationName",        @"2.5.4.10",
                    @"organizationalUnitName",  @"2.5.4.11",
                    @"title",                   @"2.5.4.12",
                    @"givenName",               @"2.5.4.42",
                    @"initials",                @"2.5.4.43",
                    @"dnQualifier",             @"2.5.4.46",
                    // certificateExtensions
                    @"X509v3 Subject Key Identifier",   @"2.5.29.14",
                    @"X509v3 Key Usage",                @"2.5.29.15",
                    @"X509v3 Subject Alternative Name", @"2.5.29.17",
                    @"X509v3 Basic Constraints",        @"2.5.29.19",
                    @"X509v3 CRL Distribution Points ", @"2.5.29.31",
                    @"X509v3 Certificate Policies",     @"2.5.29.32",
                    @"X509v3 Authority Key Identifier", @"2.5.29.35",
                    @"X509v3 Extended Key Usage",       @"2.5.29.37",
                    // country/us/organizations/netscape
                    @"Netscape Cert Type",      @"2.16.840.1.113730.1.1",
                    @"Netscape Comment",        @"2.16.840.1.113730.1.13",
                    nil];
    }
    NSString *name = [oidNames objectForKey:oidString];
    if (name.length == 0)
        return oidString;
    return name;
}

@end
