//
//  ADVAppDelegate.m
//  ADVcertificator-sample
//
//  Created by Daniel Cerutti on 12/10/12.
//  Copyright (c) 2012 ADVTOOLS. All rights reserved.
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

#import "ADVAppDelegate.h"
#import "ADVImportCertificateViewController.h"
#import "ADVCertificator/ADVCertificator.h"

@implementation ADVAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    ADVCertificator *advCertificator = [ADVCertificator sharedCertificator];
    
    [advCertificator registerHandler];
    
    [advCertificator setServerCertificateVerificationOptions:ADVServerCertificateVerificationDebug + ADVServerCertificateVerificationUseItemList];
    
    // These are the rules for SSL Server Certificate pinning (change these rules and the values to fit your needs):
    // - The fingerprint has to be b41a2c496b07650ba72618681bceee0eb9f23726
    // - The subject public key info has to be 237f501878aff6e281bb2d7edf4a9d40686d52a6 OR the suject has to be CN=secure.advtools.com, etc.
    
    // Fingerprint (in this example, it is secure.advtools.com certificate). This item is mandatory in this example.
    [advCertificator addServerCertificateVerificationItem:[ADVServerCertificateVerificationItem
                                                           serverCertificateVerificationItem:ADVServerCertificateVerificationFingerprint
                                                           stringToMatch:@"01be970fd0064f228556186b3d4d2fe2ce6040cf" maxDepth:2 isItemRequired:YES]];
    
    // Public Key (in this example, it is secure.advtools.com certificate). This item is optional in this example.
    [advCertificator addServerCertificateVerificationItem:[ADVServerCertificateVerificationItem
                                                   serverCertificateVerificationItem:ADVServerCertificateVerificationSubjectPublicKeyInfo
                                                   stringToMatch:@"0022df9c489217c4c4636a1edd407b22ab398628" maxDepth:1 isItemRequired:NO]];
    
    // Subject name (in this example, it is secure.advtools.com certificate). This item is optional in this example.
    [advCertificator addServerCertificateVerificationItem:[ADVServerCertificateVerificationItem
                                                   serverCertificateVerificationItem:ADVServerCertificateVerificationSubject
                                                   stringToMatch:@"serialNumber=DoO0Yi1mc3LRv5/6udowa0-vwXY3GH75, OU=GT10607012, OU=See www.rapidssl.com/resources/cps (c)14, OU=Domain Control Validated - RapidSSL(R), CN=secure.advtools.com" maxDepth:0 isItemRequired:NO]];
    
    // This is the name (label) of the client certificate that will be used in the remaining of the application, when needed
    // It has to be imported before ("Import Client Certificate" button)
    advCertificator.clientCertificateName = @"ADVcertificator";
    
    // Override point for customization after application launch.
    return YES;
}

@end
