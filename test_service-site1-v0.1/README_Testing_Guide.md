# Group 6 Cross-Site Self-Test Toolkit

Run this toolkit from either approved Win10 jumpbox before the final live demonstration.

Primary entry points:

```powershell
cd $HOME\Desktop\test_service-group6-v0.1
powershell -ExecutionPolicy Bypass -File .\00_ServiceBlocks_Menu.ps1 -SelfTest
powershell -ExecutionPolicy Bypass -File .\00_ServiceBlocks_Menu.ps1
```

Useful direct-run examples:

```powershell
powershell -ExecutionPolicy Bypass -File .\00_ServiceBlocks_Menu.ps1 -MainOption 1
powershell -ExecutionPolicy Bypass -File .\00_ServiceBlocks_Menu.ps1 -MainOption 2
powershell -ExecutionPolicy Bypass -File .\00_ServiceBlocks_Menu.ps1 -MainOption 8
powershell -ExecutionPolicy Bypass -File .\00_ServiceBlocks_Menu.ps1 -MainOption 9
powershell -ExecutionPolicy Bypass -File .\00_ServiceBlocks_Menu.ps1 -MainOption M
powershell -ExecutionPolicy Bypass -File .\00_ServiceBlocks_Menu.ps1 -MainOption E
```

Menu layout:

- `1` Hotseat 1 integrated self-test
- `2` Hotseat 2 integrated self-test
- `3` Service Block 1 across both sites
- `4` Service Block 2 across both sites
- `5` Service Block 3 across both sites
- `6` Service Block 4 across both sites
- `7` Service Block 5 across both sites
- `8` Run all automated Group 6 tests
- `9` Show Group 6 coverage review
- `M` Show manual follow-up guide
- `E` Export summary report

Notes:

- The toolkit is organized by company / hotseat responsibility rather than by separate Site 1 and Site 2 demo phases.
- `01_Config\LabConfig.psd1` contains the host inventory and admin usernames for both sites. Update only the `LinuxUser` or `WindowsUser` values if your environment differs.
- Results are written to `04_Results`.
- `03_Checklists\service block-group6-v0.1.xlsx` is the matching single-sheet checklist used to record live observations.
