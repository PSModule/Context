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
        [string] $Vault,

        # The type of context to remove: 'User' or 'Module'.
        [Parameter()]
        [ValidateSet('User', 'Module')]
        [string] $Type = 'User'
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Begin"
    }

    process {
        $contextInfo = Get-ContextInfo -ID $ID -Vault $Vault -Type $Type
        foreach ($contextInfo in $contextInfo) {
            $contextId = $contextInfo.ID

            if ($PSCmdlet.ShouldProcess("Context '$contextId'", 'Remove')) {
                Write-Verbose "[$stackPath] - Removing context [$contextId] of type [$Type]"
                
                # Special handling for module contexts - don't allow removing 'default' if it's the only one
                if ($Type -eq 'Module' -and $contextId -eq 'default') {
                    $allModuleContexts = Get-ContextInfo -ID '*' -Vault $Vault -Type 'Module'
                    if ($allModuleContexts.Count -le 1) {
                        Write-Warning "Cannot remove the default module context when it's the only module context."
                        continue
                    }
                }
                
                $contextInfo.Path | Remove-Item -Force -ErrorAction Stop
                Write-Verbose "[$stackPath] - Removed item: $contextId"
                
                # If we removed the active module context, reset to 'default'
                if ($Type -eq 'Module') {
                    $vaultObject = Get-ContextVault -Name $Vault
                    $activeContext = Get-ActiveModuleContext -VaultPath $vaultObject.Path
                    if ($activeContext -eq $contextId -and $contextId -ne 'default') {
                        Write-Verbose "[$stackPath] - Resetting active module context to 'default'"
                        Set-ActiveModuleContext -VaultPath $vaultObject.Path -ContextName 'default'
                    }
                }
            }
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
