function Invoke-EvaluateClientRelevance {
  <#  
   .Synopsis
    Evaluates Client Relevance statements.
  
   .Description
    Evaluates Client Relevance statements in the established Qna Session,
    parsing results into a more PowerShell-friendly format. Relevance Statements can
    be provided via the -Relevance parameter or the pipeline. Results are returned
    sequentially to the pipeline as they are evaluated in the Qna Session.
   
   .Parameter Relevance
    Specifies the Client Relevance statement(s) to evaluate in the Qna Session.

   .Parameter Session
    Specifies the Qna Session to evaluate the relevance in. If not provided,
    will attempt to use the last Qna Session created via New-QnaSession, creating
    a new Qna Session in the event none exists.
     
   .Inputs
    One or more strings representing complete valid Client Relevance expressions to
    evaluate.

   .Outputs
    A BigFix.Qna.Result object for each Client Relevance expression evaluated.

   .Example
    # Evaluate the Client Relevance statement 'computer name'.
    Invoke-EvaluateClientRelevance -Relevance 'computer name'

   .Example 
    # Evaluate the Client Relevance statements 'now' and 'version of client' using 
    # the pipeline for input.
    'now','version of client' | Invoke-EvaluateClientRelevance
  
   .Example
    # Evaluate the Client Relevance statement 'computer name' using a specific Qna Session.
    Invoke-EvaluateClientRelevance -Relevance 'computer name' -Session $QnaSession
      
    #>
  [CmdletBinding()]
  [OutputType('BigFix.Qna.Result')]
  param (
    [Parameter(
      Position = 0,
      Mandatory = $true,
      ValueFromPipeline = $true,
      ValueFromPipelineByPropertyName = $true,
      HelpMessage = 'Client Relevance statement to evaluate'
    )]
    [string[]]$Relevance,

    [Parameter(
      Mandatory = $false,
      ValueFromPipelineByPropertyName = $true,
      HelpMessage = 'Qna Session to perform the evaluation within'
    )]
    [BigFix.Qna.Session]$Session = $null
  )
  
  begin {
    if ($null -eq $Session) {
      Write-Debug -Message 'Obtaining the current Qna Session via Get-QnaSession'
      $Session = Get-QnaSession
    }

    if ($null -eq $Session) {
      Write-Debug -Message 'Creating a new Qna Session via New-QnaSession'
      $Session = New-QnaSession
    }

    Write-Verbose -Message "Using Qna $($Session.ExecutablePath) (Version: $($Session.Version))"
  }
  
  process {
    foreach ($question in $Relevance) {
      Write-Verbose -Message "Evaluating Client Relevance: $($question)"
      $Session.Query($question)
    }
  }
}