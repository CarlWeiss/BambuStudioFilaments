# SUNLU Filament Profiles for Bambu Lab H2D

This folder contains 14 SUNLU filament profiles optimized for the Bambu Lab H2D dual-extruder printer.

## What's Included

- **14 Profile Files** - JSON profiles for various SUNLU filaments (PLA, PLA+, PLA+ 2.0, PETG, ABS, TPU, Silk PLA)
- **bbl_json_entries.json** - BBL.json entries needed for profile registration
- **SUNLU_H2D_Profiles.md** - Detailed documentation about profile settings and changes

## Quick Installation

From the repository root, run:

```powershell
.\Install-FilamentProfiles.ps1
```

The script will:
1. Show an interactive menu to select which profiles to install
2. Copy selected profiles to your BambuStudio system folder
3. Update BBL.json with the necessary entries
4. Create backups before making changes

## Prerequisites

**IMPORTANT:** You must first download SUNLU base profiles through Bambu Studio:

1. Open Bambu Studio
2. Go to Filament tab → Settings (gear icon)
3. Click "Custom Filaments" > "Create New"
4. Choose SUNLU as vendor and add the base profiles:
   - SUNLU PLA @base
   - SUNLU PLA+ @base
   - SUNLU PLA+ 2.0 @base
   - SUNLU Silk PLA+ @base
   - SUNLU PETG @base
   - SUNLU ABS @base
   - SUNLU TPU @base

These base profiles contain the `filament_id` values needed for AMS recognition.

## Available Profiles

| Material | Variants |
|----------|----------|
| **PLA** | Standard, 0.2 nozzle, High Flow |
| **PLA+** | Standard |
| **PLA+ 2.0** | Standard, 0.2 nozzle, High Flow |
| **Silk PLA** | Standard |
| **PETG** | Standard, 0.2 nozzle, High Flow |
| **ABS** | Standard, High Flow |
| **TPU** | Standard |

All profiles support dual extruder configuration (0.4/0.6/0.8mm nozzles unless otherwise specified).

## Documentation

- **[Main Repository README](../../README.md)** - Complete installation guide and troubleshooting
- **[SUNLU_H2D_Profiles.md](SUNLU_H2D_Profiles.md)** - Profile-specific details and settings
- **[Adding_Custom_Filaments.md](../../Adding_Custom_Filaments.md)** - Technical guide for creating your own profiles

## Support

For issues or questions:
- Check the [troubleshooting section](../../README.md#troubleshooting) in the main README
- Review the detailed [profile documentation](SUNLU_H2D_Profiles.md)
- See the [technical guide](../../Adding_Custom_Filaments.md) for profile structure details

---

**Part of the [BambuStudio Custom Filament Profiles](../../README.md) repository**
