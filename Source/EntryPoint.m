@import AppKit;
@import Metal;
@import simd;

static NSNotificationName const wallpaperConfigChangedNotification =
        @"wallpaperConfigChangedNotification";

static NSNotificationName const layerColorChangedNotification = @"layerColorChangedNotification";

static NSNotificationName const layerSelectionChangedNotification =
        @"layerSelectionChangedNotification";

#define Min(x, y) (((x) < (y)) ? (x) : (y))
#define Max(x, y) (((x) > (y)) ? (x) : (y))

#include "AppDelegate.h"
#include "WallpaperConfig.h"
#include "InspectorViewController.h"
#include "LayersViewController.h"
#include "MainViewController.h"
#include "PreviewView.h"

#include "AppDelegate.m"
#include "WallpaperConfig.m"
#include "InspectorViewController.m"
#include "LayersViewController.m"
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
