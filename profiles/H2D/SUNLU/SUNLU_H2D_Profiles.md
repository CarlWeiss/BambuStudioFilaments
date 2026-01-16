# SUNLU Filament Profiles for Bambu Lab H2D

This document describes the SUNLU filament profiles created for the Bambu Lab H2D printer and the changes made to ensure proper AMS recognition.

## Overview

These profiles were created to add SUNLU filament support for the Bambu Lab H2D printer. For filaments to appear correctly in the AMS settings, each profile requires:

1. A unique `setting_id`
2. Proper inheritance from a base profile (preferably SUNLU-specific bases that contain `filament_id`)
3. Registration in `BBL.json`

## Profile Summary

### Profiles with SUNLU Base Inheritance

These profiles inherit from official SUNLU base profiles, which provide the `filament_id` needed for AMS filament recognition.

| Profile | Base Profile | setting_id | filament_id (from base) |
|---------|--------------|------------|-------------------------|
| SUNLU PETG @BBL H2D | SUNLU PETG @base | GFSNLS08_H2D1 | GFSNL08 |
| SUNLU PETG @BBL H2D 0.2 nozzle | SUNLU PETG @base | GFSNLS08_H2D2 | GFSNL08 |
| SUNLU PETG HF @BBL H2D | SUNLU PETG @base | GFSNLS08_H2D3 | GFSNL08 |
| SUNLU PLA+ @BBL H2D | SUNLU PLA+ @base | GFSNLS03_H2D1 | GFSNL03 |
| SUNLU PLA+ 2.0 @BBL H2D | SUNLU PLA+ 2.0 @base | GFSNLS04_H2D1 | GFSNL04 |
| SUNLU PLA+ 2.0 @BBL H2D 0.2 nozzle | SUNLU PLA+ 2.0 @base | GFSNLS04_H2D2 | GFSNL04 |
| SUNLU PLA+ 2.0 HF @BBL H2D | SUNLU PLA+ 2.0 @base | GFSNLS04_H2D3 | GFSNL04 |
| SUNLU Silk PLA @BBL H2D | SUNLU Silk PLA+ @base | GFSNLS05_H2D1 | GFSNL05 |

### Profiles with Generic Base Inheritance

These profiles inherit from Generic bases because no official SUNLU base exists for these filament types. They include `filament_vendor` to identify as SUNLU products.

| Profile | Base Profile | setting_id |
|---------|--------------|------------|
| SUNLU PLA @BBL H2D | Generic PLA @base | GFSNLPLA_H2D1 |
| SUNLU PLA @BBL H2D 0.2 nozzle | Generic PLA @base | GFSNLPLA_H2D2 |
| SUNLU PLA HF @BBL H2D | Generic PLA @base | GFSNLPLA_H2D3 |
| SUNLU ABS @BBL H2D | Generic ABS @base | GFSNLABS_H2D1 |
| SUNLU ABS HF @BBL H2D | Generic ABS @base | GFSNLABS_H2D2 |
| SUNLU TPU @BBL H2D | Generic TPU @base | GFSNLTPU_H2D1 |

## Setting ID Convention

To avoid conflicts with official Bambu setting IDs, the following convention was used:

```
<BASE_ID>_H2D<NUMBER>
```

- `<BASE_ID>`: The filament's base setting ID (e.g., `GFSNLS08` for SUNLU PETG)
- `_H2D`: Suffix indicating H2D-specific profile
- `<NUMBER>`: Variant number (1 = standard, 2 = 0.2 nozzle, 3 = HF/High Flow)

For filaments without official SUNLU bases, custom IDs were created:
- `GFSNLPLA_H2D#` - SUNLU PLA variants
- `GFSNLABS_H2D#` - SUNLU ABS variants
- `GFSNLTPU_H2D#` - SUNLU TPU variants

## Changes Made to Each Profile

### Key Modifications

1. **Added `setting_id`** - Required for AMS recognition and cloud sync
2. **Changed `inherits`** - Updated to use SUNLU-specific bases where available
3. **Removed redundant fields** - Fields inherited from base profiles were removed:
   - `filament_vendor`
   - `filament_cost`
   - `filament_density`
   - `nozzle_temperature_range_low/high`
   - `filament_start_gcode` / `filament_end_gcode`
4. **Kept H2D-specific settings** - Printer-specific overrides were retained:
   - `compatible_printers`
   - `filament_max_volumetric_speed`
   - Temperature settings
   - Fan speeds

### Example: Before and After

**Before (SUNLU PETG @BBL H2D):**
```json
{
    "type": "filament",
    "name": "SUNLU PETG @BBL H2D",
    "inherits": "Generic PETG @base",
    "from": "system",
    "instantiation": "true",
    "filament_vendor": ["SUNLU"],
    "filament_cost": ["21.99"],
    ...
}
```

**After:**
```json
{
    "type": "filament",
    "name": "SUNLU PETG @BBL H2D",
    "inherits": "SUNLU PETG @base",
    "from": "system",
    "setting_id": "GFSNLS08_H2D1",
    "instantiation": "true",
    ...
}
```

