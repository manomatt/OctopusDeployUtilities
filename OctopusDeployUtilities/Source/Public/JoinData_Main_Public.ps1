
Set-StrictMode -Version Latest

#region Function: Update-ODUExportJoinData

<#
.SYNOPSIS
Post processes export data: gets lookup data, adds id/name values, scope names, etc.
.DESCRIPTION
Post processes export data:
 - creates id to name lookup
 - adds external names for ids in exported data
 - adds scope names to variables
 - adds machine information to environments
 - adds deployment processes to projects
 - adds variable sets to projects
 - adds included library variable sets to projects
.PARAMETER Path
Full path to individual export
.PARAMETER Quiet
Suppress status output
.EXAMPLE
Update-ODUExportJoinData
#>
function Update-ODUExportJoinData {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Path,
    [switch]$Quiet
  )
  process {
    if ($false -eq (Test-Path -Path $Path)) { throw "No export found at: $Path" }

    # create lookup object in root of export with every Id and name for every exported item
    if (! $Quiet) { Write-Output "Creating Id to name lookup" }
    New-ODUIdToNameLookup $Path

    # for each exported item, look for external Id values in it, lookup the external name for the external id and add to exported item
    if (! $Quiet) { Write-Output "Adding external names for ids in exported data" }
    Update-ODUExportAddExternalNamesForIds $Path

    # for exported variables, add scope names and breadth
    if (! $Quiet) { Write-Output "Adding scope names to variables" }
    Update-ODUExportAddScopeNamesToVariables $Path

    # add machines listing to environments
    if (! $Quiet) { Write-Output "Adding machine information to environments" }
    Update-ODUExportAddMachinesToEnvironments $Path

    # add deployment processes to projects
    if (! $Quiet) { Write-Output "Adding deployment processes to projects" }
    Update-ODUExportProjectAddDeploymentProcess $Path

    # add variable sets to projects
    if (! $Quiet) { Write-Output "Adding variable sets to projects" }
    Update-ODUExportProjectAddVariableSet $Path

    # add included library variable sets to projects
    if (! $Quiet) { Write-Output "Adding included library variable sets to projects" }
    Update-ODUExportProjectAddIncludedLibraryVariableSets $Path
  }
}
#endregion