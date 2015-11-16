//
//  NSObject+Additions.h
//  Luft
//
//  Created by Emil Bogren on 15/11/15.
//  Copyright © 2015 Hugo Tunius. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (Additions)

+ (void)luft_swizzleInstanceMethod:(SEL)originalSelector with:(SEL)newSelector;

@end
