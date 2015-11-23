//
//  LuftSettings.h
//  Luft
//
//  Created by Emil Bogren on 15/11/15.
//  Copyright © 2015 Hugo Tunius. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

extern NSString *const LuftSettingsChangedNotification;

@interface LuftSettings : NSObject

+ (LuftSettings *)sharedSettings;

- (void)resetDefaults;
- (void)setGoodColor:(NSColor *)color;
- (void)setWarningColor:(NSColor *)color;
- (void)setBadColor:(NSColor *)color;
- (void)setOnlyViewControllers:(BOOL)value;
- (void)setBlendWithSidebar:(BOOL)value;
- (void)setBlendFactor:(CGFloat)factor;
- (void)setLowerLimit:(NSUInteger)limit;
- (void)setUpperLimit:(NSUInteger)limit;

- (NSColor *)goodColor;
- (NSColor *)warningColor;
- (NSColor *)badColor;
- (BOOL)onlyViewController;
- (BOOL)blendWithSidebar;
- (CGFloat)blendFactor;
- (NSUInteger)lowerLimit;
- (NSUInteger)upperLimit;

@end
