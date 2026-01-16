# Scalability Architecture

This document explains how the BambuStudio Filament Profiles repository is designed to scale beyond H2D to support multiple printers, vendors, and nozzle configurations.

## Overview

The repository uses a **centralized registry system** combined with **dynamic pattern matching** to support unlimited printer/vendor combinations without hardcoding specific patterns.

## Architecture Components

### 1. Profile Registry (`profiles/profile-registry.json`)

**Central source of truth** for all custom profiles in the repository.

```json
{
    "profiles": {
        "H2D": {
            "SUNLU": {
                "description": "SUNLU filament profiles for Bambu Lab H2D",
                "count": 15,
                "name_pattern": "*@BBL H2D*",
                "setting_id_pattern": "*_H2D*",
                "profiles": ["SUNLU PLA @BBL H2D", ...]
            }
        },
        "X1C": {
            "eSUN": {
                "description": "eSUN filament profiles for Bambu Lab X1C",
                "name_pattern": "*@BBL X1C*",
                "setting_id_pattern": "*_X1C*",
                "profiles": [...]
            }
        }
    }
}
```

**Benefits:**
- Single location to track all profiles
- Easy to query what's available
- Supports automated scanning
- Version-controlled metadata

### 2. Registry Functions (`scripts/lib/ProfileRegistry.ps1`)

PowerShell module providing functions to:

| Function | Purpose |
|----------|---------|
| `Get-ProfileRegistry` | Load the registry file |
| `Get-AllCustomProfiles` | Get all profiles across all printers/vendors |
| `Get-ProfilesForPrinter` | Get profiles for a specific printer |
| `Get-ProfilesForVendor` | Get profiles for a printer/vendor combo |
| `Test-IsCustomProfile` | Check if a profile matches repository patterns |
| `Get-InstalledCustomProfiles` | Scan BambuStudio for installed profiles |
| `Update-ProfileRegistry` | Auto-update registry from filesystem |

### 3. Scan Script (`scripts/Scan-InstalledProfiles.ps1`)

Universal scanner that works across all printers and vendors:

```powershell
# Scan everything
.\Scan-InstalledProfiles.ps1

# Filter by printer
.\Scan-InstalledProfiles.ps1 -Printer H2D

# Filter by vendor
.\Scan-InstalledProfiles.ps1 -Vendor SUNLU

# Check for orphans
.\Scan-InstalledProfiles.ps1 -CheckOrphans
```

## Adding New Printers/Vendors

### Method 1: Automatic (Recommended)

The registry auto-updates by scanning the `profiles/` directory structure:

1. **Create directory structure:**
   ```
   profiles/X1C/eSUN/
   ├── bbl_json_entries.json
   ├── eSUN PLA @BBL X1C.json
   └── eSUN PETG @BBL X1C.json
   ```

2. **Run update script:**
   ```powershell
   # Will be created - this scans profiles/ and updates registry
   .\Update-ProfileRegistry.ps1
   ```

The registry automatically detects new printers/vendors and generates appropriate patterns.

### Method 2: Manual

Add entry to `profiles/profile-registry.json`:

```json
{
    "profiles": {
        "P1S-ObXidianHF": {
            "Polymaker": {
                "description": "Polymaker profiles for P1S with ObXidian high-flow nozzle",
                "count": 8,
                "entries_file": "profiles/P1S-ObXidianHF/Polymaker/bbl_json_entries.json",
                "materials": ["PLA", "PETG", "ABS"],
                "name_pattern": "*@BBL P1S ObXidian*",
                "setting_id_pattern": "*_P1SO*",
                "destination_path": "filament/Polymaker/",
                "profiles": [
                    "Polymaker PLA @BBL P1S ObXidian HF",
                    "Polymaker PETG @BBL P1S ObXidian HF",
                    ...
                ]
            }
        }
    }
}
```

## Naming Conventions

### Standard Printers

For standard printer models:

**Profile name pattern:**
```
<Vendor> <Material> @BBL <Printer> [Variant]
```

**Examples:**
- `SUNLU PLA+ 2.0 @BBL H2D`
- `eSUN PLA+ @BBL X1C`
- `Polymaker ASA @BBL A1`

**setting_id pattern:**
```
<BASE_ID>_<PRINTER_CODE><VARIANT>
```

**Examples:**
- `GFSNLS04_H2D1` (SUNLU PLA+ 2.0, H2D, standard)
- `GFESUN02_X1C1` (eSUN PLA+, X1C, standard)

### Special Configurations

For specialty nozzles or configurations:

**Profile name pattern:**
```
<Vendor> <Material> @BBL <Printer> <Config> [Variant]
```

**Examples:**
- `Polymaker PLA @BBL P1S ObXidian HF`
- `eSUN PETG @BBL X1C Hardened 0.6mm`

**setting_id pattern:**
```
<BASE_ID>_<PRINTER_CODE><CONFIG_CODE><VARIANT>
```

**Suggested config codes:**
- `O` = ObXidian nozzle
- `H` = Hardened steel nozzle
- `R` = Ruby nozzle
- `C` = Ceramic nozzle

**Examples:**
- `GFPOLY01_P1SO1` (Polymaker, P1S, ObXidian, standard)
- `GFESUN02_X1CH2` (eSUN, X1C, Hardened, 0.6mm variant)

## Pattern Matching

### Dynamic Patterns

Patterns are stored in the registry and applied dynamically:

