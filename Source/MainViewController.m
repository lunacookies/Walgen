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

	NSInteger screenWidthMax = 0;
	NSInteger screenHeightMax = 0;

	for (NSScreen *screen in NSScreen.screens)
	{
		NSSize screenResolution = [screen convertRectToBacking:screen.frame].size;
		screenWidthMax = Max(screenWidthMax, (NSInteger)screenResolution.width);
		screenHeightMax = Max(screenHeightMax, (NSInteger)screenResolution.height);
	}

	widthField.integerValue = screenWidthMax;
	heightField.integerValue = screenHeightMax;

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
	InspectorViewController *inspectorViewController;
	LayersViewController *layersViewController;
	WallpaperConfig *wallpaperConfig;
	NSNotificationCenter *notificationCenter;
}

- (void)viewDidLoad
{
	self.title = @"Walgen";

	wallpaperConfig = [[WallpaperConfig alloc] init];
	notificationCenter = [[NSNotificationCenter alloc] init];

	PreviewView *previewView = [[PreviewView alloc] initWithWallpaperConfig:wallpaperConfig
	                                                     notificationCenter:notificationCenter];

	inspectorViewController =
	        [[InspectorViewController alloc] initWithWallpaperConfig:wallpaperConfig
	                                              notificationCenter:notificationCenter];

	layersViewController =
	        [[LayersViewController alloc] initWithWallpaperConfig:wallpaperConfig
	                                           notificationCenter:notificationCenter];

	NSBox *separator = [[NSBox alloc] init];
	separator.boxType = NSBoxSeparator;

	NSStackView *configStackView = [NSStackView stackViewWithViews:@[
		inspectorViewController.view, separator, layersViewController.view
	]];
	configStackView.orientation = NSUserInterfaceLayoutOrientationVertical;
	configStackView.spacing = 0;

	NSStackView *stackView = [NSStackView stackViewWithViews:@[ previewView, configStackView ]];
	stackView.spacing = 0;

	stackView.translatesAutoresizingMaskIntoConstraints = NO;
	[self.view addSubview:stackView];
	[NSLayoutConstraint activateConstraints:@[
		[stackView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
		[stackView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
		[stackView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
		[stackView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
	]];
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
