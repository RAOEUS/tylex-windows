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

    # Compile Add-Text as a windowed app to hide the console
    Write-Host "Compiling Add-Text.exe (no console)..." -ForegroundColor DarkGray
    Invoke-PS2EXE -InputFile (Join-Path $SourceDir "Add-Text.ps1") -OutputFile (Join-Path $BuildDir "Add-Text.exe") -noConsole

    # Compile Expand-Text as a console app so its output can be captured by AHK
    Write-Host "Compiling Expand-Text.exe (with console for output capture)..." -ForegroundColor DarkGray
    Invoke-PS2EXE -InputFile (Join-Path $SourceDir "Expand-Text.ps1") -OutputFile (Join-Path $BuildDir "Expand-Text.exe")

    Write-Host "Compiling AutoHotkey script..." -ForegroundColor Green
    $ahkCompiler = Get-Command Ahk2Exe.exe -ErrorAction SilentlyContinue
    if (-not $ahkCompiler) {
        Write-Error "AutoHotkey Compiler (Ahk2Exe.exe) not found. Please run '.\Build.ps1 -Target setup' as Admin."
        exit 1
    }

    # Use the exact base file path that previously worked for you.
    $ahkBaseFile = Join-Path $AhkDir "v2\AutoHotkey64.exe"

    $ahkInput = Join-Path $SourceDir $AutoHotkeyScript
    $ahkOutput = Join-Path $BuildDir ($AutoHotkeyScript -replace '.ahk$', '.exe')

    # Use the exact compiler command that previously worked for you.
    & $ahkCompiler.Source /in "`"$ahkInput`"" /out "`"$ahkOutput`"" /base "`"$ahkBaseFile`""

    Write-Host "Build complete." -ForegroundColor Cyan
}

# --- Main Logic (Targets) ---
switch ($Target) {
    "setup" {
        if (-not (Test-Admin)) {
            Write-Error "Setup requires Administrator privileges to install tools. Please re-run from an elevated PowerShell terminal."
            exit 1
        }
        Write-Host "Setting up build environment..." -ForegroundColor Yellow

        # 1. Install main AutoHotkey package
        if (Test-Path $AhkDir) {
            Write-Host "AutoHotkey seems to be installed." -ForegroundColor Gray
        } else {
            Write-Host "Installing AutoHotkey via winget..." -ForegroundColor Green
            winget install --id AutoHotkey.AutoHotkey -e --source winget --accept-package-agreements
        }
        
        # 2. Install the AHK compiler if not present
        $compilerPath = Join-Path $AhkDir "Compiler"
        if (Test-Path (Join-Path $compilerPath "Ahk2Exe.exe")) {
            Write-Host "AutoHotkey Compiler is already installed." -ForegroundColor Gray
        } else {
            Write-Host "Installing AutoHotkey Compiler..." -ForegroundColor Green
            $ahkInstallerScript = Join-Path $AhkDir "UX\install-ahk2exe.ahk"
            $ahkExe = Join-Path $AhkDir "v2\AutoHotkey.exe"
            if (Test-Path $ahkInstallerScript) {
                Write-Host "Please follow any on-screen prompts from the AHK compiler installer. Press enter when installation complete to continue." -ForegroundColor Yellow
                Start-Process -FilePath $ahkExe -ArgumentList "`"$ahkInstallerScript`"" -Wait
            } else {
                Write-Error "Could not find AHK compiler installer script. Please install manually."
            }
        }

        # 3. Add AHK Compiler to the system PATH if not already there
        $machinePath = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
        if ($machinePath -notlike "*$compilerPath*") {
            Write-Host "Adding AHK Compiler to system PATH..." -ForegroundColor Green
            $newPath = "$machinePath;$compilerPath"
            [System.Environment]::SetEnvironmentVariable('Path', $newPath, 'Machine')
            # Update current session's path as well
            $env:Path = $newPath
            Write-Host "PATH updated. Please restart your terminal after this script finishes for changes to take full effect." -ForegroundColor Yellow
        } else {
            Write-Host "AHK Compiler is already in the system PATH." -ForegroundColor Gray
        }

        # 4. Install PS2EXE PowerShell Module
        if (Get-Module -ListAvailable -Name PS2EXE) {
            Write-Host "PowerShell module 'PS2EXE' is already installed." -ForegroundColor Gray
        } else {
            Write-Host "Installing PowerShell module 'PS2EXE'..." -ForegroundColor Green
            Install-Module -Name PS2EXE -Repository PSGallery -Force -Scope CurrentUser
        }

        Write-Host "Environment setup complete. You can now run the 'build' target." -ForegroundColor Cyan
    }

    "build" { Build-Executables }

    "install" {
        if (-not (Test-Admin)) { Write-Error "Installation requires Administrator privileges."; exit 1 }
        Build-Executables
        Write-Host "Installing..." -ForegroundColor Green; Copy-Item -Path "$BuildDir\*" -Destination $InstallDir -Recurse -Force
        $shortcutPath = Join-Path ([Environment]::GetFolderPath('Startup')) "$AppName.lnk"; $targetPath = Join-Path $InstallDir "TylexLauncher.exe"
        $wshell = New-Object -ComObject WScript.Shell; $shortcut = $wshell.CreateShortcut($shortcutPath); $shortcut.TargetPath = $targetPath; $shortcut.Save()
        Write-Host "Installation complete." -ForegroundColor Cyan
    }

    "uninstall" {
        if (-not (Test-Admin)) { Write-Error "Uninstallation requires Administrator privileges."; exit 1 }
        $shortcutPath = Join-Path ([Environment]::GetFolderPath('Startup')) "$AppName.lnk"; if (Test-Path $shortcutPath) { Remove-Item $shortcutPath -Force }
        if (Test-Path $InstallDir) { Remove-Item $InstallDir -Recurse -Force }
        Write-Host "Uninstallation complete." -ForegroundColor Cyan
    }

    "winget" {
        if ([string]::IsNullOrWhiteSpace($ReleaseUrl)) { Write-Error "The -ReleaseUrl parameter is required."; exit 1 }
        Build-Executables
        $zipPath = Join-Path $ReleaseDir "$AppName-$PackageVersion.zip"; Compress-Archive -Path "$BuildDir\*" -DestinationPath $zipPath -Force
        $fileHash = (Get-FileHash $zipPath -Algorithm SHA256).Hash
        $manifestDir = Join-Path $SourceDir "winget-manifest\manifests\$($Publisher.ToLower())\$AppName\$PackageVersion"; New-Item -Path $manifestDir -ItemType Directory -Force | Out-Null
        $packageIdentifier = "$Publisher.$AppName"
        $versionYaml = @"
PackageIdentifier: $packageIdentifier
PackageVersion: $PackageVersion
DefaultLocale: en-US
ManifestType: version
ManifestVersion: 1.6.0
"@
        $installerYaml = @"
PackageIdentifier: $packageIdentifier
PackageVersion: $PackageVersion
InstallerType: zip
Installers:
- Architecture: x64
  InstallerUrl: $ReleaseUrl
  InstallerSha256: $fileHash
  NestedInstallerType: portable
  NestedInstallerFiles:
  - RelativeFilePath: TylexLauncher.exe
    PortableCommandAlias: TylexLauncher.exe
ManifestType: installer
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
