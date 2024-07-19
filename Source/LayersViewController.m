@interface LayerCellView : NSView
@property NSColor *layerColor;
@end

static NSUserInterfaceItemIdentifier const layerCellViewIdentifier = @"LayerCellView";

@implementation LayerCellView
{
	NSColor *layerColor;
	NSBox *coloredSquare;
}

- (instancetype)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	self.identifier = layerCellViewIdentifier;

	coloredSquare = [[NSBox alloc] init];
	coloredSquare.boxType = NSBoxCustom;
	coloredSquare.borderWidth = 1;
	coloredSquare.borderColor = [NSColor colorWithSRGBRed:1 green:1 blue:1 alpha:0.2f];
	coloredSquare.cornerRadius = 4;

	NSTextField *label = [NSTextField labelWithString:@"hello world"];

	[self addSubview:coloredSquare];
	[self addSubview:label];
	coloredSquare.translatesAutoresizingMaskIntoConstraints = NO;
	label.translatesAutoresizingMaskIntoConstraints = NO;
	[NSLayoutConstraint activateConstraints:@[
		[coloredSquare.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
		[coloredSquare.trailingAnchor constraintEqualToAnchor:label.leadingAnchor
		                                             constant:-4],
		[label.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],

		[coloredSquare.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
		[label.centerYAnchor constraintEqualToAnchor:coloredSquare.centerYAnchor],

		[coloredSquare.widthAnchor constraintEqualToConstant:16],
		[coloredSquare.heightAnchor constraintEqualToAnchor:coloredSquare.widthAnchor],
	]];

	return self;
}

- (NSColor *)layerColor
{
	return layerColor;
}

- (void)setLayerColor:(NSColor *)layerColor_
{
	layerColor = layerColor_;
	coloredSquare.fillColor = layerColor;
}

@end

@interface
LayersViewController () <NSTableViewDelegate, NSTableViewDataSource>
@end

@implementation LayersViewController
{
	WallpaperConfig *wallpaperConfig;
	NSNotificationCenter *notificationCenter;
	NSTableView *tableView;
	NSSegmentedControl *layerControls;
}

- (instancetype)initWithWallpaperConfig:(WallpaperConfig *)wallpaperConfig_
                     notificationCenter:(NSNotificationCenter *)notificationCenter_
{
	self = [self init];
	self.title = @"Layers";
	wallpaperConfig = wallpaperConfig_;
	notificationCenter = notificationCenter_;

	[notificationCenter addObserver:self
	                       selector:@selector(layerColorDidChange:)
	                           name:layerColorChangedNotification
	                         object:nil];

	return self;
}

- (void)viewDidLoad
{
	tableView = [[NSTableView alloc] init];
	tableView.delegate = self;
	tableView.dataSource = self;
	tableView.headerView = nil;
	tableView.style = NSTableViewStyleFullWidth;
	tableView.usesAlternatingRowBackgroundColors = YES;

	NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:@"column"];
	[tableView addTableColumn:column];

	NSScrollView *scrollView = [[NSScrollView alloc] init];
	scrollView.documentView = tableView;
	scrollView.hasVerticalScroller = YES;
	scrollView.autohidesScrollers = YES;

	NSArray<NSImage *> *segmentImages = @[
		[NSImage imageNamed:NSImageNameAddTemplate],
		[NSImage imageNamed:NSImageNameRemoveTemplate],
		[[NSImage alloc] init],
	];
	layerControls =
	        [NSSegmentedControl segmentedControlWithImages:segmentImages
	                                          trackingMode:NSSegmentSwitchTrackingMomentary
	                                                target:self
	                                                action:@selector(willAddOrRemoveLayer:)];
	layerControls.segmentStyle = NSSegmentStyleSmallSquare;
	[layerControls setEnabled:NO forSegment:2];
	[layerControls setWidth:32 forSegment:0];
	[layerControls setWidth:32 forSegment:1];
	[layerControls setContentHuggingPriority:1
	                          forOrientation:NSLayoutConstraintOrientationHorizontal];

	[self updateLayerControlsEnabledState];

	NSStackView *stackView = [NSStackView stackViewWithViews:@[ scrollView, layerControls ]];
	stackView.orientation = NSUserInterfaceLayoutOrientationVertical;
	stackView.spacing = 0;

	stackView.translatesAutoresizingMaskIntoConstraints = NO;
	[self.view addSubview:stackView];
	[NSLayoutConstraint activateConstraints:@[
		[stackView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
		[stackView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
		[stackView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
		[stackView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
	]];
}

- (NSView *)tableView:(NSTableView *)_
        viewForTableColumn:(NSTableColumn *)tableColumn
                       row:(NSInteger)row
{
	LayerCellView *view = [tableView makeViewWithIdentifier:layerCellViewIdentifier owner:nil];
	if (view == nil)
	{
		view = [[LayerCellView alloc] init];
	}

	WallpaperLayer *layer = [self tableView:tableView
	              objectValueForTableColumn:tableColumn
	                                    row:row];
	view.layerColor = layer.backgroundColor;

	return view;
}

- (void)layerColorDidChange:(NSNotification *)notification
{
	[tableView reloadData];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	[notificationCenter postNotificationName:layerSelectionChangedNotification
	                                  object:@(tableView.selectedRow)];
	[self updateLayerControlsEnabledState];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)_
{
	return (NSInteger)wallpaperConfig.layers.count;
}

- (id)tableView:(NSTableView *)_
        objectValueForTableColumn:(NSTableColumn *)tableColumn
                              row:(NSInteger)row
{
	return wallpaperConfig.layers[(NSUInteger)row];
}

- (void)willAddOrRemoveLayer:(NSSegmentedControl *)sender
{
	NSInteger selection = tableView.selectedRow;

	switch (layerControls.selectedSegment)
	{
		case 0:
		{
			[wallpaperConfig.layers addObject:[[WallpaperLayer alloc] init]];
			NSIndexSet *indexSet =
			        [NSIndexSet indexSetWithIndex:wallpaperConfig.layers.count - 1];
			[tableView insertRowsAtIndexes:indexSet
			                 withAnimation:NSTableViewAnimationEffectFade |
			                               NSTableViewAnimationSlideDown];
			break;
		}

		case 1:
		{
			[wallpaperConfig.layers removeObjectAtIndex:(NSUInteger)selection];
			NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:(NSUInteger)selection];
			[tableView removeRowsAtIndexes:indexSet
			                 withAnimation:NSTableViewAnimationEffectFade |
			                               NSTableViewAnimationSlideUp];
			break;
		}

		default: return;
	}

	[notificationCenter postNotificationName:wallpaperConfigChangedNotification object:nil];

	NSUInteger index = 0;
	switch (layerControls.selectedSegment)
	{
		case 0: index = wallpaperConfig.layers.count - 1; break;
		case 1: index = Min((NSUInteger)selection, wallpaperConfig.layers.count - 1); break;
	}
	[tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
	[tableView scrollRowToVisible:(NSInteger)index];

	[self updateLayerControlsEnabledState];
}

- (void)updateLayerControlsEnabledState
{
	BOOL allowedToRemove = wallpaperConfig.layers.count > 1 && tableView.selectedRow != -1;
	[layerControls setEnabled:allowedToRemove forSegment:1];
}

@end
