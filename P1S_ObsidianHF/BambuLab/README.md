# Bambu Lab Filament Profiles for P1S with Obsidian HF Nozzle

This folder contains 17 Bambu Lab filament profiles optimized for the Bambu Lab P1S printer equipped with the **Obsidian 0.4mm High Flow (HF) nozzle**.

## What's Special About These Profiles?

The Obsidian nozzle is a hardened steel nozzle designed for:
- **Abrasive filaments** (Carbon fiber, wood-fill, metal-fill, glow-in-the-dark)
- **High-flow printing** with increased volumetric speeds
- **Durability** compared to standard brass nozzles

These profiles have been tuned specifically for the thermal and flow characteristics of the Obsidian HF nozzle, which differ from standard P1S nozzles.

## What's Included

17 profile files for various Bambu Lab filament types:

| Category | Profiles |
|----------|----------|
| **PLA Variants** | Basic, Lite, Silk, Silk+, Dynamic, Marble, Matte, Metal, Galaxy, Sparkle, Glow, Wood (12 variants) |
| **PETG** | PETG HF, PETG Translucent (2 variants) |
| **ABS** | ABS (1 variant) |
| **PC** | Polycarbonate (1 variant) |
| **TPU** | TPU for AMS (1 variant) |

## Installation

### Method 1: Manual Installation (Recommended for Custom Hardware)

These profiles are configured as **user profiles** and need to be placed in a specific location:

1. **Close BambuStudio**

2. **Navigate to the Bambu Lab vendor folder:**
   ```
   C:\Users\<username>\AppData\Roaming\BambuStudio\system\BBL\filament\Bambu Lab\
   ```
   **Important:** Note the space in "Bambu Lab" - this is the correct vendor folder name.

3. **Copy the profile files** from this folder to that location

4. **Update BBL.json:**
   - Open `C:\Users\<username>\AppData\Roaming\BambuStudio\system\BBL.json`
   - Find the `"filament_list": [` array
   - Add entries from `bbl_json_entries.json`

5. **Restart BambuStudio**

### Method 2: Import via BambuStudio GUI

Alternatively, you can import these profiles directly through BambuStudio:

1. Open BambuStudio
2. Go to **Filament** tab → Click the **Settings** icon (gear)
3. Select **Import** → **Import Configs**
4. Navigate to this folder and select the `.json` files you want to import
5. The profiles will appear in your filament list

## Important Notes

### Profile Configuration

These profiles have the following characteristics:
- **Printer compatibility:** `"Bambu Lab P1S 0.4  ObXidian HF nozzle"`
- **Profile type:** User profiles (`"from": "User"`)
- **Inheritance:** Standalone profiles (no base inheritance)

### AMS Visibility

⚠️ **Important:** These profiles may **not appear in the AMS dropdown** by default because they:
- Lack a `setting_id` field (required for AMS recognition)
- Are configured as "User" profiles rather than "system" profiles
- Don't inherit from base profiles with `filament_id`

**To use these profiles for AMS:**
1. Use them for slicing, then manually select standard Bambu Lab profiles in the AMS
2. Or convert them to proper system profiles (see [Converting to System Profiles](#converting-to-system-profiles) below)

## Profile Highlights

### High Flow Capabilities

The Obsidian HF nozzle supports higher volumetric flow rates than standard nozzles:
- Standard P1S nozzle: ~12-15 mm³/s for PLA
- Obsidian HF nozzle: Up to ~21mm³/s+ for PLA (depending on filament)

These profiles are tuned to take advantage of the increased flow capacity.

### Temperature Adjustments

The Obsidian nozzle may require temperature adjustments due to:
- Different thermal mass compared to brass
- Slightly different heat transfer characteristics
- Hardened steel has lower thermal conductivity than brass

Profiles have been adjusted accordingly for optimal performance.

## Converting to System Profiles

If you want these profiles to appear in the AMS dropdown, they need to be converted to system profiles. This requires:

1. Adding `"setting_id": "unique_id_here"` with a unique identifier
2. Changing `"from": "User"` to `"from": "system"`
3. Optionally adding `"type": "filament"`
4. Optionally adding `"inherits": "Base Profile @base"` to inherit from Bambu base profiles

See the [Adding_Custom_Filaments.md](../../Adding_Custom_Filaments.md) guide for detailed instructions on profile structure.

## Hardware Requirements

To use these profiles, you need:
- **Bambu Lab P1S printer**
- **Obsidian 0.4mm High Flow nozzle** installed
- **Proper printer profile** configured in BambuStudio recognizing the Obsidian nozzle

### Configuring the Obsidian Nozzle in BambuStudio

If BambuStudio doesn't automatically detect your Obsidian nozzle:

1. Go to **Printer** settings
2. Create or edit your P1S printer profile
3. Set the nozzle type to match: `Bambu Lab P1S 0.4  ObXidian HF nozzle`
4. Ensure the nozzle diameter is set to **0.4mm**

## Troubleshooting

### Profiles Don't Appear After Import

- Restart BambuStudio completely
- Check that files are in the correct `Bambu Lab` folder (with space)
- Verify BBL.json entries were added correctly

### Print Quality Issues

If you experience issues:
- **Under-extrusion:** The HF nozzle may need flow rate adjustments
- **Over-heating:** Try reducing temperature by 5-10°C
- **Stringing:** Adjust retraction settings or temperature

### Can't Select Profile for AMS

These profiles are user profiles and may not appear in AMS dropdowns. Use Method 2 (import via GUI) or convert to system profiles as described above.

## Documentation

- **[Main Repository README](../../README.md)** - Complete installation guide
- **[Adding_Custom_Filaments.md](../../Adding_Custom_Filaments.md)** - Technical guide for understanding and modifying profiles
- **[bbl_json_entries.json](bbl_json_entries.json)** - BBL.json entries for manual registration

## About the Obsidian Nozzle

The Bambu Lab Obsidian nozzle is a premium hardened steel nozzle featuring:
- **Hardened steel construction** for abrasive filament compatibility
- **High-flow design** for faster printing
- **0.4mm diameter** maintaining fine detail capability
- **Improved durability** compared to standard brass nozzles

Perfect for printing specialty filaments (carbon fiber, wood, metal-fill) that would quickly wear out standard brass nozzles.

---

**Part of the [BambuStudio Custom Filament Profiles](../../README.md) repository**
