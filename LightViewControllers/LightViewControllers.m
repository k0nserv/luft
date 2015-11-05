//
//  LightViewControllers.m
//  LightViewControllers
//
//  Created by Hugo Tunius on 05/11/15.
//  Copyright © 2015 Hugo Tunius. All rights reserved.
//

#import "LightViewControllers.h"

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


@interface LightViewControllers()
@property (nonatomic, strong, readwrite) NSBundle *bundle;
@property (nonatomic, strong) NSMutableSet *__nonnull seenNotifications;
@property (nonatomic, strong) id /* DVTTextStorage * */ currentTexStorage;
@property (nonatomic, strong) id /* IDESourceCodeDocument * */ currentDocument;

- (void)documentDidChange:(NSNotification *)notification;
- (void)swizzleTextDidChangeInSourceView;
- (void)updateUI;
- (ViewControllerState)determineViewControllerStateForLineCount:(NSInteger)lineCount;
- (BOOL)isViewController:(NSString *__nonnull)fileName;
@end

@implementation LightViewControllers

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

        [self performSelector:@selector(swizzleTextDidChangeInSourceView)];
    }
    return self;
}

- (void)didApplicationFinishLaunchingNotification:(NSNotification*)noti {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationDidFinishLaunchingNotification object:nil];
}

- (void)documentDidChange:(NSNotification *)notification {
    NSLog(@"Class %@", [notification.object class]);
    id document = notification.object;

    if (![NSStringFromClass([document class]) isEqualTo:@"IDESourceCodeDocument"]) {
        return;
    }

    if (![document respondsToSelector:@selector(textStorage)]) {
        return;
    }

    
    id textStorage = [document textStorage];

    if (![NSStringFromClass([textStorage class]) isEqualToString:@"DVTTextStorage"]) {
        return;
    }

    self.currentTexStorage = textStorage;
    self.currentDocument = document;
    [self updateUI];
}


- (void)swizzleTextDidChangeInSourceView {
    [objc_getClass("DVTSourceTextView") aspect_hookSelector:@selector(didChangeText)
                                                withOptions:AspectPositionAfter
                                                 usingBlock:^(id<AspectInfo> info) {
                                                     [self updateUI];
                                                 } error:nil];
}

- (void)updateUI {
    SEL numberOfLinesSelector = NSSelectorFromString(@"numberOfLines");
    if (![self.currentTexStorage respondsToSelector:numberOfLinesSelector]) {
        return;
    }

    SEL displayNameSelector = NSSelectorFromString(@"displayName");
    if (![self.currentDocument respondsToSelector:displayNameSelector]) {
        return;
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    NSString *displayName = [self.currentDocument performSelector:displayNameSelector];
#pragma clang diagnostic pop
    if (![self isViewController:displayName]) {
        return;
    }

    IMP implementation = [self.currentTexStorage methodForSelector:numberOfLinesSelector];
    NSInteger linesOfCode = ((NSInteger (*) (id,SEL))implementation)(self.currentTexStorage, numberOfLinesSelector);
    NSLog(@"Number of lines %ld", linesOfCode);
    ViewControllerState state = [self determineViewControllerStateForLineCount:linesOfCode];

    switch (state) {
        case ViewControllerStateGood:
            NSLog(@"All's well");
            break;
        case ViewControllerStateWarning:
            NSLog(@"Keep an eye on those lines");
            break;
        case ViewControllerStateBad:
            NSLog(@"RED RED RED");
            break;
        default:
            break;
    }
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

- (BOOL)isViewController:(NSString *)fileName {
    return [[fileName lowercaseString] rangeOfString:@"viewcontroller"].location != NSNotFound;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
