#!/usr/bin/env python3
"""
Copy Chord and Beat detection models from Stemz.app to MusicStemNative project.

This script copies:
- Chordcrnn.mlmodelc (Chord detection)
- convtcn20_2048_fp16.mlmodelc (Beat detection)

From: Stemz.app/Frameworks/iOSSourceSeparationPlayerAudioEngine.framework/
To: MusicStemNative/Models/
"""

import os
import shutil
import sys
from pathlib import Path

def copy_models(stemz_app_path, project_path):
    """Copy chord and beat models from Stemz.app to project."""
    
    # Define source and destination paths
    framework_path = os.path.join(
        stemz_app_path,
        "Frameworks",
        "iOSSourceSeparationPlayerAudioEngine.framework"
    )
    
    models_dest = os.path.join(project_path, "MusicStemNative", "Models")
    
    # Models to copy
    models = [
        "Chordcrnn.mlmodelc",
        "convtcn20_2048_fp16.mlmodelc"
    ]
    
    print("=" * 80)
    print("COPYING CHORD & BEAT DETECTION MODELS")
    print("=" * 80)
    print()
    
    # Verify source exists
    if not os.path.exists(framework_path):
        print(f"❌ ERROR: Framework path not found: {framework_path}")
        return False
    
    print(f"✓ Source framework found: {framework_path}")
    print()
    
    # Verify destination exists
    if not os.path.exists(models_dest):
        print(f"❌ ERROR: Destination path not found: {models_dest}")
        return False
    
    print(f"✓ Destination folder found: {models_dest}")
    print()
    
    # Copy each model
    all_success = True
    for model in models:
        src = os.path.join(framework_path, model)
        dst = os.path.join(models_dest, model)
        
        if not os.path.exists(src):
            print(f"❌ Model not found: {model}")
            all_success = False
            continue
        
        # Check if already exists
        if os.path.exists(dst):
            print(f"⚠️  Model already exists: {model}")
            print(f"   Removing old version...")
            shutil.rmtree(dst)
        
        print(f"📦 Copying {model}...")
        try:
            shutil.copytree(src, dst)
            
            # Get size
            size_mb = sum(
                os.path.getsize(os.path.join(dirpath, filename))
                for dirpath, dirnames, filenames in os.walk(dst)
                for filename in filenames
            ) / (1024 * 1024)
            
            print(f"   ✓ Success ({size_mb:.2f} MB)")
            print()
        except Exception as e:
            print(f"   ❌ Failed: {e}")
            all_success = False
            print()
    
    return all_success

def main():
    """Main entry point."""
    
    # Get paths from arguments or use defaults
    if len(sys.argv) > 1:
        stemz_app_path = sys.argv[1]
    else:
        stemz_app_path = r"D:\IPA Project\Stemz.app"
    
    if len(sys.argv) > 2:
        project_path = sys.argv[2]
    else:
        project_path = r"D:\IPA Project\MusikX"
    
    print()
    print("CHORD & BEAT MODEL COPY UTILITY")
    print("=" * 80)
    print()
    print(f"Stemz.app path: {stemz_app_path}")
    print(f"Project path:   {project_path}")
    print()
    
    # Verify paths exist
    if not os.path.exists(stemz_app_path):
        print(f"❌ ERROR: Stemz.app not found at: {stemz_app_path}")
        sys.exit(1)
    
    if not os.path.exists(project_path):
        print(f"❌ ERROR: Project not found at: {project_path}")
        sys.exit(1)
    
    # Copy models
    success = copy_models(stemz_app_path, project_path)
    
    print("=" * 80)
    if success:
        print("✅ ALL MODELS COPIED SUCCESSFULLY!")
        print()
        print("Next steps:")
        print("1. Open Xcode project")
        print("2. Add models to 'Copy Bundle Resources' in Build Phases")
        print("3. Update CoreMLModelManager.swift to load chord/beat models")
        print("4. Create ChordDetector.swift and BeatDetector.swift classes")
        print()
    else:
        print("❌ SOME MODELS FAILED TO COPY")
        print()
        print("Troubleshooting:")
        print("1. Verify Stemz.app path is correct")
        print("2. Check that models exist in framework")
        print("3. Ensure write permissions to Models folder")
        print()
    
    print("=" * 80)
    print()
    
    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(main())
