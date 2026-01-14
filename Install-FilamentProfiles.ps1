#Requires -Version 5.1
<#
.SYNOPSIS
    Installs custom filament profiles for BambuStudio.

.DESCRIPTION
    This script:
    1. Detects available printer configurations in the repository
    2. Allows selection of printer and vendor
    3. Backs up the existing BBL.json file
    4. Copies selected filament profile JSON files to the BambuStudio system directory
    5. Updates BBL.json with the new filament entries

.PARAMETER Printer
    Specify the printer configuration (e.g., "H2D")

.PARAMETER Vendor
    Specify the vendor name (e.g., "SUNLU", "BambuLab")

.PARAMETER All
    Install all available profiles without prompting for selection.

.PARAMETER WhatIf
    Show what would be done without making any changes.

.PARAMETER Force
    Overwrite existing profile files.

.NOTES
    Run this script from the repository root directory.
    BambuStudio should be closed before running this script.
#>

[CmdletBinding()]
param(
    [string]$Printer,
    [string]$Vendor,
    [switch]$All,
    [switch]$WhatIf,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# Import shared helper functions
. (Join-Path $PSScriptRoot "FilamentProfileHelpers.ps1")

# Paths
$ScriptDir = $PSScriptRoot
$BambuStudioDir = Join-Path $env:APPDATA "BambuStudio\system"
$BBLJsonPath = Join-Path $BambuStudioDir "BBL.json"

# Banner
Write-Host ""
Write-Host "=============================================" -ForegroundColor Magenta
Write-Host "  BambuStudio Filament Profile Installer" -ForegroundColor Magenta
Write-Host "=============================================" -ForegroundColor Magenta
Write-Host ""

# Check if BambuStudio directory exists
if (-not (Test-Path $BambuStudioDir)) {
    Write-Err "BambuStudio system directory not found: $BambuStudioDir"
    Write-Err "Please ensure BambuStudio is installed and has been run at least once."
    exit 1
}

if (-not (Test-Path $BBLJsonPath)) {
    Write-Err "BBL.json not found: $BBLJsonPath"
    exit 1
}

# Get available printers
$AvailablePrinters = Get-AvailablePrinters -ScriptDir $ScriptDir

if ($AvailablePrinters.Count -eq 0) {
    Write-Err "No printer configurations found in repository."
    exit 1
}

# Step 1: Select Printer
$SelectedPrinter = $null

if ($Printer) {
    $SelectedPrinter = $AvailablePrinters | Where-Object { $_.Name -eq $Printer }
    if (-not $SelectedPrinter) {
        Write-Err "Printer '$Printer' not found."
        exit 1
    }
} else {
    Show-PrinterMenu -Printers $AvailablePrinters
    $Selection = Read-Host "Select printer configuration"

    if ($Selection -eq 'q' -or $Selection -eq 'Q') {
        Write-Warn "Installation cancelled."
        exit 0
    }

    $SelectionNum = [int]$Selection - 1
    if ($SelectionNum -lt 0 -or $SelectionNum -ge $AvailablePrinters.Count) {
        Write-Err "Invalid selection."
        exit 1
    }

    $SelectedPrinter = $AvailablePrinters[$SelectionNum]
}

Write-Status "Selected printer: $($SelectedPrinter.Name)"
Write-Host ""

# Step 2: Select Vendor
$SelectedVendor = $null
$VendorsForPrinter = Get-VendorsForPrinter -PrinterPath $SelectedPrinter.Path

if ($VendorsForPrinter.Count -eq 0) {
    Write-Err "No vendors found for $($SelectedPrinter.Name)."
    exit 1
}

if ($Vendor) {
    $SelectedVendor = $VendorsForPrinter | Where-Object { $_.Name -eq $Vendor }
    if (-not $SelectedVendor) {
        Write-Err "Vendor '$Vendor' not found for printer '$($SelectedPrinter.Name)'."
        exit 1
    }
} else {
    Show-VendorMenu -Vendors $VendorsForPrinter -PrinterName $SelectedPrinter.Name
    $Selection = Read-Host "Select vendor"

    if ($Selection -eq 'q' -or $Selection -eq 'Q') {
        Write-Warn "Installation cancelled."
        exit 0
    }

    $SelectionNum = [int]$Selection - 1
    if ($SelectionNum -lt 0 -or $SelectionNum -ge $VendorsForPrinter.Count) {
        Write-Err "Invalid selection."
        exit 1
    }

    $SelectedVendor = $VendorsForPrinter[$SelectionNum]
}

Write-Status "Selected vendor: $($SelectedVendor.Name)"
Write-Host ""

# Set paths
$SourceProfilesDir = $SelectedVendor.Path
$EntriesFile = $SelectedVendor.EntriesFile
$DestFilamentDir = Join-Path $BambuStudioDir "BBL\filament\$($SelectedVendor.Name)"

# Load the entries to add to BBL.json
$EntriesData = Get-Content $EntriesFile -Raw | ConvertFrom-Json
$NewEntries = $EntriesData.entries

# Get list of profile files
$ProfileFiles = Get-ChildItem -Path $SourceProfilesDir -Filter "*.json" -File | Where-Object {
    $_.Name -notlike "*entries*"
}

Write-Status "Found $($ProfileFiles.Count) filament profiles"
Write-Status "Found $($NewEntries.Count) BBL.json entries"
Write-Host ""

if ($WhatIf) {
    Write-Warn "WhatIf mode - no changes will be made"
    Write-Host ""
}

# Step 3: Select Profiles
$SelectedEntries = @()
$SelectedFiles = @()

if ($All) {
    $SelectedEntries = $NewEntries
    $SelectedFiles = $ProfileFiles
    Write-Status "Installing all $($ProfileFiles.Count) profiles (-All specified)"
} else {
    # Group profiles by material type for easier selection
    $ProfileGroups = Group-ProfilesByMaterial -Entries $NewEntries

    Write-Host "Select which filament profiles to install:" -ForegroundColor White
    Write-Host "(Enter numbers separated by commas, 'all' for everything, or 'q' to quit)" -ForegroundColor Gray
    Write-Host ""

    # Show menu and get menu items
    $MenuItems = Show-ProfileMenu -ProfileGroups $ProfileGroups

    $Selection = Read-Host "Enter selection"

    if ($Selection -eq 'q' -or $Selection -eq 'Q') {
        Write-Warn "Installation cancelled."
        exit 0
    }

    if ($Selection -eq 'a' -or $Selection -eq 'A' -or $Selection -eq 'all') {
        $SelectedEntries = $NewEntries
        $SelectedFiles = $ProfileFiles
        Write-Status "Installing all $($ProfileFiles.Count) profiles"
    } else {
        # Resolve selection using shared function
        $SelectedEntries = Resolve-Selection -Selection $Selection -MenuItems $MenuItems

        if ($SelectedEntries.Count -eq 0) {
            Write-Err "No valid profiles selected."
            exit 1
        }

        # Get corresponding files
        foreach ($Entry in $SelectedEntries) {
            $FileName = Split-Path $Entry.sub_path -Leaf
            $FilePath = Join-Path $SourceProfilesDir $FileName
            if (Test-Path $FilePath) {
                $SelectedFiles += Get-Item $FilePath
            } else {
                Write-Warn "Profile file not found: $FileName"
            }
        }

        Write-Status "Selected $($SelectedEntries.Count) profiles to install"
    }
}

Write-Host ""

# Step 4: Backup BBL.json
Write-Status "Creating backup of BBL.json..."
$BackupPath = "$BBLJsonPath.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
if (-not $WhatIf) {
    Copy-Item -Path $BBLJsonPath -Destination $BackupPath
    Write-Success "Backup created: $BackupPath"
} else {
    Write-Host "  Would backup to: $BackupPath"
}

# Step 5: Create destination directory if needed
if (-not (Test-Path $DestFilamentDir)) {
    Write-Status "Creating destination directory: $DestFilamentDir"
    if (-not $WhatIf) {
        New-Item -ItemType Directory -Path $DestFilamentDir -Force | Out-Null
        Write-Success "Directory created"
    } else {
        Write-Host "  Would create directory: $DestFilamentDir"
    }
} else {
    Write-Status "Destination directory exists: $DestFilamentDir"
}

# Step 6: Copy filament profile files
Write-Host ""
Write-Status "Copying filament profiles..."
$CopiedCount = 0
foreach ($File in $SelectedFiles) {
    $DestPath = Join-Path $DestFilamentDir $File.Name
    $Exists = Test-Path $DestPath

    if ($Exists -and -not $Force) {
        Write-Warn "Skipping (already exists): $($File.Name)"
        Write-Host "  Use -Force to overwrite existing files" -ForegroundColor Gray
    } else {
        if (-not $WhatIf) {
            Copy-Item -Path $File.FullName -Destination $DestPath -Force
            if ($Exists) {
                Write-Success "Overwritten: $($File.Name)"
            } else {
                Write-Success "Copied: $($File.Name)"
            }
            $CopiedCount++
        } else {
            if ($Exists) {
                Write-Host "  Would overwrite: $($File.Name)"
            } else {
                Write-Host "  Would copy: $($File.Name)"
            }
            $CopiedCount++
        }
    }
}

# Step 7: Update BBL.json
Write-Host ""
Write-Status "Updating BBL.json..."

# Read BBL.json
$BBLContent = Get-Content $BBLJsonPath -Raw
$BBLJson = $BBLContent | ConvertFrom-Json

# Find the filament_list array
if (-not $BBLJson.filament_list) {
    Write-Err "Could not find 'filament_list' in BBL.json"
    exit 1
}

# Get existing entry names to avoid duplicates
$ExistingNames = @{}
foreach ($Entry in $BBLJson.filament_list) {
    $ExistingNames[$Entry.name] = $true
}

# Add new entries
$AddedCount = 0
$SkippedCount = 0
foreach ($NewEntry in $SelectedEntries) {
    if ($ExistingNames.ContainsKey($NewEntry.name)) {
        Write-Warn "Entry already exists, skipping: $($NewEntry.name)"
        $SkippedCount++
    } else {
        if (-not $WhatIf) {
            $EntryObj = [PSCustomObject]@{
                name = $NewEntry.name
                sub_path = $NewEntry.sub_path
            }
            $BBLJson.filament_list += $EntryObj
        }
        Write-Success "Added entry: $($NewEntry.name)"
        $AddedCount++
    }
}

# Write updated BBL.json
if (-not $WhatIf -and $AddedCount -gt 0) {
    $BBLJson | ConvertTo-Json -Depth 100 | Set-Content $BBLJsonPath -Encoding UTF8
    Write-Success "BBL.json updated successfully"
}

# Summary
Write-Host ""
Write-Host "=============================================" -ForegroundColor Magenta
Write-Host "                 Summary" -ForegroundColor Magenta
Write-Host "=============================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Printer:                  $($SelectedPrinter.Name)" -ForegroundColor White
Write-Host "  Vendor:                   $($SelectedVendor.Name)" -ForegroundColor White
Write-Host "  Profile files copied:     $CopiedCount" -ForegroundColor White
Write-Host "  BBL.json entries added:   $AddedCount" -ForegroundColor White
Write-Host "  BBL.json entries skipped: $SkippedCount" -ForegroundColor White
Write-Host "  Backup location: $BackupPath" -ForegroundColor White
Write-Host ""

if ($WhatIf) {
    Write-Warn "This was a dry run. Run without -WhatIf to apply changes."
} else {
    Write-Success "Installation complete!"
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Close BambuStudio if it's running" -ForegroundColor White
    Write-Host "  2. Reopen BambuStudio" -ForegroundColor White
    Write-Host "  3. Your new filament profiles should appear in the AMS settings" -ForegroundColor White
    Write-Host ""
    Write-Host "If profiles don't appear, check the vendor-specific README for" -ForegroundColor Gray
    Write-Host "prerequisites and troubleshooting information." -ForegroundColor Gray
}

Write-Host ""
