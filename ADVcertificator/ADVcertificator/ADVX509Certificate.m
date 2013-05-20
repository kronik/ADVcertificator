//
//  ADVCertificate.m
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
//
//
// References:
// a.	Internet X.509 Public Key Infrastructure Certificate and CRL Profile
//	http://www.ietf.org/rfc/rfc3280.txt
// b.	ITU ASN.1 standards (free download)
//	http://www.itu.int/ITU-T/studygroups/com17/languages/


#import "ADVX509Certificate.h"
#import "ADVASN1.h"
#import "ADVOid.h"
#import "ADVNSData+Base64.h"
#import "ADVNSDataExtension.h"
#import "ADVNSFileHandleExtension.h"
#import "ADVLog.h"
#import <CommonCrypto/CommonDigest.h>

@interface ADVX509Certificate()

@property (readwrite) SecCertificateRef certificate;
@property (readwrite, strong, nonatomic) ADVASN1 *issuer;
@property (readwrite, strong, nonatomic) ADVASN1 *subject;

@property (readwrite, strong, nonatomic) NSData *rawData;

@property (readwrite, strong, nonatomic) NSData *serialNumber;
@property (readwrite, nonatomic) int version;
@property (readwrite, strong, nonatomic) ADVX500DistinguishedName *issuerName;
@property (readwrite, strong, nonatomic) NSDate *validFrom;
@property (readwrite, strong, nonatomic) NSDate *validUntil;
@property (readwrite, strong, nonatomic) ADVX500DistinguishedName *subjectName;
@property (readwrite, strong, nonatomic) NSString *commonName;
@property (strong, nonatomic) NSData *subjectPublicKeyInfo; // The subject public key full raw data
@property (readwrite, strong, nonatomic) NSString *keyAlgorithm;
@property (readwrite, strong, nonatomic) NSData *keyAlgorithmParameters;
@property (readwrite, strong, nonatomic) NSData *publicKey;

@property (readwrite, strong, nonatomic) NSString *signatureAlgorithm;
@property (readwrite, strong, nonatomic) NSData *signatureAlgorithmParameters;
@property (readwrite, strong, nonatomic) NSData *signature;

@end


@implementation ADVX509Certificate

@synthesize certificate = _certificate;
@synthesize rawData = _rawData;
@synthesize serialNumber = _serialNumber;
@synthesize version = _version;
@synthesize issuer = _issuer;
@synthesize validFrom = _validFrom;
@synthesize validUntil = _validUntil;
@synthesize subject = _subject;
@synthesize commonName = _commonName;
@synthesize subjectPublicKeyInfo = _subjectPublicKeyInfo;
@synthesize keyAlgorithm = _keyAlgorithm;
@synthesize keyAlgorithmParameters = _keyAlgorithmParameters;
@synthesize publicKey = _publicKey;
@synthesize signatureAlgorithm = _signatureAlgorithm;
@synthesize signatureAlgorithmParameters = _signatureAlgorithmParameters;
@synthesize signature = _signature;


#pragma mark Class methods

+(ADVX509Certificate *)certificateWithContentOfFile:(NSString *)filename
{
    return [[ADVX509Certificate alloc] initWithContentsOfFile:filename];
}

+(ADVX509Certificate *)certificateWithData:(NSData *)data
{
    return [[ADVX509Certificate alloc] initWithData:data];
}

+(ADVX509Certificate *)certificateWithSecCertificate:(SecCertificateRef)certificate;
{
    return [[ADVX509Certificate alloc] initWithSecCertificate:certificate];
}

#pragma mark Initialization

