# Site 2 Service Block Test Toolkit

This folder mirrors the Site 1 testing layout for Site 2.

Main result location:

- `04_Results`

Primary collector:

- `02_Modules\collect_site2_tests.py`

Notes:

- Veeam checks are intentionally excluded for this run.
- The collector uses:
  - direct local port checks
  - Tailscale SSH to `MSPUbuntuJump`
  - remote WMI execution on `WindowsJump64`
- Results are exported as:
  - timestamped summary
  - session log
  - raw JSON and command output files
