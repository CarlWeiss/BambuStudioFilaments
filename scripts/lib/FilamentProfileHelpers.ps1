#Requires -Version 5.1
<#
.SYNOPSIS
    Shared helper functions for BambuStudio filament profile management scripts.

.DESCRIPTION
    This library provides common functions used by both Install-FilamentProfiles.ps1
    and Uninstall-FilamentProfiles.ps1 to maintain consistency and avoid code duplication.
#>

# Color output functions
function Write-Status($Message) {
    Write-Host "[*] $Message" -ForegroundColor Cyan
}

function Write-Success($Message) {
    Write-Host "[+] $Message" -ForegroundColor Green
}

function Write-Warn($Message) {
    Write-Host "[!] $Message" -ForegroundColor Yellow
}

function Write-Err($Message) {
    Write-Host "[-] $Message" -ForegroundColor Red
}

# Function to get available printer configurations from repository
function Get-AvailablePrinters {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ScriptDir
    )

    if (-not (Test-Path $ScriptDir)) {
        throw "Script directory does not exist: $ScriptDir"
    }

    $Printers = @()
    Get-ChildItem -Path $ScriptDir -Directory -ErrorAction Stop | Where-Object {
        $_.Name -notmatch '^\..*' -and $_.Name -ne 'node_modules'
    } | ForEach-Object {
        # Check if it has vendor subdirectories
        $VendorDirs = Get-ChildItem -Path $_.FullName -Directory -ErrorAction SilentlyContinue
        if ($VendorDirs) {
            $Printers += [PSCustomObject]@{
                Name = $_.Name
                Path = $_.FullName
                Vendors = $VendorDirs
            }
        }
    }
    return $Printers
}

# Function to get vendors for a printer configuration
function Get-VendorsForPrinter {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$PrinterPath
    )

    if (-not (Test-Path $PrinterPath)) {
        throw "Printer path does not exist: $PrinterPath"
    }

    $Vendors = @()
    Get-ChildItem -Path $PrinterPath -Directory -ErrorAction Stop | ForEach-Object {
        # Check if it has profile files
        $ProfileFiles = Get-ChildItem -Path $_.FullName -Filter "*.json" -File | Where-Object {
            $_.Name -notlike "*entries*"
        }
        $EntriesFile = Get-ChildItem -Path $_.FullName -Filter "*entries*.json" -File | Select-Object -First 1

        if ($ProfileFiles -and $EntriesFile) {
            $Vendors += [PSCustomObject]@{
                Name = $_.Name
                Path = $_.FullName
                ProfileCount = $ProfileFiles.Count
                EntriesFile = $EntriesFile.FullName
            }
        }
    }
    return $Vendors
}

# Function to extract material type from profile name
function Get-MaterialType {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProfileName
    )

    # Try to extract material type using regex
    if ($ProfileName -match '\b(PLA\+?\s*2\.0|PLA\+|PLA|PETG|ABS|PC|TPU|ASA|PA|PVA)\b') {
        return $matches[1]
    }
    return "Other"
}

# Function to extract clean display name from profile entry
function Get-DisplayName {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProfileName
    )

    $DisplayName = $ProfileName
    # Remove only the printer designation, keeping variant info before AND after
    # Examples:
    #   "SUNLU PLA+ 2.0 HF @BBL H2D" -> "SUNLU PLA+ 2.0 HF"
    #   "SUNLU PLA+ 2.0 @BBL H2D 0.2 nozzle" -> "SUNLU PLA+ 2.0 0.2 nozzle"

    # Match "@BBL <printer_model>" specifically (e.g., "@BBL H2D", "@BBL X1C")
    $DisplayName = $DisplayName -replace '@BBL\s+[A-Z0-9]+\s*', ''

    # Match "@Bambu Lab <printer_model>" (e.g., "@Bambu Lab P1S", "@Bambu Lab X1C")
    $DisplayName = $DisplayName -replace '@Bambu Lab\s+[A-Z0-9]+\s*', ''

    # Generic fallback for other printer designations (removes @<anything> but less aggressive)
    $DisplayName = $DisplayName -replace '@[A-Za-z0-9_-]+\s*', ''

    return $DisplayName.Trim()
}

# Function to show printer selection menu
function Show-PrinterMenu {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Printers
    )

    Write-Host "Available Printer Configurations:" -ForegroundColor Yellow
    Write-Host ""
    for ($i = 0; $i -lt $Printers.Count; $i++) {
        $p = $Printers[$i]
        $vendorCount = $p.Vendors.Count
        Write-Host "  [$($i+1)] $($p.Name)" -ForegroundColor White -NoNewline
        Write-Host " ($vendorCount vendor$(if($vendorCount -ne 1){'s'}))" -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host "  [Q] Quit" -ForegroundColor Gray
    Write-Host ""
}

# Function to show vendor selection menu
function Show-VendorMenu {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Vendors,
        [Parameter(Mandatory=$true)]
        [string]$PrinterName
    )

    Write-Host "Available Vendors for ${PrinterName}:" -ForegroundColor Yellow
    Write-Host ""
    for ($i = 0; $i -lt $Vendors.Count; $i++) {
        $v = $Vendors[$i]
        Write-Host "  [$($i+1)] $($v.Name)" -ForegroundColor White -NoNewline
        Write-Host " ($($v.ProfileCount) profiles)" -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host "  [Q] Quit" -ForegroundColor Gray
    Write-Host ""
}

# Function to group profiles by material type
function Group-ProfilesByMaterial {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Entries
    )

    $ProfileGroups = @{}

    foreach ($Entry in $Entries) {
        $MaterialType = Get-MaterialType -ProfileName $Entry.name

        if (-not $ProfileGroups.ContainsKey($MaterialType)) {
            $ProfileGroups[$MaterialType] = @()
        }
        $ProfileGroups[$MaterialType] += $Entry
    }

    return $ProfileGroups
}

# Function to show profile selection menu
function Show-ProfileMenu {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$ProfileGroups
    )

    $MenuItems = @()
    $Index = 1

    # Build menu
    $SortedGroups = $ProfileGroups.Keys | Sort-Object
    foreach ($GroupName in $SortedGroups) {
        $Group = $ProfileGroups[$GroupName]
        Write-Host "  $GroupName Profiles:" -ForegroundColor Yellow
        foreach ($Entry in $Group) {
            $DisplayName = Get-DisplayName -ProfileName $Entry.name
            Write-Host "    [$Index] $DisplayName" -ForegroundColor White
            $MenuItems += @{
                Index = $Index
                Entry = $Entry
                DisplayName = $DisplayName
            }
            $Index++
        }
        Write-Host ""
    }

    Write-Host "  [A] All profiles" -ForegroundColor Cyan
    Write-Host "  [Q] Quit" -ForegroundColor Gray
    Write-Host ""

    return $MenuItems
}

# Function to resolve user selection (comma-separated numbers)
function Resolve-Selection {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Selection,
        [Parameter(Mandatory=$true)]
        [array]$MenuItems
    )

    $SelectedEntries = @()

    # Parse comma-separated numbers
    $Numbers = $Selection -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' }

    foreach ($Num in $Numbers) {
        $NumInt = [int]$Num
        $MenuItem = $MenuItems | Where-Object { $_.Index -eq $NumInt }
        if ($MenuItem) {
            $SelectedEntries += $MenuItem.Entry
        } else {
            Write-Warn "Invalid selection: $Num (skipping)"
        }
    }

    return $SelectedEntries
}

# All functions are automatically available when dot-sourced
# No Export-ModuleMember needed for dot-sourced scripts
