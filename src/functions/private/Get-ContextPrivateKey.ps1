function Get-ContextKey {
    <#
        .SYNOPSIS
        Retrieves the private key for the current context vault.

        .DESCRIPTION
        This function generates a private key based on the current machine and user context.
        It uses a seed shard to ensure that the key is unique to the environment.

        .EXAMPLE
        $privateKey = Get-ContextKey

        Retrieves the private key for the current context vault.

        .OUTPUTS
        [string]

        .NOTES
        The private key is generated using a combination of machine name, user name, and a seed shard.

        .LINK
        https://psmodule.io/Context/Functions/Get-ContextKey/
    #>
    [OutputType([string])]
    [CmdletBinding()]
    param(
        # The seed shard to use for generating the private key.
        [Parameter(Mandatory = $true)]
        [string] $SeedShard
    )
    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"
    }
    process {
        $machineShard = [System.Environment]::MachineName
        $userShard = [System.Environment]::UserName
        $seed = $machineShard + $userShard + $seedShard
        $keys = New-SodiumKeyPair -Seed $seed
        $privateKey = $keys.PrivateKey
        Write-Debug "Generated private key: [$privateKey]"
        return $privateKey
    }

    end {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - End"
    }
}
