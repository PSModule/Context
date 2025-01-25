function Rename-Context {
    <#
        .SYNOPSIS
        Renames a context.

        .DESCRIPTION
        This function renames a context.
        It retrieves the context with the old ID, sets the context with the new ID, and removes the context with the old ID.

        .EXAMPLE
        Rename-Context -ID 'PSModule.GitHub' -NewID 'PSModule.GitHub2'

        Renames the context 'PSModule.GitHub' to 'PSModule.GitHub2'.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        # The ID of the context to rename.
        [Parameter(Mandatory)]
        [string] $ID,

        # The new ID of the context.
        [Parameter(Mandatory)]
        [string] $NewID,

        # Force the rename even if the new ID already exists.
        [Parameter()]
        [switch] $Force
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
        $context = Get-Context -ID $ID
        if (-not $context) {
            throw "Context with ID '$ID' not found."
        }

        $existingContext = Get-Context -ID $NewID
        if ($existingContext -and -not $Force) {
            throw "Context with ID '$NewID' already exists."
        }

        if ($PSCmdlet.ShouldProcess("Renaming context '$ID' to '$NewID'")) {
            try {
                Set-Context -ID $NewID -Context $context
            } catch {
                Write-Error $_
                throw 'Failed to set new context'
            }

            try {
                Remove-Context -ID $ID
            } catch {
                Write-Error $_
                throw 'Failed to remove old context'
            }
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
