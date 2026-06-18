[CmdletBinding()]
param(
    [switch]$Reconnect,
    [string]$SiteUrl,

    [switch]$ShowWeb,
    [switch]$ShowSite,

    [switch]$ListLists,
    [switch]$ListLibraries,
    [switch]$ListListsWithUniquePermissions,
    [string]$ListName,
    [switch]$CheckListUniquePermissions,

    [switch]$ListTenantSites,

    [switch]$ListSiteGroups,
    [string]$GroupName,
    [switch]$ListGroupMembers,

    [switch]$ListSiteAdmins,

    [switch]$ListFolderItems,
    [string]$FolderSiteRelativeUrl,
    [string]$LibraryTitle,
    [switch]$Recursive,

    [switch]$TenantSitesDetailed,
    [string]$TenantSiteFilter,
    [switch]$IncludeOneDriveSites,

    [int]$Top = 25,
    [switch]$Table,
    [switch]$Export
)

$scriptRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $scriptRoot 'common.ps1')
. (Join-Path $scriptRoot 'config.ps1')

function Convert-PnPFolderItemToObject {
    param(
        [Parameter(Mandatory)]
        $Item
    )

    $itemType = 'Unknown'
    $serverRelativeUrl = $null
    $name = $null
    $timeCreated = $null
    $timeLastModified = $null

    if ($Item.PSObject.Properties.Name -contains 'File') {
        $itemType = 'File'
        $name = $Item.Name
        $serverRelativeUrl = $Item.ServerRelativeUrl
        $timeCreated = $Item.TimeCreated
        $timeLastModified = $Item.TimeLastModified
    }
    elseif ($Item.PSObject.Properties.Name -contains 'Folder') {
        $itemType = 'Folder'
        $name = $Item.Name
        $serverRelativeUrl = $Item.ServerRelativeUrl
        $timeCreated = $Item.TimeCreated
        $timeLastModified = $Item.TimeLastModified
    }
    else {
        if ($Item.PSObject.Properties.Name -contains 'Name') { $name = $Item.Name }
        if ($Item.PSObject.Properties.Name -contains 'ServerRelativeUrl') { $serverRelativeUrl = $Item.ServerRelativeUrl }
        if ($Item.PSObject.Properties.Name -contains 'TimeCreated') { $timeCreated = $Item.TimeCreated }
        if ($Item.PSObject.Properties.Name -contains 'TimeLastModified') { $timeLastModified = $Item.TimeLastModified }
    }

    [PSCustomObject]@{
        Name              = $name
        ItemType          = $itemType
        ServerRelativeUrl = $serverRelativeUrl
        TimeCreated       = $timeCreated
        TimeLastModified  = $timeLastModified
    }
}

if ($Reconnect) {
    if (-not $SiteUrl) {
        throw 'Use -SiteUrl together with -Reconnect.'
    }

    if (-not $Script:ToolkitConfig.PnPClientId) {
        throw 'PnPClientId is not configured in config.ps1.'
    }

    Write-Step "Connecting to SharePoint site: $SiteUrl"
    Connect-PnPOnline -Url $SiteUrl -ClientId $Script:ToolkitConfig.PnPClientId -Interactive
    Write-Ok "PnP connected to $SiteUrl"
}

if (-not (Test-CommandAvailable -Name 'Get-PnPConnection')) {
    throw 'PnP PowerShell is not available. Run bootstrap.ps1 and connect.ps1 first.'
}

try {
    $connection = Get-PnPConnection
}
catch {
    throw 'PnP is not connected. Run connect.ps1 first or use -Reconnect -SiteUrl <url>.'
}

$results = $null
$view = @()

# Current web
if ($ShowWeb) {
    $results = Get-PnPWeb -Includes Title,Url,ServerRelativeUrl,WebTemplate,Created
    $view = @('Title','Url','ServerRelativeUrl','WebTemplate','Created')
}

# Current site collection
elseif ($ShowSite) {
    $site = Get-PnPSite -Includes RootWeb,ServerRelativeUrl

    $results = [PSCustomObject]@{
        Url               = $connection.Url
        ServerRelativeUrl = $site.ServerRelativeUrl
    }

    $view = @('Url','ServerRelativeUrl')
}

# All lists in current web
elseif ($ListLists) {
    $results = Get-PnPList |
        Select-Object Title, Hidden, ItemCount, @{Name='Url';Expression={$_.RootFolder.ServerRelativeUrl}} |
        Select-Object -First $Top

    $view = @('Title','Hidden','ItemCount','Url')
}

# Libraries only
elseif ($ListLibraries) {
    $results = Get-PnPList |
        Where-Object { $_.BaseType -eq 'DocumentLibrary' } |
        Select-Object Title, Hidden, ItemCount, @{Name='Url';Expression={$_.RootFolder.ServerRelativeUrl}} |
        Select-Object -First $Top

    $view = @('Title','Hidden','ItemCount','Url')
}

