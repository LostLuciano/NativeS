#!/bin/bash
# Script untuk update Xcode project dengan models

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
XCODE_PROJECT="$PROJECT_ROOT/MusicStemNative/MusicStemNative.xcodeproj"
MODELS_DIR="$PROJECT_ROOT/MusicStemNative/Models"

echo "=========================================="
echo "🎵 MusicStemNative - Xcode Setup"
echo "=========================================="
echo ""

# Check if Xcode project exists
if [ ! -d "$XCODE_PROJECT" ]; then
    echo "❌ Error: Xcode project not found at $XCODE_PROJECT"
    exit 1
fi

echo "✅ Found Xcode project: $XCODE_PROJECT"
echo ""

# Check if models exist
if [ ! -d "$MODELS_DIR" ]; then
    echo "❌ Error: Models directory not found at $MODELS_DIR"
    exit 1
fi

echo "✅ Found models directory: $MODELS_DIR"
echo ""

# List models
echo "📦 Models to add:"
for model in "$MODELS_DIR"/*.mlmodelc; do
    if [ -d "$model" ]; then
        echo "   📦 $(basename "$model")"
    fi
done
echo ""

# Instructions for manual setup
echo "=========================================="
echo "📋 Manual Xcode Setup Instructions"
echo "=========================================="
echo ""
echo "1. Open Xcode project:"
echo "   open '$XCODE_PROJECT'"
echo ""
echo "2. In Xcode:"
echo "   a. Select 'MusicStemNative' target"
echo "   b. Go to Build Phases tab"
echo "   c. Click '+' and select 'New Copy Files Phase'"
echo "   d. Set Destination to 'Resources'"
echo "   e. Drag models from Finder to this phase"
echo ""
echo "3. Verify in Build Settings:"
echo "   a. Search for 'Copy Bundle Resources'"
echo "   b. Verify all models are listed"
echo ""
echo "4. Build and run:"
echo "   xcodebuild -project MusicStemNative.xcodeproj \\"
echo "     -scheme MusicStemNative \\"
echo "     -configuration Debug \\"
echo "     -sdk iphonesimulator \\"
echo "     build"
echo ""
echo "=========================================="
echo "✅ Setup Complete!"
echo "=========================================="
echo ""
