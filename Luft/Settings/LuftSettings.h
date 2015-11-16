//
//  LuftSettings.h
//  Luft
//
//  Created by Emil Bogren on 15/11/15.
//  Copyright © 2015 Hugo Tunius. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

@interface LuftSettings : NSObject

+ (LuftSettings *)sharedSettings;

- (void)setGoodColor:(NSColor *)color;
- (void)setWarningColor:(NSColor *)color;
- (void)setBadColor:(NSColor *)color;
- (void)setOnlyViewControllers:(BOOL)value;
- (void)setLowerLimit:(NSUInteger)limit;
- (void)setUpperLimit:(NSUInteger)limit;

- (NSColor *)goodColor;
- (NSColor *)warningColor;
- (NSColor *)badColor;
- (BOOL)onlyViewController;
- (NSUInteger)lowerLimit;
- (NSUInteger)upperLimit;

@end
