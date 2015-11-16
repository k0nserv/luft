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

#import "DVTSourceTextView.h"
#import "IDEApplicationController+Luft.h"
#import "IDESourceCodeDocument.h"
#import "IDESourceCodeEditor+Luft.h"
#import "SettingsWindowController.h"

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

+ (Luft *)instance {
    static Luft *_instance = nil;
    static dispatch_once_t _once;
    dispatch_once(&_once, ^{
        _instance = [[Luft alloc] init];
    });
    return _instance;
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
        [IDEApplicationController luft_initialize];

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

#pragma mark - Settings

- (void)addSettingMenu {
    NSMenu *menu = [[NSApplication sharedApplication] menu];
    NSMenuItem *editorMenuItem = [menu itemWithTitle:@"Editor"];

    [[editorMenuItem submenu] addItem:[NSMenuItem separatorItem]];
    [[editorMenuItem submenu] addItem:[[self class] menuItem]];
}

+ (NSMenuItem *)menuItem {
    NSMenuItem *menuItem = [[NSMenuItem alloc] init];
    menuItem.title = @"Luft";
    NSMenu* subMenu = [[NSMenu alloc] initWithTitle:@"Luft"];
    [menuItem setSubmenu:subMenu];

    NSMenuItem *subMenuItem = [[NSMenuItem alloc] init];
    subMenuItem.title = @"Preferences";
    [subMenuItem setAction:@selector(showSettings:)];
    [subMenuItem setTarget:[Luft instance]];
    [subMenu addItem:subMenuItem];

    return menuItem;
}

- (void)showSettings:(NSNotification *)notification {
    self.settingsWindow = [[SettingsWindowController alloc] initWithWindowNibName:@"SettingsWindowController"];
    [self.settingsWindow showWindow:self.settingsWindow];
}

@end
