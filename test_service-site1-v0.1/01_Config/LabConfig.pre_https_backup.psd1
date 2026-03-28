@{
    ToolkitVersion         = '1.0'
    DefaultLinuxPassword   = 'Cisco123!'
    DefaultWindowsPassword = 'Cisco123!'
    ResultsRoot            = 'C:\Users\Stephen\Desktop\test_service\04_Results'
    ChecklistRoot          = 'C:\Users\Stephen\Desktop\test_service\03_Checklists'
    LocalNode              = 'JumpboxWin10'

    Hosts = @{
        JumpboxWin10 = @{
            DisplayName = 'Jumpbox Windows'
            Address     = '172.30.64.179'
            Type        = 'windows'
            Access      = 'local'
        }
        JumpboxUbuntu = @{
            DisplayName = 'Jumpbox Ubuntu'
            Address     = '172.30.64.180'
            Type        = 'linux'
            Access      = 'ssh'
            LinuxUser   = 'admnin'
        }
        OPNsense = @{
            DisplayName = 'OPNsense'
            Address     = '172.30.64.1'
            Type        = 'network'
            Access      = 'gui'
            GuiPort     = 80
        }
        Proxmox = @{
            DisplayName = 'Proxmox VE'
            Address     = '192.168.64.10'
            Type        = 'hypervisor'
            Access      = 'gui'
            GuiPort     = 8006
        }
        LabSwitch = @{
            DisplayName = 'Lab Switch'
            Address     = '192.168.64.2'
            Type        = 'switch'
            Access      = 'ssh'
            GuiPort     = 22
        }
        Server2 = @{
            DisplayName = 'Server2'
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
            DisplayName = 'C1-DC1'
            Address     = '172.30.64.130'
            Type        = 'windows'
            Access      = 'winrm'
            WindowsUser = 'administrator'
        }
        C1DC2 = @{
            DisplayName = 'C1-DC2'
            Address     = '172.30.64.131'
            Type        = 'windows'
            Access      = 'winrm'
            WindowsUser = 'administrator'
        }
        C1Client1 = @{
            DisplayName = 'C1-Client1'
            Address     = '172.30.64.2'
            Type        = 'windows'
            Access      = 'winrm'
            WindowsUser = 'c1.local\Administrator'
        }
        C1Client2 = @{
            DisplayName = 'C1-Client2'
            Address     = '172.30.64.3'
            Type        = 'linux'
            Access      = 'ssh'
            LinuxUser   = 'admin'
        }
        C1Web = @{
            DisplayName = 'C1-WebServer'
            Address     = '172.30.64.162'
            Type        = 'windows'
            Access      = 'rdp'
            WindowsUser = 'administrator'
            GuiPort     = 80
        }
        C2DC1 = @{
            DisplayName = 'C2-DC1'
            Address     = '172.30.64.146'
            Type        = 'linux'
            Access      = 'ssh'
            LinuxUser   = 'admindc'
        }
        C2DC2 = @{
            DisplayName = 'C2-DC2'
            Address     = '172.30.64.147'
            Type        = 'linux'
            Access      = 'ssh'
            LinuxUser   = 'admindc'
        }
        C2Client1 = @{
            DisplayName = 'C2-Client1'
            Address     = '172.30.64.66'
            Type        = 'linux'
            Access      = 'ssh'
            LinuxUser   = 'admin'
        }
        C2Web = @{
            DisplayName = 'C2-WebServer'
            Address     = '172.30.64.170'
            Type        = 'web'
            Access      = 'http'
            GuiPort     = 80
        }
        Site2Repo = @{
            DisplayName = 'Site 2 Offsite Repository'
            Address     = '172.30.65.180'
            Type        = 'remote'
            Access      = 'network'
            GuiPort     = 6160
        }
    }
}
