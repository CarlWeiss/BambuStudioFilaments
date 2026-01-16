# FilamentProfileHelpers.ps1

Shared PowerShell library for BambuStudio filament profile management scripts.

## Purpose

This library provides common functions used by both [Install-FilamentProfiles.ps1](Install-FilamentProfiles.ps1) and [Uninstall-FilamentProfiles.ps1](Uninstall-FilamentProfiles.ps1) to maintain consistency and avoid code duplication.

## Functions

### Output Functions

- **`Write-Status`** - Display informational messages (cyan)
- **`Write-Success`** - Display success messages (green)
- **`Write-Warn`** - Display warning messages (yellow)
- **`Write-Err`** - Display error messages (red)

### Repository Discovery

- **`Get-AvailablePrinters`** - Scans the repository for printer configurations
  - Parameters: `$ScriptDir` - Repository root directory
  - Returns: Array of printer hashtables with Name, Path, and Vendors

- **`Get-VendorsForPrinter`** - Finds vendors for a specific printer
  - Parameters: `$PrinterPath` - Path to printer directory
  - Returns: Array of vendor hashtables with Name, Path, ProfileCount, and EntriesFile

### Profile Processing

- **`Get-MaterialType`** - Extracts material type from profile name
  - Parameters: `$ProfileName` - Full profile name
  - Returns: Material type string (PLA, PETG, ABS, etc.) or "Other"

- **`Get-DisplayName`** - Extracts clean display name from profile entry
  - Parameters: `$ProfileName` - Full profile name
  - Returns: Clean name without printer/nozzle info

- **`Group-ProfilesByMaterial`** - Groups profile entries by material type
  - Parameters: `$Entries` - Array of profile entries
  - Returns: Hashtable of material types → profile arrays

### User Interface

- **`Show-PrinterMenu`** - Displays printer selection menu
  - Parameters: `$Printers` - Array of printer hashtables

- **`Show-VendorMenu`** - Displays vendor selection menu
  - Parameters: `$Vendors` - Array of vendor hashtables, `$PrinterName` - Selected printer name

- **`Show-ProfileMenu`** - Displays profile selection menu grouped by material type
  - Parameters: `$ProfileGroups` - Hashtable from Group-ProfilesByMaterial
  - Returns: Array of menu items

- **`Parse-Selection`** - Parses comma-separated selection input
  - Parameters: `$Selection` - User input string, `$MenuItems` - Menu items array
  - Returns: Array of selected profile entries

## Usage Example

```powershell
# Import the library
. (Join-Path $PSScriptRoot "FilamentProfileHelpers.ps1")

# Get available printers
$Printers = Get-AvailablePrinters -ScriptDir $PSScriptRoot

# Show menu
Show-PrinterMenu -Printers $Printers
$Selection = Read-Host "Select printer"

# Get vendors for selected printer
$Vendors = Get-VendorsForPrinter -PrinterPath $Printers[$Selection].Path

# Group profiles and show menu
$ProfileGroups = Group-ProfilesByMaterial -Entries $Profiles
$MenuItems = Show-ProfileMenu -ProfileGroups $ProfileGroups

# Parse user selection
$Selected = Parse-Selection -Selection $UserInput -MenuItems $MenuItems
```

## Maintenance

When adding new shared functionality:
1. Add the function to `FilamentProfileHelpers.ps1`
2. Export it in the `Export-ModuleMember` block at the bottom
3. Update both Install and Uninstall scripts to use the new function
4. Update this documentation

## Benefits

- **Consistency** - Both scripts use identical logic for common operations
- **Maintainability** - Fix bugs or add features in one place
- **Testability** - Shared functions can be tested independently
- **Reusability** - Future scripts can leverage the same functions
