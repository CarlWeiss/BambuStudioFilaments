# Custom Profile Identification Guide

This document explains how the BambuStudio Filament Profiles repository identifies custom profiles for installation and removal.

## Identification Methods

Custom profiles installed by this repository can be identified using three methods:

### 1. Name Pattern Matching

All custom profiles follow a consistent naming convention:

```
<Vendor> <Material> @BBL <Printer> [Variant]
```

**Examples:**
- `SUNLU PLA+ 2.0 @BBL H2D`
- `SUNLU PETG @BBL H2D 0.2 nozzle`
- `SUNLU ABS HF @BBL H2D`

**Key identifiers:**
- Contains `@BBL` (indicating Bambu Lab compatibility)
- Contains printer model (e.g., `H2D`, `X1C`, `P1S`)
- May contain variants: `0.2 nozzle`, `0.6 nozzle`, `HF` (High Flow)

### 2. setting_id Pattern

Each custom profile has a unique `setting_id` that follows this pattern:

```
<BASE_ID>_<PRINTER><NUMBER>
```

**Examples:**
- `GFSNLS04_H2D1` - SUNLU PLA+ 2.0 standard
- `GFSNLS04_H2D2` - SUNLU PLA+ 2.0 0.2 nozzle variant
- `GFSNLS04_H2D3` - SUNLU PLA+ 2.0 High Flow variant
- `GFSNLS08_H2D1` - SUNLU PETG standard

**Pattern breakdown:**
- `GFSNLS04`: Base filament ID (from vendor's @base profile)
- `_H2D`: Printer-specific suffix
- `1`, `2`, `3`: Variant number (1=standard, 2=0.2 nozzle, 3=HF, 4=0.6 nozzle)

**Regex pattern:**
```regex
^[A-Z0-9]+_[A-Z0-9]+\d+$
```

### 3. Repository Entries File

The most reliable method is using the `bbl_json_entries.json` file in each vendor directory.

**Location:**
```
profiles/<Printer>/<Vendor>/bbl_json_entries.json
```

**Structure:**
```json
{
    "entries": [
        {
            "name": "SUNLU PLA+ 2.0 @BBL H2D",
            "sub_path": "filament/SUNLU/SUNLU PLA+ 2.0 @BBL H2D.json"
        }
    ]
}
```

This file contains the **exact** list of profiles that should be installed for a printer/vendor combination.

## Profile Structure

Custom profiles contain these key fields:

```json
{
    "type": "filament",
    "name": "SUNLU PLA+ 2.0 @BBL H2D",
    "inherits": "SUNLU PLA+ 2.0 @base",
    "from": "system",
    "setting_id": "GFSNLS04_H2D1",
    "instantiation": "true",
    "compatible_printers": [
        "Bambu Lab H2D 0.4 nozzle",
        "Bambu Lab H2D 0.8 nozzle"
    ]
}
```

**Important fields:**
- `from: "system"` - Makes the profile appear in AMS
- `setting_id` - Unique identifier for cloud sync
- `inherits` - Links to vendor's base profile (contains filament_id)
- `compatible_printers` - Which printers can use this profile

## Scanning for Installed Profiles

Use the Uninstall script with `-ScanOnly` to find installed custom profiles:

```powershell
# Scan for H2D SUNLU profiles
.\Uninstall-FilamentProfiles.ps1 -Printer H2D -Vendor SUNLU -ScanOnly

# Preview what would be removed (dry run)
.\Uninstall-FilamentProfiles.ps1 -Printer H2D -Vendor SUNLU -WhatIf
```

## Installation Locations

**Profile files:**
```
%APPDATA%\BambuStudio\system\BBL\filament\<Vendor>\
```

**BBL.json entries:**
```
%APPDATA%\BambuStudio\system\BBL.json
  └─ filament_list[] array
```

**Example:**
```
C:\Users\YourName\AppData\Roaming\BambuStudio\system\BBL\filament\SUNLU\
├── SUNLU PLA+ 2.0 @BBL H2D.json
├── SUNLU PLA+ 2.0 @BBL H2D 0.2 nozzle.json
├── SUNLU PLA+ 2.0 @BBL H2D 0.6 nozzle.json
└── SUNLU PLA+ 2.0 HF @BBL H2D.json
```

## Verification Methods

### Check if Profiles are Installed

**Method 1: Check file system**
```powershell
$vendorDir = "$env:APPDATA\BambuStudio\system\BBL\filament\SUNLU"
Get-ChildItem $vendorDir -Filter "*@BBL H2D*.json"
```

**Method 2: Check BBL.json**
```powershell
$bblJson = Get-Content "$env:APPDATA\BambuStudio\system\BBL.json" | ConvertFrom-Json
$bblJson.filament_list | Where-Object { $_.name -like "*@BBL H2D*" }
```

**Method 3: Use the scan script**
```powershell
.\Uninstall-FilamentProfiles.ps1 -ScanOnly
```

### Check Profile Validity

Use the validation script:

```powershell
# Validate all profiles in repository
.\Validate-Profiles.ps1

# Validate specific directory
.\Validate-Profiles.ps1 -Path "profiles\H2D\SUNLU"

# Strict mode (warnings as errors)
.\Validate-Profiles.ps1 -Strict
```

## Troubleshooting

### Profiles Don't Appear in AMS

1. **Check setting_id exists**
   ```powershell
   $profile = Get-Content "path\to\profile.json" | ConvertFrom-Json
   $profile.setting_id  # Should NOT be null
   ```

2. **Check setting_id is unique**
   - No two profiles should have the same setting_id
   - Run validation script to check for duplicates

3. **Check BBL.json entry exists**
   ```powershell
   $bblJson = Get-Content "$env:APPDATA\BambuStudio\system\BBL.json" | ConvertFrom-Json
   $bblJson.filament_list | Where-Object { $_.name -eq "SUNLU PLA+ 2.0 @BBL H2D" }
   ```

### Orphaned Entries

If you have BBL.json entries without corresponding files:

```powershell
# Find entries without files
$bblJson = Get-Content "$env:APPDATA\BambuStudio\system\BBL.json" | ConvertFrom-Json
foreach ($entry in $bblJson.filament_list | Where-Object { $_.name -like "*@BBL H2D*" }) {
    $filePath = Join-Path "$env:APPDATA\BambuStudio\system\" $entry.sub_path
    if (-not (Test-Path $filePath)) {
        Write-Host "Orphaned entry: $($entry.name)"
    }
}
```

## Best Practices

1. **Always backup BBL.json** before making changes
2. **Use the provided scripts** rather than manual file operations
3. **Test with -WhatIf** before applying changes
4. **Close BambuStudio** before installing/uninstalling
5. **Keep repository** for future uninstallation

## See Also

- [Adding Custom Filaments](Adding_Custom_Filaments.md) - How to create custom profiles
- [CONTRIBUTING.md](../CONTRIBUTING.md) - Guidelines for adding new profiles
- [README.md](../README.md) - Project overview and quick start
