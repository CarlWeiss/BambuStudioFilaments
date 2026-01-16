#Requires -Version 5.1
<#
.SYNOPSIS
    Profile registry management functions for tracking custom profiles across multiple printers and vendors.

.DESCRIPTION
    This module provides functions to:
    - Load and query the central profile registry
    - Identify custom profiles regardless of printer/vendor
    - Generate dynamic patterns for profile detection
    - Support scalable multi-printer/multi-vendor scenarios
#>

function Get-ProfileRegistry {
    <#
    .SYNOPSIS
        Loads the central profile registry.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$RegistryPath = (Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "profiles\profile-registry.json")
    )

    if (-not (Test-Path $RegistryPath)) {
        Write-Warning "Profile registry not found at: $RegistryPath"
        return $null
    }

    try {
        $content = Get-Content $RegistryPath -Raw
        $registry = $content | ConvertFrom-Json
        return $registry
    } catch {
        Write-Error "Failed to load profile registry: $($_.Exception.Message)"
        return $null
    }
}

function Get-AllCustomProfiles {
    <#
    .SYNOPSIS
        Gets a list of all custom profiles across all printers and vendors.
    #>
    [CmdletBinding()]
    param()

    $registry = Get-ProfileRegistry
    if (-not $registry) {
        return @()
    }

    $allProfiles = @()

    foreach ($printerName in $registry.profiles.PSObject.Properties.Name) {
        $printer = $registry.profiles.$printerName

        foreach ($vendorName in $printer.PSObject.Properties.Name) {
            $vendor = $printer.$vendorName

            foreach ($profileName in $vendor.profiles) {
                $allProfiles += [PSCustomObject]@{
                    Printer = $printerName
                    Vendor = $vendorName
                    ProfileName = $profileName
                    NamePattern = $vendor.name_pattern
                    SettingIdPattern = $vendor.setting_id_pattern
                    DestinationPath = $vendor.destination_path
                }
            }
        }
    }

    return $allProfiles
}

function Get-ProfilesForPrinter {
    <#
    .SYNOPSIS
        Gets all profiles for a specific printer.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Printer
    )

    $registry = Get-ProfileRegistry
    if (-not $registry) {
        return @()
    }

    if (-not $registry.profiles.$Printer) {
        Write-Warning "No profiles found for printer: $Printer"
        return @()
    }

    $profiles = @()
    $printerObj = $registry.profiles.$Printer

    foreach ($vendorName in $printerObj.PSObject.Properties.Name) {
        $vendor = $printerObj.$vendorName

        foreach ($profileName in $vendor.profiles) {
            $profiles += [PSCustomObject]@{
                Vendor = $vendorName
                ProfileName = $profileName
                NamePattern = $vendor.name_pattern
                SettingIdPattern = $vendor.setting_id_pattern
                DestinationPath = $vendor.destination_path
            }
        }
    }

    return $profiles
}

function Get-ProfilesForVendor {
    <#
    .SYNOPSIS
        Gets all profiles for a specific printer/vendor combination.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Printer,

        [Parameter(Mandatory)]
        [string]$Vendor
    )

    $registry = Get-ProfileRegistry
    if (-not $registry) {
        return @()
    }

    if (-not $registry.profiles.$Printer) {
        Write-Warning "No profiles found for printer: $Printer"
        return @()
    }

    if (-not $registry.profiles.$Printer.$Vendor) {
        Write-Warning "No profiles found for vendor: $Vendor on printer: $Printer"
        return @()
    }

    $vendorObj = $registry.profiles.$Printer.$Vendor

    return [PSCustomObject]@{
        Description = $vendorObj.description
        Count = $vendorObj.count
        EntriesFile = $vendorObj.entries_file
        Materials = $vendorObj.materials
        NamePattern = $vendorObj.name_pattern
        SettingIdPattern = $vendorObj.setting_id_pattern
        DestinationPath = $vendorObj.destination_path
        Profiles = $vendorObj.profiles
    }
}

function Test-IsCustomProfile {
    <#
    .SYNOPSIS
        Checks if a profile name or setting_id matches patterns from this repository.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProfileName,

        [Parameter()]
        [string]$SettingId,

        [Parameter()]
        [string]$Printer
    )

    $registry = Get-ProfileRegistry
    if (-not $registry) {
        return $false
    }

    # If printer specified, check only that printer's patterns
    if ($Printer) {
        $profiles = Get-ProfilesForPrinter -Printer $Printer
        foreach ($profile in $profiles) {
            if ($ProfileName -like $profile.NamePattern) {
                return $true
            }
            if ($SettingId -and $SettingId -like $profile.SettingIdPattern) {
                return $true
            }
        }
    } else {
        # Check all printers
        $allProfiles = Get-AllCustomProfiles
        foreach ($profile in $allProfiles) {
            if ($ProfileName -like $profile.NamePattern) {
                return $true
            }
            if ($SettingId -and $SettingId -like $profile.SettingIdPattern) {
                return $true
            }
        }
    }

    return $false
}

