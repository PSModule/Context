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
        Remove-Context -ID 'MySecret' -Vault "MyModule"

        Output:
        ```powershell
        Removing context [MySecret]
        Removed item: MySecret
        ```

        Removes a context called 'MySecret' from the "MyModule" vault by specifying its ID.

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
        [string] $Vault
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Begin"
    }

    process {
        foreach ($item in $ID) {
            Write-Verbose "Processing ID [$item] in vault$(if ($Vault) { " [$Vault]" })"
            
            # Determine the search path
            if ($Vault) {
                $searchPath = Join-Path -Path $script:Config.ContextVaultsPath -ChildPath "Vaults" | Join-Path -ChildPath $Vault | Join-Path -ChildPath $script:Config.ContextPath
            } else {
                $searchPath = $script:Config.VaultPath
            }

            if (-not (Test-Path $searchPath)) {
                Write-Verbose "Search path does not exist: $searchPath"
                continue
            }

            # Find contexts by scanning disk files instead of using in-memory cache
            $contextFiles = Get-ChildItem -Path $searchPath -Filter *.json -File -Recurse
            foreach ($file in $contextFiles) {
                try {
                    $contextInfo = Get-Content -Path $file.FullName | ConvertFrom-Json
                    if ($contextInfo.ID -like $item) {
                        Write-Verbose "Removing context [$($contextInfo.ID)]"
                        if ($PSCmdlet.ShouldProcess($contextInfo.ID, 'Remove secret')) {
                            $file.FullName | Remove-Item -Force
                            Write-Verbose "Removed context file: $($file.FullName)"
                        }
                    }
                } catch {
                    Write-Warning "Failed to read context file: $($file.FullName). Error: $_"
                }
            }
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
