#Requires -Version 5.1
<#
.SYNOPSIS
    Removes custom filament profiles from BambuStudio.

.DESCRIPTION
    This script:
    1. Detects installed printer configurations
    2. Allows selection of printer and vendor
    3. Backs up the existing BBL.json file
    4. Removes filament profile JSON files from the BambuStudio system directory
    5. Removes the corresponding entries from BBL.json

.PARAMETER Printer
    Specify the printer configuration (e.g., "H2D", "P1S_ObsidianHF")

.PARAMETER Vendor
    Specify the vendor name (e.g., "SUNLU", "BambuLab")

.PARAMETER All
    Remove all profiles for the selected vendor without prompting for selection.

.PARAMETER WhatIf
    Show what would be done without making any changes.

.NOTES
    Run this script from the repository root directory.
    BambuStudio should be closed before running this script.
#>

[CmdletBinding()]
param(
    [string]$Printer,
    [string]$Vendor,
    [switch]$All,
    [switch]$WhatIf
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
Write-Host "==============================================" -ForegroundColor Magenta
Write-Host "  BambuStudio Filament Profile Uninstaller" -ForegroundColor Magenta
Write-Host "==============================================" -ForegroundColor Magenta
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
        Write-Warn "Uninstallation cancelled."
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
        Write-Warn "Uninstallation cancelled."
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
$EntriesFile = $SelectedVendor.EntriesFile
$DestFilamentDir = Join-Path $BambuStudioDir "BBL\filament\$($SelectedVendor.Name)"

# Load the entries to remove
$EntriesData = Get-Content $EntriesFile -Raw | ConvertFrom-Json
$AllEntries = $EntriesData.entries

# Build list of installed files
$InstalledFiles = @()
$InstalledEntries = @()

foreach ($Entry in $AllEntries) {
    $FileName = Split-Path $Entry.sub_path -Leaf
    $FilePath = Join-Path $DestFilamentDir $FileName
    if (Test-Path $FilePath) {
        $InstalledFiles += @{
            Path = $FilePath
            Name = $FileName
            Entry = $Entry
        }
        $InstalledEntries += $Entry
    }
}

if ($InstalledFiles.Count -eq 0) {
    Write-Warn "No installed profiles found for $($SelectedVendor.Name) on $($SelectedPrinter.Name)"
    Write-Host ""
    Write-Host "Nothing to uninstall." -ForegroundColor Gray
    exit 0
}

Write-Status "Found $($InstalledFiles.Count) installed profile files"
Write-Host ""

if ($WhatIf) {
    Write-Warn "WhatIf mode - no changes will be made"
    Write-Host ""
}

# Step 3: Select Profiles to Remove
$SelectedEntries = @()
$SelectedFiles = @()

if ($All) {
    $SelectedEntries = $InstalledEntries
    $SelectedFiles = $InstalledFiles
    Write-Status "Removing all $($InstalledFiles.Count) profiles (-All specified)"
} else {
    # Group profiles by material type for easier selection
    $ProfileGroups = Group-ProfilesByMaterial -Entries $InstalledEntries

    Write-Host "Select which filament profiles to remove:" -ForegroundColor White
    Write-Host "(Enter numbers separated by commas, 'all' for everything, or 'q' to quit)" -ForegroundColor Gray
    Write-Host ""

    # Show menu and get menu items
    $MenuItems = Show-ProfileMenu -ProfileGroups $ProfileGroups

    $Selection = Read-Host "Enter selection"

    if ($Selection -eq 'q' -or $Selection -eq 'Q') {
        Write-Warn "Uninstallation cancelled."
        exit 0
    }

    if ($Selection -eq 'a' -or $Selection -eq 'A' -or $Selection -eq 'all') {
        $SelectedEntries = $InstalledEntries
        $SelectedFiles = $InstalledFiles
        Write-Status "Removing all $($InstalledFiles.Count) profiles"
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
            $FileItem = $InstalledFiles | Where-Object { $_.Name -eq $FileName }
            if ($FileItem) {
                $SelectedFiles += $FileItem
            }
        }

        Write-Status "Selected $($SelectedEntries.Count) profiles to remove"
    }
}

Write-Host ""

# Confirm
if (-not $WhatIf) {
    Write-Host "Are you sure you want to remove these profiles?" -ForegroundColor Yellow
    $Confirm = Read-Host "(y/N)"
    if ($Confirm -ne 'y' -and $Confirm -ne 'Y') {
        Write-Warn "Cancelled by user"
        exit 0
    }
    Write-Host ""
}

# Step 4: Backup BBL.json
Write-Status "Creating backup of BBL.json..."
$BackupPath = "$BBLJsonPath.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
if (-not $WhatIf) {
    Copy-Item -Path $BBLJsonPath -Destination $BackupPath
    Write-Success "Backup created: $BackupPath"
} else {
    Write-Host "  Would backup to: $BackupPath"
}

# Step 5: Remove filament profile files
Write-Host ""
Write-Status "Removing filament profiles..."
$RemovedFiles = 0
foreach ($FileItem in $SelectedFiles) {
    if (-not $WhatIf) {
        Remove-Item -Path $FileItem.Path -Force
        Write-Success "Removed: $($FileItem.Name)"
    } else {
        Write-Host "  Would remove: $($FileItem.Name)"
    }
    $RemovedFiles++
}

# Step 6: Update BBL.json
Write-Host ""
Write-Status "Updating BBL.json..."

$BBLContent = Get-Content $BBLJsonPath -Raw
$BBLJson = $BBLContent | ConvertFrom-Json

if (-not $BBLJson.filament_list) {
    Write-Err "Could not find 'filament_list' in BBL.json"
    exit 1
}

# Build set of names to remove
$NamesToRemove = @{}
foreach ($Entry in $SelectedEntries) {
    $NamesToRemove[$Entry.name] = $true
}

# Filter out entries to remove
$FilteredList = @()
$RemovedEntries = 0

foreach ($Entry in $BBLJson.filament_list) {
    if ($NamesToRemove.ContainsKey($Entry.name)) {
        Write-Success "Removed entry: $($Entry.name)"
        $RemovedEntries++
    } else {
        $FilteredList += $Entry
    }
}

# Write updated BBL.json
if (-not $WhatIf -and $RemovedEntries -gt 0) {
    $BBLJson.filament_list = $FilteredList
    $BBLJson | ConvertTo-Json -Depth 100 | Set-Content $BBLJsonPath -Encoding UTF8
    Write-Success "BBL.json updated successfully"
}

# Summary
Write-Host ""
Write-Host "==============================================" -ForegroundColor Magenta
Write-Host "                 Summary" -ForegroundColor Magenta
Write-Host "==============================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Printer:                  $($SelectedPrinter.Name)" -ForegroundColor White
Write-Host "  Vendor:                   $($SelectedVendor.Name)" -ForegroundColor White
Write-Host "  Profile files removed:    $RemovedFiles" -ForegroundColor White
Write-Host "  BBL.json entries removed: $RemovedEntries" -ForegroundColor White
Write-Host "  Backup location: $BackupPath" -ForegroundColor White
Write-Host ""

if ($WhatIf) {
    Write-Warn "This was a dry run. Run without -WhatIf to apply changes."
} else {
    Write-Success "Uninstallation complete!"
    Write-Host ""
    Write-Host "Restart BambuStudio for changes to take effect." -ForegroundColor Yellow
}

Write-Host ""
