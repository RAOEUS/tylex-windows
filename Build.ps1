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

# Scripts to compile
$PowerShellScripts = @(
		"Expand-Text.ps1",
		"Add-Text.ps1"
		)
$AutoHotkeyScript = "TylexLauncher.ahk"
$InstallDir = Join-Path $env:ProgramFiles $AppName

# --- Helper Functions ---
function Test-Admin {
	$currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
		return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Build-Executables {
# (This function is the same as the previous version)
	Write-Host "Creating build directory..." -ForegroundColor Green
		if (-not (Test-Path $BuildDir)) {
			New-Item -Path $BuildDir -ItemType Directory | Out-Null
		}
	Write-Host "Compiling PowerShell scripts..." -ForegroundColor Green
		if (-not (Get-Module -ListAvailable -Name PS2EXE)) { Write-Error "Module PS2EXE is not installed. Run '.\Build.ps1 -Target setup' as Admin."; exit 1 }
	foreach ($script in $PowerShellScripts) {
		$inputFile = Join-Path $SourceDir $script
			$outputFile = Join-Path $BuildDir ($script -replace '.ps1$', '.exe')
			Invoke-PS2EXE -InputFile $inputFile -OutputFile $outputFile
	}
	Write-Host "Compiling AutoHotkey script..." -ForegroundColor Green
		$ahkCompiler = "C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe"
		if (-not (Test-Path $ahkCompiler)) { Write-Error "AutoHotkey is not installed. Run '.\Build.ps1 -Target setup' as Admin."; exit 1 }
	$ahkInput = Join-Path $SourceDir $AutoHotkeyScript
		$ahkOutput = Join-Path $BuildDir ($AutoHotkeyScript -replace '.ahk$', '.exe')
		& $ahkCompiler /in $ahkInput /out $ahkOutput
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

# 1. Install AutoHotkey using winget
			if (Test-Path "C:\Program Files\AutoHotkey\AutoHotkey.exe") {
				Write-Host "AutoHotkey is already installed." -ForegroundColor Gray
			} else {
				Write-Host "Installing AutoHotkey..." -ForegroundColor Green
					winget install --id AutoHotkey.AutoHotkey -e --source winget --accept-package-agreements
			}

# 2. Install PS2EXE PowerShell Module
		if (Get-Module -ListAvailable -Name PS2EXE) {
			Write-Host "PowerShell module 'PS2EXE' is already installed." -ForegroundColor Gray
		} else {
			Write-Host "Installing PowerShell module 'PS2EXE'..." -ForegroundColor Green
				Install-Module -Name PS2EXE -Repository PSGallery -Force
		}

		Write-Host "✅ Environment setup complete. You can now run the 'build' target." -ForegroundColor Cyan
	}

	"build" {
		Build-Executables
	}

	"install" {
		if (-not (Test-Admin)) { Write-Error "Installation requires Administrator privileges."; exit 1 }
		Build-Executables
# (Rest of install logic is the same)
			Write-Host "Installing..." -ForegroundColor Green; Copy-Item -Path "$BuildDir\*" -Destination $InstallDir -Recurse -Force
			$shortcutPath = Join-Path ([Environment]::GetFolderPath('Startup')) "$AppName.lnk"; $targetPath = Join-Path $InstallDir "TylexLauncher.exe"
			$wshell = New-Object -ComObject WScript.Shell; $shortcut = $wshell.CreateShortcut($shortcutPath); $shortcut.TargetPath = $targetPath; $shortcut.Save()
			Write-Host "Installation complete." -ForegroundColor Cyan
	}

	"uninstall" {
		if (-not (Test-Admin)) { Write-Error "Uninstallation requires Administrator privileges."; exit 1 }
# (Rest of uninstall logic is the same)
		$shortcutPath = Join-Path ([Environment]::GetFolderPath('Startup')) "$AppName.lnk"; if (Test-Path $shortcutPath) { Remove-Item $shortcutPath -Force }
		if (Test-Path $InstallDir) { Remove-Item $InstallDir -Recurse -Force }
		Write-Host "Uninstallation complete." -ForegroundColor Cyan
	}

	"winget" {
		if ([string]::IsNullOrWhiteSpace($ReleaseUrl)) { Write-Error "The -ReleaseUrl parameter is required."; exit 1 }
		Build-Executables
# (Rest of winget logic is the same)
			$zipPath = Join-Path $ReleaseDir "$AppName-$PackageVersion.zip"; Compress-Archive -Path "$BuildDir\*" -DestinationPath $zipPath -Force
			$fileHash = (Get-FileHash $zipPath -Algorithm SHA256).Hash
			$manifestDir = Join-Path $SourceDir "winget-manifest\manifests\$($Publisher.ToLower())\$AppName\$PackageVersion"; New-Item -Path $manifestDir -ItemType Directory -Force | Out-Null
			$packageIdentifier = "$Publisher.$AppName"
			$versionYaml=@"
			PackageIdentifier: $packageIdentifier
			PackageVersion: $PackageVersion
			DefaultLocale: en-US
			ManifestType: version
			ManifestVersion: 1.6.0
			"@; $installerYaml=@"
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
			"@; $localeYaml=@"
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
