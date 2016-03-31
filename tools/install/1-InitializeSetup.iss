{ Function prototypes of helper methods. }
function RevitInstallationExists(Version: String): Boolean; forward;
procedure GetRegistryValues(var productRegistry : TRegistry); forward;
procedure UninstallProduct(var productRegistry: TRegistry); forward;
function ReverseGuid(sGuid : String): String; forward;

{ Primary Method - Invoked immediately after EXE is run. }
function InitializeSetup(): Boolean;
begin
  { To check for a revit installation }
  ExtractTemporaryFile('RevitInstallDetective.exe');
  ExtractTemporaryFile('RevitAddinUtility.dll');

  result := true
  { Check if there is a valid revit installation on this machine, if not - fail }
  if not (RevitInstallationExists('Revit2017') or RevitInstallationExists('Revit2016') or RevitInstallationExists('Revit2015')) then
  begin
	MsgBox('Dynamo requires an installation of Revit 2015 or Revit 2016 or Revit 2017 in order to proceed!', mbCriticalError, MB_OK);
    result := false;
    Exit;
  end;

  { Get Registry values of existing related products. }
  DynamoCoreRegistry.productName := '{#CoreProductName} {#Major}.{#Minor}';
  GetRegistryValues(DynamoCoreRegistry);
  DynamoRevitRegistry.productName := '{#ProductName} {#Major}.{#Minor}';
  GetRegistryValues(DynamoRevitRegistry);
  OldDynamoCoreRegistry.productName := 'Dynamo {#Major}.{#Minor}';
  GetRegistryValues(OldDynamoCoreRegistry);
  
  (*MsgBox(DynamoCoreRegistry.productCode + #13#10 
         + DynamoRevitRegistry.productCode + #13#10 
         + OldDynamoCoreRegistry.productCode + #13#10 + #13#10 
         , mbInformation, MB_OK);*)
  
  { By default install both DynamoCore and DynamoRevit }
  InstallDynamoCore := true;
  InstallDynamoRevit := true;
  
  // To delete old Dynamo Revit with old UpgradeCode
  //If ((DynamoRevitRegistry.Version<>'') and (DynamoRevitRegistry.Version='1.0.0') and (DynamoRevitRegistry.revVersion < 900)) then
  //  UninstallProduct(DynamoRevitRegistry);
  
