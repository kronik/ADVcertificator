//
//  ADVCertificateTableViewController.m
//  ADVcertificator-sample
//
//  Created by Daniel Cerutti on 12/13/12.
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

#import "ADVCertificateTableViewController.h"
#import "ADVCertificateViewController.h"

@interface ADVCertificateTableViewController ()

@property (nonatomic) NSMutableArray* identities;
@property (nonatomic) NSMutableArray* certificates;
@property (nonatomic) NSMutableArray* keys;

@end

@implementation ADVCertificateTableViewController

@synthesize identities = _identities;
@synthesize certificates = _certificates;
@synthesize keys = _keys;

#pragma mark - Properties getter/setter

-(NSMutableArray *)identities
{
    if (_identities == nil)
    {
        OSStatus   err;
        CFArrayRef latestIdentities = NULL;

        // Get the current identities from the keychain.
        err = SecItemCopyMatching(
                                  (__bridge CFDictionaryRef) [NSDictionary dictionaryWithObjectsAndKeys:
                                                              (__bridge id) kSecClassIdentity,     kSecClass,
                                                              kSecMatchLimitAll,    kSecMatchLimit,
                                                              kCFBooleanTrue,       kSecReturnRef,
                                                              kCFBooleanTrue,       kSecReturnAttributes,
                                                              nil
                                                              ],
                                  (CFTypeRef *) &latestIdentities
                                  );
        
        if (err == noErr && latestIdentities != NULL)
        {   // Output details to log
            CFDictionaryRef resultDict = NULL;
            for (int idx = 0; idx < CFArrayGetCount(latestIdentities); idx++)
            {
                NSLog(@"Identity");
                resultDict = CFArrayGetValueAtIndex(latestIdentities, idx);
                
                [((__bridge NSDictionary *)resultDict) enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                    NSLog(@"  key:%@ object:%@", key, obj);
                }];
            }
        }
        if (err == errSecItemNotFound)
        {
            latestIdentities = CFArrayCreate(NULL, NULL, 0, &kCFTypeArrayCallBacks);
            err = noErr;
        }
        if (err == noErr)
        {
            assert(latestIdentities != NULL);
            assert(CFGetTypeID(latestIdentities)   == CFArrayGetTypeID());
            
            self.identities = [(__bridge NSArray *)latestIdentities mutableCopy];
        }
        assert(err == noErr);
        
        if (latestIdentities != NULL)
        {
            CFRelease(latestIdentities);
        }
    }
    return _identities;
}

-(NSMutableArray *)certificates
{
    if (_certificates == nil)
    {
        OSStatus   err;
        CFArrayRef latestCertificates = NULL;

        err = SecItemCopyMatching(
                                  (__bridge CFDictionaryRef) [NSDictionary dictionaryWithObjectsAndKeys:
                                                              (__bridge id)kSecClassCertificate, kSecClass,
                                                              kSecMatchLimitAll,    kSecMatchLimit,
                                                              kCFBooleanTrue,       kSecReturnRef,
                                                              kCFBooleanTrue,       kSecReturnAttributes,
                                                              nil
                                                              ],
                                  (CFTypeRef *) &latestCertificates
                                  );
        if (err == noErr && latestCertificates != NULL)
        {   // Output details to log
            CFDictionaryRef resultDict = NULL;
            for (int idx = 0; idx < CFArrayGetCount(latestCertificates); idx++)
            {
                NSLog(@"Certificate");
                resultDict = CFArrayGetValueAtIndex(latestCertificates, idx);
                
                [((__bridge NSDictionary *)resultDict) enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                    NSLog(@"  key:%@ object:%@", key, obj);
                }];
            }
        }
        if (err == errSecItemNotFound)
        {
            latestCertificates = CFArrayCreate(NULL, NULL, 0, &kCFTypeArrayCallBacks);
            assert(latestCertificates != NULL);
            err = noErr;
        }
        if (err == noErr)
        {
            assert(latestCertificates != NULL);
            assert(CFGetTypeID(latestCertificates)   == CFArrayGetTypeID());
            
            self.certificates = [(__bridge NSArray *)latestCertificates mutableCopy];
        }
        assert(err == noErr);
        
        if (latestCertificates != NULL)
        {
            CFRelease(latestCertificates);
        }
    }
    return _certificates;
}

