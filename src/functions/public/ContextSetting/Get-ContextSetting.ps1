#Requires -Modules @{ ModuleName = 'DynamicParams'; RequiredVersion = '1.1.8' }

function Get-ContextSetting {
    <#
        .SYNOPSIS
        Retrieve a setting from a context.

        .DESCRIPTION
        This function retrieves a setting from a specified context.
        If the setting is a secret, it can be returned as plain text using the -AsPlainText switch.

        .PARAMETER Context
        The context to get the configuration from.

        .PARAMETER Name
        Name of a setting to get.

        .EXAMPLE
        Get-ContextSetting -Name 'APIBaseUri' -Context 'GitHub'

        Get the value of the 'APIBaseUri' setting from the 'GitHub' context.
    #>
    [OutputType([object])]
    [CmdletBinding()]
    param (
        # Return the setting as plain text if it is a secret.
        [Parameter()]
        [switch] $AsPlainText
    )

    dynamicparam {
        $dynamicParamDictionary = New-DynamicParamDictionary

        $contextParam = @{
            Name                   = 'Context'
            Alias                  = 'ContextName'
            Mandatory              = $true
            Type                   = [string]
            ValidateSet            = (Get-Context).Name
            DynamicParamDictionary = $dynamicParamDictionary
        }
        New-DynamicParam @contextParam

        $nameParam = @{
            Name                   = 'Name'
            Type                   = [string]
            ValidateSet            = (Get-ContextSetting -Context $Context).Name
            DynamicParamDictionary = $dynamicParamDictionary
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

        Write-Verbose "Getting settings for context: [$Context]"
        $contextObj = Get-Context -Name $Context -AsPlainText:$AsPlainText
        if (-not $contextObj) {
            Write-Error $_
            throw "Context [$Context] not found"
        }

        if ($Name) {
            Write-Verbose "Getting setting: [$Name]"
            return $contextObj | Where-Object { $_.Name -like $Name }
        }

        Write-Verbose "Returning all settings for context: [$Context]"
        $contextObj
    }
}