-(id)initWithData:(NSData *)data
{
    if ([data length] == 0)
        return nil;
    
    self = [super init];
    if (self == nil)
        return self;
    
    if (((const Byte*)data.bytes)[0] != 0x30)
    {
        // Assume PEM encoding:
        NSString *type = @"CERTIFICATE";
        NSString *pemText = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        NSString *header = [NSString stringWithFormat:@"-----BEGIN %@-----", type];
        NSString *footer = [NSString stringWithFormat:@"-----END %@-----", type];
        
        NSRange headerRange = [pemText rangeOfString:header];
        NSRange footerRange = [pemText rangeOfString:footer];
        if (headerRange.location == NSNotFound || footerRange.location == NSNotFound || footerRange.location < headerRange.location)
        {
            NSLog(@"Error loading certificate");
            return nil;
        }
        
        NSRange contentRange = NSMakeRange(headerRange.location + headerRange.length,
                                           footerRange.location - headerRange.location - headerRange.length);
        
        NSString *base64 = [pemText substringWithRange:contentRange];
        base64 = [base64 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        data = [[NSData alloc] initWithBase64String:base64];
    }
    
    SecCertificateRef certificateRef = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)data);
    if (certificateRef == NULL)
    {
        NSLog(@"Error loading certificate");
        return nil;
    }
    
    if (self.certificate != NULL)
        CFRelease(self.certificate);
    
    self.certificate = certificateRef;
    self.rawData = data;
    
    if (![self parse])
        return nil;
    
    return self;
}

-(id)initWithContentsOfFile:(NSString *)filename
{
    NSData *data = [NSData dataWithContentsOfFile:filename];
    if (data == nil)
    {
        NSLog(@"Error reading file %@", filename);
        return nil;
    }
    return [self initWithData:data];
}

-(id)initWithSecCertificate:(SecCertificateRef)certificate
{
    CFDataRef certData = SecCertificateCopyData(certificate);
    id cert = [self initWithData:(__bridge NSData *)(certData)];
    CFRelease(certData);
    return cert;
}

#pragma mark Properties

-(NSData *)getThumbprint
{
    return [self sha1:self.rawData];
}

-(NSString *)getThumbprintAsHexString
{
    return [self hexStringFromData:[self getThumbprint]];
}

-(NSData *)getSubjectPublicKeyHash
{
    return [self sha1:self.subjectPublicKeyInfo];
}

-(NSString *)getSubjectPublicKeyHashAsHexString
{
    return [self hexStringFromData:[self getSubjectPublicKeyHash]];
}


#pragma mark Private methods

-(NSData *)sha1:(NSData *)data
{
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, (CC_LONG)data.length, digest);

    return [NSData dataWithBytes:digest length:CC_SHA1_DIGEST_LENGTH];
}



-(NSString *)hexStringFromData:(NSData *)data
{
    NSMutableString* output = [NSMutableString stringWithCapacity:(data.length * 2)];
    Byte *buffer = (Byte *)data.bytes;
    for(NSUInteger i = 0; i < data.length; i++)
        [output appendFormat:@"%02x", buffer[i]];
    
    return output;
}

