//
//  OCHelper.m
//  MissMedia
//
//  Created by linhan on 16/3/30.
//  Copyright © 2016年 Miss. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OCHelper.h"

@implementation OCHelper

+ (void)tryBlock:(OCTryBlock)block
{
    @try {
        if (block != nil)
        {
            block();
        }
    } @catch (NSException *exception) {
        
    }
}

+ (id)tryBlockWithReturns:(OCReturnsTryBlock)block
{
    id value = nil;
    @try {
        if (block != nil)
        {
            value = block();
        }
    } @catch (NSException *exception) {
        return nil;
    }
    return value;
}

@end