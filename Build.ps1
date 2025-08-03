# Build.ps1 - A Makefile-like script for the Tylex-Windows project

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet('build', 'install', 'uninstall', 'winget', 'setup')]
    [string]$Target,

    [Parameter(Position = 1)]
    [string]$ReleaseUrl,
    
    [Parameter(Position = 2)]
    [string]$PackageVersion = "1.0.0"
)

# --- Configuration ---
$AppName = "Tylex"
$Publisher = "YourGitHubUsername" # Change this!
$Author = "Your Name" # Change this!
$License = "MIT"
$LicenseUrl = "https://github.com/$Publisher/Tylex-Windows/blob/main/LICENSE" # Assumes a GitHub repo
$Description = "A simple, fast text expansion utility for Windows using PowerShell and AutoHotkey."
$Homepage = "https://github.com/$Publisher/Tylex-Windows" # Assumes a GitHub repo
$Tags = "autohotkey", "powershell", "automation", "expander", "utility"

# --- Script Paths ---
$SourceDir = $PSScriptRoot
$BuildDir = Join-Path $SourceDir "build"
$ReleaseDir = Join-Path $SourceDir "release"
$InstallDir = Join-Path $env:ProgramFiles $AppName
$AhkDir = Join-Path $env:ProgramFiles "AutoHotkey"

# Scripts to compile
$PowerShellScripts = @("Expand-Text.ps1", "Add-Text.ps1")
$AutoHotkeyScript = "TylexLauncher.ahk"

# --- Helper Functions ---
function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Build-Executables {
    Write-Host "Creating build directory..." -ForegroundColor Green
    if (-not (Test-Path $BuildDir)) { New-Item -Path $BuildDir -ItemType Directory | Out-Null }

    Write-Host "Compiling PowerShell scripts..." -ForegroundColor Green
    if (-not (Get-Module -ListAvailable -Name PS2EXE)) { Write-Error "Module PS2EXE is not installed. Run '.\Build.ps1 -Target setup' as Admin."; exit 1 }

    foreach ($script in $PowerShellScripts) {
        $inputFile = Join-Path $SourceDir $script
        $outputFile = Join-Path $BuildDir ($script -replace '.ps1$', '.exe')
        Write-Host "Compiling $script (no console)..." -ForegroundColor DarkGray
        Invoke-PS2EXE -InputFile $inputFile -OutputFile $outputFile -noConsole
    }

    Write-Host "Compiling AutoHotkey script..." -ForegroundColor Green
    $ahkCompiler = Get-Command Ahk2Exe.exe -ErrorAction SilentlyContinue
    if (-not $ahkCompiler) {
        Write-Error "AutoHotkey Compiler (Ahk2Exe.exe) not found. Please run '.\Build.ps1 -Target setup' as Admin."
        exit 1
    }
    
    $ahkBaseFile = Join-Path $AhkDir "v2\AutoHotkey64.exe"
    $ahkInput = Join-Path $SourceDir $AutoHotkeyScript
    $ahkOutput = Join-Path $BuildDir ($AutoHotkeyScript -replace '.ahk$', '.exe')
    
    & $ahkCompiler.Source /in "`"$ahkInput`"" /out "`"$ahkOutput`"" /base "`"$ahkBaseFile`""
    
    Write-Host "Build complete." -ForegroundColor Cyan

    # ✅ NEW: Automatically build the Inno Setup installer
    $iscc = Get-Command ISCC.exe -ErrorAction SilentlyContinue
    if (-not $iscc) {
        Write-Error "Inno Setup Compiler (ISCC.exe) not found. Please install Inno Setup and ensure it's in your PATH."
        exit 1
    }
    Write-Host "Building installer package..." -ForegroundColor Green
    & $iscc.Source "setup.iss"
}

