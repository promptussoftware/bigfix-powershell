function ParseStructuredResult {
    param(
        [object]$Result, 
        [string[]]$FieldNames = $null,
        [int]$MaximumParseDepth = 6
    )
    $items = ParseInnerStructuredResult -Result $Result -MaximumParseDepth $MaximumParseDepth
        
    if ($items.Count -gt 0) {
        if ($FieldNames) {
            $hash = [System.Collections.Specialized.OrderedDictionary] @{}
            for ($field = 0; $field -lt $items.Count; $field++) {
                $fieldName = "Field$($field + 1)"
                    
                if ($FieldNames.Count -gt $field) {
                    $fieldName = $FieldNames[$field]
                }
                    
                $hash[$fieldName] = $items[$field]                
            }
            
            return [PSCustomObject] $hash
        }

        return $items
    }

    return $null
}

function ParseInnerStructuredResult {
    param(
        [object]$Result,
        [int]$MaximumParseDepth = 6, 
        [int]$Depth = 0,
        [object[]]$Fields = $null
    ) 
     
    if ($null -eq $Fields) {
        $Fields = @()
    } 
        
    $resultFieldCount = $Result.ItemsElementName.Count

    if ($resultFieldCount -eq 0) {
        $Fields += $Result
    } else {
        for ($field = 0; $field -lt $resultFieldCount; $field++) {
            switch ($Result.ItemsElementName[$field].ToString()) {
                'Boolean' {
                    $Fields += [boolean]$Result.Items[$field]
                    break;
                }
                'DateTime' {
                    $Fields += [datetime]$Result.Items[$field]
                    break;
                }
                'FloatingPoint' {
                    $Fields += [double]$Result.Items[$field]
                    break;
                }
                'Integer' {
                    $Fields += [int]$Result.Items[$field]
                    break;
                }
                'Tuple' { 
                    if ($Depth -lt $MaximumParseDepth) {
                        $null = ParseInnerStructuredResult -Result $Result.Items[$field] -MaximumParseDepth $MaximumParseDepth -Depth ($Depth + 1) -Fields $Fields
                    } else {
                        Write-Error -Category LimitsExceeded -Message "Nested tuple expansion exceeded the maximum depth of $($MaximumParseDepth)!"
                    }
                    break
                }
                default { 
                    $Fields += ($Result.Items[$field])
                    break 
                }
            }
        }
    }
                
    if ($Depth -eq 0) {
        return $Fields
    }

    return $null
}