## Installation

### Step 1: Copy Profile Files

Copy all `.json` files from this folder to:
```
C:\Users\<username>\AppData\Roaming\BambuStudio\system\BBL\filament\SUNLU\
```

### Step 2: Register in BBL.json

Add entries to `C:\Users\<username>\AppData\Roaming\BambuStudio\system\BBL.json` in the `filament_list` array:

```json
{
    "name": "SUNLU PETG @BBL H2D",
    "sub_path": "filament/SUNLU/SUNLU PETG @BBL H2D.json"
},
{
    "name": "SUNLU PETG @BBL H2D 0.2 nozzle",
    "sub_path": "filament/SUNLU/SUNLU PETG @BBL H2D 0.2 nozzle.json"
},
{
    "name": "SUNLU PETG HF @BBL H2D",
    "sub_path": "filament/SUNLU/SUNLU PETG HF @BBL H2D.json"
},
{
    "name": "SUNLU PLA @BBL H2D",
    "sub_path": "filament/SUNLU/SUNLU PLA @BBL H2D.json"
},
{
    "name": "SUNLU PLA @BBL H2D 0.2 nozzle",
    "sub_path": "filament/SUNLU/SUNLU PLA @BBL H2D 0.2 nozzle.json"
},
{
    "name": "SUNLU PLA HF @BBL H2D",
    "sub_path": "filament/SUNLU/SUNLU PLA HF @BBL H2D.json"
},
{
    "name": "SUNLU PLA+ @BBL H2D",
    "sub_path": "filament/SUNLU/SUNLU PLA+ @BBL H2D.json"
},
{
    "name": "SUNLU PLA+ 2.0 @BBL H2D",
    "sub_path": "filament/SUNLU/SUNLU PLA+ 2.0 @BBL H2D.json"
},
{
    "name": "SUNLU PLA+ 2.0 @BBL H2D 0.2 nozzle",
    "sub_path": "filament/SUNLU/SUNLU PLA+ 2.0 @BBL H2D 0.2 nozzle.json"
},
{
    "name": "SUNLU PLA+ 2.0 HF @BBL H2D",
    "sub_path": "filament/SUNLU/SUNLU PLA+ 2.0 HF @BBL H2D.json"
},
{
    "name": "SUNLU Silk PLA @BBL H2D",
    "sub_path": "filament/SUNLU/SUNLU Silk PLA @BBL H2D.json"
},
{
    "name": "SUNLU ABS @BBL H2D",
    "sub_path": "filament/SUNLU/SUNLU ABS @BBL H2D.json"
},
{
    "name": "SUNLU ABS HF @BBL H2D",
    "sub_path": "filament/SUNLU/SUNLU ABS HF @BBL H2D.json"
},
{
    "name": "SUNLU TPU @BBL H2D",
    "sub_path": "filament/SUNLU/SUNLU TPU @BBL H2D.json"
}
```

### Step 3: Restart BambuStudio

Close and reopen BambuStudio for changes to take effect.

## File List

| Filename | Description |
|----------|-------------|
| SUNLU PETG @BBL H2D.json | Standard PETG for 0.4/0.6/0.8 nozzles |
| SUNLU PETG @BBL H2D 0.2 nozzle.json | PETG optimized for 0.2 nozzle |
| SUNLU PETG HF @BBL H2D.json | High Flow PETG |
| SUNLU PLA @BBL H2D.json | Standard PLA for 0.4/0.6/0.8 nozzles |
| SUNLU PLA @BBL H2D 0.2 nozzle.json | PLA optimized for 0.2 nozzle |
| SUNLU PLA HF @BBL H2D.json | High Flow PLA |
| SUNLU PLA+ @BBL H2D.json | PLA+ for 0.4/0.6/0.8 nozzles |
| SUNLU PLA+ 2.0 @BBL H2D.json | PLA+ 2.0 for 0.4/0.6/0.8 nozzles |
| SUNLU PLA+ 2.0 @BBL H2D 0.2 nozzle.json | PLA+ 2.0 optimized for 0.2 nozzle |
| SUNLU PLA+ 2.0 HF @BBL H2D.json | High Flow PLA+ 2.0 |
| SUNLU Silk PLA @BBL H2D.json | Silk PLA for 0.4/0.6/0.8 nozzles |
| SUNLU ABS @BBL H2D.json | Standard ABS for 0.4/0.6/0.8 nozzles |
| SUNLU ABS HF @BBL H2D.json | High Flow ABS |
| SUNLU TPU @BBL H2D.json | TPU for 0.4/0.6/0.8 nozzles |

## Notes

- **BambuStudio Updates**: These profiles may be overwritten when BambuStudio updates. Back up your custom profiles before updating.
- **HF (High Flow) Profiles**: These have higher `filament_max_volumetric_speed` values for faster printing with high-flow nozzles.
- **0.2 Nozzle Profiles**: These have reduced `filament_max_volumetric_speed` appropriate for smaller nozzle diameters.
- **Dual Extruder**: All profiles include `fdm_filament_template_direct_dual` and use array values for dual extruder support.
