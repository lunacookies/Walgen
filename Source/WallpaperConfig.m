@implementation WallpaperLayer

- (instancetype)init
{
	self = [super init];
	self.backgroundColor = NSColor.redColor;
	self.noiseInfluence = 1;
	self.noiseBias = 0.5f;
	self.noiseThreshold = 0;
	self.pixelSize = 1;
	return self;
}

@end

@implementation WallpaperConfig

- (instancetype)init
{
	self = [super init];
	self.layers = [[NSMutableArray alloc] init];
	[self.layers addObject:[[WallpaperLayer alloc] init]];
	return self;
}

@end
