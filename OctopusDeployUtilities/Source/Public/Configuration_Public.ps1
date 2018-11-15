
#region Function: Add-ODUConfigOctopusServer

<#
.SYNOPSIS
Sets Octopus Server configuration (root url and API key)
.DESCRIPTION
Sets Octopus Server configuration (root url and API key)
See this for more info about API key: https://octopus.com/docs/api-and-integration/api/how-to-create-an-api-key

Note: this is Add- not Set- because (eventually) ODU will support multiple Octo setups in the configuration
.PARAMETER Url
Root url of Octopus server
.PARAMETER ApiKey
API Key for a specific user account to use for exports
.EXAMPLE
Add-ODUConfigOctopusServer -Url https://MyOctoServer.octopus.app -ApiKey 'API-123456789012345678901234567'
<validates then sets url and api key for Octo server>
#>
function Add-ODUConfigOctopusServer {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Url,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ApiKey
  )
  process {
    if ($false -eq (Confirm-ODUConfig)) { return }

    $Config = Get-ODUConfig

    # asdf if config settings already exist, ask to overwrite????
    # asdf validate server url format
    # asdf url remove trailing / if present
    # asdf validate server url and credentials - test swagger or /api or something


    # asdf GET NAME
    # asdf create Name - get server url for now
    # when support multiple servers/instances, will expose Name parameter on this function


    # asdf need integration testing to validate API key


    # Encrypt ONLY if this IsWindows; PS versions 5 and below are only Windows, 6 has explicit variable
    $ApiKeySecure = $ApiKey
    if (($PSVersionTable.PSVersion.Major -le 5) -or ($true -eq $IsWindows)) {
      $ApiKeySecure = ConvertTo-SecureString -String $ApiKey -AsPlainText -Force | ConvertFrom-SecureString
    }

    $OctoServer = @{ }
    $OctoServer.Name = $Name
    $OctoServer.Url = $Url
    $OctoServer.ApiKey = $ApiKeySecure
    $OctoServer.TypeBlackList = Get-ODUConfigDefaultTypeBlackList
    $OctoServer.TypeWhiteList = Get-ODUConfigDefaultTypeWhiteList
    $OctoServer.PropertyBlackList = Get-ODUConfigDefaultPropertyBlackList
    $OctoServer.PropertyWhiteList = Get-ODUConfigDefaultPropertyWhiteList
    $OctoServer.LastPurgeCompareFolder = $Undefined
    $OctoServer.Search = @{
      CodeRootPaths     = $Undefined
      CodeSearchPattern = $Undefined
    }
    $Config.OctopusServers += $OctoServer
    Save-ODUConfig -Config $Config
  }
}
#endregion


#region Function: Get-ODUConfigDiffViewer

<#
.SYNOPSIS
Gets path for diff viewer on local machine
.DESCRIPTION
Gets path for diff viewer on local machine
.EXAMPLE
Get-ODUConfigDiffViewer
<path to diff viewer>
#>
function Get-ODUConfigDiffViewer {
  [CmdletBinding()]
  [OutputType([string])]
  param()
  process {
    if ($false -eq (Confirm-ODUConfig)) { return }
    (Get-ODUConfig).ExternalTools.DiffViewerPath
  }
}
#endregion


#region Function: Get-ODUConfigExportRootFolder

<#
.SYNOPSIS
Returns export root folder path
.DESCRIPTION
Returns export root folder path
.EXAMPLE
Get-ODUConfigExportRootFolder
<export root folder path>
#>
function Get-ODUConfigExportRootFolder {
  [CmdletBinding()]
  [OutputType([string])]
  param()
  process {
    if ($false -eq (Confirm-ODUConfig)) { return }
    (Get-ODUConfig).ExportRootFolder
  }
}
#endregion


#region Function: Get-ODUConfigFilePath

<#
.SYNOPSIS
Gets path to configuration file
.DESCRIPTION
Gets path to configuration file
.EXAMPLE
Get-ODUConfigFilePath
<path to file Configuration.psd1>
#>
function Get-ODUConfigFilePath {
  [CmdletBinding()]
  [OutputType([string])]
  param()
  process {
    # Because the configuration stores the API encrypted, the configuration is stored using User scope.
    Join-Path -Path (Get-ConfigurationPath -Scope User -Version ([version]$ConfigVersion)) -ChildPath 'Configuration.psd1'
  }
}
#endregion


