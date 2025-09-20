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
            Write-Verbose "Processing vault: $vaultName"

            $vaultPath = Join-Path -Path $script:Config.RootPath -ChildPath $vaultName
            if (-not (Test-Path $vaultPath)) {
                Write-Verbose "Creating new vault [$vaultName]"
                if ($PSCmdlet.ShouldProcess("context vault folder $vaultName", 'Set')) {
                    $null = New-Item -Path $vaultPath -ItemType Directory -Force
                    
                    # Create module and user subdirectories for new vault structure
                    $moduleDir = Join-Path -Path $vaultPath -ChildPath 'module'
                    $userDir = Join-Path -Path $vaultPath -ChildPath 'user'
                    $null = New-Item -Path $moduleDir -ItemType Directory -Force
                    $null = New-Item -Path $userDir -ItemType Directory -Force
                    
                    Write-Verbose "Created vault directories: module/ and user/"
                }
            } else {
                # Check if this is a legacy vault and migrate it
                $moduleDir = Join-Path -Path $vaultPath -ChildPath 'module'
                $userDir = Join-Path -Path $vaultPath -ChildPath 'user'
                
                if (-not (Test-Path $moduleDir) -or -not (Test-Path $userDir)) {
                    Write-Verbose "Migrating legacy vault [$vaultName] to new structure"
                    if ($PSCmdlet.ShouldProcess("vault $vaultName", 'Migrate to new directory structure')) {
                        # Create new directories if they don't exist
                        if (-not (Test-Path $moduleDir)) {
                            $null = New-Item -Path $moduleDir -ItemType Directory -Force
                        }
                        if (-not (Test-Path $userDir)) {
                            $null = New-Item -Path $userDir -ItemType Directory -Force
                        }
                        
                        # Move existing context files to user directory
                        $contextFiles = Get-ChildItem -Path $vaultPath -Filter '*.json' -File
                        foreach ($file in $contextFiles) {
                            $newPath = Join-Path -Path $userDir -ChildPath $file.Name
                            Move-Item -Path $file.FullName -Destination $newPath
                            Write-Verbose "Migrated context file: $($file.Name) -> user/$($file.Name)"
                        }
                    }
                }
            }
            
            $fileShardPath = Join-Path -Path $vaultPath -ChildPath $script:Config.ShardFileName
            if (-not (Test-Path $fileShardPath)) {
                Write-Verbose "Generating encryption keys for vault [$vaultName]"
                if ($PSCmdlet.ShouldProcess("shard file $fileShardPath", 'Set')) {
                    Set-Content -Path $fileShardPath -Value ([System.Guid]::NewGuid().ToString())
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
