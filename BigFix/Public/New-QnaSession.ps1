function New-QnaSession {
  <#  
   .Synopsis
    Instantiate a new Qna Session object.
  
   .Description
    Creates a new Qna Session object and expose it into the current scope. By default, it
    will attempt to link to the qna.exe utility application binary using the following 
    search path order: 
      1. Directory defined within the environmental variable 'QnA'.
      2. Current working directory.
      3. Directory where the BigFix Client is registered 
      4. Every directory defined within the environmental variable 'PATH', in the order it 
         is defined.
      
    If called with the -ExecutablePath parameter and provided with the full path of the 
    qna.exe utility, the session will attempt to link to that binary.
   
   .Parameter ExecutablePath
    Path to the BigFix Qna utility executable (i.e. qna.exe)
   
   .Inputs
    None. This function does not accept pipeline input.

   .Outputs
    An instantiated BigFix.Qna.Session object.

   .Example
    # Create a new Qna Session using the qna.exe utility application installed as part
    # of the BigFix Client installation.
    New-QnaSession

   .Example
    # Create a new Qna Session using the qna.exe utility application at the provided path.
    New-QnaSession -ExecutablePath 'C:\Tools\BigFix\qna.exe'

    #>
  [CmdletBinding()]
  [OutputType('BigFix.Qna.Session')]
  param (
    [Parameter(
      Mandatory = $false,
      HelpMessage = 'Path to the BigFix Qna utility executable (i.e. qna.exe)'
    )]
    [string]$ExecutablePath = $null
  )
  
  try {
    $Session = $null

    if ([String]::IsNullOrWhiteSpace($ExecutablePath)) {
      $Session = Get-Variable -Name QnaSession -ValueOnly -Scope Script -ErrorAction SilentlyContinue
    }

    if ($null -eq $Session) {
      $Session = New-Object -Type BigFix.Qna.Session -ArgumentList $ExecutablePath
      $null = Set-Variable -Name QnaSession -Value $Session -Scope Script -Force -ErrorAction SilentlyContinue
    }

    $Session
  } catch {
    throw "Unable to establish a Qna Session! Please check that the BigFix Qna utility executable (i.e. qna.exe) is in the BigFix Client directory, in the system path, or present at the provided path. $_"
  }
}