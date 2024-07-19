@interface PreviewView : NSView <CALayerDelegate>
- (instancetype)initWithWallpaperConfig:(WallpaperConfig *)wallpaperConfig
                     notificationCenter:(NSNotificationCenter *)notificationCenter;
@end
