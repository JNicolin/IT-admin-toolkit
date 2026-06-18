[CmdletBinding()]
param(
    [switch]$ListUsers,
    [switch]$SearchUser,
    [string]$SearchText,
    [switch]$ListDisabledUsers,
    [switch]$ListGuestUsers,
    [switch]$ListGroups,
    [string]$UserId,
    [string]$GroupId,
    [switch]$ListGroupMembers,
    [switch]$ListUserGroups,
    [switch]$AddUserToGroup,
    [switch]$RemoveUserFromGroup,
    [switch]$GetUserLicenses,
    [int]$Top = 25,
    [switch]$Table,
    [switch]$Export
)

$scriptRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $scriptRoot 'common.ps1')
. (Join-Path $scriptRoot 'config.ps1')

if (-not (Test-CommandAvailable -Name 'Get-MgContext')) {
    throw 'Microsoft Graph is not connected. Run connect.ps1 first.'
}

$results = $null
$view = @()

function Resolve-UserObjectId {
    param(
        [Parameter(Mandatory)]
        [string]$Identity
    )

    if ($Identity -match '@') {
        $user = Get-MgUser -UserId $Identity -Property 'id'
        return $user.Id
    }

    return $Identity
}

function Resolve-DirectoryObjectSummary {
    param(
        [Parameter(Mandatory)]
        $Object
    )

    $type = $null
    $displayName = $null
    $upn = $null
    $mail = $null

    if ($Object.AdditionalProperties -and $Object.AdditionalProperties.ContainsKey('@odata.type')) {
        $type = $Object.AdditionalProperties['@odata.type']
    }

    switch ($type) {
        '#microsoft.graph.user' {
            $type = 'User'
            $user = Get-MgUser -UserId $Object.Id -Property 'displayName,userPrincipalName,mail'
            $displayName = $user.DisplayName
            $upn = $user.UserPrincipalName
            $mail = $user.Mail
        }

        '#microsoft.graph.group' {
            $type = 'Group'
            $group = Get-MgGroup -GroupId $Object.Id -Property 'displayName,mail'
            $displayName = $group.DisplayName
            $mail = $group.Mail
        }

        default {
            $type = 'Other'
        }
    }

    [PSCustomObject]@{
        DisplayName       = if ($displayName) { $displayName } else { '[unknown]' }
        UserPrincipalName = if ($upn) { $upn } else { '-' }
        Mail              = if ($mail) { $mail } else { '-' }
        Type              = $type
        Id                = $Object.Id
    }
}

# User details / user-specific actions
if ($UserId) {
    if ($ListUserGroups) {
        $memberOf = Get-MgUserMemberOf -UserId $UserId -All
        $results = $memberOf | ForEach-Object { Resolve-DirectoryObjectSummary -Object $_ }
        $view = @('DisplayName','Mail','Type','Id')
    }
    elseif ($GetUserLicenses) {
        $user = Get-MgUser -UserId $UserId -Property 'id,displayName,userPrincipalName,assignedLicenses'
        $skus = Get-MgSubscribedSku -All

        $results = foreach ($license in $user.AssignedLicenses) {
            $match = $skus | Where-Object { $_.SkuId -eq $license.SkuId }

            [PSCustomObject]@{
                DisplayName       = $user.DisplayName
                UserPrincipalName = $user.UserPrincipalName
                SkuId             = $license.SkuId
                SkuPartNumber     = if ($match) { $match.SkuPartNumber } else { '[unknown]' }
            }
        }

        $view = @('DisplayName','UserPrincipalName','SkuPartNumber','SkuId')
    }
    else {
        $results = Get-MgUser -UserId $UserId -Property 'id,displayName,userPrincipalName,mail,department,jobTitle,accountEnabled,userType' |
            Select-Object DisplayName, UserPrincipalName, Mail, Department, JobTitle, AccountEnabled, UserType, Id

        $view = @('DisplayName','UserPrincipalName','Mail','Department','JobTitle','AccountEnabled','UserType','Id')
    }
}

