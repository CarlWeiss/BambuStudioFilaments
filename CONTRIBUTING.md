# Contributing to BambuStudio Filament Profiles

Thank you for your interest in contributing! This project helps the BambuStudio community by providing custom filament profiles for unsupported printer/vendor combinations.

## What We're Looking For

### Profile Contributions

We welcome profiles for:
- **New printer models** that launched without vendor profiles
- **Specialty hardware** (hardened nozzles, high-flow hotends, custom configurations)
- **Popular vendors** missing official profiles for certain printers
- **Additional vendors** for existing printer configurations

### Code Contributions

- Bug fixes for installation/uninstallation scripts
- New features for the helper library
- Cross-platform support (Linux, macOS)
- Test coverage
- Documentation improvements

## How to Contribute

### Adding New Profiles

1. **Fork the repository**

2. **Create the folder structure:**
   ```
   PrinterModel/VendorName/
   ```
   Examples: `H2D/eSUN/`, `X1C/Polymaker/`, `P1S-ObXidianHF/SUNLU/`

3. **Add profile JSON files:**
   - Use proper `setting_id` values (see [Adding_Custom_Filaments.md](Adding_Custom_Filaments.md))
   - Follow naming convention: `<Brand> <Material> @BBL <Printer>.json`
   - Ensure profiles inherit from appropriate base profiles

4. **Create a JSON entries file:**
   - Name it `bbl_json_entries.json`
   - Include all BBL.json entries for your profiles

5. **Write vendor-specific documentation:**
   - Create a `README.md` in the vendor folder
   - Document prerequisites (base profiles needed, hardware requirements)
   - Include installation instructions
   - Add any special notes or troubleshooting tips

6. **Test thoroughly:**
   - Verify profiles work correctly in BambuStudio
   - Test AMS integration (if applicable)
   - Test with the installation script

7. **Update main README.md:**
   - Add your vendor to the "Currently Available Profiles" section
   - Update the profile count

8. **Submit a pull request:**
   - Clearly describe what profiles you're adding
   - Mention any testing you've done
   - Reference any related issues

### Code Contributions

1. **Fork and create a branch:**
   ```powershell
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes:**
   - Follow existing code style and patterns
   - Use approved PowerShell verbs (Get-, Set-, New-, etc.)
   - Add comments for complex logic
   - Update documentation if needed

3. **Test your changes:**
   - Test with multiple printer/vendor combinations
   - Test both success and failure scenarios
   - Ensure backward compatibility

4. **Commit with clear messages:**
   ```powershell
   git commit -m "Add feature: description of what you did"
   ```

5. **Submit a pull request:**
   - Reference any related issues
   - Describe what changed and why
   - Include testing details

## Guidelines

### Profile Requirements

- **Unique `setting_id`**: Add appropriate suffixes (e.g., `_H2D1`, `_X1C2`)
- **Proper inheritance**: Profiles should inherit from vendor base profiles when possible
- **Correct structure**: Include all required fields (`type`, `name`, `from`, etc.)
- **Tested**: Verify profiles work correctly before submitting

### Naming Conventions

- **Folders**: Use hyphens for multi-word names: `P1S-ObXidianHF`, not `P1S_ObXidianHF`
- **Profile files**: Follow BambuStudio convention: `<Brand> <Material> @BBL <Printer>.json`
- **Functions**: Use approved PowerShell verbs: `Get-`, `Set-`, `New-`, `Resolve-`, etc.

### Documentation Requirements

- **README.md**: Every vendor folder should have one
- **Prerequisites**: Document what base profiles users need to download first
- **Installation**: Provide both automated and manual installation steps
- **Troubleshooting**: Include common issues and solutions

### Code Style

**PowerShell:**
- Use `PascalCase` for function names
- Use `$PascalCase` for variables
- Include parameter validation
- Add comment-based help for functions
- Use `[PSCustomObject]` instead of hashtables for structured data

**Documentation:**
- Use clear, concise language
- Include code examples where helpful
- Format code blocks with appropriate syntax highlighting
- Link to related documentation

## Testing

Before submitting:

1. **Profile Testing:**
   - Import profiles into BambuStudio
   - Verify they appear in the filament list
   - Test AMS integration (if applicable)
   - Verify printer compatibility

2. **Script Testing:**
   - Test installation script with new profiles
   - Test uninstallation script
   - Test with `-WhatIf` flag
   - Test error scenarios

3. **Documentation Review:**
   - Check for typos and formatting
   - Verify all links work
   - Ensure code examples are correct

## Questions or Problems?

- **Documentation**: Check [README.md](README.md) and [Adding_Custom_Filaments.md](Adding_Custom_Filaments.md)
- **Issues**: Open an issue on GitHub
- **Discussions**: Use GitHub Discussions for general questions

## License

By contributing, you agree that your contributions will be licensed under the AGPL-3.0 license, matching BambuStudio's license.

---

Thank you for helping make BambuStudio better for everyone! 🖨️✨
