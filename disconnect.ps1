[CmdletBinding()]
param()

if (Get-Command Disconnect-ExchangeOnline -ErrorAction SilentlyContinue) {
    Disconnect-ExchangeOnline -Confirm:$false
}

if (Get-Command Disconnect-MgGraph -ErrorAction SilentlyContinue) {
    Disconnect-MgGraph
}

if (Get-Command Disconnect-MicrosoftTeams -ErrorAction SilentlyContinue) {
    Disconnect-MicrosoftTeams
}

if (Get-Command Disconnect-PnPOnline -ErrorAction SilentlyContinue) {
    Disconnect-PnPOnline
}

Write-Host 'Disconnected from available services.' -ForegroundColor Green
