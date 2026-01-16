#Requires -Version 5.1
<#
.SYNOPSIS
    Wrapper for scripts\Update-ProfileStatus.ps1

.DESCRIPTION
    This wrapper forwards all parameters to the actual script in the scripts directory.
    Maintained for backward compatibility.
#>

$ScriptPath = Join-Path $PSScriptRoot "scripts\Update-ProfileStatus.ps1"

if (-not (Test-Path $ScriptPath)) {
    Write-Error "Script not found: $ScriptPath"
    exit 1
}

& $ScriptPath @args
