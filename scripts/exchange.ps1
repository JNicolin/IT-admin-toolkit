[CmdletBinding()]
param(
    [switch]$ShowAuditStatus,
    [switch]$EnableUnifiedAuditLog,

    [switch]$ListMailboxes,
    [switch]$ListSharedMailboxes,
    [string]$MailboxIdentity,
    [switch]$ShowMailboxStatistics,
    [switch]$ShowMailboxPermissions,

    [switch]$ReviewMailboxPermissions,
    [switch]$ReviewSharedMailboxPermissions,

    [switch]$ListTransportRules,
    [switch]$ListAcceptedDomains,
    [switch]$ListInboundConnectors,
    [switch]$ListOutboundConnectors,

    [switch]$SearchAuditLog,
    [datetime]$StartDate,
    [datetime]$EndDate,
    [string]$AuditUserId,
    [string[]]$AuditOperations,

    [int]$Top = 25,
    [switch]$Table,
    [switch]$Export
)

$scriptRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $scriptRoot 'common.ps1')
. (Join-Path $scriptRoot 'config.ps1')

if (-not (Test-CommandAvailable -Name 'Get-AdminAuditLogConfig')) {
    throw 'Exchange Online cmdlets are not available. Run connect.ps1 first.'
}

$results = $null
$view = @()

# Unified audit log status
if ($EnableUnifiedAuditLog) {
    Write-Step 'Enabling unified audit log ingestion'
    Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true
    Write-Ok 'Unified audit log ingestion enabled'
}

if ($ShowAuditStatus) {
    Write-Step 'Getting unified audit log status'

    $config = Get-AdminAuditLogConfig

    $results = [PSCustomObject]@{
        UnifiedAuditLogEnabled = $config.UnifiedAuditLogIngestionEnabled
    }

    $view = @('UnifiedAuditLogEnabled')
}

# Shared mailboxes
elseif ($ListSharedMailboxes) {
    Write-Step 'Listing shared mailboxes'

    $results = Get-EXOMailbox -RecipientTypeDetails SharedMailbox -ResultSize $Top -Properties DisplayName,PrimarySmtpAddress,ArchiveStatus |
        Select-Object DisplayName, UserPrincipalName, PrimarySmtpAddress, ArchiveStatus, RecipientTypeDetails

    $view = @('DisplayName','UserPrincipalName','PrimarySmtpAddress','ArchiveStatus','RecipientTypeDetails')
}

# Mailbox statistics / permissions / mailbox details
elseif ($MailboxIdentity -and $ShowMailboxStatistics) {
    Write-Step 'Getting mailbox statistics'

    $results = Get-EXOMailboxStatistics -Identity $MailboxIdentity |
        Select-Object DisplayName, TotalItemSize, ItemCount, LastLogonTime

    $view = @('DisplayName','TotalItemSize','ItemCount','LastLogonTime')
}
elseif ($MailboxIdentity -and $ShowMailboxPermissions) {
    Write-Step 'Getting mailbox permissions'

    $results = Get-EXOMailboxPermission -Identity $MailboxIdentity |
        Where-Object { $_.User -ne 'NT AUTHORITY\SELF' } |
        Select-Object Identity, User, AccessRights, IsInherited, Deny

    $view = @('Identity','User','AccessRights','IsInherited','Deny')
}
elseif ($MailboxIdentity) {
    Write-Step 'Getting mailbox details'

    $results = Get-EXOMailbox -Identity $MailboxIdentity -Properties DisplayName,PrimarySmtpAddress,RecipientTypeDetails,ArchiveStatus |
        Select-Object DisplayName, UserPrincipalName, PrimarySmtpAddress, RecipientTypeDetails, ArchiveStatus

    $view = @('DisplayName','UserPrincipalName','PrimarySmtpAddress','RecipientTypeDetails','ArchiveStatus')
}

# Mailbox permission review - user mailboxes
elseif ($ReviewMailboxPermissions) {
    Write-Step 'Reviewing mailbox permissions for user mailboxes'

    $mailboxes = Get-EXOMailbox -RecipientTypeDetails UserMailbox -ResultSize Unlimited -Properties DisplayName,PrimarySmtpAddress

    $results = foreach ($mailbox in $mailboxes) {
        $permissions = Get-EXOMailboxPermission -Identity $mailbox.UserPrincipalName |
            Where-Object { $_.User -ne 'NT AUTHORITY\SELF' -and $_.IsInherited -eq $false }

        foreach ($perm in $permissions) {
            [PSCustomObject]@{
                DisplayName        = $mailbox.DisplayName
                UserPrincipalName  = $mailbox.UserPrincipalName
                PrimarySmtpAddress = $mailbox.PrimarySmtpAddress
                Trustee            = $perm.User
                AccessRights       = ($perm.AccessRights -join ', ')
                IsInherited        = $perm.IsInherited
                Deny               = $perm.Deny
            }
        }
    }

    if ($results) {
        $results = $results | Select-Object -First $Top
    }

    $view = @('DisplayName','UserPrincipalName','PrimarySmtpAddress','Trustee','AccessRights','IsInherited','Deny')
}

