#Requires -Version 5.1
<#
.SYNOPSIS
    Validates filament profile JSON files for correctness and consistency.

.DESCRIPTION
    This script validates all filament profile JSON files in the repository to ensure they:
    - Have valid JSON syntax
    - Contain all required fields (type, name, from, setting_id, inherits)
    - Have properly formatted setting_id values
    - Use correct inheritance patterns
    - Follow naming conventions

.PARAMETER Path
    The path to search for profile files. Defaults to the script's directory.

.PARAMETER Strict
    If specified, treats warnings as errors and exits with non-zero code.

.PARAMETER Verbose
    Provides detailed output for each validation check.

.EXAMPLE
    .\Validate-Profiles.ps1
    Validates all profiles in the default location.

.EXAMPLE
    .\Validate-Profiles.ps1 -Path "H2D\SUNLU" -Verbose
    Validates profiles in the specified path with detailed output.

.EXAMPLE
    .\Validate-Profiles.ps1 -Strict
    Validates profiles and treats any warnings as errors.

.NOTES
    Author: BambuStudio Filaments Project
    Version: 1.0.0
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Path,

    [Parameter()]
    [switch]$Strict,

    [Parameter()]
    [switch]$QuietMode
)

# Set default path to profiles directory
$RepoRoot = Split-Path $PSScriptRoot -Parent
if (-not $Path) {
    $Path = Join-Path $RepoRoot "profiles"
}

# Import helper functions if available
$helpersPath = Join-Path $PSScriptRoot "lib\FilamentProfileHelpers.ps1"
if (Test-Path $helpersPath) {
    . $helpersPath
    Write-Verbose "Loaded helper functions from FilamentProfileHelpers.ps1"
}

# Validation counters
$script:TotalProfiles = 0
$script:ValidProfiles = 0
$script:ErrorCount = 0
$script:WarningCount = 0
$script:ValidationErrors = @()
$script:ValidationWarnings = @()

function Write-ValidationResult {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Success', 'Warning', 'Error')]
        [string]$Level = 'Info'
    )

    if ($QuietMode -and $Level -in @('Info', 'Success')) {
        return
    }

    $color = switch ($Level) {
        'Info'    { 'White' }
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error'   { 'Red' }
    }

    $prefix = switch ($Level) {
        'Info'    { '  ' }
        'Success' { '✓ ' }
        'Warning' { '⚠️  ' }
        'Error'   { '❌ ' }
    }

    Write-Host "$prefix$Message" -ForegroundColor $color
}

function Test-ProfileStructure {
    <#
    .SYNOPSIS
        Validates the structure and content of a single profile JSON file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProfilePath
    )

    $fileName = Split-Path -Leaf $ProfilePath
    $profileErrors = @()
    $profileWarnings = @()

    Write-Verbose "Validating: $fileName"

    try {
        # Parse JSON
        $content = Get-Content $ProfilePath -Raw -ErrorAction Stop
        $profile = $content | ConvertFrom-Json -ErrorAction Stop

        # Required fields for all profiles
        $requiredFields = @('type', 'name', 'from')
        foreach ($field in $requiredFields) {
            if (-not $profile.PSObject.Properties.Name.Contains($field)) {
                $profileErrors += "Missing required field: $field"
            } elseif ([string]::IsNullOrWhiteSpace($profile.$field)) {
                $profileErrors += "Field '$field' is empty"
            }
        }

        # Validate 'type' field
        if ($profile.type -and $profile.type -ne 'filament') {
            $profileWarnings += "Type field is '$($profile.type)' (expected 'filament')"
        }

        # Validate 'from' field
        $validFromValues = @('system', 'user', 'default')
        if ($profile.from -and $profile.from -notin $validFromValues) {
            $profileWarnings += "Field 'from' has unusual value: '$($profile.from)' (expected: system, user, or default)"
        }

        # Validate setting_id (required for system profiles to appear in AMS)
        if ($profile.from -eq 'system') {
            if (-not $profile.setting_id) {
                $profileErrors += "System profile missing 'setting_id' (required for AMS integration)"
            } elseif ($profile.setting_id -notmatch '^[A-Z0-9]+_[A-Z0-9]+\d+$') {
                $profileWarnings += "setting_id format may be incorrect: '$($profile.setting_id)' (expected format: VENDOR_PRINTER1)"
            }
        }

        # Validate inherits field (most custom profiles should inherit from base)
        if (-not $profile.inherits -and -not $profile.filament_id) {
            $profileWarnings += "Profile doesn't inherit from a base profile or define filament_id (may not work correctly in AMS)"
        }

        # Check for instantiation field
        if ($profile.PSObject.Properties.Name.Contains('instantiation')) {
            if ($profile.instantiation -ne 'true') {
                $profileWarnings += "Field 'instantiation' is not 'true' (profile may not be selectable)"
            }
        } else {
            $profileWarnings += "Missing 'instantiation' field (profile may not be selectable)"
        }

        # Validate compatible_printers
        if ($profile.compatible_printers) {
            if ($profile.compatible_printers -isnot [array]) {
                $profileErrors += "Field 'compatible_printers' should be an array"
            } elseif ($profile.compatible_printers.Count -eq 0) {
                $profileWarnings += "Field 'compatible_printers' is empty (profile won't appear for any printer)"
            }
        } else {
            $profileWarnings += "Missing 'compatible_printers' field (profile may not appear for specific printers)"
        }

        # Validate name matches filename
        $expectedFileName = "$($profile.name).json"
        if ($fileName -ne $expectedFileName) {
            $profileWarnings += "Filename '$fileName' doesn't match profile name '$($profile.name).json'"
        }

        # Check for common temperature fields
        $tempFields = @('nozzle_temperature', 'bed_temperature', 'chamber_temperature')
        $missingTempFields = @()
        foreach ($tempField in $tempFields) {
            if (-not $profile.PSObject.Properties.Name.Contains($tempField)) {
                $missingTempFields += $tempField
            }
        }
        if ($missingTempFields.Count -eq $tempFields.Count) {
            $profileWarnings += "Missing all temperature fields (profile likely inherits from base, which is OK)"
        }

    } catch {
        $profileErrors += "Failed to parse JSON: $($_.Exception.Message)"
    }

    # Report results for this profile
    if ($profileErrors.Count -eq 0 -and $profileWarnings.Count -eq 0) {
        Write-ValidationResult "✓ $fileName" -Level Success
        $script:ValidProfiles++
    } else {
        if ($profileErrors.Count -gt 0) {
            Write-ValidationResult "✗ $fileName - $($profileErrors.Count) error(s)" -Level Error
            foreach ($error in $profileErrors) {
                Write-ValidationResult "  • $error" -Level Error
                $script:ValidationErrors += "$fileName`: $error"
            }
            $script:ErrorCount += $profileErrors.Count
        }

        if ($profileWarnings.Count -gt 0) {
            if ($profileErrors.Count -eq 0) {
                Write-ValidationResult "⚠ $fileName - $($profileWarnings.Count) warning(s)" -Level Warning
            }
            foreach ($warning in $profileWarnings) {
                Write-ValidationResult "  • $warning" -Level Warning
                $script:ValidationWarnings += "$fileName`: $warning"
            }
            $script:WarningCount += $profileWarnings.Count
        }

        if ($profileErrors.Count -eq 0) {
            $script:ValidProfiles++
        }
    }

    return @{
        Errors = $profileErrors
        Warnings = $profileWarnings
        IsValid = ($profileErrors.Count -eq 0)
    }
}