-(NSMutableArray *)keys
{
    if (_keys == nil)
    {
        OSStatus   err;
        CFArrayRef latestKeys = NULL;
        
        err = SecItemCopyMatching(
                                  (__bridge CFDictionaryRef) [NSDictionary dictionaryWithObjectsAndKeys:
                                                              (__bridge id)kSecClassKey, kSecClass,
                                                              kSecMatchLimitAll,    kSecMatchLimit,
                                                              kCFBooleanTrue,       kSecReturnRef,
                                                              kCFBooleanTrue,       kSecReturnAttributes,
                                                              nil
                                                              ],
                                  (CFTypeRef *) &latestKeys
                                  );
        if (err == noErr && latestKeys != NULL)
        {   // Output details to log
            CFDictionaryRef resultDict = NULL;
            for (int idx = 0; idx < CFArrayGetCount(latestKeys); idx++)
            {
                NSLog(@"Key");
                resultDict = CFArrayGetValueAtIndex(latestKeys, idx);
                
                [((__bridge NSDictionary *)resultDict) enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                    NSLog(@"  key:%@ object:%@", key, obj);
                }];
            }
        }
        if (err == errSecItemNotFound)
        {
            latestKeys = CFArrayCreate(NULL, NULL, 0, &kCFTypeArrayCallBacks);
            assert(latestKeys != NULL);
            err = noErr;
        }
        if (err == noErr)
        {
            assert(latestKeys != NULL);
            assert(CFGetTypeID(latestKeys)   == CFArrayGetTypeID());
            
            self.keys = [(__bridge NSArray *)latestKeys mutableCopy];
        }
        assert(err == noErr);
        
        if (latestKeys != NULL)
        {
            CFRelease(latestKeys);
        }
    }
    return _keys;
}

#pragma mark - Initialization

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

#pragma mark - Helpers

-(SecCertificateRef)getCerticateAtIndexPath:(NSIndexPath *)indexPath
{
    SecCertificateRef   certificate = nil;
    
    OSStatus            err;
    NSUInteger row = indexPath.row;
    if (indexPath.section == 0)
    {
        NSDictionary *identityData = [self.identities objectAtIndex:row];
        
        SecIdentityRef identity = (__bridge SecIdentityRef)identityData[(__bridge NSString *)kSecValueRef];
        assert(CFGetTypeID(identity) == SecIdentityGetTypeID());
        
        err = SecIdentityCopyCertificate(identity, &certificate);
        assert(err == noErr);
        assert(certificate != NULL);
    }
    else if (indexPath.section == 1)
    {
        NSDictionary *certificateData = [self.certificates objectAtIndex:row];
        
        certificate = (__bridge SecCertificateRef)certificateData[(__bridge NSString *)kSecValueRef];
        assert(certificate != NULL);
        assert(CFGetTypeID(certificate) == SecCertificateGetTypeID());
        CFRetain(certificate);
    }
    return certificate;
}

-(void)resetListAndRefreshTableView:(UITableView *)tableView;
{
    self.certificates = nil;
    self.identities = nil;
    self.keys = nil;
    [tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,3)] withRowAnimation:UITableViewRowAnimationRight];
}



