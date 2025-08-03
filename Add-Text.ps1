[System.Windows.Forms.Application]::EnableVisualStyles()
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- Dark Mode Colors ---
$darkBackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
$darkForeColor = [System.Drawing.Color]::White
$darkControlBackColor = [System.Drawing.Color]::FromArgb(60, 60, 63)
$darkButtonBackColor = [System.Drawing.Color]::FromArgb(80, 80, 83)

# --- Data Handling ---
$dataDir = "$env:LOCALAPPDATA\Tylex"
$expFile = "$dataDir\expansions.json"
if (-not (Test-Path $dataDir)) { New-Item -Path $dataDir -ItemType Directory -Force | Out-Null }
if (-not (Test-Path $expFile)) { '[]' | Set-Content -Path $expFile }

# ✅ Load expansions at the start for real-time checking
$jsonContent = Get-Content -Path $expFile -Raw -ErrorAction SilentlyContinue
$expansions = if ($jsonContent) { @($jsonContent | ConvertFrom-Json) } else { @() }

# --- GUI Form Creation ---
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Add New Tylex Expansion'
$form.Size = New-Object System.Drawing.Size(750, 300) # ✅ Wider form
$form.StartPosition = 'CenterScreen'; $form.TopMost = $true; $form.FormBorderStyle = 'FixedDialog'; $form.MaximizeBox = $false; $form.MinimizeBox = $false; $form.BackColor = $darkBackColor

# --- Controls (Left Pane) ---
$keyLabel = New-Object System.Windows.Forms.Label; $keyLabel.Text = "Abbreviation (Key):"; $keyLabel.ForeColor = $darkForeColor; $keyLabel.Location = New-Object System.Drawing.Point(10, 10); $keyLabel.AutoSize = $true
$keyBox = New-Object System.Windows.Forms.TextBox; $keyBox.Location = New-Object System.Drawing.Point(10, 30); $keyBox.Size = New-Object System.Drawing.Size(345, 20); $keyBox.BackColor = $darkControlBackColor; $keyBox.ForeColor = $darkForeColor
$valueLabel = New-Object System.Windows.Forms.Label; $valueLabel.Text = "Expansion Text (Value):"; $valueLabel.ForeColor = $darkForeColor; $valueLabel.Location = New-Object System.Drawing.Point(10, 60); $valueLabel.AutoSize = $true
$valueBox = New-Object System.Windows.Forms.TextBox; $valueBox.Location = New-Object System.Drawing.Point(10, 80); $valueBox.Size = New-Object System.Drawing.Size(345, 130); $valueBox.BackColor = $darkControlBackColor; $valueBox.ForeColor = $darkForeColor; $valueBox.MultiLine = $true; $valueBox.ScrollBars = "Vertical"

# --- Controls (Right Pane - Duplicate Preview) ---
$previewLabel = New-Object System.Windows.Forms.Label; $previewLabel.Text = "Existing Expansion:"; $previewLabel.ForeColor = $darkForeColor; $previewLabel.Location = New-Object System.Drawing.Point(380, 10); $previewLabel.AutoSize = $true; $previewLabel.Visible = $false
$previewBox = New-Object System.Windows.Forms.TextBox; $previewBox.Location = New-Object System.Drawing.Point(380, 30); $previewBox.Size = New-Object System.Drawing.Size(345, 180); $previewBox.BackColor = $darkControlBackColor; $previewBox.ForeColor = $darkForeColor; $previewBox.MultiLine = $true; $previewBox.ScrollBars = "Vertical"; $previewBox.ReadOnly = $true; $previewBox.Visible = $false

# --- Controls (Buttons) ---
$okButton = New-Object System.Windows.Forms.Button; $okButton.Text = "Save"; $okButton.Location = New-Object System.Drawing.Point(569, 225); $okButton.Size = New-Object System.Drawing.Size(75, 25); $okButton.DialogResult = 'OK'; $okButton.FlatStyle = 'Flat'; $okButton.BackColor = $darkButtonBackColor; $okButton.ForeColor = $darkForeColor
$cancelButton = New-Object System.Windows.Forms.Button; $cancelButton.Text = "Cancel"; $cancelButton.Location = New-Object System.Drawing.Point(650, 225); $cancelButton.Size = New-Object System.Drawing.Size(75, 25); $cancelButton.DialogResult = 'Cancel'; $cancelButton.FlatStyle = 'Flat'; $cancelButton.BackColor = $darkButtonBackColor; $cancelButton.ForeColor = $darkForeColor

$form.Controls.AddRange(@($keyLabel, $keyBox, $valueLabel, $valueBox, $previewLabel, $previewBox, $okButton, $cancelButton))
$form.AcceptButton = $okButton; $form.CancelButton = $cancelButton
$form.Add_Load({ $form.Activate(); $form.ActiveControl = $keyBox })

# ✅ Event: Check for duplicates as the user types in the key box
$keyBox.Add_TextChanged({
    $existing = $expansions | Where-Object { $_.key -eq $keyBox.Text }
    if ($existing) {
        $previewLabel.Visible = $true
        $previewBox.Visible = $true
        $previewBox.Text = $existing.value
        $okButton.Text = "Overwrite"
    } else {
        $previewLabel.Visible = $false
        $previewBox.Visible = $false
        $previewBox.Text = ""
        $okButton.Text = "Save"
    }
})

# --- Show Form and Process Result ---
if ($form.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { $form.Dispose(); return }

$key = $keyBox.Text
$value = $valueBox.Text
$form.Dispose()

if ([string]::IsNullOrWhiteSpace($key) -or [string]::IsNullOrWhiteSpace($value)) { return }

# ✅ --- New Overwrite Logic ---
$existing = $expansions | Where-Object { $_.key -eq $key }
if ($existing) {
    $confirmResult = [System.Windows.Forms.MessageBox]::Show(
        "An expansion with the key '$key' already exists. Do you want to overwrite it?",
        "Confirm Overwrite",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    if ($confirmResult -ne 'Yes') {
        return
    }
    # Remove the old entry
    $expansions = $expansions | Where-Object { $_.key -ne $key }
}

$newExpansion = [PSCustomObject]@{ key = $key; value = $value; usage = 0 }
$expansions += $newExpansion

# Manual "Pretty-Print" JSON Serialization
$jsonParts = foreach ($item in $expansions) { $escapedKey = $item.key -replace '\\', '\\' -replace '"', '\"'; $escapedValue = $item.value -replace '\\', '\\' -replace '"', '\"'; "  {`n    `"key`": `"$escapedKey`",`n    `"value`": `"$escapedValue`",`n    `"usage`": $($item.usage)`n  }" }
"[`n" + ($jsonParts -join ",`n") + "`n]" | Set-Content -Path $expFile

[void][System.Windows.Forms.MessageBox]::Show("Successfully saved '$key'.", "Tylex", "OK", "Information")