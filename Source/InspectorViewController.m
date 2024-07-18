@implementation InspectorViewController
{
	NSTextField *label;
}

- (void)viewDidLoad
{
	self.title = @"Inspector";

	label = [NSTextField labelWithString:@"hello world"];
	label.translatesAutoresizingMaskIntoConstraints = NO;
	[self.view addSubview:label];
	[NSLayoutConstraint activateConstraints:@[
		[label.topAnchor constraintEqualToAnchor:self.view.topAnchor],
		[label.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
		[label.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
		[label.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
	]];
}

@end
