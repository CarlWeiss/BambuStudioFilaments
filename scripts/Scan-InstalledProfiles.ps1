#Requires -Version 5.1
<#
.SYNOPSIS
    Scans BambuStudio for all custom profiles installed from this repository.

.DESCRIPTION
    This script scans your BambuStudio installation and identifies all custom profiles
    that were installed from this repository, regardless of printer or vendor.

    Useful for:
    - Auditing what's currently installed
    - Identifying orphaned profiles
    - Planning bulk removals
    - Verifying installations

.PARAMETER Printer
    Optional: Filter to a specific printer (e.g., "H2D", "X1C", "P1S")

.PARAMETER Vendor
    Optional: Filter to a specific vendor (e.g., "SUNLU", "eSUN", "Polymaker")

.PARAMETER ShowFiles
    Show file paths and existence status for each profile.

.PARAMETER CheckOrphans
    Check for orphaned BBL.json entries (entries without files) and files without entries.

.EXAMPLE
    .\Scan-InstalledProfiles.ps1
    Scans for all installed custom profiles.

.EXAMPLE
    .\Scan-InstalledProfiles.ps1 -Printer H2D
    Shows only H2D profiles.

.EXAMPLE
    .\Scan-InstalledProfiles.ps1 -Vendor SUNLU
    Shows only SUNLU profiles across all printers.

.EXAMPLE
    .\Scan-InstalledProfiles.ps1 -CheckOrphans
    Checks for orphaned entries and files.

.NOTES
    This script uses the central profile registry to identify custom profiles.
    It works across all printers and vendors defined in the repository.
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$Printer,

    [Parameter()]
    [string]$Vendor,

    [Parameter()]
    [switch]$ShowFiles,

    [Parameter()]
    [switch]$CheckOrphans
)

# Import registry functions
. (Join-Path $PSScriptRoot "lib\ProfileRegistry.ps1")
. (Join-Path $PSScriptRoot "lib\FilamentProfileHelpers.ps1")

# Banner
Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Custom Profile Scanner" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Check BambuStudio
$bambuStudioDir = Join-Path $env:APPDATA "BambuStudio\system"
$bblJsonPath = Join-Path $bambuStudioDir "BBL.json"

if (-not (Test-Path $bblJsonPath)) {
    Write-Err "BambuStudio system directory not found: $bambuStudioDir"
    Write-Err "Please ensure BambuStudio is installed and has been run at least once."
    exit 1
}

Write-Status "Scanning BambuStudio installation..."
Write-Host "  Location: $bambuStudioDir" -ForegroundColor Gray
Write-Host ""

# Get installed profiles
$installed = Get-InstalledCustomProfiles -Printer $Printer -Vendor $Vendor

if ($installed.Count -eq 0) {
    Write-Warn "No custom profiles found from this repository."

    if ($Printer -or $Vendor) {
        $filter = @()
        if ($Printer) { $filter += "Printer: $Printer" }
        if ($Vendor) { $filter += "Vendor: $Vendor" }
        Write-Host "  Filters: $($filter -join ', ')" -ForegroundColor Gray
    }

    Write-Host ""
    Write-Host "If you expected to find profiles, verify:" -ForegroundColor Yellow
    Write-Host "  1. Profiles were installed using the Install script" -ForegroundColor White
    Write-Host "  2. The profile registry is up to date" -ForegroundColor White
    Write-Host "  3. BambuStudio hasn't been reinstalled" -ForegroundColor White
    Write-Host ""
    exit 0
}

# Group by printer and vendor
$grouped = $installed | Group-Object Printer, Vendor

# Display results
Write-Success "Found $($installed.Count) custom profile(s)"
Write-Host ""

foreach ($group in $grouped) {
    $parts = $group.Name -split ', '
    $printerName = $parts[0]
    $vendorName = $parts[1]

    Write-Host "  $printerName / $vendorName" -ForegroundColor Cyan
    Write-Host "  $('─' * 60)" -ForegroundColor DarkGray

    foreach ($profile in $group.Group) {
        $icon = if ($profile.Exists) { "✓" } else { "✗" }
        $color = if ($profile.Exists) { "Green" } else { "Red" }

        Write-Host "    [$icon] $($profile.ProfileName)" -ForegroundColor $color

        if ($ShowFiles) {
            Write-Host "        File: $($profile.FilePath)" -ForegroundColor Gray
            if (-not $profile.Exists) {
                Write-Host "        Status: FILE MISSING" -ForegroundColor Red
            }
        }
    }

    Write-Host ""
}

