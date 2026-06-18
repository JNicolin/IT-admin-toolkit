Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Info {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Cyan
}

function Write-Step {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Yellow
}

function Write-Ok {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Green
}

function Write-WarnLine {
    param([string]$Message)
    Write-Warning $Message
}

function Assert-ConfigLoaded {
    if (-not (Get-Variable -Name ToolkitConfig -Scope Script -ErrorAction SilentlyContinue)) {
        throw 'Toolkit config is not loaded. Copy config.sample.ps1 to config.ps1 and edit it first.'
    }
}

function Get-ToolkitInstallScope {
    Assert-ConfigLoaded
    if ($Script:ToolkitConfig.InstallForCurrentUser) { return 'CurrentUser' }
    'AllUsers'
}

function Ensure-Directory {
    param([Parameter(Mandatory)] [string]$Path)
    if (-not (Test-Path -Path $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
    }
}

function Ensure-Module {
    param(
        [Parameter(Mandatory)] [string]$Name,
        [switch]$AllowClobber,
        [switch]$SkipImport
    )

    Assert-ConfigLoaded

    $installed = Get-Module -ListAvailable -Name $Name | Sort-Object Version -Descending | Select-Object -First 1
    $scope = Get-ToolkitInstallScope

    if (-not $installed) {
        Write-Step "Installing module: $Name"
        $params = @{
            Name  = $Name
            Scope = $scope
            Force = $true
        }
        if ($AllowClobber) { $params.AllowClobber = $true }
        Install-Module @params
    }
    elseif ($Script:ToolkitConfig.UpdateExistingModules) {
        Write-Step "Updating module: $Name"
        try {
            Update-Module -Name $Name -Force -ErrorAction Stop
        }
        catch {
            Write-WarnLine "Could not update $Name. Continuing with installed version. $_"
        }
    }

    if (-not $SkipImport) {
        Import-ToolkitModule -Name $Name
    }
}

function Import-ToolkitModule {
    param([Parameter(Mandatory)] [string]$Name)
    Import-Module $Name
}

function Test-CommandAvailable {
    param([Parameter(Mandatory)] [string]$Name)
    [bool](Get-Command -Name $Name -ErrorAction SilentlyContinue)
}

function Get-Timestamp {
    Get-Date -Format 'yyyyMMdd-HHmmss'
}

function Export-ToolkitCsv {
    param(
        [Parameter(Mandatory)] $InputObject,
        [Parameter(Mandatory)] [string]$Name,
        [string]$OutputPath
    )

    Assert-ConfigLoaded
    if (-not $OutputPath) {
        $OutputPath = $Script:ToolkitConfig.DefaultExportPath
    }

    Ensure-Directory -Path $OutputPath
    $file = Join-Path $OutputPath ("{0}-{1}.csv" -f $Name, (Get-Timestamp))
    $InputObject | Export-Csv -Path $file -NoTypeInformation -Encoding UTF8
    Write-Ok "Exported: $file"
}
function Show-ToolkitOutput {
    param(
        $Data,
        [string[]]$View,
        [switch]$Table
    )

    if (-not $Data) {
        Write-WarnLine 'No results returned.'
        return
    }

    $output = if ($View) {
        $Data | Select-Object $View
    }
    else {
        $Data
    }

    if ($Table) {
        $output | Format-Table -AutoSize
    }
    else {
        $output | Format-List
    }
}