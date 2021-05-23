function Get-WebReportsSession {
  <#  
   .Synopsis
    Gets the current Web Reports Session.
  
   .Description
    Gets the current Web Reports Session created during the last call to New-WebReportsSession.
   
   .Example
    # Get the current Web Reports Session.
    Get-WebReportsSession

  #>
  [CmdletBinding()]
  [OutputType('BigFix.WebReports.Session')]
  param()

  $Session = Get-Variable -Name WebReportsSession -ValueOnly -Scope Script -ErrorAction SilentlyContinue

  if ($null -eq $Session) {
    throw 'No previously created Web Reports Session was found. Use New-WebReportsSession to create a new instance.'
  }

  return $Session
}