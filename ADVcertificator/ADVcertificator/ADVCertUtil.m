//
//  ADVCertUtil.m
//  ADVcertificator
//
//  Created by Daniel Cerutti on 1/16/13.
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

#import "ADVCertUtil.h"
#import "ADVX509Certificate.h"
#import "ADVLog.h"

@implementation ADVCertUtil



+(NSURLCredential *)evaluateClientCertificateRequest:(NSURLAuthenticationChallenge *)challenge
{
    DLog(@"evaluateClientCertificateRequest challenge protection space: host=%@ port=%ld protocol=%@ realm=%@ receivesCredentialSecurely=%u proxyType=%@",
          challenge.protectionSpace.host,
          (long)challenge.protectionSpace.port,
          challenge.protectionSpace.protocol,
          challenge.protectionSpace.realm,
          challenge.protectionSpace.receivesCredentialSecurely,
          challenge.protectionSpace.proxyType);
    
    for (id dnData in challenge.protectionSpace.distinguishedNames)
    {
        DLog(@"accepted client certificate authority:");
        if ([dnData isKindOfClass:[NSData class]])
        {
            DLog(@"subject=%@", [ADVX500DistinguishedName distinguishedNameFromASN1:[ADVASN1 ASN1WithData:dnData]].name);
        }
    }
    
    NSString *name = [ADVCertificator sharedCertificator].clientCertificateName;
    NSURLCredential *urlCredential = [[ADVCertificator sharedCertificator] loadCertificateFromKeychain:name];

    return urlCredential;
}

