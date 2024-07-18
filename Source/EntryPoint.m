@import AppKit;
@import Metal;
@import simd;

#define Breakpoint() (__builtin_debugtrap())
#define Assert(condition) \
	if (!(condition)) \
	Breakpoint()

@interface
CALayer (Private)
- (void)setContentsChanged;
@end

typedef struct
{
	simd_float2 resolution;
} Arguments;

@interface MainView : NSView <CALayerDelegate>
@end

@implementation MainView
{
	id<MTLDevice> device;
	id<MTLCommandQueue> commandQueue;
	id<MTLRenderPipelineState> pipelineState;

	IOSurfaceRef iosurface;
	id<MTLTexture> texture;
}

- (instancetype)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	self.layer = [CALayer layer];
	self.layer.delegate = self;
	self.wantsLayer = YES;

	device = MTLCreateSystemDefaultDevice();
	commandQueue = [device newCommandQueue];

	id<MTLLibrary> library = [device newDefaultLibrary];
	MTLRenderPipelineDescriptor *descriptor = [[MTLRenderPipelineDescriptor alloc] init];
	descriptor.vertexFunction = [library newFunctionWithName:@"VertexMain"];
	descriptor.fragmentFunction = [library newFunctionWithName:@"FragmentMain"];

	MTLRenderPipelineColorAttachmentDescriptor *attachmentDescriptor =
	        descriptor.colorAttachments[0];
	attachmentDescriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;
	attachmentDescriptor.blendingEnabled = YES;
	attachmentDescriptor.destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
	attachmentDescriptor.destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
	attachmentDescriptor.sourceRGBBlendFactor = MTLBlendFactorOne;
	attachmentDescriptor.sourceAlphaBlendFactor = MTLBlendFactorOne;

	pipelineState = [device newRenderPipelineStateWithDescriptor:descriptor error:nil];

	return self;
}

- (void)displayLayer:(CALayer *)layer
{
	id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];

	MTLRenderPassDescriptor *descriptor = [[MTLRenderPassDescriptor alloc] init];
	descriptor.colorAttachments[0].texture = texture;
	descriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
	descriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.5, 0.5, 0.5, 1);

	id<MTLRenderCommandEncoder> encoder =
	        [commandBuffer renderCommandEncoderWithDescriptor:descriptor];

	[encoder setRenderPipelineState:pipelineState];

	Arguments arguments = {0};
	arguments.resolution.x = texture.width;
	arguments.resolution.y = texture.height;

	[encoder setVertexBytes:&arguments length:sizeof(arguments) atIndex:0];
	[encoder setFragmentBytes:&arguments length:sizeof(arguments) atIndex:0];

	[encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];

	[encoder endEncoding];

	[commandBuffer commit];
	[commandBuffer waitUntilCompleted];

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

	NSDictionary *properties = @{
		(__bridge NSString *)kIOSurfaceWidth : @(size.width),
		(__bridge NSString *)kIOSurfaceHeight : @(size.height),
		(__bridge NSString *)kIOSurfaceBytesPerElement : @4,
		(__bridge NSString *)kIOSurfacePixelFormat : @(kCVPixelFormatType_32BGRA),
	};

	MTLTextureDescriptor *descriptor = [[MTLTextureDescriptor alloc] init];
	descriptor.width = (NSUInteger)size.width;
	descriptor.height = (NSUInteger)size.height;
	descriptor.usage = MTLTextureUsageRenderTarget;
	descriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;

	if (iosurface != NULL)
	{
		CFRelease(iosurface);
	}

	iosurface = IOSurfaceCreate((__bridge CFDictionaryRef)properties);
	texture = [device newTextureWithDescriptor:descriptor iosurface:iosurface plane:0];
	texture.label = @"Layer Contents";

	self.layer.contents = (__bridge id)iosurface;
}

@end

@interface AppDelegate : NSObject <NSApplicationDelegate>
@end

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
	NSRect contentRect = CenteredContentRect(NSMakeSize(600, 700), styleMask, screen);

	window = [[NSWindow alloc] initWithContentRect:contentRect
	                                     styleMask:styleMask
	                                       backing:NSBackingStoreBuffered
	                                         defer:NO
	                                        screen:screen];
	window.title = @"Walgen";

	[window makeKeyAndOrderFront:nil];
	window.contentView = [[MainView alloc] init];

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

int32_t
main(void)
{
	setenv("MTL_SHADER_VALIDATION", "1", 1);
	setenv("MTL_DEBUG_LAYER", "1", 1);
	setenv("MTL_DEBUG_LAYER_WARNING_MODE", "nslog", 1);

	[NSApplication sharedApplication];
	AppDelegate *appDelegate = [[AppDelegate alloc] init];
	NSApp.delegate = appDelegate;
	[NSApp run];
}
