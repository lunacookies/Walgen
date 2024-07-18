@implementation MainViewController
{
	PreviewView *previewView;
	NSPanel *inspector;

	WallpaperConfig *wallpaperConfig;
	NSNotificationCenter *notificationCenter;
}

- (void)viewDidLoad
{
	self.title = @"Preview";

	wallpaperConfig = [[WallpaperConfig alloc] init];
	notificationCenter = [[NSNotificationCenter alloc] init];

	previewView = [[PreviewView alloc] initWithWallpaperConfig:wallpaperConfig
	                                        notificationCenter:notificationCenter];

	previewView.translatesAutoresizingMaskIntoConstraints = NO;
	[self.view addSubview:previewView];
	[NSLayoutConstraint activateConstraints:@[
		[previewView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
		[previewView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
		[previewView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
		[previewView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
	]];
}

- (void)viewDidAppear
{
	NSRect windowRect = [self.view.window contentRectForFrameRect:self.view.window.frame];

	NSRect inspectorRect = {0};

	inspectorRect.origin = windowRect.origin;
	inspectorRect.origin.x += windowRect.size.width + 24;
	inspectorRect.origin.y += windowRect.size.height;

	inspectorRect.size.width = 1;
	inspectorRect.size.height = 1;
	inspectorRect.origin.y -= inspectorRect.size.height;

	inspector = [[NSPanel alloc]
	        initWithContentRect:inspectorRect
	                  styleMask:NSWindowStyleMaskUtilityWindow | NSWindowStyleMaskTitled
	                    backing:NSBackingStoreBuffered
	                      defer:NO];

	InspectorViewController *inspectorViewController =
	        [[InspectorViewController alloc] initWithWallpaperConfig:wallpaperConfig
	                                              notificationCenter:notificationCenter];

	inspectorViewController.view.frame = inspectorRect;
	inspector.contentViewController = inspectorViewController;

	[inspector bind:NSTitleBinding
	           toObject:inspectorViewController
	        withKeyPath:@"title"
	            options:nil];

	[inspector orderFront:nil];
}

@end
