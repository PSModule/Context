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
        PSCustomObject.

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
        [hashtable] $Hashtable
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"
    }

    process {
        try {
            $result = [pscustomobject]@{}

            foreach ($key in $Hashtable.Keys) {
                $value = $Hashtable[$key]
                Write-Debug "Processing [$key]"
                Write-Debug "Value: $value"
                Write-Debug "Type:  $($value.GetType().Name)"
                if ($value -is [string] -and $value -like '`[SECURESTRING`]*') {
                    Write-Debug "Converting [$key] as [SecureString]"
                    $secureValue = $value -replace '^\[SECURESTRING\]', ''
                    $result | Add-Member -NotePropertyName $key -NotePropertyValue ($secureValue | ConvertTo-SecureString -AsPlainText -Force)
                } elseif ($value -is [hashtable]) {
                    Write-Debug "Converting [$key] as [hashtable]"
                    $result | Add-Member -NotePropertyName $key -NotePropertyValue (Convert-ContextHashtableToObjectRecursive $value)
                } elseif ($value -is [array]) {
                    Write-Debug "Converting [$key] as [array], processing elements individually"
                    $result | Add-Member -NotePropertyName $key -NotePropertyValue @(
                        $value | ForEach-Object {
                            if ($_ -is [hashtable]) {
                                Convert-ContextHashtableToObjectRecursive $_
                            } else {
                                $_
                            }
                        }
                    )
                } else {
                    Write-Debug "Adding [$key] as a standard value"
                    $result | Add-Member -NotePropertyName $key -NotePropertyValue $value
                }
            }
            return $result
        } catch {
            Write-Error $_
            throw 'Failed to convert hashtable to object'
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
