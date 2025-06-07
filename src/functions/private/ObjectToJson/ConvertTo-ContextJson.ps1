function ConvertTo-ContextJson {
    <#
        .SYNOPSIS
        Converts an object into a JSON string.

        .DESCRIPTION
        Converts objects or hashtables into a JSON string. SecureStrings are converted to plain text strings and
        prefixed with `[SECURESTRING]`. The conversion is recursive for any nested objects. The function allows
        converting back using `ConvertFrom-ContextJson`.

        .EXAMPLE
        ConvertTo-ContextJson -Context ([pscustomobject]@{
            Name = 'MySecret'
            AccessToken = '123123123' | ConvertTo-SecureString -AsPlainText -Force
        }) -ID 'CTX-001'

        Output:
        ```json
        {
            "Name": "MySecret",
            "AccessToken": "[SECURESTRING]123123123",
            "ID": "CTX-001"
        }
        ```

        Converts the given object into a JSON string, ensuring SecureStrings are handled properly.

        .OUTPUTS
        System.String

        .NOTES
        A JSON string representation of the provided object, including secure string transformations.

        .LINK
        https://psmodule.io/Context/Functions/ConvertTo-ContextJson
    #>
    [OutputType([string])]
    [CmdletBinding()]
    param (
        # The object to convert to a Context JSON string.
        [Parameter()]
        [object] $Context = @{},

        # The ID of the context.
        [Parameter(Mandatory)]
        [string] $ID
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"
    }

    process {
        try {
            $processedObject = Convert-ContextObjectToHashtableRecursive $Context
            $processedObject['ID'] = $ID
            return ($processedObject | ConvertTo-Json -Depth 100 -Compress)
        } catch {
            Write-Error $_
            throw 'Failed to convert object to JSON'
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
