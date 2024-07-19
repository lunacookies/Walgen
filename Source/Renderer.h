@interface Renderer : NSObject

@property(class, readonly) Renderer *sharedInstance;
@property(readonly) id<MTLDevice> device;

- (void)renderToTexture:(id<MTLTexture>)texture
        withWallpaperConfig:(WallpaperConfig *)wallpaperConfig;

@end
