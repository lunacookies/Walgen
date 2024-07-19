@implementation InspectorViewController
{
	WallpaperConfig *wallpaperConfig;
	NSNotificationCenter *notificationCenter;

	NSTextField *noSelectionLabel;

	NSGridView *gridView;
	NSColorWell *backgroundColorWell;
	NSSlider *noiseInfluenceSlider;
	NSSlider *noiseBiasSlider;
	NSSlider *noiseThresholdSlider;
	NSSlider *pixelSizeSlider;

	NSInteger selectedLayerIndex;
}

- (instancetype)initWithWallpaperConfig:(WallpaperConfig *)wallpaperConfig_
                     notificationCenter:(NSNotificationCenter *)notificationCenter_
{
	self = [self init];
	self.title = @"Inspector";
	wallpaperConfig = wallpaperConfig_;
	notificationCenter = notificationCenter_;
	selectedLayerIndex = -1;

	[notificationCenter addObserver:self
	                       selector:@selector(selectionDidChange:)
	                           name:layerSelectionChangedNotification
	                         object:nil];

	return self;
}

- (void)viewDidLoad
{
	noSelectionLabel = [NSTextField labelWithString:@"No Layer Selected"];
	noSelectionLabel.font = [NSFont systemFontOfSize:24];
	noSelectionLabel.textColor = NSColor.placeholderTextColor;
	noSelectionLabel.alignment = NSTextAlignmentCenter;

	noSelectionLabel.translatesAutoresizingMaskIntoConstraints = NO;
	[self.view addSubview:noSelectionLabel];
	[NSLayoutConstraint activateConstraints:@[
		[noSelectionLabel.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
		[noSelectionLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
		[noSelectionLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
	]];

	backgroundColorWell = [NSColorWell colorWellWithStyle:NSColorWellStyleDefault];
	backgroundColorWell.target = self;
	backgroundColorWell.action = @selector(configNeedsUpdate:);

	noiseInfluenceSlider = [NSSlider sliderWithValue:0
	                                        minValue:0
	                                        maxValue:1
	                                          target:self
	                                          action:@selector(configNeedsUpdate:)];

	noiseBiasSlider = [NSSlider sliderWithValue:0
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
	[self.view addSubview:gridView];
	NSLayoutGuide *guide = self.view.layoutMarginsGuide;
	[NSLayoutConstraint activateConstraints:@[
		[gridView.topAnchor constraintEqualToAnchor:guide.topAnchor],
		[gridView.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor],
		[gridView.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor],
		[gridView.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor],

		[noiseInfluenceSlider.widthAnchor constraintGreaterThanOrEqualToConstant:100],
	]];

	[self selectionDidChange:[NSNotification
	                                 notificationWithName:layerSelectionChangedNotification
	                                               object:@(selectedLayerIndex)]];
}

- (void)selectionDidChange:(NSNotification *)notification
{
	selectedLayerIndex = ((NSNumber *)notification.object).integerValue;

	if (selectedLayerIndex == -1)
	{
		noSelectionLabel.hidden = NO;
		gridView.hidden = YES;
		return;
	}

	noSelectionLabel.hidden = YES;
	gridView.hidden = NO;

	WallpaperLayer *layer = wallpaperConfig.layers[(NSUInteger)selectedLayerIndex];
	backgroundColorWell.color = layer.backgroundColor;
	noiseInfluenceSlider.floatValue = layer.noiseInfluence;
	noiseBiasSlider.floatValue = layer.noiseBias;
	noiseThresholdSlider.floatValue = layer.noiseThreshold;
	pixelSizeSlider.integerValue = layer.pixelSize;
}

- (void)configNeedsUpdate:(id)sender
{
	if (selectedLayerIndex == -1)
	{
		return;
	}

	WallpaperLayer *layer = wallpaperConfig.layers[(NSUInteger)selectedLayerIndex];
	layer.backgroundColor = backgroundColorWell.color;
	layer.noiseInfluence = noiseInfluenceSlider.floatValue;
	layer.noiseBias = noiseBiasSlider.floatValue;
	layer.noiseThreshold = noiseThresholdSlider.floatValue;
	layer.pixelSize = (uint32_t)pixelSizeSlider.integerValue;

	[notificationCenter postNotificationName:wallpaperConfigChangedNotification object:nil];
}

@end
