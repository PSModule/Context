#Requires -Modules @{ ModuleName = 'Microsoft.PowerShell.SecretManagement'; RequiredVersion = '1.1.2' }

function Remove-Context {
    <#
        .SYNOPSIS
        Removes a context from the context vault.

        .DESCRIPTION
        This function removes a context (or multiple contexts) from the vault. It supports:
        - Supply one or more IDs as strings (e.g. -ID 'Ctx1','Ctx2')
        - Supply objects that contain an ID property

        .EXAMPLE
        Remove-Context -ID 'MySecret'

        Removes a context called 'MySecret' by specifying its ID

        .EXAMPLE
        Remove-Context -ID 'Ctx1','Ctx2'

        Removes two contexts, 'Ctx1' and 'Ctx2'

        .EXAMPLE
        'Ctx1','Ctx2' | Remove-Context

        Removes two contexts, 'Ctx1' and 'Ctx2'

        .EXAMPLE
        $ctxList = @(
            [PSCustomObject]@{ ID = 'Ctx1' },
            [PSCustomObject]@{ ID = 'Ctx2' }
        )
        $ctxList | Remove-Context

        Accepts pipeline input: multiple objects each having an ID property

        .LINK
        https://psmodule.io/Context/Functions/Remove-Context/
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # One or more IDs as string of the contexts to remove.
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [string[]] $ID
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Begin"

        if (-not $script:Config.Initialized) {
            Set-ContextVault
        }
    }

    process {
        try {
            foreach ($item in $ID) {
                Write-Debug "Processing ID [$item]"
                $script:Contexts.Values.ID | Where-Object { $_ -like $item } | ForEach-Object {
                    $name = "$($script:Config.SecretPrefix)$_"
                    Write-Debug "Removing context [$name]"
                    if ($PSCmdlet.ShouldProcess($name, 'Remove secret')) {
                        Get-SecretInfo -Name $name -Vault $script:Config.VaultName | Remove-Secret
                        $null = $script:Contexts.Remove($name)
                    }
                }
            }
        } catch {
            Write-Error $_
            throw 'Failed to remove context'
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
