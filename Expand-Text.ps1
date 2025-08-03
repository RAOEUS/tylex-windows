[System.Windows.Forms.Application]::EnableVisualStyles()
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ✅ --- Dark Mode Colors ---
$darkBackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
$darkForeColor = [System.Drawing.Color]::White
$darkControlBackColor = [System.Drawing.Color]::FromArgb(60, 60, 63)

# --- Data Handling ---
$dataDir = "$env:LOCALAPPDATA\Tylex"; $configDir = "$env:APPDATA\Tylex"; $expFile = "$dataDir\expansions.json"
if (-not (Test-Path $dataDir)) { New-Item -Path $dataDir -ItemType Directory -Force | Out-Null }
if (-not (Test-Path $expFile)) { '[]' | Set-Content -Path $expFile }
$jsonContent = Get-Content -Path $expFile -Raw -ErrorAction SilentlyContinue
$expansions = if ($jsonContent) { @($jsonContent | ConvertFrom-Json) } else { @() }; $expansions = $expansions | Sort-Object -Property @{Expression='usage'; Descending=$true}, @{Expression='key'; Ascending=$true}

# --- GUI Form Creation and Logic ---
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Tylex Expander'; $form.Size = New-Object System.Drawing.Size(500, 350); $form.StartPosition = 'CenterScreen'; $form.TopMost = $true; $form.FormBorderStyle = 'FixedDialog'; $form.MaximizeBox = $false; $form.MinimizeBox = $false
$form.BackColor = $darkBackColor # ✅ Set form background color

$filterBox = New-Object System.Windows.Forms.TextBox
$filterBox.Location = New-Object System.Drawing.Point(10, 10); $filterBox.Size = New-Object System.Drawing.Size(465, 20)
$filterBox.BackColor = $darkControlBackColor; $filterBox.ForeColor = $darkForeColor; $filterBox.BorderStyle = 'FixedSingle' # ✅ Set textbox colors
$form.Controls.Add($filterBox)

$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(10, 40); $listBox.Size = New-Object System.Drawing.Size(465, 260)
$listBox.BackColor = $darkControlBackColor; $listBox.ForeColor = $darkForeColor; $listBox.BorderStyle = 'FixedSingle' # ✅ Set listbox colors
$form.Controls.Add($listBox)

$choice = $null; $openDataText = "📁 Open Data Folder..."; $openConfigText = "⚙️ Open Config Folder..."
function Update-ListBox { $filterText = $filterBox.Text; $filteredItems = $expansions | Where-Object { $_.key -like "*$filterText*" -or $_.value -like "*$filterText*" }; $listBox.BeginUpdate(); $listBox.Items.Clear(); if ([string]::IsNullOrWhiteSpace($filterText)) { $listBox.Items.Add($openDataText); $listBox.Items.Add($openConfigText) }; $listBox.Items.AddRange(($filteredItems | ForEach-Object { "$($_.key) → $($_.value) ($($_.usage))" })); $listBox.EndUpdate(); if ($listBox.Items.Count -gt 0) { $listBox.SelectedIndex = 0 } }
function Select-Item-And-Close { if ($listBox.SelectedItem) { $selectedString = $listBox.SelectedItem; switch ($selectedString) { $openDataText { Start-Process explorer.exe $dataDir; $form.DialogResult = [System.Windows.Forms.DialogResult]::Cancel; $form.Close(); return }; $openConfigText { Start-Process explorer.exe $configDir; $form.DialogResult = [System.Windows.Forms.DialogResult]::Cancel; $form.Close(); return }; default { $selectedKey = ($selectedString -split ' → ')[0].Trim(); $form.Tag = $expansions | Where-Object { $_.key -eq $selectedKey } | Select-Object -First 1; $form.DialogResult = [System.Windows.Forms.DialogResult]::OK; $form.Close() } } } }
$form.Add_Load({ for ($i = 0; $i -lt 5; $i++) { $form.Activate(); Start-Sleep -Milliseconds 20 }; $form.ActiveControl = $filterBox; Update-ListBox })
$filterBox.Add_TextChanged({ Update-ListBox })
$filterBox.Add_KeyDown({ param($s, $e); if ($e.KeyCode -eq 'Enter') { Select-Item-And-Close; $e.SuppressKeyPress = $true }; if ($e.KeyCode -eq 'Escape') { $form.Close() }; if ($e.KeyCode -eq 'Down') { if ($listBox.Items.Count -gt 0) { $listBox.SelectedIndex = ($listBox.SelectedIndex + 1) % $listBox.Items.Count }; $e.SuppressKeyPress = $true }; if ($e.KeyCode -eq 'Up') { if ($listBox.Items.Count -gt 0) { $newIndex = $listBox.SelectedIndex - 1; if ($newIndex -lt 0) { $newIndex = $listBox.Items.Count - 1 }; $listBox.SelectedIndex = $newIndex }; $e.SuppressKeyPress = $true } })
$listBox.Add_DoubleClick({ Select-Item-And-Close })
if ($form.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $choice = $form.Tag }
$form.Dispose()
if ($null -eq $choice) { return }

# --- Post-GUI Logic ---
($expansions | Where-Object { $_.key -eq $choice.key }).usage++
$jsonParts = foreach ($item in $expansions) { $escapedKey = $item.key -replace '\\', '\\' -replace '"', '\"'; $escapedValue = $item.value -replace '\\', '\\' -replace '"', '\"'; "  {`n    `"key`": `"$escapedKey`",`n    `"value`": `"$escapedValue`",`n    `"usage`": $($item.usage)`n  }" }
"[`n" + ($jsonParts -join ",`n") + "`n]" | Set-Content -Path $expFile
Start-Sleep -Milliseconds 500
[System.Windows.Forms.SendKeys]::SendWait($choice.value)