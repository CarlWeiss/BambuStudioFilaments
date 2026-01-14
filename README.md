# BambuStudio Custom Filament Profiles

A comprehensive collection of custom filament profiles for BambuStudio that properly integrate with the AMS (Automatic Material System). This repository serves as both a **profile library** for unsupported printer/vendor combinations and a **complete guide** for creating your own derived profiles when Bambu Lab hasn't provided official support yet.

## Why This Repository?

### The Problem

Bambu Lab doesn't always provide filament profiles for all printer models immediately after release and creating custom profiles dosnt show in the AMS leading to me forgetting to update the filament profile when sending prints. Maybe this will help you too.

Yes, you could create a pull request against the BambuStudio project but this approach allows a quick way to deploy custom filaments, track and share chagnes and reload the filament profiles that get cleared after a BambuStudio update.

Some cases where Bambu Lab dosnt provide filament profiles:
- **New printers** like the H2D initially launched without SUNLU profiles
- **Third-party filaments** often lack proper AMS integration even when base profiles exist

Many users create custom filament profiles for BambuStudio that work for slicing but **don't appear in the AMS dropdown**. This is because AMS visibility requires specific fields (`setting_id`, proper inheritance, registration in `BBL.json`) that aren't obvious or well-documented.

### The Solution

This repository serves as both a **profile library** and a **comprehensive guide** for creating derived profiles from vendor base profiles for printers that don't yet have official support.

**What this repository provides:**
- ✅ **Ready-to-use profiles** with correct AMS integration for unsupported printers
- 📚 **Step-by-step documentation** showing how to derive profiles from base profiles
- 🛠️ **Automated installation scripts** for easy setup
- 📖 **Working examples** you can learn from and adapt for other vendors/printers
- 🤝 **Community-driven** collection filling the gaps in official support

### Real-World Examples

**Example 1: SUNLU H2D Profiles**
The SUNLU H2D profiles were created because:
1. Bambu Lab released the H2D without SUNLU filament profiles
2. SUNLU base profiles (`@base`) existed in BambuStudio
3. Using the techniques documented here, H2D-specific profiles were derived from those bases
4. Now these profiles work perfectly in the AMS, just like official profiles

**You can use these same approaches** to create profiles for any printer model, specialty hardware, or vendor combination that Bambu Lab hasn't officially supported yet.

## Currently Available Profiles

### SUNLU Filaments for Bambu Lab H2D (14 profiles)

H2D-optimized SUNLU filament profiles covering:

| Material Type | Variants | Nozzle Sizes |
|--------------|----------|--------------|
| **PLA** | Standard, High Flow | 0.2, 0.4/0.6/0.8 |
| **PLA+** | Standard | 0.4/0.6/0.8 |
| **PLA+ 2.0** | Standard, High Flow | 0.2, 0.4/0.6/0.8 |
| **Silk PLA** | Standard | 0.4/0.6/0.8 |
| **PETG** | Standard, High Flow | 0.2, 0.4/0.6/0.8 |
| **ABS** | Standard, High Flow | 0.4/0.6/0.8 |
| **TPU** | Standard | 0.4/0.6/0.8 |

All profiles are configured for dual extruder support and include proper `setting_id` values for AMS recognition.

> **Want to contribute?** If you've created profiles for an unsupported printer/vendor combo, share them! See the [Contributing](#contributing) section below.

---

## Prerequisites

### IMPORTANT: Download Base Profiles First

**These profiles inherit from vendor-specific base profiles that must be installed first through Bambu Studio.**

#### For SUNLU Profiles

The SUNLU H2D profiles require SUNLU base profiles to be downloaded first:

Before installing these profiles:

1. **Open Bambu Studio**
2. **Navigate to the Filament tab** (top menu)
3. **Click the Settings icon** (gear icon)
4. **Select "Custom Filaments" > "Create New"**
5. **Choose SUNLU as the vendor**
6. **Add the filament types you need:**
   - SUNLU PLA @base
   - SUNLU PLA+ @base
   - SUNLU PLA+ 2.0 @base
   - SUNLU Silk PLA+ @base
   - SUNLU PETG @base
   - SUNLU ABS @base (if available)
   - SUNLU TPU @base (if available)

This process downloads the official SUNLU base profiles that contain critical `filament_id` values needed for AMS filament recognition.

**Note:** Other vendors will have their own base profile requirements. Always check vendor-specific documentation before installation.