#region Function: Get-ODUConfigTextEditor

<#
.SYNOPSIS
Gets path for text editor on local machine
.DESCRIPTION
Gets path for text editor on local machine
.EXAMPLE
Get-ODUConfigTextEditor
<path to text editor>
#>
function Get-ODUConfigTextEditor {
  [CmdletBinding()]
  [OutputType([string])]
  param()
  process {
    if ($false -eq (Confirm-ODUConfig)) { return }
    (Get-ODUConfig).ExternalTools.TextEditorPath
  }
}
#endregion


#region Function: Set-ODUConfigDiffViewer

<#
.SYNOPSIS
Sets path for diff viewer on local machine
.DESCRIPTION
Sets path for diff viewer on local machine
.PARAMETER Path
Path to diff viewer
.EXAMPLE
Set-ODUConfigDiffViewer -Path 'C:\Program Files\ExamDiff Pro\ExamDiff.exe'
<sets path to diff viewer>
#>
function Set-ODUConfigDiffViewer {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Path
  )
  process {
    if ($false -eq (Confirm-ODUConfig)) { return }

    if ($false -eq (Test-Path -Path $Path)) {
      Write-Verbose "Path is not valid: $Path"
      throw "Path is not valid: $Path"
    } else {
      $Config = Get-ODUConfig
      $Config.ExternalTools.DiffViewerPath = $Path
      Write-Verbose "Saving configuration with DiffViewerPath: $Path"
      Save-ODUConfig -Config $Config
    }
  }
}
#endregion


#region Function: Set-ODUConfigExportRootFolder

<#
.SYNOPSIS
Sets path for export root folder
.DESCRIPTION
Sets path for export root folder
.PARAMETER Path
Path to export root folder
.EXAMPLE
Set-ODUConfigExportRootFolder -Path c:\OctoExports
<sets root path for exports>
#>
function Set-ODUConfigExportRootFolder {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Path
  )
  process {

    try {
      # try to create export folder first before creating config, if errors creating folder then exit without updating configuration
      if ($false -eq (Test-Path -Path $Path)) {
        # must explicitly stop if there's an error; don't create config unless this is valid
        Write-Verbose "Creating root export folder: $Path"
        New-Item -Path $Path -ItemType Directory -ErrorAction Stop > $null
      }

      # this function is run to initialize the settings for the project so if settings files doesn't currently exist it should be created
      # however, it's possible for a user to update an existing instance to change the root export path, so only initialize config if first time
      if ($false -eq (Confirm-ODUConfig)) {
        Initialize-ODUConfig
      } else {
        Write-Verbose 'Old configuration already found, user is updating export root folder'
        Write-Output "Make sure you move any old exports from $((Get-ODUConfig).ExportRootFolder) to new path: $Path"
      }

      # update root folder
      $Config = Get-ODUConfig
      $Config.ExportRootFolder = $Path
      Write-Verbose "Saving configuration with ExportRootFolder: $Path"
      Save-ODUConfig -Config $Config

    } catch {
      throw "An error occurred creating export root folder; invalid path? $Path"
    }
  }
}
#endregion


#region Function: Set-ODUConfigTextEditor

<#
.SYNOPSIS
Sets path for text editor on local machine
.DESCRIPTION
Sets path for text editor on local machine
.PARAMETER Path
Path to text editor
.EXAMPLE
Set-ODUConfigTextEditor -Path ((Get-Command code.cmd).Source)
<sets path for VS Code - if you have it installed>
#>
function Set-ODUConfigTextEditor {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Path
  )
  process {
    if ($false -eq (Confirm-ODUConfig)) { return }

    if ($false -eq (Test-Path -Path $Path)) {
      Write-Verbose "Path is not valid: $Path"
      throw "Path is not valid: $Path"
    } else {
      $Config = Get-ODUConfig
      $Config.ExternalTools.TextEditorPath = $Path
      Write-Verbose "Saving configuration with TextEditorPath: $Path"
      Save-ODUConfig -Config $Config
    }
  }
}
#endregion
