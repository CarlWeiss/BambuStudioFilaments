# P1S with Obsidian HF Nozzle Filament Profiles

This folder contains filament profiles for the **Bambu Lab P1S printer** equipped with the **Obsidian 0.4mm High Flow nozzle** - a specialty hardened steel nozzle designed for abrasive and high-flow printing.

## Why These Profiles Exist

The Obsidian nozzle has different thermal and flow characteristics compared to standard brass nozzles. While Bambu Lab provides profiles for standard P1S configurations, the Obsidian HF nozzle requires specialized profiles tuned for:

- **Higher flow rates** supported by the high-flow design
- **Different thermal characteristics** of hardened steel vs brass
- **Abrasive filament compatibility** (carbon fiber, wood-fill, metal-fill)

These profiles bridge the gap between standard P1S profiles and the specialized capabilities of the Obsidian nozzle.

## Structure

Profiles are organized by vendor:

```
P1S_ObsidianHF/
├── BambuLab/            # Bambu Lab filament profiles (17 profiles)
│   ├── README.md
│   ├── bbl_json_entries.json
│   └── *.json profiles
│
└── [Other Vendors]/     # Additional vendor profiles welcome!
```

## Available Vendors

### Bambu Lab (17 profiles)
Complete coverage of Bambu Lab's filament range optimized for Obsidian HF:
- 12 PLA variants (Basic, Silk, Matte, Metal, Wood, Glow, etc.)
- 2 PETG variants
- ABS
- PC (Polycarbonate)
- TPU

See [BambuLab/README.md](BambuLab/README.md) for full details and installation instructions.

## About the Obsidian HF Nozzle

The Bambu Lab Obsidian nozzle features:
- **Hardened steel construction** - Resistant to abrasion from filled filaments
- **High-flow design** - Supports faster printing with higher volumetric flow
- **0.4mm diameter** - Maintains fine detail capability
- **Thermal differences** - Different heat transfer vs brass requires profile tuning

Perfect for:
- Carbon fiber filaments
- Wood-fill PLA
- Metal-filled filaments
- Glow-in-the-dark PLA
- Any abrasive material that would wear brass nozzles

## Installation

Profiles can be installed manually or via import. See the vendor-specific README for detailed instructions:
- [BambuLab Installation Guide](BambuLab/README.md#installation)

Or use the repository's main [installation guide](../README.md#manual-installation) and adapt for your vendor.

## Contributing

Have profiles for other vendors (SUNLU, eSUN, Polymaker, etc.) working with the Obsidian HF nozzle? Please contribute!

When creating profiles for Obsidian HF, consider:
1. **Higher flow rates** - Take advantage of the HF capability
2. **Temperature adjustments** - Steel has different thermal properties than brass
3. **Abrasive compatibility** - Note which filaments are safe/recommended
4. **Printer compatibility** - Set to `"Bambu Lab P1S 0.4  ObXidian HF nozzle"`

See the [Contributing section](../README.md#contributing) in the main README.

---

**Part of the [BambuStudio Custom Filament Profiles](../README.md) repository**
