@implementation AppDelegate
{
	NSWindow *window;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	[self populateMainMenu];

	MainViewController *mainViewController = [[MainViewController alloc] init];
	mainViewController.view.frame = NSMakeRect(0, 0, 800, 500);

	window = [NSWindow windowWithContentViewController:mainViewController];
	[window makeKeyAndOrderFront:nil];
	[NSApp activate];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
	return YES;
}

- (void)populateMainMenu
{
	NSBundle *bundle = [NSBundle mainBundle];
	NSString *displayName = [bundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];

	NSMenu *mainMenu = [[NSMenu alloc] init];

	{
		NSMenuItem *appMenuItem = [[NSMenuItem alloc] init];
		[mainMenu addItem:appMenuItem];

		NSMenu *appMenu = [[NSMenu alloc] init];
		appMenuItem.submenu = appMenu;

		NSString *aboutMenuItemTitle = [NSString stringWithFormat:@"About %@", displayName];
		NSMenuItem *aboutMenuItem =
		        [[NSMenuItem alloc] initWithTitle:aboutMenuItemTitle
		                                   action:@selector(orderFrontStandardAboutPanel:)
		                            keyEquivalent:@""];
		[appMenu addItem:aboutMenuItem];

		[appMenu addItem:[NSMenuItem separatorItem]];

		NSMenuItem *servicesMenuItem = [[NSMenuItem alloc] initWithTitle:@"Services"
		                                                          action:nil
		                                                   keyEquivalent:@""];
		[appMenu addItem:servicesMenuItem];

		NSMenu *servicesMenu = [[NSMenu alloc] init];
		servicesMenuItem.submenu = servicesMenu;
		NSApp.servicesMenu = servicesMenu;

		[appMenu addItem:[NSMenuItem separatorItem]];

		NSString *hideMenuItemTitle = [NSString stringWithFormat:@"Hide %@", displayName];
		NSMenuItem *hideMenuItem = [[NSMenuItem alloc] initWithTitle:hideMenuItemTitle
		                                                      action:@selector(hide:)
		                                               keyEquivalent:@"h"];
		[appMenu addItem:hideMenuItem];

		NSMenuItem *hideOthersMenuItem =
		        [[NSMenuItem alloc] initWithTitle:@"Hide Others"
		                                   action:@selector(hideOtherApplications:)
		                            keyEquivalent:@"h"];
		hideOthersMenuItem.keyEquivalentModifierMask |= NSEventModifierFlagOption;
		[appMenu addItem:hideOthersMenuItem];

		NSMenuItem *showAllMenuItem =
		        [[NSMenuItem alloc] initWithTitle:@"Show All"
		                                   action:@selector(unhideAllApplications:)
		                            keyEquivalent:@""];
		[appMenu addItem:showAllMenuItem];

		[appMenu addItem:[NSMenuItem separatorItem]];

		NSString *quitMenuItemTitle = [NSString stringWithFormat:@"Quit %@", displayName];
		NSMenuItem *quitMenuItem = [[NSMenuItem alloc] initWithTitle:quitMenuItemTitle
		                                                      action:@selector(terminate:)
		                                               keyEquivalent:@"q"];
		[appMenu addItem:quitMenuItem];
	}

	{
		NSMenuItem *fileMenuItem = [[NSMenuItem alloc] init];
		[mainMenu addItem:fileMenuItem];

		NSMenu *fileMenu = [[NSMenu alloc] init];
		fileMenu.title = @"File";
		fileMenuItem.submenu = fileMenu;

		NSMenuItem *exportMenuItem = [[NSMenuItem alloc] initWithTitle:@"Export"
		                                                        action:@selector(export:)
		                                                 keyEquivalent:@"e"];
		[fileMenu addItem:exportMenuItem];

		NSMenuItem *closeMenuItem =
		        [[NSMenuItem alloc] initWithTitle:@"Close"
		                                   action:@selector(performClose:)
		                            keyEquivalent:@"w"];
		[fileMenu addItem:closeMenuItem];
	}

	{
		NSMenuItem *viewMenuItem = [[NSMenuItem alloc] init];
		[mainMenu addItem:viewMenuItem];

		NSMenu *viewMenu = [[NSMenu alloc] init];
		viewMenu.title = @"View";
		viewMenuItem.submenu = viewMenu;

		NSMenuItem *enterFullScreenMenuItem =
		        [[NSMenuItem alloc] initWithTitle:@"Enter Full Screen"
		                                   action:@selector(toggleFullScreen:)
		                            keyEquivalent:@"f"];
		enterFullScreenMenuItem.keyEquivalentModifierMask |= NSEventModifierFlagControl;
		[viewMenu addItem:enterFullScreenMenuItem];
	}

	{
		NSMenuItem *windowMenuItem = [[NSMenuItem alloc] init];
		[mainMenu addItem:windowMenuItem];

		NSMenu *windowMenu = [[NSMenu alloc] init];
		windowMenu.title = @"Window";
		windowMenuItem.submenu = windowMenu;

		NSMenuItem *minimizeMenuItem =
		        [[NSMenuItem alloc] initWithTitle:@"Minimize"
		                                   action:@selector(performMiniaturize:)
		                            keyEquivalent:@"m"];
		[windowMenu addItem:minimizeMenuItem];

		NSMenuItem *zoomMenuItem = [[NSMenuItem alloc] initWithTitle:@"Zoom"
		                                                      action:@selector(performZoom:)
		                                               keyEquivalent:@""];
		[windowMenu addItem:zoomMenuItem];

		[windowMenu addItem:[NSMenuItem separatorItem]];

		NSMenuItem *bringAllToFrontMenuItem =
		        [[NSMenuItem alloc] initWithTitle:@"Bring All to Front"
		                                   action:@selector(arrangeInFront:)
		                            keyEquivalent:@""];
		[windowMenu addItem:bringAllToFrontMenuItem];

		NSApp.windowsMenu = windowMenu;
	}

	NSApp.mainMenu = mainMenu;
}

@end
