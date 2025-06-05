function Get-ContextVaultInfo {
    <#
        .SYNOPSIS
        Retrieves information about a context vault.

        .DESCRIPTION
        This function retrieves the path and context information for a specified context vault.

        .OUTPUTS
        [PSCustomObject] containing vault information.

        .EXAMPLE
        Get-ContextVaultInfo -Name "MyModule"

        Retrieves information about the "MyModule" context vault.
    #>
    [OutputType([PSCustomObject])]
    [CmdletBinding()]
    param(
        # The name of the vault to retrieve information for.
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Name
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"
    }

    process {
        $path = Join-Path -Path $script:Config.VaultsPath -ChildPath $Name
        [pscustomobject]@{
            Name                = $Name
            VaultPath           = $path
            ContextFolderPath   = Join-Path -Path $path -ChildPath $script:Config.ContextFolderName
            ShardFilePath       = Join-Path -Path $path -ChildPath $script:Config.SeedShardFileName
            VaultConfigFilePath = Join-Path -Path $path -ChildPath $script:Config.VaultConfigFileName
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
