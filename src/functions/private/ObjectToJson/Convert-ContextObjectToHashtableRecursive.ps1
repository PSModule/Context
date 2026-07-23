function Convert-ContextObjectToHashtableRecursive {
    <#
        .SYNOPSIS
        Converts a context object to a hashtable.

        .DESCRIPTION
        This function converts a context object to a hashtable.
        Secure strings are converted to a string representation, prefixed with '[SECURESTRING]'.
        Datetime objects are converted to a string representation using the 'o' format specifier.
        Nested context objects are recursively converted to hashtables.

        .EXAMPLE
        Convert-ContextObjectToHashtableRecursive -Object ([PSCustomObject]@{
            Name = 'MySecret'
            AccessToken = '123123123' | ConvertTo-SecureString -AsPlainText -Force
            Nested = @{
                Name = 'MyNestedSecret'
                NestedAccessToken = '123123123' | ConvertTo-SecureString -AsPlainText -Force
            }
        })

        Output:
        ```powershell
        Name         : MySecret
        AccessToken  : [SECURESTRING]123123123
        Nested       : @{Name=MyNestedSecret; NestedAccessToken=[SECURESTRING]123123123}
        ```

        Converts the context object to a hashtable. Secure strings are converted to a string representation.

        .OUTPUTS
        hashtable

        .NOTES
        Returns a hashtable representation of the input object.
        Secure strings are converted to prefixed string values.

        .LINK
        https://psmodule.io/Context/Functions/Convert-ContextObjectToHashtableRecursive
    #>
    [OutputType([string], [ValueType], [hashtable], [object[]])]
    [CmdletBinding()]
    param (
        # The object to convert.
        [Parameter()]
        [object] $Object = @{}
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"
    }

    process {
        try {
            if ($null -eq $Object) {
                return $null
            }

            if ($Object -is [datetime]) {
                return $Object.ToString('o')
            }

            if ($Object -is [System.Security.SecureString]) {
                $plainTextValue = [System.Net.NetworkCredential]::new('', $Object).Password
                return "[SECURESTRING]$plainTextValue"
            }

            if ($Object -is [string] -or $Object -is [ValueType]) {
                return $Object
            }

            if ($Object -is [System.Collections.IDictionary]) {
                $dictionaryResult = @{}
                foreach ($entry in $Object.GetEnumerator()) {
                    $dictionaryResult[[string]$entry.Key] = Convert-ContextObjectToHashtableRecursive $entry.Value
                }
                return $dictionaryResult
            }

            if ($Object -is [System.Collections.IEnumerable]) {
                $requiresDeepConversion = $false
                foreach ($item in $Object) {
                    if ($null -eq $item) {
                        continue
                    }

                    if (
                        $item -is [System.Security.SecureString] -or
                        $item -is [datetime] -or
                        $item -is [System.Collections.IDictionary] -or
                        ($item -is [System.Collections.IEnumerable] -and $item -isnot [string]) -or
                        ($item -isnot [string] -and $item -isnot [ValueType])
                    ) {
                        $requiresDeepConversion = $true
                        break
                    }
                }

                if (-not $requiresDeepConversion) {
                    return @($Object)
                }

                $listResult = [System.Collections.Generic.List[object]]::new()
                foreach ($item in $Object) {
                    $null = $listResult.Add((Convert-ContextObjectToHashtableRecursive $item))
                }
                return $listResult.ToArray()
            }

            $result = @{}
            foreach ($property in $Object.PSObject.Properties) {
                $result[$property.Name] = Convert-ContextObjectToHashtableRecursive $property.Value
            }

            return $result
        } catch {
            Write-Error $_
            throw 'Failed to convert context object to hashtable'
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
