//
//  ADVNSData-Base64.m
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

#import "ADVNSData+Base64.h"
#import "ADVLog.h"
#include <wctype.h>


@implementation NSData(ADVBase64)

-(id)initWithBase64String:(NSString *)base64String
{
    static const Byte dbase64 [] = {
        128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128,
        128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128,
        128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128,  62, 128, 128, 128,  63,
        52,  53,  54,  55,  56,  57,  58,  59,  60,  61, 128, 128, 128, 255, 128, 128,
        128,   0,   1,   2,   3,   4,   5,   6,   7,   8,   9,  10,  11,  12,  13,  14,
        15,  16,  17,  18,  19,  20,  21,  22,  23,  24,  25, 128, 128, 128, 128, 128,
        128,  26,  27,  28,  29,  30,  31,  32,  33,  34,  35,  36,  37,  38,  39,  40,
        41,  42,  43,  44,  45,  46,  47,  48,  49,  50,  51
    };
    NSMutableData *data = [[NSMutableData alloc] init];
    
    unichar source[4];
    Byte values[4];
    Byte results[3];
    
    NSUInteger length = base64String.length;
    for (NSUInteger i = 0; i < length; )
    {
        NSUInteger k;
        for (k = 0; k < 4 && i < length; )
        {
            unichar ch = [base64String characterAtIndex:i++];
            
            if (iswspace(ch))
                continue;
            
            if (ch >= sizeof(dbase64))
            {
                NSLog(@"Invalid character in base64 data at index %lu", (unsigned long)i);
                return nil;
            }
            
            source[k] = ch;
            values[k] = dbase64[ch];
            if (values[k] == 128)
            {
                NSLog(@"Invalid character in base64 data at index %lu", (unsigned long)i);
                return nil;
            }
            k++;
        }
        if (k != 0 && k != 4)
        {
            NSLog(@"Invalid character in base64 data at index %lu", (unsigned long)i);
            return nil;
        }
        if (values[0] == 255 || values[1] == 255)
        {
            NSLog(@"Invalid character in base64 data at index %lu", (unsigned long)i);
            return nil;
        }
        NSUInteger destIndex = 0;
        results[destIndex++] = (values[0] << 2) | (values[1] >> 4);
        if (values[2] != 255)
            results[destIndex++] = (values[1] << 4) | (values[2] >> 2);
        if (values[3] != 255)
            results[destIndex++] = (values[2] << 6) | values[3];
        
        [data appendBytes:results length:destIndex];
    }
    
    return [self initWithData:data];
}

-(NSString *)getBase64String
{
    static const char base64[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
    char buf[5];
	memset(buf, 0, sizeof(buf));
    
    NSMutableString *target = [[NSMutableString alloc] init];
    NSUInteger length = self.length;
    const Byte *source = (const Byte *)self.bytes;
    
    for (; length > 2; length -= 3)
    {
		buf[0] = base64[(source[0] >> 2) & 0x3f];
		buf[1] = base64[((source[0] << 4) & 0x30) | ((source[1] >> 4) & 0x0f)];
		buf[2] = base64[((source[1] << 2) & 0x3c) | ((source[2] >> 6) & 0x03)];
		buf[3] = base64[source[2] & 0x3f];
        source += 3;
        
        [target appendString:[NSString stringWithCString:buf encoding:NSASCIIStringEncoding]];
    }
    if (length == 2)
    {
		buf[0] = base64[(source[0] >> 2) & 0x3f];
		buf[1] = base64[((source[0] << 4) & 0x30)| ((source[1] >> 4) & 0x0f)];
		buf[2] = base64[((source[1] << 2) & 0x3c)];
		buf[3] = '=';
        [target appendString:[NSString stringWithCString:buf encoding:NSASCIIStringEncoding]];
    }
    else if (length == 1)
    {
		buf[0] = base64[(source[0] >> 2) & 0x3f];
		buf[1] = base64[((source[0] << 4) & 0x30)];
		buf[2] = buf[3] = '=';
        [target appendString:[NSString stringWithCString:buf encoding:NSASCIIStringEncoding]];
    }
    return target;
}

@end
