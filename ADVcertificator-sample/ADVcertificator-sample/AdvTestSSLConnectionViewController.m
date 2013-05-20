//
//  ADVTestSSLConnectionViewController.m
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

#import "ADVTestSSLConnectionViewController.h"

@interface ADVTestSSLConnectionViewController () <UITextFieldDelegate, NSURLConnectionDataDelegate>

@property (weak, nonatomic) IBOutlet UITextField *addressTextField;
@property (weak, nonatomic) IBOutlet UILabel *resultLabel;

@property (strong, nonatomic) NSURLConnection *connection;
@end

@implementation ADVTestSSLConnectionViewController

@synthesize connection = _connection;
@synthesize addressTextField = _addressTextField;
@synthesize resultLabel = _resultLabel;

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
 
    self.addressTextField.delegate = self;
}


- (BOOL)textFieldShouldReturn: (UITextField*) tf
{
    [self connectButtonPressed:nil];
    return YES;
}

- (IBAction)connectButtonPressed:(UIButton *)sender
{
    [self.addressTextField resignFirstResponder];
    self.resultLabel.text = @"-";

    NSURL *url = [NSURL URLWithString:self.addressTextField.text];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    unsigned statusCode = [(NSHTTPURLResponse *)response statusCode];
    NSLog(@"didReceiveResponse Response status: %u", statusCode);
    
    self.resultLabel.text = [NSString stringWithFormat:@"Status %u received. The connection was established and the certificate pinning checks were verified", statusCode];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError %@", error);
    self.resultLabel.text = [NSString stringWithFormat:@"%@", error];
}

- (void)viewDidUnload {
    [self setResultLabel:nil];
    [super viewDidUnload];
}
@end