```powershell
# Check if a profile is from this repository
Test-IsCustomProfile -ProfileName "SUNLU PLA @BBL H2D"
# Returns: $true

# Works for any printer
Test-IsCustomProfile -ProfileName "eSUN PETG @BBL X1C" -Printer "X1C"
# Returns: $true (if X1C/eSUN profiles exist in registry)
```

### Wildcard Support

The system uses PowerShell `-like` operator with wildcards:

| Pattern | Matches |
|---------|---------|
| `*@BBL H2D*` | Any profile for H2D |
| `*@BBL X1C*` | Any profile for X1C |
| `*_H2D*` | Any H2D setting_id |
| `*ObXidian*` | Any ObXidian nozzle profile |

## Scaling Scenarios

### Scenario 1: Add New Printer Model

**New printer: Bambu Lab P2S**

1. Create directory: `profiles/P2S/`
2. Add vendor subdirectories: `profiles/P2S/SUNLU/`, `profiles/P2S/eSUN/`, etc.
3. Create profiles with `@BBL P2S` naming
4. Use setting_id pattern: `*_P2S*`
5. Registry auto-detects on next scan

**No code changes needed!**

### Scenario 2: Add New Vendor

**New vendor: Prusament for H2D**

1. Create directory: `profiles/H2D/Prusament/`
2. Add `bbl_json_entries.json`
3. Create profiles: `Prusament PLA @BBL H2D.json`, etc.
4. Registry auto-updates

**Scripts automatically work!**

### Scenario 3: Specialty Nozzle

**ObXidian nozzle for P1S**

1. Create directory: `profiles/P1S-ObXidianHF/`
2. Add vendors: `profiles/P1S-ObXidianHF/SUNLU/`
3. Use naming: `SUNLU PLA @BBL P1S ObXidian HF`
4. Use setting_id: `GFSNLS01_P1SO1`
5. Pattern: `*@BBL P1S ObXidian*`

**Everything scales automatically!**

### Scenario 4: Multi-Nozzle Sizes

**Different nozzle sizes for same printer**

Already supported via variant system:

```
SUNLU PLA @BBL H2D               # 0.4mm (default)
SUNLU PLA @BBL H2D 0.2 nozzle    # 0.2mm
SUNLU PLA @BBL H2D 0.6 nozzle    # 0.6mm
SUNLU PLA @BBL H2D 0.8 nozzle    # 0.8mm
```

All matched by single pattern: `*@BBL H2D*`

## Future Enhancements

### Planned Features

1. **Auto-Registry Updates**
   - Git pre-commit hook to update registry
   - CI/CD check for registry consistency

2. **Cross-Platform Support**
   - Bash equivalents for Linux/macOS
   - Python-based alternatives

3. **GUI Profile Manager**
   - Visual tool to browse available profiles
   - One-click install/uninstall
   - Profile comparison

4. **Cloud Sync Detection**
   - Track which profiles are cloud-synced
   - Warn before removing synced profiles

5. **Profile Versioning**
   - Track profile version history
   - Update detection and migration

## Best Practices

### For Contributors

1. **Follow naming conventions** strictly
2. **Update bbl_json_entries.json** when adding profiles
3. **Test with Validate-Profiles.ps1** before committing
4. **Document new printer/vendor combos** in README
5. **Use unique setting_id values** (check registry)

### For Maintainers

1. **Keep registry in sync** with filesystem
2. **Validate patterns** work across all printers
3. **Test scripts** with multiple printer/vendor combos
4. **Document special configurations** (ObXidian, etc.)
5. **Version control** the registry carefully

## Migration from Hardcoded Patterns

### Old Approach (H2D-specific)

```powershell
# Hardcoded in script
$profiles = Get-ChildItem | Where-Object { $_.Name -like "*@BBL H2D*" }
```

**Problems:**
- Won't work for X1C, P1S, etc.
- Requires code changes for new printers
- No central tracking

### New Approach (Registry-based)

```powershell
# Dynamic from registry
$profiles = Get-InstalledCustomProfiles -Printer $PrinterName
```

**Benefits:**
- Works for any printer in registry
- No code changes needed
- Central tracking
- Extensible

## Examples

### Check What's Available

```powershell
# Load registry
$registry = Get-ProfileRegistry

# List all printers
$registry.profiles | Get-Member -MemberType NoteProperty

# List vendors for H2D
$registry.profiles.H2D | Get-Member -MemberType NoteProperty

# Get profile count
$registry.profiles.H2D.SUNLU.count
```

### Scan Installation

```powershell
# All printers
.\Scan-InstalledProfiles.ps1

# Specific printer
.\Scan-InstalledProfiles.ps1 -Printer H2D

# Specific vendor across all printers
.\Scan-InstalledProfiles.ps1 -Vendor SUNLU

# Check for problems
.\Scan-InstalledProfiles.ps1 -CheckOrphans
```

### Programmatic Access

```powershell
# Import module
. "scripts\lib\ProfileRegistry.ps1"

# Get all custom profiles
$all = Get-AllCustomProfiles
$all | Group-Object Printer | Format-Table

# Check if specific profile is custom
Test-IsCustomProfile -ProfileName "SUNLU PLA @BBL H2D"

# Get what's installed
$installed = Get-InstalledCustomProfiles
$installed | Format-Table Printer, Vendor, ProfileName, Exists
```

## See Also

- [PROFILE_IDENTIFICATION.md](PROFILE_IDENTIFICATION.md) - How profiles are identified
- [Adding_Custom_Filaments.md](Adding_Custom_Filaments.md) - Creating new profiles
- [CONTRIBUTING.md](../CONTRIBUTING.md) - Contribution guidelines
- [README.md](../README.md) - Project overview
