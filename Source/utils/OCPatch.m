//
//  OCPatch.m
//  YiyaPuzzleDemo
//
//  Created by linhan on 2016/11/18.
//  Copyright © 2016年 test. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreImage/CoreImage.h>
#import <UIKit/UIKit.h>
#import "OCPatch.h"

@implementation OCPatch
    
+ (nonnull CIContext*) CIContextMake
{
    return [CIContext contextWithOptions:nil];
}
    
@end

//@implementation UIView (Patch)
//
//- (CGRect) convertRect:(CGRect)rect to_view:(nullable UIView *)view
//{
//    return [self convertRect:rect toView:view];
//}
//
//@end
