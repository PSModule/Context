# Using a dictionary to get the benefit of reference type in PowerShell while multiple functions are running in parallel.
# Using concurrent dictionary to be able to safely access the dictionary from multiple threads /ForEach -Parallel.
$script:Contexts = [System.Collections.Concurrent.ConcurrentDictionary[string, [PSCustomObject]]]::new()
