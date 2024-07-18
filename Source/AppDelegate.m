@implementation AppDelegate
{
	NSWindow *window;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	[self populateMainMenu];

	NSWindowStyleMask styleMask = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
	                              NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable;

	NSScreen *screen = NSScreen.mainScreen;
	NSRect contentRect = CenteredContentRect(NSMakeSize(800, 500), styleMask, screen);

	window = [[NSWindow alloc] initWithContentRect:contentRect
	                                     styleMask:styleMask
	                                       backing:NSBackingStoreBuffered
	                                         defer:NO
	                                        screen:screen];

	[window makeKeyAndOrderFront:nil];

	MainViewController *mainViewController = [[MainViewController alloc] init];
	mainViewController.view.frame = contentRect;
	window.contentViewController = mainViewController;

	[window bind:NSTitleBinding toObject:mainViewController withKeyPath:@"title" options:nil];

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

static NSRect
CenteredContentRect(NSSize contentSize, NSWindowStyleMask styleMask, NSScreen *screen)
{
	NSEdgeInsets insets = VisibleScreenFrameEdgeInsets(screen);

	// Ignore horizontal offsets (caused by those heathens who position the Dock
	// on the left or right edge of the screen) to make sure the window is
	// centered horizontally.
	insets.left = 0;
	insets.right = 0;

	NSRect fullScreenFrame = {0};
	fullScreenFrame.size = screen.frame.size;
	NSRect screenFrame = InsetRect(fullScreenFrame, insets);

	NSRect contentRect = {0};
	contentRect.size = contentSize;
	NSSize windowSize = [NSWindow frameRectForContentRect:contentRect styleMask:styleMask].size;

	NSRect windowRect = {0};
	windowRect.size = windowSize;
	windowRect.origin = screenFrame.origin;

	// 1:1 left gap to right gap ratio.
	windowRect.origin.x += (screenFrame.size.width - windowSize.width) / 2;

	// 1:2 top gap to bottom gap ratio.
	windowRect.origin.y += (screenFrame.size.height - windowSize.height) / 3 * 2;

	return [NSWindow contentRectForFrameRect:windowRect styleMask:styleMask];
}

static NSEdgeInsets
VisibleScreenFrameEdgeInsets(NSScreen *screen)
{
	NSEdgeInsets result = {0};

	NSRect fullScreenFrame = screen.frame;
	NSRect visibleScreenFrame = screen.visibleFrame;

	result.bottom = visibleScreenFrame.origin.y - fullScreenFrame.origin.y;
	result.left = visibleScreenFrame.origin.x - fullScreenFrame.origin.x;

	result.top = (fullScreenFrame.origin.y + fullScreenFrame.size.height) -
	             (visibleScreenFrame.origin.y + visibleScreenFrame.size.height);
	result.right = (fullScreenFrame.origin.x + fullScreenFrame.size.width) -
	               (visibleScreenFrame.origin.x + visibleScreenFrame.size.width);

	return result;
}

static NSRect
InsetRect(NSRect rect, NSEdgeInsets insets)
{
	NSRect result = rect;

	result.origin.x += insets.left;
	result.size.width -= insets.left;

	result.origin.y += insets.bottom;
	result.size.height -= insets.bottom;

	result.size.width -= insets.right;

	result.size.height -= insets.top;

	return result;
}

@end
