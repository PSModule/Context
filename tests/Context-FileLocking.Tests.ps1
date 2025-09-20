#Requires -Modules @{ ModuleName = 'Pester'; RequiredVersion = '5.7.1' }

[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments', '',
    Justification = 'Pester grouping syntax: known issue.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidUsingWriteHost', '',
    Justification = 'Log outputs to GitHub Actions logs.'
)]
[CmdletBinding()]
param()

BeforeAll {
    # Create test directory for file locking tests
    $script:TestVaultPath = Join-Path ([System.IO.Path]::GetTempPath()) "context-file-locking-tests"
    if (Test-Path $script:TestVaultPath) {
        Remove-Item -Path $script:TestVaultPath -Recurse -Force
    }
    New-Item -Path $script:TestVaultPath -ItemType Directory -Force | Out-Null
    
    # Create test context files
    $script:TestContextFile = Join-Path $script:TestVaultPath "test-context.json"
    $script:TestShardFile = Join-Path $script:TestVaultPath "shard"
    
    $testContext = @{
        ID = "FileLockingTest"
        Path = $script:TestContextFile
        Vault = "FileLockingTestVault"
        Context = "encrypted-test-data-for-locking"
    } | ConvertTo-Json
    
    $testShard = [System.Guid]::NewGuid().ToString()
    
    Set-Content -Path $script:TestContextFile -Value $testContext
    Set-Content -Path $script:TestShardFile -Value $testShard
}

AfterAll {
    # Clean up test files
    if (Test-Path $script:TestVaultPath) {
        Remove-Item -Path $script:TestVaultPath -Recurse -Force
    }
}

