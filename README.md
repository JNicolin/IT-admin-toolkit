# IT admin toolkit

A practical PowerShell toolkit for Microsoft 365 administration.

This repository gives IT administrators a simple and repeatable way to:

- connect to Microsoft 365 services
- run common operational tasks
- reuse and extend scripts over time
- keep setup and daily usage consistent across devices

Instead of writing scripts from scratch each time, this toolkit provides a clean starting point for installation, connection, and operational work.

## Quick start

### First-time setup

```powershell
Copy-Item ./config.sample.ps1 ./config.ps1
pwsh ./bootstrap.ps1
pwsh ./connect.ps1
pwsh ./validate.ps1
```

### Daily usage

```powershell
pwsh
. ./connect.ps1
./scripts/entra.ps1 -ListUsers
```

## Design principles

- clear separation between installation, connection, and operational scripts
- simple per-tenant local configuration
- easy to extend without heavy frameworks
- consistent output handling via shared helper functions

In this toolkit:

- **bootstrap** installs required modules
- **connect** establishes authenticated sessions
- **operational scripts** perform actual admin work such as lookups, validation, export, and troubleshooting

## Repository structure

- `bootstrap.ps1`  
  Installs required modules.

- `connect.ps1`  
  Connects to Exchange Online, Microsoft Graph, Teams, and PnP.

- `validate.ps1`  
  Verifies that sessions are working.

- `disconnect.ps1`  
  Disconnects active sessions.

- `common.ps1`  
  Shared helper functions.

- `config.sample.ps1`  
  Template for tenant-specific configuration. Copy to `config.ps1` locally.

- `scripts/autopilot.ps1`  
  Intune / Autopilot queries and exports.

- `scripts/entra.ps1`  
  Entra / Graph queries for users and groups.

- `scripts/exchange.ps1`  
  Exchange admin tasks.

- `scripts/sharepoint.ps1`  
  SharePoint operations via PnP.

## Base modules

The toolkit uses:

- `ExchangeOnlineManagement`
- `Microsoft.Graph.Authentication`
- `Microsoft.Graph.Users`
- `Microsoft.Graph.Groups`
- `Microsoft.Graph.Identity.DirectoryManagement`
- `Microsoft.Graph.DeviceManagement`
- `Microsoft.Graph.DeviceManagement.Enrollment`
- `Microsoft.Graph.Identity.SignIns`
- `MicrosoftTeams`
- `PnP.PowerShell`

Optional:

- `Az.Accounts`
- `Microsoft.Graph.Beta.DeviceManagement.Enrollment`

## Why these modules

The modules are selected to cover the core Microsoft 365 workloads while keeping responsibilities separated.

- **ExchangeOnlineManagement**  
  Used for Exchange administration such as audit settings, mailbox-related administration, and Exchange-specific operations.

- **Microsoft Graph PowerShell**  
  Used for identity, users, groups, and devices. This is the main interface for Entra ID, Intune device data, and directory-driven administration.

- **MicrosoftTeams**  
  Used for Teams-specific administration such as tenant settings and policy work.

- **PnP.PowerShell**  
  Used for SharePoint administration and automation using a modern cross-platform approach that works well with PowerShell 7.

Together, these modules provide coverage across identity, messaging, collaboration, and content.

## PnP PowerShell

PnP is used for SharePoint administration and automation.

PnP requires your own Entra ID app registration.

Run:

```powershell
Register-PnPEntraIDAppForInteractiveLogin -ApplicationName "PnP.PowerShell" -Tenant <your-tenant-id>
```

After sign-in, copy the App ID and add it to `config.ps1`:

```powershell
PnPClientId = 'your-app-id'
```

PnP is then used automatically by `connect.ps1`.

## Enterprise baseline covered

This toolkit covers the main administrative workloads in a Microsoft 365 environment:

- Exchange administration and audit
- Entra ID / Graph queries
- Intune managed devices
- Windows Autopilot device identities
- Teams connectivity and validation
- SharePoint administration via PnP

## Output model
All scripts use a shared helper:

- Show-ToolkitOutput
- Export-ToolkitCsv

This ensures:

- consistent formatting across scripts
- optional table view (-Table)
- unified export behavior

## Setup on a new device

### 1. Clone the repository

```bash
git clone https://github.com/JNicolin/IT-admin-toolkit.git
cd IT-admin-toolkit
```

### 2. Create local configuration

```bash
cp config.sample.ps1 config.ps1
```

Edit `config.ps1` and fill in:

```powershell
TenantId    = 'your-tenant-id'
AdminUpn    = 'your-admin-upn'
PnPClientId = 'your-app-id'
```

If the PnP app registration has not been created yet, complete the PnP setup section above first.

### 3. Install modules

