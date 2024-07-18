@implementation InspectorViewController
{
	NSGridView *gridView;
}

- (void)viewDidLoad
{
	self.title = @"Inspector";

	NSTextField *label = [NSTextField labelWithString:@"Background Color:"];
	NSColorWell *backgroundColorWell = [NSColorWell colorWellWithStyle:NSColorWellStyleDefault];
	backgroundColorWell.target = self;
	backgroundColorWell.action = @selector(backgroundColorDidChange:);

	gridView = [NSGridView gridViewWithViews:@[
		@[ label, backgroundColorWell ],
	]];
	gridView.yPlacement = NSGridCellPlacementCenter;

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
	]];
}

- (void)backgroundColorDidChange:(NSColorWell *)backgroundColorWell
{
	NSLog(@"%@", backgroundColorWell.color);
}

@end