Describe 'Context File Locking' {
    Context 'Concurrent File Read Operations' {
        It 'Should allow multiple concurrent reads of context files without locking conflicts' {
            $jobs = @()
            
            # Start multiple concurrent read operations
            for ($i = 1; $i -le 5; $i++) {
                $jobs += Start-Job -ScriptBlock {
                    param($filePath, $readerId)
                    try {
                        # Test the enhanced file reading approach used in Get-ContextInfo (FileStream with explicit sharing)
                        Start-Sleep -Milliseconds (Get-Random -Minimum 10 -Maximum 50)
                        $stream = [System.IO.FileStream]::new(
                            $filePath,
                            [System.IO.FileMode]::Open,
                            [System.IO.FileAccess]::Read,
                            [System.IO.FileShare]::ReadWrite -bor [System.IO.FileShare]::Delete
                        )
                        try {
                            $reader = [System.IO.StreamReader]::new($stream)
                            try {
                                $content = $reader.ReadToEnd()
                                $contextInfo = $content | ConvertFrom-Json
                            } finally {
                                $reader.Close()
                            }
                        } finally {
                            $stream.Close()
                        }
                        return @{
                            Success = $true
                            ReaderId = $readerId
                            ContextId = $contextInfo.ID
                            Error = $null
                        }
                    } catch {
                        return @{
                            Success = $false
                            ReaderId = $readerId
                            ContextId = $null
                            Error = $_.Exception.Message
                        }
                    }
                } -ArgumentList $script:TestContextFile, $i
            }
            
            # Wait for all jobs and collect results
            $results = $jobs | Wait-Job | Receive-Job
            $jobs | Remove-Job
            
            # All reads should succeed
            $results | ForEach-Object { $_.Success | Should -Be $true }
            $results | ForEach-Object { $_.ContextId | Should -Be "FileLockingTest" }
            $results.Count | Should -Be 5
        }
        
        It 'Should allow concurrent reads of shard files without locking conflicts' {
            $jobs = @()
            
            # Start multiple concurrent shard file reads
            for ($i = 1; $i -le 5; $i++) {
                $jobs += Start-Job -ScriptBlock {
                    param($filePath, $readerId)
                    try {
                        # Test the enhanced file reading approach used in Get-ContextVaultKeyPair (FileStream with explicit sharing)
                        Start-Sleep -Milliseconds (Get-Random -Minimum 10 -Maximum 50)
                        $stream = [System.IO.FileStream]::new(
                            $filePath,
                            [System.IO.FileMode]::Open,
                            [System.IO.FileAccess]::Read,
                            [System.IO.FileShare]::ReadWrite -bor [System.IO.FileShare]::Delete
                        )
                        try {
                            $reader = [System.IO.StreamReader]::new($stream)
                            try {
                                $fileShard = $reader.ReadToEnd().Trim()
                            } finally {
                                $reader.Close()
                            }
                        } finally {
                            $stream.Close()
                        }
                        return @{
                            Success = $true
                            ReaderId = $readerId
                            ShardValue = $fileShard
                            Error = $null
                        }
                    } catch {
                        return @{
                            Success = $false
                            ReaderId = $readerId
                            ShardValue = $null
                            Error = $_.Exception.Message
                        }
                    }
                } -ArgumentList $script:TestShardFile, $i
            }
            
            # Wait for all jobs and collect results
            $results = $jobs | Wait-Job | Receive-Job
            $jobs | Remove-Job
            
            # All reads should succeed
            $results | ForEach-Object { $_.Success | Should -Be $true }
            $results | ForEach-Object { $_.ShardValue | Should -Not -BeNullOrEmpty }
            
            # All shard values should be the same
            $uniqueShardValues = $results | Select-Object -ExpandProperty ShardValue | Sort-Object | Get-Unique
            $uniqueShardValues.Count | Should -Be 1
            $results.Count | Should -Be 5
        }
        
        It 'Should handle fallback from FileStream to Get-Content gracefully' {
            # Test that both methods produce equivalent results
            $stream = [System.IO.FileStream]::new(
                $script:TestContextFile,
                [System.IO.FileMode]::Open,
                [System.IO.FileAccess]::Read,
                [System.IO.FileShare]::ReadWrite -bor [System.IO.FileShare]::Delete
            )
            try {
                $reader = [System.IO.StreamReader]::new($stream)
                try {
                    $content1 = $reader.ReadToEnd()
                } finally {
                    $reader.Close()
                }
            } finally {
                $stream.Close()
            }
            
            $content2 = Get-Content -Path $script:TestContextFile -Raw

            $json1 = $content1 | ConvertFrom-Json
            $json2 = $content2 | ConvertFrom-Json

            $json1.ID | Should -Be $json2.ID
            $json1.Vault | Should -Be $json2.Vault
            $json1.Context | Should -Be $json2.Context
        }
    }
    
    Context 'Write Operations File Locking' {
        It 'Should maintain proper file locking for write operations' {
            $testFile = Join-Path $script:TestVaultPath "write-lock-test.json"
            
            # Start a write operation using Set-Content (as used in Set-Context)
            $writer = Start-Job -ScriptBlock {
                param($filePath)
                try {
                    $content = @{
                        ID = "WriteTestContext"
                        Path = $filePath
                        Vault = "WriteTestVault"
                        Context = "encrypted-write-test-data"
                    } | ConvertTo-Json
                    
                    Start-Sleep -Milliseconds 50  # Simulate write time
                    Set-Content -Path $filePath -Value $content
                    return @{ Success = $true; Error = $null }
                } catch {
                    return @{ Success = $false; Error = $_.Exception.Message }
                }
            } -ArgumentList $testFile
            
            $writeResult = $writer | Wait-Job | Receive-Job
            $writer | Remove-Job
            
            # Write should succeed
            $writeResult.Success | Should -Be $true
            
            # File should be readable after write completes
            if (Test-Path $testFile) {
                $stream = [System.IO.FileStream]::new(
                    $testFile,
                    [System.IO.FileMode]::Open,
                    [System.IO.FileAccess]::Read,
                    [System.IO.FileShare]::ReadWrite -bor [System.IO.FileShare]::Delete
                )
                try {
                    $reader = [System.IO.StreamReader]::new($stream)
                    try {
                        $finalContent = $reader.ReadToEnd()
                    } finally {
                        $reader.Close()
                    }
                } finally {
                    $stream.Close()
                }
                $finalJson = $finalContent | ConvertFrom-Json
                $finalJson.ID | Should -Be "WriteTestContext"
            }
        }
    }
    
    Context 'Performance and Scalability' {
        It 'Should handle multiple concurrent reads efficiently' {
            $startTime = Get-Date
            $jobs = @()
            
            # Start multiple concurrent read operations
            for ($i = 1; $i -le 10; $i++) {
                $jobs += Start-Job -ScriptBlock {
                    param($filePath, $readerId)
                    try {
                        # Perform multiple reads to stress test using FileStream approach
                        for ($j = 1; $j -le 2; $j++) {
                            $stream = [System.IO.FileStream]::new(
                                $filePath,
                                [System.IO.FileMode]::Open,
                                [System.IO.FileAccess]::Read,
                                [System.IO.FileShare]::ReadWrite -bor [System.IO.FileShare]::Delete
                            )
                            try {
                                $reader = [System.IO.StreamReader]::new($stream)
                                try {
                                    $content = $reader.ReadToEnd()
                                    $contextInfo = $content | ConvertFrom-Json
                                } finally {
                                    $reader.Close()
                                }
                            } finally {
                                $stream.Close()
                            }
                            Start-Sleep -Milliseconds 5
                        }
                        return @{ Success = $true; ReaderId = $readerId }
                    } catch {
                        return @{ Success = $false; ReaderId = $readerId; Error = $_.Exception.Message }
                    }
                } -ArgumentList $script:TestContextFile, $i
            }
            
            # Wait for all jobs
            $results = $jobs | Wait-Job | Receive-Job
            $jobs | Remove-Job
            
            $endTime = Get-Date
            $duration = ($endTime - $startTime).TotalSeconds
            
            # All reads should succeed
            $results | ForEach-Object { $_.Success | Should -Be $true }
            $results.Count | Should -Be 10
            
            # Should complete in reasonable time
            $duration | Should -BeLessThan 30
            
            Write-Host "Completed 20 concurrent file reads in $duration seconds"
        }
    }
}