# Profile Metadata Implementation Guide

This document explains the profile metadata system for reliable identification and tracking of custom profiles.

## Overview

**Problem:** Pattern matching (`*@BBL H2D*`) can have false positives/negatives.

**Solution:** Embed metadata directly in profile JSON files for guaranteed identification.

## Metadata Structure

### Recommended Format

```json
{
    "type": "filament",
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
        "updated": "2026-01-15"
    },

    "compatible_printers": ["Bambu Lab H2D 0.4 nozzle", ...],
    ...
}
```

### Field Definitions

#### `bsf_metadata` (Required - This is Our Identifier)

```json
"bsf_metadata": {
    "managed_by": "BambuStudioFilaments",
    "repository_url": "https://github.com/yourusername/BambuStudioFilaments",
    "version": "1.0.0",
    "printer": "H2D",
    "vendor": "SUNLU",
    "updated": "2026-01-15"
}
```

| Field | Required | Type | Description | Example |
|-------|----------|------|-------------|---------|
| `managed_by` | Yes | string | Repository identifier | `"BambuStudioFilaments"` |
| `repository_url` | Yes | string | Git repository URL | `"https://github.com/user/repo"` |
| `version` | Yes | string | Profile version (semver) | `"1.0.0"` |
| `printer` | Yes | string | Printer model | `"H2D"`, `"X1C"` |
| `vendor` | Yes | string | Filament vendor | `"SUNLU"`, `"eSUN"` |
| `updated` | Yes | string (date) | Last update date (ISO 8601) | `"2026-01-15"` |

## Why Use Metadata?

### Benefits

✅ **Reliable identification** - No pattern matching ambiguity
✅ **Self-documenting** - Profile declares its source
✅ **Version tracking** - Know which version is installed
✅ **Update detection** - Compare installed vs repository versions
✅ **Audit trail** - Track when profiles were modified
✅ **Multi-repo support** - Different repos can coexist safely
✅ **Future-proof** - Extensible for new features

### Comparison: Pattern Matching vs Metadata

| Scenario | Pattern Matching | Metadata |
|----------|------------------|----------|
| Identify custom profile | `*@BBL H2D*` might match unrelated profiles | ✓ Guaranteed accurate |
| Version tracking | ❌ Not possible | ✓ Built-in |
| Update detection | ❌ Not possible | ✓ Easy comparison |
| Multi-repo safety | ⚠️ Conflicts possible | ✓ Namespace isolated |
| Orphan detection | ⚠️ Pattern-based guess | ✓ Definitive |
| Speed | ✓ Fast (name check) | ⚠️ Slower (JSON parse) |

**Recommendation:** Use metadata as primary method, patterns as fallback.

## Adding Metadata to Profiles

### Automated (Recommended)

```powershell
# Add metadata to all profiles in a directory
.\Add-ProfileMetadata.ps1 -Path "profiles\H2D\SUNLU" -Printer "H2D" -Vendor "SUNLU"

# Add to a single file
.\Add-ProfileMetadata.ps1 -Path "profiles\H2D\SUNLU\SUNLU PLA @BBL H2D.json" -Printer "H2D" -Vendor "SUNLU"

# Preview changes (dry run)
.\Add-ProfileMetadata.ps1 -Path "profiles\H2D\SUNLU" -Printer "H2D" -Vendor "SUNLU" -WhatIf

# Force update existing metadata
.\Add-ProfileMetadata.ps1 -Path "profiles\H2D\SUNLU" -Printer "H2D" -Vendor "SUNLU" -Force
```

The script:
- Creates `.bak` backup files
- Preserves JSON formatting
- Skips files that already have metadata (unless `-Force`)
- Validates JSON syntax

### Manual

1. Open profile JSON file
2. Add fields after `instantiation`:

```json
{
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

    "compatible_printers": [...]
}
```

3. Validate JSON syntax
4. Test profile in BambuStudio

## Using Metadata for Identification

### Check if Profile is Managed

```powershell
# Import module
. "scripts\lib\ProfileMetadata.ps1"

# Check by file path
Test-IsManagedProfile -ProfilePath "path\to\profile.json"

# Check by name (scans BambuStudio installation)
Test-IsManagedProfile -ProfileName "SUNLU PLA @BBL H2D"
```

### Find All Managed Profiles

```powershell
# Find all managed profiles in BambuStudio
$managed = Find-ManagedProfiles

# Filter by printer
$h2dProfiles = Find-ManagedProfiles -Printer "H2D"

# Filter by vendor
$sunluProfiles = Find-ManagedProfiles -Vendor "SUNLU"

# Both filters
$specificProfiles = Find-ManagedProfiles -Printer "H2D" -Vendor "SUNLU"

# Display results
$managed | Format-Table ProfileName, Printer, Vendor, RepositoryVersion
```

