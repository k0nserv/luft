//
//  IDESourceCodeEditor+Luft.m
//  Luft
//
//  Created by Hugo Tunius on 15/11/15.
//  Copyright © 2015 Hugo Tunius. All rights reserved.
//

#import "IDESourceCodeEditor+Luft.h"

#import "DVTSourceTextView.h"
#import "Aspects.h"
#import "LuftSettings.h"
#import <AppKit/AppKit.h>

typedef NS_ENUM(NSInteger, ViewControllerState) {
    ViewControllerStateGood,
    ViewControllerStateWarning,
    ViewControllerStateBad
};

static NSColor *defaultSidebarColor;

@interface IDESourceCodeEditor(LuftPrivate)
- (void)addSettingsChangedObserver;
- (void)removeSettingsChangedObeserver;
- (void)updateUIWithSourceTextView:(DVTSourceTextView *)sourceTextView
                          document:(IDESourceCodeDocument *)document;
- (ViewControllerState)determineViewControllerStateForLineCount:(NSInteger)lineCount;
- (BOOL)isViewController:(NSString *__nonnull)filename;

+ (NSColor *)generateSidebarColorFromColor:(NSColor *)color;
+ (NSColor *)goodColor;
+ (NSColor *)warningColor;
+ (NSColor *)badColor;
@end

@implementation IDESourceCodeEditor (Luft)

+ (void)luft_initialize {
    [self aspect_hookSelector:@selector(textDidChange:)
                  withOptions:AspectPositionAfter
                   usingBlock:^(id<AspectInfo> aspectInfo,  id arg) {
                       [aspectInfo.instance handleTextChange];
                   }
                        error:nil];

    [self aspect_hookSelector:@selector(setScrollView:)
                  withOptions:AspectPositionAfter
                   usingBlock:^(id<AspectInfo> aspectInfo, DVTSourceTextView *textView) {
                       [aspectInfo.instance handleTextChange];
                   }
                        error:nil];

    [self aspect_hookSelector:@selector(setTextView:)
                  withOptions:AspectPositionAfter
                   usingBlock:^(id<AspectInfo> aspectInfo, DVTSourceTextView *textView) {
                       [aspectInfo.instance handleTextChange];
                   }
                        error:nil];
    NSError *error;
    [self aspect_hookSelector:@selector(viewDidAppear)
                  withOptions:AspectPositionAfter
                   usingBlock:^(id<AspectInfo> aspectInfo){
                           [aspectInfo.instance addSettingsChangedObserver];
                   }
                        error:&error];
    if (error) {
        NSLog(@"%@", error);
    }

    error = nil;
    [self aspect_hookSelector:@selector(viewDidDisappear)
                  withOptions:AspectPositionAfter
                   usingBlock:^(id<AspectInfo> aspectInfo){
                       [aspectInfo.instance removeSettingsChangedObeserver];
                   }
                        error:&error];
    if (error) {
        NSLog(@"%@", error);
    }
}

- (void)addSettingsChangedObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTextChange) name:LuftSettingsChangedNotification object:nil];
}

- (void)removeSettingsChangedObeserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LuftSettingsChangedNotification object:nil];
}

- (void)handleTextChange {
    if (self.textView == nil) {
        return;
    }

    [self updateUIWithSourceTextView:self.textView document:self.sourceCodeDocument];
}

