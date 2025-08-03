# Define Paths
$dataDir = "$env:LOCALAPPDATA\Tylex"
$expFile = "$dataDir\expansions.json"

# Create directory and file if they don't exist
if (-not (Test-Path $dataDir)) { New-Item -Path $dataDir -ItemType Directory | Out-Null }
if (-not (Test-Path $expFile)) { '[]' | Set-Content -Path $expFile }

# Prompt for Input
# Load an assembly to use a simple graphical input box.
Add-Type -AssemblyName Microsoft.VisualBasic

$key = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the new abbreviation (key):", "Add Tylex Expansion")
if ([string]::IsNullOrWhiteSpace($key)) { return } # Exit if user cancels or enters nothing

$value = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the full text for '$key':", "Add Tylex Expansion")
if ([string]::IsNullOrWhiteSpace($value)) { return } # Exit if user cancels

# Add New Expansion and Save
$expansions = Get-Content -Path $expFile | ConvertFrom-Json

# Check if the key already exists
if ($expansions | Where-Object { $_.key -eq $key }) {
	[System.Windows.Forms.MessageBox]::Show("Error: Abbreviation '$key' already exists.", "Tylex", "OK", "Error")
		return
}

# Create a new PowerShell object for the expansion
$newExpansion = [PSCustomObject]@{
	key   = $key
		value = $value
		usage = 0
}

# Add the new object to the array and save back to the file
($expansions + $newExpansion) | ConvertTo-Json | Set-Content -Path $expFile

[System.Windows.Forms.MessageBox]::Show("Successfully added '$key'.", "Tylex", "OK", "Information")
