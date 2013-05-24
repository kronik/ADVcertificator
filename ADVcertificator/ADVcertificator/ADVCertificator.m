//
//  ADVCertificator.m
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

#import "ADVCertificator.h"
#import "ADVUrlProtocol.h"
#import "ADVLog.h"

@implementation ADVServerCertificateVerificationItem

+(ADVServerCertificateVerificationItem *)serverCertificateVerificationItem:
(ADVServerCertificateVerificationComponent)certificateComponent
                                                             stringToMatch:(NSString *)componentString
                                                                  maxDepth:(NSUInteger)maxDepth
                                                            isItemRequired:(BOOL)isRequired
{
    return [[ADVServerCertificateVerificationItem alloc] initWithComponentInfo:certificateComponent stringToMatch:componentString maxDepth:maxDepth isItemRequired:isRequired];
}

-(id)initWithComponentInfo:(ADVServerCertificateVerificationComponent)certificateComponent
             stringToMatch:(NSString *)componentString
                  maxDepth:(NSUInteger)maxDepth
            isItemRequired:(BOOL)isRequired
{
    self = [super init];
    if (self)
    {
        self.certificateComponent = certificateComponent;
        self.componentString = componentString;
        self.maxCertificateChainDepth = maxDepth;
        self.isRequiredItem = isRequired;
    }
    return self;
}


@end


@interface ADVCertificator()

@property (readwrite, strong, nonatomic) NSMutableArray* _serverCertificateVerificationItems;

@end


@implementation ADVCertificator

static ADVCertificator *sharedInstance_ = nil;


@synthesize delegate = _delegate;
@synthesize serverCertificateVerificationOptions = _serverCertificateVerificationOptions;

+(ADVCertificator *)instance
{
    return [ADVCertificator sharedCertificator];
}

+(ADVCertificator *)sharedCertificator
{
    if (sharedInstance_ == nil)
    {
        sharedInstance_ = [[super allocWithZone:NULL] init];
    }
    return sharedInstance_;
}

-(void)registerHandler
{
    [NSURLProtocol registerClass:[ADVUrlProtocol class]];
}


-(NSArray *)serverCertificateVerificationItems
{
    return self._serverCertificateVerificationItems;
}


-(void)clearServerCertificateVerificationItemList
{
    [self._serverCertificateVerificationItems removeAllObjects];
}

-(void)addServerCertificateVerificationItem:(ADVServerCertificateVerificationItem *)item
{  
    if (!self.serverCertificateVerificationItems)
    {
        self._serverCertificateVerificationItems = [[NSMutableArray alloc] initWithObjects:item, nil];
    }
    else
        [self._serverCertificateVerificationItems addObject:item];
}

-(ADVCertificateImportStatus)importCertificateToKeychain:(NSURL *)url
                                            withPassword:(NSString *)password
                                            name:(NSString *)name
{
    
    OSStatus                err;
    ADVCertificateImportStatus  status;
    NSString*               statusText;
    CFArrayRef              importedItems;
    
    status = ADVCertificateImportStatusFailed;
    
    importedItems = NULL;
    
    NSData* data = [url isFileURL] ? [NSData dataWithContentsOfFile:url.path] : [NSData dataWithContentsOfURL:url];
    if(nil == data)
    {
        statusText = @"Error loading data";
        return status;
    }
    
    err = SecPKCS12Import(
                          (__bridge CFDataRef) data,
                          (__bridge CFDictionaryRef) [NSDictionary dictionaryWithObjectsAndKeys:
                                                      password, kSecImportExportPassphrase,
                                                      nil
                                                      ],
                          &importedItems
                          );
    if (err == noErr) {
        // +++ If there are multiple identities in the PKCS#12, and adding a non-first
        // one fails, we end up with partial results.  Right now that's not an issue
        // in practice, but I might want to revisit this.
        
        for (NSDictionary * itemDict in (__bridge id) importedItems) {
            SecIdentityRef  identity;
            
            assert([itemDict isKindOfClass:[NSDictionary class]]);
            
            identity = (__bridge SecIdentityRef) [itemDict objectForKey:(__bridge NSString *) kSecImportItemIdentity];
            assert(identity != NULL);
            assert( CFGetTypeID(identity) == SecIdentityGetTypeID() );
            
            NSMutableDictionary *addItemDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                      (__bridge id)identity, kSecValueRef,
                                                      //                                               kCFBooleanTrue, kSecReturnAttributes,
                                                      nil
                                                      ];
            if (name.length > 0)
                [addItemDictionary setValue:name forKey:(__bridge NSString *)kSecAttrLabel];
            
            // CFDictionaryRef identityAttributes;
            err = SecItemAdd((__bridge CFDictionaryRef)addItemDictionary, NULL); // (CFTypeRef *)&identityAttributes);
            if (err != noErr && err != errSecDuplicateItem) {
                break;
            }
        }
        if (err == noErr) {
            status = ADVCertificateImportStatusSucceeded;
            statusText = @"Import successful";
        }
        else if (err == errSecDuplicateItem)
        {
            status = ADVCertificateImportStatusDuplicate;
            statusText = @"Duplicate item";
        }
        else
        {
            statusText = [NSString stringWithFormat:@"Import failed. Error %ld", (long)err];
        }
    } else if (err == errSecAuthFailed) {
        status = ADVCertificateImportStatusAuthFailed;
        statusText = @"Invalid passphrase";
    }
    
    if (importedItems != NULL) {
        CFRelease(importedItems);
    }
    
    DLog(@"result:%u - %@", status, statusText);
    
    return status;
}