-(BOOL)parse
{
    // from http://www.ietf.org/rfc/rfc2459.txt
    //
    //Certificate  ::=  SEQUENCE  {
    //     tbsCertificate       TBSCertificate,
    //     signatureAlgorithm   AlgorithmIdentifier,
    //     signature            BIT STRING  }
    //
    //TBSCertificate  ::=  SEQUENCE  {
    //     version         [0]  Version DEFAULT v1,
    //     serialNumber         SerialNumber,
    //     signature            AlgorithmIdentifier,
    //     issuer               Name,
    //     validity             Validity,
    //     subject              Name,
    //     subjectPublicKeyInfo SubjectPublicKeyInfo,
    //     issuerUniqueID  [1]  IMPLICIT UniqueIdentifier OPTIONAL,
    //                          -- If present, version shall be v2 or v3
    //     subjectUniqueID [2]  IMPLICIT UniqueIdentifier OPTIONAL,
    //                          -- If present, version shall be v2 or v3
    //     extensions      [3]  Extensions OPTIONAL
    //                          -- If present, version shall be v3 --  }
    
    ADVASN1 *asn1 = [ADVASN1 ASN1WithData:self.rawData];
    if (asn1 == nil)
    {
        NSLog(@"Error parsing certificate data");
        return NO;
    }
    if (asn1.type != ASN1TagSequence && asn1.itemCount != 0 && [asn1 getItem:0].type != ASN1TagSequence)
    {
        NSLog(@"Certificate encoding error");
        return NO;
    }
    
    ADVASN1 *tbsCertificate = [asn1 getItem:0];
    NSUInteger tbs = 0;
    
    // Certificate / TBSCertificate / Version
    ADVASN1 *asn1Version = [tbsCertificate getItem:tbs];
    self.version = 1;
    if (asn1Version.class == ASN1ClassContext && asn1Version.type == 0)
    {
        self.version = 1 + ((const Byte *)[asn1Version getItem:0].value.bytes)[0];
        tbs++;
    }
    
    // Certificate / TBSCertificate / SerialNumber
    ADVASN1 *asn1Serial = [tbsCertificate getItem:tbs++];
    if (!asn1Serial.isConstructed && asn1Serial.type != ASN1TagInteger)
    {
        NSLog(@"Certificate encoding error");
        return NO;
    }
    NSMutableData *serialNumber = [NSMutableData dataWithData:asn1Serial.value];
    [serialNumber reverseData];
    self.serialNumber = serialNumber;
    
    // Certificate / TBSCertificate / AlgorithmIdentifier
    tbs++;
    
    // Certificate / TBSCertificate / Issuer
    self.issuer = [tbsCertificate getItem:tbs++];
    if (!self.issuer.isConstructed || self.issuer.type != ASN1TagSequence)
    {
        NSLog(@"Certificate error: no issuer");
        return NO;
    }
    self.issuerName = [ADVX500DistinguishedName distinguishedNameFromASN1:self.issuer];
    
    
    // Certificate / TBSCertificate / Validity
    ADVASN1 *validity = [tbsCertificate getItem:tbs++];
    if (!validity.isConstructed || validity.type != ASN1TagSequence || validity.itemCount != 2)
    {
        NSLog(@"Certificate error: no validity date");
        return NO;
    }
    ADVASN1 *validFrom = [validity getItem:0];
    ADVASN1 *validUntil = [validity getItem:1];
    self.validFrom = validFrom.dateValue;
    self.validUntil = validUntil.dateValue;
    
    // Certificate / TBSCertificate / Subject
    self.subject = [tbsCertificate getItem:tbs++];
    if (!self.subject.isConstructed || self.subject.type != ASN1TagSequence)
    {
        NSLog(@"Certificate error: no issuer");
        return NO;
    }
    self.subjectName = [ADVX500DistinguishedName distinguishedNameFromASN1:self.subject];
    self.commonName = self.subjectName.getCommonName;
    
    // Certificate / TBSCertificate / SubjectPublicKeyInfo
    ADVASN1 *subjectPublicKeyInfo = [tbsCertificate getItem:tbs++];
    if (!subjectPublicKeyInfo.isConstructed || subjectPublicKeyInfo.type != ASN1TagSequence || subjectPublicKeyInfo.itemCount < 2)
    {
        NSLog(@"Certificate error: invalid or missing subject public key info");
        return NO;
    }
    self.subjectPublicKeyInfo = subjectPublicKeyInfo.rawData;
    
    ADVASN1 *algorithm = [subjectPublicKeyInfo getItem:0];
    if (!algorithm.isConstructed || algorithm.type != ASN1TagSequence || algorithm.itemCount < 1)
    {
        NSLog(@"Certificate error: invalid algorithm definition in subject public key info");
        return NO;
    }
    ADVASN1 *keyAlgorithm = [algorithm getItem:0];
    if (keyAlgorithm.type != ASN1TagObjectIdentifier)
    {
        NSLog(@"Certificate error: invalid algorithm definition in subject public key info");
        return NO;
    }
    self.keyAlgorithm = keyAlgorithm.oidValue;
    
    if (algorithm.itemCount > 1)
    {
        ADVASN1 *keyAlgorithmParameters = [algorithm getItem:1];
        self.keyAlgorithmParameters = keyAlgorithmParameters.value;
    }
    
    ADVASN1 *publicKey = [subjectPublicKeyInfo getItem:1];
    if (publicKey.type != ASN1TagBitString)
    {
        NSLog(@"Certificate error: invalid public key in subject public key info");
        return NO;
    }
    // drop the first byte which is the number of unused bits in the BITSTRING
    self.publicKey = [publicKey.value subdataWithRange:NSMakeRange(1, publicKey.value.length - 1)];
    
    // signature processing
    if (asn1.itemCount < 3)
    {
        NSLog(@"Certificate error: missing signature information");
        return NO;
    }
    
    ADVASN1 *signatureAlgorithm = [asn1 getItem:1];
    if (!signatureAlgorithm.isConstructed || signatureAlgorithm.type != ASN1TagSequence || signatureAlgorithm.itemCount < 1)
    {
        NSLog(@"Certificate error: invalid algorithm definition in signature");
        return NO;
    }
    ADVASN1 *signatureAlgorithmKey = [signatureAlgorithm getItem:0];
    self.signatureAlgorithm = signatureAlgorithmKey.oidValue;
    if (self.signatureAlgorithm == nil)
    {
        NSLog(@"Certificate error: invalid algorithm definition in signature");
        return NO;
    }
    if (signatureAlgorithm.itemCount > 1)
    {
        ADVASN1 *signatureAlgorithmParameters = [signatureAlgorithm getItem:1];
        self.signatureAlgorithmParameters = signatureAlgorithmParameters.value;
    }
    
    ADVASN1 *signature = [asn1 getItem:2];
    if (signature.type != ASN1TagBitString)
    {
        NSLog(@"Certificate error: invalid signature");
        return NO;
    }
    // drop the first byte which is the number of unused bits in the BITSTRING
    self.signature = [signature.value subdataWithRange:NSMakeRange(1, signature.value.length - 1)];
    
    
    return YES;
}


