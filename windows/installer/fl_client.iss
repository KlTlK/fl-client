[Setup]
AppName=fl-client
AppVersion=0.8.0
AppPublisher=KITIK
DefaultDirName={autopf}\fl-client
DefaultGroupName=fl-client
OutputBaseFilename=fl-client-setup
OutputDir=Output
Compression=lzma2/max
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
WizardStyle=modern
PrivilegesRequired=admin

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create desktop shortcut"; GroupDescription: "Additional icons:"; Flags: unchecked

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\fl-client"; Filename: "{app}\fl_client.exe"
Name: "{autodesktop}\fl-client"; Filename: "{app}\fl_client.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\fl_client.exe"; Description: "Launch fl-client"; Flags: nowait postinstall skipifsilent
