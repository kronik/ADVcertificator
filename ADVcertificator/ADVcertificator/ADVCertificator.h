//
//  ADVCertificator.h
//  ADVcertificator
//
//  Created by Daniel Cerutti on 15/01/13.
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

typedef NS_OPTIONS(int, ADVServerCertificateVerificationOptions) {
    ADVServerCertificateVerificationDefault = 0,
    ADVServerCertificateVerificationUseItemList = 1,
    ADVServerCertificateVerificationDebug = 8
};

typedef NS_ENUM(int, ADVServerCertificateResponse) {
    ADVServerCertificateResponseDefault = 0,
    ADVServerCertificateResponseAccept = 1,
    ADVServerCertificateResponseReject = 2,
    ADVServerCertificateResponseDone = 3
};

typedef NS_ENUM(int, ADVServerCertificateVerificationComponent) {
    ADVServerCertificateVerificationFingerprint = 0,
    ADVServerCertificateVerificationSubjectPublicKeyInfo = 1,
    ADVServerCertificateVerificationSubject = 2
};

typedef enum {
    ADVCertificateImportStatusSucceeded = 0,
    ADVCertificateImportStatusFailed = 1,
    ADVCertificateImportStatusAuthFailed = 2,
    ADVCertificateImportStatusDuplicate = 3,
} ADVCertificateImportStatus;

/// ----------------------------------------------------------------------------
/// ADVCertificatorDelegate allows the application to handle the different
/// credentials during an HTTPS connection
///
/// Note: The delegate methods can be invoked from any backgroup thread

@protocol ADVCertificatorDelegate <NSObject>

@optional

/// Invoked at the begin of a request. To indicate that the request should be processed by
/// ADVCertificator handler, return YES. Otherwise return NO.
///
/// @param request A NSURLRequest specifying the request to be processed.
-(BOOL)canHandleRequest:(NSURLRequest *)request;

/// Tells the delegate that the connection will send a server certificate validation request
///
/// @param connection The connection sending the message
/// @param challenge  The authentication challenge for which a request is being sent.
/// @returns A ADVServerCertificateResponse specifying how the challenge should be processed. It can
/// be one of the following value:
///
/// - ADVServerCertificateResponseDefault: Perform default processing which ensure that the server certificate
///   is valid and that the certificate chain starts with a trusted root certificate.
/// - ADVServerCertificateResponseReject: Reject the request, aborting the connection.
/// - ADVServerCertificateResponseDone: Indicates that the request has been processed by the delegate.
/// - ADVServerCertificateResponseAccept: Accepts the request.
-(ADVServerCertificateResponse)connection:(NSURLConnection *)connection verifyServerCertificate:(NSURLAuthenticationChallenge *)challenge;

/// Tells the delegate that the connection will send a client certificate request
///
/// @param connection The connection sending the message
/// @param challenge  The authentication challenge for which a request is being sent.
-(NSURLCredential *)connection:(NSURLConnection *)connection requestClientCertificate:(NSURLAuthenticationChallenge *)challenge;


/// Tells the delegate that the connection will send a basic authentication challenge
///
/// @param connection The connection sending the message
/// @param challenge  The authentication challenge for which a request is being sent.
-(NSURLCredential *)connection:(NSURLConnection *)connection requestUserPassword:(NSURLAuthenticationChallenge *)challenge;

@end

/// ----------------------------------------------------------------------------
/// ADVServerCertificateVerificationItem represents one certificate verification rule
/// to be used for server certificate pinning. One or more rule are added to
/// the list of verification rules using the ADVCertificator
/// addServerCertificateVerificationItem method
@interface ADVServerCertificateVerificationItem : NSObject