# Lists with unique permissions
elseif ($ListListsWithUniquePermissions) {
    Write-Step 'Checking lists for unique permissions'

    $results = Get-PnPList -Includes HasUniqueRoleAssignments |
        Where-Object { $_.HasUniqueRoleAssignments -eq $true } |
        Select-Object Title, Hidden, ItemCount, HasUniqueRoleAssignments, @{Name='Url';Expression={$_.RootFolder.ServerRelativeUrl}} |
        Select-Object -First $Top

    $view = @('Title','Hidden','ItemCount','HasUniqueRoleAssignments','Url')
}

# Specific list permission inheritance check
elseif ($CheckListUniquePermissions) {
    if (-not $ListName) {
        throw 'Use -ListName together with -CheckListUniquePermissions.'
    }

    $list = Get-PnPList -Identity $ListName -Includes HasUniqueRoleAssignments

    $results = [PSCustomObject]@{
        Title                    = $list.Title
        Url                      = $list.RootFolder.ServerRelativeUrl
        Hidden                   = $list.Hidden
        ItemCount                = $list.ItemCount
        HasUniqueRoleAssignments = $list.HasUniqueRoleAssignments
    }

    $view = @('Title','Url','Hidden','ItemCount','HasUniqueRoleAssignments')
}

# Tenant sites
elseif ($ListTenantSites) {
    Write-Step 'Getting tenant sites'

    $params = @{}

    if ($TenantSitesDetailed) {
        $params.Detailed = $true
    }

    if ($IncludeOneDriveSites) {
        $params.IncludeOneDriveSites = $true
    }

    if ($TenantSiteFilter) {
        $params.Filter = $TenantSiteFilter
    }

    $results = Get-PnPTenantSite @params |
        Select-Object Url, Title, Owner, Template, StorageUsageCurrent, LockState |
        Select-Object -First $Top

    $view = @('Title','Url','Owner','Template','StorageUsageCurrent','LockState')
}

# Site groups
elseif ($ListSiteGroups -and -not $ListGroupMembers) {
    if ($GroupName) {
        $results = Get-PnPGroup -Identity $GroupName |
            Select-Object Title, Id, LoginName
    }
    else {
        $results = Get-PnPGroup |
            Select-Object Title, Id, LoginName |
            Select-Object -First $Top
    }

    $view = @('Title','Id','LoginName')
}

# Site group members
elseif ($ListSiteGroups -and $ListGroupMembers) {
    if (-not $GroupName) {
        throw 'Use -GroupName together with -ListSiteGroups -ListGroupMembers.'
    }

    $results = Get-PnPGroupMember -Group $GroupName |
        Select-Object Title, Email, LoginName, PrincipalType |
        Select-Object -First $Top

    $view = @('Title','Email','LoginName','PrincipalType')
}

# Site collection admins
elseif ($ListSiteAdmins) {
    $results = Get-PnPSiteCollectionAdmin |
        Select-Object Title, Email, LoginName, PrincipalType |
        Select-Object -First $Top

    $view = @('Title','Email','LoginName','PrincipalType')
}

# Folder items / library content
elseif ($ListFolderItems) {
    if ($LibraryTitle) {
        Write-Step "Getting items from library: $LibraryTitle"
        $folderItems = Get-PnPFolderItem -List $LibraryTitle
    }
    elseif ($FolderSiteRelativeUrl) {
        Write-Step "Getting items from folder: $FolderSiteRelativeUrl"

        $params = @{
            FolderSiteRelativeUrl = $FolderSiteRelativeUrl
        }

        if ($Recursive) {
            $params.Recursive = $true
        }

        $folderItems = Get-PnPFolderItem @params
    }
    else {
        throw 'Use -FolderSiteRelativeUrl or -LibraryTitle together with -ListFolderItems.'
    }

    $results = $folderItems |
        ForEach-Object { Convert-PnPFolderItemToObject -Item $_ } |
        Select-Object -First $Top

    $view = @('Name','ItemType','ServerRelativeUrl','TimeCreated','TimeLastModified')
}

else {
    Write-WarnLine 'No action selected. Use -ShowWeb, -ShowSite, -ListLists, -ListLibraries, -ListListsWithUniquePermissions, -CheckListUniquePermissions, -ListTenantSites, -ListSiteGroups, -ListGroupMembers, -ListSiteAdmins or -ListFolderItems.'
    return
}

Show-ToolkitOutput -Data $results -View $view -Table:$Table

if ($Export) {
    Export-ToolkitCsv -InputObject $results -Name 'sharepoint-results' -ScriptName 'sharepoint'
}