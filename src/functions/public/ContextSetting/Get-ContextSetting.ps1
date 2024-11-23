﻿#Requires -Modules @{ ModuleName = 'Microsoft.PowerShell.SecretManagement'; RequiredVersion = '1.1.2' }

function Get-ContextSetting {
    <#
        .SYNOPSIS
        Retrieve a setting from a context.

        .DESCRIPTION
        This function retrieves a setting from a specified context.

        .EXAMPLE
        Get-ContextSetting -Context 'GitHub' -Name 'APIBaseUri'

        Get the value of the 'APIBaseUri' setting from the 'GitHub' context.
    #>
    [OutputType([object])]
    [CmdletBinding()]
    param (
        # The context to get the configuration from.
        [Parameter(Mandatory)]
        [Alias('ContextID')]
        [string] $ID,

        # Name of a setting to get.
        [Parameter(Mandatory)]
        [string] $Name
    )

    try {
        $null = Get-ContextVault
        $context = Get-Context -ID $ID

        if (-not $context) {
            throw "Context [$ID] not found"
        }

        Write-Verbose "Returning setting: [$Name]"
        $context.$Name
    } catch {
        throw $_
    }
}
