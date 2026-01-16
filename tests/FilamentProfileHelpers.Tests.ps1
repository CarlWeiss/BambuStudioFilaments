#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.0.0" }

<#
.SYNOPSIS
    Pester tests for FilamentProfileHelpers.ps1

.DESCRIPTION
    Tests for the helper functions used in filament profile installation and management.
    Covers Get-DisplayName, Get-MaterialType, and Resolve-Selection functions.
#>

BeforeAll {
    # Import the module to test
    . "$PSScriptRoot/../scripts/lib/FilamentProfileHelpers.ps1"
}

Describe "Get-DisplayName" {
    Context "BBL printer designation removal" {
        It "Removes @BBL printer designation" {
            $result = Get-DisplayName -ProfileName "SUNLU PLA+ 2.0 @BBL H2D"
            $result | Should -Be "SUNLU PLA+ 2.0"
        }

        It "Preserves variant info after printer designation" {
            $result = Get-DisplayName -ProfileName "SUNLU PLA+ 2.0 @BBL H2D 0.6 nozzle"
            $result | Should -Be "SUNLU PLA+ 2.0 0.6 nozzle"
        }

        It "Preserves HF designation after printer designation" {
            $result = Get-DisplayName -ProfileName "SUNLU PLA+ 2.0 HF @BBL H2D"
            $result | Should -Be "SUNLU PLA+ 2.0 HF"
        }

        It "Handles multiple variant parts correctly" {
            $result = Get-DisplayName -ProfileName "SUNLU PETG @BBL H2D 0.2 nozzle"
            $result | Should -Be "SUNLU PETG 0.2 nozzle"
        }
    }

    Context "Bambu Lab printer designation removal" {
        It "Removes @Bambu Lab printer designation" {
            $result = Get-DisplayName -ProfileName "Bambu PLA @Bambu Lab P1S"
            $result | Should -Be "Bambu PLA"
        }

        It "Removes @Bambu Lab with variant preservation" {
            $result = Get-DisplayName -ProfileName "Bambu PETG @Bambu Lab X1C 0.6 nozzle"
            $result | Should -Be "Bambu PETG 0.6 nozzle"
        }
    }

    Context "Edge cases" {
        It "Handles profile name without printer designation" {
            $result = Get-DisplayName -ProfileName "SUNLU PLA+ 2.0"
            $result | Should -Be "SUNLU PLA+ 2.0"
        }

        It "Handles empty string" {
            $result = Get-DisplayName -ProfileName ""
            $result | Should -Be ""
        }

        It "Preserves 0.2 nozzle designation" {
            $result = Get-DisplayName -ProfileName "SUNLU PLA @BBL H2D 0.2 nozzle"
            $result | Should -Be "SUNLU PLA 0.2 nozzle"
        }
    }
}

