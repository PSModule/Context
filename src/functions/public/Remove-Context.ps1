function Remove-Context {
    <#
        .SYNOPSIS
        Removes a context from the context vault.

        .DESCRIPTION
        This function removes a context (or multiple contexts) from the vault. It supports:
        - Supply one or more IDs as strings (e.g. -ID 'Ctx1','Ctx2')
        - Supply objects that contain an ID property

        The function accepts pipeline input for easier batch removal.

        .EXAMPLE
        Remove-Context -ID 'MySecret'

        Output:
        ```powershell
        Removing context [MySecret]
        Removed item: MySecret
        ```

        Removes a context called 'MySecret' by specifying its ID.

        .EXAMPLE
        Remove-Context -ID 'MySecret' -VaultName "WorkVault"

        Output:
        ```powershell
        Removing context [MySecret]
        Removed item: MySecret
        ```

        Removes a context called 'MySecret' from the specified "WorkVault".

        .EXAMPLE
        Remove-Context -ID 'Ctx1','Ctx2'

        Output:
        ```powershell
        Removing context [Ctx1]
        Removed item: Ctx1
        Removing context [Ctx2]
        Removed item: Ctx2
        ```

        Removes two contexts, 'Ctx1' and 'Ctx2'.

        .EXAMPLE
        'Ctx1','Ctx2' | Remove-Context

        Output:
        ```powershell
        Removing context [Ctx1]
        Removed item: Ctx1
        Removing context [Ctx2]
        Removed item: Ctx2
        ```

        Removes two contexts, 'Ctx1' and 'Ctx2' via pipeline input.

        .EXAMPLE
        $ctxList = @(
            [PSCustomObject]@{ ID = 'Ctx1' },
            [PSCustomObject]@{ ID = 'Ctx2' }
        )
        $ctxList | Remove-Context

        Output:
        ```powershell
        Removing context [Ctx1]
        Removed item: Ctx1
        Removing context [Ctx2]
        Removed item: Ctx2
        ```

        Accepts pipeline input: multiple objects each having an ID property.

        .OUTPUTS
        [System.String]

        .NOTES
        Returns the name of each removed context if successful.

        .LINK
        https://psmodule.io/Context/Functions/Remove-Context/
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        # One or more IDs as strings of the contexts to remove.
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [SupportsWildcards()]
        [string[]] $ID,

        # The name of the vault to remove contexts from.
        [Parameter()]
        [string] $VaultName
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Begin"

        if (-not $script:Config.Initialized) {
            if ($VaultName) {
                Set-ContextVault -VaultName $VaultName
            } else {
                Set-ContextVault
            }
        } elseif ($VaultName -and $VaultName -ne $script:Config.CurrentVault) {
            # Switch to specified vault
            Set-ContextVault -VaultName $VaultName
        }
    }

    process {
        foreach ($item in $ID) {
            Write-Verbose "Processing ID [$item]"
            $script:Contexts.Keys | Where-Object { $_ -like $item } | ForEach-Object {
                Write-Verbose "Removing context [$_]"
                if ($PSCmdlet.ShouldProcess($_, 'Remove secret')) {
                    $script:Contexts[$_].Path | Remove-Item -Force

                    Write-Verbose "Attempting to remove context: $_"
                    [PSCustomObject]$removedItem = $null
                    if ($script:Contexts.TryRemove($_, [ref]$removedItem)) {
                        Write-Verbose "Removed item: $removedItem"
                    } else {
                        Write-Verbose 'Key not found'
                    }
                }
            }
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