# Search users
elseif ($SearchUser) {
    if (-not $SearchText) {
        throw 'Use -SearchText together with -SearchUser.'
    }

    $results = Get-MgUser -Filter "startsWith(displayName,'$SearchText') or startsWith(userPrincipalName,'$SearchText')" -Top $Top -Property 'id,displayName,userPrincipalName,mail,department,jobTitle,accountEnabled,userType' |
        Select-Object DisplayName, UserPrincipalName, Mail, Department, JobTitle, AccountEnabled, UserType, Id

    $view = @('DisplayName','UserPrincipalName','Mail','Department','JobTitle','AccountEnabled','UserType','Id')
}

# Disabled users
elseif ($ListDisabledUsers) {
    $results = Get-MgUser -Filter "accountEnabled eq false" -Top $Top -Property 'id,displayName,userPrincipalName,mail,department,jobTitle,userType' |
        Select-Object DisplayName, UserPrincipalName, Mail, Department, JobTitle, UserType, Id

    $view = @('DisplayName','UserPrincipalName','Mail','Department','JobTitle','UserType','Id')
}

# Guest users
elseif ($ListGuestUsers) {
    $results = Get-MgUser -Filter "userType eq 'Guest'" -Top $Top -Property 'id,displayName,userPrincipalName,mail,department,jobTitle,accountEnabled' |
        Select-Object DisplayName, UserPrincipalName, Mail, Department, JobTitle, AccountEnabled, Id

    $view = @('DisplayName','UserPrincipalName','Mail','Department','JobTitle','AccountEnabled','Id')
}

# List users
elseif ($ListUsers) {
    $results = Get-MgUser -Top $Top -Property 'id,displayName,userPrincipalName,mail,department,jobTitle,accountEnabled,userType' |
        Select-Object DisplayName, UserPrincipalName, Mail, Department, JobTitle, AccountEnabled, UserType, Id

    $view = @('DisplayName','UserPrincipalName','Mail','Department','JobTitle','AccountEnabled','UserType','Id')
}

# Group members
elseif ($GroupId -and $ListGroupMembers) {
    $members = Get-MgGroupMember -GroupId $GroupId -All
    $results = $members | ForEach-Object { Resolve-DirectoryObjectSummary -Object $_ }
    $view = @('DisplayName','UserPrincipalName','Mail','Type','Id')
}

# Add user to group
elseif ($GroupId -and $AddUserToGroup) {
    if (-not $UserId) {
        throw 'Use -UserId together with -GroupId and -AddUserToGroup.'
    }

    $resolvedUserId = Resolve-UserObjectId -Identity $UserId

    New-MgGroupMemberByRef -GroupId $GroupId -BodyParameter @{
        "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$resolvedUserId"
    }

    Write-Ok "Added user $UserId to group $GroupId"
    return
}

# Remove user from group
elseif ($GroupId -and $RemoveUserFromGroup) {
    if (-not $UserId) {
        throw 'Use -UserId together with -GroupId and -RemoveUserFromGroup.'
    }

    $resolvedUserId = Resolve-UserObjectId -Identity $UserId

    Remove-MgGroupMemberByRef -GroupId $GroupId -DirectoryObjectId $resolvedUserId
    Write-Ok "Removed user $UserId from group $GroupId"
    return
}

# Group details
elseif ($GroupId) {
    $results = Get-MgGroup -GroupId $GroupId -Property 'id,displayName,mail,mailEnabled,securityEnabled,groupTypes,description' |
        Select-Object DisplayName, Mail, MailEnabled, SecurityEnabled, GroupTypes, Description, Id

    $view = @('DisplayName','Mail','MailEnabled','SecurityEnabled','GroupTypes','Description','Id')
}

# List groups
elseif ($ListGroups) {
    $results = Get-MgGroup -Top $Top -Property 'id,displayName,mail,mailEnabled,securityEnabled,groupTypes' |
        Select-Object DisplayName, Mail, MailEnabled, SecurityEnabled, GroupTypes, Id

    $view = @('DisplayName','Mail','MailEnabled','SecurityEnabled','GroupTypes','Id')
}

else {
    Write-WarnLine 'No action selected. Use -ListUsers, -SearchUser, -ListDisabledUsers, -ListGuestUsers, -UserId, -ListGroups, -GroupId, -ListGroupMembers, -ListUserGroups, -AddUserToGroup, -RemoveUserFromGroup or -GetUserLicenses.'
    return
}

Show-ToolkitOutput -Data $results -View $view -Table:$Table

if ($Export) {
    Export-ToolkitCsv -InputObject $results -Name 'entra-results' -ScriptName 'entra'
}