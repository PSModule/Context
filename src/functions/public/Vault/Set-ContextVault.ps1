function Set-ContextVault {
    <#
        .SYNOPSIS
        Creates or updates a context vault configuration.

        .DESCRIPTION
        Declaratively creates or updates a context vault configuration. If the vault exists,
        its configuration is updated with the provided parameters. If the vault does not exist,
        it is created with the specified configuration.

        .EXAMPLE
        Set-ContextVault -Name 'MyModule'

        Creates a new vault named 'MyModule' or updates its description if it already exists.

        .OUTPUTS
        [PSCustomObject]

        .LINK
        https://psmodule.io/Context/Functions/Vault/Set-ContextVault/
    #>
    [OutputType([PSCustomObject])]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The name of the vault to create or update.
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Name
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"
    }

    process {
        $vault = Get-ContextVaultInfo -Name $Name

        if ($PSCmdlet.ShouldProcess($Name, 'Set context vault configuration')) {
            if (-not (Test-Path $vault.VaultPath)) {
                Write-Verbose "Creating new vault [$Name]"
                $null = New-Item -Path $vault.VaultPath -ItemType Directory -Force
            }
            # Ensure context directory exists
            if (-not (Test-Path $vault.ContextFolderPath)) {
                $null = New-Item -Path $vault.ContextFolderPath -ItemType Directory -Force
            }

            if (-not (Test-Path $vault.ShardFilePath)) {
                Write-Verbose "Generating encryption keys for vault [$Name]"
                $seedShardContent = [System.Guid]::NewGuid().ToString()
                Set-Content -Path $vault.ShardFilePath -Value $seedShardContent
            }

            [PSCustomObject]@{
                Name = $Name
                Path = $vault.VaultPath
            }
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
