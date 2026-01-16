# Profile Testing Status Guide

## Overview

This repository tracks the testing status of profiles to help users understand which profiles are production-ready and which are experimental.

## Testing Status Levels

| Status | Description | When to Use |
|--------|-------------|-------------|
| `tested` | Fully tested and verified | Profile has been printed with successfully, temperatures verified, flow rates tuned |
| `beta` | Partially tested | Profile works but may need fine-tuning, limited testing done |
| `untested` | Not yet tested | Profile created but not verified with actual prints |
| `experimental` | Experimental settings | Profile uses non-standard settings, use with caution |

## Implementation Approaches

We support two complementary approaches:

### Approach 1: Metadata-Based (Recommended)

Add `testing_status` field to `bsf_metadata`:

```json
{
    "name": "SUNLU PLA+ 2.0 @BBL H2D",
    "bsf_metadata": {
        "managed_by": "BambuStudioFilaments",
        "repository_url": "https://github.com/yourusername/BambuStudioFilaments",
        "version": "1.0.0",
        "printer": "H2D",
        "vendor": "SUNLU",
        "updated": "2026-01-15",
        "testing_status": "tested"
    }
}
```

**Pros:**
- No directory restructuring needed
- Easy to filter programmatically
- Can change status without moving files
- Works with existing scripts

**Cons:**
- Not visible in file explorer
- Requires script support

### Approach 2: Directory-Based (Optional)

Organize profiles into subdirectories by status:

```
profiles/
└── H2D/
    └── SUNLU/
        ├── tested/
        │   ├── SUNLU PLA+ 2.0 @BBL H2D.json
        │   └── SUNLU PLA @BBL H2D.json
        ├── beta/
        │   └── SUNLU TPU @BBL H2D.json
        └── untested/
            └── SUNLU ABS @BBL H2D.json
```

**Pros:**
- Visually clear in file explorer
- Easy to browse by status
- Clear separation of tested vs untested

**Cons:**
- More directory depth
- Moving files requires path updates
- Harder to reorganize

### Approach 3: Hybrid (Best of Both)

Use metadata as the source of truth, optionally organize directories for convenience:

1. **Always set `testing_status` in metadata** - this is the definitive status
2. **Optionally organize directories** for visual clarity
3. **Scripts read metadata** to determine status, regardless of directory location

This gives you flexibility to organize files however you want while maintaining programmatic filtering capabilities.

## Usage Examples

### Adding Testing Status to Profiles

```powershell
# Add metadata with testing status
.\scripts\Add-ProfileMetadata.ps1 `
    -Path "profiles\H2D\SUNLU\SUNLU PLA+ 2.0 @BBL H2D.json" `
    -Printer "H2D" `
    -Vendor "SUNLU" `
    -TestingStatus "tested"

# Bulk update all profiles in a directory
.\scripts\Add-ProfileMetadata.ps1 `
    -Path "profiles\H2D\SUNLU" `
    -Printer "H2D" `
    -Vendor "SUNLU" `
    -TestingStatus "beta"
```

### Installing Only Tested Profiles

```powershell
# Install only tested profiles
.\scripts\Install-FilamentProfiles.ps1 -Printer H2D -Vendor SUNLU -TestingStatus tested

# Install tested and beta (exclude untested/experimental)
.\scripts\Install-FilamentProfiles.ps1 -Printer H2D -Vendor SUNLU -TestingStatus tested,beta
```

### Scanning by Testing Status

```powershell
# Find all untested profiles
.\scripts\Scan-InstalledProfiles.ps1 -TestingStatus untested

# Find all tested H2D profiles
.\scripts\Scan-InstalledProfiles.ps1 -Printer H2D -TestingStatus tested
```

### Updating Profile Status

```powershell
# After testing a profile, update its status
.\scripts\Update-ProfileStatus.ps1 `
    -Path "profiles\H2D\SUNLU\SUNLU PLA @BBL H2D.json" `
    -TestingStatus "tested" `
    -Notes "Verified with 5 successful prints, temps and flow confirmed"
```

## Workflow Recommendations

### For Profile Creators

1. **Create new profile** with `testing_status: "untested"`
2. **Test the profile** with actual prints
3. **Update to "beta"** after initial successful prints
4. **Update to "tested"** after thorough validation
5. **Document** testing notes in git commit or separate notes file

### For Users

1. **Install tested profiles** for production use
2. **Try beta profiles** if you're willing to fine-tune
3. **Avoid untested** unless you're helping with testing
4. **Report issues** for beta/untested profiles

### For Repository Maintainers

1. **Require testing status** on all new profiles
2. **Review testing notes** before promoting to tested
3. **Create testing checklist** (see below)
4. **Update documentation** when profiles change status

## Testing Checklist

Before marking a profile as `tested`, verify:

- [ ] At least 3 successful prints completed
- [ ] First layer adhesion is good
- [ ] No stringing or excessive oozing
- [ ] Layer adhesion is strong
- [ ] Correct flow rate (measure part dimensions)
- [ ] Temperature appropriate (no under/over-extrusion)
- [ ] Compatible with specified nozzle sizes
- [ ] No unexpected behaviors (warping, delamination, etc.)
- [ ] Documentation includes any special considerations

## Migration Strategy

### Existing Profiles

Current profiles in the repository should be tagged based on testing:

```powershell
# Example: Tag all current SUNLU profiles as tested
.\scripts\Add-ProfileMetadata.ps1 `
    -Path "profiles\H2D\SUNLU" `
    -Printer "H2D" `
    -Vendor "SUNLU" `
    -TestingStatus "tested" `
    -Force
```

### Default Status

If a profile doesn't have `testing_status` field:
- Scripts should assume `untested` by default
- Display warning when installing profiles without status
- Encourage adding status metadata

## Future Enhancements

1. **Testing Notes**: Add `testing_notes` field with detailed information
2. **Tester Attribution**: Track who tested the profile
3. **Test Date**: Record when testing was completed
4. **Print Count**: Track number of successful prints reported
5. **Quality Score**: Community rating system

## Example Complete Metadata

```json
{
    "name": "SUNLU PLA+ 2.0 @BBL H2D",
    "bsf_metadata": {
        "managed_by": "BambuStudioFilaments",
        "repository_url": "https://github.com/yourusername/BambuStudioFilaments",
        "version": "1.0.0",
        "printer": "H2D",
        "vendor": "SUNLU",
        "updated": "2026-01-15",
        "testing_status": "tested",
        "testing_notes": "Verified with 10+ prints. Excellent layer adhesion. Temps confirmed 210-230C range.",
        "tested_by": "username",
        "tested_date": "2026-01-15"
    }
}
```

## See Also

- [METADATA_QUICK_REFERENCE.md](METADATA_QUICK_REFERENCE.md) - Basic metadata structure
- [METADATA_IMPLEMENTATION.md](METADATA_IMPLEMENTATION.md) - Implementation details
- [CONTRIBUTING.md](../CONTRIBUTING.md) - Contribution guidelines
