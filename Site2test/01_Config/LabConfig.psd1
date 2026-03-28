@{
    ToolkitVersion = '0.1'
    ResultsRoot    = 'C:\Algonquin\Winter2026\Emerging_Tech\Project\Site2test\04_Results'
    LocalNode      = 'OperatorWorkstation'

    Hosts = @{
        WindowsJump = @{
            DisplayName = 'Windows Jump'
            Address     = '10.50.17.31:33464'
            Type        = 'windows'
            Access      = 'rdp'
        }
        UbuntuJump = @{
            DisplayName = 'Ubuntu Jump'
            Address     = '10.50.17.31:33564'
            Type        = 'linux'
            Access      = 'ssh'
        }
        C1DC1 = @{
            DisplayName = 'C1DC1'
            Address     = '172.30.65.2'
            Type        = 'windows'
        }
        C1DC2 = @{
            DisplayName = 'C1DC2'
            Address     = '172.30.65.3'
            Type        = 'windows'
        }
        C1FS = @{
            DisplayName = 'C1FS'
            Address     = '172.30.65.4'
            Type        = 'windows'
        }
        C1Web = @{
            DisplayName = 'C1 Web'
            Address     = '172.30.65.162'
            Type        = 'web'
        }
        C2IdM1 = @{
            DisplayName = 'C2IdM1'
            Address     = '172.30.65.66'
            Type        = 'linux'
        }
        C2IdM2 = @{
            DisplayName = 'C2IdM2'
            Address     = '172.30.65.67'
            Type        = 'linux'
        }
        C2FS = @{
            DisplayName = 'C2FS'
            Address     = '172.30.65.68'
            Type        = 'linux'
        }
        C2LinuxClient = @{
            DisplayName = 'C2LinuxClient'
            Address     = '172.30.65.70'
            Type        = 'linux'
        }
        Site2Veeam = @{
            DisplayName = 'Site2 Veeam'
            Address     = '172.30.65.180'
            Type        = 'windows'
        }
    }
}
