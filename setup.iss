; Inno Setup Script for Tylex

[Setup]
AppName=Tylex
AppVersion=1.0.0
AppPublisher=Zach Rice
DefaultDirName={autopf}\Tylex
DefaultGroupName=Tylex
UninstallDisplayIcon={app}\TylexLauncher.exe
WizardStyle=modern
SolidCompression=yes
OutputBaseFilename=Tylex-Setup-v1.0.0

[Files]
; Bundle the compiled executables from the build folder
Source: "build\*.exe"; DestDir: "{app}"
; Bundle the default config file from the source folder
Source: "config.ini"; DestDir: "{userappdata}\Tylex"; Flags: uninsneveruninstall

[Icons]
; Create the Start Menu shortcuts
Name: "{group}\Tylex"; Filename: "{app}\TylexLauncher.exe"
Name: "{group}\Uninstall Tylex"; Filename: "{uninstallexe}"
; Create the shortcut to run the app on startup
Name: "{autostartup}\Tylex"; Filename: "{app}\TylexLauncher.exe"

[Run]
Filename: "{app}\TylexLauncher.exe"; Description: "Launch Tylex"; Flags: nowait postinstall

[Registry]
; Add the installation directory to the system PATH
Root: HKLM; Subkey: "System\CurrentControlSet\Control\Session Manager\Environment"; \
    ValueType: expandsz; ValueName: "Path"; ValueData: "{olddata};{app}"; \
    Check: NeedsAddPath('{app}')

; ✅ ADD THIS ENTIRE [CODE] SECTION
[Code]
function NeedsAddPath(Path: string): boolean;
var
  OldPath: string;
begin
  if not RegQueryStringValue(HKEY_LOCAL_MACHINE,
    'System\CurrentControlSet\Control\Session Manager\Environment',
    'Path', OldPath)
  then begin
    Result := True;
    exit;
  end;
  // Check if the path is not already present, ensuring whole-path matching
  Result := Pos(';' + LowerCase(Path) + ';', ';' + LowerCase(OldPath) + ';') = 0;
end;