function Convert-ContextHashtableToObjectRecursive {
    <#
        .SYNOPSIS
        Converts a hashtable into a structured context object.

        .DESCRIPTION
        This function recursively converts a hashtable into a structured PowerShell object.
        String values prefixed with '[SECURESTRING]' are converted back to SecureString objects.
        Other values retain their original data types, including integers, booleans, strings, arrays,
        and nested objects.

        .EXAMPLE
        Convert-ContextHashtableToObjectRecursive -Hashtable @{
            Name   = 'Test'
            Token  = '[SECURESTRING]TestToken'
            Nested = @{
                Name  = 'Nested'
                Token = '[SECURESTRING]NestedToken'
            }
        }

        Output:
        ```powershell
        Name   : Test
        Token  : System.Security.SecureString
        Nested : @{ Name = Nested; Token = System.Security.SecureString }
        ```

        This example converts a hashtable into a structured object, where 'Token' and 'Nested.Token'
        values are SecureString objects.

        .OUTPUTS
        PSCustomObject

        .NOTES
        Returns an object where values are converted to their respective types,
        including SecureString for sensitive values, arrays for list structures, and nested objects
        for hashtables.

        .LINK
        https://psmodule.io/Context/Functions/Convert-ContextHashtableToObjectRecursive
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSAvoidUsingConvertToSecureStringWithPlainText', '',
        Justification = 'The SecureString is extracted from the object being processed by this function.'
    )]
    [OutputType([pscustomobject])]
    [CmdletBinding()]
    param (
        # Hashtable to convert into a structured context object
        [Parameter(Mandatory)]
        [System.Collections.IDictionary] $Hashtable
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"
    }

    process {
        try {
            $result = [ordered]@{}

            foreach ($key in $Hashtable.Keys) {
                $value = $Hashtable[$key]

                if ($null -eq $value) {
                    $result[$key] = $null
                    continue
                }

                if ($value -is [string] -and $value.StartsWith('[SECURESTRING]', [System.StringComparison]::Ordinal)) {
                    $secureValue = $value.Substring(14)
                    $result[$key] = ConvertTo-SecureString -String $secureValue -AsPlainText -Force
                    continue
                }

                if ($value -is [System.Collections.IDictionary]) {
                    $result[$key] = Convert-ContextHashtableToObjectRecursive $value
                    continue
                }

                if ($value -is [System.Collections.IEnumerable] -and $value -isnot [string]) {
                    $requiresDeepConversion = $false
                    foreach ($item in $value) {
                        if (
                            $item -is [System.Collections.IDictionary] -or
                            ($item -is [string] -and $item.StartsWith('[SECURESTRING]', [System.StringComparison]::Ordinal))
                        ) {
                            $requiresDeepConversion = $true
                            break
                        }
                    }

                    if (-not $requiresDeepConversion) {
                        $result[$key] = @($value)
                        continue
                    }

                    $arrayResult = [System.Collections.Generic.List[object]]::new()
                    foreach ($item in $value) {
                        if ($item -is [System.Collections.IDictionary]) {
                            $null = $arrayResult.Add((Convert-ContextHashtableToObjectRecursive $item))
                        } elseif ($item -is [string] -and $item.StartsWith('[SECURESTRING]', [System.StringComparison]::Ordinal)) {
                            $null = $arrayResult.Add((ConvertTo-SecureString -String $item.Substring(14) -AsPlainText -Force))
                        } else {
                            $null = $arrayResult.Add($item)
                        }
                    }
                    $result[$key] = $arrayResult.ToArray()
                } else {
                    $result[$key] = $value
                }
            }

            return [pscustomobject]$result
        } catch {
            Write-Error $_
            throw 'Failed to convert hashtable to object'
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
