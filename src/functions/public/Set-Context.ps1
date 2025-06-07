#Requires -Modules @{ ModuleName = 'Sodium'; RequiredVersion = '2.2.0' }

function Set-Context {
    <#
        .SYNOPSIS
        Set a context in a context vault.

        .DESCRIPTION
        If the context does not exist, it will be created. If it already exists, it will be updated.
        The context is encrypted and stored on disk. If the context vault does not exist, it will be created.

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
            AccessToken = '123123123' | ConvertTo-SecureString -AsPlainText -Force
        }
        $context | Set-Context

        Output:
        ```powershell
        ID      : MyUser
        Path    : C:\Vault\Guid.json
        Context : {
            ID          = MySecret
            Name        = MyUser
            AccessToken = System.Security.SecureString
        }
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
    [Alias('New-Context', 'Update-Context')]
    [OutputType([PSCustomObject])]
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
        $vaultObject = Set-ContextVault -Name $Vault
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

        $contextInfo = Get-ContextInfo -ID $ID -Vault $Vault
        if (-not $contextInfo) {
            Write-Verbose "Context [$ID] not found in vault"
            $guid = [Guid]::NewGuid().Guid
            $contextPath = Join-Path -Path $vaultObject.ContextFolderPath -ChildPath "$guid.json"
        } else {
            Write-Verbose "Context [$ID] found in vault"
            $contextPath = $contextInfo.Path
        }

        $contextJson = ConvertTo-ContextJson -Context $Context -ID $ID
        $keys = Get-ContextVaultKeys -Vault $Vault

        $content = [pscustomobject]@{
            ID      = $ID
            Path    = $contextPath
            Vault   = $Vault
            Context = ConvertTo-SodiumSealedBox -Message $contextJson -PublicKey $keys.PublicKey
        } | ConvertTo-Json -Depth 5
        Write-Debug ($content | ConvertTo-Json -Depth 5)

        if ($PSCmdlet.ShouldProcess("file: [$contextPath]", 'Set content')) {
            Write-Verbose "Setting context [$ID] in vault [$Vault]"
            Set-Content -Path $contextPath -Value $content
        }

        Get-Context -ID $ID -Vault $Vault
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
