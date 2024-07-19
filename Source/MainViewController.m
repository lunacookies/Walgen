@implementation MainViewController
{
	PreviewView *previewView;
	NSPanel *inspector;
	NSPanel *layersPanel;

	WallpaperConfig *wallpaperConfig;
	NSNotificationCenter *notificationCenter;
}

- (void)viewDidLoad
{
	self.title = @"Preview";

	WallpaperLayer *layer = [[WallpaperLayer alloc] init];
	layer.backgroundColor = NSColor.redColor;
	layer.noiseInfluence = 1;
	layer.noiseBias = 0.5f;
	layer.noiseThreshold = 0;
	layer.pixelSize = 1;

	wallpaperConfig = [[WallpaperConfig alloc] init];
	wallpaperConfig.layers = @[ layer ];

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
	CGFloat panelMargin = 24;

	NSRect windowContentRect =
	        [self.view.window contentRectForFrameRect:self.view.window.frame];

	NSRect inspectorContentRect = {0};

	inspectorContentRect.origin = windowContentRect.origin;
	inspectorContentRect.origin.x += windowContentRect.size.width + panelMargin;
	inspectorContentRect.origin.y += windowContentRect.size.height;

	inspectorContentRect.size.width = 1;
	inspectorContentRect.size.height = 1;
	inspectorContentRect.origin.y -= inspectorContentRect.size.height;

	inspector = [[NSPanel alloc]
	        initWithContentRect:inspectorContentRect
	                  styleMask:NSWindowStyleMaskUtilityWindow | NSWindowStyleMaskTitled
	                    backing:NSBackingStoreBuffered
	                      defer:NO];

	InspectorViewController *inspectorViewController =
	        [[InspectorViewController alloc] initWithWallpaperConfig:wallpaperConfig
	                                              notificationCenter:notificationCenter];
	inspectorViewController.view.frame = inspectorContentRect;
	inspector.contentViewController = inspectorViewController;

	[inspector bind:NSTitleBinding
	           toObject:inspectorViewController
	        withKeyPath:@"title"
	            options:nil];

	[inspector orderFront:nil];

	NSRect layersPanelFrameRect = {0};

	layersPanelFrameRect.size.width = inspectorViewController.view.frame.size.width;
	layersPanelFrameRect.size.height = 300;

	layersPanelFrameRect.origin = inspector.frame.origin;
	layersPanelFrameRect.origin.y -= layersPanelFrameRect.size.height + panelMargin;

	NSWindowStyleMask layersPanelStyleMask =
	        NSWindowStyleMaskUtilityWindow | NSWindowStyleMaskTitled;
	NSRect layersPanelContentRect = [NSPanel contentRectForFrameRect:layersPanelFrameRect
	                                                       styleMask:layersPanelStyleMask];

	layersPanel = [[NSPanel alloc] initWithContentRect:layersPanelContentRect
	                                         styleMask:layersPanelStyleMask
	                                           backing:NSBackingStoreBuffered
	                                             defer:NO];

	LayersViewController *layersViewController =
	        [[LayersViewController alloc] initWithWallpaperConfig:wallpaperConfig
	                                           notificationCenter:notificationCenter];
	layersViewController.view.frame = layersPanelContentRect;
	layersPanel.contentViewController = layersViewController;

	[layersPanel bind:NSTitleBinding
	           toObject:layersViewController
	        withKeyPath:@"title"
	            options:nil];

	[layersPanel orderFront:nil];
}

@end
