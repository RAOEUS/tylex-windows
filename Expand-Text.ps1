# Define Paths
$dataDir = "$env:LOCALAPPDATA\Tylex"
$expFile = "$dataDir\expansions.json"

# Create directory and empty JSON file if they don't exist
if (-not (Test-Path $dataDir)) { New-Item -Path $dataDir -ItemType Directory -Force | Out-Null }
if (-not (Test-Path $expFile)) { '[]' | Set-Content -Path $expFile }

# Read and Prepare Data
$expansions = Get-Content -Path $expFile | ConvertFrom-Json

# Display the Launcher UI
$choice = $expansions | Sort-Object -Property Usage -Descending | Out-GridView -PassThru -Title "Tylex Expander"

# Exit if the user closed the window or clicked Cancel
if ($null -eq $choice) {
    return
}

# Update the usage count in the JSON file
($expansions | Where-Object { $_.key -eq $choice.key }).usage++
$expansions | ConvertTo-Json | Set-Content -Path $expFile

# Return the chosen value as standard output so AutoHotkey can capture it
Write-Output $choice.value
