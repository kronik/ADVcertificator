//
//  ADVNSDataExtension.m
//  ADVcertificator
//
//  Created by Daniel Cerutti on 2/7/13.
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

#import "ADVNSDataExtension.h"
#import "ADVLog.h"

@implementation NSData(ADVNSDataExtension)

-(BOOL)isEqualToByteArray:(const Byte *)byteArray length:(NSUInteger)length
{
    const Byte *bytes = (const Byte *)self.bytes;
    
    int i;
    for (i = 0; i < self.length; i++)
    {
        if (i >= length)
            return NO;
        if (bytes[i] != byteArray[i])
            return NO;
    }
    return (i == length);
}

@end




@implementation NSMutableData(ADVNSDataExtension)

-(void)reverseData
{
    BytePtr resultData = (BytePtr)self.bytes;
    
    NSUInteger length = self.length;
    for (NSUInteger i = 0; i < (length / 2); i++)
    {
        Byte temp = resultData[length - i - 1];
        resultData[length - i - 1] = resultData[i];
        resultData[i] = temp;
    }
}

@end
