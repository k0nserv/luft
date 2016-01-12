//
//  IDEApplicationController+Luft.m
//  Luft
//
//  Created by Emil Bogren on 15/11/15.
//  Copyright © 2015 Hugo Tunius. All rights reserved.
//

#import "IDEApplicationController+Luft.h"
#import "Aspects.h"
#import "Luft.h"

@implementation IDEApplicationController (Luft)

+ (void)luft_initialize {
    [self luft_aspect_hookSelector:@selector(_updateEditorAndNavigateMenusIfNeeded)
                  withOptions:AspectPositionAfter
                   usingBlock:^(id<Luft_AspectInfo> aspectInfo) {
        [aspectInfo.instance luft_updateEditorAndNavigateMenusIfNeeded];
    } error:nil];
}

- (void)luft_updateEditorAndNavigateMenusIfNeeded{
    NSMenu *menu = [[NSApplication sharedApplication] menu];

    NSMenuItem *editorMenuItem = [menu itemWithTitle:@"Editor"];
    NSMenuItem *menuItem = [Luft menuItem];

    if ([[editorMenuItem submenu] itemWithTitle:menuItem.title] == nil) {
        [[editorMenuItem submenu] addItem:[NSMenuItem separatorItem]];
        [[editorMenuItem submenu] addItem:menuItem];
    }
}

@end
