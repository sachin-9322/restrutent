; MyApp.iss (place in project root)
[Setup]
AppName=Restaurant
AppVersion=1.0.0
AppPublisher=YourCompanyName
DefaultDirName={pf}\Restaurant
DefaultGroupName=Restaurant
OutputDir=output
OutputBaseFilename=RestaurantSetup
Compression=lzma
SolidCompression=yes
PrivilegesRequired=admin
Uninstallable=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
; Use the actual debug exe path found by PowerShell:
Source: "build\windows\x64\runner\Debug\restaurant1.exe"; DestDir: "{app}"; Flags: ignoreversion

; Add other resources explicitly if needed (example):
; Source: "assets\*"; DestDir: "{app}\assets"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
Name: "{group}\Restaurant"; Filename: "{app}\restaurant1.exe"
Name: "{commondesktop}\Restaurant"; Filename: "{app}\restaurant1.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop icon"; GroupDescription: "Additional icons:"; Flags: unchecked

[Run]
Filename: "{app}\restaurant1.exe"; Description: "Launch Restaurant"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}"
