# Site 2 Live Inspection Summary - 2026-03-27

Live inspection artifacts for the current pass are stored in:
- C:\Algonquin\Winter2026\Emerging_Tech\Project\site2_v42_live_2026-03-27_2026-03-27_162602

Key outcomes:
- MSPUbuntuJump and Jump64 were both used as active management vantage points.
- Jump64 provided direct Windows-side inspection into C1DC1, C1DC2, C1FS, C1WebServer, C1WindowsClient, and S2Veeam.
- C1WebServer was confirmed as a workgroup-hosted IIS node managed through its local administrator context.
- C1WindowsClient was confirmed as domain-joined and able to resolve and reach both internal web hostnames through Jump64-managed WMI or SMB-backed remote execution, even though WinRM on 5985 was closed.
- C1FS showed a dedicated F: SharedData volume, Company 1 shares, and an active iSCSI session.
- OPNsense responded on port 80 with HTTP 403 and on port 53 with TCP success from MSPUbuntuJump; port 443 timed out from the same path.
- S2Veeam was reachable from MSP and was also administratively operable from Jump64 using .\Administrator.