function Get-InstalledCustomProfiles {
    <#
    .SYNOPSIS
        Scans BambuStudio directory for installed custom profiles from this repository.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Printer,

        [Parameter()]
        [string]$Vendor
    )

    $bambuStudioDir = Join-Path $env:APPDATA "BambuStudio\system"
    $bblJsonPath = Join-Path $bambuStudioDir "BBL.json"

    if (-not (Test-Path $bblJsonPath)) {
        Write-Warning "BBL.json not found. BambuStudio may not be installed."
        return @()
    }

    $bblJson = Get-Content $bblJsonPath -Raw | ConvertFrom-Json
    $installed = @()

    # Get patterns to search for
    if ($Printer -and $Vendor) {
        $vendorInfo = Get-ProfilesForVendor -Printer $Printer -Vendor $Vendor
        $patterns = @([PSCustomObject]@{
            Printer = $Printer
            Vendor = $Vendor
            NamePattern = $vendorInfo.NamePattern
            Profiles = $vendorInfo.Profiles
        })
    } elseif ($Printer) {
        $profiles = Get-ProfilesForPrinter -Printer $Printer
        $patterns = $profiles | Group-Object Vendor | ForEach-Object {
            [PSCustomObject]@{
                Printer = $Printer
                Vendor = $_.Name
                NamePattern = $_.Group[0].NamePattern
                Profiles = $_.Group.ProfileName
            }
        }
    } else {
        # Search all
        $allProfiles = Get-AllCustomProfiles
        $patterns = $allProfiles | Group-Object Printer, Vendor | ForEach-Object {
            $parts = $_.Name -split ', '
            [PSCustomObject]@{
                Printer = $parts[0]
                Vendor = $parts[1]
                NamePattern = $_.Group[0].NamePattern
                Profiles = $_.Group.ProfileName
            }
        }
    }

    # Search BBL.json for matching entries
    foreach ($pattern in $patterns) {
        foreach ($entry in $bblJson.filament_list) {
            if ($entry.name -in $pattern.Profiles) {
                # Check if file exists
                $filePath = Join-Path $bambuStudioDir $entry.sub_path
                $installed += [PSCustomObject]@{
                    Printer = $pattern.Printer
                    Vendor = $pattern.Vendor
                    ProfileName = $entry.name
                    FilePath = $filePath
                    Exists = (Test-Path $filePath)
                    Entry = $entry
                }
            }
        }
    }

    return $installed
}

function Update-ProfileRegistry {
    <#
    .SYNOPSIS
        Automatically updates the registry by scanning the profiles directory.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ProfilesPath = (Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "profiles")
    )

    Write-Verbose "Scanning profiles directory: $ProfilesPath"

    $registry = Get-ProfileRegistry
    if (-not $registry) {
        Write-Error "Failed to load existing registry"
        return
    }

    # Scan for printer directories
    $printerDirs = Get-ChildItem -Path $ProfilesPath -Directory | Where-Object {
        $_.Name -ne 'testdata' -and $_.Name -notmatch '^\.'
    }

    foreach ($printerDir in $printerDirs) {
        $printerName = $printerDir.Name

        # Initialize printer if not exists
        if (-not $registry.profiles.PSObject.Properties.Name.Contains($printerName)) {
            $registry.profiles | Add-Member -NotePropertyName $printerName -NotePropertyValue ([PSCustomObject]@{})
        }

        # Scan for vendor directories
        $vendorDirs = Get-ChildItem -Path $printerDir.FullName -Directory

        foreach ($vendorDir in $vendorDirs) {
            $vendorName = $vendorDir.Name

            # Look for entries file
            $entriesFile = Join-Path $vendorDir.FullName "bbl_json_entries.json"
            if (-not (Test-Path $entriesFile)) {
                Write-Warning "No bbl_json_entries.json found for $printerName/$vendorName"
                continue
            }

            # Read entries
            $entriesData = Get-Content $entriesFile -Raw | ConvertFrom-Json
            $profileNames = $entriesData.entries | ForEach-Object { $_.name }

            # Update registry
            if (-not $registry.profiles.$printerName.PSObject.Properties.Name.Contains($vendorName)) {
                $registry.profiles.$printerName | Add-Member -NotePropertyName $vendorName -NotePropertyValue ([PSCustomObject]@{
                    description = "Custom profiles for $vendorName on $printerName"
                    count = $profileNames.Count
                    entries_file = "profiles/$printerName/$vendorName/bbl_json_entries.json"
                    materials = @()
                    name_pattern = "*@BBL $printerName*"
                    setting_id_pattern = "*_$printerName*"
                    destination_path = "filament/$vendorName/"
                    profiles = $profileNames
                })
            } else {
                # Update existing entry
                $registry.profiles.$printerName.$vendorName.count = $profileNames.Count
                $registry.profiles.$printerName.$vendorName.profiles = $profileNames
            }

            Write-Verbose "Updated: $printerName/$vendorName ($($profileNames.Count) profiles)"
        }
    }

    return $registry
}

# Export functions
Export-ModuleMember -Function @(
    'Get-ProfileRegistry',
    'Get-AllCustomProfiles',
    'Get-ProfilesForPrinter',
    'Get-ProfilesForVendor',
    'Test-IsCustomProfile',
    'Get-InstalledCustomProfiles',
    'Update-ProfileRegistry'
)
