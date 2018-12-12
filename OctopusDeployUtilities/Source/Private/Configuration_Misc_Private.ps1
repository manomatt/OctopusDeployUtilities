
Set-StrictMode -Version Latest

#region Function: Convert-ODUDecryptApiKey

<#
.SYNOPSIS
Decrypts an encrypted value - Windows machines only
.DESCRIPTION
Decrypts an encrypted value - Windows machines only
.PARAMETER ApiKey
Value to decrypt
.EXAMPLE
Convert-ODUDecryptApiKey <encrypted value>
API-ABCDEFGH01234567890ABCDEFGH
#>
function Convert-ODUDecryptApiKey {
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ApiKey
  )
  process {
    # Decrypt ONLY if this IsWindows; PS versions 5 and below are only Windows, 6 has explicit variable
    if (($PSVersionTable.PSVersion.Major -le 5) -or ($true -eq $IsWindows)) {
      Write-Verbose "$($MyInvocation.MyCommand) :: Decrypting ApiKey"
      $ApiKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR( ($ApiKey | ConvertTo-SecureString) ))
    }
    $ApiKey
  }
}
#endregion


#region Function: Convert-ODUEncryptApiKey

<#
.SYNOPSIS
Encrypts an plain text value - Windows machines only
.DESCRIPTION
Encrypts an plain text value - Windows machines only
The API used only works on Windows machines (as of PowerShell 6.1)
.PARAMETER ApiKey
Text to encrypt
.EXAMPLE
Convert-ODUEncryptApiKey 'API-ABCDEFGH01234567890ABCDEFGH'
<encrypted value>
#>
function Convert-ODUEncryptApiKey {
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ApiKey
  )
  process {
    # Decrypt ONLY if this IsWindows; PS versions 5 and below are only Windows, 6 has explicit variable
    if (($PSVersionTable.PSVersion.Major -le 5) -or ($true -eq $IsWindows)) {
      Write-Verbose "$($MyInvocation.MyCommand) :: Encrypting ApiKey"
      $ApiKey = ConvertTo-SecureString -String $ApiKey -AsPlainText -Force | ConvertFrom-SecureString
    }
    $ApiKey
  }
}
#endregion



#region Function: Get-ODUConfigOctopusServerSection

<#
.SYNOPSIS
Creates Octopus Server-specific section of the configuration
.DESCRIPTION
Creates Octopus Server-specific section of the configuration, uses values from user
along with default values for type/property black/white lists.
.PARAMETER Name
Name of Octopus server
.PARAMETER Url
Url of Octopus server
.PARAMETER ApiKeySecure
Encrypted API Key
.EXAMPLE
Get-ODUConfigOctopusServerSection -Name 'MyOctoServer.octopus.app' -Url 'https://MyOctoServer.octopus.app' -ApiKeySecure <encrypted value>
<hashtable with these values and default black/white list values>
#>
function Get-ODUConfigOctopusServerSection {
  [CmdletBinding()]
  [OutputType([hashtable])]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Name,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Url,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ApiKeySecure
    )
  process {
    Write-Verbose "$($MyInvocation.MyCommand) :: Creating Octopus Server configuration section"
    $OctoServer = @{ }
    Write-Verbose "$($MyInvocation.MyCommand) :: Octopus server Name: $Name"
    $OctoServer.Name = $Name
    Write-Verbose "$($MyInvocation.MyCommand) :: Octopus server Url: $Url"
    $OctoServer.Url = $Url

    Write-Verbose "$($MyInvocation.MyCommand) :: Octopus API Key - first 7 characters: $((Convert-ODUDecryptApiKey -ApiKey $ApiKeySecure).Substring(0,8))..."
    $OctoServer.ApiKey = $ApiKeySecure
    $OctoServer.TypeBlacklist = Get-ODUConfigDefaultTypeBlacklist
    $OctoServer.TypeWhitelist = Get-ODUConfigDefaultTypeWhitelist
    $OctoServer.PropertyBlacklist = Get-ODUConfigDefaultPropertyBlacklist
    $OctoServer.PropertyWhitelist = Get-ODUConfigDefaultPropertyWhitelist
    $OctoServer.LastPurgeCompareFolder = $Undefined
    $OctoServer.Search = @{
      CodeRootPaths     = $Undefined
      CodeSearchPattern = $Undefined
    }
    $OctoServer
  }
}
#endregion


#region Function: Test-ODUConfigFilePath

<#
.SYNOPSIS
Tests if configuration file exists (returns $true or $false)
.DESCRIPTION
Tests if configuration file exists; returns $true if it does, $false otherwise.
Use this to test if configuration initialized without throwing exception like
Confirm-ODUConfig does.
.EXAMPLE
Test-ODUConfigFilePath
$true
(already existed)
#>
function Test-ODUConfigFilePath {
  [CmdletBinding()]
  [OutputType([bool])]
  param()
  process {
    Test-Path -Path (Get-ODUConfigFilePath)
  }
}
#endregion
