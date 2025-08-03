# ✅ Enable modern visual styles for a nicer look
[System.Windows.Forms.Application]::EnableVisualStyles()

# Define Paths
$dataDir = "$env:LOCALAPPDATA\Tylex"
$expFile = "$dataDir\expansions.json"

# Create directory and file if they don't exist
if (-not (Test-Path $dataDir)) { New-Item -Path $dataDir -ItemType Directory -Force | Out-Null }
if (-not (Test-Path $expFile)) { '[]' | Set-Content -Path $expFile }

# Prompt for Input
Add-Type -AssemblyName Microsoft.VisualBasic
$key = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the new abbreviation (key):", "Add Tylex Expansion")
if ([string]::IsNullOrWhiteSpace($key)) { return }
$value = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the full text for '$key':", "Add Tylex Expansion")
if ([string]::IsNullOrWhiteSpace($value)) { return }

# Robustly read the entire file as a single raw string before parsing
$jsonContent = Get-Content -Path $expFile -Raw -ErrorAction SilentlyContinue
$expansions = if ($jsonContent) { @($jsonContent | ConvertFrom-Json) } else { @() }

if ($expansions.key -contains $key) {
    Add-Type -AssemblyName System.Windows.Forms
    [void][System.Windows.Forms.MessageBox]::Show("Error: Abbreviation '$key' already exists.", "Tylex", "OK", "Error")
    return
}

$newExpansion = [PSCustomObject]@{ key = $key; value = $value; usage = 0 }
$expansions += $newExpansion

# --- MANUAL "PRETTY-PRINT" JSON SERIALIZATION ---
$jsonParts = foreach ($item in $expansions) {
    $escapedKey = $item.key -replace '\\', '\\' -replace '"', '\"'
    $escapedValue = $item.value -replace '\\', '\\' -replace '"', '\"'
    # Build a formatted, multi-line string for each object
    "  {`n    `"key`": `"$escapedKey`",`n    `"value`": `"$escapedValue`",`n    `"usage`": $($item.usage)`n  }"
}
# Join the formatted parts and wrap in brackets for a valid, pretty JSON array
"[`n" + ($jsonParts -join ",`n") + "`n]" | Set-Content -Path $expFile

Add-Type -AssemblyName System.Windows.Forms
[void][System.Windows.Forms.MessageBox]::Show("Successfully added '$key'.", "Tylex", "OK", "Information")