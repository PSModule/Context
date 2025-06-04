function Move-Context {
    <#
        .SYNOPSIS
        Moves a context from one vault to another.

        .DESCRIPTION
        Moves a context by ID from a source vault to a target vault. The context is
        decrypted from the source vault and re-encrypted for the target vault.

        .EXAMPLE
        Move-Context -ID "ApiKey" -SourceVault "OldModule" -TargetVault "NewModule"

        Moves the "ApiKey" context from the "OldModule" vault to the "NewModule" vault.

        .OUTPUTS
        [PSCustomObject]

        .NOTES
        The context is decrypted from the source vault and re-encrypted for the target vault.

        .LINK
        https://psmodule.io/Context/Functions/Move-Context/
    #>
    [OutputType([PSCustomObject])]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The ID of the context to move.
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [string] $ID,

        # The name of the source vault.
        [Parameter(Mandatory)]
        [string] $SourceVault,

        # The name of the target vault.
        [Parameter(Mandatory)]
        [string] $TargetVault
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"
    }

    process {
        try {
            if ($SourceVault -eq $TargetVault) {
                throw "Source and target vaults cannot be the same: $SourceVault"
            }

            # Verify both vaults exist
            $sourceVaultInfo = Get-ContextVault -Name $SourceVault
            if (-not $sourceVaultInfo) {
                throw "Source vault '$SourceVault' does not exist"
            }

            $targetVaultInfo = Get-ContextVault -Name $TargetVault
            if (-not $targetVaultInfo) {
                throw "Target vault '$TargetVault' does not exist"
            }

            if ($PSCmdlet.ShouldProcess("$ID from $SourceVault to $TargetVault", 'Move context')) {
                Write-Verbose "Moving context [$ID] from vault [$SourceVault] to vault [$TargetVault]"

                # Get the context from the source vault
                $context = Get-Context -ID $ID -Vault $SourceVault
                if (-not $context) {
                    throw "Context '$ID' not found in source vault '$SourceVault'"
                }

                # Check if context already exists in target vault
                $existingInTarget = Get-Context -ID $ID -Vault $TargetVault -ErrorAction SilentlyContinue
                if ($existingInTarget) {
                    throw "Context '$ID' already exists in target vault '$TargetVault'"
                }

                # Set the context in the target vault
                $newContext = Set-Context -ID $ID -Context $context -Vault $TargetVault -PassThru

                # Remove the context from the source vault
                Remove-Context -ID $ID -Vault $SourceVault

                Write-Verbose "Context [$ID] moved successfully from [$SourceVault] to [$TargetVault]"

                return $newContext
            }
        } catch {
            Write-Error "Failed to move context '$ID' from '$SourceVault' to '$TargetVault': $_"
            throw
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
