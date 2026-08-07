[Setup]
AppName=fl-client
AppVersion=0.7.0
AppPublisher=KITIK
DefaultDirName={autopf}\fl-client
DefaultGroupName=fl-client
OutputBaseFilename=fl-client-setup
OutputDir=Output
Compression=lzma2
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
WizardStyle=modern
PrivilegesRequired=admin
SourceDir=.

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "libs\windows\sing-box.exe"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\fl-client"; Filename: "{app}\fl_client.exe"
Name: "{commondesktop}\fl-client"; Filename: "{app}\fl_client.exe"

[Run]
Filename: "{app}\fl_client.exe"; Description: "Launch fl-client"; Flags: nowait postinstall skipifsilent
