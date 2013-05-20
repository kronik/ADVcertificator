//
//  ADVCertificateViewController.m
//  ADVcertificator-sample
//
//  Created by Daniel Cerutti on 1/24/13.
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

#import "ADVCertificateViewController.h"
#import "ADVCertificator/ADVX509Certificate.h"
#import "ADVCertificator/ADVOid.h"

@interface ADVCertificateViewController ()

@property (strong, nonatomic) ADVX509Certificate *certificate;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UILabel *serialLabel;
@property (weak, nonatomic) IBOutlet UILabel *issuerLabel;
@property (weak, nonatomic) IBOutlet UILabel *validFromLabel;
@property (weak, nonatomic) IBOutlet UILabel *validUntilLabel;
@property (weak, nonatomic) IBOutlet UILabel *subjectLabel;
@property (weak, nonatomic) IBOutlet UILabel *pubKeyAlgoLabel;
@property (weak, nonatomic) IBOutlet UITextView *pubKeyDataTextView;
@property (weak, nonatomic) IBOutlet UILabel *pubKeyHashLabel;
@property (weak, nonatomic) IBOutlet UILabel *signatureAlgoLabel;
@property (weak, nonatomic) IBOutlet UILabel *signatureDataLabel;
@property (weak, nonatomic) IBOutlet UILabel *fingerprintLabel;

@end

@implementation ADVCertificateViewController

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
    [self fillCertificateData:self.certificate];
}


-(void)showCertificate:(NSData *)certificateData
{
    NSLog(@"showCertificate");
    self.certificate = [ADVX509Certificate certificateWithData:certificateData];
}

-(NSString *)hexData:(NSData *)data
{
    const unsigned COLUMNS = 16;
    
    NSMutableString *result = [[NSMutableString alloc] init];
    const Byte* bytes = data.bytes; 
    for (int hexRow = 0; hexRow < ((data.length + COLUMNS - 1) / COLUMNS); hexRow++)
    {
        for (int hexCol = 0; hexCol < COLUMNS && hexCol < (data.length - hexRow * COLUMNS); hexCol++)
        {
            if(hexCol > 0)
                [result appendString:@" "];
            [result appendFormat:@"%02x", bytes[hexCol + hexRow * COLUMNS]];
        }
        [result appendString:@"\n"];
    }
    return result;
}

-(void)fillCertificateData:(ADVX509Certificate *)cert
{
    if(cert == nil)
        return;
    
    self.nameLabel.text = cert.commonName;
    self.versionLabel.text = [NSString stringWithFormat:@"%d", cert.version];
    self.serialLabel.text = [self hexData:cert.serialNumber];
    self.issuerLabel.text = cert.issuerName.name;
    self.validFromLabel.text = [NSString stringWithFormat:@"%@", cert.validFrom];
    self.validUntilLabel.text = [NSString stringWithFormat:@"%@", cert.validUntil];
    self.subjectLabel.text = cert.subjectName.name;
    self.pubKeyAlgoLabel.text = [ADVOid oidFromOidString:cert.keyAlgorithm].friendlyName;
    self.pubKeyDataTextView.text = [self hexData:cert.publicKey];
    self.pubKeyHashLabel.text = cert.getSubjectPublicKeyHashAsHexString;
    self.signatureAlgoLabel.text = [ADVOid oidFromOidString:cert.signatureAlgorithm].friendlyName;
    self.signatureDataLabel.text = [self hexData:cert.signature];
    self.fingerprintLabel.text = cert.getThumbprintAsHexString;
}

- (void)viewDidUnload
{
    [self setNameLabel:nil];
    [self setVersionLabel:nil];
    [self setSerialLabel:nil];
    [self setIssuerLabel:nil];
    [self setValidFromLabel:nil];
    [self setValidUntilLabel:nil];
    [self setSubjectLabel:nil];
    [self setPubKeyAlgoLabel:nil];
    [self setPubKeyHashLabel:nil];
    [self setSignatureAlgoLabel:nil];
    [self setSignatureDataLabel:nil];
    [self setFingerprintLabel:nil];
    [self setPubKeyDataTextView:nil];
    [super viewDidUnload];
}
@end
