function Get-WebReportsServer {
  <#  
   .Synopsis
    Gets registered Web Reports Server objects.
  
   .Description
    Gets registered Web Reports Server objects. When called without parameters, a listing of 
    all registered Web Reports Server objects will be returned. If a URI is provided, attempt
    to return the matching Web Reports Server object. If called with the -Default switch, the
    registered default Web Reports Server object will be returned (if found).
   
   .Parameter Uri
    Specifies the well-formed absolute URI of the registered Web Reports Server object to return.

   .Parameter Default
    Switch specifying that the default registered Web Reports Server object is to be returned.
   
   .Inputs
    A System.String specifying the well-formed absolute URI of the registered Web Reports Server object
    to return.

   .Outputs
    A BigFix.WebReports.Server object representing a specific Web Reports Server.

   .Example
    # Gets a listing of all registered Web Reports Server objects.
    Get-WebReportsServer

   .Example
    # Gets the registered Web Reports Server object matching the Web Reports Server URI
    # 'https://webreports/'
    Get-WebReportsServer -Uri 'https://webreports/'

   .Example
    # Gets the default registered Web Reports Server object.
    Get-WebReportsServer -Default

  #>
  [CmdletBinding()]
  [OutputType('BigFix.WebReports.Server')]
  param(
    [Parameter(
      Mandatory = $false,
      Position = 0,
      HelpMessage = 'Well-formed absolute URI to the Web Reports Server (e.g. https://webreports/)'
    )]
    [ValidateScript( { Test-Uri -Uri $_ -Kind Absolute -Throw })]
    [string] $Uri = $null,

    [Parameter(
      Mandatory = $false,
      HelpMessage = 'Get the default Web Reports Server (if set)'
    )]
    [Switch] $Default = $false
  )
  
  if ($Default -eq $true) {
    return Get-Variable -Name WebReportsServersDefault -ValueOnly -Scope Script -ErrorAction SilentlyContinue
  }

  $Servers = Get-Variable -Name WebReportsServers -ValueOnly -Scope Script -ErrorAction SilentlyContinue

  if ($null -eq $Uri -or $Uri -eq "") {
    return @($Servers)
  }

  foreach ($server in @($Servers)) {
    if ($server.Uri -eq $Uri) {
      return $server
    }
  }

  return 
}