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

        # Example: ensure your vault/contexts are initialized once
        if (-not $script:Config.Initialized) {
            Set-ContextVault
            Import-Context
        }
    }

    process {
        try {
            foreach ($item in $ID) {
                Write-Debug "Processing ID [$item]"
                Write-Debug ($script:Contexts.GetEnumerator() | Format-List | Out-String)
                $list = $script:Contexts.GetEnumerator() | Where-Object { $_.Value.ID -like $item }
                Write-Debug "Found contexts: $($list.Count)"
                $list | ForEach-Object {
                    $name = $_.Key
                    Write-Debug "Removing context [$name]"
                    if ($PSCmdlet.ShouldProcess($item, 'Remove secret')) {
                        Get-SecretInfo -Name $name -Vault $script:Config.VaultName | Remove-Secret
                        $script:Contexts[$name] = $null
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
