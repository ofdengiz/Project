# Site 2 Test Toolkit Snapshot

This folder mirrors the intent of `Site1test`, but it captures the read-only validation run completed for Site 2 on `2026-03-15`.

## Scope

- MSP public management path
- Ubuntu MSP jumpbox network baseline
- Company 1 Windows server reachability
- Company 2 identity, storage, sync, and client identity
- Inter-site connectivity toward Site 1

## Important notes

- No configuration changes were made during this test run.
- Commands were executed through the MSP jump path outside the sandbox, as requested.
- Windows jump deep automation from the local machine was limited because RPC/WMI to `10.50.17.31` was unavailable during this run.
- Raw command output is stored in `04_Results/raw`.

## Key findings at a glance

- Windows jump public RDP path: `PASS`
- Ubuntu jump public SSH path: `PASS`
- Company 1 DC management ports: `PASS`
- Company 2 DC core service and recursive DNS checks: `PASS`
- Company 2 file server mount and sync automation: `PASS`
- Company 2 Linux client domain identity resolution: `PASS`
- Company 1 web path: `FAIL`
- Site 2 Veeam host management/control ports from jump path: `FAIL`
- Detailed Samba replication automation on `C2IdM1` and `C2IdM2`: `REVIEW` because privileged output was not fully captured in the final automated step

## Output files

- `04_Results/latest_session.log`
- `20260315_154707_Summary.txt`
- `04_Results/raw/*.txt`
