[CmdletBinding()]
param(
    [Parameter()]
    [string]
    $CmdletModule = (Join-Path -Path $PSScriptRoot `
            -ChildPath "..\Stubs\Microsoft365.psm1" `
            -Resolve)
)
$GenericStubPath = (Join-Path -Path $PSScriptRoot `
        -ChildPath "..\Stubs\Generic.psm1" `
        -Resolve)
Import-Module -Name (Join-Path -Path $PSScriptRoot `
        -ChildPath "..\UnitTestHelper.psm1" `
        -Resolve)

$Global:DscHelper = New-M365DscUnitTestHelper -StubModule $CmdletModule `
    -DscResource "SPOOrgAssetsLibrary" -GenericStubModule $GenericStubPath
Describe -Name $Global:DscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:DscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:DscHelper.InitializeScript -NoNewScope

        $secpasswd = ConvertTo-SecureString "test@password1" -AsPlainText -Force
        $GlobalAdminAccount = New-Object System.Management.Automation.PSCredential ("tenantadmin", $secpasswd)

        Mock -CommandName Test-MSCloudLogin -MockWith {

        }

        Mock -CommandName Get-PSSession -MockWith {

        }
        Mock -CommandName Remove-PSSession -MockWith {

        }

        Mock -CommandName Remove-PNPOrgAssetsLibrary -MockWith {

        }

        Mock -CommandName Add-PnPOrgAssetsLibrary -MockWith {

        }

        Mock -CommandName Get-SPOAdministrationUrl -MockWith {
            return 'https://contoso-admin.sharepoint.com'
        }

        # Test contexts
        Context -Name "The site sssets srg library should exist but it DOES NOT" -Fixture {
            $testParams = @{
                IsSingleInstance   = "Yes"
                LibraryUrl         = "https://contoso.sharepoint.com/sites/GuestSharing/Branding"
                CdnType            = "Public"
                GlobalAdminAccount = $GlobalAdminAccount;
                Ensure             = "Present"
            }

            Mock -CommandName Get-PnPTenantCdnEnabled -MockWith {
                return { cdn = "Public" }
            }

            Mock -CommandName Get-PNPOrgAssetsLibrary -MockWith {
                return $null
            }
            It "Should return Values from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should be 'Absent'
                Assert-MockCalled -CommandName "Get-PNPOrgAssetsLibrary" -Exactly 1
            }
            It 'Should return false from the Test method' {
                Test-TargetResource @testParams | Should Be $false
            }
            It 'Should Create the site assets org libary from the Set method' {
                Set-TargetResource @testParams
                Assert-MockCalled -CommandName "Add-PNPOrgAssetsLibrary" -Exactly 1
            }
        }

        Context -Name "The site sssets srg library exists but it SHOULD NOT" -Fixture {
            $testParams = @{
                IsSingleInstance   = "Yes"
                LibraryUrl         = "https://contoso.sharepoint.com/sites/GuestSharing/Branding"
                CdnType            = "Public"
                GlobalAdminAccount = $GlobalAdminAccount;
                Ensure             = "Absent"
            }

            Mock -CommandName Get-PnPTenantCdnEnabled -MockWith {
                return { cdn = "Public" }
            }

            Mock -CommandName Get-PNPOrgAssetsLibrary -MockWith {
                return @{LibraryUrl = "https://contoso.sharepoint.com/sites/GuestSharing/Branding" }
            }

            It "Should return Values from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should be 'Present'
                Assert-MockCalled -CommandName "Get-PNPOrgAssetsLibrary" -Exactly 1
            }

            It 'Should return false from the Test method' {
                Test-TargetResource @testParams | Should Be $false
            }

            It 'Should Remove the site assets org library from the Set method' {
                Set-TargetResource @testParams
                Assert-MockCalled -CommandName "Remove-PNPOrgAssetsLibrary" -Exactly 1
            }
        }
        Context -Name "The site sssets org library Exists and Values are already in the desired state" -Fixture {
            $testParams = @{
                IsSingleInstance   = "Yes"
                LibraryUrl         = "https://contoso.sharepoint.com/sites/GuestSharing/Branding"
                CdnType            = "Public"
                GlobalAdminAccount = $GlobalAdminAccount;
                Ensure             = "Present"
            }

            Mock -CommandName Get-PnPTenantCdnEnabled -MockWith {
                return { cdn = "Public" }
            }


            Mock -CommandName Get-PNPOrgAssetsLibrary -MockWith {
                return @{
                    OrgAssetsLibraries = @{
                        LibraryUrl = @{
                            decodedurl = "sites/GuestSharing/Branding"
                        }
                    }
                    CdnType            = "Public"
                }
            }

            It "Should return Values from the Get method" {
                Get-TargetResource @testParams
                Assert-MockCalled -CommandName "Get-PNPOrgAssetsLibrary" -Exactly 1
            }

            It 'Should return true from the Test method' {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "The site sssets org library exists and values are NOT in the desired state" -Fixture {
            $testParams = @{
                IsSingleInstance   = "Yes"
                LibraryUrl         = "https://contoso.sharepoint.com/sites/GuestSharing/Branding"
                CdnType            = "Public"
                GlobalAdminAccount = $GlobalAdminAccount;
                Ensure             = "Present"
            }

            Mock -CommandName Get-PNPOrgAssetsLibrary -MockWith {
                return @{
                    IsSingleInstance   = "Yes"
                    LibraryUrl         = "https://contoso.sharepoint.com/sites/GuestSharing/Branding"
                    CdnType            = "Private"
                    GlobalAdminAccount = $GlobalAdminAccount;
                    Ensure             = "Present"
                }
            }

            Mock -CommandName Get-PnPTenantCdnEnabled -MockWith {
                return { cdn = "Public" }
            }

            It "Should return Values from the Get method" {
                Get-TargetResource @testParams
                Assert-MockCalled -CommandName "Get-PNPOrgAssetsLibrary" -Exactly 1
            }

            It 'Should return false from the Test method' {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call the Set method" {
                Set-TargetResource @testParams
                Assert-MockCalled -CommandName 'Add-PNPOrgAssetsLibrary' -Exactly 1
            }
        }

        Context -Name "ReverseDSC Tests" -Fixture {
            $testParams = @{
                GlobalAdminAccount = $GlobalAdminAccount
            }

            Mock -CommandName New-M365DSCConnection -MockWith {
                return "Credential"
            }

            Mock -CommandName Get-PnPTenantCdnEnabled -MockWith {
                return { cdn = "Private" }
            }

            Mock -CommandName Get-PNPOrgAssetsLibrary -MockWith {
                return @{
                    LibraryUrl = "https://contoso.sharepoint.com/sites/GuestSharing/Branding"
                    CdnType    = "Private"
                }
            }
            It "Should Reverse Engineer resource from the Export method" {
                Export-TargetResource @testParams
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:DscHelper.CleanupScript -NoNewScope