#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"viewCertificateDetails"])
    {
        if ([sender isKindOfClass:[UITableViewCell class]])
        {
            NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
            SecCertificateRef certificate = [self getCerticateAtIndexPath:indexPath];
            if (certificate != nil)
            {
                NSData * certData = (NSData *)CFBridgingRelease(SecCertificateCopyData(certificate));
                
                NSLog(@"prepareForSegue id=%@", sender);
                ADVCertificateViewController *certificateViewController = (ADVCertificateViewController *)segue.destinationViewController;
                [certificateViewController showCertificate:certData];
                
                CFRelease(certificate);
            }
        }
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        return @"Identities";
    }
    else if (section == 1)
    {
        return @"Certificates";
    }
    else
    {
        return @"Keys";
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
    {
        // Return the number of rows in the section.
        NSLog(@"Number of identities: %u", self.identities.count);
        return self.identities.count;
    }
    else if (section == 1)
    {
        NSLog(@"Number of certificates: %u", self.certificates.count);
        return self.certificates.count;
    }
    else
    {
        NSLog(@"Number of keys: %u", self.keys.count);
        return self.keys.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    // Configure the cell...

    OSStatus            err;
    NSUInteger row = indexPath.row;

    if (indexPath.section == 0)
    {
        SecIdentityRef      identity;
        SecCertificateRef   identityCertificate;
        CFStringRef         identitySubject;
        
        NSDictionary *identityData = [self.identities objectAtIndex:row];
        
        identity = (__bridge SecIdentityRef)identityData[(__bridge NSString *)kSecValueRef];
        assert(CFGetTypeID(identity) == SecIdentityGetTypeID());
        
        err = SecIdentityCopyCertificate(identity, &identityCertificate);
        assert(err == noErr);
        assert(identityCertificate != NULL);
        
        CFDataRef certData = SecCertificateCopyData(identityCertificate);
        
        
        identitySubject = SecCertificateCopySubjectSummary(identityCertificate);
        assert(identitySubject != NULL);
        
        cell.textLabel.text = identityData[(__bridge NSString *)kSecAttrLabel];
        cell.detailTextLabel.text = (__bridge NSString *)identitySubject;
        CFRelease(certData);
        CFRelease(identitySubject);
        CFRelease(identityCertificate);
    }
    else if (indexPath.section == 1)
    {
        SecCertificateRef   certificate;
        CFStringRef         identitySubject;

        NSDictionary *certificateData = [self.certificates objectAtIndex:row];
        
        certificate = (__bridge SecCertificateRef)certificateData[(__bridge NSString *)kSecValueRef];
        assert(certificate != NULL);
        NSLog(@"certificate type id:%ld should be %ld", CFGetTypeID(certificate), SecCertificateGetTypeID());
        assert(CFGetTypeID(certificate) == SecCertificateGetTypeID());
        
        identitySubject = SecCertificateCopySubjectSummary(certificate);
        assert(identitySubject != NULL);
        
        cell.textLabel.text = certificateData[(__bridge NSString *)kSecAttrLabel];
        cell.detailTextLabel.text = (__bridge NSString *)identitySubject;
        CFRelease(identitySubject);
    }
    else
    {
        NSDictionary *keyData = [self.keys objectAtIndex:row];
      
        id label = keyData[(__bridge NSString *)kSecAttrApplicationLabel];
        NSLog(@"label: %@", label);
        cell.textLabel.text = [NSString stringWithFormat:@"Key %d", row + 1];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", label];
    }
    return cell;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        OSStatus err;
        
        NSLog(@"Item to delete: '%@'", [tableView cellForRowAtIndexPath:indexPath].textLabel.text);
        
        if (indexPath.section == 0)
        {
            NSDictionary *identityData = [self.identities objectAtIndex:indexPath.row];
            
            id label = identityData[(__bridge NSString *)kSecAttrLabel];
            err = SecItemDelete((__bridge CFDictionaryRef)([NSDictionary dictionaryWithObjectsAndKeys:
                                                            (__bridge id)(kSecClassCertificate), kSecClass,
                                                            label, kSecAttrLabel,
                                                            nil]));
            if (err == noErr)
            {
                // it seems that to delete a key we need to use some property like kSecAttrApplicationLabel
                label = identityData[(__bridge NSString *)kSecAttrApplicationLabel];
                
                err = SecItemDelete((__bridge CFDictionaryRef)([NSDictionary dictionaryWithObjectsAndKeys:
                                                                (__bridge id)(kSecClassKey), kSecClass,
                                                                label, kSecAttrApplicationLabel,
                                                                nil]));
            }
            
            
            if (err == noErr)
            {
                [self resetListAndRefreshTableView:tableView];
            }
            else
                NSLog(@"error deleting identity from keychain: %ld", err);
        }
        else if (indexPath.section == 1)
        {
            NSDictionary *certificateData = [self.certificates objectAtIndex:indexPath.row];
            id label = certificateData[(__bridge NSString *)kSecAttrLabel];
            
            err = SecItemDelete((__bridge CFDictionaryRef)([NSDictionary dictionaryWithObjectsAndKeys:
                                                            (__bridge id)(kSecClassCertificate), kSecClass,
                                                            label, kSecAttrLabel,
                                                            nil]));
            if (err == noErr)
            {
                [self resetListAndRefreshTableView:tableView];
            }
            else
                NSLog(@"error deleting certificate from keychain: %ld", err);
        }
        else
        {
            NSDictionary *keyData = [self.keys objectAtIndex:indexPath.row];
            id label = keyData[(__bridge NSString *)kSecAttrApplicationLabel];
            
            err = SecItemDelete((__bridge CFDictionaryRef)([NSDictionary dictionaryWithObjectsAndKeys:
                                                            (__bridge id)(kSecClassKey), kSecClass,
                                                            label, kSecAttrApplicationLabel,
                                                            nil]));
            if (err == noErr)
            {
                [self resetListAndRefreshTableView:tableView];
            }
            else
                NSLog(@"error deleting key from keychain: %ld", err);
        }
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert)
    {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"didSelectRowAtIndexPath indexPath=%@", indexPath);
}

@end
