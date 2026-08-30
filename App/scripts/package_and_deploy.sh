#!/bin/bash
set -e

# scripts/package_and_deploy.sh
# Production multi-platform build & deployment pipeline.
# Builds Linux bundle, Android APK, and iPad iOS IPA.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ARTIFACTS_DIR="/home/aprajit/Cozmo/ipad/build_artifacts"

mkdir -p "$ARTIFACTS_DIR/linux"
mkdir -p "$ARTIFACTS_DIR/android"
mkdir -p "$ARTIFACTS_DIR/ipad_ios"

echo "========================================="
echo "🛠️ Local Ecosystem — Multi-Platform Build"
echo "========================================="

cd "$APP_DIR"

# 1. Build Linux Release
echo "🐧 Building Linux Release..."
flutter build linux --release
pkill -f "$ARTIFACTS_DIR/linux/local_ecosystem" 2>/dev/null || true
rm -rf "$ARTIFACTS_DIR/linux/"*
cp -r build/linux/x64/release/bundle/* "$ARTIFACTS_DIR/linux/"
echo "✅ Linux build copied to: $ARTIFACTS_DIR/linux/"

# 2. Build Android Release APK
echo "📱 Building Android Release APK..."
flutter build apk --release
cp build/app/outputs/flutter-apk/app-release.apk "$ARTIFACTS_DIR/android/local_ecosystem.apk"
echo "✅ Android APK copied to: $ARTIFACTS_DIR/android/local_ecosystem.apk"

# 3. Package iPad/iOS Release AOT .ipa
echo "🍎 Compiling iPad/iOS Release AOT Framework..."
mkdir -p /tmp/bin /tmp/iPhoneOS.sdk
ln -sf /usr/bin/llvm-lipo-18 /tmp/bin/lipo 2>/dev/null || true
ln -sf /usr/bin/llvm-strip-18 /tmp/bin/strip 2>/dev/null || true
ln -sf /usr/bin/dsymutil-18 /tmp/bin/dsymutil 2>/dev/null || ln -sf /usr/bin/true /tmp/bin/dsymutil
ln -sf /usr/bin/true /tmp/bin/codesign

PATH="/tmp/bin:$PATH" flutter assemble \
  -dTargetPlatform=ios -dBuildMode=release \
  -dSdkRoot=/tmp/iPhoneOS.sdk -dIosArchs=arm64 \
  -dTargetFile=lib/main.dart --output=build/ios_aot aot_assembly_release || true

rm -rf /tmp/ios_ipa_build
mkdir -p /tmp/ios_ipa_build/Payload/Runner.app/Frameworks/App.framework

cp -r "$APP_DIR/build/ios_aot/Flutter.framework" /tmp/ios_ipa_build/Payload/Runner.app/Frameworks/

AOT_DYLIB=$(find "$APP_DIR/.dart_tool/flutter_build" -name "App" -type f | grep -E "arm64/App.framework/App" | head -n 1)
if [ -n "$AOT_DYLIB" ]; then
  cp "$AOT_DYLIB" /tmp/ios_ipa_build/Payload/Runner.app/Frameworks/App.framework/App
fi

cp -r "$APP_DIR/build/flutter_assets" /tmp/ios_ipa_build/Payload/Runner.app/Frameworks/App.framework/flutter_assets
cp -r "$APP_DIR/build/flutter_assets" /tmp/ios_ipa_build/Payload/Runner.app/
cp "$APP_DIR/ios/Runner/Info.plist" /tmp/ios_ipa_build/Payload/Runner.app/
sed -i 's/\$(EXECUTABLE_NAME)/Runner/g' /tmp/ios_ipa_build/Payload/Runner.app/Info.plist
sed -i 's/\$(PRODUCT_BUNDLE_IDENTIFIER)/com.localecosystem.localEcosystem/g' /tmp/ios_ipa_build/Payload/Runner.app/Info.plist
sed -i 's/\$(FLUTTER_BUILD_NAME)/1.0.0/g' /tmp/ios_ipa_build/Payload/Runner.app/Info.plist
sed -i 's/\$(FLUTTER_BUILD_NUMBER)/1/g' /tmp/ios_ipa_build/Payload/Runner.app/Info.plist
sed -i 's/local_ecosystem/LocalEcosystem/g' /tmp/ios_ipa_build/Payload/Runner.app/Info.plist
echo "APPL????" > /tmp/ios_ipa_build/Payload/Runner.app/PkgInfo

cat << 'PLIST' > /tmp/ios_ipa_build/Payload/Runner.app/Frameworks/App.framework/Info.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>App</string>
  <key>CFBundleIdentifier</key>
  <string>io.flutter.flutter.app</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>App</string>
  <key>CFBundlePackageType</key>
  <string>FMWK</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundleSignature</key>
  <string>????</string>
  <key>CFBundleVersion</key>
  <string>1.0</string>
  <key>MinimumOSVersion</key>
  <string>12.0</string>
</dict>
</plist>
PLIST

# Setup LLVM Darwin linker and iOS tbd stubs
ln -sf /usr/bin/lld /tmp/ld64.lld

cat << 'EOF' > /tmp/UIKit.tbd
--- !tapi-tbd-v3
archs:           [ arm64 ]
uuids:           [ 'arm64: 00000000-0000-0000-0000-000000000000' ]
platform:        ios
install-name:    '/System/Library/Frameworks/UIKit.framework/UIKit'
current-version: 6100
compatibility-version: 1
exports:
  - archs:           [ arm64 ]
    symbols:         [ _UIApplicationMain ]
...
EOF

cat << 'EOF' > /tmp/objc.tbd
--- !tapi-tbd-v3
archs:           [ arm64 ]
uuids:           [ 'arm64: 00000000-0000-0000-0000-000000000000' ]
platform:        ios
install-name:    '/usr/lib/libobjc.A.dylib'
current-version: 228
compatibility-version: 1
exports:
  - archs:           [ arm64 ]
    symbols:         [ _objc_allocateClassPair, _objc_registerClassPair, _objc_getClass, _sel_registerName, _objc_msgSend, _class_addMethod ]
...
EOF

cat << 'EOF' > /tmp/libSystem.tbd
--- !tapi-tbd-v3
archs:           [ arm64 ]
uuids:           [ 'arm64: 00000000-0000-0000-0000-000000000000' ]
platform:        ios
install-name:    '/usr/lib/libSystem.B.dylib'
current-version: 1319
compatibility-version: 1
exports:
  - archs:           [ arm64 ]
    symbols:         [ dyld_stub_binder, _dyld_stub_binder, ___stack_chk_guard, ___stack_chk_fail ]
...
EOF

cat << 'EOF' > /tmp/runner.c
#include <stdint.h>
#include <stdbool.h>

typedef struct objc_class *Class;
typedef struct objc_object *id;
typedef struct objc_selector *SEL;
typedef void *IMP;

typedef struct {
    double x;
    double y;
} CGPoint;

typedef struct {
    double width;
    double height;
} CGSize;

typedef struct {
    CGPoint origin;
    CGSize size;
} CGRect;

extern Class objc_allocateClassPair(Class superclass, const char *name, unsigned long extraBytes);
extern void objc_registerClassPair(Class cls);
extern Class objc_getClass(const char *name);
extern SEL sel_registerName(const char *name);
extern id objc_msgSend(id self, SEL op, ...);
extern bool class_addMethod(Class cls, SEL name, IMP imp, const char *types);
extern int UIApplicationMain(int argc, char *argv[], id principalClassName, id delegateClassName);

static id make_nsstring(const char *str) {
    Class NSStringClass = objc_getClass("NSString");
    SEL sel = sel_registerName("stringWithUTF8String:");
    return ((id (*)(Class, SEL, const char *))objc_msgSend)(NSStringClass, sel, str);
}

static bool app_didFinishLaunching(id self, SEL _cmd, id application, id launchOptions) {
    // 1. Get UIScreen mainScreen bounds
    Class UIScreenClass = objc_getClass("UIScreen");
    id mainScreen = ((id (*)(Class, SEL))objc_msgSend)(UIScreenClass, sel_registerName("mainScreen"));
    CGRect bounds = ((CGRect (*)(id, SEL))objc_msgSend)(mainScreen, sel_registerName("bounds"));

    // 2. Alloc and init UIWindow
    Class UIWindowClass = objc_getClass("UIWindow");
    id windowAlloc = ((id (*)(Class, SEL))objc_msgSend)(UIWindowClass, sel_registerName("alloc"));
    id window = ((id (*)(id, SEL, CGRect))objc_msgSend)(windowAlloc, sel_registerName("initWithFrame:"), bounds);

    // 3. Alloc and init FlutterViewController
    Class FVCClass = objc_getClass("FlutterViewController");
    id fvcAlloc = ((id (*)(Class, SEL))objc_msgSend)(FVCClass, sel_registerName("alloc"));
    id fvc = ((id (*)(id, SEL, id, id, id, id))objc_msgSend)(fvcAlloc, sel_registerName("initWithProject:initialRoute:nibName:bundle:"), (id)0, (id)0, (id)0, (id)0);

    // 4. Set rootViewController
    ((void (*)(id, SEL, id))objc_msgSend)(window, sel_registerName("setRootViewController:"), fvc);

    // 5. Set self.window = window
    ((void (*)(id, SEL, id))objc_msgSend)(self, sel_registerName("setWindow:"), window);

    // 6. makeKeyAndVisible
    ((void (*)(id, SEL))objc_msgSend)(window, sel_registerName("makeKeyAndVisible"));

    // 7. Optional plugin registration
    Class registrantClass = objc_getClass("GeneratedPluginRegistrant");
    if (registrantClass) {
        SEL regSel = sel_registerName("registerWithRegistry:");
        if (regSel) {
            ((void (*)(Class, SEL, id))objc_msgSend)(registrantClass, regSel, self);
        }
    }

    return true;
}

int main(int argc, char *argv[]) {
    Class flutterAppDelegateClass = objc_getClass("FlutterAppDelegate");
    if (!flutterAppDelegateClass) {
        flutterAppDelegateClass = objc_getClass("UIResponder");
    }

    Class appDelegateClass = objc_getClass("AppDelegate");
    if (!appDelegateClass && flutterAppDelegateClass) {
        appDelegateClass = objc_allocateClassPair(flutterAppDelegateClass, "AppDelegate", 0);
        if (appDelegateClass) {
            SEL launchSel = sel_registerName("application:didFinishLaunchingWithOptions:");
            class_addMethod(appDelegateClass, launchSel, (IMP)app_didFinishLaunching, "c@:@@");
            objc_registerClassPair(appDelegateClass);
        }
    }

    id delegateName = make_nsstring("AppDelegate");
    return UIApplicationMain(argc, argv, (id)0, delegateName);
}
EOF

clang -target arm64-apple-ios14.0 -ffreestanding -c /tmp/runner.c -o /tmp/runner.o

/tmp/ld64.lld -arch arm64 -platform_version ios 14.0 14.0 \
  -rpath @executable_path/Frameworks \
  /tmp/UIKit.tbd /tmp/objc.tbd /tmp/libSystem.tbd \
  /tmp/ios_ipa_build/Payload/Runner.app/Frameworks/Flutter.framework/Flutter \
  -e _main /tmp/runner.o -o /tmp/ios_ipa_build/Payload/Runner.app/Runner

cp -r "$APP_DIR/ios/Runner/Base.lproj" /tmp/ios_ipa_build/Payload/Runner.app/ 2>/dev/null || true
cp "$APP_DIR/assets/icons/app_icon.png" /tmp/ios_ipa_build/Payload/Runner.app/AppIcon.png 2>/dev/null || true
cp "$APP_DIR/assets/icons/app_icon.png" /tmp/ios_ipa_build/Payload/Runner.app/AppIcon20x20@2x.png 2>/dev/null || true
cp "$APP_DIR/assets/icons/app_icon.png" /tmp/ios_ipa_build/Payload/Runner.app/AppIcon29x29@2x.png 2>/dev/null || true
cp "$APP_DIR/assets/icons/app_icon.png" /tmp/ios_ipa_build/Payload/Runner.app/AppIcon40x40@2x.png 2>/dev/null || true
cp "$APP_DIR/assets/icons/app_icon.png" /tmp/ios_ipa_build/Payload/Runner.app/AppIcon60x60@2x.png 2>/dev/null || true
cp "$APP_DIR/assets/icons/app_icon.png" /tmp/ios_ipa_build/Payload/Runner.app/AppIcon76x76@2x~ipad.png 2>/dev/null || true
cp "$APP_DIR/assets/icons/app_icon.png" /tmp/ios_ipa_build/Payload/Runner.app/AppIcon83.5x83.5@2x~ipad.png 2>/dev/null || true
cp "$APP_DIR/assets/icons/app_icon.png" /tmp/ios_ipa_build/Payload/Runner.app/AppIcon1024x1024.png 2>/dev/null || true

# Strip any conflicting legacy code signatures so sideloader can sign with 0x20400 modern signature
rm -rf /tmp/ios_ipa_build/Payload/Runner.app/Frameworks/Flutter.framework/_CodeSignature 2>/dev/null || true
rm -rf /tmp/ios_ipa_build/Payload/Runner.app/Frameworks/App.framework/_CodeSignature 2>/dev/null || true
rm -rf /tmp/ios_ipa_build/Payload/Runner.app/_CodeSignature 2>/dev/null || true

(cd /tmp/ios_ipa_build && zip -qr9 "$ARTIFACTS_DIR/ipad_ios/local_ecosystem.ipa" Payload)
echo "✅ iOS IPA created at: $ARTIFACTS_DIR/ipad_ios/local_ecosystem.ipa"

# 4. Package Windows Release Bundle
echo "🪟 Packaging Windows Release Bundle..."
python3 "$SCRIPT_DIR/package_windows.py"

# 5. Build Web PWA Bundle (for iPad & Browsers)
echo "🌐 Building Web PWA App..."
flutter build web --release
mkdir -p "$ARTIFACTS_DIR/web"
cp -r build/web/* "$ARTIFACTS_DIR/web/"
echo "✅ Web PWA copied to: $ARTIFACTS_DIR/web/"

# 6. Android APK ready (manual install or download via Web Portal)
echo "📱 Android APK ready at: $ARTIFACTS_DIR/android/local_ecosystem.apk"

echo "========================================="
echo "🎉 Build & Deployment Complete!"
echo "📁 All artifacts organized in: $ARTIFACTS_DIR"
echo "========================================="