### Get Profile Metadata

```powershell
$metadata = Get-ProfileMetadata -ProfilePath "C:\Users\...\SUNLU PLA @BBL H2D.json"

Write-Host "Profile: $($metadata.ProfileName)"
Write-Host "Managed by: $($metadata.ManagedBy)"
Write-Host "Version: $($metadata.RepositoryVersion)"
Write-Host "Printer: $($metadata.Printer)"
Write-Host "Vendor: $($metadata.Vendor)"
```

### Check for Updates

```powershell
# Compare installed vs repository versions
$comparison = Compare-ProfileVersions

# Show only profiles with updates available
$comparison | Where-Object { $_.UpdateAvailable } | Format-Table

# Show all
$comparison | Format-Table ProfileName, InstalledVersion, RepoVersion, UpdateAvailable
```

### Find Profiles Without Metadata

```powershell
# Scan repository for profiles missing metadata
$missing = Get-ProfilesWithoutMetadata

$missing | Format-Table Printer, Vendor, FileName

# Add metadata to them
foreach ($profile in $missing) {
    .\Add-ProfileMetadata.ps1 -Path $profile.FilePath -Printer $profile.Printer -Vendor $profile.Vendor
}
```

## Integration with Existing Scripts

### Install Script Integration

**Before installation**, add `install_date`:

```powershell
# In Install-FilamentProfiles.ps1
foreach ($File in $SelectedFiles) {
    # Read profile
    $content = Get-Content $File.FullName -Raw
    $profile = $content | ConvertFrom-Json

    # Add install_date to metadata
    if ($profile.bsf_metadata) {
        $profile.bsf_metadata | Add-Member -NotePropertyName 'install_date' -NotePropertyValue (Get-Date -Format "yyyy-MM-dd") -Force

        # Write updated profile
        $destPath = Join-Path $DestFilamentDir $File.Name
        $profile | ConvertTo-Json -Depth 100 | Set-Content $destPath -Encoding UTF8
    } else {
        # Fallback: copy as-is
        Copy-Item -Path $File.FullName -Destination $destPath
    }
}
```

### Uninstall Script Integration

Use metadata for **primary identification**:

```powershell
# In Uninstall-FilamentProfiles.ps1

# METHOD 1: Use metadata (reliable)
$managedProfiles = Find-ManagedProfiles -Printer $SelectedPrinter.Name -Vendor $SelectedVendor.Name

# METHOD 2: Fallback to pattern matching (for profiles without metadata)
if ($managedProfiles.Count -eq 0) {
    Write-Warning "No profiles with metadata found. Falling back to pattern matching..."
    # Use old pattern-based method
}
```

### Scan Script Integration

Enhanced scanning with metadata:

```powershell
# In Scan-InstalledProfiles.ps1

# Metadata-based scan
$managedProfiles = Find-ManagedProfiles

# Show additional info
foreach ($profile in $managedProfiles) {
    Write-Host "  ✓ $($profile.ProfileName)" -ForegroundColor Green
    Write-Host "    Version: $($profile.RepositoryVersion)" -ForegroundColor Gray
    Write-Host "    Installed: $($profile.InstallDate)" -ForegroundColor Gray
    Write-Host "    Last Updated: $($profile.LastUpdated)" -ForegroundColor Gray
}
```

## Migration Strategy

### Phase 1: Add Metadata to Existing Profiles

```powershell
# Add metadata to all H2D/SUNLU profiles
.\Add-ProfileMetadata.ps1 -Path "profiles\H2D\SUNLU" -Printer "H2D" -Vendor "SUNLU"

# Verify
Get-ProfilesWithoutMetadata
```

### Phase 2: Update Scripts to Use Metadata

1. Update `Uninstall-FilamentProfiles.ps1` to check metadata first
2. Update `Scan-InstalledProfiles.ps1` to show metadata info
3. Keep pattern matching as fallback for backward compatibility

### Phase 3: Enforce Metadata on New Profiles

1. Update validation script to require `bsf_metadata`
2. Add pre-commit hook to check for metadata
3. Update CI/CD to validate metadata presence

## Best Practices

### For Profile Creation

1. **Always add metadata** when creating new profiles
2. **Use consistent version numbering** (semantic versioning)
3. **Update `last_updated`** when modifying profiles
4. **Validate JSON** after adding metadata

### For Repository Maintenance

1. **Keep metadata in sync** with actual profile versions
2. **Document version changes** in CHANGELOG
3. **Test profiles** after adding/updating metadata
4. **Backup before bulk operations**

### For Contributors

1. **Run metadata script** on new profiles before committing
2. **Increment version** when making changes
3. **Test in BambuStudio** to ensure metadata doesn't break anything
4. **Include metadata** in profile templates

## Safety & Compatibility

### BambuStudio Compatibility

