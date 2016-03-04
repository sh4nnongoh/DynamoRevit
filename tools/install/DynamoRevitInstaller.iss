; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#define Major
#define Minor
#define Rev
#define Build
#define path "..\..\bin\AnyCPU\Release\Revit_2015\DynamoRevitDS.dll"
;#define ParseVersion(str path, *Major, *Minor, *Rev, *Build)
#expr ParseVersion("..\..\bin\AnyCPU\Release\Revit_2015\DynamoRevitDS.dll", Major, Minor, Rev, Build)
#define ProductName "Dynamo Revit"
#define ProductVersion Str(Major) + "." + Str(Minor) + "." + Str(Rev)
#define FullVersion GetFileVersion("..\..\bin\AnyCPU\Release\Revit2015\DynamoRevitDS.dll")

[Setup]
AppName={#ProductName}
AppPublisher={#ProductName}
AppID={{BD3E04C9-9F53-4887-9F1A-D86722C0757E}
AppCopyright=
AppPublisherURL=http://www.dynamobim.org
AppSupportURL=http://www.dynamobim.org
AppUpdatesURL=http://www.dynamobim.org
AppVersion={#ProductVersion}
VersionInfoVersion={#ProductVersion}
VersionInfoCompany={#ProductName}
VersionInfoDescription={#ProductName} {#ProductVersion}
VersionInfoTextVersion={#ProductName} {#ProductVersion}
VersionInfoCopyright=
DefaultGroupName=Dynamo
OutputDir=.\
OutputBaseFilename=InstallDynamoRevit{#ProductVersion}
SetupIconFile=..\..\..\Dynamo\doc\distrib\Images\logo_square_32x32.ico
Compression=lzma
SolidCompression=true
RestartIfNeededByRun=false
FlatComponentsList=false
ShowLanguageDialog=auto
DirExistsWarning=no
;CreateAppDir=no
DefaultDirName={pf64}\{#ProductName} {#Major}.{#Minor}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "..\..\src\DynamoRevitInstall\bin\x86\Release\DynamoRevitInstall.msi"; DestDir: "{tmp}"; Flags: ignoreversion
Source: "..\..\..\Dynamo\src\DynamoInstall\bin\x86\Release\DynamoInstall.msi"; DestDir: "{tmp}"; Flags: ignoreversion
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Run]
Filename: "msiexec.exe"; Parameters: "/i ""{tmp}\DynamoInstall.msi"""
Filename: "msiexec.exe"; Parameters: "/i ""{tmp}\DynamoRevitInstall.msi"""

[Code]
var
silentFlag : String;
updateFlag : String;

// Nothing to do with First page or any page
function InitializeSetup(): Boolean;
var
  j: Cardinal;
  sUnInstPath: String;
  sUninstallString: String;
  revision: Cardinal;
  iResultCode: Integer;
  exeVersion: String;
  sMsg: String;
  sMsg2: String;
begin
  silentFlag := ''
  updateFlag := ''
  for j := 1 to ParamCount do
    begin
      if (CompareText(ParamStr(j),'/verysilent') = 0)  then
        silentFlag := '/VERYSILENT'
      else if (CompareText(ParamStr(j),'/silent') = 0)  then
          silentFlag := '/SILENT'
      else if (CompareText(ParamStr(j),'/UPDATE') = 0) then
          updateFlag := '/UPDATE'
    end;

  // if old EXE version of 0.8.0 is installed, uninstall it
  sUnInstPath := 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{6B5FA6CA-9D69-46CF-B517-1F90C64F7C0B}_is1'
  sUnInstallString := ''
  exeVersion := ''
  RegQueryStringValue(HKLM, sUnInstPath, 'UnInstallString', sUninstallString)
  RegQueryStringValue(HKLM, sUnInstPath, 'DisplayVersion', exeVersion)
  if (sUnInstallString <> '') and (exeVersion = '0.8.0') then
	Exec(RemoveQuotes(sUnInstallString), '/VERYSILENT /NORESTART /SUPPRESSMSGBOXES /UPDATE', '', SW_HIDE, ewWaitUntilTerminated, iResultCode);

  result := true

  sUnInstPath := ExpandConstant('Software\Microsoft\Windows\CurrentVersion\Uninstall\{#ProductName} {#Major}.{#Minor}');
  sUninstallString := '';
  RegQueryStringValue(HKLM64, sUnInstPath, 'UnInstallString', sUninstallString);
    if (sUninstallString <> '') then
	begin
		if not RegQueryDWordValue(HKLM64, sUnInstPath, 'RevVersion', revision) then
			begin
				sMsg := ExpandConstant('Could not determine the revision number for already installed {#ProductName} {#Major}.{#Minor}.')
				sMsg2 := ExpandConstant('Please uninstall {#ProductName} {#Major}.{#Minor} manually, before proceeding with the installation.')
				MsgBox(sMsg + #13#10#13#10 + sMsg2, mbInformation, MB_OK);
				result := false
			end
		else if (revision > {#Rev}) then
			begin
				sMsg := ExpandConstant('A newer version of {#ProductName} {#ProductVersion} is already installed.')
				sMsg2 := ExpandConstant('Please uninstall {#ProductName} {#Major}.{#Minor}.' + IntToStr(revision) + ' manually, before proceeding with the installation.')
				MsgBox(sMsg + #13#10#13#10 + sMsg2, mbInformation, MB_OK);
				result := false
			end
	end;
end;

// Nothing to do with First page or any page
procedure CurStepChanged(CurStep: TSetupStep);
var 
  sUnInstPath: String;
  sUninstallString: String;
  sUnInstallParam: String;
  iResultCode: Integer;
begin
  if (CurStep=ssInstall) then
    begin
        sUnInstPath := ExpandConstant('Software\Microsoft\Windows\CurrentVersion\Uninstall\{#ProductName} {#Major}.{#Minor}');
        RegQueryStringValue(HKLM64, sUnInstPath, 'UnInstallString', sUninstallString);
        RegQueryStringValue(HKLM64, sUnInstPath, 'UnInstallParam', sUninstallParam);
        Exec(sUnInstallString, sUnInstallParam, '', SW_HIDE, ewWaitUntilTerminated, iResultCode);
    end;
end;