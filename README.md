# IT admin toolkit v2

En enkel PowerShell-toolkit för daglig Microsoft 365-administration.

Målet med v2 är:

- tydlig uppdelning mellan installation, anslutning och day-2 scripts
- enkel lokal konfig per tenant
- lätt att bygga vidare på utan att låsa fast dig i för mycket ramverk

## Struktur

- `bootstrap.ps1`
  Installerar basmoduler.

- `connect.ps1`
  Ansluter till Exchange Online, Microsoft Graph, Teams och PnP.

- `validate.ps1`
  Kör några snabba kontroller så att du ser att sessionerna fungerar.

- `disconnect.ps1`
  Kopplar ner sessionerna.

- `common.ps1`
  Gemensamma hjälpfunktioner.

- `config.sample.ps1`
  Mall för tenant-specifik konfig. Kopiera till `config.ps1` lokalt.

- `scripts/autopilot.ps1`
  Intune / Autopilot-relaterade list- och exportkommandon.

- `scripts/entra.ps1`
  Entra / Graph-relaterade uppslag för användare och grupper.

- `scripts/exchange.ps1`
  Enkel Exchange-admin för audit status.

- `scripts/sharepoint.ps1`
  Enkel PnP-baserad SharePoint site context / site info.

## Basmoduler

Toolkiten använder i grunden:

- ExchangeOnlineManagement
- Microsoft Graph PowerShell submoduler
- MicrosoftTeams
- PnP.PowerShell

Valfritt:

- Az.Accounts
- Microsoft.Graph.Beta.DeviceManagement.Enrollment

## Varför dessa moduler

Exchange Online PowerShell använder modern auth via `Connect-ExchangeOnline`. Microsoft Graph PowerShell använder `Connect-MgGraph` och kräver att du ansluter innan Graph-cmdlets körs. Teams-modulen använder `Connect-MicrosoftTeams`. PnP PowerShell är cross-platform och körs på Windows, Linux och macOS, men är community-driven och inte en Microsoft-stödd modul. citeturn23search105turn23search93turn23search99turn23search104turn24search140turn24search142

För din Mac-miljö är PnP-spåret enklare än att luta sig på SharePoint Online Management Shell, eftersom dokumentationen för Microsofts SharePoint Online PowerShell i PowerShell 7 beskriver `-UseWindowsPowerShell` i Windows-kontext. citeturn16search81

## Enterprise-baseline som täcks

v2 täcker det som normalt behövs för en admin i en Microsoft 365 enterprise-miljö:

- Exchange Online admin
- Entra ID / Graph-uppslag
- Intune managed devices via Graph
- Windows Autopilot device identities via Graph
- Teams anslutning och grundkontroll
- SharePoint Online via PnP PowerShell

Microsoft Learn dokumenterar att `Get-MgDeviceManagementManagedDevice` returnerar managed devices och att `Get-MgDeviceManagementWindowsAutopilotDeviceIdentity` returnerar Windows Autopilot device identities. För Autopilot anger dokumentationen också de delegerade behörigheterna `DeviceManagementServiceConfig.Read.All` eller `DeviceManagementServiceConfig.ReadWrite.All`. Microsoft Learn dokumenterar också att `Get-MgUser`, `Get-MgGroup` och `Get-MgGroupMember` hämtar users, groups respektive direkta gruppmedlemmar. citeturn24search120turn24search134turn24search135turn24search127turn24search153turn24search154

## Första uppsättning

1. Kopiera `config.sample.ps1` till `config.ps1`
2. Fyll i tenant-värden
3. Lägg till `PnPClientId` om du vill använda PnP interaktivt
4. Kör bootstrap
5. Kör connect
6. Kör validate

Exempel:

```powershell
Copy-Item ./config.sample.ps1 ./config.ps1
pwsh ./bootstrap.ps1
pwsh ./connect.ps1 -ShowCommands
pwsh ./validate.ps1
```

## PnP-notering

PnP PowerShell kräver att du använder en egen Entra app registration för interaktiv auth. Lägg client id i `config.ps1` som `PnPClientId`. Det är uttryckligen beskrivet i PnP-dokumentationen att den gamla multi-tenant PnP Management Shell-appen inte längre är vägen fram. citeturn23search111turn23search117turn24search142

## Exempel på användning

Anslut allt:

```powershell
pwsh ./connect.ps1 -ShowCommands
```

Lista Autopilot-enheter:

```powershell
pwsh ./scripts/autopilot.ps1 -ListAutopilotDevices -Top 20
```

Sök Autopilot på serienummer:

```powershell
pwsh ./scripts/autopilot.ps1 -SerialNumber ABC123
```

Lista Intune managed devices:

```powershell
pwsh ./scripts/autopilot.ps1 -ListManagedDevices -Top 20
```

Lista användare:

```powershell
pwsh ./scripts/entra.ps1 -ListUsers -Top 20
```

Hämta specifik användare:

```powershell
pwsh ./scripts/entra.ps1 -UserId user@contoso.com
```

Lista grupper:

```powershell
pwsh ./scripts/entra.ps1 -ListGroups -Top 20
```

Visa audit-status i Exchange:

```powershell
pwsh ./scripts/exchange.ps1 -ShowAuditStatus
```

Slå på unified audit log ingestion:

```powershell
pwsh ./scripts/exchange.ps1 -EnableUnifiedAuditLog
```

Visa nuvarande SharePoint site context i PnP:

```powershell
pwsh ./scripts/sharepoint.ps1 -ShowWeb
```

Byt site context och visa web info:

```powershell
pwsh ./scripts/sharepoint.ps1 -Reconnect -SiteUrl https://yieldit.sharepoint.com/sites/example -ShowWeb
```

## Rekommenderad vidareutveckling

Nästa praktiska steg att lägga till:

- `scripts/intune.ps1`
  rapporter för compliance, ownership, primary user och export

- `scripts/teams.ps1`
  tenant settings, policies och standardrapporter

- `scripts/mailflow.ps1`
  connectors, transport rules, accepted domains

- `scripts/licenses.ps1`
  Graph-baserad licensinventering

- `scripts/reports/`
  separata exporter och rapporter

## Säkerhet och drift

- committa inte `config.ps1`
- håll Graph-scopes så smala som möjligt
- använd delegerad auth för manuellt arbete
- använd app/cert-baserad auth när du senare automatiserar

## Minimal repo-layout framåt

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
