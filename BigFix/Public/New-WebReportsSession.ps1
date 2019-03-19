function New-WebReportsSession {
  <#  
   .Synopsis
    Create a Web Reports Session object.
  
   .Description
    Creates a new Web Reports Session object exposing the BigFix Web Reports SOAP API. 
    This session object is used by the other cmdlets in this module. 
   
   .Parameter Default
    Use the default Web Reports Server previouslly defined to establish the session
    with. The default Web Reports Server is the last one created using 
    New-WebReportsServer or Set-WebReportsServer. Get-WebReportsServer -Default will
    return the current default.

   .Parameter Server
    Specifies the Web Reports Server object (created using New-WebReportsServer
    or returned from Get-WebReportsServer) to establish the session with. 

   .Parameter Uri
    Specifies a well-formed absolute URI to the Web Reports Server to establish 
    the session with. A new Web Reports Server object will be registered
    if one is not already found matching the URI.
  
   .Parameter Credential
    Specifies the Web Reports account either as "myuser", "domain\myusern", or a 
    PSCredential object. Omitting or providing a $null or 
    [System.Management.Automation.PSCredential]::Empty will prompt the caller.
  
   .Example
    # Create a Web Reports Session object to the default Web Reports Server, 
    # prompting for credentails.
    New-WebReportsSession -Default

   .Example
    # Create a Web Reports Session object to the Web Reports Server defined in 
    # the $MyServer variable, prompting for credentails.
    New-WebReportsSession -Server $MyServer

   .Example
    # Create a Web Reports Session object to the server 'webreports' over HTTPS, 
    # prompting for credentails.
    New-WebReportsSession -Uri 'https://webreports/'
  
   .Example
    # Create a Web Reports Session object to the server 'webreports' over HTTP,
    # prompting for credentials.
    New-WebReportsSession -Uri 'http://webreports/'
  
   .Example
    # Create a Web Reports Session object to the server 'webreports' over HTTP
    # on port 8080, prompting for credentials.
    New-WebReportsSession -Uri 'http://webreports:8080/'
  
   .Example
    # Create a Web Reports Session object to the server 'webreports' over HTTPS, 
    # using the [PSCredentail] credential object in the variable $credential.
    New-WebReportsSession -Uri 'https://webreports/' -Credential $credential
  
  #>
  [CmdletBinding(DefaultParameterSetName = 'URI')]
  [OutputType('BigFix.WebReports.Session')]
  param (
    [Parameter(
      Mandatory = $true,
      ParameterSetName = 'DEFAULT',
      HelpMessage = 'Use the default Web Reports Server (see Set-WebReportsServer)'
    )]
    [Switch]$Default,
  
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
      ParameterSetName = 'URI',
      HelpMessage = 'Well-formed absolute URI to the Web Reports Server (e.g. https://webreports/)'
    )]
    [ValidateScript( { Test-Uri -Uri $_ -Kind Absolute -Throw })]
    [String]$Uri,

    [Parameter (
      Mandatory = $false,
      HelpMessage = 'Web Reports account, entered as "myuser", "domain\myuser", or a PSCredential object'
    )]
    [ValidateNotNull()]
    [System.Management.Automation.Credential()]
    [System.Management.Automation.PSCredential]$Credential = [System.Management.Automation.PSCredential]::Empty        
  )
  
  if ('DEFAULT' -eq $PSCmdlet.ParameterSetName) {
    $Server = Get-WebReportsServer -Default

    if ($null -eq $Server) {
      throw 'There is no default Web Reports Server defined!'
    }
  }

  $session = [PSCustomObject]@{
    PSTypeName        = 'BigFix.WebReports.Session'
    Server            = if ('DEFAULT' -eq $PSCmdlet.ParameterSetName) { $Server } elseif ('SERVER' -eq $PSCmdlet.ParameterSetName) { $Server } else { New-WebReportsServer -Uri $Uri }
    State             = 'Unknown'
    Credential        = $Credential
    Service           = $null
    SessionToken      = $null
    MaximumParseDepth = 6
  }
      
  $connect = {
    if ('Connected' -eq $this.State) {
      Write-Verbose -Message "Already connected to Web Reports Server: $($this.Server)"
      return $true
    }

    if ($null -eq $this.Credential -or [System.Management.Automation.PSCredential]::Empty -eq $this.Credential) {
      Write-Verbose -Message 'Prompting for account credentials.'
      $credential = Get-Credential -Message "Please enter credentials for Web Reports Server '$($this.Server)'"

      if ($null -eq $credential) {
        Write-Verbose -Message 'Account credentials were not provided!'
          
        $this.State = 'Error'
          
        return $false
      }

      $this.Credential = $credential
      $this.State = 'Unknown'
    }

    if ($null -eq $this.Service) {
      Write-Verbose -Message "Obtaining Web Reports API service descriptor '$($this.Server.Wsdl)'."
      try {
        $this.Service = New-WebServiceProxy -Uri $this.Server.Wsdl

        if ($null -eq $this.Service) {
          Write-Verbose -Message "Unable to obtain and/or instantiate the Web Reports API service descriptor '$($this.Server.Wsdl)'!"
                  
          $this.State = 'Error'
          
          return $false
        }
      }
      catch { 
        Write-Verbose -Message "Unable to obtain and/or instantiate the Web Reports API service descriptor '$($this.Server.Wsdl)'!"
        Write-Verbose -Message $PSItem
          
        $this.State = 'Error'
          
        return $false
      }
    }

    Write-Verbose -Message "Connecting to Web Reports Server: $($this.Server)"
    try {
      $this.State = 'Connecting'
          
      $version = $this.Evaluate('maximum of versions of modules')

      if ($version.Error) {
        Write-Verbose -Message "Connection to Web Reports Server '$($this.Server)' failed!"
        Write-Verbose -Message $version.Error

        $this.State = 'Error'

        return $false
      }
      Write-Verbose -Message "Connected to Web Reports Server: $($this.Server) (Version $($version.Results))"

      $this.State = 'Connected'
    }
    catch [System.Management.Automation.MethodInvocationException] {
      Write-Verbose -Message "Failed to connect to Web Reports Server: $($this.Server)"
      Write-Verbose -Message $PSItem.Exception.InnerException
          
      $this.State = 'Error'
          
      return $false
    }
    catch {
      Write-Verbose -Message "Failed to connect to Web Reports Server: $($this.Server)"

      $this.State = 'Error'
          
      return $false
    }

    return $true
  }

  $disconnect = {
    if ('Connected' -eq $this.State) {
      $this.State = 'Disconnected'
          
      Write-Verbose -Message "Disconnected from Web Reports Server: $($this.Server)"
      return $true
    }

    Write-Verbose -Message 'No established connection to a Web Reports Server was found!'
    return $false
  }

  $evaluate = {
    param(
      [Parameter(
        Mandatory = $true, 
        Position = 0, 
        HelpMessage = 'Session Relevance statement to evaluate'
      )]
      [ValidateNotNullOrEmpty()]
      [string]$Relevance, 

      [Parameter(
        Mandatory = $false,
        Position = 1,
        HelpMessage = 'Array of strings representing the names for each resultant tuple field'
      )]
      [string[]]$FieldNames = $null
    )

    Invoke-EvaluateSessionRelevance -Relevance $Relevance -Session $this -FieldNames $FieldNames
  }

  $session = $session | Add-Member -MemberType ScriptMethod -Name Connect -Value $connect -Force -PassThru
  $session = $session | Add-Member -MemberType ScriptMethod -Name Disconnect -Value $disconnect -Force -PassThru
  $session = $session | Add-Member -MemberType ScriptMethod -Name Evaluate -Value $evaluate -Force -PassThru
  
  $null = $session.Connect()

  if ('Error' -eq $session.State) {
    throw 'Unable to create a new WebReportsSession.'
  }
  
  $null = Set-Variable -Name WebReportsSession -Value $session -Scope Script -Force
  
  return $session
}