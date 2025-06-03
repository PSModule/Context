function Rename-Context {
    <#
        .SYNOPSIS
        Renames a context.

        .DESCRIPTION
        This function renames a context by retrieving the existing context with the old ID,
        setting the new context with the provided new ID, and removing the old context.
        If a context with the new ID already exists, the operation will fail unless
        the `-Force` switch is specified.

        .EXAMPLE
        Rename-Context -ID 'PSModule.GitHub' -NewID 'PSModule.GitHub2'

        Output:
        ```powershell
        Context 'PSModule.GitHub' renamed to 'PSModule.GitHub2'
        ```

        Renames the context 'PSModule.GitHub' to 'PSModule.GitHub2'.

        .EXAMPLE
        'PSModule.GitHub' | Rename-Context -NewID 'PSModule.GitHub2'

        Output:
        ```powershell
        Context 'PSModule.GitHub' renamed to 'PSModule.GitHub2'
        ```

        Renames the context 'PSModule.GitHub' to 'PSModule.GitHub2' using pipeline input.

        .OUTPUTS
        [System.String]

        .NOTES
        The confirmation message indicating the successful renaming of the context.

        .LINK
        https://psmodule.io/Context/Functions/Rename-Context/
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param (
        # The ID of the context to rename.
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [string] $ID,

        # The new ID of the context.
        [Parameter(Mandatory)]
        [string] $NewID,

        # Force the rename even if the new ID already exists.
        [Parameter()]
        [switch] $Force,

        # The name of the vault containing the context.
        [Parameter()]
        [string] $Vault
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"
    }

    process {
        $context = Get-Context -ID $ID -Vault $Vault
        if (-not $context) {
            throw "Context with ID '$ID' not found$(if ($Vault) { " in vault '$Vault'" })."
        }

        $existingContext = Get-Context -ID $NewID -Vault $Vault
        if ($existingContext -and -not $Force) {
            throw "Context with ID '$NewID' already exists$(if ($Vault) { " in vault '$Vault'" })."
        }

        if ($PSCmdlet.ShouldProcess("Renaming context '$ID' to '$NewID'$(if ($Vault) { " in vault '$Vault'" })")) {
            $context | Set-Context -ID $NewID -Vault $Vault
            Remove-Context -ID $ID -Vault $Vault
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
