function Expand-StructuredRelevanceResult {
  <#  
   .Synopsis
    Expand a Structured Relevance Result.
  
   .Description
    This module internal function is used to expand the Structured Relevance Result objects
    returned as a result of calling the Web Reports SOAP API's GetStructuredRelevanceResult
    method into a more PowerShell friendly object.
   
   .Parameter InputObject
    The Structured Relevance Result object to expand.
   
   .Parameter FieldNames
    Array of strings representing the names for each resultant tuple field. 

   .Parameter Prefix
    Prefix to use for auto-generated resultant tuple field names (Default: Field_).

   .Inputs
    Any object that follows the GetStructuredRelevanceResult method schema.

   .Outputs
    A dynamically-created System.Management.Automation.PSCustomObject object representing
    the results of a GetStructuredRelevanceResult method call with all resultant tuple fields
    expanded fully.

   .Notes
    This function is currently considered for internal module use only and not exported out
    for direct use by external entities. As users of this module will not be working directly
    with the resultant SOAP API XML, there was no need to make this function public. This will
    allow greater flexibility in future optimizations of the processing code paths as no
    backwards compatibility has to be provided for.

   .Example
    # Expand a Structured Relevance Result object using auto-generated resultant tuple field names
    # prefixed with the default 'Field_' (e.g. 'Field_0', 'Field_1', ...).
    Expand-StructuredRelevanceResult -InputObject $StructuredResult

   .Example
    # Expand a Structured Relevance Result object using the tuple field names 'Id', 'Name', and 'Value'.
    Expand-StructuredRelevanceResult -InputObject $StructuredResult -FieldNames Id, Name, Value

   .Example
    # Expand a Structured Relevance Result object using auto-generated resultant tuple field names 
    # prefixed with 'F_' (e.g. 'F_0', 'F_1', ...).
    Expand-StructuredRelevanceResult -InputObject $StructuredResult

    #>
  [CmdletBinding()]
  param(
    [Parameter(
      Mandatory = $true,
      Position = 0,
      ValueFromPipeline = $true,
      HelpMessage = 'The Structured Relevance Result object to expand.'
    )]
    [object]$InputObject, 

    [Parameter(
      Mandatory = $false,
      ValueFromPipelineByPropertyName = $true,
      HelpMessage = 'Array of strings representing the names for each resultant tuple field.'
    )]
    [string[]]$FieldNames = $null,

    [Parameter(
      Mandatory = $false,
      HelpMessage = 'Prefix to use for auto-generated resultant tuple field names (Default: Field_).'
    )]
    [string]$Prefix = 'Field_'
  )
  
  $ExtractValue = [ScriptBlock] {
    param($Item)
    if ($Item.Items) {
      & $ExtractValue $Item.Items
    }
    else {
      $Item
    }
  }

  foreach ($Item in $InputObject) {
    if ($Item.results) {
      $Hash = [ordered]@{}
      foreach ($Result in $Item.results.Items) {
        if ($Result.Items) {
          $ExpandedItems = & $ExtractValue $Result.Items
        }
        else {
          $ExpandedItems = $Result
        }

        if ($null -eq $FieldNames) {
          @(, $ExpandedItems)
        }
        else {
          $FieldsCount = $FieldNames.Count
          if ($FieldsCount -lt $ExpandedItems.Count) {
            $FieldNames += (0 .. ($ExpandedItems.Count - $FieldsCount)) | ForEach-Object { "$($Prefix)$($FieldCount + $_)" }
          }

          $Index = 0
          foreach ($ExpandedItem in $ExpandedItems) {
            $Hash[$FieldNames[$Index++]] = $ExpandedItem
          }
          [PSCustomObject]$Hash
        }
      }
    }
    elseif ($Item.Items) {
      Expand-StructuredRelevanceResult -InputObject @{ InputObject = $Item }
    }
  }
}