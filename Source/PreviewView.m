@interface
CALayer (Private)
- (void)setContentsChanged;
@end

typedef struct
{
	simd_float2 resolution;
	simd_float3 backgroundColor;
	float noiseInfluence;
	float noiseBias;
	float noiseThreshold;
	uint32_t pixelSize;
} Arguments;

#define colorSpaceName kCGColorSpaceDisplayP3

@implementation PreviewView
{
	id<MTLDevice> device;
	id<MTLCommandQueue> commandQueue;
	id<MTLRenderPipelineState> pipelineState;

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

	device = MTLCreateSystemDefaultDevice();
	commandQueue = [device newCommandQueue];

	id<MTLLibrary> library = [device newDefaultLibrary];
	MTLRenderPipelineDescriptor *descriptor = [[MTLRenderPipelineDescriptor alloc] init];
	descriptor.vertexFunction = [library newFunctionWithName:@"VertexMain"];
	descriptor.fragmentFunction = [library newFunctionWithName:@"FragmentMain"];

	MTLRenderPipelineColorAttachmentDescriptor *attachmentDescriptor =
	        descriptor.colorAttachments[0];
	attachmentDescriptor.pixelFormat = MTLPixelFormatRGBA16Float;
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

	id<MTLRenderCommandEncoder> encoder =
	        [commandBuffer renderCommandEncoderWithDescriptor:descriptor];

	[encoder setRenderPipelineState:pipelineState];

	WallpaperLayer *wallpaperLayer = wallpaperConfig.layers[0];

	CGColorSpaceRef cgColorSpace = CGColorSpaceCreateWithName(colorSpaceName);
	NSColorSpace *colorSpace = [[NSColorSpace alloc] initWithCGColorSpace:cgColorSpace];
	NSColor *backgroundColor = [wallpaperLayer.backgroundColor colorUsingColorSpace:colorSpace];

	Arguments arguments = {0};
	arguments.resolution.x = texture.width;
	arguments.resolution.y = texture.height;
	arguments.backgroundColor.r = (float)backgroundColor.redComponent;
	arguments.backgroundColor.g = (float)backgroundColor.greenComponent;
	arguments.backgroundColor.b = (float)backgroundColor.blueComponent;
	arguments.noiseInfluence = wallpaperLayer.noiseInfluence;
	arguments.noiseBias = wallpaperLayer.noiseBias;
	arguments.noiseThreshold = wallpaperLayer.noiseThreshold;
	arguments.pixelSize = wallpaperLayer.pixelSize;

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
	texture = [device newTextureWithDescriptor:descriptor iosurface:iosurface plane:0];
	texture.label = @"Layer Contents";

	self.layer.contents = (__bridge id)iosurface;
}

- (void)configWasUpdated:(id)sender
{
	[self.layer setNeedsDisplay];
}

@end
