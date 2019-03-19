function Set-WebReportsServer {
  <#  
   .Synopsis
    Sets the default Web Reports Server object.
  
   .Description
    Sets the default Web Reports Server object to use when calling New-WebReportsSession
    with the -Default switch. If the Web Reports Server object does not yet exist in 
    the registry, then it will also be added.
   
   .Parameter Server
    Specifies the Web Reports Server object (created using New-WebReportsServer
    or returned from Get-WebReportsServer) to set as default. 

   .Parameter Uri
    Specifies a well-formed absolute URI to the Web Reports Server to be set as the
    default. A new Web Reports Server object will be registered if one is not 
    already found matching the URI.
  
   .Example
    # Sets the default Web Reports Session object to the Web Reports Server defined in 
    # the $MyServer variable.
    Set-WebReportsServer -Server $MyServer

   .Example
    # Sets the default Web Reports Server object to the server 'webreports' over HTTPS,
    # creating and registering a new object if a matching one does not already exist.
    Set-WebReportsServer -Uri 'https://webreports/'
    
  #>
  [CmdletBinding(DefaultParameterSetName = 'URI')]
  param(
    [Parameter(
      Mandatory = $true,
      Position = 0,
      ParameterSetName = 'SERVER',
      HelpMessage = 'Web Reports Server object for the Web Reports Server'
    )]
    [ValidateNotNull()]
    [PSTypeName('BigFix.WebReports.Server')]$Server,

    [Parameter(
      Mandatory = $true,
      Position = 0,
      ValueFromPipeline = $true,
      ParameterSetName = 'URI',
      HelpMessage = 'Well-formed absolute URI to the Web Reports Server (e.g. https://webreports/)'
    )]
    [ValidateScript( { Test-Uri -Uri $_ -Kind Absolute -Throw })]
    [string]$Uri    
  )
  
  if ($PSCmdlet.ParameterSetName -eq 'URI') {
    $Server = New-WebReportsServer -Uri $Uri -NoPersist
  }

  $Servers = Get-Variable -Name WebReportsServers -ValueOnly -Scope Script -ErrorAction SilentlyContinue

  $found = $false
  foreach ($s in @($Servers)) {
    if ($s.Uri -eq $Server.Uri) {
      $found = $true
      $Server = $s
      break
    }
  }
  
  if ($found -eq $false) {
    $null = Set-Variable -Name WebReportsServers -Value @($Servers + $Server) -Scope Script -Force
  }
  
  $null = Set-Variable -Name WebReportsServersDefault -Value $Server -Scope Script -Force

  return $Server
}