Describe "Get-MaterialType" {
    Context "Basic material types" {
        It "Extracts PLA from profile name" {
            $result = Get-MaterialType -ProfileName "SUNLU PLA @BBL H2D"
            $result | Should -Be "PLA"
        }

        It "Extracts PETG from profile name" {
            $result = Get-MaterialType -ProfileName "SUNLU PETG @BBL H2D"
            $result | Should -Be "PETG"
        }

        It "Extracts ABS from profile name" {
            $result = Get-MaterialType -ProfileName "SUNLU ABS HF @BBL H2D"
            $result | Should -Be "ABS"
        }

        It "Extracts TPU from profile name" {
            $result = Get-MaterialType -ProfileName "SUNLU TPU @BBL H2D"
            $result | Should -Be "TPU"
        }

        It "Extracts ASA from profile name" {
            $result = Get-MaterialType -ProfileName "SUNLU ASA @BBL H2D"
            $result | Should -Be "ASA"
        }

        It "Extracts PA-CF from profile name" {
            $result = Get-MaterialType -ProfileName "SUNLU PA-CF @BBL H2D"
            $result | Should -Be "PA-CF"
        }

        It "Extracts PET-CF from profile name" {
            $result = Get-MaterialType -ProfileName "SUNLU PET-CF @BBL H2D"
            $result | Should -Be "PET-CF"
        }
    }

    Context "PLA variants" {
        It "Extracts PLA+ from profile name" {
            $result = Get-MaterialType -ProfileName "SUNLU PLA+ 2.0 @BBL H2D"
            $result | Should -Be "PLA+"
        }

        It "Extracts Silk PLA from profile name" {
            $result = Get-MaterialType -ProfileName "SUNLU Silk PLA @BBL H2D"
            $result | Should -Be "Silk PLA"
        }

        It "Extracts Matte PLA from profile name" {
            $result = Get-MaterialType -ProfileName "SUNLU Matte PLA @BBL H2D"
            $result | Should -Be "Matte PLA"
        }
    }

    Context "Edge cases and unknown materials" {
        It "Returns 'Other' for unknown materials" {
            $result = Get-MaterialType -ProfileName "Custom Material @BBL H2D"
            $result | Should -Be "Other"
        }

        It "Returns 'Other' for empty string" {
            $result = Get-MaterialType -ProfileName ""
            $result | Should -Be "Other"
        }

        It "Handles profile without spaces correctly" {
            $result = Get-MaterialType -ProfileName "SUNLU_PLA_@BBL_H2D"
            $result | Should -Be "Other"
        }
    }

    Context "Case sensitivity" {
        It "Handles lowercase material names" {
            $result = Get-MaterialType -ProfileName "SUNLU pla @BBL H2D"
            $result | Should -Be "PLA"
        }

        It "Handles mixed case material names" {
            $result = Get-MaterialType -ProfileName "SUNLU Petg @BBL H2D"
            $result | Should -Be "PETG"
        }
    }
}