# Mailbox permission review - shared mailboxes
elseif ($ReviewSharedMailboxPermissions) {
    Write-Step 'Reviewing mailbox permissions for shared mailboxes'

    $mailboxes = Get-EXOMailbox -RecipientTypeDetails SharedMailbox -ResultSize Unlimited -Properties DisplayName,PrimarySmtpAddress

    $results = foreach ($mailbox in $mailboxes) {
        $permissions = Get-EXOMailboxPermission -Identity $mailbox.UserPrincipalName |
            Where-Object { $_.User -ne 'NT AUTHORITY\SELF' -and $_.IsInherited -eq $false }

        foreach ($perm in $permissions) {
            [PSCustomObject]@{
                DisplayName        = $mailbox.DisplayName
                UserPrincipalName  = $mailbox.UserPrincipalName
                PrimarySmtpAddress = $mailbox.PrimarySmtpAddress
                Trustee            = $perm.User
                AccessRights       = ($perm.AccessRights -join ', ')
                IsInherited        = $perm.IsInherited
                Deny               = $perm.Deny
            }
        }
    }

    if ($results) {
        $results = $results | Select-Object -First $Top
    }

    $view = @('DisplayName','UserPrincipalName','PrimarySmtpAddress','Trustee','AccessRights','IsInherited','Deny')
}

# List mailboxes
elseif ($ListMailboxes) {
    Write-Step 'Listing mailboxes'

    $results = Get-EXOMailbox -ResultSize $Top -Properties DisplayName,PrimarySmtpAddress,RecipientTypeDetails |
        Select-Object DisplayName, UserPrincipalName, PrimarySmtpAddress, RecipientTypeDetails

    $view = @('DisplayName','UserPrincipalName','PrimarySmtpAddress','RecipientTypeDetails')
}

# Mail flow and domains
elseif ($ListTransportRules) {
    Write-Step 'Listing transport rules'

    $results = Get-TransportRule |
        Select-Object Name, State, Mode, Priority

    $view = @('Name','State','Mode','Priority')
}
elseif ($ListAcceptedDomains) {
    Write-Step 'Listing accepted domains'

    $results = Get-AcceptedDomain |
        Select-Object Name, DomainName, DomainType, Default

    $view = @('Name','DomainName','DomainType','Default')
}
elseif ($ListInboundConnectors) {
    Write-Step 'Listing inbound connectors'

    $results = Get-InboundConnector |
        Select-Object Name, Enabled, ConnectorType, SenderDomains

    $view = @('Name','Enabled','ConnectorType','SenderDomains')
}
elseif ($ListOutboundConnectors) {
    Write-Step 'Listing outbound connectors'

    $results = Get-OutboundConnector |
        Select-Object Name, Enabled, ConnectorType, RecipientDomains

    $view = @('Name','Enabled','ConnectorType','RecipientDomains')
}

# Unified audit log search
elseif ($SearchAuditLog) {
    Write-Step 'Searching unified audit log'

    if (-not $StartDate -or -not $EndDate) {
        throw 'Use -StartDate and -EndDate together with -SearchAuditLog.'
    }

    $params = @{
        StartDate  = $StartDate
        EndDate    = $EndDate
        ResultSize = $Top
        Formatted  = $true
    }

    if ($AuditUserId) {
        $params.UserIds = @($AuditUserId)
    }

    if ($AuditOperations) {
        $params.Operations = $AuditOperations
    }

    $results = Search-UnifiedAuditLog @params |
        Select-Object CreationDate, UserIds, Operations, RecordType, AuditData

    $view = @('CreationDate','UserIds','Operations','RecordType','AuditData')
}

else {
    Write-WarnLine 'No action selected. Use -ShowAuditStatus, -EnableUnifiedAuditLog, -ListMailboxes, -ListSharedMailboxes, -MailboxIdentity, -ShowMailboxStatistics, -ShowMailboxPermissions, -ReviewMailboxPermissions, -ReviewSharedMailboxPermissions, -ListTransportRules, -ListAcceptedDomains, -ListInboundConnectors, -ListOutboundConnectors or -SearchAuditLog.'
    return
}

Show-ToolkitOutput -Data $results -View $view -Table:$Table

if ($Export) {
    Export-ToolkitCsv -InputObject $results -Name 'exchange-results' -ScriptName 'exchange'
}