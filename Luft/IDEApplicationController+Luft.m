//
//  IDEApplicationController+Luft.m
//  Luft
//
//  Created by Emil Bogren on 15/11/15.
//  Copyright © 2015 Hugo Tunius. All rights reserved.
//

#import "IDEApplicationController+Luft.h"
#import "NSObject+Additions.h"
#import "Luft.h"

@implementation IDEApplicationController (Luft)

+ (void)luft_initialize {
    if ([self methodForSelector:@selector(_updateEditorAndNavigateMenusIfNeeded)] == NULL) {
        return;
    }

    [self luft_swizzleInstanceMethod:@selector(_updateEditorAndNavigateMenusIfNeeded) with:@selector(luft_updateEditorAndNavigateMenusIfNeeded)];
}

- (void)luft_updateEditorAndNavigateMenusIfNeeded{
    [self luft_updateEditorAndNavigateMenusIfNeeded];

    NSMenu *menu = [[NSApplication sharedApplication] menu];

    NSMenuItem *editorMenuItem = [menu itemWithTitle:@"Editor"];
    NSMenuItem *menuItem = [Luft menuItem];

    if ([[editorMenuItem submenu] itemWithTitle:menuItem.title] == nil) {
        [[editorMenuItem submenu] addItem:[NSMenuItem separatorItem]];
        [[editorMenuItem submenu] addItem:menuItem];
    }
}

@end
