@interface
CALayer (Private)
- (void)setContentsChanged;
@end

typedef struct
{
	simd_float2 resolution;
} Arguments;

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
