#Requires -Modules @{ ModuleName = 'DynamicParams'; RequiredVersion = '1.1.8' }

filter Remove-ContextSetting {
    <#
        .SYNOPSIS
        Remove a setting from the context.

        .DESCRIPTION
        This function removes a setting from the specified context.
        It supports wildcard patterns for the name and does accept pipeline input.

        .PARAMETER Name
        Name of a setting to remove.

        .EXAMPLE
        Remove-ContextSetting -Name 'APIBaseUri' -Context 'GitHub'

        Remove the APIBaseUri setting from the 'GitHub' context.

        .EXAMPLE
        Get-ContextSetting -Context 'GitHub' | Remove-ContextSetting

        Remove all settings starting with 'API' from the 'GitHub' context.

        .EXAMPLE
        Remove-ContextSetting -Name 'API*' -Context 'GitHub'

        Remove all settings starting with 'API' from the 'GitHub' context.

        .EXAMPLE
        Get-ContextSetting -Context 'GitHub' | Where-Object { $_.Name -like 'API*' } | Remove-ContextSetting

        Remove all settings starting with 'API' from the 'GitHub' context using pipeline input.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param ()

    dynamicparam {
        $dynamicParamDictionary = New-DynamicParamDictionary

        $contextParam = @{
            Name                            = 'Context'
            Alias                           = 'ContextName'
            Mandatory                       = $true
            Type                            = [string]
            ValueFromPipelineByPropertyName = $true
            ValidateSet                     = (Get-Context).Name
            DynamicParamDictionary          = $dynamicParamDictionary
        }
        New-DynamicParam @contextParam

        $nameParam = @{
            Name                            = 'Name'
            Type                            = [string]
            ValueFromPipeline               = $true
            ValueFromPipelineByPropertyName = $true
            ValidateSet                     = (Get-ContextSetting -Context $Context).Name
            DynamicParamDictionary          = $dynamicParamDictionary
        }
        New-DynamicParam @nameParam

        return $dynamicParamDictionary
    }

    begin {
        $Context = $PSBoundParameters.Context
        $Name = $PSBoundParameters.Name
    }

    process {
        $null = Get-ContextVault

        $contextObj = Get-Context -Name $Context

        if ($PSCmdlet.ShouldProcess('Target', "Remove value [$Name] from context [$($contextObj.Name)]")) {
            Set-ContextSetting -Name $Name -Value $null -Context $($contextObj.Name)
        }
    }
}
