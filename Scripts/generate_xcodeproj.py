import os
import sys
import uuid

def generate_id(name):
    # Deterministic UUID generation based on name to keep IDs stable across runs
    namespace = uuid.UUID('12345678-1234-5678-1234-567812345678')
    h = uuid.uuid5(namespace, name).hex
    return h[:24].upper()

def create_xcodeproj(project_root):
    music_stem_native_dir = os.path.join(project_root, "MusicStemNative")
    xcodeproj_dir = os.path.join(music_stem_native_dir, "MusicStemNative.xcodeproj")
    os.makedirs(xcodeproj_dir, exist_ok=True)
    
    pbxproj_path = os.path.join(xcodeproj_dir, "project.pbxproj")
    
    # Collect all files
    all_files = []
    for root, dirs, files in os.walk(music_stem_native_dir):
        # Exclude directories
        if ".xcodeproj" in root or "build" in root or "DerivedData" in root:
            continue
        for file in files:
            full_path = os.path.join(root, file)
            rel_path = os.path.relpath(full_path, music_stem_native_dir)
            all_files.append(rel_path.replace(os.sep, '/'))

    # Filter files by target
    dsp_files = []
    app_files = []
    test_files = []
    resources = []
    headers = []
    
    # We also need to add the models (.mlmodelc directories) as resource references.
    # Since os.walk lists files inside directories, we want to treat the .mlmodelc directories themselves
    # as single folder references in the project.
    models_added = set()
    
    for file in all_files:
        if "DSPFramework/" in file:
            if file.endswith((".cpp", ".mm")):
                dsp_files.append(file)
            elif file.endswith((".h", ".hpp", ".modulemap")):
                headers.append(file)
        elif "Models/" in file:
            # Get the path to the .mlmodelc folder
            parts = file.split('/')
            mlmodelc_path = ""
            for part in parts:
                if part.endswith(".mlmodelc"):
                    mlmodelc_path = mlmodelc_path + part if mlmodelc_path == "" else mlmodelc_path + "/" + part
                    break
                else:
                    mlmodelc_path = mlmodelc_path + part if mlmodelc_path == "" else mlmodelc_path + "/" + part
            
            # Add once
            if mlmodelc_path not in models_added:
                models_added.add(mlmodelc_path)
                resources.append(mlmodelc_path)
        elif file.endswith(".swift"):
            if "Tests/" in file:
                test_files.append(file)
            else:
                app_files.append(file)
        elif file.endswith("Info.plist"):
            # Info.plist doesn't go to compile sources, it's referenced in build settings
            pass
        else:
            # General assets/config
            resources.append(file)
            
    # Print statistics
    print(f"Collected {len(app_files)} App source files")
    print(f"Collected {len(test_files)} Test source files")
    print(f"Collected {len(dsp_files)} DSP source files")
    print(f"Collected {len(headers)} header files")
    print(f"Collected {len(resources)} resources")

    # Generate UUIDs
    proj_id = generate_id("PROJECT")
    app_target_id = generate_id("TARGET_APP")
    dsp_target_id = generate_id("TARGET_DSP")
    
    app_prod_id = generate_id("PROD_APP")
    dsp_prod_id = generate_id("PROD_DSP")
    
    main_group_id = generate_id("GROUP_MAIN")
    sources_group_id = generate_id("GROUP_SOURCES")
    products_group_id = generate_id("GROUP_PRODUCTS")
    
    # Group IDs
    group_ids = {}
    for g in ["App", "AudioEngine", "DSPFramework", "DSPFramework/include", "DSPFramework/src", "ML", "Managers", "Models", "Storage", "Tests", "UI", "UI/Components"]:
        group_ids[g] = generate_id(f"GROUP_{g}")
        
    # Build configurations
    app_cfg_list_id = generate_id("CFGLIST_APP")
    dsp_cfg_list_id = generate_id("CFGLIST_DSP")
    proj_cfg_list_id = generate_id("CFGLIST_PROJ")
    
    app_debug_cfg_id = generate_id("CFG_APP_DEBUG")
    app_release_cfg_id = generate_id("CFG_APP_RELEASE")
    dsp_debug_cfg_id = generate_id("CFG_DSP_DEBUG")
    dsp_release_cfg_id = generate_id("CFG_DSP_RELEASE")
    proj_debug_cfg_id = generate_id("CFG_PROJ_DEBUG")
    proj_release_cfg_id = generate_id("CFG_PROJ_RELEASE")
    
    # Build Phases
    app_sources_phase_id = generate_id("PHASE_APP_SOURCES")
    app_frameworks_phase_id = generate_id("PHASE_APP_FRAMEWORKS")
    app_resources_phase_id = generate_id("PHASE_APP_RESOURCES")
    
    dsp_sources_phase_id = generate_id("PHASE_DSP_SOURCES")
    dsp_headers_phase_id = generate_id("PHASE_DSP_HEADERS")
    dsp_frameworks_phase_id = generate_id("PHASE_DSP_FRAMEWORKS")
    
    # Target Dependency
    target_dep_id = generate_id("TARGET_DEP")
    container_portal_id = generate_id("CONTAINER_PORTAL")
    
    # File references & Build files
    file_refs = {}
    build_files = {}
    
    system_frameworks = ["Accelerate", "AVFoundation", "AudioToolbox", "CoreML", "Foundation", "CoreGraphics"]
    for fw in system_frameworks:
        fw_name = f"{fw}.framework"
        file_refs[fw_name] = (generate_id(f"REF_SYSTEM_FW_{fw}"), "wrapper.framework", "SDKROOT", f"System/Library/Frameworks/{fw_name}")
        
    dsp_fw_build_files = {f"{fw}.framework": generate_id(f"BF_DSP_{fw}") for fw in system_frameworks}
    app_fw_build_files = {f"{fw}.framework": generate_id(f"BF_APP_{fw}") for fw in system_frameworks}
    
    # Register products
    file_refs["MusicStemNative.app"] = (generate_id("REF_PROD_APP"), "wrapper.application", "BUILT_PRODUCTS_DIR", "MusicStemNative.app")
    file_refs["DSPFramework.framework"] = (generate_id("REF_PROD_DSP"), "wrapper.framework", "BUILT_PRODUCTS_DIR", "DSPFramework.framework")
    
    for f in app_files + dsp_files + headers + resources + test_files + ["Info.plist"]:
        ref_id = generate_id(f"REF_{f}")
        bf_id = generate_id(f"BF_{f}")
        
        # Determine file type
        ext = os.path.splitext(f)[1].lower()
        if ext == ".swift":
            ftype = "sourcecode.swift"
        elif ext == ".cpp":
            ftype = "sourcecode.cpp.cpp"
        elif ext == ".mm":
            ftype = "sourcecode.cpp.objcpp"
        elif ext == ".h":
            ftype = "sourcecode.c.h"
        elif ext == ".hpp":
            ftype = "sourcecode.cpp.h"
        elif ext == ".modulemap":
            ftype = "sourcecode.module-map"
        elif ext == ".mlmodelc":
            ftype = "wrapper.image-bundle"
        elif ext == ".plist":
            ftype = "text.plist.xml"
        else:
            ftype = "text"
            
        file_refs[f] = (ref_id, ftype, "SOURCE_ROOT", f)
        build_files[f] = (bf_id, ref_id)

    # Start writing project.pbxproj
    with open(pbxproj_path, "w", encoding="utf-8") as f:
        f.write("// !$*UTF8*$!\n")
        f.write("{\n")
        f.write("\tarchiveVersion = 1;\n")
        f.write("\tclasses = {\n")
        f.write("\t};\n")
        f.write("\tobjectVersion = 56;\n")
        f.write("\tobjects = {\n\n")
        
        # 1. PBXBuildFile Section
        f.write("/* Begin PBXBuildFile section */\n")
        # DSP framework dependency in app target
        f.write(f"\t\t{generate_id('BF_DSP_DEP')} /* DSPFramework.framework in Frameworks */ = {{isa = PBXBuildFile; fileRef = {file_refs['DSPFramework.framework'][0]} /* DSPFramework.framework */; }};\n")
        # System frameworks for DSPFramework
        for fw_name, bf_id in dsp_fw_build_files.items():
            f.write(f"\t\t{bf_id} /* {fw_name} in Frameworks */ = {{isa = PBXBuildFile; fileRef = {file_refs[fw_name][0]} /* {fw_name} */; }};\n")
        # System frameworks for App
        for fw_name, bf_id in app_fw_build_files.items():
            f.write(f"\t\t{bf_id} /* {fw_name} in Frameworks */ = {{isa = PBXBuildFile; fileRef = {file_refs[fw_name][0]} /* {fw_name} */; }};\n")
        # DSPFramework.framework in Embed Frameworks
        f.write(f"\t\t{generate_id('BF_DSP_EMBED')} /* DSPFramework.framework in Embed Frameworks */ = {{isa = PBXBuildFile; fileRef = {file_refs['DSPFramework.framework'][0]} /* DSPFramework.framework */; settings = {{ATTRIBUTES = (CodeSignOnCopy, RemoveHeadersOnCopy); }}; }};\n")
        
        for file, (bf_id, ref_id) in build_files.items():
            if file in app_files or file in dsp_files or file in resources:
                f.write(f"\t\t{bf_id} /* {os.path.basename(file)} in Sources/Resources */ = {{isa = PBXBuildFile; fileRef = {ref_id} /* {os.path.basename(file)} */; }};\n")
            elif file in headers:
                # Only DSPBridge.h should be a Public header. Others should be Project headers.
                if os.path.basename(file) == "DSPBridge.h":
                    f.write(f"\t\t{bf_id} /* {os.path.basename(file)} in Headers */ = {{isa = PBXBuildFile; fileRef = {ref_id} /* {os.path.basename(file)} */; settings = {{ATTRIBUTES = (Public, ); }}; }};\n")
                else:
                    f.write(f"\t\t{bf_id} /* {os.path.basename(file)} in Headers */ = {{isa = PBXBuildFile; fileRef = {ref_id} /* {os.path.basename(file)} */; }};\n")
        f.write("/* End PBXBuildFile section */\n\n")
        
        # 2. PBXContainerItemProxy Section
        f.write("/* Begin PBXContainerItemProxy section */\n")
        f.write(f"\t\t{container_portal_id} /* PBXContainerItemProxy */ = {{\n")
        f.write(f"\t\t\tisa = PBXContainerItemProxy;\n")
        f.write(f"\t\t\tcontainerPortal = {proj_id} /* Project object */;\n")
        f.write(f"\t\t\tproxyType = 1;\n")
        f.write(f"\t\t\tremoteGlobalIDString = {dsp_target_id} /* DSPFramework */;\n")
        f.write(f"\t\t\tremoteInfo = DSPFramework;\n")
        f.write(f"\t\t}};\n")
        f.write("/* End PBXContainerItemProxy section */\n\n")
        
        # 3. PBXFileReference Section
        f.write("/* Begin PBXFileReference section */\n")
        for file, (ref_id, ftype, source_tree, path) in file_refs.items():
            f.write(f"\t\t{ref_id} /* {os.path.basename(file)} */ = {{isa = PBXFileReference; lastKnownFileType = {ftype}; name = \"{os.path.basename(file)}\"; path = \"{path}\"; sourceTree = {source_tree}; }};\n")
        f.write("/* End PBXFileReference section */\n\n")
        
        # 4. PBXFrameworksBuildPhase Section
        f.write("/* Begin PBXFrameworksBuildPhase section */\n")
        f.write(f"\t\t{app_frameworks_phase_id} /* Frameworks */ = {{\n")
        f.write("\t\t\tisa = PBXFrameworksBuildPhase;\n")
        f.write("\t\t\tbuildActionMask = 2147483647;\n")
        f.write("\t\t\tfiles = (\n")
        f.write(f"\t\t\t\t{generate_id('BF_DSP_DEP')} /* DSPFramework.framework in Frameworks */,\n")
        f.write("\t\t\t);\n")
        f.write("\t\t\trunOnlyForDeploymentPostprocessing = 0;\n")
        f.write("\t\t};\n")
        
        f.write(f"\t\t{dsp_frameworks_phase_id} /* Frameworks */ = {{\n")
        f.write("\t\t\tisa = PBXFrameworksBuildPhase;\n")
        f.write("\t\t\tbuildActionMask = 2147483647;\n")
        f.write("\t\t\tfiles = (\n")
        f.write("\t\t\t);\n")
        f.write("\t\t\trunOnlyForDeploymentPostprocessing = 0;\n")
        f.write("\t\t};\n")
        f.write("/* End PBXFrameworksBuildPhase section */\n\n")
        
        # 5. PBXGroup Section
        f.write("/* Begin PBXGroup section */\n")
        
        # Main Group
        f.write(f"\t\t{main_group_id} = {{\n")
        f.write("\t\t\tisa = PBXGroup;\n")
        f.write("\t\t\tchildren = (\n")
        f.write(f"\t\t\t\t{sources_group_id} /* MusicStemNative */,\n")
        f.write(f"\t\t\t\t{products_group_id} /* Products */,\n")
        f.write("\t\t\t);\n")
        f.write("\t\t\tsourceTree = \"<group>\";\n")
        f.write("\t\t};\n")
        
        # Products Group
        f.write(f"\t\t{products_group_id} /* Products */ = {{\n")
        f.write("\t\t\tisa = PBXGroup;\n")
        f.write("\t\t\tchildren = (\n")
        f.write(f"\t\t\t\t{file_refs['MusicStemNative.app'][0]} /* MusicStemNative.app */,\n")
        f.write(f"\t\t\t\t{file_refs['DSPFramework.framework'][0]} /* DSPFramework.framework */,\n")
        f.write("\t\t\t);\n")
        f.write("\t\t\tname = Products;\n")
        f.write("\t\t\tsourceTree = \"<group>\";\n")
        f.write("\t\t};\n")
        
        # Sources Group (MusicStemNative root group)
        f.write(f"\t\t{sources_group_id} /* MusicStemNative */ = {{\n")
        f.write("\t\t\tisa = PBXGroup;\n")
        f.write("\t\t\tchildren = (\n")
        f.write(f"\t\t\t\t{group_ids['App']} /* App */,\n")
        f.write(f"\t\t\t\t{group_ids['AudioEngine']} /* AudioEngine */,\n")
        f.write(f"\t\t\t\t{group_ids['DSPFramework']} /* DSPFramework */,\n")
        f.write(f"\t\t\t\t{group_ids['ML']} /* ML */,\n")
        f.write(f"\t\t\t\t{group_ids['Managers']} /* Managers */,\n")
        f.write(f"\t\t\t\t{group_ids['Models']} /* Models */,\n")
        f.write(f"\t\t\t\t{group_ids['Storage']} /* Storage */,\n")
        f.write(f"\t\t\t\t{group_ids['Tests']} /* Tests */,\n")
        f.write(f"\t\t\t\t{group_ids['UI']} /* UI */,\n")
        f.write(f"\t\t\t\t{file_refs['Info.plist'][0]} /* Info.plist */,\n")
        f.write("\t\t\t);\n")
        f.write("\t\t\tname = MusicStemNative;\n")
        f.write("\t\t\tsourceTree = \"<group>\";\n")
        f.write("\t\t};\n")
        
        # Subgroups
        subgroups = {
            "App": [f for f in app_files + headers + resources if "App/" in f],
            "AudioEngine": [f for f in app_files + headers + resources if "AudioEngine/" in f],
            "DSPFramework": [group_ids["DSPFramework/include"], group_ids["DSPFramework/src"], "DSPFramework/module.modulemap"],
            "DSPFramework/include": [f for f in headers if "DSPFramework/include/" in f],
            "DSPFramework/src": [f for f in dsp_files + headers if "DSPFramework/src/" in f],
            "ML": [f for f in app_files + headers + resources if "ML/" in f],
            "Managers": [f for f in app_files + headers + resources if "Managers/" in f],
            "Models": [f for f in resources if "Models/" in f],
            "Storage": [f for f in app_files + headers + resources if "Storage/" in f],
            "Tests": [f for f in test_files if "Tests/" in f],
            "UI": [group_ids["UI/Components"]] + [f for f in app_files + headers + resources if "UI/" in f and "UI/Components/" not in f],
            "UI/Components": [f for f in app_files + headers + resources if "UI/Components/" in f]
        }
        
        for name, items in subgroups.items():
            f.write(f"\t\t{group_ids[name]} /* {name} */ = {{\n")
            f.write("\t\t\tisa = PBXGroup;\n")
            f.write("\t\t\tchildren = (\n")
            for item in items:
                if item.startswith("GROUP_") or item in group_ids.values():
                    # It's a subgroup ID
                    f.write(f"\t\t\t\t{item} /* Subgroup */,\n")
                elif item in file_refs:
                    f.write(f"\t\t\t\t{file_refs[item][0]} /* {os.path.basename(item)} */,\n")
            f.write("\t\t\t);\n")
            f.write(f"\t\t\tname = \"{os.path.basename(name)}\";\n")
            f.write("\t\t\tsourceTree = \"<group>\";\n")
            f.write("\t\t};\n")
            
        f.write("/* End PBXGroup section */\n\n")
        
        # 6. PBXHeadersBuildPhase Section
        f.write("/* Begin PBXHeadersBuildPhase section */\n")
        f.write(f"\t\t{dsp_headers_phase_id} /* Headers */ = {{\n")
        f.write("\t\t\tisa = PBXHeadersBuildPhase;\n")
        f.write("\t\t\tbuildActionMask = 2147483647;\n")
        f.write("\t\t\tfiles = (\n")
        for h in headers:
            f.write(f"\t\t\t\t{build_files[h][0]} /* {os.path.basename(h)} in Headers */,\n")
        f.write("\t\t\t);\n")
        f.write("\t\t\trunOnlyForDeploymentPostprocessing = 0;\n")
        f.write("\t\t};\n")
        f.write("/* End PBXHeadersBuildPhase section */\n\n")
        
        # 7. PBXNativeTarget Section
        f.write("/* Begin PBXNativeTarget section */\n")
        # App target
        f.write(f"\t\t{app_target_id} /* MusicStemNative */ = {{\n")
        f.write("\t\t\tisa = PBXNativeTarget;\n")
        f.write(f"\t\t\tbuildConfigurationList = {app_cfg_list_id} /* Build configuration list for PBXNativeTarget \"MusicStemNative\" */;\n")
        f.write("\t\t\tbuildPhases = (\n")
        f.write(f"\t\t\t\t{app_sources_phase_id} /* Sources */,\n")
        f.write(f"\t\t\t\t{app_frameworks_phase_id} /* Frameworks */,\n")
        f.write(f"\t\t\t\t{app_resources_phase_id} /* Resources */,\n")
        f.write("\t\t\t);\n")
        f.write("\t\t\tbuildRules = (\n")
        f.write("\t\t\t);\n")
        f.write("\t\t\tdependencies = (\n")
        f.write(f"\t\t\t\t{target_dep_id} /* PBXTargetDependency */,\n")
        f.write("\t\t\t);\n")
        f.write("\t\t\tname = MusicStemNative;\n")
        f.write("\t\t\tproductName = MusicStemNative;\n")
        f.write(f"\t\t\tproductReference = {file_refs['MusicStemNative.app'][0]} /* MusicStemNative.app */;\n")
        f.write("\t\t\tproductType = \"com.apple.product-type.application\";\n")
        f.write("\t\t};\n")
        
        # DSP framework target
        f.write(f"\t\t{dsp_target_id} /* DSPFramework */ = {{\n")
        f.write("\t\t\tisa = PBXNativeTarget;\n")
        f.write(f"\t\t\tbuildConfigurationList = {dsp_cfg_list_id} /* Build configuration list for PBXNativeTarget \"DSPFramework\" */;\n")
        f.write("\t\t\tbuildPhases = (\n")
        f.write(f"\t\t\t\t{dsp_sources_phase_id} /* Sources */,\n")
        f.write(f"\t\t\t\t{dsp_headers_phase_id} /* Headers */,\n")
        f.write(f"\t\t\t\t{dsp_frameworks_phase_id} /* Frameworks */,\n")
        f.write("\t\t\t);\n")
        f.write("\t\t\tbuildRules = (\n")
        f.write("\t\t\t);\n")
        f.write("\t\t\tdependencies = (\n")
        f.write("\t\t\t);\n")
        f.write("\t\t\tname = DSPFramework;\n")
        f.write("\t\t\tproductName = DSPFramework;\n")
        f.write(f"\t\t\tproductReference = {file_refs['DSPFramework.framework'][0]} /* DSPFramework.framework */;\n")
        f.write("\t\t\tproductType = \"com.apple.product-type.framework\";\n")
        f.write("\t\t};\n")
        f.write("/* End PBXNativeTarget section */\n\n")
        
        # 8. PBXProject Section
        f.write("/* Begin PBXProject section */\n")
        f.write(f"\t\t{proj_id} /* Project object */ = {{\n")
        f.write("\t\t\tisa = PBXProject;\n")
        f.write("\t\t\tattributes = {\n")
        f.write("\t\t\t\tLastSwiftUpdateCheck = 1500;\n")
        f.write("\t\t\t\tTargetAttributes = {\n")
        f.write(f"\t\t\t\t\t{app_target_id} = {{\n")
        f.write("\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;\n")
        f.write("\t\t\t\t\t};\n")
        f.write(f"\t\t\t\t\t{dsp_target_id} = {{\n")
        f.write("\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;\n")
        f.write("\t\t\t\t\t};\n")
        f.write("\t\t\t\t};\n")
        f.write("\t\t\t};\n")
        f.write(f"\t\t\tbuildConfigurationList = {proj_cfg_list_id} /* Build configuration list for PBXProject \"MusicStemNative\" */;\n")
        f.write("\t\t\tcompatibilityVersion = \"Xcode 14.0\";\n")
        f.write("\t\t\tdevelopmentRegion = en;\n")
        f.write("\t\t\thasScannedForEncodings = 0;\n")
        f.write("\t\t\tknownRegions = (\n")
        f.write("\t\t\t\ten,\n")
        f.write("\t\t\t\tBase,\n")
        f.write("\t\t\t);\n")
        f.write(f"\t\t\tmainGroup = {main_group_id};\n")
        f.write(f"\t\t\tproductRefGroup = {products_group_id} /* Products */;\n")
        f.write("\t\t\tprojectDirPath = \"\";\n")
        f.write("\t\t\tprojectRoot = \"\";\n")
        f.write("\t\t\ttargets = (\n")
        f.write(f"\t\t\t\t{dsp_target_id} /* DSPFramework */,\n")
        f.write(f"\t\t\t\t{app_target_id} /* MusicStemNative */,\n")
        f.write("\t\t\t);\n")
        f.write("\t\t};\n")
        f.write("/* End PBXProject section */\n\n")
        
        # 9. PBXResourcesBuildPhase Section
        f.write("/* Begin PBXResourcesBuildPhase section */\n")
        f.write(f"\t\t{app_resources_phase_id} /* Resources */ = {{\n")
        f.write("\t\t\tisa = PBXResourcesBuildPhase;\n")
        f.write("\t\t\tbuildActionMask = 2147483647;\n")
        f.write("\t\t\tfiles = (\n")
        for r in resources:
            f.write(f"\t\t\t\t{build_files[r][0]} /* {os.path.basename(r)} in Resources */,\n")
        f.write("\t\t\t);\n")
        f.write("\t\t\trunOnlyForDeploymentPostprocessing = 0;\n")
        f.write("\t\t};\n")
        f.write("/* End PBXResourcesBuildPhase section */\n\n")
        
        # 10. PBXSourcesBuildPhase Section
        f.write("/* Begin PBXSourcesBuildPhase section */\n")
        # App sources
        f.write(f"\t\t{app_sources_phase_id} /* Sources */ = {{\n")
        f.write("\t\t\tisa = PBXSourcesBuildPhase;\n")
        f.write("\t\t\tbuildActionMask = 2147483647;\n")
        f.write("\t\t\tfiles = (\n")
        for file in app_files:
            f.write(f"\t\t\t\t{build_files[file][0]} /* {os.path.basename(file)} in Sources */,\n")
        f.write("\t\t\t);\n")
        f.write("\t\t\trunOnlyForDeploymentPostprocessing = 0;\n")
        f.write("\t\t};\n")
        
        # DSP sources
        f.write(f"\t\t{dsp_sources_phase_id} /* Sources */ = {{\n")
        f.write("\t\t\tisa = PBXSourcesBuildPhase;\n")
        f.write("\t\t\tbuildActionMask = 2147483647;\n")
        f.write("\t\t\tfiles = (\n")
        for file in dsp_files:
            f.write(f"\t\t\t\t{build_files[file][0]} /* {os.path.basename(file)} in Sources */,\n")
        f.write("\t\t\t);\n")
        f.write("\t\t\trunOnlyForDeploymentPostprocessing = 0;\n")
        f.write("\t\t};\n")
        f.write("/* End PBXSourcesBuildPhase section */\n\n")
        
        # 11. PBXTargetDependency Section
        f.write("/* Begin PBXTargetDependency section */\n")
        f.write(f"\t\t{target_dep_id} /* PBXTargetDependency */ = {{\n")
        f.write("\t\t\tisa = PBXTargetDependency;\n")
        f.write(f"\t\t\ttarget = {dsp_target_id} /* DSPFramework */;\n")
        f.write(f"\t\t\ttargetProxy = {container_portal_id} /* PBXContainerItemProxy */;\n")
        f.write("\t\t};\n")
        f.write("/* End PBXTargetDependency section */\n\n")
        
        # 12. XCBuildConfiguration Section
        f.write("/* Begin XCBuildConfiguration section */\n")
        # Project level configurations
        f.write(f"\t\t{proj_debug_cfg_id} /* Debug */ = {{\n")
        f.write("\t\t\tisa = XCBuildConfiguration;\n")
        f.write("\t\t\tbuildSettings = {\n")
        f.write("\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;\n")
        f.write("\t\t\t\tCLANG_ANALYZER_NONNULL = YES;\n")
        f.write("\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = \"gnu++17\";\n")
        f.write("\t\t\t\tCLANG_ENABLE_MODULES = YES;\n")
        f.write("\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;\n")
        f.write("\t\t\t\tCOPY_PHASE_STRIP = NO;\n")
        f.write("\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;\n")
        f.write("\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;\n")
        f.write("\t\t\t\tENABLE_TESTABILITY = YES;\n")
        f.write("\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu11;\n")
        f.write("\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;\n")
        f.write("\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;\n")
        f.write("\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = (\n")
        f.write("\t\t\t\t\t\"DEBUG=1\",\n")
        f.write("\t\t\t\t\t\"$(inherited)\",\n")
        f.write("\t\t\t\t);\n")
        f.write("\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;\n")
        f.write("\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;\n")
        f.write("\t\t\t\tONLY_ACTIVE_ARCH = YES;\n")
        f.write("\t\t\t\tSDKROOT = iphoneos;\n")
        f.write("\t\t\t};\n")
        f.write("\t\t\tname = Debug;\n")
        f.write("\t\t};\n")
        
        f.write(f"\t\t{proj_release_cfg_id} /* Release */ = {{\n")
        f.write("\t\t\tisa = XCBuildConfiguration;\n")
        f.write("\t\t\tbuildSettings = {\n")
        f.write("\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;\n")
        f.write("\t\t\t\tCLANG_ANALYZER_NONNULL = YES;\n")
        f.write("\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = \"gnu++17\";\n")
        f.write("\t\t\t\tCLANG_ENABLE_MODULES = YES;\n")
        f.write("\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;\n")
        f.write("\t\t\t\tCOPY_PHASE_STRIP = YES;\n")
        f.write("\t\t\t\tDEBUG_INFORMATION_FORMAT = \"dwarf-with-dsym\";\n")
        f.write("\t\t\t\tENABLE_NS_ASSERTIONS = NO;\n")
        f.write("\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;\n")
        f.write("\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu11;\n")
        f.write("\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;\n")
        f.write("\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;\n")
        f.write("\t\t\t\tSDKROOT = iphoneos;\n")
        f.write("\t\t\t\tVALIDATE_PRODUCT = YES;\n")
        f.write("\t\t\t};\n")
        f.write("\t\t\tname = Release;\n")
        f.write("\t\t};\n")
        
        # DSP framework configurations
        f.write(f"\t\t{dsp_debug_cfg_id} /* Debug */ = {{\n")
        f.write("\t\t\tisa = XCBuildConfiguration;\n")
        f.write("\t\t\tbuildSettings = {\n")
        f.write("\t\t\t\tCLANG_ENABLE_MODULES = YES;\n")
        f.write("\t\t\t\tDEFINES_MODULE = YES;\n")
        f.write("\t\t\t\tDYLIB_COMPATIBILITY_VERSION = 1;\n")
        f.write("\t\t\t\tDYLIB_CURRENT_VERSION = 1;\n")
        f.write("\t\t\t\tDYLIB_INSTALL_NAME_BASE = \"@rpath\";\n")
        f.write("\t\t\t\tHEADER_SEARCH_PATHS = (\n")
        f.write("\t\t\t\t\t\"$(inherited)\",\n")
        f.write("\t\t\t\t\t\"$(PROJECT_DIR)/DSPFramework/include\",\n")
        f.write("\t\t\t\t);\n")
        f.write("\t\t\t\tINFOPLIST_FILE = \"\";\n")
        f.write("\t\t\t\tINSTALL_PATH = \"$(LOCAL_LIBRARY_DIR)/Frameworks\";\n")
        f.write("\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (\n")
        f.write("\t\t\t\t\t\"$(inherited)\",\n")
        f.write("\t\t\t\t\t\"@executable_path/Frameworks\",\n")
        f.write("\t\t\t\t\t\"@loader_path/Frameworks\",\n")
        f.write("\t\t\t\t);\n")
        f.write("\t\t\t\tMODULEMAP_FILE = \"$(SRCROOT)/DSPFramework/module.modulemap\";\n")
        f.write("\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.musikx.DSPFramework;\n")
        f.write("\t\t\t\tPRODUCT_NAME = \"$(TARGET_NAME)\";\n")
        f.write("\t\t\t\tPUBLIC_HEADERS_FOLDER_PATH = Headers;\n")
        f.write("\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = \"c++17\";\n")
        f.write("\t\t\t\tCLANG_CXX_LIBRARY = \"libc++\";\n")
        f.write("\t\t\t\tSKIP_INSTALL = YES;\n")
        f.write("\t\t\t\tSWIFT_VERSION = 5.0;\n")
        f.write("\t\t\t};\n")
        f.write("\t\t\tname = Debug;\n")
        f.write("\t\t};\n")
        
        f.write(f"\t\t{dsp_release_cfg_id} /* Release */ = {{\n")
        f.write("\t\t\tisa = XCBuildConfiguration;\n")
        f.write("\t\t\tbuildSettings = {\n")
        f.write("\t\t\t\tCLANG_ENABLE_MODULES = YES;\n")
        f.write("\t\t\t\tDEFINES_MODULE = YES;\n")
        f.write("\t\t\t\tDYLIB_COMPATIBILITY_VERSION = 1;\n")
        f.write("\t\t\t\tDYLIB_CURRENT_VERSION = 1;\n")
        f.write("\t\t\t\tDYLIB_INSTALL_NAME_BASE = \"@rpath\";\n")
        f.write("\t\t\t\tHEADER_SEARCH_PATHS = (\n")
        f.write("\t\t\t\t\t\"$(inherited)\",\n")
        f.write("\t\t\t\t\t\"$(PROJECT_DIR)/DSPFramework/include\",\n")
        f.write("\t\t\t\t);\n")
        f.write("\t\t\t\tINFOPLIST_FILE = \"\";\n")
        f.write("\t\t\t\tINSTALL_PATH = \"$(LOCAL_LIBRARY_DIR)/Frameworks\";\n")
        f.write("\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (\n")
        f.write("\t\t\t\t\t\"$(inherited)\",\n")
        f.write("\t\t\t\t\t\"@executable_path/Frameworks\",\n")
        f.write("\t\t\t\t\t\"@loader_path/Frameworks\",\n")
        f.write("\t\t\t\t);\n")
        f.write("\t\t\t\tMODULEMAP_FILE = \"$(SRCROOT)/DSPFramework/module.modulemap\";\n")
        f.write("\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.musikx.DSPFramework;\n")
        f.write("\t\t\t\tPRODUCT_NAME = \"$(TARGET_NAME)\";\n")
        f.write("\t\t\t\tPUBLIC_HEADERS_FOLDER_PATH = Headers;\n")
        f.write("\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = \"c++17\";\n")
        f.write("\t\t\t\tCLANG_CXX_LIBRARY = \"libc++\";\n")
        f.write("\t\t\t\tSKIP_INSTALL = YES;\n")
        f.write("\t\t\t\tSWIFT_VERSION = 5.0;\n")
        f.write("\t\t\t};\n")
        f.write("\t\t\tname = Release;\n")
        f.write("\t\t};\n")
        
        # App configurations
        f.write(f"\t\t{app_debug_cfg_id} /* Debug */ = {{\n")
        f.write("\t\t\tisa = XCBuildConfiguration;\n")
        f.write("\t\t\tbuildSettings = {\n")
        f.write("\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;\n")
        f.write("\t\t\t\tCODE_SIGN_STYLE = Automatic;\n")
        f.write("\t\t\t\tFRAMEWORK_SEARCH_PATHS = (\n")
        f.write("\t\t\t\t\t\"$(inherited)\",\n")
        f.write("\t\t\t\t\t\"$(BUILT_PRODUCTS_DIR)\",\n")
        f.write("\t\t\t\t);\n")
        f.write("\t\t\t\tHEADER_SEARCH_PATHS = (\n")
        f.write("\t\t\t\t\t\"$(inherited)\",\n")
        f.write("\t\t\t\t\t\"$(PROJECT_DIR)/DSPFramework/include\",\n")
        f.write("\t\t\t\t);\n")
        f.write("\t\t\t\tINFOPLIST_FILE = Info.plist;\n")
        f.write("\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (\n")
        f.write("\t\t\t\t\t\"$(inherited)\",\n")
        f.write("\t\t\t\t\t\"@executable_path/Frameworks\",\n")
        f.write("\t\t\t\t);\n")
        f.write("\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.musikx.MusicStemNative;\n")
        f.write("\t\t\t\tPRODUCT_NAME = \"$(TARGET_NAME)\";\n")
        f.write("\t\t\t\tSWIFT_VERSION = 5.0;\n")
        f.write("\t\t\t\tTARGETED_DEVICE_FAMILY = \"1,2\";\n")
        f.write("\t\t\t};\n")
        f.write("\t\t\tname = Debug;\n")
        f.write("\t\t};\n")
        
        f.write(f"\t\t{app_release_cfg_id} /* Release */ = {{\n")
        f.write("\t\t\tisa = XCBuildConfiguration;\n")
        f.write("\t\t\tbuildSettings = {\n")
        f.write("\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;\n")
        f.write("\t\t\t\tCODE_SIGN_STYLE = Automatic;\n")
        f.write("\t\t\t\tFRAMEWORK_SEARCH_PATHS = (\n")
        f.write("\t\t\t\t\t\"$(inherited)\",\n")
        f.write("\t\t\t\t\t\"$(BUILT_PRODUCTS_DIR)\",\n")
        f.write("\t\t\t\t);\n")
        f.write("\t\t\t\tHEADER_SEARCH_PATHS = (\n")
        f.write("\t\t\t\t\t\"$(inherited)\",\n")
        f.write("\t\t\t\t\t\"$(PROJECT_DIR)/DSPFramework/include\",\n")
        f.write("\t\t\t\t);\n")
        f.write("\t\t\t\tINFOPLIST_FILE = Info.plist;\n")
        f.write("\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (\n")
        f.write("\t\t\t\t\t\"$(inherited)\",\n")
        f.write("\t\t\t\t\t\"@executable_path/Frameworks\",\n")
        f.write("\t\t\t\t);\n")
        f.write("\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.musikx.MusicStemNative;\n")
        f.write("\t\t\t\tPRODUCT_NAME = \"$(TARGET_NAME)\";\n")
        f.write("\t\t\t\tSWIFT_VERSION = 5.0;\n")
        f.write("\t\t\t\tTARGETED_DEVICE_FAMILY = \"1,2\";\n")
        f.write("\t\t\t};\n")
        f.write("\t\t\tname = Release;\n")
        f.write("\t\t};\n")
        f.write("/* End XCBuildConfiguration section */\n\n")
        
        # 13. XCConfigurationList Section
        f.write("/* Begin XCConfigurationList section */\n")
        f.write(f"\t\t{proj_cfg_list_id} /* Build configuration list for PBXProject \"MusicStemNative\" */ = {{\n")
        f.write("\t\t\tisa = XCConfigurationList;\n")
        f.write("\t\t\tbuildConfigurations = (\n")
        f.write(f"\t\t\t\t{proj_debug_cfg_id} /* Debug */,\n")
        f.write(f"\t\t\t\t{proj_release_cfg_id} /* Release */,\n")
        f.write("\t\t\t);\n")
        f.write("\t\t\tdefaultConfigurationIsVisible = 0;\n")
        f.write("\t\t\tdefaultConfigurationName = Release;\n")
        f.write("\t\t};\n")
        
        f.write(f"\t\t{dsp_cfg_list_id} /* Build configuration list for PBXNativeTarget \"DSPFramework\" */ = {{\n")
        f.write("\t\t\tisa = XCConfigurationList;\n")
        f.write("\t\t\tbuildConfigurations = (\n")
        f.write(f"\t\t\t\t{dsp_debug_cfg_id} /* Debug */,\n")
        f.write(f"\t\t\t\t{dsp_release_cfg_id} /* Release */,\n")
        f.write("\t\t\t);\n")
        f.write("\t\t\tdefaultConfigurationIsVisible = 0;\n")
        f.write("\t\t\tdefaultConfigurationName = Release;\n")
        f.write("\t\t};\n")
        
        f.write(f"\t\t{app_cfg_list_id} /* Build configuration list for PBXNativeTarget \"MusicStemNative\" */ = {{\n")
        f.write("\t\t\tisa = XCConfigurationList;\n")
        f.write("\t\t\tbuildConfigurations = (\n")
        f.write(f"\t\t\t\t{app_debug_cfg_id} /* Debug */,\n")
        f.write(f"\t\t\t\t{app_release_cfg_id} /* Release */,\n")
        f.write("\t\t\t);\n")
        f.write("\t\t\tdefaultConfigurationIsVisible = 0;\n")
        f.write("\t\t\tdefaultConfigurationName = Release;\n")
        f.write("\t\t};\n")
        f.write("/* End XCConfigurationList section */\n\n")
        
        f.write("\t};\n")
        f.write(f"\trootObject = {proj_id} /* Project object */;\n")
        f.write("}\n")
        
    print(f"Generated project.pbxproj successfully at {pbxproj_path}")

    # Create Shared Scheme
    shared_schemes_dir = os.path.join(xcodeproj_dir, "xcshareddata", "xcschemes")
    os.makedirs(shared_schemes_dir, exist_ok=True)
    
    scheme_path = os.path.join(shared_schemes_dir, "MusicStemNative.xcscheme")
    
    with open(scheme_path, "w", encoding="utf-8") as f:
        f.write('<?xml version="1.0" encoding="UTF-8"?>\n')
        f.write('<Scheme LastUpgradeVersion="1500" version="1.7">\n')
        f.write('\t<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES">\n')
        f.write('\t\t<BuildActionEntries>\n')
        
        # Build DSPFramework dependency entry
        f.write('\t\t\t<BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">\n')
        f.write(f'\t\t\t\t<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{dsp_target_id}" BuildableName="DSPFramework.framework" BlueprintName="DSPFramework" ReferencedContainer="container:MusicStemNative.xcodeproj">\n')
        f.write('\t\t\t\t</BuildableReference>\n')
        f.write('\t\t\t</BuildActionEntry>\n')
        
        # Build app target entry
        f.write('\t\t\t<BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">\n')
        f.write(f'\t\t\t\t<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{app_target_id}" BuildableName="MusicStemNative.app" BlueprintName="MusicStemNative" ReferencedContainer="container:MusicStemNative.xcodeproj">\n')
        f.write('\t\t\t\t</BuildableReference>\n')
        f.write('\t\t\t</BuildActionEntry>\n')
        
        f.write('\t\t</BuildActionEntries>\n')
        f.write('\t</BuildAction>\n')
        
        f.write('\t<TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES">\n')
        f.write('\t\t<Testables>\n')
        f.write('\t\t</Testables>\n')
        f.write('\t</TestAction>\n')
        
        f.write('\t<LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" launchStyle="0" useLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES">\n')
        f.write(f'\t\t<BuildableProductRunnable runableDebuggingMode="0">\n')
        f.write(f'\t\t\t<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{app_target_id}" BuildableName="MusicStemNative.app" BlueprintName="MusicStemNative" ReferencedContainer="container:MusicStemNative.xcodeproj">\n')
        f.write('\t\t\t</BuildableReference>\n')
        f.write('\t\t</BuildableProductRunnable>\n')
        f.write('\t</LaunchAction>\n')
        
        f.write('\t<ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES">\n')
        f.write(f'\t\t<BuildableProductRunnable runableDebuggingMode="0">\n')
        f.write(f'\t\t\t<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{app_target_id}" BuildableName="MusicStemNative.app" BlueprintName="MusicStemNative" ReferencedContainer="container:MusicStemNative.xcodeproj">\n')
        f.write('\t\t\t</BuildableReference>\n')
        f.write('\t\t</BuildableProductRunnable>\n')
        f.write('\t</ProfileAction>\n')
        
        f.write('\t<AnalyzeAction buildConfiguration="Debug">\n')
        f.write('\t</AnalyzeAction>\n')
        
        f.write('\t<ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES">\n')
        f.write('\t</ArchiveAction>\n')
        f.write('</Scheme>\n')
        
    print(f"Generated shared scheme successfully at {scheme_path}")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        root = sys.argv[1]
    else:
        root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    create_xcodeproj(root)
