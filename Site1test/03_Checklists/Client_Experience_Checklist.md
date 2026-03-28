# Client Experience Checklist

Related document sections:
- `3.3 Identity Services`
- `3.6 DNS and DHCP`
- `3.7 Storage and SAN Services`
- `3.8.2 Client Backup Agent`
- `3.9.1 Company Branding through Group Policy (Company 1)`
- `3.10.2 Administrative Access`

Show these items on `C1-Client1`:
- User logon under the Company 1 domain
- Client DNS settings point to the expected Company 1 domain controllers
- Desktop branding or wallpaper result from Group Policy
- Access to the expected Company 1 shared folders
- Clear distinction between public and private user access behavior
- Veeam Agent presence in Programs and Features, Services, or the system tray

Show these items on `C1-Client2`:
- Linux client sign-in or shell access path
- Mounted `C1_Public` and `C1_Private` locations
- Public share visibility for collaboration
- Private share isolation per user
- SSH administration path if the teacher asks for Linux client validation

Show these items on `C2-Client1`:
- User logon under the Company 2 domain
- Mounted `C2_Public` and `C2_Private`
- Public share visibility for collaboration
- Private share isolation per user
- SSH access path if the teacher asks for Linux client administration

Expected result:
- User experience aligns with the document narrative
- Client-visible access control matches the final report
