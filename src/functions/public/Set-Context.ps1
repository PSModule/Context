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

        # The name of the vault to store the context in.
        [Parameter(Mandatory)]
        [string] $Vault,

        # Pass the context through the pipeline.
        [Parameter()]
        [switch] $PassThru
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Begin"
        Assert-ContextSodiumModule
    }

    process {
        $vaultObject = Set-ContextVault -Name $Vault -PassThru
        if ($VerbosePreference -eq 'Continue') {
            $vaultObject | Format-List | Out-String -Stream | ForEach-Object { Write-Verbose "[$stackPath]   $_" }
        }

        if ($context -is [System.Collections.IDictionary]) {
            $Context = [PSCustomObject]$Context
        }

        if (-not $ID) {
            $ID = $Context.ID
        }
        if (-not $ID) {
            throw 'An ID is required, either as a parameter or as a property of the context object.'
        }

        $contextPath = $null
        $contextIndex = Get-ContextFileIndex -Vault $vaultObject.Name -VaultPath $vaultObject.Path
        $existingContextPath = $null
        if ($contextIndex.TryGetValue($ID, [ref]$existingContextPath)) {
            if (Test-Path -LiteralPath $existingContextPath -PathType Leaf) {
                Write-Verbose "[$stackPath] - Context [$ID] found in [$Vault]"
                $contextPath = $existingContextPath
            } else {
                Remove-ContextFileIndexEntry -Vault $vaultObject.Name -ID $ID
            }
        }

        if ($null -eq $contextPath) {
            Write-Verbose "[$stackPath] - Creating context [$ID] in [$Vault]"
            $contextPath = [System.IO.Path]::Combine($vaultObject.Path, "$([Guid]::NewGuid().Guid).json")
        }
        Write-Verbose "[$stackPath] - Context path: [$contextPath]"

        $contextJson = ConvertTo-ContextJson -Context $Context -ID $ID
        $keys = Get-ContextVaultKeyPair -Vault $Vault
        $content = [pscustomobject]@{
            ID      = $ID
            Path    = $contextPath
            Vault   = $Vault
            Context = ConvertTo-SodiumSealedBox -Message $contextJson -PublicKey $keys.PublicKey
        } | ConvertTo-Json -Depth 5 -Compress
        if ($VerbosePreference -eq 'Continue') {
            Write-Verbose 'Content:'
            $content | Out-String -Stream | ForEach-Object { Write-Verbose "[$stackPath]   $_" }
        }

        if ($PSCmdlet.ShouldProcess("file: [$contextPath]", 'Set content')) {
            Write-Verbose "[$stackPath] - Setting context [$ID] in vault [$Vault]"
            [System.IO.File]::WriteAllText($contextPath, $content, [System.Text.UTF8Encoding]::new($false))
            Set-ContextFileIndexEntry -Vault $vaultObject.Name -ID $ID -Path $contextPath
        }

        if ($PassThru) {
            Get-Context -ID $ID -Vault $Vault
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
