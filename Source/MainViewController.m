@interface
MainViewController () <InspectorDelegate>
@end

@implementation MainViewController
{
	PreviewView *previewView;
	NSPanel *inspector;
}

- (void)viewDidLoad
{
	self.title = @"Preview";

	previewView = [[PreviewView alloc] init];

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

	InspectorViewController *inspectorViewController = [[InspectorViewController alloc] init];
	inspectorViewController.delegate = self;

	// Prevent the inspector from being 500×500 by setting the view’s frame explicitly,
	// for some reason.
	inspectorViewController.view.frame = inspectorRect;
	inspector.contentViewController = inspectorViewController;

	[inspector bind:NSTitleBinding
	           toObject:inspector.contentViewController
	        withKeyPath:@"title"
	            options:nil];

	[inspector orderFront:nil];
}

- (void)backgroundColorDidChange:(NSColor *)color
{
	previewView.backgroundColor = color;
}

- (void)noiseInfluenceDidChange:(float)influence
{
	previewView.noiseInfluence = influence;
}

@end
