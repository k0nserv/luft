//
//  NSObject+Additions.m
//  Luft
//
//  Created by Emil Bogren on 15/11/15.
//  Copyright © 2015 Hugo Tunius. All rights reserved.
//

#import "NSObject+Additions.h"
#import <objc/runtime.h>

@implementation NSObject (Additions)

+ (void)luft_swizzleInstanceMethod:(SEL)originalSelector with:(SEL)newSelector {
    Method origMethod = class_getInstanceMethod(self, originalSelector);
    Method newMethod  = class_getInstanceMethod(self, newSelector);

    if (class_addMethod(self, originalSelector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
        class_replaceMethod(self, originalSelector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod));
        class_replaceMethod(self, newSelector, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    } else {
        method_exchangeImplementations(newMethod, origMethod);
    }
}

@end
