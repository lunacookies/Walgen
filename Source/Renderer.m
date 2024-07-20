typedef struct
{
	simd_float2 resolution;
	simd_float3 backgroundColor;
	float noiseInfluence;
	float noiseBias;
	float noiseThreshold;
	uint32_t pixelSize;
} Arguments;

@implementation Renderer
{
	id<MTLDevice> device;
	id<MTLCommandQueue> commandQueue;
	id<MTLRenderPipelineState> pipelineState;
}

- (instancetype)init
{
	self = [super init];

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

+ (instancetype)sharedInstance
{
	static Renderer *sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[Renderer alloc] init];
	});
	return sharedInstance;
}

- (void)renderToTexture:(id<MTLTexture>)texture
        withWallpaperConfig:(WallpaperConfig *)wallpaperConfig
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
}

- (id<MTLDevice>)device
{
	return device;
}

@end
