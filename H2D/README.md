# Bambu Lab H2D Filament Profiles

This folder contains custom filament profiles for the Bambu Lab H2D dual-extruder printer.

## Structure

Profiles are organized by vendor:

```
H2D/
├── SUNLU/              # SUNLU filament profiles (14 profiles)
│   ├── README.md
│   ├── bbl_json_entries.json
│   ├── SUNLU_H2D_Profiles.md
│   └── *.json profiles
│
└── [Other Vendors]/    # Additional vendors coming soon
```

## Available Vendors

### SUNLU (14 profiles)
- PLA, PLA+, PLA+ 2.0, Silk PLA
- PETG
- ABS
- TPU
- Various nozzle sizes and High Flow variants

See [SUNLU/README.md](SUNLU/README.md) for details.

## Why H2D Profiles?

The Bambu Lab H2D launched without many third-party vendor profiles. These profiles were created by deriving from vendor base profiles (e.g., SUNLU PLA @base) and adapting them for the H2D's dual-extruder configuration.

**You can use the same technique** to create profiles for other vendors. See [Adding_Custom_Filaments.md](../Adding_Custom_Filaments.md) for the complete guide.

## Installation

From the repository root:

```powershell
.\Install-FilamentProfiles.ps1
```

Or see the [main README](../README.md) for manual installation instructions.

## Contributing

Have profiles for other vendors (eSUN, Polymaker, etc.) working on H2D? Please contribute!

See the [Contributing section](../README.md#contributing) in the main README.

---

**Part of the [BambuStudio Custom Filament Profiles](../README.md) repository**
