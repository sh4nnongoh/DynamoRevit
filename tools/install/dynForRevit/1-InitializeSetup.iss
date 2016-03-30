// Function prototypes of helper methods.
function RevitInstallationExists(Version: String): Boolean; forward;
procedure GetRegistryValues(var productRegistry : TRegistry); forward;

/// Primary Method
/// Invoked immediately after EXE is run.
function InitializeSetup(): Boolean;
begin
  // To check for a revit installation
  ExtractTemporaryFile('RevitInstallDetective.exe');
  ExtractTemporaryFile('RevitAddinUtility.dll');

  result := true
  // Check if there is a valid revit installation on this machine, if not - fail
  if not (RevitInstallationExists('Revit2017') or RevitInstallationExists('Revit2016') or RevitInstallationExists('Revit2015')) then
  begin
	MsgBox('Dynamo requires an installation of Revit 2015 or Revit 2016 or Revit 2017 in order to proceed!', mbCriticalError, MB_OK);
    result := false;
    Exit;
  end;

  // Get Registry values of existing related products.
  DynamoCoreRegistry.productName := '{#CoreProductName} {#Major}.{#Minor}';
  GetRegistryValues(DynamoCoreRegistry);
  DynamoRevitRegistry.productName := '{#ProductName} {#Major}.{#Minor}';
  GetRegistryValues(DynamoRevitRegistry);
  OldDynamoCoreRegistry.productName := 'Dynamo {#Major}.{#Minor}';
  GetRegistryValues(OldDynamoCoreRegistry);
  
  // By default install both DynamoCore and DynamoRevit
  InstallDynamoCore := true;
  InstallDynamoRevit := true;
  
  //http://stackoverflow.com/questions/17936064/how-can-i-find-the-upgrade-code-for-an-installed-application-in-c
end;

/// Procedure to obtain registry values of the specified product type.
/// The var keyword means that the parameter is passed by reference.
/// http://wiki.freepascal.org/Variable_parameter
procedure GetRegistryValues(var productRegistry : TRegistry);
var
  sTempVersion : String;
  iTempPeriodPos : Integer;
begin
  productRegistry.uninstallPath := ExpandConstant('Software\Microsoft\Windows\CurrentVersion\Uninstall\' + productRegistry.productName);
  RegQueryStringValue(HKLM64, productRegistry.uninstallPath, 'InstallLocation', productRegistry.installLocation);
  if (productRegistry.installLocation='') then
  begin
    productRegistry.uninstallPath := '';
    Exit;
  end;
  RegQueryStringValue(HKLM64, productRegistry.uninstallPath, 'Version', productRegistry.version);
  RegQueryDWordValue(HKLM64, productRegistry.uninstallPath, 'RevVersion', productRegistry.revVersion);
  RegQueryStringValue(HKLM64, productRegistry.uninstallPath, 'UnInstallParam', productRegistry.uninstallParam);
  RegQueryStringValue(HKLM64, productRegistry.uninstallPath, 'UnInstallString', productRegistry.uninstallString);
  
  // Get Parent directory.
  // Example:
  //    installLocation       : C:\Program Files\Dynamo\Dynamo Core\1.0\
  //    productName           : Dynamo Core 1.0
  //    parentInstallLocation : C:\Program Files\Dynamo\
  productRegistry.parentInstallLocation 
    := copy(productRegistry.installLocation,1,length(productRegistry.installLocation)-length(productRegistry.productName)-2);
  
  // To obtain individual version fields.
  // (1) Find first position of '.'
  // (2) Obtain version field.
  // (3) Delete the obtained version field.
  // (4) Repeat
  sTempVersion := productRegistry.version;
  // Get MAJOR
  iTempPeriodPos := Pos('.',sTempVersion);
  productRegistry.majorVersion := StrToInt(Copy(sTempVersion, 1, iTempPeriodPos-1));  
  Delete(sTempVersion,1,iTempPeriodPos);
  // Get MINOR
  iTempPeriodPos := Pos('.',sTempVersion);
  productRegistry.minorVersion := StrToInt(Copy(sTempVersion, 1, iTempPeriodPos-1));  
  Delete(sTempVersion,1,iTempPeriodPos);
  // Get BUILD
  productRegistry.buildVersion := StrToInt(Copy(sTempVersion, 1, Length(sTempVersion)));
end;

/// Checks if Revit is installed in system.
function RevitInstallationExists(Version: String): Boolean;
var 
  ResultCode: Integer;
begin
  if Exec(ExpandConstant('{tmp}\RevitInstallDetective.exe'), Version, '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
    Result := (ResultCode = 0)
  else
    MsgBox('RevitInstallDetective failed!' + #13#10 + SysErrorMessage(ResultCode), mbError, MB_OK);
end;