- (void)updateUIWithSourceTextView:(DVTSourceTextView *)sourceTextView document:(id)document {
    if (![NSStringFromClass([sourceTextView class]) isEqualToString:@"DVTSourceTextView"]) {
        return;
    }

    if (![NSStringFromClass([document class]) isEqualTo:@"IDESourceCodeDocument"]) {
        return;
    }

    id textStorage = [document textStorage];

    if (![NSStringFromClass([textStorage class]) isEqualToString:@"DVTTextStorage"]) {
        return;
    }

    SEL numberOfLinesSelector = NSSelectorFromString(@"numberOfLines");
    if (![textStorage respondsToSelector:numberOfLinesSelector]) {
        return;
    }

    SEL displayNameSelector = NSSelectorFromString(@"displayName");
    if (![document respondsToSelector:displayNameSelector]) {
        return;
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    NSString *displayName = [document performSelector:displayNameSelector];
#pragma clang diagnostic pop
    if (![self isViewController:displayName]) {
        return;
    }

    IMP implementation = [textStorage methodForSelector:numberOfLinesSelector];
    NSInteger linesOfCode = ((NSInteger (*) (id,SEL))implementation)(textStorage, numberOfLinesSelector);
    ViewControllerState state = [self determineViewControllerStateForLineCount:linesOfCode];

    NSView *__nullable sideBarView = nil;
    for (NSView *view in [self.scrollView subviews]) {
        if ([NSStringFromClass([view class]) isEqualToString:@"DVTTextSidebarView"]) {
            sideBarView = view;
            break;
        }
    }

    if (nil == sideBarView) {
        return;
    }

    SEL setBackgroundColorSelector = NSSelectorFromString(@"setSidebarBackgroundColor:");

    if (![sideBarView respondsToSelector:setBackgroundColorSelector]) {
        return;
    }
    
    if (!defaultSidebarColor) {
        SEL getBackgroundColorSelector = NSSelectorFromString(@"sidebarBackgroundColor");
        
        if (![sideBarView respondsToSelector:getBackgroundColorSelector]) {
            return;
        }
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        defaultSidebarColor = [sideBarView performSelector:getBackgroundColorSelector];
#pragma clang diagnostic pop
    }

    NSColor *newSidebarColor;
    
    switch (state) {
        case ViewControllerStateGood:
            newSidebarColor = [[self class] generateSidebarColorFromColor:[[self class] goodColor]];
            break;
        case ViewControllerStateWarning:
            newSidebarColor = [[self class] generateSidebarColorFromColor:[[self class] warningColor]];
            break;
        case ViewControllerStateBad:
            newSidebarColor = [[self class] generateSidebarColorFromColor:[[self class] badColor]];
            break;
        default:
            break;
    }
    
    if (newSidebarColor) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [sideBarView performSelector:setBackgroundColorSelector withObject:newSidebarColor];
#pragma clang diagnostic pop
    }
}

- (ViewControllerState)determineViewControllerStateForLineCount:(NSInteger)lineCount {
    if (lineCount < [[LuftSettings sharedSettings] lowerLimit]) {
        return ViewControllerStateGood;
    } else if (lineCount >= [[LuftSettings sharedSettings] lowerLimit] && lineCount < [[LuftSettings sharedSettings] upperLimit]) {
        return ViewControllerStateWarning;
    } else {
        return ViewControllerStateBad;
    }
}

- (BOOL)isViewController:(NSString *)filename {
    if (![LuftSettings sharedSettings].onlyViewController) {
        return YES;
    }
    
    // The regex excludes:
    // - Categories (checks for "+" in the name)
    // - Files with extension other than "m" or "swift"
    // - Files that don't end in "ViewController"
    
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^[^\\+]*ViewController\\.(m|swift)$"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    
    return !error && [regex firstMatchInString:filename options:0 range:NSMakeRange(0, filename.length)] != nil;
}

+ (NSColor *)generateSidebarColorFromColor:(NSColor *)color {
    if ([[LuftSettings sharedSettings] blendWithSidebar]) {
        return [defaultSidebarColor blendedColorWithFraction:[[LuftSettings sharedSettings] blendFactor] ofColor:color];
    } else {
        return color;
    }
}

+ (NSColor *)goodColor {
    return [[LuftSettings sharedSettings] goodColor];
}

+ (NSColor *)warningColor {
    return [[LuftSettings sharedSettings] warningColor];
}

+ (NSColor *)badColor {
    return [[LuftSettings sharedSettings] badColor];
    
}


@end
