#Requires -Modules @{ ModuleName = 'Sodium'; RequiredVersion = '2.2.2' }

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

        .EXAMPLE
        Set-Context -ID 'default' -Context @{ ApiEndpoint = 'https://api.example.com' } -Vault 'MyModule' -Type 'Module'

        Creates or updates the default module context for 'MyModule' vault. This becomes the active module context.

        .EXAMPLE  
        Set-Context -ID 'staging' -Context @{ ApiEndpoint = 'https://staging.example.com' } -Vault 'MyModule' -Type 'Module'

        Creates a staging module context and sets it as the active module context for 'MyModule' vault.

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

        # The type of context to set: 'User' or 'Module'.
        [Parameter()]
        [ValidateSet('User', 'Module')]
        [string] $Type = 'User',

        # Pass the context through the pipeline.
        [Parameter()]
        [switch] $PassThru
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Begin"
    }

    process {
        $vaultObject = Set-ContextVault -Name $Vault -PassThru
        $vaultObject | Format-List | Out-String -Stream | ForEach-Object { Write-Verbose "[$stackPath]   $_" }

        if ($context -is [System.Collections.IDictionary]) {
            $Context = [PSCustomObject]$Context
        }

        if (-not $ID) {
            $ID = $Context.ID
        }
        if (-not $ID) {
            throw 'An ID is required, either as a parameter or as a property of the context object.'
        }

        $contextInfo = Get-ContextInfo -ID $ID -Vault $Vault -Type $Type
        Write-Verbose 'Context info:'
        $contextInfo | Format-List | Out-String -Stream | ForEach-Object { Write-Verbose "[$stackPath]   $_" }
        
        if (-not $contextInfo) {
            Write-Verbose "[$stackPath] - Creating context [$ID] in [$Vault] of type [$Type]"
            $guid = [Guid]::NewGuid().Guid
            $contextDir = Get-ContextDirectory -VaultPath $vaultObject.Path -Type $Type
            $contextPath = Join-Path -Path $contextDir -ChildPath "$guid.json"
        } else {
            Write-Verbose "[$stackPath] - Context [$ID] found in [$Vault]"
            $contextPath = $contextInfo.Path
        }
        Write-Verbose "[$stackPath] - Context path: [$contextPath]"

        # For Module contexts, handle default context creation and active context logic
        if ($Type -eq 'Module') {
            # Ensure 'default' context exists for module type
            if ($ID -eq 'default' -or -not (Get-ContextInfo -ID 'default' -Vault $Vault -Type 'Module')) {
                Write-Verbose "[$stackPath] - Ensuring default module context exists"
            }
            
            # Set this as the active context for module type (unless it's just updating the same context)
            if (-not $contextInfo -or (Get-ActiveModuleContext -VaultPath $vaultObject.Path) -ne $ID) {
                Write-Verbose "[$stackPath] - Setting [$ID] as active module context"
                Set-ActiveModuleContext -VaultPath $vaultObject.Path -ContextName $ID
            }
        }

        $contextJson = ConvertTo-ContextJson -Context $Context -ID $ID
        $keys = Get-ContextVaultKeyPair -Vault $Vault
        $content = [pscustomobject]@{
            ID      = $ID
            Path    = $contextPath
            Vault   = $Vault
            Context = ConvertTo-SodiumSealedBox -Message $contextJson -PublicKey $keys.PublicKey
        } | ConvertTo-Json -Depth 5
        Write-Verbose 'Content:'
        $content | ConvertTo-Json -Depth 5 | Out-String -Stream | ForEach-Object { Write-Verbose "[$stackPath]   $_" }

        if ($PSCmdlet.ShouldProcess("file: [$contextPath]", 'Set content')) {
            Write-Verbose "[$stackPath] - Setting context [$ID] in vault [$Vault]"
            Set-Content -Path $contextPath -Value $content
        }

        if ($PassThru) {
            Get-Context -ID $ID -Vault $Vault -Type $Type
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