# Check for orphans
if ($CheckOrphans) {
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host "  Orphan Check" -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host ""

    # Orphaned entries (in BBL.json but file doesn't exist)
    $orphanedEntries = $installed | Where-Object { -not $_.Exists }

    if ($orphanedEntries.Count -gt 0) {
        Write-Warn "Found $($orphanedEntries.Count) orphaned BBL.json entries:"
        foreach ($orphan in $orphanedEntries) {
            Write-Host "  [!] $($orphan.ProfileName)" -ForegroundColor Yellow
            Write-Host "      Expected: $($orphan.FilePath)" -ForegroundColor Gray
        }
        Write-Host ""
        Write-Host "These entries reference files that don't exist." -ForegroundColor Gray
        Write-Host "You can remove them using the Uninstall script." -ForegroundColor Gray
    } else {
        Write-Success "No orphaned BBL.json entries found"
    }

    Write-Host ""

    # Orphaned files (files exist but not in BBL.json)
    # Scan the actual file system
    $registry = Get-ProfileRegistry
    $orphanedFiles = @()

    foreach ($printerName in $registry.profiles.PSObject.Properties.Name) {
        $printer = $registry.profiles.$printerName

        foreach ($vendorName in $printer.PSObject.Properties.Name) {
            $vendor = $printer.$vendorName
            $vendorDir = Join-Path $bambuStudioDir "BBL\filament\$vendorName"

            if (Test-Path $vendorDir) {
                # Get all JSON files matching the pattern
                $pattern = $vendor.name_pattern -replace '\*', '*'
                $files = Get-ChildItem -Path $vendorDir -Filter "*.json" | Where-Object {
                    $_.Name -like ($pattern -replace '.*/', '')
                }

                foreach ($file in $files) {
                    # Check if this file is in our installed list
                    $inBblJson = $installed | Where-Object {
                        $_.FilePath -eq $file.FullName
                    }

                    if (-not $inBblJson) {
                        $orphanedFiles += [PSCustomObject]@{
                            Printer = $printerName
                            Vendor = $vendorName
                            FileName = $file.Name
                            FilePath = $file.FullName
                        }
                    }
                }
            }
        }
    }

    if ($orphanedFiles.Count -gt 0) {
        Write-Warn "Found $($orphanedFiles.Count) orphaned file(s):"
        foreach ($orphan in $orphanedFiles) {
            Write-Host "  [!] $($orphan.Printer)/$($orphan.Vendor): $($orphan.FileName)" -ForegroundColor Yellow
            Write-Host "      Path: $($orphan.FilePath)" -ForegroundColor Gray
        }
        Write-Host ""
        Write-Host "These files exist but aren't registered in BBL.json." -ForegroundColor Gray
        Write-Host "They won't appear in BambuStudio." -ForegroundColor Gray
    } else {
        Write-Success "No orphaned files found"
    }

    Write-Host ""
}

# Summary
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Summary" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

$byPrinter = $installed | Group-Object Printer
Write-Host "  Printers:" -ForegroundColor White
foreach ($group in $byPrinter) {
    Write-Host "    - $($group.Name): $($group.Count) profiles" -ForegroundColor Gray
}
Write-Host ""

$byVendor = $installed | Group-Object Vendor
Write-Host "  Vendors:" -ForegroundColor White
foreach ($group in $byVendor) {
    Write-Host "    - $($group.Name): $($group.Count) profiles" -ForegroundColor Gray
}
Write-Host ""

$missing = ($installed | Where-Object { -not $_.Exists }).Count
if ($missing -gt 0) {
    Write-Host "  Missing files: $missing" -ForegroundColor Red
} else {
    Write-Host "  All files present: ✓" -ForegroundColor Green
}

Write-Host ""
Write-Host "Use .\Uninstall-FilamentProfiles.ps1 to remove profiles." -ForegroundColor Yellow
Write-Host ""
