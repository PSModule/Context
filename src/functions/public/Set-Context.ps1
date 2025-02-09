#Requires -Modules @{ ModuleName = 'Sodium'; RequiredVersion = '2.1.1' }

function Set-Context {
    <#
        .SYNOPSIS
        Set a context and store it in the context vault.

        .DESCRIPTION
        If the context does not exist, it will be created. If it already exists, it will be updated.
        The context is cached in memory for faster access.

        .EXAMPLE
        Set-Context -ID 'PSModule.GitHub' -Context @{ Name = 'MySecret' }

        Create a context called 'MySecret' in the vault.

        .EXAMPLE
        Set-Context -ID 'PSModule.GitHub' -Context @{ Name = 'MySecret'; AccessToken = '123123123' }

        Creates a context called 'MySecret' in the vault with the settings.

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
            #Do i already have a context for this ID?
            $existingContext = Get-Context -ID $ID
            if (-not $existingContext) {
                Write-Verbose "Context [$ID] not found in vault"
                $Guid = [Guid]::NewGuid().ToString()
                $fileName = "$Guid.json"
            } else {
                Write-Verbose "Context [$ID] found in vault"
                $fileName = $existingContext.FileName
            }

            try {
                $contextJson = ConvertTo-ContextJson -Context $Context -ID $ID
            } catch {
                Write-Error $_
                throw 'Failed to convert context to JSON'
            }

            $param = [pscustomobject]@{
                ID       = $ID
                FileName = $fileName
                Context  = ConvertTo-SodiumSealedBox -Message $contextJson -PublicKey $script:Config.PublicKey
            } | ConvertTo-Json -Depth 5
            Write-Debug ($param | ConvertTo-Json -Depth 5)

            if ($PSCmdlet.ShouldProcess($ID, 'Set context')) {
                $contextPath = Join-Path -Path $script:Config.VaultPath -ChildPath $fileName
                Write-Verbose "Setting context [$ID] in vault"
                Set-Content -Path $contextPath -Value $param
                $content = Get-Content -Path $contextPath
                $contextJson = $content | ConvertFrom-Json
                $params = @{
                    SealedBox  = $contextJson.Context
                    PublicKey  = $script:Config.PublicKey
                    PrivateKey = $script:Config.PrivateKey
                }
                $context = ConvertFrom-SodiumSealedBox @params
                $script:Contexts[$ID] = [PSCustomObject]@{
                    ID       = $ID
                    FileName = $fileName
                    Context  = ConvertFrom-ContextJson -JsonString $context
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
