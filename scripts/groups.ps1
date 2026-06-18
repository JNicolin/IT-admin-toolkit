[CmdletBinding()]
param(
    [switch]$ListGroups,
    [string]$GroupId,
    [switch]$ListGroupMembers,
    [switch]$ListGroupOwners,
    [switch]$ListEmptyGroups,
    [switch]$ListLargeGroups,
    [switch]$ListGroupsWithoutOwners,
    [int]$Threshold = 10,
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

# Group members
if ($GroupId -and $ListGroupMembers) {
    $members = Get-MgGroupMember -GroupId $GroupId -All

    $results = foreach ($m in $members) {
        $type = $null
        $displayName = $null
        $upn = $null

        if ($m.AdditionalProperties -and $m.AdditionalProperties.ContainsKey('@odata.type')) {
            $type = $m.AdditionalProperties['@odata.type']
        }

        switch ($type) {
            '#microsoft.graph.user' {
                $type = 'User'
                $user = Get-MgUser -UserId $m.Id -Property 'displayName,userPrincipalName'
                $displayName = $user.DisplayName
                $upn = $user.UserPrincipalName
            }

            '#microsoft.graph.group' {
                $type = 'Group'
                $group = Get-MgGroup -GroupId $m.Id -Property 'displayName'
                $displayName = $group.DisplayName
            }

            default {
                $type = 'Other'
            }
        }

        [PSCustomObject]@{
            DisplayName       = if ($displayName) { $displayName } else { '[unknown]' }
            UserPrincipalName = if ($upn) { $upn } else { '-' }
            Type              = $type
            Id                = $m.Id
        }
    }

    $view = @('DisplayName','UserPrincipalName','Type','Id')
}

# Group owners
elseif ($GroupId -and $ListGroupOwners) {
    $owners = Get-MgGroupOwner -GroupId $GroupId -All

    $results = foreach ($o in $owners) {
        $type = $null
        $displayName = $null
        $upn = $null

        if ($o.AdditionalProperties -and $o.AdditionalProperties.ContainsKey('@odata.type')) {
            $type = $o.AdditionalProperties['@odata.type']
        }

        switch ($type) {
            '#microsoft.graph.user' {
                $type = 'User'
                $user = Get-MgUser -UserId $o.Id -Property 'displayName,userPrincipalName'
                $displayName = $user.DisplayName
                $upn = $user.UserPrincipalName
            }

            '#microsoft.graph.group' {
                $type = 'Group'
                $group = Get-MgGroup -GroupId $o.Id -Property 'displayName'
                $displayName = $group.DisplayName
            }

            default {
                $type = 'Other'
            }
        }

        [PSCustomObject]@{
            DisplayName       = if ($displayName) { $displayName } else { '[unknown]' }
            UserPrincipalName = if ($upn) { $upn } else { '-' }
            Type              = $type
            Id                = $o.Id
        }
    }

    $view = @('DisplayName','UserPrincipalName','Type','Id')
}

# Group details
elseif ($GroupId) {
    $results = Get-MgGroup -GroupId $GroupId -Property 'displayName,mail,mailEnabled,securityEnabled,groupTypes,description'

    $view = @(
        'DisplayName',
        'Mail',
        'MailEnabled',
        'SecurityEnabled',
        'GroupTypes',
        'Description'
    )
}

# Empty groups
elseif ($ListEmptyGroups) {
    Write-Info 'Evaluating groups for empty membership...'

    $results = foreach ($group in Get-MgGroup -All -Property 'id,displayName,mail,mailEnabled,securityEnabled,groupTypes') {
        $memberCount = (Get-MgGroupMember -GroupId $group.Id -All | Measure-Object).Count

        if ($memberCount -eq 0) {
            [PSCustomObject]@{
                DisplayName     = $group.DisplayName
                Mail            = $group.Mail
                MailEnabled     = $group.MailEnabled
                SecurityEnabled = $group.SecurityEnabled
                Type            = ($group.GroupTypes -join ', ')
                MemberCount     = $memberCount
                Id              = $group.Id
            }
        }
    }

    $view = @('DisplayName','Mail','MailEnabled','SecurityEnabled','Type','MemberCount','Id')
}

# Large groups
elseif ($ListLargeGroups) {
    Write-Info "Evaluating groups with at least $Threshold members..."

    $results = foreach ($group in Get-MgGroup -All -Property 'id,displayName,mail,mailEnabled,securityEnabled,groupTypes') {
        $memberCount = (Get-MgGroupMember -GroupId $group.Id -All | Measure-Object).Count

        if ($memberCount -ge $Threshold) {
            [PSCustomObject]@{
                DisplayName     = $group.DisplayName
                Mail            = $group.Mail
                MailEnabled     = $group.MailEnabled
                SecurityEnabled = $group.SecurityEnabled
                Type            = ($group.GroupTypes -join ', ')
                MemberCount     = $memberCount
                Id              = $group.Id
            }
        }
    }

    $view = @('DisplayName','MemberCount','Mail','MailEnabled','SecurityEnabled','Type','Id')
}

# Groups without owners
elseif ($ListGroupsWithoutOwners) {
    Write-Info 'Evaluating groups without owners...'

    $results = foreach ($group in Get-MgGroup -All -Property 'id,displayName,mail,mailEnabled,securityEnabled,groupTypes') {
        $ownerCount = (Get-MgGroupOwner -GroupId $group.Id -All | Measure-Object).Count

        if ($ownerCount -eq 0) {
            [PSCustomObject]@{
                DisplayName     = $group.DisplayName
                Mail            = $group.Mail
                MailEnabled     = $group.MailEnabled
                SecurityEnabled = $group.SecurityEnabled
                Type            = ($group.GroupTypes -join ', ')
                OwnerCount      = $ownerCount
                Id              = $group.Id
            }
        }
    }

    $view = @('DisplayName','Mail','MailEnabled','SecurityEnabled','Type','OwnerCount','Id')
}

# List groups
elseif ($ListGroups) {
    $results = Get-MgGroup -Top $Top -Property 'displayName,mail,mailEnabled,securityEnabled,groupTypes'

    $view = @('DisplayName','Mail','MailEnabled','SecurityEnabled','GroupTypes')
}

else {
    Write-WarnLine 'No action selected. Use -ListGroups, -GroupId, -ListGroupMembers, -ListGroupOwners, -ListEmptyGroups, -ListLargeGroups or -ListGroupsWithoutOwners.'
    return
}

Show-ToolkitOutput -Data $results -View $view -Table:$Table

if ($Export) {
    Export-ToolkitCsv -InputObject $results -Name 'group-results' -ScriptName 'groups'
}