[CmdletBinding()]
param(
    [switch]$ListUsers,
    [switch]$SearchUser,
    [string]$SearchText,
    [switch]$ListGroups,
    [string]$UserId,
    [string]$GroupId,
    [switch]$ListGroupMembers,
    [switch]$ListUserGroups,
    [switch]$AddUserToGroup,
    [switch]$RemoveUserFromGroup,
    [switch]$GetUserLicenses,
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
    if ($ListUserGroups) {
        $results = Get-MgUserMemberOf -UserId $UserId -All |
            Select-Object Id, AdditionalProperties
    }
    elseif ($GetUserLicenses) {
        $results = Get-MgUser -UserId $UserId -Property 'id,displayName,userPrincipalName,assignedLicenses' |
            Select-Object Id, DisplayName, UserPrincipalName, AssignedLicenses
    }
    else {
        $results = Get-MgUser -UserId $UserId -Property 'id,displayName,userPrincipalName,mail,department,jobTitle,accountEnabled' |
            Select-Object Id, DisplayName, UserPrincipalName, Mail, Department, JobTitle, AccountEnabled
    }
}
elseif ($SearchUser) {
    if (-not $SearchText) {
        throw 'Use -SearchText together with -SearchUser.'
    }

    $results = Get-MgUser -Search "displayName:$SearchText" -ConsistencyLevel eventual -Top $Top -Property 'id,displayName,userPrincipalName,mail,department,jobTitle,accountEnabled' |
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
elseif ($GroupId -and $AddUserToGroup) {
    if (-not $UserId) {
        throw 'Use -UserId together with -GroupId and -AddUserToGroup.'
    }

    New-MgGroupMemberByRef -GroupId $GroupId -BodyParameter @{
        "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$UserId"
    }

    Write-Ok "Added user $UserId to group $GroupId"
    return
}
elseif ($GroupId -and $RemoveUserFromGroup) {
    if (-not $UserId) {
        throw 'Use -UserId together with -GroupId and -RemoveUserFromGroup.'
    }

    Remove-MgGroupMemberByRef -GroupId $GroupId -DirectoryObjectId $UserId
    Write-Ok "Removed user $UserId from group $GroupId"
    return
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
    Write-WarnLine 'No action selected. Use -ListUsers, -SearchUser, -UserId, -ListGroups, -GroupId, -ListGroupMembers, -ListUserGroups, -AddUserToGroup, -RemoveUserFromGroup or -GetUserLicenses.'
    return
}

$results | Format-Table -AutoSize

if ($Export) {
    Export-ToolkitCsv -InputObject $results -Name 'entra-results' -ScriptName 'entra'
}