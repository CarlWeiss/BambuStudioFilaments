#Requires -Version 5.1
<#
.SYNOPSIS
    Adds custom metadata to profile JSON files for identification.

.DESCRIPTION
    This script adds bsf_metadata and custom_attr fields to profile JSON files,
    making them easily identifiable as profiles managed by this repository.

.PARAMETER Path
    Path to a profile JSON file or directory containing profiles.

.PARAMETER Printer
    Printer model (e.g., "H2D", "X1C")

.PARAMETER Vendor
    Vendor name (e.g., "SUNLU", "eSUN")

.PARAMETER Version
    Repository version (defaults to "1.0.0")

.PARAMETER RepositoryUrl
    Git repository URL (auto-detected from git remote if not specified)

.PARAMETER TestingStatus
    Testing status: tested, beta, untested, or experimental (defaults to "untested")

.PARAMETER WhatIf
    Show what would be changed without modifying files.

.PARAMETER Force
    Overwrite existing metadata.

.EXAMPLE
    .\Add-ProfileMetadata.ps1 -Path "profiles\H2D\SUNLU" -Printer "H2D" -Vendor "SUNLU"
    Adds metadata to all profiles in the SUNLU H2D directory.

.EXAMPLE
    .\Add-ProfileMetadata.ps1 -Path "profiles\H2D\SUNLU\SUNLU PLA @BBL H2D.json" -Printer "H2D" -Vendor "SUNLU"
    Adds metadata to a single profile file.

.NOTES
    This script is safe - BambuStudio ignores unknown JSON fields.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Path,

    [Parameter(Mandatory)]
    [string]$Printer,

    [Parameter(Mandatory)]
    [string]$Vendor,

    [Parameter()]
    [string]$Version = "1.0.0",

    [Parameter()]
    [string]$RepositoryUrl,

    [Parameter()]
    [ValidateSet('tested', 'beta', 'untested', 'experimental')]
    [string]$TestingStatus = 'untested',

    [Parameter()]
    [switch]$WhatIf,

    [Parameter()]
    [switch]$Force
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Profile Metadata Manager" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Auto-detect repository URL from git if not specified
if (-not $RepositoryUrl) {
    try {
        $gitRemote = git remote get-url origin 2>$null
        if ($gitRemote) {
            # Convert SSH to HTTPS if needed
            if ($gitRemote -match '^git@github\.com:(.+)\.git$') {
                $RepositoryUrl = "https://github.com/$($Matches[1])"
            } elseif ($gitRemote -match '^https://github\.com/(.+)(\.git)?$') {
                $RepositoryUrl = "https://github.com/$($Matches[1])"
            } else {
                $RepositoryUrl = $gitRemote -replace '\.git$', ''
            }
            Write-Host "Auto-detected repository: $RepositoryUrl" -ForegroundColor Gray
        } else {
            $RepositoryUrl = "https://github.com/yourusername/BambuStudioFilaments"
            Write-Host "Using default repository URL (no git remote found)" -ForegroundColor Yellow
        }
    } catch {
        $RepositoryUrl = "https://github.com/yourusername/BambuStudioFilaments"
        Write-Host "Using default repository URL (git not available)" -ForegroundColor Yellow
    }
}

Write-Host ""

# Get profile files
$profileFiles = @()

if (Test-Path $Path -PathType Leaf) {
    # Single file
    $profileFiles = @(Get-Item $Path)
} elseif (Test-Path $Path -PathType Container) {
    # Directory - get all JSON files except entries
    $profileFiles = Get-ChildItem -Path $Path -Filter "*.json" | Where-Object {
        $_.Name -notlike "*entries*" -and $_.Name -notlike "*registry*"
    }
} else {
    Write-Error "Path not found: $Path"
    exit 1
}

if ($profileFiles.Count -eq 0) {
    Write-Warning "No profile files found at: $Path"
    exit 0
}

Write-Host "Found $($profileFiles.Count) profile file(s)" -ForegroundColor White
Write-Host ""

$updatedCount = 0
$skippedCount = 0
$errorCount = 0

foreach ($file in $profileFiles) {
    Write-Host "Processing: $($file.Name)" -ForegroundColor Cyan

    try {
        # Read JSON
        $content = Get-Content $file.FullName -Raw
        $profileData = $content | ConvertFrom-Json

        # Check if already has metadata
        $hasMetadata = $profileData.PSObject.Properties.Name -contains 'bsf_metadata'

        if ($hasMetadata -and -not $Force) {
            Write-Host "  ⊙ Skipped (already has metadata, use -Force to overwrite)" -ForegroundColor Yellow
            $skippedCount++
            continue
        }

        # Add bsf_metadata
        $metadata = [PSCustomObject]@{
            managed_by = "BambuStudioFilaments"
            repository_url = $RepositoryUrl
            version = $Version
            printer = $Printer
            vendor = $Vendor
            updated = (Get-Date -Format "yyyy-MM-dd")
            testing_status = $TestingStatus
        }

        if ($hasMetadata) {
            $profileData.bsf_metadata = $metadata
        } else {
            $profileData | Add-Member -NotePropertyName 'bsf_metadata' -NotePropertyValue $metadata
        }

        # Write back to file
        if (-not $WhatIf) {
            # Create backup
            $backupPath = "$($file.FullName).bak"
            Copy-Item $file.FullName $backupPath

            # Write updated JSON with nice formatting
            $profileData | ConvertTo-Json -Depth 100 | Set-Content $file.FullName -Encoding UTF8

            Write-Host "  ✓ Updated (backup: $($file.Name).bak)" -ForegroundColor Green
            $updatedCount++
        } else {
            Write-Host "  → Would add metadata" -ForegroundColor Gray
            Write-Host "     managed_by: BambuStudioFilaments" -ForegroundColor Gray
            Write-Host "     repository_url: $RepositoryUrl" -ForegroundColor Gray
            Write-Host "     version: $Version" -ForegroundColor Gray
            Write-Host "     printer: $Printer" -ForegroundColor Gray
            Write-Host "     vendor: $Vendor" -ForegroundColor Gray
            Write-Host "     testing_status: $TestingStatus" -ForegroundColor Gray
            $updatedCount++
        }

    } catch {
        Write-Host "  ✗ Error: $($_.Exception.Message)" -ForegroundColor Red
        $errorCount++
    }

    Write-Host ""
}

# Summary
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Summary" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Updated:  $updatedCount" -ForegroundColor $(if ($updatedCount -gt 0) { 'Green' } else { 'Gray' })
Write-Host "  Skipped:  $skippedCount" -ForegroundColor $(if ($skippedCount -gt 0) { 'Yellow' } else { 'Gray' })
Write-Host "  Errors:   $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { 'Red' } else { 'Gray' })
Write-Host ""

if ($WhatIf) {
    Write-Host "This was a dry run. Run without -WhatIf to apply changes." -ForegroundColor Yellow
} elseif ($updatedCount -gt 0) {
    Write-Host "Metadata added successfully!" -ForegroundColor Green
    Write-Host "Backup files created with .bak extension" -ForegroundColor Gray
}

Write-Host ""
