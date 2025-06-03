#Requires -Modules @{ ModuleName = 'Sodium'; RequiredVersion = '2.2.0' }

function Set-Context {
    <#
        .SYNOPSIS
        Set a context and store it in the context vault.

        .DESCRIPTION
        If the context does not exist, it will be created. If it already exists, it will be updated.
        The context is securely stored on disk using encryption mechanisms.
        Each context operation reads the current state from disk to ensure consistency across processes.

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
        if ($context -is [System.Collections.IDictionary]) {
            $Context = [PSCustomObject]$Context
        }

        if (-not $ID) {
            $ID = $Context.ID
        }
        if (-not $ID) {
            throw 'An ID is required, either as a parameter or as a property of the context object.'
        }
        $existingContextFile = $null
        # Check if context already exists by scanning disk files
        $contextFiles = Get-ChildItem -Path $script:Config.VaultPath -Filter *.json -File -Recurse
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
            Write-Verbose "Context [$ID] not found in vault"
            $Guid = [Guid]::NewGuid().ToString()
            $Path = Join-Path -Path $script:Config.VaultPath -ChildPath "$Guid.json"
        } else {
            Write-Verbose "Context [$ID] found in vault"
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
        }

        if ($PassThru) {
            Get-Context -ID $ID
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