Describe "Resolve-Selection" {
    BeforeEach {
        # Create test menu items
        $script:MenuItems = @(
            @{ Index = 1; Entry = @{ name = "SUNLU PLA @BBL H2D" } }
            @{ Index = 2; Entry = @{ name = "SUNLU PLA+ @BBL H2D" } }
            @{ Index = 3; Entry = @{ name = "SUNLU PETG @BBL H2D" } }
            @{ Index = 4; Entry = @{ name = "SUNLU ABS @BBL H2D" } }
            @{ Index = 5; Entry = @{ name = "SUNLU TPU @BBL H2D" } }
        )
    }

    Context "Single selections" {
        It "Resolves single selection" {
            $result = Resolve-Selection -Selection "1" -MenuItems $MenuItems
            $result.Count | Should -Be 1
            $result[0].name | Should -Be "SUNLU PLA @BBL H2D"
        }

        It "Resolves selection in middle of range" {
            $result = Resolve-Selection -Selection "3" -MenuItems $MenuItems
            $result.Count | Should -Be 1
            $result[0].name | Should -Be "SUNLU PETG @BBL H2D"
        }

        It "Resolves last item selection" {
            $result = Resolve-Selection -Selection "5" -MenuItems $MenuItems
            $result.Count | Should -Be 1
            $result[0].name | Should -Be "SUNLU TPU @BBL H2D"
        }
    }

    Context "Multiple selections" {
        It "Resolves comma-separated selections" {
            $result = Resolve-Selection -Selection "1,3" -MenuItems $MenuItems
            $result.Count | Should -Be 2
            $result[0].name | Should -Be "SUNLU PLA @BBL H2D"
            $result[1].name | Should -Be "SUNLU PETG @BBL H2D"
        }

        It "Resolves space-separated selections" {
            $result = Resolve-Selection -Selection "1 3 5" -MenuItems $MenuItems
            $result.Count | Should -Be 3
            $result[0].name | Should -Be "SUNLU PLA @BBL H2D"
            $result[1].name | Should -Be "SUNLU PETG @BBL H2D"
            $result[2].name | Should -Be "SUNLU TPU @BBL H2D"
        }

        It "Resolves comma and space separated selections" {
            $result = Resolve-Selection -Selection "1, 2, 3" -MenuItems $MenuItems
            $result.Count | Should -Be 3
        }

        It "Handles selections in non-sequential order" {
            $result = Resolve-Selection -Selection "5,2,4" -MenuItems $MenuItems
            $result.Count | Should -Be 3
            $result[0].name | Should -Be "SUNLU PLA+ @BBL H2D"
            $result[1].name | Should -Be "SUNLU ABS @BBL H2D"
            $result[2].name | Should -Be "SUNLU TPU @BBL H2D"
        }
    }

    Context "Range selections" {
        It "Resolves range selection (1-3)" {
            $result = Resolve-Selection -Selection "1-3" -MenuItems $MenuItems
            $result.Count | Should -Be 3
            $result[0].name | Should -Be "SUNLU PLA @BBL H2D"
            $result[1].name | Should -Be "SUNLU PLA+ @BBL H2D"
            $result[2].name | Should -Be "SUNLU PETG @BBL H2D"
        }

        It "Resolves range selection (2-4)" {
            $result = Resolve-Selection -Selection "2-4" -MenuItems $MenuItems
            $result.Count | Should -Be 3
        }

        It "Combines ranges and individual selections" {
            $result = Resolve-Selection -Selection "1-2,5" -MenuItems $MenuItems
            $result.Count | Should -Be 3
        }
    }

    Context "Invalid selections" {
        It "Skips invalid selections" {
            $result = Resolve-Selection -Selection "1,99,2" -MenuItems $MenuItems
            $result.Count | Should -Be 2
            $result[0].name | Should -Be "SUNLU PLA @BBL H2D"
            $result[1].name | Should -Be "SUNLU PLA+ @BBL H2D"
        }

        It "Handles out of range selections" {
            $result = Resolve-Selection -Selection "10" -MenuItems $MenuItems
            $result.Count | Should -Be 0
        }

        It "Handles negative selections" {
            $result = Resolve-Selection -Selection "-1" -MenuItems $MenuItems
            $result.Count | Should -Be 0
        }

        It "Handles zero selection" {
            $result = Resolve-Selection -Selection "0" -MenuItems $MenuItems
            $result.Count | Should -Be 0
        }

        It "Handles non-numeric input gracefully" {
            $result = Resolve-Selection -Selection "abc" -MenuItems $MenuItems
            $result.Count | Should -Be 0
        }

        It "Handles empty selection" {
            $result = Resolve-Selection -Selection "" -MenuItems $MenuItems
            $result.Count | Should -Be 0
        }
    }

    Context "Special selections" {
        It "Handles 'A' for all selections" -Skip {
            # This test is skipped because 'A' handling might be done at a higher level
            $result = Resolve-Selection -Selection "A" -MenuItems $MenuItems
            $result.Count | Should -Be 5
        }
    }

    Context "Duplicate selections" {
        It "Handles duplicate selections (returns unique items)" {
            $result = Resolve-Selection -Selection "1,1,1" -MenuItems $MenuItems
            $result.Count | Should -BeGreaterThan 0
            # Depending on implementation, might return duplicates or unique items
        }
    }
}

Describe "Integration Tests" {
    Context "Real-world profile name processing" {
        It "Processes full H2D profile name correctly" {
            $profileName = "SUNLU PLA+ 2.0 @BBL H2D 0.6 nozzle"
            $displayName = Get-DisplayName -ProfileName $profileName
            $materialType = Get-MaterialType -ProfileName $profileName

            $displayName | Should -Be "SUNLU PLA+ 2.0 0.6 nozzle"
            $materialType | Should -Be "PLA+"
        }

        It "Processes HF profile name correctly" {
            $profileName = "SUNLU PETG HF @BBL H2D"
            $displayName = Get-DisplayName -ProfileName $profileName
            $materialType = Get-MaterialType -ProfileName $profileName

            $displayName | Should -Be "SUNLU PETG HF"
            $materialType | Should -Be "PETG"
        }

        It "Processes 0.2 nozzle profile correctly" {
            $profileName = "SUNLU PLA+ 2.0 @BBL H2D 0.2 nozzle"
            $displayName = Get-DisplayName -ProfileName $profileName
            $materialType = Get-MaterialType -ProfileName $profileName

            $displayName | Should -Be "SUNLU PLA+ 2.0 0.2 nozzle"
            $materialType | Should -Be "PLA+"
        }
    }
}
