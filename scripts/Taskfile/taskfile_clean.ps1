# Remove-GitIgnored.ps1
# Deletes files/folders defined in .gitignore and logs all patterns

# Path to the .gitignore file (default: current directory)
$gitignorePath = Join-Path (Get-Location) ".gitignore"

if (-Not (Test-Path $gitignorePath)) {
    Write-Error "No .gitignore file found at $gitignorePath"
    exit 1
}

# Read patterns from .gitignore
$patterns = Get-Content $gitignorePath | Where-Object {
    $_ -and -not $_.StartsWith("#") -and $_.Trim() -ne ""
}

Write-Host "=== Processing .gitignore at $gitignorePath ==="
Write-Host "Found $($patterns.Count) patterns:"
foreach ($p in $patterns) {
    Write-Host "  -> $p"
}
Write-Host "==============================================="

foreach ($pattern in $patterns) {
    $normalized = $pattern.Trim()
    $isRootFolder = $normalized -match "^/?([^*?]+/)$"

    if ($isRootFolder) {
        # Handle root-level folder like /build/
        $folderName = $normalized.TrimStart("/").TrimEnd("/")
        $folderPath = Join-Path (Get-Location) $folderName
        Write-Host "Checking for root folder: $folderPath"
        if (Test-Path $folderPath) {
            try {
                Remove-Item $folderPath -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "  Deleted folder: $folderPath"
            } catch {
                Write-Warning "  Failed to delete folder: $folderPath"
            }
        } else {
            Write-Host "  No folder found for pattern: $pattern"
        }
        continue
    }

    # Normalize slashes for Windows
    $globPattern = $normalized -replace "/", "\"

    Write-Host "Searching for matches of pattern: $pattern (glob: $globPattern)"

    # Expand globbing pattern
    $matches = Get-ChildItem -Path . -Recurse -Force -Include $globPattern -ErrorAction SilentlyContinue

    if ($matches.Count -eq 0) {
        Write-Host "  No matches found for: $pattern"
    }

    foreach ($match in $matches) {
        try {
            if ($match.PSIsContainer) {
                Remove-Item $match.FullName -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "  Deleted folder: $($match.FullName)"
            } else {
                Remove-Item $match.FullName -Force -ErrorAction SilentlyContinue
                Write-Host "  Deleted file: $($match.FullName)"
            }
        } catch {
            Write-Warning "  Failed to delete: $($match.FullName)"
        }
    }
}
