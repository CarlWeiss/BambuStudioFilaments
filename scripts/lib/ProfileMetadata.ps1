#Requires -Version 5.1
<#
.SYNOPSIS
    Functions for working with profile metadata (bsf_metadata field).

.DESCRIPTION
    This module provides functions to check, read, and manage the custom
    metadata embedded in profile JSON files for identification and tracking.
#>

function Test-HasProfileMetadata {
    <#
    .SYNOPSIS
        Checks if a profile JSON file has bsf_metadata.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProfilePath
    )

    if (-not (Test-Path $ProfilePath)) {
        return $false
    }

    try {
        $content = Get-Content $ProfilePath -Raw
        $profileData = $content | ConvertFrom-Json

        return ($profileData.PSObject.Properties.Name -contains 'bsf_metadata')
    } catch {
        Write-Warning "Failed to read profile: $ProfilePath - $($_.Exception.Message)"
        return $false
    }
}

function Get-ProfileMetadata {
    <#
    .SYNOPSIS
        Reads the bsf_metadata from a profile JSON file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProfilePath
    )

    if (-not (Test-Path $ProfilePath)) {
        Write-Warning "Profile not found: $ProfilePath"
        return $null
    }

    try {
        $content = Get-Content $ProfilePath -Raw
        $profileData = $content | ConvertFrom-Json

        if ($profileData.PSObject.Properties.Name -contains 'bsf_metadata') {
            return [PSCustomObject]@{
                ManagedBy = $profileData.bsf_metadata.managed_by
                RepositoryVersion = $profileData.bsf_metadata.version
                RepositoryUrl = $profileData.bsf_metadata.repository_url
                Printer = $profileData.bsf_metadata.printer
                Vendor = $profileData.bsf_metadata.vendor
                LastUpdated = $profileData.bsf_metadata.updated
                TestingStatus = $profileData.bsf_metadata.testing_status
                TestingNotes = $profileData.bsf_metadata.testing_notes
                InstallDate = $profileData.bsf_metadata.install_date
                ProfileName = $profileData.name
                SettingId = $profileData.setting_id
                FilePath = $ProfilePath
            }
        }

        return $null
    } catch {
        Write-Warning "Failed to read profile metadata: $ProfilePath - $($_.Exception.Message)"
        return $null
    }
}

function Test-IsManagedProfile {
    <#
    .SYNOPSIS
        Checks if a profile is managed by BambuStudioFilaments repository.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Path')]
        [string]$ProfilePath,

        [Parameter(Mandatory, ParameterSetName = 'Name')]
        [string]$ProfileName,

        [Parameter(ParameterSetName = 'Name')]
        [string]$BambuStudioDir = (Join-Path $env:APPDATA "BambuStudio\system")
    )

    if ($PSCmdlet.ParameterSetName -eq 'Name') {
        # Find profile by name in BambuStudio
        $bblJsonPath = Join-Path $BambuStudioDir "BBL.json"

        if (-not (Test-Path $bblJsonPath)) {
            Write-Warning "BBL.json not found"
            return $false
        }

        $bblJson = Get-Content $bblJsonPath -Raw | ConvertFrom-Json
        $entry = $bblJson.filament_list | Where-Object { $_.name -eq $ProfileName } | Select-Object -First 1

        if (-not $entry) {
            Write-Warning "Profile not found in BBL.json: $ProfileName"
            return $false
        }

        $ProfilePath = Join-Path $BambuStudioDir $entry.sub_path
    }

    $metadata = Get-ProfileMetadata -ProfilePath $ProfilePath

    return ($metadata -and $metadata.ManagedBy -eq "BambuStudioFilaments")
}

