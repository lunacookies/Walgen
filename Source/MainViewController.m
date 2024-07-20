@interface ExportAccessoryView : NSView
@property(readonly) NSInteger width;
@property(readonly) NSInteger height;
@end

@implementation ExportAccessoryView
{
	NSTextField *widthField;
	NSTextField *heightField;
}

- (instancetype)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];

	widthField = [[NSTextField alloc] init];
	heightField = [[NSTextField alloc] init];

	NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
	formatter.minimum = @1;
	widthField.formatter = formatter;
	heightField.formatter = formatter;

	widthField.integerValue = 1920;
	heightField.integerValue = 1080;

	NSGridView *gridView = [NSGridView gridViewWithViews:@[
		@[ [NSTextField labelWithString:@"Width:"], widthField ],
		@[ [NSTextField labelWithString:@"Height:"], heightField ],
	]];
	gridView.rowAlignment = NSGridRowAlignmentFirstBaseline;

	NSGridColumn *firstColumn = [gridView columnAtIndex:0];
	firstColumn.xPlacement = NSGridCellPlacementTrailing;

	gridView.translatesAutoresizingMaskIntoConstraints = NO;
	[self addSubview:gridView];
	NSLayoutGuide *guide = self.layoutMarginsGuide;
	[NSLayoutConstraint activateConstraints:@[
		[gridView.topAnchor constraintEqualToAnchor:guide.topAnchor],
		[gridView.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor],
		[gridView.leadingAnchor constraintGreaterThanOrEqualToAnchor:guide.leadingAnchor],
		[guide.trailingAnchor constraintGreaterThanOrEqualToAnchor:gridView.trailingAnchor],
		[gridView.centerXAnchor constraintEqualToAnchor:guide.centerXAnchor],
		[gridView.centerYAnchor constraintEqualToAnchor:guide.centerYAnchor],
		[widthField.widthAnchor constraintEqualToConstant:100],
		[widthField.widthAnchor constraintEqualToAnchor:heightField.widthAnchor],
	]];

	return self;
}

- (NSInteger)width
{
	return widthField.integerValue;
}

- (NSInteger)height
{
	return heightField.integerValue;
}

@end

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

- (void)export:(id)sender
{
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	savePanel.nameFieldLabel = @"Export As:";
	savePanel.allowedContentTypes = @[ UTTypePNG ];

	ExportAccessoryView *accessoryView = [[ExportAccessoryView alloc] init];
	savePanel.accessoryView = accessoryView;

	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	dateFormatter.dateFormat = @"yyyy-MM-dd 'at' HH.mm";
	savePanel.nameFieldStringValue = [NSString stringWithFormat:@"Wallpaper at %@.png",
	                                           [dateFormatter stringFromDate:[NSDate date]]];

	void (^completionHandler)(NSModalResponse) = ^(NSModalResponse response) {
		if (response != NSModalResponseOK)
		{
			return;
		}

		MTLTextureDescriptor *descriptor = [[MTLTextureDescriptor alloc] init];
		descriptor.width = (NSUInteger)accessoryView.width;
		descriptor.height = (NSUInteger)accessoryView.height;
		descriptor.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
		descriptor.pixelFormat = MTLPixelFormatRGBA16Float;

		id<MTLTexture> texture =
		        [Renderer.sharedInstance.device newTextureWithDescriptor:descriptor];
		texture.label = @"Export Texture";

		[Renderer.sharedInstance renderToTexture:texture
		                     withWallpaperConfig:wallpaperConfig];

		CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(colorSpaceName);
		CIImage *ciImage = [CIImage
		        imageWithMTLTexture:texture
		                    options:@{kCIImageColorSpace : (__bridge id)colorSpace}];

		NSError *error = nil;

		[[CIContext context] writePNGRepresentationOfImage:ciImage
		                                             toURL:savePanel.URL
		                                            format:kCIFormatRGBAh
		                                        colorSpace:colorSpace
		                                           options:@{}
		                                             error:&error];

		if (error != nil)
		{
			[self presentError:error
			            modalForWindow:self.view.window
			                  delegate:nil
			        didPresentSelector:nil
			               contextInfo:NULL];
			return;
		}

		[NSFileManager.defaultManager
		        setAttributes:@{NSFileExtensionHidden : @(savePanel.extensionHidden)}
		         ofItemAtPath:savePanel.URL.path
		                error:&error];

		if (error != nil)
		{
			[self presentError:error
			            modalForWindow:self.view.window
			                  delegate:nil
			        didPresentSelector:nil
			               contextInfo:NULL];
			return;
		}
	};

	[savePanel beginSheetModalForWindow:self.view.window completionHandler:completionHandler];
}

@end
