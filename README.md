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

---


## PnP PowerShell

PnP PowerShell is used for SharePoint administration and automation.  
It provides a modern, cross-platform way of working with SharePoint Online, especially from PowerShell 7 and macOS where legacy modules are limited.

It is required in this toolkit for:

- accessing SharePoint site data  
- managing site context and structure  
- enabling automation scenarios  

### Setup PnP (one-time)

PnP requires your own Entra ID app registration for authentication.

Run the following command in PowerShell:

```zsh
Register-PnPEntraIDAppForInteractiveLogin -ApplicationName "PnP.PowerShell" -Tenant <your-tenant-id>
```

A browser window will open:

- sign in with your admin account  
- accept permissions  

After completion, you will get:

- Azure App ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

Copy this value and add it to config.ps1:

- PnPClientId = 'your-app-id'

### Usage

PnP is automatically used when running:

```zsh
pwsh ./connect.ps1
```

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

## Setup on a new device

### 1. Clone the repo

 ```zsh
 git clone https://github.com/JNicolin/IT-admin-toolkit.git  
 cd IT-admin-toolkit
 ```

### 2. Create local config

Copy config file:

 ```zsh
 cp config.sample.ps1 config.ps1
 ```

Edit config.ps1 and fill in:

- TenantId    = 'your-tenant-id'  
- AdminUpn    = 'your-admin-upn'  
- PnPClientId = 'your-app-id'

Note: If you have not created a PnP app registration yet, follow the steps in the PnP PowerShell section above before continuing.

### 3. Install modules

This is a one time per device action. Installation of modules. No need to run it again after a device restart. 

```zsh 
pwsh ./bootstrap.ps1 
```

### 4. Connect to services

This action shall be completed at each new session. After a restart of device or login of user. 

```zsh
pwsh ./connect.ps1
```

### 5. Validate setup

```zsh
pwsh ./validate.ps1
```

This will authenticate and connect:

- Exchange Online  
- Microsoft Graph  
- Microsoft Teams  
- SharePoint (PnP)

---
## Daily workflow

Use this workflow for day-to-day usage of the toolkit.

### 1. Open the repository

Navigate to your local repository:

```zsh
cd IT-admin-toolkit
```

---

### 2. Update from GitHub (recommended)

Pull the latest changes before starting work:

```zsh
git pull
````

---

### 3. Connect to services

Start your session:

```zsh
pwsh ./connect.ps1
```

This will authenticate and connect:

- Exchange Online  
- Microsoft Graph  
- Microsoft Teams  
- SharePoint (PnP)

---

### 4. Run scripts

Examples:

```zsh
pwsh ./scripts/autopilot.ps1 -ListAutopilotDevices  
pwsh ./scripts/entra.ps1 -ListUsers  
pwsh ./scripts/exchange.ps1 -ShowAuditStatus  
```

---

### 5. Save changes (if you modify scripts)

```zsh
git add .  
git commit -m "Describe your change"  
git push  
```

---

### Notes

- bootstrap.ps1 is only needed on first setup or when adding modules  
- connect.ps1 should be run for each new session  
- config.ps1 is local and should not be committed to GitHub. It is therefor noted in the .gitignore file
