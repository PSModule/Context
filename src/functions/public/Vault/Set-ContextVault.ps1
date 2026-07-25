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
        [ContextVault]

        .LINK
        https://psmodule.io/Context/Functions/Vault/Set-ContextVault/
    #>
    [OutputType([ContextVault])]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The name of the vault to create or update.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]] $Name,

        # Pass the context through the pipeline.
        [Parameter()]
        [switch] $PassThru
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Begin"
    }

    process {
        foreach ($vaultName in $Name) {
            if ([string]::IsNullOrWhiteSpace($vaultName)) {
                throw 'Vault name cannot be null, empty, or whitespace.'
            }
            if (
                [System.IO.Path]::IsPathRooted($vaultName) -or
                [System.Management.Automation.WildcardPattern]::ContainsWildcardCharacters($vaultName) -or
                $vaultName.Contains('/') -or
                $vaultName.Contains('\') -or
                $vaultName -eq '.' -or
                $vaultName -eq '..' -or
                $vaultName.IndexOfAny([System.IO.Path]::GetInvalidFileNameChars()) -ge 0
            ) {
                throw "Vault name '$vaultName' is invalid. Use a simple folder name without path separators or wildcard characters."
            }

            Write-Verbose "Processing vault: $vaultName"

            $vaultPath = Join-Path -Path $script:Config.RootPath -ChildPath $vaultName
            if (-not (Test-Path $vaultPath)) {
                Write-Verbose "Creating new vault [$vaultName]"
                if ($PSCmdlet.ShouldProcess("context vault folder $vaultName", 'Set')) {
                    $null = New-Item -Path $vaultPath -ItemType Directory -Force
                }
            }
            $fileShardPath = Join-Path -Path $vaultPath -ChildPath $script:Config.ShardFileName
            if (-not (Test-Path $fileShardPath)) {
                Write-Verbose "Generating encryption keys for vault [$vaultName]"
                if ($PSCmdlet.ShouldProcess("shard file $fileShardPath", 'Set')) {
                    [System.IO.File]::WriteAllText($fileShardPath, [System.Guid]::NewGuid().ToString(), [System.Text.UTF8Encoding]::new($false))
                }
            }

            if ($PassThru) {
                [ContextVault]::new($vaultName, $vaultPath)
            }
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
