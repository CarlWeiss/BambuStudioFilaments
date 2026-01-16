# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- CHANGELOG.md to track version history
- GitHub issue templates for bug reports, feature requests, and documentation
- GitHub Actions CI/CD workflow for testing PowerShell scripts with Pester tests
- Pull request template for standardized contributions
- Pester unit tests for FilamentProfileHelpers.ps1 functions
- Validate-Profiles.ps1 script for comprehensive profile validation
- Convenience wrapper scripts at root level for backward compatibility
- **Scalability architecture** for supporting multiple printers and vendors:
  - Central profile registry (`profiles/profile-registry.json`)
  - ProfileRegistry.ps1 module with dynamic pattern matching
  - Scan-InstalledProfiles.ps1 universal scanner
  - Support for unlimited printer/vendor combinations without code changes
  - Auto-detection of new printers and vendors
- Enhanced Uninstall script with `-ScanOnly` parameter
- Comprehensive documentation:
  - PROFILE_IDENTIFICATION.md (identification methods)
  - SCALABILITY_ARCHITECTURE.md (scalable design patterns)

### Changed
- **BREAKING**: Reorganized directory structure for better maintainability
  - Moved profiles to `profiles/` directory
  - Moved scripts to `scripts/` directory with helpers in `scripts/lib/`
  - Moved documentation to `docs/` directory
  - Tests remain in `tests/` directory
- Fixed profile count in README (corrected from 14 to 15 profiles)
- Updated all script path references to work with new structure
- Updated documentation links to reflect new file locations

### Migration Guide
If you have local modifications or scripts that reference the old structure:
- Profiles: `H2D/` → `profiles/H2D/`
- Scripts: `*.ps1` → `scripts/*.ps1` (wrappers available at root for backward compatibility)
- Docs: `Adding_Custom_Filaments.md` → `docs/Adding_Custom_Filaments.md`
- Helpers: `FilamentProfileHelpers.ps1` → `scripts/lib/FilamentProfileHelpers.ps1`

**Note**: You can still run scripts from the root directory (e.g., `.\Install-FilamentProfiles.ps1`) - the wrapper scripts will automatically call the scripts in the new location.

## [1.0.0] - 2026-01-14

### Added
- Initial release with 15 SUNLU H2D profiles
- Automated PowerShell installation script (Install-FilamentProfiles.ps1)
- Automated PowerShell uninstallation script (Uninstall-FilamentProfiles.ps1)
- FilamentProfileHelpers.ps1 module with reusable functions
- Comprehensive documentation (README.md, Adding_Custom_Filaments.md)
- .gitignore for proper version control
- LICENSE (AGPL-3.0 to match BambuStudio)
- CONTRIBUTING.md with contribution guidelines

### Profiles Included
- SUNLU PLA (standard, 0.2 nozzle, High Flow variants)
- SUNLU PLA+ (standard)
- SUNLU PLA+ 2.0 (standard, 0.2 nozzle, 0.6 nozzle, High Flow variants)
- SUNLU Silk PLA (standard)
- SUNLU PETG (standard, 0.2 nozzle, High Flow variants)
- SUNLU ABS (standard, High Flow variants)
- SUNLU TPU (standard)

### Technical Details
- All profiles properly inherit from SUNLU base profiles
- Unique setting_id values for each profile to ensure AMS recognition
- Proper BBL.json integration for AMS dropdown visibility
- Dual extruder support configured

---

## Release Notes

### v1.0.0 - Initial Release (2026-01-14)

This initial release fills the gap when Bambu Lab H2D launched without SUNLU filament profiles. The project provides:

**15 Ready-to-Use SUNLU H2D Profiles:**
- Complete coverage of SUNLU filament types (PLA, PLA+, PLA+ 2.0, Silk PLA, PETG, ABS, TPU)
- Variants for different nozzle sizes (0.2mm, 0.4mm/0.6mm/0.8mm)
- High Flow (HF) variants for high-flow hotends

**Automation Scripts:**
- Interactive PowerShell installation with profile selection menu
- Automatic BBL.json backup and update
- Dry-run mode with -WhatIf parameter
- Uninstallation script for clean removal

**Comprehensive Documentation:**
- Step-by-step installation guide (automated and manual methods)
- Technical deep-dive on creating custom filament profiles
- Troubleshooting guide for common issues
- Profile settings reference tables

**Community Features:**
- Contribution guidelines for adding new vendors/printers
- Template structure for organizing future profiles
- Examples that can be adapted for other unsupported combinations

This release demonstrates the process of deriving profiles from vendor base profiles and serves as both a usable profile library and an educational resource for the BambuStudio community.

---

[Unreleased]: https://github.com/yourusername/BambuStudioFilaments/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/yourusername/BambuStudioFilaments/releases/tag/v1.0.0
