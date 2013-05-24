//
//  ADVImportCertificateViewController.m
//  ADVcertificator-sample
//
//  Created by Daniel Cerutti on 12/12/12.
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

#import "ADVImportCertificateViewController.h"
#import <CommonCrypto/CommonDigest.h>
#import "ADVCertificator/ADVCertificator.h"

@interface ADVImportCertificateViewController ()

@property (weak, nonatomic) IBOutlet UILabel *importFileInfoLabel;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

@end

@implementation ADVImportCertificateViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];   
    self.passwordTextField.delegate = self;  
}

- (NSURL*)getBundleClientCertificateURL
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"ADVcertificator" ofType:@"p12"];
    return [NSURL fileURLWithPath:path];
}

- (IBAction)importCertificate:(id)sender
{
    ADVCertificateImportStatus status;
    NSString*               statusText;
    
    // Take the client certificate from the bundle
    // In your application, it is better to retrieve it from a mail, a web site, etc. or to obfuscate it a little
    NSURL *pkcs12url = [self getBundleClientCertificateURL];

    // Import the client certificate and store it in the keychain
    // It will then be automatically be used (when needed) because we have called "clientCertificateName" in AdvAppDelegate.m
    status = [[ADVCertificator sharedCertificator] importCertificateToKeychain:pkcs12url
                                                                  withPassword:self.passwordTextField.text
                                                                          name:@"ADVcertificator"]; // This name (label) is the same than in AdvAppDelegate.m
    switch (status)
    {
        case ADVCertificateImportStatusSucceeded:
            statusText = @"Import successful";
            break;
        case ADVCertificateImportStatusAuthFailed:
            statusText = @"Invalid passphrase";
            break;
        case ADVCertificateImportStatusDuplicate:
            statusText = @"Certificate already exists";
            break;
        case ADVCertificateImportStatusFailed:
            statusText = @"Import failed";
            break;
        default:
            statusText = @"Import failed with unknown status";
            break;
    }
    [self.statusLabel setText:statusText];
}

- (BOOL)textFieldShouldReturn: (UITextField*) tf
{
    [tf resignFirstResponder];
    [self importCertificate:tf];
    return YES;
}

- (void)viewDidUnload
{
    [self setStatusLabel:nil];
    [super viewDidUnload];
}

@end
