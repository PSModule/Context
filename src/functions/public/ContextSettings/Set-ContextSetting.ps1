﻿#Requires -Modules Microsoft.PowerShell.SecretManagement

function Set-ContextSetting {
    <#
        .SYNOPSIS
        Sets a setting in a context.

        .DESCRIPTION
        Sets a setting in the specified context.
        To store a secret, use the name 'Secret'.

        .EXAMPLE
        Set-ContextSetting -Name 'ApiBaseUri' -Value 'https://api.github.com' -Context 'GitHub'

        Sets a setting called 'ApiBaseUri' in the context called 'GitHub'.

        .EXAMPLE
        $secret = 'myAccessToken' | ConvertTo-SecureString -AsPlainText -Force
        Set-ContextSetting -Name 'Secret' -Value $secret -Context 'GitHub'

        Sets a secret in the configuration context called 'GitHub'.
    #>
    [OutputType([void])]
    [CmdletBinding(SupportsShouldProcess)]
    param (
        # The name of the setting to set.
        [Parameter(Mandatory)]
        [string] $Name,

        # The value to set for the specified setting. This can be a plain text string or a secure string.
        [Parameter(Mandatory)]
        [AllowNull()]
        [AllowEmptyString()]
        [object] $Value,

        # The name of the context where the setting will be set.
        [Parameter(Mandatory)]
        [Alias('ContextName')]
        [string] $Context
    )

    $contextVault = Get-ContextVault

    $context = Get-Context -Name $Context

    if ($PSCmdlet.ShouldProcess($Name, "Set value [$Value]")) {
        Write-Verbose "Setting [$Name] to [$Value] in [$($context.Name)]"
        switch ($Name) {
            'Secret' {
                if ([string]::IsNullOrEmpty($Value)) {
                    Write-Verbose "Value is null or empty, setting to 'null'"
                    $Value = 'null'
                }
                if ($Value -is [SecureString]) {
                    Write-Verbose "Value is a SecureString, setting [$Name] in context [$($context.Name)]"
                    Set-Secret -Name $context.Name -SecureStringSecret $Value -Vault $contextVault.Name
                } else {
                    Write-Verbose "Value is $($Value.GetType().FullName), setting [$Name] in context [$($context.Name)]"
                    Set-Secret -Name $context.Name -Value $Value -Vault $contextVault.Name
                }
                break
            }
            'Name' {
                if ([string]::IsNullOrEmpty($Value)) {
                    Write-Error 'Name cannot be null or empty'
                    return
                }
                Set-Secret -Name $Value -SecureStringSecret $secretValue -Vault $context.Name -Metadata $secretInfo.Metadata
                $newSecretInfo = Get-SecretInfo -Name $Value -Vault $context.Name
                if ($newSecretInfo) {
                    Remove-Secret -Name $Name -Vault $context.Name
                } else {
                    Remove-Secret -Name $Value -Vault $context.Name
                }
                break
            }
            default {
                Write-Verbose 'Updating metadata'
                $metadata = ($secretInfo | Select-Object -ExpandProperty Metadata) + @{}
                if ([string]::IsNullOrEmpty($Value)) {
                    Write-Verbose " - Removing [$Name] from metadata"
                    $metadata.Remove($Name)
                } else {
                    Write-Verbose " - Setting [$Name] to [$Value] in metadata"
                    $metadata[$Name] = $Value
                }
                Write-Verbose "Updating context [$($context.Name)] in vault [$($contextVault.Name)]"
                Set-SecretInfo -Name $Context -Metadata $metadata -Vault $contextVault.Name
            }
        }
    }
}