✅ **Safe:** BambuStudio ignores unknown JSON fields
✅ **Tested:** Profiles with metadata work identically to those without
✅ **Future-proof:** If BambuStudio adds these fields later, values can be migrated

### JSON Standards

✅ **Valid JSON:** Metadata follows standard JSON object format
✅ **Namespaced:** `bsf_metadata` avoids conflicts with BambuStudio fields
✅ **Extensible:** Additional fields can be added without breaking existing code

### Multi-Repository Safety

If multiple profile repositories emerge:

```json
// Repository A
"bsf_metadata": { "managed_by": "BambuStudioFilaments", ... }

// Repository B
"community_profiles_metadata": { "managed_by": "AnotherRepo", ... }
```

Each uses a unique namespace - no conflicts!

## Troubleshooting

### Metadata Not Being Read

**Check JSON syntax:**
```powershell
$content = Get-Content "profile.json" -Raw
try {
    $content | ConvertFrom-Json
    Write-Host "Valid JSON"
} catch {
    Write-Host "Invalid JSON: $($_.Exception.Message)"
}
```

**Check field name:**
```powershell
$profile = Get-Content "profile.json" -Raw | ConvertFrom-Json
$profile.PSObject.Properties.Name -contains 'bsf_metadata'
```

### Profile Not Appearing in Scan

1. **Check metadata exists:**
   ```powershell
   Test-HasProfileMetadata -ProfilePath "path\to\profile.json"
   ```

2. **Check managed_by value:**
   ```powershell
   $metadata = Get-ProfileMetadata -ProfilePath "path\to\profile.json"
   $metadata.ManagedBy  # Should be "BambuStudioFilaments"
   ```

3. **Check file installed in BambuStudio:**
   ```powershell
   Test-Path "$env:APPDATA\BambuStudio\system\BBL\filament\SUNLU\profile.json"
   ```

### Version Mismatch

If installed version differs from repository:

```powershell
# Find mismatches
$comparison = Compare-ProfileVersions
$outdated = $comparison | Where-Object { $_.UpdateAvailable }

# Reinstall to update
.\Install-FilamentProfiles.ps1 -Printer H2D -Vendor SUNLU -Force
```

## Examples

### Complete Workflow

```powershell
# 1. Create new profile (manual or derived)
# ... edit H2D\SUNLU\SUNLU PLA Pro @BBL H2D.json ...

# 2. Add metadata
.\Add-ProfileMetadata.ps1 `
    -Path "profiles\H2D\SUNLU\SUNLU PLA Pro @BBL H2D.json" `
    -Printer "H2D" `
    -Vendor "SUNLU" `
    -Version "1.1.0"

# 3. Validate
.\Validate-Profiles.ps1 -Path "profiles\H2D\SUNLU"

# 4. Test metadata
$metadata = Get-ProfileMetadata -ProfilePath "profiles\H2D\SUNLU\SUNLU PLA Pro @BBL H2D.json"
$metadata | Format-List

# 5. Commit to repository
git add "profiles\H2D\SUNLU\SUNLU PLA Pro @BBL H2D.json"
git commit -m "Add SUNLU PLA Pro profile for H2D"
```

### Bulk Operations

```powershell
# Add metadata to all profiles in repository
$printers = @("H2D")  # Expand as needed
foreach ($printer in $printers) {
    $vendorDirs = Get-ChildItem "profiles\$printer" -Directory
    foreach ($vendorDir in $vendorDirs) {
        $vendor = $vendorDir.Name
        Write-Host "Processing $printer / $vendor..."

        .\Add-ProfileMetadata.ps1 `
            -Path $vendorDir.FullName `
            -Printer $printer `
            -Vendor $vendor `
            -Version "1.0.0"
    }
}
```

## Future Enhancements

### Planned Features

1. **Update Detection System**
   - Automatic checking for newer versions
   - One-click update functionality

2. **Metadata Validation**
   - CI/CD check to ensure all profiles have metadata
   - Pre-commit hook validation

3. **Version History**
   - Track all version changes in metadata
   - Rollback capability

4. **Installation Tracking**
   - Record installation history
   - Track which profiles are actively used

5. **Cloud Sync Compatibility**
   - Detect cloud-synced profiles
   - Prevent conflicts with BambuLab Cloud

## See Also

- [PROFILE_IDENTIFICATION.md](PROFILE_IDENTIFICATION.md) - Identification methods
- [TESTING_STATUS_GUIDE.md](TESTING_STATUS_GUIDE.md) - Testing status organization
- [SCALABILITY_ARCHITECTURE.md](SCALABILITY_ARCHITECTURE.md) - Multi-printer support
- [Adding_Custom_Filaments.md](Adding_Custom_Filaments.md) - Creating profiles
- [CONTRIBUTING.md](../CONTRIBUTING.md) - Contribution guidelines
