//
//  Luft.m
//  Luft
//
//  Created by Hugo Tunius on 05/11/15.
//  Copyright © 2015 Hugo Tunius. All rights reserved.
//

#import "Luft.h"

#import "Aspects.h"
#import <objc/runtime.h>

typedef NS_ENUM(NSInteger, ViewControllerState) {
    ViewControllerStateGood,
    ViewControllerStateWarning,
    ViewControllerStateBad
};

/*!
 * Triggered when the open document changes
 */
static NSString *const IDEEditorDocumentDidChangeNotification = @"IDEEditorDocumentDidChangeNotification";
static NSString *const IDEEditorDocumentWillSaveNotification = @"IDEEditorDocumentWillSaveNotification";

static BOOL debug = YES;

@interface Luft()
@property (nonatomic, strong, readwrite) NSBundle *bundle;
@property (nonatomic, strong) NSMutableSet *__nonnull seenNotifications;

- (void)traceNotifications:(NSNotification *)notification;
- (void)documentDidChange:(NSNotification *)notification;
- (void)updateUIWithSourceTextView:(NSView /*DVTSourceTextView*/ *)sourceTextView
                          document:(id /* IDESourceCodeDocument * */)document;
- (ViewControllerState)determineViewControllerStateForLineCount:(NSInteger)lineCount;
- (BOOL)isViewController:(NSString *__nonnull)filename;

+ (NSColor *)goodColor;
+ (NSColor *)warningColor;
+ (NSColor *)badColor;
@end

@implementation Luft

+ (instancetype)sharedPlugin {
    return sharedPlugin;
}

- (id)initWithBundle:(NSBundle *)plugin {
    if (self = [super init]) {
        // reference to plugin's bundle, for resource access
        self.bundle = plugin;
        self.seenNotifications = [NSMutableSet new];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didApplicationFinishLaunchingNotification:)
                                                     name:NSApplicationDidFinishLaunchingNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(documentDidChange:)
                                                     name:IDEEditorDocumentDidChangeNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(documentDidChange:)
                                                     name:IDEEditorDocumentWillSaveNotification
                                                   object:nil];

        if (debug) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(traceNotifications:) name:nil object:nil];
        }
    }
    return self;
}

- (void)didApplicationFinishLaunchingNotification:(NSNotification*)noti {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationDidFinishLaunchingNotification object:nil];
}

- (void)traceNotifications:(NSNotification *)notification {
    if ([notification.name hasPrefix:@"IDE"] || [notification.name hasPrefix:@"DVT"]) {
        NSLog(@"Notification with name: %@, Class: %@", notification.name, [notification.object class]);
    }
}

- (void)documentDidChange:(NSNotification *)notification {
    id document = notification.object;
    NSLog(@"Document did changeIDEEditorDocumentDidChangeNotification");

    if (![NSStringFromClass([document class]) isEqualTo:@"IDESourceCodeDocument"]) {
        return;
    }

    if (![document respondsToSelector:@selector(textStorage)]) {
        return;
    }

    id firstResponder = [[NSApp mainWindow] firstResponder];
    if ([NSStringFromClass([firstResponder class]) isEqualToString:@"DVTSourceTextView"]) {
        [self updateUIWithSourceTextView:(NSView *)firstResponder document:document];
    }
}

- (void)updateUIWithSourceTextView:(NSView *)sourceTextView document:(id)document {
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
    for (NSView *view in sourceTextView.superview.superview.subviews) {
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

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
