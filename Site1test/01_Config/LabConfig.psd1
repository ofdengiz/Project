@{
    ToolkitVersion = '1.0'
    DefaultLinuxPassword = 'Cisco123!'
    DefaultWindowsPassword = 'Cisco123!'
    ResultsRoot    = 'C:\Users\Stephen\Desktop\test\04_Results'
    ChecklistRoot  = 'C:\Users\Stephen\Desktop\test\03_Checklists'
    LocalNode      = 'JumpboxWin10'

    Hosts = @{
        JumpboxWin10 = @{
            DisplayName = 'Jumpbox Windows'
            Address     = '172.30.64.179'
            Type        = 'windows'
            Access      = 'local'
            DocSections = @('3.9.4', '3.10.2')
        }
        JumpboxUbuntu = @{
            DisplayName = 'Jumpbox Ubuntu'
            Address     = '172.30.64.180'
            Type        = 'linux'
            Access      = 'ssh'
            LinuxUser   = 'admnin'
            DocSections = @('3.9.2', '3.10.2')
        }
        OPNsense = @{
            DisplayName = 'OPNsense'
            Address     = '172.30.64.1'
            Type        = 'network'
            Access      = 'gui'
            GuiPort     = 80
            DocSections = @('3.2', '3.10.1', '3.10.2')
        }
        Proxmox = @{
            DisplayName = 'Proxmox VE'
            Address     = '192.168.64.10'
            Type        = 'hypervisor'
            Access      = 'gui'
            GuiPort     = 8006
            DocSections = @('3.5', '3.10.2')
        }
        LabSwitch = @{
            DisplayName = 'Lab Switch'
            Address     = '192.168.64.2'
            Type        = 'switch'
            Access      = 'ssh'
            GuiPort     = 22
            DocSections = @('3.4.2', '3.10.2')
        }
        Server2 = @{
            DisplayName = 'Server2 Windows Storage and Backup'
            Address     = '192.168.64.20'
            Type        = 'windows'
            Access      = 'winrm'
            WindowsUser = 'administrator'
            DocSections = @('3.7', '3.8')
        }
        C1DC1 = @{
            DisplayName = 'C1-DC1'
            Address     = '172.30.64.130'
            Type        = 'windows'
            Access      = 'winrm'
            WindowsUser = 'administrator'
            DocSections = @('3.3', '3.6', '3.7')
        }
        C1DC2 = @{
            DisplayName = 'C1-DC2'
            Address     = '172.30.64.131'
            Type        = 'windows'
            Access      = 'winrm'
            WindowsUser = 'administrator'
            DocSections = @('3.3', '3.6', '3.7')
        }
        C1Client1 = @{
            DisplayName = 'C1-Client1'
            Address     = '172.30.64.2'
            Type        = 'windows'
            Access      = 'winrm'
            WindowsUser = 'admin'
            DocSections = @('3.6', '3.7', '3.8.2', '3.9.1')
        }
        C1Client2 = @{
            DisplayName = 'C1-Client2'
            Address     = '172.30.64.3'
            Type        = 'linux'
            Access      = 'ssh'
            LinuxUser   = 'admin'
            DocSections = @('3.7', '3.10.2')
        }
        C2DC1 = @{
            DisplayName = 'C2-DC1'
            Address     = '172.30.64.146'
            Type        = 'linux'
            Access      = 'ssh'
            LinuxUser   = 'admindc'
            DocSections = @('3.3', '3.6', '3.7', '3.9.3')
        }
        C2DC2 = @{
            DisplayName = 'C2-DC2'
            Address     = '172.30.64.147'
            Type        = 'linux'
            Access      = 'ssh'
            LinuxUser   = 'admindc'
            DocSections = @('3.3', '3.6', '3.7', '3.9.3')
        }
        C2Client1 = @{
            DisplayName = 'C2-Client1'
            Address     = '172.30.64.66'
            Type        = 'linux'
            Access      = 'ssh'
            LinuxUser   = 'admin'
            DocSections = @('3.6', '3.7', '3.10.2')
        }
        C1Web = @{
            DisplayName = 'C1 Web Server'
            Address     = '172.30.64.162'
            Type        = 'web'
            Access      = 'gui'
            GuiPort     = 80
            DocSections = @('3.2', '3.10')
        }
        C2Web = @{
            DisplayName = 'C2 Web Server'
            Address     = '172.30.64.170'
            Type        = 'web'
            Access      = 'gui'
            GuiPort     = 80
            DocSections = @('3.2', '3.10')
        }
        Site2Repo = @{
            DisplayName = 'Site 2 Offsite Repository'
            Address     = '172.30.65.180'
            Type        = 'remote'
            Access      = 'network'
            GuiPort     = 6160
            DocSections = @('3.8.3', '3.10.1')
        }
    }

    Checklists = @{
        Proxmox = @{
            File        = 'Proxmox_Server1_Checklist.md'
            Description = 'GUI walkthrough for Proxmox inventory, templates, and management views.'
            DocSections = @('3.5', '3.10.2')
        }
        Server2 = @{
            File        = 'Server2_Storage_Backup_Checklist.md'
            Description = 'GUI walkthrough for Windows storage, iSCSI targets, and Veeam.'
            DocSections = @('3.7', '3.8')
        }
        OPNsense = @{
            File        = 'OPNsense_Checklist.md'
            Description = 'GUI walkthrough for VLANs, routing, firewall policy, and VPN.'
            DocSections = @('3.2', '3.10.1', '3.10.2')
        }
        LabSwitch = @{
            File        = 'Lab_Switch_Checklist.md'
            Description = 'CLI or SSH walkthrough for trunks, access ports, and upstream handoff.'
            DocSections = @('3.4.2')
        }
        WebApps = @{
            File        = 'Web_Applications_Checklist.md'
            Description = 'Browser checks for C1 and C2 web applications.'
            DocSections = @('3.2', '3.10')
        }
        ValueAdd = @{
            File        = 'Value_Added_GUI_Checklist.md'
            Description = 'GUI checks for Grafana, Cockpit, and Windows Admin Center.'
            DocSections = @('3.9.2', '3.9.3', '3.9.4')
        }
        ClientAccess = @{
            File        = 'Client_Experience_Checklist.md'
            Description = 'Manual checks for client identity, DNS, backup agent presence, branding, mapped shares, and private/public access behavior.'
            DocSections = @('3.3', '3.6', '3.7', '3.8.2', '3.9.1', '3.10.2')
        }
    }
}
