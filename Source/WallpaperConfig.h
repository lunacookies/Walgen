@interface WallpaperLayer : NSObject
@property NSColor *backgroundColor;
@property float noiseInfluence;
@property float noiseBias;
@property float noiseThreshold;
@property uint32_t pixelSize;
@end

@interface WallpaperConfig : NSObject
@property NSMutableArray<WallpaperLayer *> *layers;
@end
