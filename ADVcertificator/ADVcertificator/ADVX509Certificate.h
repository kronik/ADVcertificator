//
//  ADVCertificate.h
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
#import <Security/Security.h>
#import "ADVX500DistinguishedName.h"


/// Represents a X509 certificate
@interface ADVX509Certificate : NSObject

///---------------------------------------------------------
/// @name Creating an initializing an ADVX500DistinguishedName


/// Creates a ADVX509Certificate instance from a certificate file
///
/// The certificate file should be in PEM or DER format.
///
/// @param filename the file pathname
/// @returns an ADVX509Certificate
+(ADVX509Certificate *)certificateWithContentOfFile:(NSString *)filename;

/// Creates a ADVX509Certificate instance from certificate data as a NSData object
///
/// The certificate data should be in PEM or DER format.
///
/// @param data a NSData object with the certificate data
/// @returns an ADVX509Certificate
+(ADVX509Certificate *)certificateWithData:(NSData *)data;

/// Creates a ADVX509Certificate instance from SecCertificateRef
///
/// @param certificate a SecCertificateRef
/// @returns an ADVX509Certificate
+(ADVX509Certificate *)certificateWithSecCertificate:(SecCertificateRef)certificate;

-(id)initWithData:(NSData *)data;
-(id)initWithContentsOfFile:(NSString *)filename;
-(id)initWithSecCertificate:(SecCertificateRef)certificate;

///---------------------------------------------------------
/// @name Reading certificate properties

/// Get the certificate raw data in DER format
@property (readonly, strong, nonatomic) NSData *rawData;

/// Get the certificate serial number
@property (readonly, strong, nonatomic) NSData *serialNumber;

/// Get the certificate format version
@property (readonly, nonatomic) int version;

/// Get the certificate issuer
@property (readonly, strong, nonatomic) ADVX500DistinguishedName *issuerName;

/// Get the certificate start validity date
@property (readonly, strong, nonatomic) NSDate *validFrom;

/// Get the certificate end validity date
@property (readonly, strong, nonatomic) NSDate *validUntil;

/// Get the certificate subject
@property (readonly, strong, nonatomic) ADVX500DistinguishedName *subjectName;

/// Get the certificate subject common name
@property (readonly, strong, nonatomic) NSString *commonName;

/// Get the certificate subject public key algorithm name
@property (readonly, strong, nonatomic) NSString *keyAlgorithm;

/// Get the certificate subject public key parameters
@property (readonly, strong, nonatomic) NSData *keyAlgorithmParameters;

/// Get the certificate subject public key
@property (readonly, strong, nonatomic) NSData *publicKey;

/// Get the certificate signature algorithm name
@property (readonly, strong, nonatomic) NSString *signatureAlgorithm;

/// Get the certificate signature algorithm parameters
@property (readonly, strong, nonatomic) NSData *signatureAlgorithmParameters;

/// Get the certificate signature
@property (readonly, strong, nonatomic) NSData *signature;

///---------------------------------------------------------
/// @name Calculating common hashes

/// Get a hash of the certificate subject public key
///
/// This is used for verification of a certificate in server certificate pinning.
/// It consists of the SHA1 of the full subject public key information in DER format.
/// and includes the algorithm, parameters and the key. It is returned as binary data
-(NSData *)getSubjectPublicKeyHash;

/// Get a hash of the certificate subject public key
///
/// This is used for verification of a certificate in server certificate pinning.
/// It consists of the SHA1 of the full subject public key information in DER format.
/// and includes the algorithm, parameters and the key. It is returned as an Hex string
/// representation
-(NSString *)getSubjectPublicKeyHashAsHexString;


/// Get the certificate thumbprint
///
/// It consists of the SHA1 of the certificate in DER format.
/// It is returned as binary data
-(NSData *)getThumbprint;

/// Get the certificate thumbprint
///
/// It consists of the SHA1 of the certificate in DER format.
/// It is returned as an Hex string representation
-(NSString *)getThumbprintAsHexString;

///---------------------------------------------------------
/// @name Dumping certificate content in text format

-(void)dumpCertificateInfo:(NSFileHandle *)file;

@end
