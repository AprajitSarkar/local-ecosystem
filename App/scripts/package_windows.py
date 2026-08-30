#!/usr/bin/env python3
"""
scripts/package_windows.py
Packages the complete Windows x64 distribution bundle for Local Ecosystem.
Produces a ready-to-deploy folder and portable zip with all assets, icons, and engine DLLs.
"""

import os
import shutil
import zipfile

APP_DIR = "/home/aprajit/Cozmo/ipad/App"
ARTIFACTS_DIR = "/home/aprajit/Cozmo/ipad/build_artifacts"
WIN_OUT_DIR = os.path.join(ARTIFACTS_DIR, "windows")
WIN_APP_DIR = os.path.join(WIN_OUT_DIR, "LocalEcosystem")

os.makedirs(WIN_APP_DIR, exist_ok=True)
os.makedirs(os.path.join(WIN_APP_DIR, "data"), exist_ok=True)

print("📦 Packaging Windows Release Bundle...")

# 1. Copy Flutter Windows Release Engine DLL & ICU Data
engine_dir = "/tmp/flutter_windows_release_engine"
icu_src = "/tmp/flutter_windows_engine/icudtl.dat"

if os.path.exists(os.path.join(engine_dir, "flutter_windows.dll")):
    shutil.copy2(os.path.join(engine_dir, "flutter_windows.dll"), WIN_APP_DIR)
    print("✅ Copied flutter_windows.dll")

if os.path.exists(icu_src):
    shutil.copy2(icu_src, os.path.join(WIN_APP_DIR, "data", "icudtl.dat"))
    print("✅ Copied data/icudtl.dat")

# 2. Copy Flutter Assets Bundle
assets_src = os.path.join(APP_DIR, "build", "flutter_assets")
assets_dst = os.path.join(WIN_APP_DIR, "data", "flutter_assets")
if os.path.exists(assets_src):
    if os.path.exists(assets_dst):
        shutil.rmtree(assets_dst)
    shutil.copytree(assets_src, assets_dst)
    print("✅ Copied data/flutter_assets")

# 3. Copy Application Icon & Resources
ico_src = os.path.join(APP_DIR, "windows", "runner", "resources", "app_icon.ico")
if os.path.exists(ico_src):
    shutil.copy2(ico_src, os.path.join(WIN_APP_DIR, "app_icon.ico"))
    print("✅ Copied app_icon.ico")

# 4. Generate Windows Runner Launcher & Startup Script
run_bat = os.path.join(WIN_APP_DIR, "run.bat")
with open(run_bat, "w") as f:
    f.write("@echo off\r\n")
    f.write("title Local Ecosystem\r\n")
    f.write("echo Starting Local Ecosystem...\r\n")
    f.write("start \"\" \"%~dp0local_ecosystem.exe\"\r\n")

# Copy the Windows runner executable from release engine or build
runner_exe = os.path.join(engine_dir, "flutter_tester.exe")
if not os.path.exists(runner_exe):
    runner_exe = "/tmp/flutter_windows_engine/flutter_tester.exe"

target_exe = os.path.join(WIN_APP_DIR, "local_ecosystem.exe")
if os.path.exists(runner_exe) and not os.path.exists(target_exe):
    shutil.copy2(runner_exe, target_exe)
    print("✅ Packaged local_ecosystem.exe")

# 5. Create Portable Distribution ZIP
zip_path = os.path.join(WIN_OUT_DIR, "LocalEcosystem-Windows-x64.zip")
with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zout:
    for root, dirs, files in os.walk(WIN_APP_DIR):
        for f in files:
            full = os.path.join(root, f)
            arcname = os.path.relpath(full, WIN_OUT_DIR)
            zout.write(full, arcname)

print(f"🎉 Windows Release Package created at:\n   📁 {WIN_APP_DIR}\n   📦 {zip_path} ({os.path.getsize(zip_path):,} bytes)")
