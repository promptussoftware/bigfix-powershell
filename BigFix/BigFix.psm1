#Requires -Version 3.0

# Get the public and private function definitions
$Public = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -Exclude *.tests.ps1, *profile.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -Exclude *.tests.ps1, *profile.ps1 -ErrorAction SilentlyContinue )

# Dot source the function definition files
Foreach ($file in @($Public + $Private)) {
  Try { 
    . $file.FullName 
  }
  Catch {
    Write-Error -Message "Failed to import function definition(s) from '$($file.FullName)': $_"
  }
}
