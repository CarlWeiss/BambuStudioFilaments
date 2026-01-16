# Metadata Quick Reference

## TL;DR - The Simple Version

**Just add this to your profile JSON:**

```json
{
    "name": "SUNLU PLA+ 2.0 @BBL H2D",
    "inherits": "SUNLU PLA+ 2.0 @base",
    "from": "system",
    "setting_id": "GFSNLS04_H2D1",
    "instantiation": "true",

    "bsf_metadata": {
        "managed_by": "BambuStudioFilaments",
        "repository_url": "https://github.com/yourusername/BambuStudioFilaments",
        "version": "1.0.0",
        "printer": "H2D",
        "vendor": "SUNLU",
        "updated": "2026-01-15",
        "testing_status": "tested"
    },

    "compatible_printers": [...],
    ...
}
```

**That's it. Nothing else needed.**

## Why This Works

✅ **`bsf_metadata` presence = managed by this repository**
- No need for `custom_attr` or other markers
- Single source of truth
- Simple and clean

✅ **BambuStudio ignores unknown fields**
- Completely safe to add
- Won't break anything
- Works with all BambuStudio versions

## Required Fields

| Field | Value | Why |
|-------|-------|-----|
| `managed_by` | `"BambuStudioFilaments"` | Identifies our repository |
| `repository_url` | Git URL | Source attribution & updates |
| `version` | `"1.0.0"` | Track profile versions |
| `printer` | `"H2D"` | Which printer |
| `vendor` | `"SUNLU"` | Which vendor |
| `updated` | `"2026-01-15"` | Last modification date |
| `testing_status` | `"tested"` | Testing status: tested, beta, untested, experimental |

## Auto-Add Metadata

```powershell
# Automatically adds metadata to all profiles in a directory
.\Add-ProfileMetadata.ps1 -Path "profiles\H2D\SUNLU" -Printer "H2D" -Vendor "SUNLU" -TestingStatus "tested"

# Auto-detects repository URL from git
# Creates .bak backup files
# Preserves all existing profile data
# Defaults to "untested" if -TestingStatus not specified
```

## Identification

```powershell
# Check if profile is managed by this repository
. "scripts\lib\ProfileMetadata.ps1"

# Simple check
Test-IsManagedProfile -ProfilePath "profile.json"
# Returns: $true or $false

# Get all managed profiles in BambuStudio
$managed = Find-ManagedProfiles
# Returns: Array of all profiles with bsf_metadata

# Filter by printer/vendor
Find-ManagedProfiles -Printer "H2D" -Vendor "SUNLU"
```

## Removal

Profiles are removed based on `bsf_metadata` presence:

```powershell
# Scan what's installed
.\Uninstall-FilamentProfiles.ps1 -ScanOnly

# Remove all H2D/SUNLU profiles with metadata
.\Uninstall-FilamentProfiles.ps1 -Printer H2D -Vendor SUNLU -All
```

**Fallback:** If profile doesn't have metadata, pattern matching is used as backup.

## Version History

### Current: With Testing Status

```json
"bsf_metadata": {
    "managed_by": "BambuStudioFilaments",
    "repository_url": "https://github.com/user/repo",
    "version": "1.0.0",
    "printer": "H2D",
    "vendor": "SUNLU",
    "updated": "2026-01-15",
    "testing_status": "tested"
}
```

**No `custom_attr` needed** - metadata presence is sufficient.

### Previous Versions

Earlier versions may have had `custom_attr` - this is now removed for simplicity.

## FAQs

**Q: Will this break BambuStudio?**
A: No. BambuStudio ignores unknown JSON fields. This is completely safe.

**Q: What if I don't have metadata in old profiles?**
A: Scripts fall back to pattern matching (`*@BBL H2D*`) for backward compatibility.

**Q: Can I add my own metadata fields?**
A: Yes, but use a different object name to avoid conflicts. Example: `my_custom_metadata`

**Q: Does this slow down BambuStudio?**
A: No. The metadata is tiny (6 fields, ~200 bytes) and only read on profile load.

**Q: What if the repository URL changes?**
A: Update metadata with `-Force` flag: `.\Add-ProfileMetadata.ps1 ... -Force`

## See Also

- [METADATA_STRUCTURE.md](METADATA_STRUCTURE.md) - Complete field definitions
- [METADATA_IMPLEMENTATION.md](METADATA_IMPLEMENTATION.md) - Implementation details
- [PROFILE_IDENTIFICATION.md](PROFILE_IDENTIFICATION.md) - How identification works
- [TESTING_STATUS_GUIDE.md](TESTING_STATUS_GUIDE.md) - Testing status organization
