# Profile Metadata Structure

## Final Metadata Format

This document defines the official metadata structure for profiles in this repository.

### Complete Profile Example

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
        "updated": "2026-01-15",
        "testing_status": "tested"
    },

    "compatible_printers": [
        "Bambu Lab H2D 0.4 nozzle",
        "Bambu Lab H2D 0.8 nozzle"
    ],
    "filament_flow_ratio": ["0.98", "0.98"],
    "nozzle_temperature": ["220", "220"],
    ...
}
```

## Field Definitions

### `bsf_metadata` Object (Required)

**This is the sole identifier for profiles managed by this repository.**

```json
"bsf_metadata": {
    "managed_by": "BambuStudioFilaments",
    "repository_url": "https://github.com/yourusername/BambuStudioFilaments",
    "version": "1.0.0",
    "printer": "H2D",
    "vendor": "SUNLU",
    "updated": "2026-01-15",
    "testing_status": "tested"
}
```

| Field | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| `managed_by` | string | **Yes** | Repository name | `"BambuStudioFilaments"` |
| `repository_url` | string | **Yes** | Full GitHub repository URL | `"https://github.com/user/repo"` |
| `version` | string | **Yes** | Profile version (semver) | `"1.0.0"`, `"1.2.3"` |
| `printer` | string | **Yes** | Printer model code | `"H2D"`, `"X1C"`, `"P1S"` |
| `vendor` | string | **Yes** | Filament vendor name | `"SUNLU"`, `"eSUN"` |
| `updated` | string | **Yes** | Last update date (ISO 8601) | `"2026-01-15"` |
| `testing_status` | string | **Yes** | Testing status | `"tested"`, `"beta"`, `"untested"`, `"experimental"` |

## Why Repository URL?

### Key Benefits

✅ **Clear Attribution**
- Users know exactly where the profile came from
- Properly credits the source repository

✅ **Update Detection**
- Can fetch latest version info from repository
- Compare installed version with remote version

✅ **Multi-Repository Support**
- Different repositories distinguished by URL
- Forks have different URLs - no conflicts

✅ **Documentation Access**
- Users can navigate to repository for docs
- Find issues, PRs, and contribution guidelines

✅ **Fork-Friendly**
- Forked repositories have their own URL
- Clear provenance tracking

### URL Format Examples

**GitHub HTTPS:**
```
https://github.com/username/BambuStudioFilaments
```

**GitHub (without .git suffix):**
```
https://github.com/username/BambuStudioFilaments
```

**GitLab:**
```
https://gitlab.com/username/bambu-profiles
```

**Self-Hosted:**
```
https://git.example.com/username/profiles
```

## Auto-Detection

The `Add-ProfileMetadata.ps1` script auto-detects the repository URL from git remote:

```powershell
# Automatic detection
.\Add-ProfileMetadata.ps1 -Path "profiles\H2D\SUNLU" -Printer "H2D" -Vendor "SUNLU"
# Auto-detected repository: https://github.com/yourusername/BambuStudioFilaments

# Manual override
.\Add-ProfileMetadata.ps1 -Path "profiles\H2D\SUNLU" -Printer "H2D" -Vendor "SUNLU" `
    -RepositoryUrl "https://github.com/customuser/fork"
```

### Detection Logic

1. **Try git remote:** `git remote get-url origin`
2. **Convert SSH to HTTPS:** `git@github.com:user/repo.git` → `https://github.com/user/repo`
3. **Remove .git suffix:** `https://github.com/user/repo.git` → `https://github.com/user/repo`
4. **Fallback:** Use default placeholder URL

## Usage Examples

### Check Repository Source

```powershell
# Import module
. "scripts\lib\ProfileMetadata.ps1"

# Get metadata
$metadata = Get-ProfileMetadata -ProfilePath "path\to\profile.json"

# Check source
Write-Host "Profile from: $($metadata.RepositoryUrl)"
Write-Host "Version: $($metadata.Version)"
```

### Verify Authenticity

```powershell
# Verify this is the official repository
if ($metadata.RepositoryUrl -eq "https://github.com/yourusername/BambuStudioFilaments") {
    Write-Host "✓ Official repository profile" -ForegroundColor Green
} else {
    Write-Host "⚠ Third-party fork or custom profile" -ForegroundColor Yellow
    Write-Host "  Source: $($metadata.RepositoryUrl)"
}
```

### Open Repository

```powershell
# Open repository in browser
$metadata = Get-ProfileMetadata -ProfilePath "profile.json"
Start-Process $metadata.RepositoryUrl
```

### Future: Check for Updates

```powershell
# Pseudo-code for future update checker
$metadata = Get-ProfileMetadata -ProfilePath "installed\profile.json"
$apiUrl = $metadata.RepositoryUrl -replace 'github.com', 'api.github.com/repos'
$releases = Invoke-RestMethod "$apiUrl/releases/latest"

if ($releases.tag_name -gt $metadata.Version) {
    Write-Host "Update available: $($releases.tag_name)"
    Write-Host "Current version: $($metadata.Version)"
    Write-Host "Release notes: $($releases.html_url)"
}
```