/// Return a new ADVServerCertificateVerificationItem object with the specified properties
///
/// @param certificateComponent specifies the certficate component to be verified as one of the
/// following value:
///
/// - ADVServerCertificateVerificationFingerprint: The fingerprint of the certficate as an hex string
/// - ADVServerCertificateVerificationSubjectPublicKeyInfo: The SHA1 of the complete
/// subject public key information of the certificate.
/// - ADVServerCertificateVerificationSubject: The text representation of the certificate subject.
///
/// @param componentString the value of the component to verify.
/// @param maxDepth the maximum depth of the certificate chain from the certificate
/// matching this rule to the actual server certificate
/// @param isRequired all rules with isRequired=YES must be verified and at least one of the rule
/// with isRequired=NO must be verified.
+(ADVServerCertificateVerificationItem *)serverCertificateVerificationItem:
    (ADVServerCertificateVerificationComponent)certificateComponent
    stringToMatch:(NSString *)componentString
    maxDepth:(NSUInteger)maxDepth
    isItemRequired:(BOOL)isRequired;

@property (nonatomic) ADVServerCertificateVerificationComponent certificateComponent;
@property (strong, nonatomic) NSString* componentString;
@property (nonatomic) NSUInteger maxCertificateChainDepth;
@property (nonatomic) BOOL isRequiredItem;

@end

/// ----------------------------------------------------------------------------
/// ADVCertificator is a library providing a very easy way to use client certificate and implement server certificate
/// pinning for IOS application. The support provided is independent on the network communication library
/// as long as it uses NSUrlConnection underneath. In particular UIWebView is transparently supported
///
///
@interface ADVCertificator : NSObject

/// @name Getting the ADVCertificator instance
///
/// Return the single shared instance of the ADVCertificator class.
+(ADVCertificator *)instance;

/// @name Setting and getting the delegate

@property (weak, nonatomic) id<ADVCertificatorDelegate> delegate;

/// @name Configuring SSL client and server certificate handling

/// Initialize transparent support for SSL client certificate and server certificate pinning
-(void)registerHandler;

/// Get or set the keychain name (label) of the client certificate to use for SSL connections
@property (strong, nonatomic) NSString *clientCertificateName;

/// Get or set the server certificate verification options
@property (nonatomic) ADVServerCertificateVerificationOptions serverCertificateVerificationOptions;

/// Add a server verification rules for server certficate pinning
///
/// @param item An ADVServerCertificateVerificationItem object describing a server certificate verification rule
/// @see ADVServerCertificateVerificationItem
-(void)addServerCertificateVerificationItem:(ADVServerCertificateVerificationItem *)item;

/// Clear the list of server verification rules
-(void)clearServerCertificateVerificationItemList;

/// Get the list of of server verification rules.
///
/// @returns A NSArray with ADVServerCertificateVerificationItem elements
-(NSArray *)serverCertificateVerificationItems;

/// @name Client certificate import

/// Import a PKCS12 certificate into the keychain
///
/// This will load a certificate and private key from a PKCS12 file and import it to the application keychain.
/// If the application specifies keychain access groups in the application bundle, then the certificate will
/// be imported in the first keychain access group specified so it will be shared by all application specifying
/// the same keychain access group. For more information see the SecItemAdd method documentation in the IOS reference
/// documentation.
///
/// @param url Url of the PKCS12 file to import (can also be a file URL).
/// @param password The password to open the PKCS12 file
/// @param name The name (label) to use to store the certificate and private key to the keychain
/// @returns The result of the operation as one of the following value:
///
/// - ADVCertificateImportStatusSucceeded: The certificate was successfully added to the keychain
/// - ADVCertificateImportStatusFailed: The operation failed for a non specified reason
/// - ADVCertificateImportStatusAuthFailed: The provided password was invalid
/// - ADVCertificateImportStatusDuplicate: A certificate with the same name already exists in the keychsin
-(ADVCertificateImportStatus)importCertificateToKeychain:(NSURL *)url withPassword:(NSString *)password
                                                    name:(NSString *)name;

/// @name Loading client certificate

/// Load an indentity (certificate and private key) from the keychain and return it as an NSURLCredential
/// to be used for client certificate authentication in a SSL connection.
///
/// If the application specifies keychain access groups in the application bundle, then the certificate will
/// be searched in all keychain access group specified in the application bundle in addition to the
/// application access group.
///
/// @param name The name of the identity in the keychain.
/// @returns a NSURLCredential representing the identity.
-(NSURLCredential *)loadCertificateFromKeychain:(NSString *)name;

@end
