@implementation MainViewController
{
	PreviewView *previewView;
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	previewView = [[PreviewView alloc] init];

	previewView.translatesAutoresizingMaskIntoConstraints = NO;
	[self.view addSubview:previewView];
	[NSLayoutConstraint activateConstraints:@[
		[previewView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
		[previewView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
		[previewView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
		[previewView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
	]];
}

@end