# --- Main Logic (Targets) ---
switch ($Target) {
  "setup" {
        if (-not (Test-Admin)) {
            Write-Error "Setup requires Administrator privileges to install tools. Please re-run from an elevated PowerShell terminal."
            exit 1
        }
        Write-Host "Setting up build environment..." -ForegroundColor Yellow

        # 1 & 2. Install AutoHotkey and its compiler
        if (Test-Path $AhkDir) { Write-Host "AutoHotkey seems to be installed." -ForegroundColor Gray } 
        else { Write-Host "Installing AutoHotkey via winget..."; winget install --id AutoHotkey.AutoHotkey -e --source winget --accept-package-agreements }
        $compilerPath = Join-Path $AhkDir "Compiler"; if (Test-Path (Join-Path $compilerPath "Ahk2Exe.exe")) { Write-Host "AutoHotkey Compiler is already installed." -ForegroundColor Gray }
        else { Write-Host "Installing AutoHotkey Compiler..."; $ahkInstallerScript = Join-Path $AhkDir "UX\install-ahk2exe.ahk"; $ahkExe = Join-Path $AhkDir "v2\AutoHotkey.exe"; if (Test-Path $ahkInstallerScript) { Start-Process -FilePath $ahkExe -ArgumentList "`"$ahkInstallerScript`"" -Wait } else { Write-Error "Could not find AHK compiler installer script." } }

        # 3. Add AHK Compiler to PATH
        $machinePath = [System.Environment]::GetEnvironmentVariable('Path', 'Machine'); if ($machinePath -notlike "*$compilerPath*") { Write-Host "Adding AHK Compiler to system PATH..."; $newPath = "$machinePath;$compilerPath"; [System.Environment]::SetEnvironmentVariable('Path', $newPath, 'Machine'); $env:Path = $newPath }

        # 4. Install PS2EXE PowerShell Module
        if (Get-Module -ListAvailable -Name PS2EXE) { Write-Host "PowerShell module 'PS2EXE' is already installed." -ForegroundColor Gray } 
        else { Write-Host "Installing PowerShell module 'PS2EXE'..."; Install-Module -Name PS2EXE -Repository PSGallery -Force -Scope CurrentUser }

        # ✅ 5. Manually Define Inno Setup Path and Add to Environment
        # Using the correct path you found
        $innoDir = "C:\Users\Zach\AppData\Local\Programs\Inno Setup 6"
        
        Write-Host "Using Inno Setup path: $innoDir" -ForegroundColor Cyan

        # Add the Inno Setup path to the system PATH
        $machinePath = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
        if ($machinePath -notlike "*$innoDir*") {
            Write-Host "Adding '$innoDir' to system PATH..." -ForegroundColor Green
            $newPath = "$machinePath;$innoDir"
            [System.Environment]::SetEnvironmentVariable('Path', $newPath, 'Machine')
            $env:Path = $newPath
        } else {
            Write-Host "Inno Setup is already in the system PATH." -ForegroundColor Gray
        }

        Write-Host "✅ Environment setup complete. Please restart your terminal, then run the 'build' target." -ForegroundColor Cyan
    }

    "build" { Build-Executables }

"install" {
        if (-not (Test-Admin)) { Write-Error "Installation requires Administrator privileges."; exit 1 }
        Build-Executables
        
        Write-Host "Creating installation directory at '$InstallDir'..." -ForegroundColor Green
        New-Item -Path $InstallDir -ItemType Directory -Force | Out-Null
        
        Write-Host "Copying application files..." -ForegroundColor Green
        Copy-Item -Path "$BuildDir\*" -Destination $InstallDir -Recurse -Force

        Write-Host "Adding installation directory to system PATH..." -ForegroundColor Green
        $machinePath = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
        if ($machinePath -notlike "*$InstallDir*") {
            $newPath = "$machinePath;$InstallDir"
            [System.Environment]::SetEnvironmentVariable('Path', $newPath, 'Machine')
            $env:Path = $newPath
        }
        
        # ✅ Create user config directory and copy default config.ini
        Write-Host "Setting up user configuration..." -ForegroundColor Green
        $userConfigDir = Join-Path $env:APPDATA $AppName
        New-Item -Path $userConfigDir -ItemType Directory -Force | Out-Null
        $destConfigFile = Join-Path $userConfigDir "config.ini"
        if (-not (Test-Path $destConfigFile)) {
            Write-Host "Copying default config.ini to '$userConfigDir'..." -ForegroundColor DarkGray
            Copy-Item -Path (Join-Path $SourceDir "config.ini") -Destination $destConfigFile
        }

        # Create Startup shortcut for auto-launch
        Write-Host "Creating startup shortcut..." -ForegroundColor Green
        $startupShortcutPath = Join-Path ([Environment]::GetFolderPath('Startup')) "$AppName.lnk"
        $targetPath = Join-Path $InstallDir "TylexLauncher.exe"
        $wshell = New-Object -ComObject WScript.Shell
        $shortcut = $wshell.CreateShortcut($startupShortcutPath)
        $shortcut.TargetPath = $targetPath
        $shortcut.Save()

        # Create Start Menu shortcut for visibility
        Write-Host "Creating Start Menu entry..." -ForegroundColor Green
        $startMenuPath = Join-Path ([System.Environment]::GetFolderPath('Programs')) $AppName
        New-Item -Path $startMenuPath -ItemType Directory -Force | Out-Null
        $startMenuShortcutPath = Join-Path $startMenuPath "$AppName Launcher.lnk"
        if (-not (Test-Path $startMenuShortcutPath)) {
            $shortcut = $wshell.CreateShortcut($startMenuShortcutPath)
            $shortcut.TargetPath = $targetPath
            $shortcut.Save()
        }
        
        Write-Host "✅ Installation complete! Users can edit their hotkeys in %APPDATA%\Tylex\config.ini" -ForegroundColor Cyan
    }

    "uninstall" {
        if (-not (Test-Admin)) { Write-Error "Uninstallation requires Administrator privileges."; exit 1 }
        # Remove Startup Shortcut
        $shortcutPath = Join-Path ([Environment]::GetFolderPath('Startup')) "$AppName.lnk"; if (Test-Path $shortcutPath) { Remove-Item $shortcutPath -Force }
        # ✅ Remove Start Menu Shortcut and Folder
        $startMenuPath = Join-Path ([System.Environment]::GetFolderPath('Programs')) $AppName; if (Test-Path $startMenuPath) { Remove-Item $startMenuPath -Recurse -Force }
        # Remove Installation Directory
        if (Test-Path $InstallDir) { Remove-Item $InstallDir -Recurse -Force }
        Write-Host "Uninstallation complete." -ForegroundColor Cyan
    }

"winget" {
    # This target no longer needs to build. It just generates the manifest.
    if ([string]::IsNullOrWhiteSpace($ReleaseUrl)) { Write-Error "The -ReleaseUrl parameter is required."; exit 1 }
    
    # Get the installer from the 'Output' sub-directory created by Inno Setup
    $installerName = "Tylex-Setup-v$($PackageVersion).exe"
    $installerPath = Join-Path $SourceDir "Output\$($installerName)"
    if (-not (Test-Path $installerPath)) { Write-Error "Installer not found at '$installerPath'. Run the 'build' target first." ; exit 1}

    $fileHash = (Get-FileHash $installerPath -Algorithm SHA256).Hash
    $manifestDir = Join-Path $SourceDir "winget-manifest\manifests\$($Publisher.ToLower())\$AppName\$PackageVersion"; New-Item -Path $manifestDir -ItemType Directory -Force | Out-Null
    $packageIdentifier = "$Publisher.$AppName"
    
    # ✅ Updated YAML to specify the installer type is 'inno'
    $installerYaml = @"
PackageIdentifier: $packageIdentifier
PackageVersion: $PackageVersion
InstallerType: inno
Installers:
- Architecture: x64
  InstallerUrl: $ReleaseUrl
  InstallerSha256: $fileHash
ManifestType: installer
ManifestVersion: 1.6.0
"@

    # (The rest of the winget target is the same)
    $versionYaml = @"
PackageIdentifier: $packageIdentifier
PackageVersion: $PackageVersion
DefaultLocale: en-US
ManifestType: version
ManifestVersion: 1.6.0
"@
    $localeYaml = @"
PackageIdentifier: $packageIdentifier
PackageVersion: $PackageVersion
PackageLocale: en-US
Publisher: $Publisher
Author: $Author
PackageName: $AppName
PackageUrl: $Homepage
License: $License
LicenseUrl: $LicenseUrl
ShortDescription: $Description
Tags:
$($Tags | ForEach-Object { " - $_" })
ManifestType: defaultLocale
ManifestVersion: 1.6.0
"@
    Set-Content -Path (Join-Path $manifestDir "$packageIdentifier.yaml") -Value $versionYaml
    Set-Content -Path (Join-Path $manifestDir "$packageIdentifier.installer.yaml") -Value $installerYaml
    Set-Content -Path (Join-Path $manifestDir "$packageIdentifier.locale.en-US.yaml") -Value $localeYaml
    Write-Host "Winget manifest created successfully." -ForegroundColor Cyan
}
}