# Project Structure Recommendations

**Date:** 2026-01-14
**Current State:** Functional but needs organizational improvements

---

## Executive Summary

The BambuStudio Filament Profiles project is well-structured at a functional level with good documentation and working automation scripts. However, several organizational and structural improvements would make it more professional, maintainable, and contributor-friendly.

**Priority Improvements:**
1. 🔴 **HIGH**: Fix profile count in README (15 profiles, not 14)
2. 🔴 **HIGH**: Consolidate/remove duplicate SUNLU_Profiles_H2D directory
3. 🟡 **MEDIUM**: Reorganize directory structure for better scalability
4. 🟡 **MEDIUM**: Add Pester tests for PowerShell scripts
5. 🟢 **LOW**: Improve documentation with screenshots/diagrams

---

## 1. Directory Structure Improvements

### Current Issues

❌ **Mixed concerns**: Scripts, profiles, and documentation at root level
❌ **Inconsistent naming**: `P1S_ObXidianHF` (underscores) vs `H2D` (no separators)
❌ **No dedicated test directory**
❌ **Possible duplicate**: `SUNLU_Profiles_H2D/` directory (needs investigation)

### Recommended Structure

```
BambuStudioFilaments/
├── profiles/                          # All profile definitions
│   ├── H2D/
│   │   ├── README.md                  # H2D-specific info
│   │   ├── SUNLU/
│   │   │   ├── README.md
│   │   │   ├── bbl_json_entries.json
│   │   │   └── *.json (profiles)
│   │   └── eSUN/                      # Future vendor
│   │
│   ├── X1C/                          # Future printer models
│   ├── P1P/
│   └── A1/
│
├── scripts/                          # All automation scripts
│   ├── Install-FilamentProfiles.ps1
│   ├── Uninstall-FilamentProfiles.ps1
│   └── lib/                          # Shared libraries
│       ├── FilamentProfileHelpers.ps1
│       └── FilamentProfileHelpers.md
│
├── docs/                             # Extended documentation
│   ├── Adding_Custom_Filaments.md
│   ├── TROUBLESHOOTING.md
│   ├── API.md                        # For script API reference
│   └── images/                       # Screenshots, diagrams
│       ├── ams-dropdown.png
│       ├── installation-flow.png
│       └── folder-structure.png
│
├── tests/                            # Test suite
│   ├── FilamentProfileHelpers.Tests.ps1
│   ├── Install-FilamentProfiles.Tests.ps1
│   └── testdata/                     # Mock profiles for testing
│
├── .github/                          # GitHub-specific
│   ├── workflows/
│   │   └── test.yml                  # CI/CD
│   ├── ISSUE_TEMPLATE/
│   └── PULL_REQUEST_TEMPLATE.md
│
├── .gitignore                        # ✅ Created
├── LICENSE                           # ✅ Created
├── CONTRIBUTING.md                   # ✅ Created
├── CHANGELOG.md                      # Version history
└── README.md
```

### Migration Steps

1. **Create new directory structure:**
   ```powershell
   New-Item -ItemType Directory -Path profiles, scripts/lib, docs, tests, .github/workflows
   ```

2. **Move existing files:**
   ```powershell
   # Move profiles
   Move-Item H2D profiles/
   Move-Item P1S_ObXidianHF profiles/P1S-ObXidianHF

   # Move scripts
   Move-Item Install-FilamentProfiles.ps1 scripts/
   Move-Item Uninstall-FilamentProfiles.ps1 scripts/
   Move-Item FilamentProfileHelpers.ps1 scripts/lib/
   Move-Item FilamentProfileHelpers.md scripts/lib/

   # Move documentation
   Move-Item Adding_Custom_Filaments.md docs/
   ```

3. **Update script paths:**
   - Update `$PSScriptRoot` references in scripts
   - Update documentation links

4. **Test thoroughly:**
   - Verify installation scripts work with new paths
   - Check all documentation links

---

## 2. Code Quality Improvements

### A. Add Pester Tests

**Create: `tests/FilamentProfileHelpers.Tests.ps1`**

