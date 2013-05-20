//
//  ADVCertificatorTests.m
//  ADVcertificatorTests
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

#import "ADVCertificatorTests.h"
#import "ADVCertificator.h"

@implementation ADVCertificatorTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testSharedInstance
{
    ADVCertificator *certLib = [ADVCertificator sharedCertLib];
    
    STAssertNotNil(certLib, @"ADVCertificator sharedInstance must return a non nil instance");
    
    ADVCertificator *certLib2 = [ADVCertificator sharedCertLib];
    
    STAssertEqualObjects(certLib, certLib2, @"ADVCerLib sharedCertLib must always return the same instance");
}

@end
