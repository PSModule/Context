function Get-PSCallStackPath {
    <#
        .SYNOPSIS
        Creates a string representation of the current call stack.

        .DESCRIPTION
        This function generates a string representation of the current call stack.
        It allows skipping the first and last elements of the call stack using the `SkipFirst`
        and `SkipLatest` parameters. By default, it skips the first function (typically `<ScriptBlock>`)
        and the last function (`Get-PSCallStackPath`) to present a cleaner view of the actual call stack.

        .EXAMPLE
        Get-PSCallStackPath

        Output:
        ```powershell
        First-Function\Second-Function\Third-Function
        ```

        Returns the call stack with the first (`<ScriptBlock>`) and last (`Get-PSCallStackPath`)
        functions removed.

        .EXAMPLE
        Get-PSCallStackPath -SkipFirst 0

        Output:
        ```powershell
        <ScriptBlock>\First-Function\Second-Function\Third-Function
        ```

        Includes the first function (typically `<ScriptBlock>`) in the call stack output.

        .EXAMPLE
        Get-PSCallStackPath -SkipLatest 0

        Output:
        ```powershell
        First-Function\Second-Function\Third-Function\Get-PSCallStackPath
        ```

        Includes the last function (`Get-PSCallStackPath`) in the call stack output.

        .OUTPUTS
        System.String

        .NOTES
        A string representing the call stack path, with function names separated by backslashes.

        .LINK
        https://psmodule.io/PSCallStack/Functions/Get-PSCallStackPath/
    #>
    [CmdletBinding()]
    param(
        # The number of functions to skip from the last function called.
        # The last function in the stack is this function (`Get-PSCallStackPath`).
        [Parameter()]
        [int] $SkipLatest = 1,

        # The number of functions to skip from the first function called.
        # The first function is typically `<ScriptBlock>`.
        [Parameter()]
        [int] $SkipFirst = 1
    )

    $skipFirst++
    $cmds = (Get-PSCallStack).Command
    $functionPath = $cmds[($cmds.Count - $skipFirst)..$SkipLatest] -join '\'
    $functionPath = $functionPath -replace '^.*<ScriptBlock>\\'
    $functionPath = $functionPath -replace '^.*.ps1\\'
    return $functionPath
}