**For more information:** [Bambu Lab Wiki - Creating Custom Filaments](https://wiki.bambulab.com/en/bambu-studio/create-filament)

---

## Quick Start (Recommended)

### Automated Installation with PowerShell Script

The easiest way to install these profiles is using the included PowerShell script:

```powershell
# Interactive installation - choose which profiles to install
.\Install-FilamentProfiles.ps1

# Preview what will happen (dry run)
.\Install-FilamentProfiles.ps1 -WhatIf

# Install all profiles without prompting
.\Install-FilamentProfiles.ps1 -All

# Overwrite existing files
.\Install-FilamentProfiles.ps1 -Force
```

#### What the Script Does

1. **Creates a timestamped backup** of your `BBL.json` file
2. **Copies selected profile files** to `%APPDATA%\BambuStudio\system\BBL\filament\SUNLU\`
3. **Updates BBL.json** by adding entries to the `filament_list` array
4. **Validates** that prerequisites exist before making changes

#### Interactive Selection

When run without `-All`, the script shows a menu organized by filament type:

```
Select which filament profiles to install:

  PLA Profiles:
    [1] SUNLU PLA
    [2] SUNLU PLA 0.2 nozzle
    [3] SUNLU PLA HF

  PLA+ Profiles:
    [4] SUNLU PLA+

  PETG Profiles:
    [5] SUNLU PETG
    [6] SUNLU PETG 0.2 nozzle
    [7] SUNLU PETG HF

  ... (and more)

  [A] All profiles
  [Q] Quit

Enter selection: 1,5,7
```

Enter profile numbers separated by commas, or type `A` for all profiles.

#### After Installation

1. **Close BambuStudio** if it's running
2. **Reopen BambuStudio**
3. Your profiles should appear in:
   - **Prepare tab** → Filament dropdown
   - **AMS settings** → Filament selection dialog

---

## Manual Installation

If you prefer not to use the script or need more control:

### Step 1: Copy Profile Files

1. Close BambuStudio
2. Navigate to the appropriate vendor folder:
   ```
   C:\Users\<username>\AppData\Roaming\BambuStudio\system\BBL\filament\<VendorName>\
   ```
   - For SUNLU: `...\filament\SUNLU\`
   - For other vendors: `...\filament\<VendorName>\`

   (Create the vendor folder if it doesn't exist)
3. Copy desired `.json` files from the profile folder (e.g., `H2D\SUNLU\`) to this location

### Step 2: Update BBL.json

1. **Backup first:** Copy `BBL.json` to `BBL.json.backup`
2. Open `BBL.json` in a text editor (Notepad++, VS Code, etc.)
3. Find the `"filament_list": [` array
4. Add entries from the vendor's `bbl_json_entries.json` file (e.g., `H2D\SUNLU\bbl_json_entries.json`) for each profile you copied

Example entry:
```json
{
    "name": "SUNLU PETG @BBL H2D",
    "sub_path": "filament/SUNLU/SUNLU PETG @BBL H2D.json"
},
```

**Tip:** For better organization, insert entries near related profiles (e.g., add H2D profiles near existing SUNLU PETG profiles around line 2650).

### Step 3: Restart BambuStudio

Close and reopen BambuStudio for changes to take effect.

---

## Profile Settings Summary

### SUNLU H2D Profile Settings

#### PLA Variants

| Profile | Nozzle Temp | Bed Temp | Max Vol. Speed | Flow Ratio |
|---------|-------------|----------|----------------|------------|
| **SUNLU PLA** | 215°C (first: 220°C) | 55°C | 12 mm³/s | 0.98 |
| **SUNLU PLA 0.2 nozzle** | 215°C (first: 220°C) | 55°C | 5 mm³/s | 0.98 |
| **SUNLU PLA HF** | 215°C (first: 220°C) | 55°C | 21 mm³/s | 0.98 |
| **SUNLU PLA+** | 220°C (first: 225°C) | 60°C | 14 mm³/s | 0.98 |
| **SUNLU PLA+ 2.0** | 220°C (first: 225°C) | 60°C | 14 mm³/s | 0.98 |
| **SUNLU PLA+ 2.0 0.2** | 220°C (first: 225°C) | 60°C | 6 mm³/s | 0.98 |
| **SUNLU PLA+ 2.0 HF** | 220°C (first: 225°C) | 60°C | 21 mm³/s | 0.98 |
| **SUNLU Silk PLA** | 215°C (first: 220°C) | 55°C | 10 mm³/s | 0.98 |

#### PETG Variants

| Profile | Nozzle Temp | Bed Temp | Max Vol. Speed | Flow Ratio | Fan Speed |
|---------|-------------|----------|----------------|------------|-----------|
| **SUNLU PETG** | 245°C | 70°C | 12 mm³/s | 0.98 | 40-60% |
| **SUNLU PETG 0.2 nozzle** | 245°C | 70°C | 5 mm³/s | 0.98 | 40-60% |
| **SUNLU PETG HF** | 245°C | 70°C | 21 mm³/s | 0.98 | 40-60% |

#### ABS Variants

| Profile | Nozzle Temp | Bed Temp | Chamber | Max Vol. Speed | Flow Ratio | Fan Speed |
|---------|-------------|----------|---------|----------------|------------|-----------|
| **SUNLU ABS** | 250°C | 100°C | 60°C | 15 mm³/s | 0.95 | 0-30% |
| **SUNLU ABS HF** | 250°C | 100°C | 60°C | 24 mm³/s | 0.95 | 0-30% |

#### TPU

| Profile | Nozzle Temp | Bed Temp | Max Vol. Speed | Flow Ratio | Fan Speed | Notes |
|---------|-------------|----------|----------------|------------|-----------|-------|
| **SUNLU TPU** | 225°C | 35°C | 3.2 mm³/s | 1.0 | 80-100% | Print slowly; **not recommended for AMS** |

**Note:** HF (High Flow) profiles are optimized for high-flow hotends and faster printing.

> Settings for additional vendors will be documented here as they are added to the repository.

---

## Troubleshooting

### Profiles Not Showing in AMS

| Issue | Solution |
|-------|----------|
| **Missing base profiles** | Download SUNLU base profiles through Bambu Studio (see Prerequisites) |
| **Not in BBL.json** | Ensure entries were added to the `filament_list` array |
| **Wrong file location** | Profiles must be in `system\BBL\filament\SUNLU\`, not `user\` folder |
| **Duplicate `setting_id`** | Each profile needs a unique `setting_id` (already configured correctly) |
| **BambuStudio not restarted** | Close and reopen BambuStudio completely |
| **Printer not recognized** | Verify your printer is detected as H2D in Device settings |

### Print Quality Issues

| Issue | Solution |
|-------|----------|
| **Over/under-extrusion** | Adjust flow ratio ±0.02 (e.g., 0.98 → 0.96 or 1.00) |
| **Poor layer adhesion** | Increase nozzle temperature by 5°C |
| **Stringing** | Decrease nozzle temperature by 5°C |
| **Warping** | Ensure bed is clean; increase bed temperature by 5°C |
| **Poor surface finish** | Dry filament (especially PETG, ABS, TPU); check nozzle isn't clogged |

### Script Issues

| Issue | Solution |
|-------|----------|
| **"BBL.json not found"** | Run BambuStudio at least once to create system files |
| **"Profiles already exist"** | Use `-Force` flag to overwrite existing files |
| **PowerShell execution blocked** | Run `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser` |

---

## Uninstalling Profiles

To remove installed profiles:

```powershell
.\Uninstall-FilamentProfiles.ps1
```

This script will:
1. Create a backup of `BBL.json`
2. Remove all SUNLU H2D profile files
3. Remove corresponding entries from `BBL.json`

---

## Advanced Documentation

### Understanding Profile Requirements

For profiles to appear in AMS, they need:

| Field | Purpose | Example |
|-------|---------|---------|
| `setting_id` | Unique cloud sync identifier | `"GFSNLS08_H2D1"` |
| `inherits` | Base profile with `filament_id` | `"SUNLU PETG @base"` |
| `compatible_printers` | Target printer list | `["Bambu Lab H2D 0.4 nozzle"]` |
| `from` | Source type | `"system"` |
| `instantiation` | Can be instantiated | `"true"` |

### Setting ID Convention

These profiles use the following `setting_id` pattern to avoid conflicts:

```
<BASE_ID>_H2D<NUMBER>
```

- **BASE_ID**: Filament's base ID (e.g., `GFSNLS08` for SUNLU PETG)
- **_H2D**: H2D-specific suffix
- **NUMBER**: Variant (1=standard, 2=0.2 nozzle, 3=HF/High Flow)

### BambuStudio Loading Order

BambuStudio loads profiles from three locations:

1. **Resources** (`Program Files\Bambu Studio\resources\`) - Bundled defaults (read-only)
2. **System** (`AppData\Roaming\BambuStudio\system\`) - **Primary location for AMS profiles**
3. **User** (`AppData\Roaming\BambuStudio\user\`) - User customizations (not visible in AMS)

Only profiles in the **System** folder with proper `setting_id` appear in the AMS picker.

For more technical details, see [Adding_Custom_Filaments.md](Adding_Custom_Filaments.md).

---

## Important Notes

- ⚠️ **BambuStudio updates may overwrite** profiles in the `system` folder. Keep backups!
- 💡 **Always test** new profiles with a small test print before full prints
- 🌡️ **Temperature calibration** is recommended - every filament batch varies slightly
- 📦 **TPU is not recommended for AMS** - load manually due to flexibility
- 🏠 **ABS requires enclosed chamber** for best results
- 🧪 **Run temperature towers** when switching to a new filament spool

---

## Filament Storage Tips

For optimal print quality:

- **PLA/PLA+**: Store in sealed bags with desiccant; relatively moisture-resistant
- **PETG**: Very hygroscopic - **must** be stored dry; dry at 65°C for 4-6 hours if wet
- **ABS**: Hygroscopic - store in dry box; dry at 80°C for 2-4 hours if needed
- **TPU**: Extremely hygroscopic - **always** store in dry box with desiccant

Signs of wet filament: Popping sounds during printing, stringing, poor layer adhesion, rough surface finish.

---

## Contributing

Contributions are welcome! This repository aims to be a comprehensive collection of custom filament profiles for various vendors and printer models.

### Have an Unsupported Printer/Vendor Combo?

If you've successfully created profiles for a printer or configuration that Bambu Lab doesn't officially support yet, **please share them!** Examples include:
- New printer models without vendor profiles (like H2D was at launch)
- Specialty nozzles or hotends (ObXidian nozzle, high-flow hotends, etc.)
- Popular vendors missing profiles for certain printers
- Custom printer configurations

Your contribution helps the entire community and serves as a reference for others facing similar situations.

### Adding New Vendor/Printer Profiles

To contribute profiles for a new vendor or printer model:

1. **Create the folder structure**: `PrinterModel/VendorName/`
   - Example: `H2D/SUNLU/`, `X1C/eSUN/`, `P1S_ObXidian/Polymaker/`
2. **Add profile JSON files** with proper `setting_id` values (see [Adding_Custom_Filaments.md](Adding_Custom_Filaments.md) for details)
3. **Create a JSON entries file** (`bbl_json_entries.json`) with BBL.json entries
4. **Write vendor-specific documentation** (optional but recommended) - include prerequisites and any special notes
5. **Test thoroughly** on the target printer before submitting

### General Contribution Guidelines

1. **Follow naming conventions**: `<Brand> <Material> @BBL <Printer>.json`
2. **Use unique `setting_id` values**: Add appropriate suffixes (e.g., `_X1C1`, `_P1P1`)
3. **Document prerequisites**: If profiles inherit from base profiles, document how to obtain them
4. **Test your changes**: Verify profiles work correctly in BambuStudio
5. **Update documentation**: Add your vendor to the "Currently Available Profiles" section

### What We're Looking For

**Profiles that fill official support gaps:**
- **New printer models** that launched without vendor profiles
- **Specialty configurations** (ObXidian nozzle, hardened steel nozzles, high-flow hotends)
- **Popular vendor/printer combos** lacking official profiles

**Additional profile coverage:**
- **More vendors**: eSUN, Polymaker, Prusament, Overture, Hatchbox, etc.
- **More printers**: X1C, P1P, A1, P2S, X1, etc.
- **Specialized materials**: Carbon fiber, wood-fill, metal-fill, glow-in-the-dark, etc.

**Improvements:**
- **Documentation enhancements**: Better troubleshooting, clearer setup guides
- **Script improvements**: Cross-platform support, better error handling
- **Profile templates**: Generic templates for creating new profiles

---

## Resources

- **Bambu Lab Wiki:** [Creating Custom Filaments](https://wiki.bambulab.com/en/bambu-studio/create-filament)
- **BambuStudio GitHub:** [github.com/bambulab/BambuStudio](https://github.com/bambulab/BambuStudio)
- **Community Forum:** [forum.bambulab.com](https://forum.bambulab.com/)

---

## License

This project is licensed under the **GNU Affero General Public License v3.0 (AGPL-3.0)** to match [BambuStudio's license](https://github.com/bambulab/BambuStudio/blob/master/LICENSE).

You are free to use, modify, and distribute these profiles, provided derivative works are also shared under AGPL-3.0.

---

## Version History

### v1.0 - Initial Release

**SUNLU H2D Profiles (14 profiles):**
- Created to fill the gap when H2D launched without SUNLU support
- Derived from SUNLU base profiles using documented techniques
- Full AMS integration with proper `setting_id` values
- Automated PowerShell installation and uninstall scripts

**Documentation:**
- Comprehensive installation guides for both profile sets
- Technical deep-dive guide ([Adding_Custom_Filaments.md](Adding_Custom_Filaments.md)) showing how to derive profiles from bases
- Working examples that can be used as templates for other unsupported printer/vendor combinations
- Organized folder structure (Printer_Config/Vendor pattern)


---

**A community-driven project for BambuStudio users** 🖨️✨
