@interface WallpaperLayer : NSObject
@property NSColor *backgroundColor;
@property float noiseInfluence;
@property float noiseBias;
@property float noiseThreshold;
@property simd_uint2 noiseOffset;
@property uint32_t pixelSize;
@end

@interface WallpaperConfig : NSObject
@property NSMutableArray<WallpaperLayer *> *layers;
@end
