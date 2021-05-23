function New-WebReportsServer {
  <#  
   .Synopsis
    Creates a new Web Reports Server object.
  
   .Description
    Creates a new Web Reports Server object to use when calling New-WebReportsSession,
    and [optionally] both registers and sets it as the default Web Reports Server object. 
   
   .Parameter Uri
    Specifies a well-formed absolute URI to the Web Reports Server.
  
   .Parameter Fqdn
    Specifies the Fully Qualified Domain Name (FQDN) of the Web Reports Server. This
    can be entered either as just the hostname, IP address, or the FQDN (preferred).

   .Parameter Port
    Specifies the TCP port number of the Web Reports Server, if a non-standard (80/443)
    port is being used.

   .Parameter Ssl
    Switch specifying if SSL (HTTPS) is to be used when connecting to the Web Reports Server.

   .Parameter NoPersist
    Switch specifying that the Web Reports Server object created not be persisted to the 
    registry nor set as the default.
   
   .Example
    # Create a new Web Reports Server object to the server 'webreports' over HTTPS,
    # using URI nomenclature.
    New-WebReportsServer -Uri 'https://webreports/'

   .Example
    # Create a new Web Reports Server object to the server 'webreports' over HTTPS,
    # using URI nomenclature, and requesting it be non-persisted.
    New-WebReportsServer -Uri 'https://webreports/' -NoPersist

   .Example
    # Create a new Web Reports Server object to the server 'webreports' over HTTP on
    # the default HTTP port (80).
    New-WebReportsServer -Fqdn 'webreports'

   .Example
    # Create a new Web Reports Server object to the server 'webreports' over HTTP on
    # the non-standard TCP port (8080).
    New-WebReportsServer -Fqdn 'webreports' -Port 8080
    
   .Example
    # Create a new Web Reports Server object to the server 'webreports' over HTTP on
    # the non-standard TCP port (8080) and request it to be non-persisted.
    New-WebReportsServer -Fqdn 'webreports' -Port 8080 -NoPersist

   .Example
    # Create a new Web Reports Server object to the server 'webreports' over HTTPS on
    # the default HTTPS port (443).
    New-WebReportsServer -Fqdn 'webreports' -Ssl

   .Example
    # Create a new Web Reports Server object to the server 'webreports' over HTTPS on
    # the non-standard TCP port (8443).
    New-WebReportsServer -Fqdn 'webreports' -Port 8443 -Ssl

   .Example
    # Create a new Web Reports Server object to the server 'webreports' over HTTPS on
    # the non-standard TCP port (8443) and request it to be non-persisted.
    New-WebReportsServer -Fqdn 'webreports' -Port 8443 -Ssl -NoPersist

  #>
  [CmdLetBinding(DefaultParameterSetName = 'URI')]
  [OutputType('BigFix.WebReports.Server')]
  param(
    [Parameter(
      Mandatory = $true, 
      Position = 0, 
      ParameterSetName = 'URI',
      HelpMessage = 'Well-formed absolute URI to the Web Reports Server (e.g. https://webreports/)'
    )]
    [ValidateScript( { Test-Uri -Uri $_ -Kind Absolute -Throw })]
    [string]$Uri,

    [Parameter(
      Mandatory = $true,
      Position = 0,
      ParameterSetName = 'FQDN',
      HelpMessage = 'FQDN of the Web Reports Server (e.g. webreports)'
    )]
    [ValidateNotNullOrEmpty()]
    [string]$Fqdn,

    [Parameter(
      Mandatory = $false,
      Position = 1,
      ParameterSetName = 'FQDN',
      HelpMessage = 'TCP port of the Web Reports Server (commonly port 80 for HTTP, 443 for HTTPS)'
    )]
    [int]$Port = -1,

    [Parameter(
      Mandatory = $false,
      ParameterSetName = 'FQDN',
      HelpMessage = 'Use HTTPS (SSL) when communicating with the Web Reports Server'
    )]
    [Switch]$Ssl = $false,

    [Parameter(
      Mandatory = $false,
      HelpMessage = 'Do not persist the resulting Web Reports Server object'
    )]
    [Switch]$NoPersist = $false
  )

  if ($PSCmdlet.ParameterSetName -eq 'URI') {
    [System.Uri]$ParsedUri = Test-Uri -Uri $Uri -Kind Absolute -Scheme @([System.Uri]::UriSchemeHttp, [System.Uri]::UriSchemeHttps) -PassThru -Transform

    if ($null -eq $ParsedUri) {
      throw "Cannot validate argument on parameter 'Uri'. The argument ""$($Uri)"" is not a well-formed absolute HTTP or HTTPS URI. Supply an argument that is a well-formed absolute HTTP or HTTPS URI and try the command again."
    }
      
    $Fqdn = $ParsedUri.Host
    $Port = if ($ParsedUri.IsDefaultPort) { -1 } else { $ParsedUri.Port }
    $Ssl = $ParsedUri.Scheme -eq [System.Uri]::UriSchemeHttps
  }
  else {
    if (![System.Uri]::CheckHostName($Fqdn)) {
      throw "Cannot validate argument on parameter 'Fqdn'. The argument ""$($Fqdn)"" is not a valid FQDN. Supply an argument that is a FQDN and try the command again."
    }
  }
  
  $scheme = if ($Ssl) { [System.Uri]::UriSchemeHttps } else { [System.Uri]::UriSchemeHttp }
  [System.UriBuilder]$uriBuilder = New-Object -TypeName System.UriBuilder -ArgumentList $scheme, $Fqdn, $Port
  $Uri = $uriBuilder.ToString()

  $uriBuilder.Query = 'wsdl'

  $server = [PSCustomObject]@{
    PSTypeName = 'BigFix.WebReports.Server'
    Uri        = $Uri
    Wsdl       = $uriBuilder.ToString()
  }
  $server = $server | Add-Member -MemberType ScriptMethod -Name ToString -Value { $this.Uri } -Force -PassThru
  
  if ($NoPersist -ne $true) {
    $null = Set-WebReportsServer -Server $server
  }

  return $server
}
