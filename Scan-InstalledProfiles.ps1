#Requires -Version 5.1
<#
.SYNOPSIS
    Convenience wrapper for the Scan-InstalledProfiles.ps1 script.

.DESCRIPTION
    This wrapper allows you to run the scan script from the repository root
    directory while maintaining backward compatibility with the new directory structure.

.NOTES
    This script forwards all parameters to scripts\Scan-InstalledProfiles.ps1
#>

# Forward all parameters to the actual script
& "$PSScriptRoot\scripts\Scan-InstalledProfiles.ps1" @args
