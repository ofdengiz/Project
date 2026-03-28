@{
    ToolkitVersion         = 'group6-v0.1'
    DefaultLinuxPassword   = 'Cisco123!'
    DefaultWindowsPassword = 'Cisco123!'
    ResultsRoot            = 'C:\Users\Stephen\Desktop\project\test\test_service-group6-v0.1\04_Results'
    ChecklistRoot          = 'C:\Users\Stephen\Desktop\project\test\test_service-group6-v0.1\03_Checklists'
    LocalNode              = 'Group6WinJump'

    Hosts = @{
        JumpboxWin10 = @{
            DisplayName = 'Site 1 Jumpbox Windows'
            Address     = '172.30.64.179'
            Type        = 'windows'
            Access      = 'local'
        }
        JumpboxUbuntu = @{
            DisplayName = 'Site 1 Jumpbox Ubuntu'
            Address     = '172.30.64.180'
            Type        = 'linux'
            Access      = 'ssh'
            LinuxUser   = 'admin'
        }
        OPNsense = @{
            DisplayName = 'Site 1 OPNsense'
            Address     = '172.30.64.1'
            Type        = 'network'
            Access      = 'gui'
            GuiPort     = 80
        }
        Proxmox = @{
            DisplayName = 'Site 1 Proxmox VE'
            Address     = '192.168.64.10'
            Type        = 'hypervisor'
            Access      = 'gui'
            GuiPort     = 8006
        }
        LabSwitch = @{
            DisplayName = 'Site 1 Lab Switch'
            Address     = '192.168.64.2'
            Type        = 'switch'
            Access      = 'ssh'
            GuiPort     = 22
        }
        Server2 = @{
            DisplayName = 'Site 1 Server2 / Veeam'
            Address     = '192.168.64.20'
            Type        = 'windows'
            Access      = 'winrm'
            WindowsUser = 'administrator'
        }
        Server1iLO = @{
            DisplayName = 'Server1 / Proxmox host iLO'
            Address     = '192.168.64.11'
            Type        = 'oobm'
            Access      = 'gui'
            GuiPort     = 443
        }
        Server2iLO = @{
            DisplayName = 'Server2 iLO'
            Address     = '192.168.64.21'
            Type        = 'oobm'
            Access      = 'gui'
            GuiPort     = 443
        }
        C1DC1 = @{
            DisplayName = 'Site 1 C1-DC1'
            Address     = '172.30.64.130'
            Type        = 'windows'
            Access      = 'winrm'
            WindowsUser = 'administrator'
        }
        C1DC2 = @{
            DisplayName = 'Site 1 C1-DC2'
            Address     = '172.30.64.131'
            Type        = 'windows'
            Access      = 'winrm'
            WindowsUser = 'administrator'
        }
        C1Client1 = @{
            DisplayName = 'Site 1 C1-Client1'
            Address     = '172.30.64.2'
            Type        = 'windows'
            Access      = 'winrm'
            WindowsUser = 'c1.local\Administrator'
        }
        C1Client2 = @{
            DisplayName = 'Site 1 C1-Client2'
            Address     = '172.30.64.3'
            Type        = 'linux'
            Access      = 'ssh'
            LinuxUser   = 'admin'
        }
        C1Web = @{
            DisplayName = 'Site 1 C1-WebServer'
            Address     = '172.30.64.162'
            Type        = 'windows'
            Access      = 'rdp'
            WindowsUser = 'administrator'
            GuiPort     = 443
        }
        C2DC1 = @{
            DisplayName = 'Site 1 C2-DC1'
            Address     = '172.30.64.146'
            Type        = 'linux'
            Access      = 'ssh'
            LinuxUser   = 'admindc'
        }
        C2DC2 = @{
            DisplayName = 'Site 1 C2-DC2'
            Address     = '172.30.64.147'
            Type        = 'linux'
            Access      = 'ssh'
            LinuxUser   = 'admindc'
        }
        C2Client1 = @{
            DisplayName = 'Site 1 C2-Client1'
            Address     = '172.30.64.66'
            Type        = 'linux'
            Access      = 'ssh'
            LinuxUser   = 'admin'
        }
        C2Web = @{
            DisplayName = 'Site 1 C2-WebServer'
            Address     = '172.30.64.170'
            Type        = 'web'
            Access      = 'https'
            GuiPort     = 443
        }
        Site2Repo = @{
            DisplayName = 'Site 2 Offsite Shared Repository'
            Address     = '172.30.65.180'
            Type        = 'remote'
            Access      = 'smb'
            GuiPort     = 445
        }

        # Site 2 host usernames below are aligned to the current documented/admin workflow.
        # If a local admin name differs in your environment, update only the LinuxUser or
        # WindowsUser field here without touching the test logic.
        Site2Jump64 = @{
            DisplayName = 'Site 2 Jump64'
            Address     = '172.30.65.178'
            Type        = 'windows'
            Access      = 'rdp'
            WindowsUser = 'Administrator'
            GuiPort     = 3389
        }
        Site2MSPUbuntuJump = @{
            DisplayName = 'Site 2 MSPUbuntuJump'
            Address     = '172.30.65.179'
            Type        = 'linux'
            Access      = 'ssh'
            LinuxUser   = 'admin'
        }
        Site2OPNsense = @{
            DisplayName = 'Site 2 OPNsense'
            Address     = '172.30.65.177'
            Type        = 'network'
            Access      = 'gui'
            GuiPort     = 80
        }
        S2Veeam = @{
            DisplayName = 'Site 2 S2Veeam'
            Address     = '172.30.65.180'
            Type        = 'windows'
            Access      = 'winrm'
            WindowsUser = 'Administrator'
        }
        S2C1DC1 = @{
            DisplayName = 'Site 2 C1DC1'
            Address     = '172.30.65.2'
            Type        = 'windows'
            Access      = 'winrm'
            WindowsUser = 'C1\Administrator'
        }
        S2C1DC2 = @{
            DisplayName = 'Site 2 C1DC2'
            Address     = '172.30.65.3'
            Type        = 'windows'
            Access      = 'winrm'
            WindowsUser = 'C1\Administrator'
        }
        S2C1FS = @{
            DisplayName = 'Site 2 C1FS'
            Address     = '172.30.65.4'
            Type        = 'windows'
            Access      = 'winrm'
            WindowsUser = 'C1\Administrator'
        }
        S2C1WindowsClient = @{
            DisplayName = 'Site 2 C1WindowsClient'
            Address     = '172.30.65.11'
            Type        = 'windows'
            Access      = 'winrm'
            WindowsUser = 'C1\Administrator'
        }
        S2C1UbuntuClient = @{
            DisplayName = 'Site 2 C1UbuntuClient'
            Address     = '172.30.65.36'
            Type        = 'linux'
            Access      = 'ssh'
            LinuxUser   = 'Administrator'
        }
        S2C1Web = @{
            DisplayName = 'Site 2 C1WebServer'
            Address     = '172.30.65.162'
            Type        = 'web'
            Access      = 'https'
            GuiPort     = 443
        }
        S2C1SAN = @{
            DisplayName = 'Site 2 C1SAN'
            Address     = '172.30.65.186'
            Type        = 'san'
            Access      = 'iscsi'
            GuiPort     = 3260
        }
        S2C2IdM1 = @{
            DisplayName = 'Site 2 C2IdM1'
            Address     = '172.30.65.66'
            Type        = 'linux'
            Access      = 'ssh'
            LinuxUser   = 'admin'
        }
        S2C2IdM2 = @{
            DisplayName = 'Site 2 C2IdM2'
            Address     = '172.30.65.67'
            Type        = 'linux'
            Access      = 'ssh'
            LinuxUser   = 'admin'
        }
        S2C2FS = @{
            DisplayName = 'Site 2 C2FS'
            Address     = '172.30.65.68'
            Type        = 'linux'
            Access      = 'ssh'
            LinuxUser   = 'admin'
        }
        S2C2LinuxClient = @{
            DisplayName = 'Site 2 C2LinuxClient'
            Address     = '172.30.65.70'
            Type        = 'linux'
            Access      = 'ssh'
            LinuxUser   = 'admin'
        }
        S2C2Web = @{
            DisplayName = 'Site 2 C2WebServer'
            Address     = '172.30.65.170'
            Type        = 'web'
            Access      = 'https'
            GuiPort     = 443
        }
        S2C2SAN = @{
            DisplayName = 'Site 2 C2SAN'
            Address     = '172.30.65.194'
            Type        = 'san'
            Access      = 'iscsi'
            GuiPort     = 3260
        }
    }
}
