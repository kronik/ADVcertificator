//
//  ADVCertUtil.h
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

#import <Foundation/Foundation.h>
#import "ADVCertificator.h"


@interface ADVCertUtil : NSObject


+(NSURLCredential *)evaluateClientCertificateRequest:(NSURLAuthenticationChallenge *)challenge;
+(ADVServerCertificateResponse)evaluateServerCertificate:(NSURLAuthenticationChallenge *)challenge;


@end