```powershell
#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.0.0" }

BeforeAll {
    . "$PSScriptRoot/../scripts/lib/FilamentProfileHelpers.ps1"
}

Describe "Get-DisplayName" {
    It "Removes @BBL printer designation" {
        $result = Get-DisplayName -ProfileName "SUNLU PLA+ 2.0 @BBL H2D"
        $result | Should -Be "SUNLU PLA+ 2.0"
    }

    It "Preserves variant info after printer designation" {
        $result = Get-DisplayName -ProfileName "SUNLU PLA+ 2.0 @BBL H2D 0.6 nozzle"
        $result | Should -Be "SUNLU PLA+ 2.0 0.6 nozzle"
    }

    It "Removes @Bambu Lab printer designation" {
        $result = Get-DisplayName -ProfileName "Bambu PLA @Bambu Lab P1S"
        $result | Should -Be "Bambu PLA"
    }

    It "Preserves HF designation" {
        $result = Get-DisplayName -ProfileName "SUNLU PLA+ 2.0 HF @BBL H2D"
        $result | Should -Be "SUNLU PLA+ 2.0 HF"
    }
}

Describe "Get-MaterialType" {
    It "Extracts PLA from profile name" {
        $result = Get-MaterialType -ProfileName "SUNLU PLA @BBL H2D"
        $result | Should -Be "PLA"
    }

    It "Extracts PLA+ from profile name" {
        $result = Get-MaterialType -ProfileName "SUNLU PLA+ 2.0 @BBL H2D"
        $result | Should -Be "PLA+"
    }

    It "Extracts PETG from profile name" {
        $result = Get-MaterialType -ProfileName "SUNLU PETG @BBL H2D"
        $result | Should -Be "PETG"
    }

    It "Returns 'Other' for unknown materials" {
        $result = Get-MaterialType -ProfileName "Custom Material @BBL H2D"
        $result | Should -Be "Other"
    }
}

Describe "Resolve-Selection" {
    BeforeEach {
        $script:MenuItems = @(
            @{ Index = 1; Entry = @{ name = "Profile 1" } }
            @{ Index = 2; Entry = @{ name = "Profile 2" } }
            @{ Index = 3; Entry = @{ name = "Profile 3" } }
        )
    }

    It "Resolves single selection" {
        $result = Resolve-Selection -Selection "1" -MenuItems $MenuItems
        $result.Count | Should -Be 1
        $result[0].name | Should -Be "Profile 1"
    }

    It "Resolves comma-separated selections" {
        $result = Resolve-Selection -Selection "1,3" -MenuItems $MenuItems
        $result.Count | Should -Be 2
        $result[0].name | Should -Be "Profile 1"
        $result[1].name | Should -Be "Profile 3"
    }

    It "Skips invalid selections" {
        $result = Resolve-Selection -Selection "1,99,2" -MenuItems $MenuItems
        $result.Count | Should -Be 2
    }
}
```

**Run tests:**
```powershell
Invoke-Pester -Path tests/ -Output Detailed
```

### B. Add CI/CD Pipeline

**Create: `.github/workflows/test.yml`**

```yaml
name: Test PowerShell Scripts

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: windows-latest

    steps:
    - uses: actions/checkout@v3

    - name: Install Pester
      shell: pwsh
      run: |
        Install-Module -Name Pester -MinimumVersion 5.0.0 -Force -SkipPublisherCheck

    - name: Run Tests
      shell: pwsh
      run: |
        Invoke-Pester -Path tests/ -Output Detailed -CI

    - name: PSScriptAnalyzer
      shell: pwsh
      run: |
        Install-Module -Name PSScriptAnalyzer -Force -SkipPublisherCheck
        $results = Invoke-ScriptAnalyzer -Path scripts/ -Recurse
        if ($results) {
          $results | Format-Table
          exit 1
        }
```

### C. Script Improvements

**1. Add parameter validation:**
```powershell
# In Install-FilamentProfiles.ps1
param(
    [ValidateScript({
        Test-Path (Join-Path $PSScriptRoot "profiles/$_")
    })]
    [string]$Printer,

    [ValidateNotNullOrEmpty()]
    [string]$Vendor
)
```

**2. Add verbose/debug output:**
```powershell
function Get-AvailablePrinters {
    # ...
    Write-Verbose "Scanning for printers in: $ScriptDir"
    Write-Debug "Found $($Printers.Count) printer configurations"
}
```

**3. Add error logging:**
```powershell
function Write-ErrorLog {
    param([string]$Message, [string]$LogPath = "$env:TEMP\BambuStudioFilaments.log")

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - ERROR: $Message" | Out-File -Append -FilePath $LogPath
}
```

---

## 3. Documentation Improvements

### A. Add Visual Documentation

**Recommended images:**
1. `docs/images/installation-flow.png` - Flowchart of installation process
2. `docs/images/folder-structure.png` - Visual representation of file organization
3. `docs/images/ams-dropdown.png` - Screenshot showing profiles in AMS
4. `docs/images/bambu-studio-settings.png` - Where to find BambuStudio settings

### B. Create TROUBLESHOOTING.md

**Create: `docs/TROUBLESHOOTING.md`**

```markdown
# Troubleshooting Guide

## Installation Issues

### Error: "Printer not found"
**Cause:** Printer name doesn't match available configurations
**Solution:** Run script without parameters to see available printers

### Error: "BBL.json not found"
**Cause:** BambuStudio hasn't been run yet
**Solution:** Open and close BambuStudio once to create system files

[Continue with more troubleshooting scenarios...]
```

