typedef struct
{
	simd_float2 resolution;
	simd_float3 backgroundColor;
	float noiseInfluence;
	float noiseBias;
	float noiseThreshold;
	uint32_t pixelSize;
	MTLResourceID noiseTexture;
} Arguments;

@implementation Renderer
{
	id<MTLDevice> device;
	id<MTLCommandQueue> commandQueue;
	id<MTLRenderPipelineState> pipelineState;
	id<MTLTexture> noiseTexture;
}

- (instancetype)init
{
	self = [super init];

	device = MTLCreateSystemDefaultDevice();
	commandQueue = [device newCommandQueue];

	id<MTLLibrary> library = [device newDefaultLibrary];

	{
		MTLRenderPipelineDescriptor *descriptor =
		        [[MTLRenderPipelineDescriptor alloc] init];
		descriptor.vertexFunction = [library newFunctionWithName:@"VertexMain"];
		descriptor.fragmentFunction = [library newFunctionWithName:@"FragmentMain"];

		MTLRenderPipelineColorAttachmentDescriptor *attachmentDescriptor =
		        descriptor.colorAttachments[0];
		attachmentDescriptor.pixelFormat = MTLPixelFormatRGBA16Float;
		attachmentDescriptor.blendingEnabled = YES;
		attachmentDescriptor.destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
		attachmentDescriptor.destinationAlphaBlendFactor =
		        MTLBlendFactorOneMinusSourceAlpha;
		attachmentDescriptor.sourceRGBBlendFactor = MTLBlendFactorOne;
		attachmentDescriptor.sourceAlphaBlendFactor = MTLBlendFactorOne;

		pipelineState = [device newRenderPipelineStateWithDescriptor:descriptor error:nil];
	}

	{
		MTLTextureDescriptor *descriptor = [[MTLTextureDescriptor alloc] init];
		descriptor.width = 1024;
		descriptor.height = 1024;
		descriptor.pixelFormat = MTLPixelFormatR8Unorm;
		descriptor.usage = MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite;
		descriptor.storageMode = MTLStorageModePrivate;
		noiseTexture = [device newTextureWithDescriptor:descriptor];

		id<MTLComputePipelineState> noiseGenerationPipelineState =
		        [device newComputePipelineStateWithFunction:
		                        [library newFunctionWithName:@"GenerateNoise"]
		                                              error:nil];

		id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];

		id<MTLComputeCommandEncoder> encoder = [commandBuffer computeCommandEncoder];
		[encoder setComputePipelineState:noiseGenerationPipelineState];
		[encoder setTexture:noiseTexture atIndex:0];
		[encoder dispatchThreads:MTLSizeMake(descriptor.width, descriptor.height, 1)
		        threadsPerThreadgroup:MTLSizeMake(32, 32, 1)];
		[encoder endEncoding];

		[commandBuffer commit];
		[commandBuffer waitUntilCompleted];
	}

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
	arguments.noiseTexture = noiseTexture.gpuResourceID;

	[encoder useResource:noiseTexture usage:MTLResourceUsageRead stages:MTLRenderStageFragment];
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