# Main execution
Write-Host "`n=======================================" -ForegroundColor Cyan
Write-Host "Filament Profile Validator" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan

Write-ValidationResult "Scanning for profile files in: $Path" -Level Info

# Find all profile JSON files (exclude entries files)
$profileFiles = Get-ChildItem -Path $Path -Filter "*.json" -Recurse -ErrorAction Stop | Where-Object {
    $_.Name -notlike "*entries*" -and
    $_.FullName -notmatch '[\\\/]\.git[\\\/]' -and
    $_.FullName -notmatch '[\\\/]node_modules[\\\/]' -and
    $_.FullName -notmatch '[\\\/]\.vscode[\\\/]' -and
    $_.FullName -notmatch '[\\\/]\.claude[\\\/]' -and
    # Only include profiles in printer model directories
    ($_.FullName -match '[\\\/](H2D|P1S|X1C|P1P|A1)[\\\/]' -or $_.Directory.Name -match '^(H2D|P1S|X1C|P1P|A1)$')
}

$script:TotalProfiles = $profileFiles.Count

if ($script:TotalProfiles -eq 0) {
    Write-ValidationResult "No profile files found in the specified path." -Level Warning
    exit 0
}

Write-ValidationResult "Found $script:TotalProfiles profile file(s) to validate`n" -Level Info

# Validate each profile
foreach ($file in $profileFiles) {
    Test-ProfileStructure -ProfilePath $file.FullName
}

# Summary
Write-Host "`n=======================================" -ForegroundColor Cyan
Write-Host "Validation Summary" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "Total profiles checked: $script:TotalProfiles" -ForegroundColor White
Write-Host "Valid profiles:         $script:ValidProfiles" -ForegroundColor Green
Write-Host "Errors found:           $script:ErrorCount" -ForegroundColor $(if ($script:ErrorCount -gt 0) {'Red'} else {'Green'})
Write-Host "Warnings found:         $script:WarningCount" -ForegroundColor $(if ($script:WarningCount -gt 0) {'Yellow'} else {'Green'})
Write-Host "=======================================" -ForegroundColor Cyan

# Exit code logic
if ($script:ErrorCount -gt 0) {
    Write-Host "`n❌ Validation failed with $script:ErrorCount error(s)." -ForegroundColor Red
    Write-Host "Please fix the errors above before committing." -ForegroundColor Red
    exit 1
} elseif ($Strict -and $script:WarningCount -gt 0) {
    Write-Host "`n⚠️  Validation completed with $script:WarningCount warning(s) (strict mode)." -ForegroundColor Yellow
    Write-Host "Fix warnings or remove -Strict flag to proceed." -ForegroundColor Yellow
    exit 1
} elseif ($script:WarningCount -gt 0) {
    Write-Host "`n⚠️  Validation completed with $script:WarningCount warning(s)." -ForegroundColor Yellow
    Write-Host "Consider addressing warnings for better profile quality." -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "`n✅ All profiles passed validation!" -ForegroundColor Green
    exit 0
}
