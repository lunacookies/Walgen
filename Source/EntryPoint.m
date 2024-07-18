@import AppKit;
@import Metal;
@import simd;

#include "AppDelegate.h"
#include "InspectorViewController.h"
#include "MainViewController.h"
#include "PreviewView.h"

#include "AppDelegate.m"
#include "InspectorViewController.m"
#include "MainViewController.m"
#include "PreviewView.m"

int32_t
main(void)
{
	setenv("MTL_SHADER_VALIDATION", "1", 1);
	setenv("MTL_DEBUG_LAYER", "1", 1);
	setenv("MTL_DEBUG_LAYER_WARNING_MODE", "nslog", 1);

	[NSApplication sharedApplication];
	AppDelegate *appDelegate = [[AppDelegate alloc] init];
	NSApp.delegate = appDelegate;
	[NSApp run];
}
