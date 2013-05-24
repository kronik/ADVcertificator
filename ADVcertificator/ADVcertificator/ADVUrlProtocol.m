//
//  ADVUrlProtocol.m
//  ADVcertificator
//
//  Created by Daniel Cerutti on 12/20/12.
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

#import "ADVUrlProtocol.h"
#import "ADVCertUtil.h"
#import "ADVCertificator.h"
#import "ADVLog.h"

@interface ADVUrlProtocol() <NSURLConnectionDataDelegate>

@property (strong, nonatomic) NSURLConnection* connection;

@end

// Defines an additional property to NSURLRequest so we can check for the inner NSURLRequest
// used in our NSURLProtocol implementation

@interface NSURLRequest (ADVUrlProtocol)
- (NSString *)innerRequest;
@end

@interface NSMutableURLRequest (ADVUrlProtocol)
- (void)setInnerRequest:(NSString *)innerRequest;
@end

static NSString *ADVProtocolInnerRequestKey = @"ADVInnerRequest";

@implementation NSURLRequest (ADVUrlProtocol)
- (NSString *)innerRequest
{
    return [NSURLProtocol propertyForKey:ADVProtocolInnerRequestKey inRequest:self];
}
@end

@implementation NSMutableURLRequest (ADVUrlProtocol)
- (void)setInnerRequest:(NSString *)isInnerRequest
{
    [NSURLProtocol setProperty:isInnerRequest forKey:ADVProtocolInnerRequestKey inRequest:self];
}
@end

// Our NSURLProtocol implementation use internally a NSURLConnection to perform the request.

@implementation ADVUrlProtocol

@synthesize connection = _connection;

+(BOOL)canInitWithRequest:(NSURLRequest *)request
{
    if ([request.URL.scheme caseInsensitiveCompare:@"https"] == NSOrderedSame)
    {
        if ([ADVUrlProtocol propertyForKey:ADVProtocolInnerRequestKey inRequest:request] == nil)
        {
            BOOL result = YES;
            id<ADVCertificatorDelegate> delegate = [ADVCertificator sharedCertificator].delegate;
            if ([delegate respondsToSelector:@selector(canHandleRequest:)])
            {
                result = [delegate canHandleRequest:request];
            }
            DLog(@"returns %d for %@", result, request);
            return result;
        }
    }
    return NO;
}

+(NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

+(BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b
{
    return [super requestIsCacheEquivalent:a toRequest:b];
}

-(void)startLoading
{
    DLog(@"request.URL: %@", self.request.URL.absoluteString);
    
    NSMutableURLRequest* innerRequest = (NSMutableURLRequest*)[self.request mutableCopy];
    [ADVUrlProtocol setProperty:@"1" forKey:ADVProtocolInnerRequestKey inRequest:innerRequest];
    // [innerRequest setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    
    self.connection = [NSURLConnection connectionWithRequest:innerRequest delegate:self];
}

-(void)stopLoading
{
    DLog(@"");

    [self.connection cancel];
}


-(void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    DLog(@"authenticationMethod: %@", challenge.protectionSpace.authenticationMethod);
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodClientCertificate])
    {
        NSURLCredential *urlCredential;
        id<ADVCertificatorDelegate> delegate = [ADVCertificator sharedCertificator].delegate;
        if ([delegate respondsToSelector:@selector(connection:requestClientCertificate:)])
        {
            urlCredential = [delegate connection:connection requestClientCertificate:challenge];
        }
        else
        {
            urlCredential = [ADVCertUtil evaluateClientCertificateRequest:challenge];
        }
        [[challenge sender] useCredential:urlCredential forAuthenticationChallenge:challenge];
    }
    else if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
    {
        ADVServerCertificateResponse response;
        
        id<ADVCertificatorDelegate> delegate = [ADVCertificator sharedCertificator].delegate;
        if ([delegate respondsToSelector:@selector(connection:verifyServerCertificate:)])
        {
            response = [delegate connection:connection verifyServerCertificate:challenge];
        }
        else
        {
            response = [ADVCertUtil evaluateServerCertificate:challenge];
        }
        switch (response)
        {
            case ADVServerCertificateResponseAccept:
                [[challenge sender] useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]
                       forAuthenticationChallenge:challenge];
                break;
            case ADVServerCertificateResponseReject:
                [[challenge sender] cancelAuthenticationChallenge: challenge];
                [self.client URLProtocol:self didCancelAuthenticationChallenge:challenge];
                break;
            case ADVServerCertificateResponseDefault:
                [[challenge sender] performDefaultHandlingForAuthenticationChallenge:challenge];
                break;
            case ADVServerCertificateResponseDone:
                break;
            default:
                break;
        }
    }
    else if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodDefault] ||
             [challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodHTTPBasic])
    {
        id<ADVCertificatorDelegate> delegate = [ADVCertificator sharedCertificator].delegate;
        if ([delegate respondsToSelector:@selector(connection:requestUserPassword:)])
        {
            NSURLCredential *urlCredential;
            urlCredential = [delegate connection:connection requestUserPassword:challenge];
            [[challenge sender] useCredential:urlCredential forAuthenticationChallenge:challenge];
        }
        else
            [self.client URLProtocol:self didReceiveAuthenticationChallenge:challenge];
    }
    else
    {
        [self.client URLProtocol:self didReceiveAuthenticationChallenge:challenge];
    }
}

-(BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection
{
    DLog(@"");
    return NO;
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    DLog(@"error: %@", error);
    
    [self.client URLProtocol:self didFailWithError:error];
}


-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    DLog(@"data.length: %lu bytes", (unsigned long)data.length);

    [self.client URLProtocol:self didLoadData:data];
}


-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    DLog(@"HTTP status=%ld", (long)[(NSHTTPURLResponse *)response statusCode]);

    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
   
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    DLog(@"");

    [self.client URLProtocolDidFinishLoading:self];
}

@end
