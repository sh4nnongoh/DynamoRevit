#define Major
#define Minor
#define Build
#define Rev
#expr ParseVersion("..\..\..\Dynamo\bin\AnyCPU\Release\Revit_2017\DynamoRevitDS.dll", Major, Minor, Build, Rev)
#define ProductName "Dynamo Revit"
#define CoreProductName "Dynamo Core"
#define ProductVersion Str(Major) + "." + Str(Minor) + "." + Str(Build)
#define FullVersion Str(Major) + "." + Str(Minor) + "." + Str(Build) + "." + Str(Rev)
#define DynamoTools "..\..\..\Dynamo\tools"

[Setup]
AppName={#ProductName}
AppPublisher={#ProductName}
AppID={{BD3E04C9-9F53-4887-9F1A-D86722C0757E}
AppCopyright=
AppPublisherURL=http://www.dynamobim.org
AppSupportURL=http://www.dynamobim.org
AppUpdatesURL=http://www.dynamobim.org
AppVersion={#FullVersion}
VersionInfoVersion={#FullVersion}
VersionInfoCompany={#ProductName}
VersionInfoDescription={#ProductName} {#ProductVersion}
VersionInfoTextVersion={#ProductName} {#ProductVersion}
VersionInfoCopyright=
DefaultGroupName=Dynamo
OutputDir=.\
OutputBaseFilename=DynamoRevit{#ProductVersion}
SetupIconFile=.\Extra\DynamoInstaller.ico
Compression=lzma
SolidCompression=true
RestartIfNeededByRun=false
FlatComponentsList=false
ShowLanguageDialog=auto
DirExistsWarning=no
DisableDirPage=no
DefaultDirName={pf64}\Dynamo
Uninstallable = no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
;Needed before installation guaranteed to be complete
Source: "{#DynamoTools}\install\Extra\RevitInstallDetective.exe"; Flags: dontcopy
Source: "{#DynamoTools}\install\Extra\RevitAddinUtility.dll"; Flags: dontcopy
Source: "{#DynamoTools}\install\Installers\DynamoRevit.msi"; DestDir: {tmp}; Flags: ignoreversion
Source: "{#DynamoTools}\install\Installers\DynamoCore.msi"; DestDir: {tmp}; Flags: ignoreversion
;DirectX
Source: "{#DynamoTools}\install\Extra\DirectX\*.*"; DestDir: {tmp}\DirectX;
;IronPython-2
Source: "{#DynamoTools}\install\Extra\IronPython-2.7.3.msi"; DestDir: {tmp}; Flags: deleteafterinstall;
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Run]
Filename: "msiexec.exe"; Parameters: "/i ""{tmp}\IronPython-2.7.3.msi"" /qn"; WorkingDir: {tmp};
Filename: "{tmp}\DirectX\dxsetup.exe"; Parameters: "/silent"; WorkingDir: {tmp};
; Install Dynamo Core
Filename: "msiexec.exe"; Parameters: "/i \
                                     ""{tmp}\DynamoCore.msi"" \
                                     /l* DynamoCore.log \
                                     INSTALLDIR=""{code:DynamoCoreInstallPath}"" \
                                     /q"; \
                         WorkingDir: {tmp}; \
                         StatusMsg: Installing Dynamo Core; \
                         Check: CheckInstallDynamoCore;

; Install Dynamo Revit
Filename: "msiexec.exe"; Parameters: "/i \
                                     ""{tmp}\DynamoRevit.msi"" \
                                     /l* DynamoRevit.log \
                                     INSTALLDIR=""{code:DynamoRevitInstallPath}"" \
                                     SELECT_REVIT_2015=""{code:CheckRevit2015}"" \
                                     SELECT_REVIT_2016=""{code:CheckRevit2016}"" \
                                     SELECT_REVIT_2017=""{code:CheckRevit2017}"" \
                                     SELECT_SAMPLES=""{code:CheckSamples}"" \
                                     ADSK_SETUP_EXE=""1"" \
                                     /q"; \
                         WorkingDir: {tmp}; \
                         StatusMsg: Installing Dynamo Revit; \
                         Check: CheckInstallDynamoRevit;
                         
Filename: "{code:DynamoRevitInstallPath}\{#CoreProductName}\{#Major}.{#Minor}\README.txt"; \
                         Flags: shellexec ; \
                         Check: CheckReadMe;

[CustomMessages]
ComponentsFormCaption =Select Components
ComponentsFormDescription =Which components should be installed?
ComponentsFormLabelCaption1 =Select the components you want to install; clear the components you do not want to install. Click Next when you are ready to continue.
ComponentsFormCheckBoxCaption1 =Dynamo Core
ComponentsFormCheckBoxCaption2 =Dynamo Revit 2015
ComponentsFormCheckBoxCaption3 =Dynamo Revit 2016
ComponentsFormCheckBoxCaption4 =Dynamo Revit 2017
ComponentsFormCheckBoxCaption5 =Dynamo Training Files

[Code]
// GLOBAL VARIABLES ................................................................. //
type
  TRegistry = record
  productName           : String;
  uninstallKey          : String;
  installLocation       : String;
  parentInstallLocation : String;
  uninstallParam        : String;
  uninstallString       : String;
  productCode           : String;
  version               : String;
  majorVersion          : Cardinal;
  minorVersion          : Cardinal;
  buildVersion          : Cardinal;
  revVersion            : Cardinal;
end;

var
  // Variables containing install directory.
  DynamoCoreDirectory   : String;
  DynamoRevitDirectory  : String;
  // Flags determining to install the product or not.
  InstallDynamoCore     : Boolean;
  InstallDynamoRevit    : Boolean;
  // Flags to uninstall existing Dynamo Core/Revit
  UninstallDynamoRevit  : Boolean;
  UninstallDynamoCore   : Boolean;
  // Variables containing registry values of existing installed product.
  DynamoCoreRegistry    : TRegistry;
  DynamoRevitRegistry   : TRegistry;
  OldDynamoCoreRegistry : TRegistry;

// VARIOUS INSTALL STAGES
#include "1-InitializeSetup.iss"
#include "2-ComponentSelection.iss"
#include "3-PreInstall.iss"

/// SCRIPTED CONSTANTS & CHECK FUNCTIONS
/// These functions are called from the [Run] section of the script.
function CheckRevit2015(Value: string): String;
begin
  Result := '0';
  if (DynamoRevit2015CheckBox.Checked) then
    Result := '1';
  Log('CheckRevit2015 = ' + Result);
end;
function CheckRevit2016(Value: string): String;
begin
  Result := '0';
  if (DynamoRevit2016CheckBox.Checked) then
    Result := '1';
  Log('CheckRevit2016 = ' + Result);
end;
function CheckRevit2017(Value: string): String;
begin
  Result := '0';
  if (DynamoRevit2017CheckBox.Checked) then
    Result := '1';
  Log('CheckRevit2017 = ' + Result);
end;
function CheckSamples(Value: string): String;
begin
  Result := '0';
  if (SamplesCheckBox.Checked) then
    Result := '1';
  Log('CheckSamples = ' + Result);
end;

function DynamoCoreInstallPath(Value: string): String;
begin
  Result := DynamoCoreDirectory;
  Log('DynamoCoreInstallPath = ' + Result);
end;
function DynamoRevitInstallPath(Value: string): String;
begin
  Result := DynamoRevitDirectory;
  Log('DynamoRevitInstallPath = ' + Result);
end;

function CheckInstallDynamoCore: Boolean;
begin
  Result := InstallDynamoCore;
  Log('CheckInstallDynamoCore = ' + IntToStr(Integer(Result)));
end;
function CheckInstallDynamoRevit: Boolean;
begin
  Result := InstallDynamoRevit;
  Log('CheckInstallDynamoRevit = ' + IntToStr(Integer(Result)));
end;

function CheckReadMe: Boolean;
begin
  Result := False;
  //if (WizardForm.ComponentsList.Checked[5]) then
  //  Result := True;
end;
function CheckLaunchDynamo: Boolean;
begin
  Result := False;
  //if (WizardForm.ComponentsList.Checked[6]) then
   // Result := True;
end;