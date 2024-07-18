@implementation InspectorViewController
{
	WallpaperConfig *wallpaperConfig;
	NSNotificationCenter *notificationCenter;
	NSGridView *gridView;
	NSColorWell *backgroundColorWell;
	NSSlider *noiseInfluenceSlider;
}

- (instancetype)initWithWallpaperConfig:(WallpaperConfig *)wallpaperConfig_
                     notificationCenter:(NSNotificationCenter *)notificationCenter_
{
	self = [super init];
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

	gridView = [NSGridView gridViewWithViews:@[
		@[ [NSTextField labelWithString:@"Background Color:"], backgroundColorWell ],
		@[ [NSTextField labelWithString:@"Noise Influence:"], noiseInfluenceSlider ],
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

	[notificationCenter postNotificationName:wallpaperConfigChangedNotification object:nil];
}

@end
