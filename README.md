# IT admin toolkit

A practical PowerShell toolkit for Microsoft 365 administration.

This repository gives IT administrators a simple and repeatable way to:

- connect to Microsoft 365 services
- run common operational tasks
- review permissions and governance settings
- export results for reporting and follow-up
- keep setup and daily usage consistent across devices

Instead of writing scripts from scratch each time, this toolkit provides a clean starting point for installation, connection, shared helper functions, and operational work.

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

- clear separation between installation, connection, helper functions, and operational scripts
- simple per-tenant local configuration
- easy to extend without heavy frameworks
- consistent output and export handling across scripts

In this toolkit:

- **bootstrap** installs required modules
- **connect** establishes authenticated sessions
- **common** provides shared helper functions for output, export, validation, and reuse
- **operational scripts** perform actual admin work such as lookups, validation, export, governance, and troubleshooting

## Output model

Operational scripts use shared helper functions from `common.ps1`.

Main helpers:

- `Show-ToolkitOutput`
- `Export-ToolkitCsv`

This provides:

- consistent formatting across scripts
- optional table view with `-Table`
- consistent CSV export with `-Export`
- simpler script structure and better reuse

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
  Shared helper functions for output, export, and reusable logic.

- `config.sample.ps1`  
  Template for tenant-specific configuration. Copy to `config.ps1` locally.

- `scripts/autopilot.ps1`  
  Intune / Autopilot queries, compliance views, and export.

- `scripts/entra.ps1`  
  Entra / Graph queries for users, groups, memberships, licenses, and identity hygiene.

- `scripts/groups.ps1`  
  Group governance and ownership review.

- `scripts/exchange.ps1`  
  Exchange administration, mailbox review, audit checks, and permission review.

- `scripts/sharepoint.ps1`  
  SharePoint administration, site context, permissions, and governance checks via PnP.

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
  Used for Exchange administration such as audit settings, mailbox-related administration, permissions, and mail flow review.

- **Microsoft Graph PowerShell**  
  Used for identity, users, groups, devices, and Intune / Autopilot data.

- **MicrosoftTeams**  
  Used for Teams-specific administration and validation.

- **PnP.PowerShell**  
  Used for SharePoint administration and automation using a modern cross-platform approach that works well with PowerShell 7.

Together, these modules provide coverage across identity, messaging, collaboration, devices, and content.

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

## Governance use cases

This toolkit can be used for:

- identifying groups without owners
- reviewing mailbox permissions
- detecting unique SharePoint permissions
- finding unmanaged or unassigned devices
- auditing tenant configuration and access patterns

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

Run once for each new PowerShell session:

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
./scripts/groups.ps1 -ListGroupsWithoutOwners
./scripts/autopilot.ps1 -ListNonCompliantDevices
./scripts/exchange.ps1 -ShowAuditStatus
./scripts/sharepoint.ps1 -ShowWeb
```

### 4. Export results

```powershell
./scripts/entra.ps1 -ListUsers -Export
./scripts/groups.ps1 -ListGroupsWithoutOwners -Export
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

## Common script options

Most operational scripts support one or more of the following options:

- `-Table`  
  Displays results in table format.

- `-Export`  
  Exports results to CSV.

- `-Top`  
  Limits the number of returned results.

## Script overview

### `scripts/autopilot.ps1`

Used for Intune / Autopilot lookups and basic device governance.

Examples:

```powershell
./scripts/autopilot.ps1 -ListAutopilotDevices
./scripts/autopilot.ps1 -SerialNumber ABC123
./scripts/autopilot.ps1 -ListManagedDevices
./scripts/autopilot.ps1 -ListNonCompliantDevices
./scripts/autopilot.ps1 -ListDevicesWithoutUser
```

### `scripts/entra.ps1`

Used for users, groups, memberships, and identity review in Entra ID.

Examples:

```powershell
./scripts/entra.ps1 -ListUsers
./scripts/entra.ps1 -SearchUser -SearchText Johan
./scripts/entra.ps1 -UserId user@contoso.com
./scripts/entra.ps1 -UserId user@contoso.com -ListUserGroups
./scripts/entra.ps1 -UserId user@contoso.com -GetUserLicenses
./scripts/entra.ps1 -ListDisabledUsers
./scripts/entra.ps1 -ListGuestUsers
```

### `scripts/groups.ps1`

Used for group governance and ownership review.

Examples:

```powershell
./scripts/groups.ps1 -ListGroups
./scripts/groups.ps1 -GroupId <group-id> -ListGroupMembers
./scripts/groups.ps1 -GroupId <group-id> -ListGroupOwners
./scripts/groups.ps1 -ListEmptyGroups
./scripts/groups.ps1 -ListLargeGroups -Threshold 25
./scripts/groups.ps1 -ListGroupsWithoutOwners
```

### `scripts/exchange.ps1`

Used for Exchange administration, mailbox review, and audit-related checks.

Examples:

```powershell
./scripts/exchange.ps1 -ShowAuditStatus
./scripts/exchange.ps1 -EnableUnifiedAuditLog
./scripts/exchange.ps1 -ListMailboxes
./scripts/exchange.ps1 -ListSharedMailboxes
./scripts/exchange.ps1 -MailboxIdentity user@contoso.com -ShowMailboxStatistics
./scripts/exchange.ps1 -MailboxIdentity user@contoso.com -ShowMailboxPermissions
./scripts/exchange.ps1 -ReviewMailboxPermissions
./scripts/exchange.ps1 -ReviewSharedMailboxPermissions
./scripts/exchange.ps1 -ListTransportRules
./scripts/exchange.ps1 -ListAcceptedDomains
./scripts/exchange.ps1 -ListInboundConnectors
./scripts/exchange.ps1 -ListOutboundConnectors
```

### `scripts/sharepoint.ps1`

Used for SharePoint administration and governance via PnP.

Examples:

```powershell
./scripts/sharepoint.ps1 -ShowWeb
./scripts/sharepoint.ps1 -Reconnect -SiteUrl https://contoso.sharepoint.com/sites/example -ShowWeb
./scripts/sharepoint.ps1 -ListLibraries
./scripts/sharepoint.ps1 -ListTenantSites
./scripts/sharepoint.ps1 -ListSiteAdmins
./scripts/sharepoint.ps1 -ListSiteGroups
./scripts/sharepoint.ps1 -ListSiteGroups -GroupName "Site Members" -ListGroupMembers
./scripts/sharepoint.ps1 -ListListsWithUniquePermissions
./scripts/sharepoint.ps1 -CheckListUniquePermissions -ListName "Documents"
```

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

### SharePoint tenant site queries

Tenant-wide SharePoint queries can take longer than site-level queries.

If `-ListTenantSites` is slow, run it from the SharePoint admin context and reduce the result scope where possible.

## Recommended next additions

Logical next scripts to add:

- `scripts/security.ps1`
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
- use separate admin accounts where possible

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
    groups.ps1
    exchange.ps1
    sharepoint.ps1
```