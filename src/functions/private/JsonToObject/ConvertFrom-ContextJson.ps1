function ConvertFrom-ContextJson {
    <#
        .SYNOPSIS
        Converts a JSON string to a context object.

        .DESCRIPTION
        Converts a JSON string to a context object. Text prefixed with `[SECURESTRING]` is converted to SecureString objects.
        Other values are converted to their original types, such as integers, booleans, strings, arrays, and nested objects.

        .EXAMPLE
        $content = @'
        {
            "Name": "Test",
            "Token": "[SECURESTRING]TestToken",
            "Nested": {
                "Name": "Nested",
                "Token": "[SECURESTRING]NestedToken"
            }
        }
        '@
        ConvertFrom-ContextJson -JsonString $content

        Output:
        ```powershell
        Name   : Test
        Token  : System.Security.SecureString
        Nested : @{Name=Nested; Token=System.Security.SecureString}
        ```

        Converts a JSON string to a context object, ensuring 'Token' and 'Nested.Token' values are SecureString objects.

        .OUTPUTS
        [pscustomobject].

        .NOTES
        Returns a PowerShell custom object with SecureString conversion applied where necessary.

        .LINK
        https://psmodule.io/Context/Functions/ConvertFrom-ContextJson/
    #>
    [OutputType([pscustomobject])]
    [CmdletBinding()]
    param (
        # JSON string to convert to context object
        [Parameter()]
        [string] $JsonString = '{}'
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"
    }

    process {
        try {
            $hashtableObject = $JsonString | ConvertFrom-Json -Depth 100 -AsHashtable
            return Convert-ContextHashtableToObjectRecursive $hashtableObject
        } catch {
            Write-Error $_
            throw 'Failed to convert JSON to object'
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
