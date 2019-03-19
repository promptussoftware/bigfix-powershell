function Test-Uri {
    [CmdletBinding()]
    [OutputType([boolean])]
    [OutputType([string], [System.Uri], ParameterSetName = 'PASSTHRU')]
    param(
        [Parameter(
            Mandatory = $true, 
            Position = 0, 
            ValueFromPipeline = $true,
            HelpMessage = 'URI to validate'
        )]
        [string]$Uri,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Kind of URI that is expected'
        )]
        [ValidateSet('Absolute', 'Relative', 'RelativeOrAbsolute')]
        [string]$Kind = 'Absolute',

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Scheme(s) that must be used'
        )]
        [ValidateNotNullOrEmpty()]
        [string[]]$Scheme = $null,

        [Parameter(
            Mandatory = $false
        )]
        [Switch]$PassThru = $false,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Transform output into a System.Uri object'
        )]
        [ValidateNotNullOrEmpty()]
        [Switch]$Transform = $false,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Throw instead of just returning $false'
        )]
        [Switch]$Throw = $false        
    )

    Begin {
        [System.UriKind]$UriKind = switch($Kind) {
            'Absolute' { [System.UriKind]::Absolute; break; }
            'Relative' { [System.UriKind]::Relative; break; }
            'RelativeOrAbsolute' { [System.UriKind]::RelativeOrAbsolute; break; }
            default { [System.UriKind]::Absolute; break; }
        }

        Write-Verbose -Message "Test-Uri will be validating using UriKind '$($UriKind)'"
    }

    Process {
        Write-Debug -Message "Testing '$($Uri)' is a well-formed URI of kind $($UriKind)"
        if ([System.Uri]::IsWellFormedUriString($Uri, $UriKind) -eq $false) {
            $Message = "Uri '$($Uri)' is NOT well-formed"
            
            if ($Throw) {
                throw $Message
            } 
            
            Write-Verbose -Message $Message            
            if (!$PassThru) {
              $false
            }
            return
        }

        Write-Debug -Message "Testing '$($Uri)' is instantiatable"
        [System.Uri]$ParsedUri = $null
        if ([System.Uri]::TryCreate($Uri, $UriKind, [ref] $ParsedUri) -eq $false) {
            $Message = "Uri '$($Uri)' is NOT instantiatable"
            
            if ($Throw) {
                throw $Message
            } 
            
            Write-Verbose -Message $Message
            if (!$PassThru) {
              $false
            }
            return
        }

        if ($null -ne $Scheme) {
            Write-Debug -Message "Testing '$($Uri)' is using an acceptable scheme"

            [boolean]$Matched = $false
            Foreach($Match in @($Scheme)) {
                if ($Match -eq $ParsedUri.Scheme) {
                    Write-Debug -Message "Uri '$($Uri)' is using the scheme '$($Match)'"
                    
                    $Matched = $true
                    break
                } else {
                  Write-Debug -Message "Uri '$($Uri)' is NOT using the scheme '$($Match)'"
                }
            }

            if ($Matched -eq $false) {
                $Message = "Uri '$($Uri)' is NOT using an acceptable scheme"
                
                if ($Throw) {
                    throw $Message
                }
            
                Write-Verbose -Message $Message
                if (!$PassThru) {
                  $false
                }
                return
            }
        }
        
        if ($PassThru) { 
          if ($Transform) { 
            $ParsedUri 
          } else { 
            $Uri 
          } 
        } else { 
          $true 
        }
        return
    }
}