[CmdletBinding()]
param(
    [switch]$ListGroups,
    [string]$GroupId,
    [switch]$ListGroupMembers,
    [switch]$ListGroupOwners,
    [switch]$ListEmptyGroups,
    [switch]$ListLargeGroups,
    [int]$Threshold = 100,
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

if ($GroupId -and $ListGroupMembers) {
    $results = Get-MgGroupMember -GroupId $GroupId -All |
        Select-Object Id, AdditionalProperties
}
elseif ($GroupId -and $ListGroupOwners) {
    $results = Get-MgGroupOwner -GroupId $GroupId -All |
        Select-Object Id, AdditionalProperties
}
elseif ($GroupId) {
    $results = Get-MgGroup -GroupId $GroupId -Property 'id,displayName,mail,mailEnabled,securityEnabled,groupTypes,description' |
        Select-Object Id, DisplayName, Mail, MailEnabled, SecurityEnabled, GroupTypes, Description
}
elseif ($ListEmptyGroups) {
    $allGroups = Get-MgGroup -All -Property 'id,displayName,mail,mailEnabled,securityEnabled,groupTypes'

    $results = foreach ($group in $allGroups) {
        $members = Get-MgGroupMember -GroupId $group.Id -All
        $memberCount = @($members).Count

        if ($memberCount -eq 0) {
            [PSCustomObject]@{
                Id              = $group.Id
                DisplayName     = $group.DisplayName
                Mail            = $group.Mail
                MailEnabled     = $group.MailEnabled
                SecurityEnabled = $group.SecurityEnabled
                GroupTypes      = ($group.GroupTypes -join ', ')
                MemberCount     = $memberCount
            }
        }
    }
}
elseif ($ListLargeGroups) {
    $allGroups = Get-MgGroup -All -Property 'id,displayName,mail,mailEnabled,securityEnabled,groupTypes'

    $results = foreach ($group in $allGroups) {
        $members = Get-MgGroupMember -GroupId $group.Id -All
        $memberCount = @($members).Count

        if ($memberCount -ge $Threshold) {
            [PSCustomObject]@{
                Id              = $group.Id
                DisplayName     = $group.DisplayName
                Mail            = $group.Mail
                MailEnabled     = $group.MailEnabled
                SecurityEnabled = $group.SecurityEnabled
                GroupTypes      = ($group.GroupTypes -join ', ')
                MemberCount     = $memberCount
            }
        }
    }
}
elseif ($ListGroups) {
    $results = Get-MgGroup -Top $Top -Property 'id,displayName,mail,mailEnabled,securityEnabled,groupTypes,description' |
        Select-Object Id, DisplayName, Mail, MailEnabled, SecurityEnabled, GroupTypes, Description
}
else {
    Write-WarnLine 'No action selected. Use -ListGroups, -GroupId, -ListGroupMembers, -ListGroupOwners, -ListEmptyGroups or -ListLargeGroups.'
    return
}

$results | Format-Table -AutoSize

if ($Export) {
    Export-ToolkitCsv -InputObject $results -Name 'group-results' -ScriptName 'groups'
}