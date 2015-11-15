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
#import <AppKit/AppKit.h>

typedef NS_ENUM(NSInteger, ViewControllerState) {
    ViewControllerStateGood,
    ViewControllerStateWarning,
    ViewControllerStateBad
};

@interface IDESourceCodeEditor(LuftPrivate)
- (void)updateUIWithSourceTextView:(DVTSourceTextView *)sourceTextView
                          document:(IDESourceCodeDocument *)document;
- (ViewControllerState)determineViewControllerStateForLineCount:(NSInteger)lineCount;
- (BOOL)isViewController:(NSString *__nonnull)filename;

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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    switch (state) {
        case ViewControllerStateGood:
            [sideBarView performSelector:setBackgroundColorSelector withObject:[[self class] goodColor]];
            break;
        case ViewControllerStateWarning:
            [sideBarView performSelector:setBackgroundColorSelector withObject:[[self class] warningColor]];
            break;
        case ViewControllerStateBad:
            [sideBarView performSelector:setBackgroundColorSelector withObject:[[self class] badColor]];
            break;
        default:
            break;
    }
#pragma clang diagnostic pop
}

- (ViewControllerState)determineViewControllerStateForLineCount:(NSInteger)lineCount {
    if (lineCount < 150) {
        return ViewControllerStateGood;
    } else if (lineCount >= 150 && lineCount < 300) {
        return ViewControllerStateWarning;
    } else {
        return ViewControllerStateBad;
    }
}

- (BOOL)isViewController:(NSString *)filename {
    NSString *lowerCaseFilename = [filename lowercaseString];
    BOOL isViewController = [lowerCaseFilename rangeOfString:@"viewcontroller"].location != NSNotFound;
    BOOL isImplementationOrSwift = [lowerCaseFilename rangeOfString:@".m"].location != NSNotFound || [lowerCaseFilename rangeOfString:@".swift"].location != NSNotFound;
    isViewController = isViewController && isImplementationOrSwift;

    return isViewController;
}

+ (NSColor *)goodColor {
    return [NSColor colorWithCalibratedRed: 0.2 green: 0.51 blue: 0.0471 alpha: 0.5];
}

+ (NSColor *)warningColor {
    return [NSColor colorWithCalibratedRed: 0.49 green: 0.51 blue: 0.0471 alpha: 0.5];
}

+ (NSColor *)badColor {
    return [NSColor colorWithCalibratedRed: 0.51 green: 0.0471 blue: 0.0471 alpha: 0.5];
    
}


@end
