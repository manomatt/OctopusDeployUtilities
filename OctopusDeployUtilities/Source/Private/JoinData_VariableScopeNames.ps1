
Set-StrictMode -Version Latest

#region Function: Update-ODUExportAddScopeNamesToVariable

<#
.SYNOPSIS
Adds scope names to variables
.DESCRIPTION
Adds scope names to variables
.PARAMETER Path
Path to export folder that contains folders exported values
.EXAMPLE
Update-ODUExportAddScopeNamesToVariable -Path c:\Exports\MyOctoServer.octopus.app\20181120-103152
<adds scope names to variables>
#>
function Update-ODUExportAddScopeNamesToVariable {
  #region Function parameters
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [ValidateNotNullOrEmpty()]
    [string]$Path = $(throw "$($MyInvocation.MyCommand) : missing parameter Path")
  )
  #endregion
  process {
    if ($false -eq (Test-Path -Path $Path)) { throw "No export found at: $Path" }

    [string]$LookupPath = Join-Path -Path $Path -ChildPath $IdToNameLookupFileName
    if ($false -eq (Test-Path -Path $LookupPath)) { throw "Export Id to name lookup file not found: $LookupPath" }
    $IdToNameLookup = ConvertFrom-Json -InputObject (Get-Content -Path $LookupPath -Raw)

    # for this we only process the Variables data
    $RestApiCall = Get-ODUStandardExportRestApiCall | Where-Object { $_.RestName -eq 'Variables' }
    $ItemExportFolder = Join-Path -Path $Path -ChildPath ($RestApiCall.RestName)

    if (($null -ne $RestApiCall.ExternalIdToResolvePropertyName) -and ($RestApiCall.ExternalIdToResolvePropertyName.Count -gt 0)) {
      # loop through all files under item folder
      Get-ChildItem -Path $ItemExportFolder -Recurse | ForEach-Object {
        $ExportFilePath = $_.FullName
        $ExportItem = ConvertFrom-Json -InputObject (Get-Content -Path $ExportFilePath -Raw)

        $ExportItem.Variables | Where-Object { $null -ne (Get-Member -InputObject $_.Scope -Type NoteProperty) } | ForEach-Object {
          $Variable = $_

          [string[]]$Breadth = @()
          # if re-running this on files that have already been processed then *-Name properties will already exist
          # along with Breadth property so filter them out from this list
          (Get-Member -InputObject $Variable.Scope -Type NoteProperty).Name | Where-Object { $_ -notmatch '.*Name$' -and $_ -ne 'Breadth' } | ForEach-Object {
            $ScopePropertyName = $_
            [string[]]$ScopePropertyValue = @()

            $Variable.Scope.$ScopePropertyName | ForEach-Object {
              $ScopePropertyNameIdValue = $_
              # do not create new project / do lookups for Roles  - these are just text and get added as-is to Breadth
              if ($ScopePropertyName -eq 'Role') {
                $ScopePropertyDisplayName = $ScopePropertyNameIdValue
              } else {
                $ScopePropertyDisplayName = Get-ODUIdToNameLookupValue -Lookup $IdToNameLookup -Key $ScopePropertyNameIdValue
              }
              $ScopePropertyValue += $ScopePropertyDisplayName
              $Breadth += $ScopePropertyDisplayName
            }
            # again, don't add <scope property>Name lookup values for roles
            if ($ScopePropertyName -ne 'Role') {
              Add-ODUOrUpdateMember -InputObject $Variable.Scope -PropertyName ($ScopePropertyName + 'Name') -Value ([string[]]($ScopePropertyValue | Sort-Object))
            }
          }
          Add-ODUOrUpdateMember -InputObject $Variable.Scope -PropertyName 'Breadth' -Value ([string[]]($Breadth | Sort-Object))
        }
        Out-ODUFileJson -FilePath $ExportFilePath -Data $ExportItem
      }
    }
  }
}
