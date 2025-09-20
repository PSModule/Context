function Get-ContentNonLocking {
    <#
        .SYNOPSIS
        Reads file content without locking the file for other processes.

        .DESCRIPTION
        Uses FileStream with explicit sharing flags to read file content while allowing
        other processes to read, write, or delete the file concurrently. This prevents
        file locking conflicts in multi-process scenarios.

        .EXAMPLE
        Get-ContentNonLocking -Path 'C:\data\file.txt'

        Reads the content of the file without locking it.

        .EXAMPLE
        Get-ContentNonLocking -Path 'C:\data\file.json' | ConvertFrom-Json

        Reads a JSON file without locking it and converts it to an object.

        .OUTPUTS
        string

        .NOTES
        This function uses System.IO.FileStream with FileShare.ReadWrite and FileShare.Delete
        flags to ensure maximum concurrency while reading files.
    #>
    [CmdletBinding()]
    param(
        # The path to the file to read.
        [Parameter(Mandatory)]
        [string] $Path,

        # The text encoding to use when reading the file.
        [Parameter()]
        [System.Text.Encoding] $Encoding = [System.Text.Encoding]::UTF8
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Begin"
    }

    process {
        try {
            Write-Verbose "[$stackPath] - Reading file without locking: $Path"

            # Open the file in read mode but allow others to read/write/delete at the same time
            $stream = [System.IO.FileStream]::new(
                $Path,
                [System.IO.FileMode]::Open,
                [System.IO.FileAccess]::Read,
                [System.IO.FileShare]::ReadWrite -bor [System.IO.FileShare]::Delete
            )

            try {
                $reader = [System.IO.StreamReader]::new($stream, $Encoding)
                try {
                    $content = $reader.ReadToEnd()
                    Write-Debug "[$stackPath] - Successfully read $($content.Length) characters from file"
                    return $content
                } finally {
                    $reader.Close()
                }
            } finally {
                $stream.Close()
            }
        } catch {
            Write-Debug "[$stackPath] - Error reading file: $($_.Exception.Message)"
            throw
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