## Versioning Strategy

### Semantic Versioning

Follow [semver](https://semver.org/) format: `MAJOR.MINOR.PATCH`

```
1.0.0  →  Initial release
1.0.1  →  Bug fix (typo, minor temp adjustment)
1.1.0  →  New feature (added 0.6mm nozzle variant)
2.0.0  →  Breaking change (incompatible with old BambuStudio)
```

### When to Increment

| Change Type | Version Bump | Example |
|-------------|--------------|---------|
| Fix typo in profile | PATCH | `1.0.0` → `1.0.1` |
| Adjust temperature 5°C | PATCH | `1.0.0` → `1.0.1` |
| Add new nozzle variant | MINOR | `1.0.0` → `1.1.0` |
| Add new material type | MINOR | `1.0.0` → `1.1.0` |
| Change setting_id format | MAJOR | `1.0.0` → `2.0.0` |
| Incompatible restructure | MAJOR | `1.0.0` → `2.0.0` |

### Repository vs Profile Versions

**Repository version** (in git tags):
```
git tag v1.0.0
git push --tags
```

**Profile version** (in metadata):
```json
"bsf_metadata": {
    "version": "1.0.0"
}
```

**Recommendation:** Keep them in sync!

## Metadata Operations

### Add Metadata to New Profile

```powershell
# Single file
.\Add-ProfileMetadata.ps1 `
    -Path "profiles\H2D\SUNLU\New Profile.json" `
    -Printer "H2D" `
    -Vendor "SUNLU" `
    -Version "1.1.0"
```

### Bulk Update Existing Profiles

```powershell
# All profiles in directory
.\Add-ProfileMetadata.ps1 `
    -Path "profiles\H2D\SUNLU" `
    -Printer "H2D" `
    -Vendor "SUNLU" `
    -Version "1.0.1" `
    -Force
```

### Preview Changes

```powershell
# Dry run
.\Add-ProfileMetadata.ps1 `
    -Path "profiles\H2D\SUNLU" `
    -Printer "H2D" `
    -Vendor "SUNLU" `
    -WhatIf
```

## Validation

### Required Fields Check

```powershell
$profile = Get-Content "profile.json" | ConvertFrom-Json

# Check all required fields exist
$required = @('managed_by', 'repository_url', 'version', 'printer', 'vendor', 'updated')
$missing = $required | Where-Object { -not $profile.bsf_metadata.$_ }

if ($missing) {
    Write-Warning "Missing fields: $($missing -join ', ')"
}
```

### URL Validation

```powershell
# Verify URL is valid
$url = $profile.bsf_metadata.repository_url

if ($url -match '^https?://') {
    Write-Host "✓ Valid URL format"
} else {
    Write-Warning "Invalid URL: $url"
}

# Check if URL is accessible (optional)
try {
    $response = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 5
    Write-Host "✓ Repository accessible"
} catch {
    Write-Warning "Repository not accessible: $url"
}
```

## Migration from Old Format

If you have profiles with old metadata format:

### Old Format

```json
"bsf_metadata": {
    "managed_by": "BambuStudioFilaments",
    "repository_version": "1.0.0",
    "printer": "H2D",
    "vendor": "SUNLU",
    "last_updated": "2026-01-14"
}
```

### New Format

```json
"bsf_metadata": {
    "managed_by": "BambuStudioFilaments",
    "repository_url": "https://github.com/yourusername/BambuStudioFilaments",
    "version": "1.0.0",
    "printer": "H2D",
    "vendor": "SUNLU",
    "updated": "2026-01-15",
    "testing_status": "tested"
}
```

### Migration Script

```powershell
# Update all profiles to new format
.\Add-ProfileMetadata.ps1 `
    -Path "profiles\H2D\SUNLU" `
    -Printer "H2D" `
    -Vendor "SUNLU" `
    -Force
```

This will:
- Add `repository_url` field
- Rename `repository_version` → `version`
- Rename `last_updated` → `updated`
- Preserve all other data

## Best Practices

### For Contributors

1. **Always add metadata to new profiles**
2. **Use auto-detection for repository URL**
3. **Increment version when modifying profiles**
4. **Update `updated` field on changes**
5. **Test profiles after adding metadata**

### For Maintainers

1. **Validate metadata in CI/CD**
2. **Keep repository URL consistent**
3. **Document version changes in CHANGELOG**
4. **Use git tags for releases**
5. **Verify URLs are accessible**

### For Forks

1. **Update repository URL to your fork**
2. **Keep version numbers distinct**
3. **Credit original repository**
4. **Document divergences**

## See Also

- [METADATA_IMPLEMENTATION.md](METADATA_IMPLEMENTATION.md) - Implementation guide
- [PROFILE_IDENTIFICATION.md](PROFILE_IDENTIFICATION.md) - Identification methods
- [TESTING_STATUS_GUIDE.md](TESTING_STATUS_GUIDE.md) - Testing status organization
- [Adding_Custom_Filaments.md](Adding_Custom_Filaments.md) - Creating profiles
- [CONTRIBUTING.md](../CONTRIBUTING.md) - Contribution guidelines
