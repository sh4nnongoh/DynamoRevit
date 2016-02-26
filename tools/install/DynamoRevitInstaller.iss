[Setup]
AppName=Dynamo For Revit
AppVersion=1.0
DefaultDirName={pf}\Dynamo\DynamoRevit
DefaultGroupName=Dynamo
Uninstallable=no
CreateAppDir=no

[Files]
Source: temp\DynamoInstall.msi; DestDir: {tmp}
Source: temp\DynamoRevitInstall.msi; DestDir: {tmp}

[Run]
Filename: "msiexec.exe"; Parameters: "/i ""{tmp}\DynamoInstall.msi"""
Filename: "msiexec.exe"; Parameters: "/i ""{tmp}\DynamoRevitInstall.msi"""