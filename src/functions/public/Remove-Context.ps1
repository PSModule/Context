#Requires -Modules @{ ModuleName = 'DynamicParams'; RequiredVersion = '1.1.8' }
#Requires -Modules @{ ModuleName = 'Microsoft.PowerShell.SecretManagement'; RequiredVersion = '1.1.2' }

function Remove-Context {
    <#
        .SYNOPSIS
        Removes a context from the context vault.

        .DESCRIPTION
        This function removes a context from the vault. It supports removing a single context by name,
        multiple contexts using wildcard patterns, and can also accept input from the pipeline.
        If the specified context(s) exist, they will be removed from the vault.

        .EXAMPLE
        Remove-Context

        Removes all contexts from the vault.

        .EXAMPLE
        Remove-Context -ID 'MySecret'

        Removes the context called 'MySecret' from the vault.
    #>
    [OutputType([void])]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The name of the context to remove from the vault.
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [string] $ID
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"
        if (-not $script:Config.Initialized) {
            Set-ContextVault
            Import-Context
        }
    }

    process {
        try {
            if ($PSCmdlet.ShouldProcess($ID, 'Remove secret')) {
                $script:Contexts.GetEnumerator() | Where-Object { $_.Value.ID -eq $ID } | ForEach-Object {
                    Remove-Secret -Name $_.Key -Vault $script:Config.VaultName -Verbose:$false
                    $script:Contexts.Remove($_.Key)
                    Write-Debug "Removed context [$ID]"
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
