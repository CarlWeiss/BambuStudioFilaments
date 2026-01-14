# Adding Custom Filament Profiles to BambuStudio AMS

This guide explains how to add custom filament profiles that appear in BambuStudio's AMS (Automatic Material System) settings.

## Overview

For a filament profile to appear in the AMS settings, it requires:

1. A properly formatted JSON profile file with required fields
2. Placement in the correct directory
3. Registration in the `BBL.json` manifest file

## How BambuStudio Loads Filament Profiles

### Loading Sequence

BambuStudio loads profiles in a specific order with later sources able to override earlier ones:

```
1. Resources Directory (Install Location) - READ ONLY
   └── C:\Program Files\Bambu Studio\resources\profiles\
       └── BBL.json + BBL\filament\*.json

2. System Directory (AppData) - PRIMARY LOCATION
   └── C:\Users\<username>\AppData\Roaming\BambuStudio\system\
       └── BBL.json + BBL\filament\*.json

3. User Directory (AppData) - USER CUSTOMIZATIONS
   └── C:\Users\<username>\AppData\Roaming\BambuStudio\user\<folder>\
       └── filament\*.json
```

### BBL.json Discovery Process

From [PresetBundle.cpp:1540-1601](../src/libslic3r/PresetBundle.cpp#L1540):

```cpp
// BambuStudio scans the system directory for vendor JSON files
boost::filesystem::path dir = (boost::filesystem::path(data_dir()) / PRESET_SYSTEM_DIR);

// Looks for *.json files (BBL.json, Creality.json, etc.)
for (auto& dir_entry : boost::filesystem::directory_iterator(dir)) {
    if (is_json_file(dir_entry)) {
        std::string vendor_name = dir_entry.path().stem().string();
        load_vendor_configs_from_json(vendor_name, ...);
    }
}
```

### Filament List Parsing

When `BBL.json` is found, BambuStudio parses the `filament_list` array ([PresetBundle.cpp:4300-4302](../src/libslic3r/PresetBundle.cpp#L4300)):

```cpp
if (boost::iequals(it.key(), BBL_JSON_KEY_FILAMENT_LIST)) {
    get_name_and_subpath(it, filament_subfiles);
}
```

Each entry specifies:
- `name`: The preset name (must match JSON file's `name` field)
- `sub_path`: Relative path from vendor folder to the JSON file

### Inheritance Resolution

From [PresetBundle.cpp:4391-4412](../src/libslic3r/PresetBundle.cpp#L4391):

```cpp
// When loading a filament, check for 'inherits' field
auto it1 = key_values.find(BBL_JSON_KEY_INHERITS);
if (it1 != key_values.end()) {
    inherits = it1->second;
    auto it2 = config_maps.find(inherits);
    if (it2 != config_maps.end()) {
        default_config = &(it2->second);
        // Inherit filament_id from parent if not explicitly set
        if (filament_id.empty()) {
            filament_id = filament_id_maps[inherits];
        }
    }
}
```

**Key Points:**
- Child profiles inherit all settings from parent via `inherits` field
- `filament_id` is automatically inherited from base profiles
- Only override values that differ from the parent

### Directory Priority

| Location | Purpose | Writeable | Survives Updates |
|----------|---------|-----------|------------------|
| Resources (`Program Files`) | Bundled defaults | No | Overwritten |
| System (`AppData/system`) | Active profiles | Yes | May be overwritten |
| User (`AppData/user`) | User customizations | Yes | Yes |

### Version Sync Mechanism

From [PresetUpdater.cpp:1340-1390](../src/slic3r/Utils/PresetUpdater.cpp#L1340):

```cpp
// BambuStudio compares versions between resources and AppData
Semver resource_ver = get_version_from_json(resources_file);
Semver vendor_ver = get_version_from_json(appdata_file);

if (vendor_ver < resource_ver) {
    // Copy newer version from resources to AppData
    bundles.push_back(vendor_name);
}
```

**Warning:** When BambuStudio updates, it may overwrite the `system` folder with newer versions. Always back up custom profiles.

### Key Code References

| Function | File | Line | Purpose |
|----------|------|------|---------|
| `load_presets()` | PresetBundle.cpp | 512-544 | Main entry - loads system then user |
| `load_system_presets_from_json()` | PresetBundle.cpp | 1540-1601 | Scans system dir for BBL.json |
| `load_vendor_configs_from_json()` | PresetBundle.cpp | 4216-4530 | Parses vendor JSON and subfiles |
| `PresetCollection::load_presets()` | Preset.cpp | 1226-1415 | Loads preset files from directory |
| `check_installed_vendor_profiles()` | PresetUpdater.cpp | 1340-1390 | Version comparison and sync |

## File Locations

### System Profiles (Recommended for Custom Additions)

```
C:\Users\<username>\AppData\Roaming\BambuStudio\system\
├── BBL.json                          # Manifest file listing all profiles
└── BBL\
    └── filament\
        └── SUNLU\                    # Vendor subfolder
            └── MyFilament @BBL H2D.json
```

**Note:** This location persists across application restarts but may be overwritten by BambuStudio updates.

## JSON Profile Structure

### Required Fields

| Field | Description | Example |
|-------|-------------|---------|
| `type` | Must be `"filament"` | `"filament"` |
| `name` | Unique profile name matching filename | `"SUNLU PETG @BBL H2D"` |
| `inherits` | Parent profile to inherit settings from | `"SUNLU PETG @base"` |
| `from` | Source type | `"system"` |
| `setting_id` | **Unique** cloud database identifier | `"GFSNLS08_H2D1"` |
| `instantiation` | Whether profile can be instantiated | `"true"` |
| `compatible_printers` | List of compatible printer profiles | See example below |

### Setting ID Convention

The `setting_id` must be **globally unique**. Follow this naming convention:

```
<BASE_ID>_<VARIANT>
```

**Examples:**
- Base filament: `GFSNLS08` (SUNLU PETG base)
- X1C variant: `GFSNLS08_00`
- A1 variant: `GFSNLS08_02`
- Custom H2D: `GFSNLS08_H2D1`

**Important:** Using a suffix like `_H2D1` prevents conflicts with Bambu's official numbering scheme.

### Finding Base Profile IDs

To find the correct `filament_id` and `setting_id` for inheritance, check existing base profiles:

```
C:\Users\<username>\AppData\Roaming\BambuStudio\system\BBL\filament\SUNLU\SUNLU PETG @base.json
```

Look for:
- `filament_id` - Identifies the filament type (e.g., `"GFSNL08"`)
- Existing `setting_id` patterns in variant profiles

## Complete Example

### Filament JSON File

`SUNLU PETG @BBL H2D.json`:

```json
{
    "type": "filament",
    "name": "SUNLU PETG @BBL H2D",
    "inherits": "SUNLU PETG @base",
    "from": "system",
    "setting_id": "GFSNLS08_H2D1",
    "instantiation": "true",
    "filament_max_volumetric_speed": [
        "12",
        "12"
    ],
    "filament_flow_ratio": [
        "0.98",
        "0.98"
    ],
    "nozzle_temperature": [
        "245",
        "245"
    ],
    "nozzle_temperature_initial_layer": [
        "245",
        "245"
    ],
    "compatible_printers": [
        "Bambu Lab H2D 0.4 nozzle",
        "Bambu Lab H2D 0.6 nozzle",
        "Bambu Lab H2D 0.8 nozzle"
    ]
}
```

### BBL.json Entry

Add to the `filament_list` array in `BBL.json`:

```json
{
    "name": "SUNLU PETG @BBL H2D",
    "sub_path": "filament/SUNLU/SUNLU PETG @BBL H2D.json"
}
```

**Tip:** Place the entry near related profiles (e.g., after other SUNLU PETG variants).

## Step-by-Step Instructions

### 1. Create the Filament JSON File

1. Copy an existing profile for the same filament type as a template
2. Modify the `name` field to match your new profile
3. Update `compatible_printers` to list your target printer(s)
4. Assign a **unique** `setting_id` using the `_H2D#` suffix convention
5. Ensure `inherits` points to a valid base profile (e.g., `"SUNLU PETG @base"`)

### 2. Place the File

Copy your JSON file to:
```
C:\Users\<username>\AppData\Roaming\BambuStudio\system\BBL\filament\<Vendor>\
```

### 3. Register in BBL.json

1. Open `C:\Users\<username>\AppData\Roaming\BambuStudio\system\BBL.json`
2. Find the `filament_list` array
3. Add your entry in the appropriate location (alphabetically or near related profiles)
4. Save the file

### 4. Restart BambuStudio

Close and reopen BambuStudio for changes to take effect.

## Inheritance Chain

Filament profiles use inheritance to reduce duplication:

```
fdm_filament_pet (generic PETG template)
    └── SUNLU PETG @base (SUNLU-specific base with filament_id)
        ├── SUNLU PETG @BBL X1C (X1C-specific settings)
        ├── SUNLU PETG @BBL A1 (A1-specific settings)
        └── SUNLU PETG @BBL H2D (H2D-specific settings) ← Your custom profile
```

The base profile (`@base`) contains:
- `filament_id` - Required for AMS filament recognition
- Common settings (density, cost, temperature ranges, etc.)

Variant profiles (`@BBL <Printer>`) contain:
- `setting_id` - Unique identifier
- `compatible_printers` - Printer compatibility list
- Printer-specific overrides (volumetric speed, retraction, etc.)

## Troubleshooting

### Profile Not Appearing in AMS

| Issue | Solution |
|-------|----------|
| Missing `setting_id` | Add a unique `setting_id` field |
| Duplicate `setting_id` | Use a unique suffix like `_H2D1` |
| Wrong `inherits` | Ensure base profile exists (e.g., `SUNLU PETG @base`) |
| Not in BBL.json | Add entry to `filament_list` array |
| Wrong file location | Use `AppData\Roaming\BambuStudio\system\` path |
| Typo in `compatible_printers` | Verify printer names match exactly |

### Verifying Your Profile

Check that your profile:
1. Has valid JSON syntax (use a JSON validator)
2. Has a unique `setting_id` not used by other profiles
3. References an existing base profile in `inherits`
4. Is registered in `BBL.json` with correct `sub_path`
5. Lists correct printer names in `compatible_printers`

## Dual Extruder Support

For printers with dual extruders (like H2D), array values should have two entries:

```json
"nozzle_temperature": [
    "245",
    "245"
],
"filament_flow_ratio": [
    "0.98",
    "0.98"
]
```

Include the template for dual extruder support:
```json
"include": [
    "fdm_filament_template_direct_dual"
]
```

## Backup Recommendation

Before modifying system files, back up:
- `C:\Users\<username>\AppData\Roaming\BambuStudio\system\BBL.json`
- Your custom profile files

BambuStudio updates may overwrite the `system` folder contents.
