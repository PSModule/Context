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
            ValueFromPipelineByPropertyName
        )]
        [string[]] $ID
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
        foreach ($item in $ID) {
            try {
                if ($PSCmdlet.ShouldProcess($item, 'Remove secret')) {
                    $script:Contexts.Values | Where-Object { $_.ID -eq $item } | ForEach-Object {
                        Write-Debug "Removing context [$item]"
                        $name = $_.Key
                        Remove-Secret -Name $name -Vault $script:Config.VaultName -Verbose:$false
                        $script:Contexts.Remove($name)
                    }
                }
            } catch {
                Write-Error $_
                throw 'Failed to remove context'
            }
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
