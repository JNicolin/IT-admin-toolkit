# IT admin toolkit

A simple PowerShell toolkit for daily Microsoft 365 administration.

The goal of the toolkit is:

- clear separation between installation, connection, and day‑2 scripts  
- simple per‑tenant local configuration  
- easy to extend without being locked into a heavy framework  

## Structure

- `bootstrap.ps1`  
  Installs base modules.

- `connect.ps1`  
  Connects to Exchange Online, Microsoft Graph, Teams and PnP.

- `validate.ps1`  
  Runs quick checks to verify that the session is working.

- `disconnect.ps1`  
  Disconnects the sessions.

- `common.ps1`  
  Shared helper functions.

- `config.sample.ps1`  
  Template for tenant-specific configuration. Copy to `config.ps1` locally.

- `scripts/autopilot.ps1`  
  Intune / Autopilot-related listing and export commands.

- `scripts/entra.ps1`  
  Entra / Graph-related queries for users and groups.

- `scripts/exchange.ps1`  
  Basic Exchange admin tasks for audit status.

- `scripts/sharepoint.ps1`  
  Basic PnP-based SharePoint site context and site information.

---

## Base modules

The toolkit relies on:

- ExchangeOnlineManagement  
- Microsoft Graph PowerShell submodules  
- MicrosoftTeams  
- PnP.PowerShell  

Optional:

- Az.Accounts  
- Microsoft.Graph.Beta.DeviceManagement.Enrollment  

---

## Why these modules

Exchange Online PowerShell uses modern authentication via `Connect-ExchangeOnline`.  
Microsoft Graph PowerShell uses `Connect-MgGraph` and requires authentication before running cmdlets.  
Teams uses `Connect-MicrosoftTeams`.  

PnP PowerShell is cross-platform (Windows, macOS, Linux) and is the recommended way to work with SharePoint in PowerShell 7 environments, especially on Mac.

---

## Enterprise baseline covered

This toolkit covers what is typically needed for a Microsoft 365 enterprise admin:

- Exchange Online administration  
- Entra ID / Graph queries  
- Intune managed devices via Graph  
- Windows Autopilot device identities via Graph  
- Teams connectivity and validation  
- SharePoint Online via PnP PowerShell  

---

## Initial setup (first time)

1. Copy config template
2. Fill in values
3. Install modules
4. Connect
5. Validate

```powershell
Copy-Item ./config.sample.ps1 ./config.ps1
pwsh ./bootstrap.ps1
pwsh ./connect.ps1 -ShowCommands
pwsh ./validate.ps1
```
--- 

## Setup on a new device

1. Clone the repo

   - git clone https://github.com/JNicolin/IT-admin-toolkit.git  
   - cd IT-admin-toolkit

2. Create local config

     Copy config file:

     - cp config.sample.ps1 config.ps1

     Edit config.ps1 and fill in:

     - TenantId    = 'your-tenant-id'  
     - AdminUpn    = 'your-admin-upn'  
     - PnPClientId = 'your-app-id'

3. Install modules

    - pwsh ./bootstrap.ps1

4. Connect to services

   - pwsh ./connect.ps1

5. Validate setup

   - pwsh ./validate.ps1

   This will authenticate and connect:

     - Exchange Online  
     - Microsoft Graph  
     - Microsoft Teams  
     - SharePoint (PnP)

6. Daily usage

    For daily usage:

     - pwsh ./connect.ps1
```