@interface LayerCellView : NSView
@end

static NSUserInterfaceItemIdentifier const layerCellViewIdentifier = @"LayerCellView";

@implementation LayerCellView

- (instancetype)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	self.identifier = layerCellViewIdentifier;

	NSTextField *label = [NSTextField labelWithString:@"hello world"];
	[self addSubview:label];
	label.translatesAutoresizingMaskIntoConstraints = NO;
	[NSLayoutConstraint activateConstraints:@[
		[label.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
		[label.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
		[label.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
	]];

	return self;
}

@end

@interface
LayersViewController () <NSTableViewDelegate, NSTableViewDataSource>
@end

@implementation LayersViewController
{
	WallpaperConfig *wallpaperConfig;
	NSNotificationCenter *notificationCenter;
}

- (instancetype)initWithWallpaperConfig:(WallpaperConfig *)wallpaperConfig_
                     notificationCenter:(NSNotificationCenter *)notificationCenter_
{
	self = [self init];
	self.title = @"Layers";
	wallpaperConfig = wallpaperConfig_;
	notificationCenter = notificationCenter_;
	return self;
}

- (void)viewDidLoad
{
	NSTableView *tableView = [[NSTableView alloc] init];
	tableView.delegate = self;
	tableView.dataSource = self;
	tableView.headerView = nil;

	NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:@"column"];
	[tableView addTableColumn:column];

	NSScrollView *scrollView = [[NSScrollView alloc] init];
	scrollView.documentView = tableView;
	scrollView.hasVerticalScroller = YES;
	scrollView.autohidesScrollers = YES;

	scrollView.translatesAutoresizingMaskIntoConstraints = NO;
	[self.view addSubview:scrollView];
	[NSLayoutConstraint activateConstraints:@[
		[scrollView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
		[scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
		[scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
		[scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
	]];
}

- (NSView *)tableView:(NSTableView *)tableView
        viewForTableColumn:(NSTableColumn *)tableColumn
                       row:(NSInteger)row
{
	LayerCellView *view = [tableView makeViewWithIdentifier:layerCellViewIdentifier owner:nil];

	if (view == nil)
	{
		view = [[LayerCellView alloc] init];
	}

	return view;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	NSTableView *tableView = notification.object;
	[notificationCenter postNotificationName:layerSelectionChangedNotification
	                                  object:@(tableView.selectedRow)];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return (NSInteger)wallpaperConfig.layers.count;
}

- (id)tableView:(NSTableView *)tableView
        objectValueForTableColumn:(NSTableColumn *)tableColumn
                              row:(NSInteger)row
{
	return wallpaperConfig.layers[(NSUInteger)row];
}

@end