Run once per device:

```powershell
pwsh ./bootstrap.ps1
```

### 4. Connect to services

Run once for each new session:

```powershell
pwsh ./connect.ps1
```

### 5. Validate the setup

```powershell
pwsh ./validate.ps1
```

## Daily workflow

### Important

All operational scripts must run in the same PowerShell session.

Do **not** run scripts by prefixing them with `pwsh` once you are already inside PowerShell, because that starts a new session and existing connections will not be reused.

### 1. Start PowerShell

```powershell
pwsh
```

### 2. Connect in the same session

```powershell
. ./connect.ps1
```

This connects:

- Microsoft Graph
- Exchange Online
- Microsoft Teams
- SharePoint (PnP)

### 3. Run operational scripts

Examples:

```powershell
./scripts/entra.ps1 -ListUsers
./scripts/entra.ps1 -ListGroups
./scripts/entra.ps1 -SearchUser -SearchText Johan
./scripts/autopilot.ps1 -ListAutopilotDevices
./scripts/exchange.ps1 -ShowAuditStatus
./scripts/sharepoint.ps1 -ShowWeb
```

### 4. Export results

```powershell
./scripts/entra.ps1 -ListUsers -Export
```

### 5. Update the repository

```bash
git pull
```

### 6. Save changes

```bash
git add .
git commit -m "Describe your change"
git push
```

## Script overview

### `scripts/autopilot.ps1`

Used for Intune / Autopilot lookups.

Examples:

```powershell
./scripts/autopilot.ps1 -ListAutopilotDevices
./scripts/autopilot.ps1 -SerialNumber ABC123
./scripts/autopilot.ps1 -ListManagedDevices
```

### `scripts/entra.ps1`

Used for user, group, and membership lookups in Entra ID.

Examples:

```powershell
./scripts/entra.ps1 -ListUsers
./scripts/entra.ps1 -UserId user@contoso.com
./scripts/entra.ps1 -ListGroups
./scripts/entra.ps1 -GroupId <group-id> -ListGroupMembers
```

### `scripts/exchange.ps1`

Used for Exchange administration and governance:

- mailboxes and shared mailboxes
- mailbox permissions and access review
- audit log queries
- mail flow rules and connectors
- tenant audit configuration

Examples:

```powershell
./scripts/exchange.ps1 -ShowAuditStatus
./scripts/exchange.ps1 -EnableUnifiedAuditLog
```

### `scripts/sharepoint.ps1`

SharePoint administration and governance:

- site and tenant site overview
- site collection administrators
- SharePoint groups and membership
- lists and libraries
- permission inheritance checks
- detection of unique permissions (governance)

Examples:

```powershell
./scripts/sharepoint.ps1 -ShowWeb
./scripts/sharepoint.ps1 -Reconnect -SiteUrl https://contoso.sharepoint.com/sites/example -ShowWeb
```

## Governance use cases

This toolkit can be used for:

- identifying groups without owners  
- reviewing mailbox permissions  
- detecting unique SharePoint permissions  
- finding unmanaged or unassigned devices  
- auditing tenant configuration and access patterns 


## Notes

- `bootstrap.ps1` is only needed during initial setup or when adding modules
- `connect.ps1` must be run once per PowerShell session
- `config.ps1` is local and must not be committed
- `config.ps1` should stay excluded through `.gitignore`

## Troubleshooting

### Graph authentication on macOS / Linux

`connect.ps1` uses device code authentication for Microsoft Graph on macOS and Linux to avoid known interactive browser authentication issues.

If Graph authentication behaves unexpectedly, start a fresh terminal session and reconnect.

### Separate PowerShell sessions

If a script says authentication is missing even though `connect.ps1` was run earlier, the script was likely started in a new PowerShell session.

Correct pattern:

```powershell
pwsh
. ./connect.ps1
./scripts/entra.ps1 -ListUsers
```

Incorrect pattern:

```powershell
pwsh ./connect.ps1
pwsh ./scripts/entra.ps1 -ListUsers
```

## Recommended next additions

Logical next scripts to add:

- `scripts/intune.ps1`
- `scripts/teams.ps1`
- `scripts/mailflow.ps1`
- `scripts/licenses.ps1`
- `scripts/reports/`

## Security and operations

- do not commit `config.ps1`
- keep Graph scopes as narrow as possible
- use delegated authentication for manual admin work
- use app or certificate authentication for automation later

## Minimal repo layout

```text
it-admin-toolkit/
  bootstrap.ps1
  connect.ps1
  validate.ps1
  disconnect.ps1
  common.ps1
  config.sample.ps1
  config.ps1
  scripts/
    autopilot.ps1
    entra.ps1
    exchange.ps1
    sharepoint.ps1
```

