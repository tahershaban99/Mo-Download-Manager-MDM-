; Mo Download Manager (MDM) — Windows installer (Inno Setup 6)
; Built automatically by BUILD.bat -> dist\MDM-Setup.exe
;
; Installs for the current user (no admin needed) into
;   %LOCALAPPDATA%\Programs\Mo Download Manager
; so yt-dlp can update itself. Adds a Start Menu folder, an optional desktop
; shortcut, "start with Windows", and a normal uninstaller.

#define MyAppName "Mo Download Manager (MDM)"
#define MyAppExe "MDM.exe"
; BUILD.bat passes the version of Cargo.toml: /DMyAppVersion=1.0.1
; the files that go into the setup (gathered by BUILD.bat / the CI)
#ifndef Stage
  #define Stage "..\build-cache\stage"
#endif
#ifndef MyAppVersion
  #define MyAppVersion "2.0.3"
#endif

[Setup]
AppId={{9D4E8B21-6C3A-4F19-A8E5-3B7D92C1E4F0}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher=Mohamed
DefaultDirName={localappdata}\Programs\Mo Download Manager
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=..\dist
OutputBaseFilename=MDM-Setup
#ifndef NoIcon
SetupIconFile=..\crates\app\icon.ico
#endif
UninstallDisplayIcon={app}\{#MyAppExe}
VersionInfoVersion={#MyAppVersion}
VersionInfoCompany=Mohamed
VersionInfoDescription=Mo Download Manager (MDM) Setup
VersionInfoProductName={#MyAppName}
VersionInfoProductVersion={#MyAppVersion}
VersionInfoCopyright=Copyright (C) 2026 Mohamed
UninstallDisplayName={#MyAppName}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "arabic"; MessagesFile: "compiler:Languages\Arabic.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"
Name: "autostart"; Description: "{cm:AutoStartDesc}"; GroupDescription: "{cm:AutoStartGroup}"

[CustomMessages]
english.AutoStartDesc=Start Mo Download Manager (MDM) when Windows starts (recommended)
english.AutoStartGroup=Startup:
english.BrowserExtFolder=Browser extension folder
english.InstallingRuntime=Installing required system files...

arabic.AutoStartDesc=تشغيل Mo Download Manager (MDM) تلقائياً مع بدء تشغيل الويندوز (موصى به)
arabic.AutoStartGroup=بدء التشغيل:
arabic.BrowserExtFolder=مجلد إضافة المتصفح
arabic.InstallingRuntime=جاري تثبيت ملفات النظام المطلوبة...

[Files]
Source: "{#Stage}\{#MyAppExe}"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#Stage}\icon.ico"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist
Source: "{#Stage}\THIRD-PARTY-NOTICES.txt"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist
; the helpers go into {app}\tools; the app updates them there by itself
Source: "{#Stage}\tools\*"; DestDir: "{app}\tools"; Flags: ignoreversion skipifsourcedoesntexist
Source: "{#Stage}\extension\*"; DestDir: "{app}\extension"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "{#Stage}\extension-firefox\*"; DestDir: "{app}\extension-firefox"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "{#Stage}\mdm-firefox.xpi"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist
; system runtime files, installed only when they are missing (see [Code])
#ifexist "..\build-cache\redist\vc_redist.x64.exe"
  #define HaveRedist
Source: "..\build-cache\redist\vc_redist.x64.exe"; DestDir: "{tmp}"; Flags: dontcopy
#endif

[InstallDelete]
; older versions kept the helpers next to the program
Type: files; Name: "{app}\yt-dlp.exe"
Type: files; Name: "{app}\ffmpeg.exe"

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExe}"; IconFilename: "{app}\icon.ico"
Name: "{group}\{cm:BrowserExtFolder}"; Filename: "{app}\extension"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"; IconFilename: "{app}\icon.ico"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExe}"; IconFilename: "{app}\icon.ico"; Tasks: desktopicon

[Registry]
; tells the app the installer already decided about "start with Windows"
Root: HKCU; Subkey: "Software\Mohamed\MDM"; ValueType: string; ValueName: "Installed"; ValueData: "1"; Flags: uninsdeletekey
; start in the background (next to the clock) when the user signs in
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "MDM"; ValueData: """{app}\{#MyAppExe}"" --background"; Flags: uninsdeletevalue; Tasks: autostart

[Run]
Filename: "{app}\{#MyAppExe}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent
; after an automatic update: start the new version again
Filename: "{app}\{#MyAppExe}"; Flags: nowait; Check: IsAutoUpdate


[UninstallRun]
Filename: "{cmd}"; Parameters: "/C taskkill /IM {#MyAppExe} /F"; Flags: runhidden; RunOnceId: "StopMDM"

[UninstallDelete]
Type: filesandordirs; Name: "{app}\extension"
Type: filesandordirs; Name: "{app}\extension-firefox"
Type: filesandordirs; Name: "{app}\tools"

[Code]
function IsAutoUpdate: Boolean;
begin
  Result := ExpandConstant('{param:AUTOUPDATE|0}') = '1';
end;

{ the Visual C++ 2015-2022 runtime (vcruntime140.dll) }
function RuntimeMissing: Boolean;
var
  Installed: Cardinal;
begin
  Result := True;
  if RegQueryDWordValue(HKLM64, 'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64', 'Installed', Installed) and (Installed = 1)
     and FileExists(ExpandConstant('{sys}\vcruntime140.dll'))
     and FileExists(ExpandConstant('{sys}\vcruntime140_1.dll'))
     and FileExists(ExpandConstant('{sys}\msvcp140.dll')) then
    Result := False;
end;

procedure InstallRuntime;
var
  Code: Integer;
begin
#ifdef HaveRedist
  if not RuntimeMissing then exit;
  { an automatic update must not show any window }
  if WizardSilent then exit;
  try
    ExtractTemporaryFile('vc_redist.x64.exe');
  except
    exit;
  end;
  WizardForm.StatusLabel.Caption := ExpandConstant('{cm:InstallingRuntime}');
  { needs administrator rights: Windows asks once. If that is refused the
    program still works, it carries its own copy of these files. }
  ShellExec('runas', ExpandConstant('{tmp}\vc_redist.x64.exe'), '/install /quiet /norestart', '', SW_HIDE, ewWaitUntilTerminated, Code);
#endif
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
    InstallRuntime;
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  Code: Integer;
  OldName: String;
  OldKey: String;
begin
  { If an earlier MDM build registered under the legacy shared AppId, remove that
    uninstall entry so Ezoo's installer will never mistake MDM's folder for its own }
  OldKey := 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{F5837666-2925-4FD9-8CE9-728BE9C5D7E4}_is1';
  if RegQueryStringValue(HKCU, OldKey, 'DisplayName', OldName) then
  begin
    if Pos('Mo Download Manager', OldName) > 0 then
      RegDeleteKeyIncludingSubkeys(HKCU, OldKey);
  end;

  { stop any running instances of MDM }
  Exec(ExpandConstant('{cmd}'), '/C taskkill /IM {#MyAppExe} >nul 2>&1', '', SW_HIDE, ewWaitUntilTerminated, Code);
  Sleep(1500);
  Exec(ExpandConstant('{cmd}'), '/C taskkill /F /IM {#MyAppExe} >nul 2>&1', '', SW_HIDE, ewWaitUntilTerminated, Code);
  Sleep(500);
  Result := '';
end;