function Find-ManagedProfiles {
    <#
    .SYNOPSIS
        Scans BambuStudio for all profiles managed by this repository.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$BambuStudioDir = (Join-Path $env:APPDATA "BambuStudio\system"),

        [Parameter()]
        [string]$Printer,

        [Parameter()]
        [string]$Vendor
    )

    $bblJsonPath = Join-Path $BambuStudioDir "BBL.json"

    if (-not (Test-Path $bblJsonPath)) {
        Write-Warning "BBL.json not found. BambuStudio may not be installed."
        return @()
    }

    $bblJson = Get-Content $bblJsonPath -Raw | ConvertFrom-Json
    $managedProfiles = @()

    foreach ($entry in $bblJson.filament_list) {
        $filePath = Join-Path $BambuStudioDir $entry.sub_path

        if (Test-Path $filePath) {
            $metadata = Get-ProfileMetadata -ProfilePath $filePath

            if ($metadata -and $metadata.ManagedBy -eq "BambuStudioFilaments") {
                # Apply filters if specified
                $include = $true

                if ($Printer -and $metadata.Printer -ne $Printer) {
                    $include = $false
                }

                if ($Vendor -and $metadata.Vendor -ne $Vendor) {
                    $include = $false
                }

                if ($include) {
                    $managedProfiles += $metadata
                }
            }
        }
    }

    return $managedProfiles
}

function Get-ProfilesWithoutMetadata {
    <#
    .SYNOPSIS
        Finds profile JSON files in the repository that don't have bsf_metadata.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ProfilesPath = (Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "profiles")
    )

    $profilesWithoutMetadata = @()

    $allProfiles = Get-ChildItem -Path $ProfilesPath -Filter "*.json" -Recurse | Where-Object {
        $_.Name -notlike "*entries*" -and
        $_.Name -notlike "*registry*" -and
        $_.FullName -notmatch '[\\\/]\.git[\\\/]'
    }

    foreach ($file in $allProfiles) {
        if (-not (Test-HasProfileMetadata -ProfilePath $file.FullName)) {
            # Try to determine printer/vendor from path
            $relativePath = $file.FullName -replace [regex]::Escape($ProfilesPath), ''
            $pathParts = $relativePath -split '[\\\/]' | Where-Object { $_ -ne '' }

            $printer = if ($pathParts.Count -ge 1) { $pathParts[0] } else { "Unknown" }
            $vendor = if ($pathParts.Count -ge 2) { $pathParts[1] } else { "Unknown" }

            $profilesWithoutMetadata += [PSCustomObject]@{
                FilePath = $file.FullName
                FileName = $file.Name
                Printer = $printer
                Vendor = $vendor
                RelativePath = $relativePath
            }
        }
    }

    return $profilesWithoutMetadata
}

function Compare-ProfileVersions {
    <#
    .SYNOPSIS
        Compares installed profile versions with repository versions.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$BambuStudioDir = (Join-Path $env:APPDATA "BambuStudio\system"),

        [Parameter()]
        [string]$ProfilesPath = (Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "profiles")
    )

    $installed = Find-ManagedProfiles -BambuStudioDir $BambuStudioDir
    $comparison = @()

    foreach ($installedProfile in $installed) {
        # Find corresponding file in repository
        $repoPath = Join-Path $ProfilesPath "$($installedProfile.Printer)\$($installedProfile.Vendor)"
        $repoFile = Get-ChildItem -Path $repoPath -Filter "*$($installedProfile.ProfileName)*" -ErrorAction SilentlyContinue | Select-Object -First 1

        if ($repoFile) {
            $repoMetadata = Get-ProfileMetadata -ProfilePath $repoFile.FullName

            $comparison += [PSCustomObject]@{
                ProfileName = $installedProfile.ProfileName
                Printer = $installedProfile.Printer
                Vendor = $installedProfile.Vendor
                InstalledVersion = $installedProfile.RepositoryVersion
                RepoVersion = $repoMetadata.RepositoryVersion
                UpdateAvailable = ($repoMetadata.RepositoryVersion -ne $installedProfile.RepositoryVersion)
                InstalledDate = $installedProfile.InstallDate
                LastUpdated = $repoMetadata.LastUpdated
            }
        } else {
            $comparison += [PSCustomObject]@{
                ProfileName = $installedProfile.ProfileName
                Printer = $installedProfile.Printer
                Vendor = $installedProfile.Vendor
                InstalledVersion = $installedProfile.RepositoryVersion
                RepoVersion = "Not found"
                UpdateAvailable = $false
                InstalledDate = $installedProfile.InstallDate
                LastUpdated = $null
            }
        }
    }

    return $comparison
}

# Export functions
Export-ModuleMember -Function @(
    'Test-HasProfileMetadata',
    'Get-ProfileMetadata',
    'Test-IsManagedProfile',
    'Find-ManagedProfiles',
    'Get-ProfilesWithoutMetadata',
    'Compare-ProfileVersions'
)