### C. Create API Documentation

**Create: `docs/API.md`**

Document all public functions for contributors.

---

## 4. Profile Management Improvements

### A. Profile Validation Script

**Create: `scripts/Validate-Profiles.ps1`**

```powershell
#Requires -Version 5.1
<#
.SYNOPSIS
    Validates filament profile JSON files for correctness.
#>

function Test-ProfileStructure {
    param([string]$ProfilePath)

    $profile = Get-Content $ProfilePath -Raw | ConvertFrom-Json

    # Required fields
    $requiredFields = @('type', 'name', 'from')
    foreach ($field in $requiredFields) {
        if (-not $profile.$field) {
            Write-Error "Missing required field: $field in $ProfilePath"
            return $false
        }
    }

    # Validate setting_id format
    if ($profile.setting_id -and $profile.setting_id -notmatch '^[A-Z0-9]+_[A-Z0-9]+\d+$') {
        Write-Warning "setting_id format may be incorrect: $($profile.setting_id)"
    }

    return $true
}

# Validate all profiles
Get-ChildItem -Path profiles -Filter "*.json" -Recurse | ForEach-Object {
    Write-Host "Validating: $($_.Name)"
    Test-ProfileStructure -ProfilePath $_.FullName
}
```

### B. Profile Generator Script

**Create: `scripts/New-ProfileFromTemplate.ps1`**

Help users create new profiles from templates.

---

## 5. Community & Contribution Improvements

### A. Issue Templates

**Create: `.github/ISSUE_TEMPLATE/bug_report.md`**
**Create: `.github/ISSUE_TEMPLATE/feature_request.md`**
**Create: `.github/ISSUE_TEMPLATE/new_profiles.md`**

### B. Pull Request Template

**Create: `.github/PULL_REQUEST_TEMPLATE.md`**

```markdown
## Description
<!-- Describe your changes -->

## Type of Change
- [ ] Bug fix
- [ ] New profiles
- [ ] New feature
- [ ] Documentation update

## Checklist
- [ ] I have tested my changes
- [ ] I have updated the documentation
- [ ] My code follows the project style guidelines
- [ ] I have added tests (if applicable)
- [ ] All existing tests pass

## Testing Done
<!-- Describe how you tested your changes -->
```

---

## 6. Immediate Action Items

### High Priority (Do First)

1. **✅ Create .gitignore** - DONE
2. **✅ Create LICENSE** - DONE
3. **✅ Create CONTRIBUTING.md** - DONE
4. **Update README.md profile count:** 15 profiles (not 14) for H2D/SUNLU
5. **Investigate SUNLU_Profiles_H2D directory:** Determine if duplicate, remove if so
6. **Fix naming consistency:** Rename `P1S_ObXidianHF` to `P1S-ObXidianHF`

### Medium Priority (Do Soon)

7. **Reorganize directory structure** as outlined above
8. **Create Pester tests** for helper functions
9. **Add CI/CD pipeline** with GitHub Actions
10. **Create CHANGELOG.md** to track version history
11. **Add validation script** for profile correctness

### Low Priority (Nice to Have)

12. **Add visual documentation** (screenshots, diagrams)
13. **Create profile generator script**
14. **Add verbose/debug logging**
15. **Create TROUBLESHOOTING.md**
16. **Set up GitHub Discussions** for community Q&A

---

## 7. Benefits of Recommended Changes

### For Maintainers
- Easier to manage and navigate codebase
- Automated testing catches bugs early
- Clear contribution guidelines reduce review time
- Better documentation reduces support burden

### For Contributors
- Clear structure makes it easy to add new profiles
- Tests provide confidence changes don't break things
- Templates and guidelines make contribution straightforward
- CI/CD provides immediate feedback

### For Users
- Professional appearance increases trust
- Better documentation reduces confusion
- Troubleshooting guide helps solve problems
- Visual aids make instructions clearer

---

## 8. Migration Timeline

**Week 1: Critical Fixes**
- Fix README profile count
- Remove duplicate directory
- Add .gitignore, LICENSE, CONTRIBUTING.md ✅

**Week 2: Structural Improvements**
- Reorganize directory structure
- Update all documentation links
- Fix naming inconsistencies

**Week 3: Testing & Automation**
- Add Pester tests
- Set up CI/CD
- Add profile validation script

**Week 4: Documentation & Community**
- Add visual documentation
- Create troubleshooting guide
- Set up issue templates

---

## Questions or Concerns?

This document outlines significant structural changes. Before implementing, consider:

1. **Backward compatibility:** Will existing users' workflows break?
2. **Community input:** Should you gather feedback before restructuring?
3. **Incremental vs. big bang:** Implement all at once or gradually?
4. **Breaking changes:** Will you need to version this as 2.0?

---

**Document Version:** 1.0
**Last Updated:** 2026-01-14
