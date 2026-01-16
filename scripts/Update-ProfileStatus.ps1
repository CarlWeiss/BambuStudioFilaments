#Requires -Version 5.1
<#
.SYNOPSIS
    Updates the testing status of profile JSON files.

.DESCRIPTION
    This script updates the testing_status field in profile metadata,
    useful for promoting profiles from untested -> beta -> tested.

.PARAMETER Path
    Path to a profile JSON file or directory containing profiles.

.PARAMETER TestingStatus
    New testing status: tested, beta, untested, or experimental

.PARAMETER Notes
    Optional testing notes to document what was verified

.PARAMETER WhatIf
    Show what would be changed without modifying files.

.EXAMPLE
    .\Update-ProfileStatus.ps1 -Path "profiles\H2D\SUNLU\SUNLU PLA @BBL H2D.json" -TestingStatus "tested"
    Promotes a single profile to tested status.

.EXAMPLE
    .\Update-ProfileStatus.ps1 -Path "profiles\H2D\SUNLU" -TestingStatus "beta" -Notes "Initial testing complete"
    Updates all profiles in a directory to beta status with notes.

.NOTES
    This script requires profiles to already have bsf_metadata.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Path,

    [Parameter(Mandatory)]
    [ValidateSet('tested', 'beta', 'untested', 'experimental')]
    [string]$TestingStatus,

    [Parameter()]
    [string]$Notes,

    [Parameter()]
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Profile Status Updater" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
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
Write-Host "New status: $TestingStatus" -ForegroundColor White
if ($Notes) {
    Write-Host "Notes: $Notes" -ForegroundColor White
}
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

        # Check if has metadata
        $hasMetadata = $profileData.PSObject.Properties.Name -contains 'bsf_metadata'

        if (-not $hasMetadata) {
            Write-Host "  ⊙ Skipped (no bsf_metadata found - use Add-ProfileMetadata.ps1 first)" -ForegroundColor Yellow
            $skippedCount++
            continue
        }

        # Get current status
        $currentStatus = $profileData.bsf_metadata.testing_status
        if (-not $currentStatus) {
            $currentStatus = "none"
        }

        # Update testing_status
        $profileData.bsf_metadata.testing_status = $TestingStatus

        # Update the updated date
        $profileData.bsf_metadata.updated = (Get-Date -Format "yyyy-MM-dd")

        # Add notes if provided
        if ($Notes) {
            if ($profileData.bsf_metadata.PSObject.Properties.Name -contains 'testing_notes') {
                $profileData.bsf_metadata.testing_notes = $Notes
            } else {
                $profileData.bsf_metadata | Add-Member -NotePropertyName 'testing_notes' -NotePropertyValue $Notes
            }
        }

        # Write back to file
        if (-not $WhatIf) {
            # Create backup
            $backupPath = "$($file.FullName).bak"
            Copy-Item $file.FullName $backupPath

            # Write updated JSON with nice formatting
            $profileData | ConvertTo-Json -Depth 100 | Set-Content $file.FullName -Encoding UTF8

            Write-Host "  ✓ Updated: $currentStatus → $TestingStatus" -ForegroundColor Green
            if ($Notes) {
                Write-Host "    Notes: $Notes" -ForegroundColor Gray
            }
            $updatedCount++
        } else {
            Write-Host "  → Would update: $currentStatus → $TestingStatus" -ForegroundColor Gray
            if ($Notes) {
                Write-Host "    Notes: $Notes" -ForegroundColor Gray
            }
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
    Write-Host "Status updated successfully!" -ForegroundColor Green
    Write-Host "Backup files created with .bak extension" -ForegroundColor Gray
}

Write-Host ""
