//
//  ADVSSLPinningRulesViewController.m
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

#import "ADVSSLPinningRulesViewController.h"
#import <ADVCertificator/ADVCertificator.h>

@interface ADVSSLPinningRulesViewController ()

@end

@implementation ADVSSLPinningRulesViewController

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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    ADVCertificator *certLib = [ADVCertificator sharedCertificator];
    
    return [certLib serverCertificateVerificationItems].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    NSUInteger row = indexPath.row;
    
    ADVServerCertificateVerificationItem *item = [[ADVCertificator sharedCertificator].serverCertificateVerificationItems objectAtIndex:row];
    
    NSString *component;
    switch (item.certificateComponent)
    {
        case ADVServerCertificateVerificationFingerprint:
            component = @"Fingerprint";
            break;
        case ADVServerCertificateVerificationSubject:
            component = @"Subject";
            break;
        case ADVServerCertificateVerificationSubjectPublicKeyInfo:
            component = @"Public key info";
            break;
        default:
            component = @"?invalid";
            break;
    }
    
    cell.textLabel.text =[NSString stringWithFormat:@"Verify %@", component];
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"maxDepth: %d\nisRequired: %@\n%@",
                                 item.maxCertificateChainDepth, (item.isRequiredItem ? @"YES" : @"NO"), item.componentString];;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

@end
