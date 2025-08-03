# Define Paths
# Use %LOCALAPPDATA% for the data file, which is standard for Windows apps.
$dataDir = "$env:LOCALAPPDATA\Tylex"
$expFile = "$dataDir\expansions.json"

# Create directory and empty JSON file if they don't exist
if (-not (Test-Path $dataDir)) { New-Item -Path $dataDir -ItemType Directory | Out-Null }
if (-not (Test-Path $expFile)) { '[]' | Set-Content -Path $expFile }

# Read and Prepare Data
# PowerShell's ConvertFrom-Json automatically turns the JSON into objects.
$expansions = Get-Content -Path $expFile | ConvertFrom-Json

# Display the Launcher UI
# Out-GridView is the dmenu/rofi equivalent.
# -PassThru sends the selected object down the pipeline.
# -Title sets the window title.
$choice = $expansions | Sort-Object -Property Usage -Descending | Out-GridView -PassThru -Title "Tylex Expander"

# Exit if the user closed the window or clicked Cancel
if ($null -eq $choice) {
	return
}

# Type the Expansion
# We need to load the Windows Forms assembly to use SendKeys.
Add-Type -AssemblyName System.Windows.Forms

# Wait a fraction of a second for focus to return to the previous window.
Start-Sleep -Milliseconds 200

# SendWait simulates typing the value of the chosen expansion.
[System.Windows.Forms.SendKeys]::SendWait($choice.value)

# Increment Usage Count and Save
# Find the chosen expansion in the original list and increment its usage.
	($expansions | Where-Object { $_.key -eq $choice.key }).usage++

# Convert the updated object array back to JSON and save it.
	$expansions | ConvertTo-Json | Set-Content -Path $expFile
