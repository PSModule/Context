function Reset-ContextVault {
    <#
        .SYNOPSIS
        Resets a context vault.

        .DESCRIPTION
        Resets an existing context vault by deleting all contexts and regenerating
        the encryption keys. The vault configuration and name are preserved.

        .EXAMPLE
        Reset-ContextVault -Name 'MyModule'

        Resets the 'MyModule' vault, deleting all contexts and regenerating encryption keys.

        .OUTPUTS
        [PSCustomObject]

        .LINK
        https://psmodule.io/Context/Functions/Vault/Reset-ContextVault/
    #>
    [OutputType([PSCustomObject])]
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        # The name of the vault to reset.
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [string] $Name,

        # Skip confirmation prompts.
        [Parameter()]
        [switch] $Force
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"
    }

    process {
        $vault = Get-ContextVaultInfo -Name $Name

        if (-not $vault) {
            Write-Error "Vault '$Name' does not exist."
            return
        }
        if ($PSCmdlet.ShouldProcess("ContextVault: [$Name]", 'Reset')) {
            Write-Verbose "Resetting ContextVault [$Name] at path [$($vault.VaultPath)]"
            Remove-ContextVault -Name $Name
            Set-ContextVault -Name $Name
            Write-Verbose "ContextVault [$Name] reset successfully."
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
