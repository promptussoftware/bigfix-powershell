# Get the library type definitions
$Libs = @(Get-ChildItem -Path $PSScriptRoot\Lib\*.cs -ErrorAction SilentlyContinue)

# Add the library type definitions
foreach ($file in @($Libs)) {
  try {
    Add-Type -TypeDefinition (Get-Content $file.FullName -Encoding UTF8 -Raw)
  }
  catch {
    throw "Failed to load library type definition(s) from '$($file.FullName)': $_"
  }
}