+(ADVServerCertificateResponse)evaluateServerCertificate:(NSURLAuthenticationChallenge *)challenge
{
    ADVServerCertificateVerificationOptions options = [ADVCertificator sharedCertificator].serverCertificateVerificationOptions;
    if (options == ADVServerCertificateVerificationDefault)
        return ADVServerCertificateResponseDefault;
    
    BOOL trustCertificate = NO;

    SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
    SecTrustResultType evaluateTrustResult;
    OSStatus status = SecTrustEvaluate(serverTrust, &evaluateTrustResult);
    
    if ((options & ADVServerCertificateVerificationDebug) != 0)
    {
        NSLog(@"evaluateServerCertificate protection space: host=%@ port=%ld protocol=%@ realm=%@ receivesCredentialSecurely=%u proxyType=%@",
              challenge.protectionSpace.host,
              (long)challenge.protectionSpace.port,
              challenge.protectionSpace.protocol,
              challenge.protectionSpace.realm,
              challenge.protectionSpace.receivesCredentialSecurely,
              challenge.protectionSpace.proxyType);
        NSLog(@"  SecTrustEvaluate OSStatus:%ld SecTrustResultType:%lu", (long)status, (unsigned long)evaluateTrustResult);
    }
    
    
    if (status == errSecSuccess &&
        (evaluateTrustResult == kSecTrustResultProceed || evaluateTrustResult == kSecTrustResultUnspecified))
    {
        trustCertificate = YES;
    }

    if (trustCertificate)
    {
        NSArray *verificationItems = [ADVCertificator sharedCertificator].serverCertificateVerificationItems;
        if ((options & ADVServerCertificateVerificationUseItemList) != 0 && verificationItems && verificationItems.count != 0)
        {
            trustCertificate = NO;
            int optionalItemMatches = 0;
            int requiredItemMatches = 0;
            int requiredItemExpectedMatches = 0;
            for (ADVServerCertificateVerificationItem *verificationItem in verificationItems)
            {
                if (verificationItem.isRequiredItem)
                    requiredItemExpectedMatches++;
            }
            
            CFIndex certCount = SecTrustGetCertificateCount(serverTrust);
            if ((options & ADVServerCertificateVerificationDebug) != 0)
            {
                NSLog(@"  Number of certificates in serverTrust: %ld", certCount);
            }
            
            // start from server certificate and follow the CA chain up to the root or until we have enough matches
            for (CFIndex index = 0; index < certCount; index++)
            {
                SecCertificateRef serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, index);
                
                ADVX509Certificate * advCertificate = [ADVX509Certificate certificateWithSecCertificate:serverCertificate];

                for (ADVServerCertificateVerificationItem *verificationItem in verificationItems)
                {
                    BOOL itemMatch = NO;
                    if (verificationItem.maxCertificateChainDepth >= index)
                    {
                        switch (verificationItem.certificateComponent)
                        {
                            case ADVServerCertificateVerificationFingerprint:
                                if ((options & ADVServerCertificateVerificationDebug) != 0)
                                    NSLog(@"  checking fingerprint for certificate %lu - %@", (unsigned long)index, advCertificate.subjectName.name);
                                if ([verificationItem.componentString isEqualToString:advCertificate.getThumbprintAsHexString])
                                    itemMatch = YES;
                                break;
                            case ADVServerCertificateVerificationSubject:
                                if ((options & ADVServerCertificateVerificationDebug) != 0)
                                    NSLog(@"  checking subject for certificate %lu - %@", (unsigned long)index, advCertificate.subjectName.name);
                                if ([verificationItem.componentString isEqualToString:advCertificate.subjectName.name])
                                    itemMatch = YES;
                                break;
                            case ADVServerCertificateVerificationSubjectPublicKeyInfo:
                                if ((options & ADVServerCertificateVerificationDebug) != 0)
                                    NSLog(@"  checking SPKI for certificate %lu - %@", (unsigned long)index, advCertificate.subjectName.name);
                                if ([verificationItem.componentString isEqualToString:advCertificate.getSubjectPublicKeyHashAsHexString])
                                    itemMatch = YES;
                                break;
                        }
                    }
                    if (itemMatch)
                    {
                        if (verificationItem.isRequiredItem)
                            requiredItemMatches++;
                        else
                            optionalItemMatches++;
                        
                        if ((options & ADVServerCertificateVerificationDebug) != 0)
                            NSLog(@"  match found. isRequired:%d requiredItemMatchCount:%d expected:%d optionalItemMatchCount:%d",
                              verificationItem.isRequiredItem, requiredItemMatches, requiredItemExpectedMatches, optionalItemMatches);
                        
                        if (optionalItemMatches > 0 && requiredItemMatches >= requiredItemExpectedMatches)
                            break;
                    }
                }
                if (optionalItemMatches > 0 && requiredItemMatches >= requiredItemExpectedMatches)
                {
                    if ((options & ADVServerCertificateVerificationDebug) != 0)
                        NSLog(@"  Verification successful");
                    trustCertificate = YES;
                    break;
                }
            }
        }
    }
    else if ((options & ADVServerCertificateVerificationDebug) != 0)
    {
        CFIndex certCount = SecTrustGetCertificateCount(serverTrust);
        NSLog(@"  Server certificate is not trusted");
        NSLog(@"  number certificate in serverTrust: %ld", certCount);
        for (CFIndex index = 0; index < certCount; index++)
        {
            SecCertificateRef serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, index);
            
            CFStringRef summary = SecCertificateCopySubjectSummary(serverCertificate);
            NSLog(@"  server certificate: %@", summary);
            CFRelease(summary);
            
            ADVX509Certificate * advCertificate = [ADVX509Certificate certificateWithSecCertificate:serverCertificate];
            
            NSLog(@"  server certificate: %@", advCertificate.subjectName.name);
            NSLog(@"    SPKI hash:  %@", advCertificate.getSubjectPublicKeyHashAsHexString);
            NSLog(@"    thumbprint: %@", advCertificate.getThumbprintAsHexString);
        }
    }
    
    
    if (trustCertificate)
        return ADVServerCertificateResponseAccept;
    else
    {
        if ((options & ADVServerCertificateVerificationDebug) != 0)
        {
            NSLog(@"  Canceling request");
        }
        return ADVServerCertificateResponseReject;
    }
    
}


@end
