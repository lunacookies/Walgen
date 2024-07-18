@implementation InspectorViewController
{
	WallpaperConfig *wallpaperConfig;
	NSNotificationCenter *notificationCenter;
	NSGridView *gridView;
	NSColorWell *backgroundColorWell;
	NSSlider *noiseInfluenceSlider;
	NSSlider *noiseBiasSlider;
	NSSlider *noiseThresholdSlider;
	NSSlider *pixelSizeSlider;
}

- (instancetype)initWithWallpaperConfig:(WallpaperConfig *)wallpaperConfig_
                     notificationCenter:(NSNotificationCenter *)notificationCenter_
{
	self = [self init];
	wallpaperConfig = wallpaperConfig_;
	notificationCenter = notificationCenter_;
	return self;
}

- (void)viewDidLoad
{
	self.title = @"Inspector";

	backgroundColorWell = [NSColorWell colorWellWithStyle:NSColorWellStyleDefault];
	backgroundColorWell.target = self;
	backgroundColorWell.action = @selector(configNeedsUpdate:);
	backgroundColorWell.color = NSColor.grayColor;

	noiseInfluenceSlider = [NSSlider sliderWithValue:1
	                                        minValue:0
	                                        maxValue:1
	                                          target:self
	                                          action:@selector(configNeedsUpdate:)];

	noiseBiasSlider = [NSSlider sliderWithValue:1
	                                   minValue:0.001
	                                   maxValue:1
	                                     target:self
	                                     action:@selector(configNeedsUpdate:)];

	noiseThresholdSlider = [NSSlider sliderWithValue:0
	                                        minValue:0
	                                        maxValue:1
	                                          target:self
	                                          action:@selector(configNeedsUpdate:)];

	uint32_t pixelSizeMinimum = 1;
	uint32_t pixelSizeMaximum = 4;
	pixelSizeSlider = [NSSlider sliderWithValue:pixelSizeMinimum
	                                   minValue:pixelSizeMinimum
	                                   maxValue:pixelSizeMaximum
	                                     target:self
	                                     action:@selector(configNeedsUpdate:)];
	pixelSizeSlider.numberOfTickMarks = pixelSizeMaximum - pixelSizeMinimum + 1;
	pixelSizeSlider.allowsTickMarkValuesOnly = YES;

	gridView = [NSGridView gridViewWithViews:@[
		@[ [NSTextField labelWithString:@"Background Color:"], backgroundColorWell ],
		@[ [NSTextField labelWithString:@"Noise Influence:"], noiseInfluenceSlider ],
		@[ [NSTextField labelWithString:@"Noise Bias:"], noiseBiasSlider ],
		@[ [NSTextField labelWithString:@"Noise Threshold:"], noiseThresholdSlider ],
		@[ [NSTextField labelWithString:@"Pixel Size:"], pixelSizeSlider ],
	]];
	gridView.rowAlignment = NSGridRowAlignmentFirstBaseline;

	NSGridColumn *firstColumn = [gridView columnAtIndex:0];
	firstColumn.xPlacement = NSGridCellPlacementTrailing;

	gridView.translatesAutoresizingMaskIntoConstraints = NO;
	CGFloat padding = 10;
	[self.view addSubview:gridView];
	[NSLayoutConstraint activateConstraints:@[
		[gridView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:padding],
		[gridView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor
		                                       constant:padding],
		[gridView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor
		                                        constant:-padding],
		[gridView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor
		                                      constant:-padding],

		[noiseInfluenceSlider.widthAnchor constraintGreaterThanOrEqualToConstant:100],
	]];

	[self configNeedsUpdate:nil];
}

- (void)configNeedsUpdate:(id)sender
{
	wallpaperConfig.backgroundColor = backgroundColorWell.color;
	wallpaperConfig.noiseInfluence = noiseInfluenceSlider.floatValue;
	wallpaperConfig.noiseBias = noiseBiasSlider.floatValue;
	wallpaperConfig.noiseThreshold = noiseThresholdSlider.floatValue;
	wallpaperConfig.pixelSize = (uint32_t)pixelSizeSlider.integerValue;

	[notificationCenter postNotificationName:wallpaperConfigChangedNotification object:nil];
}

@end