end;
//const
//  aReversePattern : Array[1..11] of Integer = (8, 4, 4, 2, 2, 2, 2, 2, 2, 2, 2);
{ Procedure to obtain registry values of the specified product type. }
{ The var keyword means that the parameter is passed by reference. }
{ http://wiki.freepascal.org/Variable_parameter }
procedure GetRegistryValues(var productRegistry : TRegistry);
var
  sTempVersion : String;
  iTempPeriodPos : Integer;
begin
  productRegistry.uninstallKey := ExpandConstant('Software\Microsoft\Windows\CurrentVersion\Uninstall\' + productRegistry.productName);
  if (NOT RegKeyExists(HKLM64, productRegistry.uninstallKey)) then
  begin
    productRegistry.uninstallKey := '';
    Exit;
  end;
  { Get Registry Values in UninstallKey }
  RegQueryStringValue(HKLM64, productRegistry.uninstallKey, 'InstallLocation', productRegistry.installLocation);
  RegQueryStringValue(HKLM64, productRegistry.uninstallKey, 'Version', productRegistry.version);
  RegQueryDWordValue(HKLM64, productRegistry.uninstallKey, 'RevVersion', productRegistry.revVersion);
  RegQueryStringValue(HKLM64, productRegistry.uninstallKey, 'UnInstallParam', productRegistry.uninstallParam);
  RegQueryStringValue(HKLM64, productRegistry.uninstallKey, 'UnInstallString', productRegistry.uninstallString);
  
  { Get Parent directory }
  // Example:
  //  installLocation       : C:\Program Files\Dynamo\Dynamo Core\1.0\
  //  productName           : Dynamo Core 1.0
  //  parentInstallLocation : C:\Program Files\Dynamo\
  productRegistry.parentInstallLocation 
    := copy(productRegistry.installLocation,1,length(productRegistry.installLocation)-length(productRegistry.productName)-2);
  
  { To obtain individual version fields }
  // (1) Find first position of '.'
  // (2) Obtain version field.
  // (3) Delete the obtained version field.
  // (4) Repeat
  sTempVersion := productRegistry.version;
  { Get MAJOR }
  iTempPeriodPos := Pos('.',sTempVersion);
  productRegistry.majorVersion := StrToInt(Copy(sTempVersion, 1, iTempPeriodPos-1));  
  Delete(sTempVersion,1,iTempPeriodPos);
  { Get MINOR }
  iTempPeriodPos := Pos('.',sTempVersion);
  productRegistry.minorVersion := StrToInt(Copy(sTempVersion, 1, iTempPeriodPos-1));  
  Delete(sTempVersion,1,iTempPeriodPos);
  { Get BUILD }
  // Need to add additional check for Old Dynamo product with Version of #.#.#.# instead of #.#.#
  iTempPeriodPos := Pos('.',sTempVersion);
  if (iTempPeriodPos = 0) then
    productRegistry.buildVersion := StrToInt(Copy(sTempVersion, 1, Length(sTempVersion)))
  else
    productRegistry.minorVersion := StrToInt(Copy(sTempVersion, 1, iTempPeriodPos-1));
    
  { Get Product Code }
  // Does not find Product Code for the Old Dynamo product 
  if (Pos('{',productRegistry.uninstallParam)<>0) then
    productRegistry.productCode := Copy(productRegistry.uninstallParam,Pos('{',productRegistry.uninstallParam),Pos('}',productRegistry.uninstallParam) - 1);
end;

function CheckUpgradeKey(dynamoCoreProductCode: String; dynamoRevitProductCode: String): Boolean;
var
  sUpgradeKey : String;
  sDynamoCoreUpgradeCode : String;
  sDynamoRevitUpgradeCode : String;
  sReverseDynamoCoreProductCode : String;
  sReverseDynamoRevitProductCode : String;
  sReverseDynamoCoreUpgradeCode : String;
  sReverseDynamoRevitUpgradeCode : String;
  sTemp : String;
begin
  { UpgradeCode Constants currently in use }
  sDynamoCoreUpgradeCode := '{584B3E06-FE7A-4341-8C22-339B00ABD58A}';
  sDynamoRevitUpgradeCode := '{E1D2382A-7EFD-4844-9664-7D84DF316B62}';
  
  { Try get Upgrade Key } 
  sReverseDynamoCoreUpgradeCode := ReverseGuid(sDynamoCoreUpgradeCode);
  sUpgradeKey := ExpandConstant('SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UpgradeCodes\' + sReverseDynamoCoreUpgradeCode);
  if (NOT RegKeyExists(HKLM64, sUpgradeKey)) then
  begin
    MsgBox(sDynamoCoreUpgradeCode + ' is not in use. This means Dynamo Core and Old Dynamo Revit is not installed.' 
       , mbInformation, MB_OK);
    Result := true;
    Exit;
  end;
  
  sReverseDynamoCoreProductCode := ReverseGuid(dynamoCoreProductCode);
  MsgBox(sReverseDynamoCoreProductCode + #13#10 
       + sReverseDynamoCoreUpgradeCode + #13#10  
       , mbInformation, MB_OK);

  // RegQueryStringValue return True if found.
  if(RegQueryStringValue(HKLM64, sUpgradeKey, sReverseDynamoCoreProductCode, sTemp)) then
  begin
    MsgBox(dynamoCoreProductCode + ' found in ' + sDynamoCoreUpgradeCode + '.  This means Dynamo Core with the same UpgradeCode is installed.' 
       , mbInformation, MB_OK);
    Result := true;
  end;
  {*
  if (RegQueryStringValue(HKLM64, sUpgradeSubkey, sReverseProductGuid, sTempGuid)) then
  begin
    MsgBox(sUpgradeSubkey + ' With ' + sReverseProductGuid + ' EXIST!' + #13#10, mbError, MB_OK);
  end;*}
end;
function ReverseGuid(sGuid : String): String;
var
  i,j,base : Integer;
  sTempReverseGuid : String;
  aReversePattern : Array[1..11] of Integer;
begin
  { Remove '-' }
  StringChangeEx(sGuid, '-', '', true);
  { Remove Brackets }
  sGuid := Copy(sGuid,2,32);
  { GUID Reversal Pattern: 8, 4, 4, 2, 2, 2, 2, 2, 2, 2, 2 }
  //http://stackoverflow.com/questions/17936064/how-can-i-find-the-upgrade-code-for-an-installed-application-in-c
  aReversePattern[1] := 8;
  aReversePattern[2] := 4;
  aReversePattern[3] := 4;
  aReversePattern[4] := 2;
  aReversePattern[5] := 2;
  aReversePattern[6] := 2;
  aReversePattern[7] := 2;
  aReversePattern[8] := 2;
  aReversePattern[9] := 2;
  aReversePattern[10] := 2;
  aReversePattern[11] := 2;
  { Reverse GUID }
  sTempReverseGuid := StringOfChar(' ',32);
  base := 0;
  for i := 1 to 11 do
  begin
    for j := 1 to aReversePattern[i] do
      sTempReverseGuid[base + j] := sGuid[base + aReversePattern[i] - j + 1];
    base := base + aReversePattern[i];
  end;    
  Result := sTempReverseGuid;
end;

{ Checks if Revit is installed in system. }
function RevitInstallationExists(Version: String): Boolean;
var 
  ResultCode: Integer;
begin
  if Exec(ExpandConstant('{tmp}\RevitInstallDetective.exe'), Version, '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
    Result := (ResultCode = 0)
  else
    MsgBox('RevitInstallDetective failed!' + #13#10 + SysErrorMessage(ResultCode), mbError, MB_OK);
end;
