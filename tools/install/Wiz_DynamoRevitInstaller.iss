; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#define MyAppName "Dynamo For Revit"
#define MyAppVersion "1.0"
#define MyAppPublisher "Autodesk Dynamo"
#define MyAppExeName "InstallDynamoRevit.exe"

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{BD3E04C9-9F53-4887-9F1A-D86722C0757E}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
CreateAppDir=no
OutputDir=.\
OutputBaseFilename=InstallDynamoRevit
SetupIconFile=..\..\..\Dynamo\doc\distrib\Images\logo_square_32x32.ico
Compression=lzma
SolidCompression=yes
Uninstallable=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "..\..\src\DynamoRevitInstall\bin\x86\Release\DynamoRevitInstall.msi"; DestDir: "{tmp}"; Flags: ignoreversion
Source: "..\..\..\Dynamo\src\DynamoInstall\bin\x86\Release\DynamoInstall.msi"; DestDir: "{tmp}"; Flags: ignoreversion
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Run]
Filename: "msiexec.exe"; Parameters: "/i ""{tmp}\DynamoInstall.msi"""
Filename: "msiexec.exe"; Parameters: "/i ""{tmp}\DynamoRevitInstall.msi"""

