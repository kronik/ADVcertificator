//
//  ADVNSFileHandleExtension.m
//  ADVcertificator
//
//  Created by Daniel Cerutti on 22/01/13.
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

#import "ADVNSFileHandleExtension.h"
#import "ADVLog.h"

@implementation NSFileHandle(ADVNSFileHandleExtension)

-(void)writeWithFormat:(NSString*)format, ...
{
    va_list args;
    va_start(args, format);
    NSString *outputString = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self writeData:[outputString dataUsingEncoding:NSUTF8StringEncoding]];
}


-(void)writeLine:(NSString*)format, ...
{
    va_list args;
    va_start(args, format);
    NSString *outputString = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self writeData:[outputString dataUsingEncoding:NSUTF8StringEncoding]];
    [self writeData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];
}

@end
