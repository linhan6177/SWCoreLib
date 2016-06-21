//
//  OCHelper.h
//  MissMedia
//
//  Created by linhan on 16/3/30.
//  Copyright © 2016年 Miss. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^OCTryBlock)();
typedef id(^OCReturnsTryBlock)();
@interface SWOCHelper : NSObject
+ (void)tryBlock:(OCTryBlock)block;
+ (id)tryBlockWithReturns:(OCReturnsTryBlock)block;
@end
