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
    [OutputType([hashtable])]
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
            $result = @{}

            if ($Object -is [hashtable]) {
                Write-Debug 'Converting [hashtable] to [PSCustomObject]'
                $Object = [PSCustomObject]$Object
            } elseif ($Object -is [string] -or $Object -is [int] -or $Object -is [bool]) {
                Write-Debug 'returning as string'
                return $Object
            }

            foreach ($property in $Object.PSObject.Properties) {
                $name = $property.Name
                $value = $property.Value
                Write-Debug "Processing [$name]"
                Write-Debug "Value: $value"
                Write-Debug "Type:  $($value.GetType().Name)"
                if ($value -is [datetime]) {
                    Write-Debug '- as DateTime'
                    $result[$property.Name] = $value.ToString('o')
                } elseif ($value -is [string] -or $Object -is [int] -or $Object -is [bool]) {
                    Write-Debug '- as string, int, bool'
                    $result[$property.Name] = $value
                } elseif ($value -is [System.Security.SecureString]) {
                    Write-Debug '- as SecureString'
                    $value = $value | ConvertFrom-SecureString -AsPlainText
                    $result[$property.Name] = "[SECURESTRING]$value"
                } elseif ($value -is [psobject] -or $value -is [PSCustomObject] -or $value -is [hashtable]) {
                    Write-Debug '- as PSObject, PSCustomObject or hashtable'
                    $result[$property.Name] = Convert-ContextObjectToHashtableRecursive $value
                } elseif ($value -is [System.Collections.IEnumerable]) {
                    Write-Debug '- as IEnumerable, including arrays and hashtables'
                    $result[$property.Name] = @(
                        $value | ForEach-Object {
                            Convert-ContextObjectToHashtableRecursive $_
                        }
                    )
                } else {
                    Write-Debug '- as regular value'
                    $result[$property.Name] = $value
                }
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
