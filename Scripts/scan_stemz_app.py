#!/usr/bin/env python3
"""
Scanner untuk Stemz.app - menghasilkan inventory asset, model, framework, dan audio
Berjalan di Windows untuk scan folder .app
"""

import os
import json
import argparse
from pathlib import Path
from collections import defaultdict
import plistlib

def scan_directory(input_dir, output_dir):
    """Scan Stemz.app dan generate inventory files"""
    
    input_path = Path(input_dir)
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)
    
    # Initialize collectors
    file_tree = []
    assets = []
    models = []
    frameworks = []
    audio_assets = []
    plists = []
    strings_files = []
    legal_flags = []
    
    # File extensions to track
    extensions_map = {
        'models': ['.mlmodelc'],
        'frameworks': ['.framework'],
        'binaries': ['.dylib', '.so'],
        'bundles': ['.bundle'],
        'images': ['.car', '.png', '.jpg', '.jpeg', '.webp', '.pdf', '.svg'],
        'audio': ['.m4a', '.wav', '.caf', '.mp3', '.aac'],
        'config': ['.json', '.plist', '.strings'],
        'metal': ['.metallib']
    }
    
    print(f"[*] Scanning {input_path}...")
    
    # Walk through directory
    for root, dirs, files in os.walk(input_path):
        rel_root = os.path.relpath(root, input_path)
        
        for file in files:
            file_path = os.path.join(root, file)
            rel_path = os.path.relpath(file_path, input_path)
            file_size = os.path.getsize(file_path)
            file_ext = os.path.splitext(file)[1].lower()
            
            # Add to file tree
            file_tree.append({
                'path': rel_path,
                'size': file_size,
                'type': file_ext
            })
            
            # Categorize files
            if file_ext in extensions_map['models']:
                models.append({
                    'name': file,
                    'path': rel_path,
                    'size': file_size,
                    'type': 'CoreML Model',
                    'legal_status': 'PROPRIETARY_REFERENCE_ONLY',
                    'action': 'Copy to Models/ for testing'
                })
                legal_flags.append({
                    'file': rel_path,
                    'type': 'CoreML Model',
                    'flag': 'PROPRIETARY_REFERENCE_ONLY'
                })
            
            elif file_ext in extensions_map['frameworks']:
                frameworks.append({
                    'name': file,
                    'path': rel_path,
                    'size': file_size,
                    'type': 'Framework',
                    'legal_status': 'PROPRIETARY_REFERENCE_ONLY',
                    'action': 'Analyze for reimplementation'
                })
                legal_flags.append({
                    'file': rel_path,
                    'type': 'Framework',
                    'flag': 'PROPRIETARY_REFERENCE_ONLY'
                })
            
            elif file_ext in extensions_map['binaries']:
                frameworks.append({
                    'name': file,
                    'path': rel_path,
                    'size': file_size,
                    'type': 'Binary/Dylib',
                    'legal_status': 'PROPRIETARY_REFERENCE_ONLY',
                    'action': 'Analyze for reimplementation'
                })
            
            elif file_ext in extensions_map['images']:
                assets.append({
                    'name': file,
                    'path': rel_path,
                    'size': file_size,
                    'type': 'Image/Asset',
                    'legal_status': 'PROPRIETARY_REFERENCE_ONLY',
                    'action': 'Create original replacement'
                })
            
            elif file_ext in extensions_map['audio']:
                audio_assets.append({
                    'name': file,
                    'path': rel_path,
                    'size': file_size,
                    'type': 'Audio',
                    'legal_status': 'PROPRIETARY_REFERENCE_ONLY',
                    'action': 'Reference only - create original'
                })
            
            elif file_ext in extensions_map['config']:
                if file_ext == '.plist':
                    plists.append({
                        'name': file,
                        'path': rel_path,
                        'size': file_size,
                        'type': 'Plist Config'
                    })
                elif file_ext == '.strings':
                    strings_files.append({
                        'name': file,
                        'path': rel_path,
                        'size': file_size,
                        'type': 'Strings Localization'
                    })
    
    # Write outputs
    print(f"[+] Writing inventory files to {output_path}...")
    
    # File tree
    with open(output_path / 'file_tree.txt', 'w') as f:
        f.write(f"Total files: {len(file_tree)}\n\n")
        for item in sorted(file_tree, key=lambda x: x['path']):
            f.write(f"{item['path']} ({item['size']} bytes)\n")
    
    # Assets
    with open(output_path / 'assets.json', 'w') as f:
        json.dump(assets, f, indent=2)
    
    # Models
    with open(output_path / 'models.json', 'w') as f:
        json.dump(models, f, indent=2)
    
    # Frameworks
    with open(output_path / 'frameworks.json', 'w') as f:
        json.dump(frameworks, f, indent=2)
    
    # Audio assets
    with open(output_path / 'audio_assets.json', 'w') as f:
        json.dump(audio_assets, f, indent=2)
    
    # Plists
    with open(output_path / 'plists.json', 'w') as f:
        json.dump(plists, f, indent=2)
    
    # Strings
    with open(output_path / 'strings_report.txt', 'w') as f:
        f.write(f"Total .strings files: {len(strings_files)}\n\n")
        for item in strings_files:
            f.write(f"{item['path']}\n")
    
    # Legal flags
    with open(output_path / 'legal_flags.json', 'w') as f:
        json.dump(legal_flags, f, indent=2)
    
    # Summary
    print(f"\n[✓] Scan complete!")
    print(f"    Total files: {len(file_tree)}")
    print(f"    Models found: {len(models)}")
    print(f"    Frameworks found: {len(frameworks)}")
    print(f"    Assets found: {len(assets)}")
    print(f"    Audio files found: {len(audio_assets)}")
    print(f"    Plists found: {len(plists)}")
    print(f"    Strings files found: {len(strings_files)}")

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Scan Stemz.app for inventory')
    parser.add_argument('--input', required=True, help='Path to Stemz.app directory')
    parser.add_argument('--output', required=True, help='Output directory for inventory files')
    
    args = parser.parse_args()
    
    if not os.path.isdir(args.input):
        print(f"[!] Error: Input directory not found: {args.input}")
        exit(1)
    
    scan_directory(args.input, args.output)
