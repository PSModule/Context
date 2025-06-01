#Requires -Modules @{ ModuleName = 'Sodium'; RequiredVersion = '2.1.2' }

function New-ContextVault {
    <#
        .SYNOPSIS
        Creates a new context vault.

        .DESCRIPTION
        Creates a new named context vault for storing encrypted contexts.
        Each vault has its own encryption key and storage directory.
        If this is the first vault created, it becomes the default vault.

        .EXAMPLE
        New-ContextVault -Name 'Work'

        Creates a new vault named 'Work' in the default location.

        .OUTPUTS
        PSCustomObject

        .NOTES
        The first vault created automatically becomes the default vault.
        Each vault has its own unique encryption keys for security isolation.

        .LINK
        https://psmodule.io/Context/Functions/New-ContextVault/
    #>
    [OutputType([PSCustomObject])]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The name of the vault to create.
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [Parameter()]
        [string] $Path = $script:Config.VaultsFolderPath
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"
    }

    process {
        $vault = Get-ContextVault -Name $Name
        if ($vault) {
            Write-Error "Vault with name '$Name' already exists at path '$($vault.Path)'. Use a different name or remove the existing vault."
            return $null
        }

        $vaultPath = Join-Path -Path $Path -ChildPath $Name
        Write-Verbose "Creating vault directory: [$vaultPath]"
        $null = New-Item -Path $vaultPath -ItemType Directory -Force

        # Create a shard file for the vault
        $keys = New-SodiumKeyPair
        $fileShard = "$($keys.PrivateKey)$($keys.PublicKey)"
        $config = [pscustomobject]@{
            Name        = $Name
            Path        = $vaultPath
            Shard       = $fileShard
            CreatedAt   = (Get-Date)
            UpdatedAt   = (Get-Date)
        }
        $configPath = Join-Path -Path $vaultPath -ChildPath 'config.json'
        Write-Verbose "Saving vault config to: [$configPath]"
        $config | ConvertTo-Json -Depth 5 | Set-Content -Path $configPath -Force
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
