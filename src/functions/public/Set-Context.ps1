#Requires -Modules @{ ModuleName = 'Sodium'; RequiredVersion = '2.2.0' }

function Set-Context {
    <#
        .SYNOPSIS
        Set a context and store it in a context vault.

        .DESCRIPTION
        If the context does not exist, it will be created. If it already exists, it will be updated.
        The context is encrypted and stored on disk. Also if the context vault does not exist, it will be created.

        .EXAMPLE
        Set-Context -ID 'MyUser' -Context @{ Name = 'MyUser' } -Vault 'MyModule'

        Output:
        ```powershell
        ID      : MyUser
        Path    : C:\Vault\Guid.json
        Context : @{ Name = 'MyUser' }
        ```

        Creates a context called 'MyUser' in the 'MyModule' vault.

        .EXAMPLE
        $context = @{
            ID          = 'MySecret'
            Name        = 'SomeSecretIHave'
            AccessToken = '123123123'|ConvertTo-SecureString -AsPlainText -Force
        }
        $context | Set-Context

        Output:
        ```powershell
        ID      : MyUser
        Path    : C:\Vault\Guid.json
        Context : { Name = 'MyUser' }
        ```

        Sets a context using a hashtable object.

        .OUTPUTS
        [PSCustomObject]

        .NOTES
        Returns an object representing the stored or updated context.
        The object includes the ID, path, and securely stored context information.

        .LINK
        https://psmodule.io/Context/Functions/Set-Context/
    #>
    [OutputType([object])]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The ID of the context.
        [Parameter()]
        [string] $ID,

        # The data of the context.
        [Parameter(ValueFromPipeline)]
        [object] $Context = @{},

        # Pass the context through the pipeline.
        [Parameter()]
        [switch] $PassThru,

        # The name of the vault to store the context in.
        [Parameter()]
        [string] $Vault
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"
    }

    process {
        if ($context -is [System.Collections.IDictionary]) {
            $Context = [PSCustomObject]$Context
        }

        if (-not $ID) {
            $ID = $Context.ID
        }
        if (-not $ID) {
            throw 'An ID is required, either as a parameter or as a property of the context object.'
        }

        $vaultObject = Set-ContextVault -Name $Vault
        $searchPath = $vaultObject.ContextFolderName
        $basePath = $vaultObject.ContextFolderName

        $contextFiles = Get-ChildItem -Path $searchPath -Filter *.json -File -Recurse -ErrorAction SilentlyContinue
        foreach ($file in $contextFiles) {
            try {
                $contextInfo = Get-Content -Path $file.FullName | ConvertFrom-Json
                if ($contextInfo.ID -eq $ID) {
                    $existingContextFile = $file
                    $Path = $contextInfo.Path
                    break
                }
            } catch {
                Write-Warning "Failed to read context file: $($file.FullName). Error: $_"
            }
        }

        if (-not $existingContextFile) {
            Write-Verbose "Context [$ID] not found in vault$(if ($Vault) { " [$Vault]" })"
            $Guid = [Guid]::NewGuid().ToString()
            $Path = Join-Path -Path $basePath -ChildPath "$Guid.json"
        } else {
            Write-Verbose "Context [$ID] found in vault$(if ($Vault) { " [$Vault]" })"
        }

        $contextJson = ConvertTo-ContextJson -Context $Context -ID $ID

        $param = [pscustomobject]@{
            ID      = $ID
            Path    = $Path
            Context = ConvertTo-SodiumSealedBox -Message $contextJson -PublicKey $script:Config.PublicKey
        } | ConvertTo-Json -Depth 5
        Write-Debug ($param | ConvertTo-Json -Depth 5)

        if ($PSCmdlet.ShouldProcess($ID, 'Set context')) {
            Write-Verbose "Setting context [$ID] in vault$(if ($Vault) { " [$Vault]" })"
            Set-Content -Path $Path -Value $param
        }

        if ($PassThru) {
            Get-Context -ID $ID -Vault $Vault
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