-(NSURLCredential *)loadCertificateFromKeychain:(NSString *)name
{
    OSStatus        err;
    CFArrayRef      latestIdentities;
    
    latestIdentities   = NULL;
    
    // Get the current identities from the keychain.
    
    NSMutableDictionary *filterDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                             (__bridge id)kSecClassIdentity,     kSecClass,
                                             kSecMatchLimitAll,          kSecMatchLimit,
                                             kCFBooleanTrue,             kSecReturnRef,
                                             nil];
    if (name.length > 0)
        [filterDictionary setValue:name forKey:(__bridge NSString *)kSecAttrLabel]; // kSecMatchSubjectContains
    
    err = SecItemCopyMatching((__bridge CFDictionaryRef)(filterDictionary),
                              (CFTypeRef *) &latestIdentities
                              );
    if (err == errSecItemNotFound) {
        return nil;
    }
    
    if (err == noErr) {
        
        assert(latestIdentities != NULL);
        assert(CFGetTypeID(latestIdentities)   == CFArrayGetTypeID());
    }
    assert(err == noErr);
    
    
    SecIdentityRef identityRef = (SecIdentityRef)CFArrayGetValueAtIndex(latestIdentities, 0);
    assert(CFGetTypeID(identityRef) == SecIdentityGetTypeID());
    
    // Code to log the human readable certificate summary
    SecCertificateRef   identityCertificate;
    CFStringRef         identitySubject;
    
    err = SecIdentityCopyCertificate(identityRef, &identityCertificate);
    assert(err == noErr);
    assert(identityCertificate != NULL);
    
    identitySubject = SecCertificateCopySubjectSummary(identityCertificate);
    assert(identitySubject != NULL);
    
    DLog(@"using client certificate: %@", identitySubject);
    CFRelease(identitySubject);
    CFRelease(identityCertificate);
    // end logging code
    
    
    id certificates = nil;
    
    NSURLCredential* credential = [NSURLCredential credentialWithIdentity:identityRef certificates:certificates persistence:NSURLCredentialPersistenceNone];
    
    if (latestIdentities != NULL) {
        CFRelease(latestIdentities);
    }
    return credential;
}

-(NSURLCredential *)loadCertificateFromFile:(NSString *)name withPassword:(NSString *)password
{
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"p12"];
    NSData *pkcs12 = [[NSData alloc] initWithContentsOfFile:path];
    
    NSDictionary* dictionnary = [NSDictionary dictionaryWithObject:password forKey:(__bridge id)(kSecImportExportPassphrase)];
    
    CFArrayRef ref = nil;
    OSStatus status = SecPKCS12Import((__bridge CFDataRef)pkcs12, (__bridge CFDictionaryRef)dictionnary, &ref);
    
    if(status != noErr)
    {
        NSLog(@"Error importing %@", name);
        return nil;
    }
    
    NSArray *keystore = (__bridge_transfer NSArray *)ref;
    SecIdentityRef identityRef = (__bridge SecIdentityRef)[[keystore objectAtIndex:0] objectForKey:(__bridge id)kSecImportItemIdentity];
    
    id certificates = nil;
    
    NSURLCredential* credential = [NSURLCredential credentialWithIdentity:identityRef certificates:certificates persistence:NSURLCredentialPersistenceNone];
    
    return credential;
}

@end