#pragma mark Debugging


-(NSString *)description
{
    return [NSString stringWithFormat:@"X509Certificate: %@", self.subjectName.name];
}



-(void)dumpHexData:(NSFileHandle *)file data:(NSData *)data withIndent:(int)indent
{
    const Byte* bytes = data.bytes;
    for (int hexRow = 0; hexRow < ((data.length + 15) / 16); hexRow++)
    {
        NSMutableString *value = [[NSMutableString alloc] init];
        for (int hexCol = 0; hexCol < 16 && hexCol < (data.length - hexRow * 16); hexCol++)
        {
            [value appendFormat:@" %02x", bytes[hexCol + hexRow * 16]];
        }
        [file writeLine:@"%*s%@", indent, "", value];
    }
}

-(void)dumpCertificateInfo:(NSFileHandle *)file
{
    [file writeLine:@"Certificate:"];
    [file writeLine:@"  Data:"];
    [file writeLine:@"    Version: %d", self.version];
    [file writeLine:@"    Serial Number: %@", self.serialNumber];
    [self dumpHexData:file data:self.serialNumber withIndent:6];
    [file writeLine:@"    Issuer: %@", self.issuerName.name];
    [file writeLine:@"    Valid from:  %@", self.validFrom];
    [file writeLine:@"    Valid until: %@", self.validUntil];
    [file writeLine:@"    Subject: %@", self.subjectName.name];
    [file writeLine:@"    Subject common name: %@", self.commonName];
    [file writeLine:@"    Subject Public Key Info:"];
    [file writeLine:@"      Public key algorithm: %@", [ADVOid oidFromOidString:self.keyAlgorithm].friendlyName];
    [self dumpHexData:file data:self.publicKey withIndent:8];
    [file writeLine:@"    Subject Public Key Info fingerprint: %@", self.getSubjectPublicKeyHashAsHexString];
    
    [file writeLine:@"  Signature algorithm: %@", [ADVOid oidFromOidString:self.signatureAlgorithm].friendlyName];
    [self dumpHexData:file data:self.signature withIndent:4];
    
    [file writeLine:@"  Fingerprint: %@", self.getThumbprintAsHexString];
}

-(void)dealloc
{
    if (self.certificate != NULL)
        CFRelease(self.certificate);
}

@end
