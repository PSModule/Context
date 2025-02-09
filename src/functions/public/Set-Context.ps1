#Requires -Modules @{ ModuleName = 'Sodium'; RequiredVersion = '2.1.1' }

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
        Set-Context -ID 'PSModule.GitHub' -Context @{ Name = 'MySecret'; AccessToken = '123123123' }

        Output:
        ```powershell
        ID      : PSModule.GitHub
        Path    : C:\Vault\Guid.json
        Context : @{ Name = 'MySecret'; AccessToken = '123123123' }
        ```

        Creates a context called 'MySecret' in the vault with additional settings.

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
        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $ID,

        # The data of the context.
        [Parameter(ValueFromPipeline)]
        [object] $Context = @{},

        # Pass the context through the pipeline.
        [Parameter()]
        [switch] $PassThru
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"

        if (-not $script:Config.Initialized) {
            Set-ContextVault
        }
    }

    process {
        try {
            $existingContextInfo = $script:Contexts[$ID]
            if (-not $existingContextInfo) {
                Write-Verbose "Context [$ID] not found in vault"
                $Guid = [Guid]::NewGuid().ToString()
                $Path = Join-Path -Path $script:Config.VaultPath -ChildPath "$Guid.json"
            } else {
                Write-Verbose "Context [$ID] found in vault"
                $Path = $existingContextInfo.Path
            }

            try {
                $contextJson = ConvertTo-ContextJson -Context $Context -ID $ID
            } catch {
                Write-Error $_
                throw 'Failed to convert context to JSON'
            }

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

        } catch {
            Write-Error $_
            throw 'Failed to set secret'
        }

        if ($PassThru) {
            Get-Context -ID $ID
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
