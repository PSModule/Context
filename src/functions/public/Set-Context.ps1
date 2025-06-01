#Requires -Modules @{ ModuleName = 'Sodium'; RequiredVersion = '2.1.2' }

function Set-Context {
    <#
        .SYNOPSIS
        Set a context and store it in the context vault.

        .DESCRIPTION
        If the context does not exist, it will be created. If it already exists, it will be updated.
        The context is cached in memory for faster access. This function ensures that the context
        is securely stored using encryption mechanisms.

        .EXAMPLE
        Set-Context -ID 'PSModule.GitHub' -Context @{ Name = 'MySecret' }

        Output:
        ```powershell
        ID      : PSModule.GitHub
        Path    : C:\Vault\Guid.json
        Context : @{ Name = 'MySecret' }
        ```

        Creates a context called 'MySecret' in the vault.

        .EXAMPLE
        Set-Context -ID 'PSModule.GitHub' -Context @{ Name = 'MySecret' } -VaultName "WorkVault"

        Output:
        ```powershell
        ID      : PSModule.GitHub
        Path    : C:\Vault\WorkVault\Guid.json
        Context : @{ Name = 'MySecret' }
        ```

        Creates a context called 'MySecret' in the specified "WorkVault".

        .EXAMPLE
        Set-Context -ID 'PSModule.GitHub' -Context @{ Name = 'MySecret'; AccessToken = '123123123' }

        Output:
        ```powershell
        ID      : PSModule.GitHub
        Path    : C:\Vault\Guid.json
        Context : @{ Name = 'MySecret'; AccessToken = '123123123' }
        ```

        Creates a context called 'MySecret' in the vault with additional settings.

        .EXAMPLE
        $context = @{ ID = 'MySecret'; Name = 'SomeSecretIHave'; AccessToken = '123123123' }
        $context | Set-Context

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

        # The name of the vault to store the context in.
        [Parameter()]
        [string] $VaultName,

        # Pass the context through the pipeline.
        [Parameter()]
        [switch] $PassThru
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"

        if (-not $script:Config.Initialized) {
            if ($VaultName) {
                Set-ContextVault -VaultName $VaultName
            } else {
                Set-ContextVault
            }
        } elseif ($VaultName -and $VaultName -ne $script:Config.CurrentVault) {
            # Switch to specified vault
            Set-ContextVault -VaultName $VaultName
        }
    }

    process {
        if ($context -is [System.Collections.IDictionary]) {
            $Context = [PSCustomObject]$Context
        }

        if (-not $ID) {
            $ID = $Context.ID
        }
        if (-not $ID) {
            throw "An ID is required, either as a parameter or as a property of the context object."
        }
        $existingContextInfo = $script:Contexts[$ID]
        if (-not $existingContextInfo) {
            Write-Verbose "Context [$ID] not found in vault"
            $Guid = [Guid]::NewGuid().ToString()
            $Path = Join-Path -Path $script:Config.VaultPath -ChildPath "$Guid.json"
        } else {
            Write-Verbose "Context [$ID] found in vault"
            $Path = $existingContextInfo.Path
        }

        $contextJson = ConvertTo-ContextJson -Context $Context -ID $ID

        $param = [pscustomobject]@{
            ID      = $ID
            Path    = $Path
            Context = ConvertTo-SodiumSealedBox -Message $contextJson -PublicKey $script:Config.PublicKey
        } | ConvertTo-Json -Depth 5
        Write-Debug ($param | ConvertTo-Json -Depth 5)

        if ($PSCmdlet.ShouldProcess($ID, 'Set context')) {
            Write-Verbose "Setting context [$ID] in vault"
            Set-Content -Path $Path -Value $param
            $content = Get-Content -Path $Path
            $contextInfoObj = $content | ConvertFrom-Json
            $params = @{
                SealedBox  = $contextInfoObj.Context
                PublicKey  = $script:Config.PublicKey
                PrivateKey = $script:Config.PrivateKey
            }
            $contextObj = ConvertFrom-SodiumSealedBox @params
            Write-Verbose ($contextObj | Format-List | Out-String)
            $script:Contexts[$ID] = [PSCustomObject]@{
                ID      = $ID
                Path    = $Path
                Context = ConvertFrom-ContextJson -JsonString $contextObj
            }
        }

        if ($PassThru) {
            Get-Context -ID $ID
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
