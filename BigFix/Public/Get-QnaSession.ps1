function Get-QnaSession {
  <#  
   .Synopsis
    Gets the previously instantiated Qna Session object.
  
   .Description
    The Get-QnaSession function is used to obtain the Qna Session object last instantiated  
    by a call to New-QnaSession in the current scope. If called with the -Throw switch, the
    call will throw a fault in the event that no previously instantiated Qna Session object
    is found.
   
   .Parameter Throw
    Switch specifying that the call should throw a fault in the event that no previously 
    instantiated Qna Session object is found.
   
   .Inputs
    None. This function does not accept pipeline input.

   .Outputs
    The last BigFix.Qna.Session object instantiated via a call to New-QnaSession, or nothing
    if no instantiated object exists.

   .Example
    # Gets the last instantiated Qna Session object.
    Get-QnaSession

   .Example
    # Gets the last instantiated Qna Session object or throw a fault.
    Get-QnaSession -Throw

    #>
  [CmdletBinding()]
  [OutputType('BigFix.Qna.Session')]
  param (
    [Parameter(
      Mandatory = $false,
      HelpMessage = 'Throw an error if no previously created Qna Session was found.'
    )]
    [Switch]$Throw = $false
  )
    
  $Session = Get-Variable -Name QnaSession -ValueOnly -Scope Script -ErrorAction SilentlyContinue

  if ($null -ne $Session) {
    return $Session
  }

  if ($true -eq $Throw) {
    throw 'No previously created Qna Session was found! Please call New-QnaSession first to create a new session instance.'
  }

  return
}