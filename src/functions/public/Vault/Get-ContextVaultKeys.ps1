function Get-ContextVaultKeys {
    <#
        .SYNOPSIS
        Retrieves the public and private keys from the context vault.

        .DESCRIPTION
        Retrieves the public and private keys used for encrypting contexts in the context vault.
        The keys are stored in a secure manner and can be used to encrypt or decrypt contexts.

        .EXAMPLE
        Get-ContextVaultKeys

        Output:
        ```powershell
        PublicKey  : <public key>
        PrivateKey : <private key>
        ```

        Retrieves the public and private keys from the context vault.
    #>
    [OutputType([object])]
    [CmdletBinding()]
    param(
        # The name of the vault to retrieve the keys from.
        [Parameter(Mandatory)]
        [string] $Vault
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"
        $vaultObject = Set-ContextVault -Name $Vault
    }

    process {
        $seedShard = Get-Content -Path $vaultObject.ShardFilePath
        $machineShard = [System.Environment]::MachineName
        $userShard = [System.Environment]::UserName
        #$userInputShard = Read-Host -Prompt 'Enter a seed shard' # Eventually 4 shards. +1 for user input.
        $seed = $machineShard + $userShard + $seedShard # + $userInputShard
        $keys = New-SodiumKeyPair -Seed $seed
        $keys
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
