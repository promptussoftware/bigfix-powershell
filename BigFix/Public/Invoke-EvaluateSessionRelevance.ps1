function Invoke-EvaluateSessionRelevance {
    <#
   .Synopsis
    Evaluates Session Relevance statements.

   .Description
    Evaluates Session Relevance statements on the established Web Reports Session,
    parsing results into a more PowerShell-friendly format. Relevance Statements can
    be provided via the -Relevance parameter or the pipeline. Results are returned
    only after all Relevance Statements have completed.

   .Parameter Relevance
    Specifies the Session Relevance statement to evaluate on the Web Reports Session.

   .Parameter Session
    Specifies the Web Reports Session to evaluate the relevance on. If not provided,
    will attempt to use the last Web Reports Session created via New-WebReportsSession.

   .Parameter FieldNames
    Specifies a listing of field names to translate the evaluation tuple results into.

   .Example
    # Evaluate the Session Relevance statement 'number of bes computers'.
    Invoke-EvaluateSessionRelevance -Relevance 'number of bes computers'

   .Example
    # Evaluate the Session Relevance statement '(id of it, (if (exists name of it) then (name of it)
    # else ("<not reported>")) of it) of bes computers', parsing results into objects with the field
    # names 'Id' and 'Name'.
    Invoke-EvaluateSessionRelevance -Relevance '(id of it, (if (exists name of it) then (name of it) else ("<not reported>")) of it) of bes computers' -FieldNames @('Id', 'Name')

  #>
  [CmdLetBinding()]
  [OutputType('BigFix.SessionRelevanceResult')]
  Param(
    [Parameter(
      Mandatory = $true,
      Position = 0,
      ValueFromPipeline = $true,
      HelpMessage = 'Session Relevance statement to evaluate'
    )]
    [ValidateNotNullOrEmpty()]
    [string]$Relevance,

    [Parameter(
      Mandatory = $false,
      HelpMessage = 'Web Reports Session to perform the evaluation in'
    )]
    [ValidateNotNull()]
    [PSTypeName('BigFix.WebReports.Session')]$Session = (Get-WebReportsSession),

    [Parameter(
      Mandatory = $false,
      HelpMessage = 'Array of strings representing the names for each resultant tuple field'
    )]
    [string[]]$FieldNames = $null
  )

  Begin {
    if ($null -eq $Session) {
      throw "Cannot validate argument on parameter 'Session'. The argument is null. Call New-WebReportsSession first or provide a valid value for the argument, and then try running the command again."
    }

    if ($Session.State -ne 'Connected' -and $Session.State -ne 'Connecting') {
      $Session.Connect()
    }

    if ($Session.State -eq 'Connecting' -or $null -eq $Session.SessionToken) {
      $header = New-Object "$($Session.Service.GetType().Namespace).LoginHeader"
      $header.username = $Session.Credential.UserName
      $header.password = $Session.Credential.GetNetworkCredential().Password
    }
    else {
      $header = New-Object "$($Session.Service.GetType().Namespace).AuthenticateHeader"
      $header.username = $Session.Credential.UserName
      $header.sessionToken = $Session.SessionToken
    }

    $Session.Service.RequestHeaderElement = $header
  }

  Process {
    $result = [PSCustomObject]@{
      PSTypeName     = 'BigFix.SessionRelevanceResult'
      Relevance      = $Relevance
      Results        = $null
      Error          = $null
      Time           = $null
      EvaluationTime = $null
    }

    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    try {
      Write-Verbose -Message "Evaluating Relevance: $Relevance"

      $structuredResult = $Session.Service.GetStructuredRelevanceResult($Relevance)

      $result.EvaluationTime = $structuredResult.evaltime

      if ($structuredResult.error) {
        $result.Error = $structuredResult.error
      }
      else {
        $result.Results = Expand-StructuredRelevanceResult -InputObject $structuredResult -FieldNames $FieldNames
      }
    }
    catch {
      $result.Error = $PSItem.ToString()
      $Session.State = 'Error'
    }
    finally {
      $null = $timer.Stop()
      $result.Time = $timer.Elapsed

      if ($result.Error) {
        Write-Verbose -Message "Evaluation failed: $($result.Error)"
      }
      else {
        $Session.SessionToken = $Session.Service.ResponseHeaderElement.sessionToken
        Write-Verbose -Message "Evaluation produced $($result.Results.Count.ToString('N0')) answer(s) in $($result.Time)."
      }
    }

    return $result
  }
}