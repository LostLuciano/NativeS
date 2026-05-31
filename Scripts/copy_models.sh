#!/bin/bash
# Xcode Build Phase Script - Copy Models to Bundle

MODELS_SOURCE="${SRCROOT}/MusicStemNative/Models"
MODELS_DEST="${BUILT_PRODUCTS_DIR}/${EXECUTABLE_FOLDER_PATH}/Models"

# Create destination directory
mkdir -p "$MODELS_DEST"

# Copy all models
for model in "$MODELS_SOURCE"/*.mlmodelc; do
    if [ -d "$model" ]; then
        cp -r "$model" "$MODELS_DEST/"
        echo "[OK] Copied: $(basename "$model")"
    fi
done

echo "[OK] Models copied to bundle"
