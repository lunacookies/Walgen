#!/bin/sh

set -e

clang-format -i Source/*.h Source/*.m Source/*.metal

rm -rf "Build"

mkdir -p "Build/Walgen.app/Contents/MacOS"
mkdir -p "Build/Walgen.app/Contents/Resources"

cp "Data/Walgen-Info.plist" "Build/Walgen.app/Contents/Info.plist"
plutil -convert binary1 "Build/Walgen.app/Contents/Info.plist"

clang \
	-o "Build/Walgen.app/Contents/MacOS/Walgen" \
	-I Source \
	-fmodules -fobjc-arc \
	-g3 \
	-fsanitize=undefined \
	-W \
	-Wall \
	-Wextra \
	-Wpedantic \
	-Wconversion \
	-Wimplicit-fallthrough \
	-Wmissing-prototypes \
	-Wshadow \
	-Wstrict-prototypes \
	"Source/EntryPoint.m"

xcrun metal \
	-o "Build/Walgen.app/Contents/Resources/default.metallib" \
	-gline-tables-only -frecord-sources \
	"Source/Shaders.metal"

cp "Data/Walgen.entitlements" "Build/Walgen.entitlements"
/usr/libexec/PlistBuddy -c 'Add :com.apple.security.get-task-allow bool YES' \
	"Build/Walgen.entitlements"
codesign \
	--sign - \
	--entitlements "Build/Walgen.entitlements" \
	--options runtime "Build/Walgen.app/Contents/MacOS/Walgen"
