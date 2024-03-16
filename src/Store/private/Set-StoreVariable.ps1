﻿function Set-StoreVariable {
    <#
        .SYNOPSIS
        Set a variable in the store.

        .EXAMPLE
        Set-StoreVariable -Name 'Name' -Value 'MyName'
    #>
    param(
        # The name of the variable to set.
        [Parameter(Mandatory)]
        [string] $Name,

        # The value to set.
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $Value
    )

    if ($null -eq $Value) {
        $script:Store.Remove($Name)
    } else {
        $script:Store.$Name = $Value
    }
    Save-VariableStore
}
