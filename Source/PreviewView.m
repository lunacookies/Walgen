@interface
CALayer (Private)
- (void)setContentsChanged;
@end

@implementation PreviewView
{
	IOSurfaceRef iosurface;
	id<MTLTexture> texture;
	WallpaperConfig *wallpaperConfig;
	NSNotificationCenter *notificationCenter;
}

- (instancetype)initWithWallpaperConfig:(WallpaperConfig *)wallpaperConfig_
                     notificationCenter:(NSNotificationCenter *)notificationCenter_
{
	self = [self init];

	wallpaperConfig = wallpaperConfig_;
	notificationCenter = notificationCenter_;
	[notificationCenter addObserver:self
	                       selector:@selector(configWasUpdated:)
	                           name:wallpaperConfigChangedNotification
	                         object:nil];

	self.layer = [CALayer layer];
	self.layer.delegate = self;
	self.wantsLayer = YES;

	[NSLayoutConstraint activateConstraints:@[
		[self.widthAnchor constraintGreaterThanOrEqualToConstant:300],
		[self.heightAnchor constraintGreaterThanOrEqualToConstant:200],
	]];

	return self;
}

- (void)displayLayer:(CALayer *)layer
{
	[Renderer.sharedInstance renderToTexture:texture withWallpaperConfig:wallpaperConfig];
	[self.layer setContentsChanged];
}

- (void)layoutSublayersOfLayer:(CALayer *)layer
{
	[self updateIOSurface];
	[self.layer setNeedsDisplay];
}

- (void)viewDidChangeBackingProperties
{
	[super viewDidChangeBackingProperties];

	self.layer.contentsScale = self.window.backingScaleFactor;
	[self updateIOSurface];
	[self.layer setNeedsDisplay];
}

- (void)updateIOSurface
{
	NSSize size = [self convertSizeToBacking:self.layer.frame.size];

	if (size.width == 0 || size.height == 0)
	{
		return;
	}

	NSDictionary *properties = @{
		(__bridge NSString *)kIOSurfaceWidth : @(size.width),
		(__bridge NSString *)kIOSurfaceHeight : @(size.height),
		(__bridge NSString *)kIOSurfaceBytesPerElement : @8,
		(__bridge NSString *)kIOSurfacePixelFormat : @(kCVPixelFormatType_64RGBAHalf),
	};

	MTLTextureDescriptor *descriptor = [[MTLTextureDescriptor alloc] init];
	descriptor.width = (NSUInteger)size.width;
	descriptor.height = (NSUInteger)size.height;
	descriptor.usage = MTLTextureUsageRenderTarget;
	descriptor.pixelFormat = MTLPixelFormatRGBA16Float;

	if (iosurface != NULL)
	{
		CFRelease(iosurface);
	}

	iosurface = IOSurfaceCreate((__bridge CFDictionaryRef)properties);
	IOSurfaceSetValue(iosurface, kIOSurfaceColorSpace, colorSpaceName);
	texture = [Renderer.sharedInstance.device newTextureWithDescriptor:descriptor
	                                                         iosurface:iosurface
	                                                             plane:0];
	texture.label = @"Layer Contents";

	self.layer.contents = (__bridge id)iosurface;
}

- (void)configWasUpdated:(id)sender
{
	[self.layer setNeedsDisplay];
}

@end
