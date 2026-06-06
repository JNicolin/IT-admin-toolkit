[CmdletBinding()]
param(
    [switch]$ListUsers,
    [switch]$ListGroups,
    [string]$UserId,
    [string]$GroupId,
    [switch]$ListGroupMembers,
    [int]$Top = 25,
    [switch]$Export
)

$scriptRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $scriptRoot 'common.ps1')
. (Join-Path $scriptRoot 'config.ps1')

if (-not (Test-CommandAvailable -Name 'Get-MgContext')) {
    throw 'Microsoft Graph is not connected. Run connect.ps1 first.'
}

$results = $null

if ($UserId) {
    $results = Get-MgUser -UserId $UserId -Property 'id,displayName,userPrincipalName,mail,department,jobTitle,accountEnabled' |
        Select-Object Id, DisplayName, UserPrincipalName, Mail, Department, JobTitle, AccountEnabled
}
elseif ($ListUsers) {
    $results = Get-MgUser -Top $Top -Property 'id,displayName,userPrincipalName,mail,department,jobTitle,accountEnabled' |
        Select-Object Id, DisplayName, UserPrincipalName, Mail, Department, JobTitle, AccountEnabled
}
elseif ($GroupId -and $ListGroupMembers) {
    $results = Get-MgGroupMember -GroupId $GroupId -All |
        Select-Object Id, AdditionalProperties
}
elseif ($GroupId) {
    $results = Get-MgGroup -GroupId $GroupId -Property 'id,displayName,mail,mailEnabled,securityEnabled,groupTypes' |
        Select-Object Id, DisplayName, Mail, MailEnabled, SecurityEnabled, GroupTypes
}
elseif ($ListGroups) {
    $results = Get-MgGroup -Top $Top -Property 'id,displayName,mail,mailEnabled,securityEnabled,groupTypes' |
        Select-Object Id, DisplayName, Mail, MailEnabled, SecurityEnabled, GroupTypes
}
else {
    Write-WarnLine 'No action selected. Use -ListUsers, -UserId, -ListGroups, -GroupId or -ListGroupMembers.'
    return
}

$results | Format-Table -AutoSize

if ($Export) {
    Export-ToolkitCsv -InputObject $results -Name 'entra-results'
}
