//
//  Luft.m
//  Luft
//
//  Created by Hugo Tunius on 05/11/15.
//  Copyright © 2015 Hugo Tunius. All rights reserved.
//

#import "Luft.h"

#import "Aspects.h"
#import "SettingsWindowController.h"
#import <objc/runtime.h>

#import "DVTSourceTextView.h"
#import "IDESourceCodeDocument.h"
#import "IDESourceCodeEditor+Luft.h"

static BOOL debug = NO;

static NSString *const IDESourceCodeEditorDidFinishSetupNotification = @"IDESourceCodeEditorDidFinishSetup";

@interface Luft()
@property (nonatomic, strong, readwrite) NSBundle *bundle;
@property (nonatomic, strong) NSMutableSet *__nonnull seenNotifications;
@property (nonatomic, strong) SettingsWindowController *settingsWindow;

- (void)editorDidFinishSetup:(NSNotification *)notification;
- (void)traceNotifications:(NSNotification *)notification;
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
                                                 selector:@selector(editorDidFinishSetup:)
                                                     name:IDESourceCodeEditorDidFinishSetupNotification
                                                   object:nil];
        [IDESourceCodeEditor luft_initialize];

        if (debug) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(traceNotifications:) name:nil object:nil];
        }
    }
    return self;
}

- (void)didApplicationFinishLaunchingNotification:(NSNotification*)noti {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationDidFinishLaunchingNotification object:nil];

    [self addSettingMenu];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)editorDidFinishSetup:(NSNotification *)notification {
    IDESourceCodeEditor *editor = notification.object;

    if (![editor isKindOfClass:[IDESourceCodeEditor class]]) {
        return;
    }

    [editor handleTextChange];
}

- (void)traceNotifications:(NSNotification *)notification {
    if ([notification.name hasPrefix:@"IDE"] || [notification.name hasPrefix:@"DVT"]) {
        NSLog(@"Notification with name: %@, Class: %@", notification.name, [notification.object class]);
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

#pragma mark - Settings

- (void)addSettingMenu {
    NSMenuItem *editMenuItem = [[NSApp mainMenu] itemWithTitle:@"Window"];
    if (editMenuItem) {
        NSMenuItem *newMenuItem = [[NSMenuItem alloc] initWithTitle:@"Luft💨" action:@selector(showSettings:) keyEquivalent:@""];

        [newMenuItem setTarget:self];
        [[editMenuItem submenu] addItem:newMenuItem];
    }
}

- (void)showSettings:(NSNotification *)notification {
    self.settingsWindow = [[SettingsWindowController alloc] initWithWindowNibName:@"SettingsWindowController"];
    [self.settingsWindow showWindow:self.settingsWindow];
}

@end
