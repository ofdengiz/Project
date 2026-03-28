# Site 1 Service Block Test Toolkit

Run this toolkit from `Jumpbox Windows (172.30.64.179)`.

Main entry points:

```powershell
cd $HOME\Desktop\test_service
powershell -ExecutionPolicy Bypass -File .\00_ServiceBlocks_Menu.ps1 -SelfTest
powershell -ExecutionPolicy Bypass -File .\00_ServiceBlocks_Menu.ps1
```

Useful direct-run examples:

```powershell
powershell -ExecutionPolicy Bypass -File .\00_ServiceBlocks_Menu.ps1 -MainOption 1 -SubOption 3
powershell -ExecutionPolicy Bypass -File .\00_ServiceBlocks_Menu.ps1 -MainOption 6
powershell -ExecutionPolicy Bypass -File .\00_ServiceBlocks_Menu.ps1 -MainOption 7
powershell -ExecutionPolicy Bypass -File .\00_ServiceBlocks_Menu.ps1 -MainOption 9
```

Menu layout:

- `1` Service Block 1
- `2` Service Block 2
- `3` Service Block 3
- `4` Service Block 4
- `5` Service Block 5
- `6` Run all automated Service Block tests
- `7` Show coverage review
- `8` Show physical inspection guide
- `9` Export summary

Notes:

- The toolkit shows both the check description and the command(s) used for each test.
- `Service Block 5 / Misc` includes automated iLO reachability checks, but the final physical role explanation is still a manual walkthrough by design.
- Results are written to `04_Results`.
