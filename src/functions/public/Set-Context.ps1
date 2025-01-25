#Requires -Modules @{ ModuleName = 'Microsoft.PowerShell.SecretManagement'; RequiredVersion = '1.1.2' }

function Set-Context {
    <#
        .SYNOPSIS
        Set a context and store it in the context vault.

        .DESCRIPTION
        If the context does not exist, it will be created. If it already exists, it will be updated.

        .EXAMPLE
        Set-Context -ID 'PSModule.GitHub' -Context @{ Name = 'MySecret' }

        Create a context called 'MySecret' in the vault.

        .EXAMPLE
        Set-Context -ID 'PSModule.GitHub' -Context @{ Name = 'MySecret'; AccessToken = '123123123' }

        Creates a context called 'MySecret' in the vault with the settings.
    #>
    [OutputType([object])]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The ID of the context.
        [Parameter(Mandatory)]
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
            Import-Context
        }
    }

    process {
        try {
            $secret = ConvertTo-ContextJson -Context $Context -ID $ID
        } catch {
            Write-Error $_
            throw 'Failed to convert context to JSON'
        }

        $Name = "$($script:Config.SecretPrefix)$ID"
        $param = @{
            Name    = $Name
            Secret  = $secret
            Vault   = $script:Config.VaultName
            Verbose = $false
        }
        Write-Debug ($param | ConvertTo-Json -Depth 5)

        try {
            if ($PSCmdlet.ShouldProcess($Name, 'Set Secret')) {
                Set-Secret @param
                $data = ConvertFrom-ContextJson -JsonString $secret
                $script:Contexts[$Name] = $data
            }
        } catch {
            Write-Error $_
            throw 'Failed to set secret'
        }

        if ($PassThru) {
            $data
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
