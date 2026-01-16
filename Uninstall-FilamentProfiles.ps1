#Requires -Version 5.1
<#
.SYNOPSIS
    Convenience wrapper for the Uninstall-FilamentProfiles.ps1 script.

.DESCRIPTION
    This wrapper allows you to run the uninstallation script from the repository root
    directory while maintaining backward compatibility with the new directory structure.

.NOTES
    This script forwards all parameters to scripts\Uninstall-FilamentProfiles.ps1
#>

# Forward all parameters to the actual script
& "$PSScriptRoot\scripts\Uninstall-FilamentProfiles.ps1" @args
