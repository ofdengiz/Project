Site 1 Test Toolkit Review Changes - 2026-03-25

Files copied into this folder are the active files that were changed after reviewing:

- `test_service-site1-v0.1\01_Config\LabConfig.psd1`
- `test_service-site1-v0.1\02_Modules\Group6.Tests.psm1`

Final applied change set:

1. Hardened the `Site 2 C2LinuxClient per-user share access summary` SMB read-only checks.
   - The toolkit now retries the `smbclient ... -c ''ls''` access probe up to three times
     when the specific transient error `NT_STATUS_IO_TIMEOUT` is returned.
   - This was kept because the environment already showed evidence that a one-off
     tree-connect timeout can fail the first `admin -> C2_Public` probe even when
     later checks in the same run succeed.

Config review outcome:

- `JumpboxUbuntu = admnin` was reviewed and restored to the source-of-truth inventory value.
- `S2C1UbuntuClient = Administrator` was reviewed and restored to the source-of-truth inventory value.
- `C2DC1` / `C2DC2 = admindc` were left unchanged because the active log already shows those tests passing.
- Site 1 / Site 2 OPNsense GUI ports were left unchanged because the Site 1 workbook and Site 1 final documentation still reference the GUI on port `80`.

Recommended next validation pass:

1. Re-run the active toolkit using the updated files.
2. Pay special attention to `Site 2 C2LinuxClient per-user share access summary`.
3. If web-enforcement failures remain, treat them as live environment web-binding / firewall issues rather than toolkit username issues.
