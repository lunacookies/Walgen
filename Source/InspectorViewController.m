@implementation InspectorViewController
{
	NSGridView *gridView;
}

- (void)viewDidLoad
{
	self.title = @"Inspector";

	NSColorWell *backgroundColorWell = [NSColorWell colorWellWithStyle:NSColorWellStyleDefault];
	backgroundColorWell.target = self;
	backgroundColorWell.action = @selector(backgroundColorDidChange:);
	backgroundColorWell.color = NSColor.grayColor;
	[self backgroundColorDidChange:backgroundColorWell];

	NSSlider *noiseInfluenceSlider =
	        [NSSlider sliderWithValue:1
	                         minValue:0
	                         maxValue:1
	                           target:self
	                           action:@selector(noiseInfluenceDidChange:)];
	[self noiseInfluenceDidChange:noiseInfluenceSlider];

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
}

- (void)backgroundColorDidChange:(NSColorWell *)backgroundColorWell
{
	[self.delegate backgroundColorDidChange:backgroundColorWell.color];
}

- (void)noiseInfluenceDidChange:(NSSlider *)slider
{
	[self.delegate noiseInfluenceDidChange:slider.floatValue];
}

@end
