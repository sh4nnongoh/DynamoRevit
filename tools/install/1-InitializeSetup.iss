{ Function prototypes of helper methods. }
function RevitInstallationExists(Version: String): Boolean; forward;
procedure GetRegistryValues(var productRegistry : TRegistry); forward;
function ReverseGuid(sGuid : String): String; forward;
procedure CheckUpgradeCodes(dynamoCoreRegistry : TRegistry; dynamoRevitRegistry : TRegistry); forward;
function NewerVersionExist(product : TRegistry) : Boolean; forward;
function SameVersionExist(product : TRegistry) : Boolean; forward;

{ Primary Method - Invoked immediately after EXE is run. }
function InitializeSetup(): Boolean;
var
  sUpgradeKey                     : String;
  sReverseDynamoRevitProductCode  : String;
  sTemp                           : String;
begin
  result := True
  
  // To check for a revit installation 
  ExtractTemporaryFile('RevitInstallDetective.exe');
  ExtractTemporaryFile('RevitAddinUtility.dll');
  
  // Check if there is a valid revit installation on this machine, if not - fail
  if not (RevitInstallationExists('Revit2017') or RevitInstallationExists('Revit2016') or RevitInstallationExists('Revit2015')) then
  begin
	MsgBox('Dynamo requires an installation of Revit 2015 or Revit 2016 or Revit 2017 in order to proceed!', mbCriticalError, MB_OK);
    result := True;
    //Exit;
  end;

  // Get Registry values of existing related products.
  DynamoCoreRegistry.productName := '{#CoreProductName} {#Major}.{#Minor}';
  GetRegistryValues(DynamoCoreRegistry);
  DynamoRevitRegistry.productName := '{#ProductName} {#Major}.{#Minor}';
  GetRegistryValues(DynamoRevitRegistry);
  OldDynamoCoreRegistry.productName := 'Dynamo {#Major}.{#Minor}';
  GetRegistryValues(OldDynamoCoreRegistry);
  
  // By default install both DynamoCore and DynamoRevit
  InstallDynamoCore := True;
  InstallDynamoRevit := True;
  
  // If Old Dynamo Revit with wrong UpgradeCode is installed, it will be set to True.
  // If Dynamo Core/Revit already installed with same product version, it will be set to True.
  UninstallDynamoRevit := False;
  UninstallDynamoCore := False;
  
  // (1) Newer Dynamo Core installed. InstallDynamoCore := False;
  // (2) Newer Dynamo Revit installed. InstallDynamoRevit := False;
  // (3) Dynamo Core with same product version already installed. UninstallDynamoCore := True;
  // (4) Dynamo Revit with same product version already installed. UninstallDynamoRevit := True;
  //CheckUpgradeCodes(DynamoCoreRegistry, DynamoRevitRegistry);
  
  // Let user know of newer versions already installed.
  if ((InstallDynamoCore=False) and (InstallDynamoRevit=False)) then
  begin
    MsgBox('Newer versions of Dynamo Core & Dynamo Revit already installed! Exiting Setup...', mbCriticalError, MB_OK);
    result := False;
    Exit;
  end
  else if (InstallDynamoCore=False) then
  begin
    MsgBox('Newer version of Dynamo Core already installed! It will not be installed.', mbInformation, MB_OK);
  end
  else if (InstallDynamoRevit=False) then
  begin
    MsgBox('Newer version of Dynamo Revit already installed! It will not be installed.', mbInformation, MB_OK);
  end
  
  // Compare Revision field
  // Double checks with user if want to uninstall or not if a higher revision is installed.
  // sTemp will contain the Display String which will be displayed in the Popup box.
  sTemp := '';
  if ( ( UninstallDynamoCore and UninstallDynamoRevit )
      and ( DynamoCoreRegistry.revVersion > StrToInt('{#Rev}') ) 
      and ( DynamoRevitRegistry.revVersion > StrToInt('{#Rev}') )) then
    sTemp := DynamoCoreRegistry.productName + ' & ' + DynamoRevitRegistry.productName
  else if ( UninstallDynamoCore
          and ( DynamoCoreRegistry.revVersion > StrToInt('{#Rev}') )) then
    sTemp := DynamoCoreRegistry.productName
  else if ( UninstallDynamoRevit
          and ( DynamoRevitRegistry.revVersion > StrToInt('{#Rev}') )) then
    sTemp := DynamoRevitRegistry.productName;
    
  // As long as user clicks no, Setup will end.
  if ( ( sTemp <> '' )
      and ( MsgBox('A newer Revision of ' + sTemp + ' is already installed.'
              + #13#10#13#10 + 'Do you wish to uninstall it?'
              + #13#10#13#10 + 'Choosing "No" will end the setup.'
              , mbError, MB_YESNO) = IDNO )) then
  begin
      result := False;
      Exit;
  end;
  
  { This section will be deleted before release. }
  // Check for Old Dynamo Revit
  // Check UpgradeCode for Old Dynamo Revit with the same Dynamo Core UpgradeCode.   
  if ((not UninstallDynamoRevit) and (DynamoRevitRegistry.uninstallKey<>'')) then
  begin
    sReverseDynamoRevitProductCode := ReverseGuid('{#DynamoCoreUpgradeCode}');
    sUpgradeKey := ExpandConstant('SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UpgradeCodes\' + sReverseDynamoRevitProductCode);
    if(RegQueryStringValue(HKLM64, sUpgradeKey, sReverseDynamoRevitProductCode, sTemp)) then
    begin
      MsgBox(dynamoRevitRegistry.productCode + ' found in ' + '{#DynamoCoreUpgradeCode}' 
            + '.  This means Old Dynamo Revit with the old UpgradeCode is installed.' 
            + #13#10#13#10 + 'The existing Dynamo Revit will be uninstalled.' 
         , mbError, MB_OK);
      // Since Old Dynamo Revit found, uninstall it.
      UninstallDynamoRevit := True;
    end;
  end;
end;

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
  // Get Registry Values in UninstallKey
  RegQueryStringValue(HKLM64, productRegistry.uninstallKey, 'InstallLocation', productRegistry.installLocation);
  RegQueryStringValue(HKLM64, productRegistry.uninstallKey, 'Version', productRegistry.version);
  RegQueryDWordValue(HKLM64, productRegistry.uninstallKey, 'RevVersion', productRegistry.revVersion);
  RegQueryStringValue(HKLM64, productRegistry.uninstallKey, 'UnInstallParam', productRegistry.uninstallParam);
  RegQueryStringValue(HKLM64, productRegistry.uninstallKey, 'UnInstallString', productRegistry.uninstallString);
  
  // Get Parent directory
  // Example:
  //  installLocation       : C:\Program Files\Dynamo\Dynamo Core\1.0\
  //  productName           : Dynamo Core 1.0
  //  parentInstallLocation : C:\Program Files\Dynamo\
  productRegistry.parentInstallLocation 
    := copy(productRegistry.installLocation,1,length(productRegistry.installLocation)-length(productRegistry.productName)-2);
  
  // To obtain individual version fields
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
  // Need to add additional check for Old Dynamo product with Version of #.#.#.# instead of #.#.#
  iTempPeriodPos := Pos('.',sTempVersion);
  if (iTempPeriodPos = 0) then
    productRegistry.buildVersion := StrToInt(Copy(sTempVersion, 1, Length(sTempVersion)))
  else
    productRegistry.minorVersion := StrToInt(Copy(sTempVersion, 1, iTempPeriodPos-1));
    
  // Get Product Code
  // Does not find Product Code for the Old Dynamo product 
  if (Pos('{',productRegistry.uninstallParam)<>0) then
    productRegistry.productCode := Copy(productRegistry.uninstallParam,Pos('{',productRegistry.uninstallParam),Pos('}',productRegistry.uninstallParam) - 1);
end;

{ Inspects existing products' UpgradeCode }
procedure CheckUpgradeCodes(dynamoCoreRegistry : TRegistry; dynamoRevitRegistry : TRegistry);
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
  // UpgradeCode GUIDs currently in use
  sDynamoCoreUpgradeCode := '{#DynamoCoreUpgradeCode}';
  sDynamoRevitUpgradeCode := '{#DynamoRevitUpgradeCode}';
  
  // Obtain the Reverse GUIDs
  sReverseDynamoCoreProductCode := ReverseGuid(dynamoCoreRegistry.productCode);
  sReverseDynamoRevitProductCode := ReverseGuid(dynamoRevitRegistry.productCode);
  sReverseDynamoCoreUpgradeCode := ReverseGuid('{#DynamoCoreUpgradeCode}');
  sReverseDynamoRevitUpgradeCode := ReverseGuid('{#DynamoRevitUpgradeCode}');
  
  // Try get Upgrade Key for Dynamo Core  
  if (dynamoCoreRegistry.uninstallKey<>'') then
  begin
    sUpgradeKey := ExpandConstant('SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UpgradeCodes\' + sReverseDynamoCoreUpgradeCode);
    if (RegKeyExists(HKLM64, sUpgradeKey)) then
    begin
      // Check UpgradeCode for Dynamo Core.
      if(RegQueryStringValue(HKLM64, sUpgradeKey, sReverseDynamoCoreProductCode, sTemp)) then
      begin
        MsgBox(dynamoCoreRegistry.productCode + ' found in ' + '{#DynamoCoreUpgradeCode}' + '.  This means Dynamo Core with the same UpgradeCode is installed.' 
           , mbInformation, MB_OK);
        // Since UpgradeCode the same, compare versions.
        if (NewerVersionExist(dynamoCoreRegistry)) then
          InstallDynamoCore := False
        else if (SameVersionExist(dynamoCoreRegistry)) then
          UninstallDynamoCore := True;
      end;
      (*
      // Check UpgradeCode for Old Dynamo Revit with the same Dynamo Core UpgradeCode.   
      if(RegQueryStringValue(HKLM64, sUpgradeKey, sReverseDynamoRevitProductCode, sTemp)) then
      begin
        MsgBox(dynamoRevitRegistry.productCode + ' found in ' + '{#DynamoCoreUpgradeCode}' + '.  This means Old Dynamo Revit with the old UpgradeCode is installed.' 
           , mbInformation, MB_OK);
        // Since Old Dynamo Revit found, uninstall it.
        UninstallDynamoRevit := True;
      end;*)
    end
    else
    begin
      MsgBox('{#DynamoCoreUpgradeCode}' + ' is not in use. This means Dynamo Core and Old Dynamo Revit is not installed.' 
         , mbInformation, MB_OK);
    end;
  end;
  
  // Try get Upgrade Key for Dynamo Revit  
  if (dynamoCoreRegistry.uninstallKey<>'') then
  begin
    sUpgradeKey := ExpandConstant('SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UpgradeCodes\' + sReverseDynamoRevitUpgradeCode);
    if (RegKeyExists(HKLM64, sUpgradeKey)) then
    begin
      if(RegQueryStringValue(HKLM64, sUpgradeKey, sReverseDynamoRevitProductCode, sTemp)) then
      begin
        MsgBox(dynamoRevitRegistry.productCode + ' found in ' + '{#DynamoRevitUpgradeCode}' + '.  This means Dynamo Revit with the same UpgradeCode is installed.' 
           , mbInformation, MB_OK);
        // Since UpgradeCode the same, compare versions.
        if (NewerVersionExist(dynamoRevitRegistry)) then
          InstallDynamoRevit := False
        else if (SameVersionExist(dynamoRevitRegistry)) then
          UninstallDynamoRevit := True;
      end;
    end
    else
    begin
      MsgBox('{#DynamoRevitUpgradeCode}' + ' is not in use. This means Dynamo Revit is not installed.' 
         , mbInformation, MB_OK);
    end;
  end;
end;

{ Reverses the specified GUID based on the registry pattern }
function ReverseGuid(sGuid : String): String;
var
  i,j,base : Integer;
  sTempReverseGuid : String;
  aReversePattern : Array[1..11] of Integer;
begin
  if (sGuid='') then
    Exit;
  { Remove '-' }
  StringChangeEx(sGuid, '-', '', True);
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

{ Compare Versions - Newer }
function NewerVersionExist(product : TRegistry) : Boolean;
begin
  Result := False;
  if ( (product.majorVersion > StrToInt('{#Major}')) 
    or ((product.majorVersion = StrToInt('{#Major}')) and (product.minorVersion > StrToInt('{#Minor}')))
    or ((product.minorVersion = StrToInt('{#Minor}')) and (product.buildVersion > StrToInt('{#Build}'))) ) then
    Result := True;
end;

{ Compare Versions - Same }
function SameVersionExist(product : TRegistry) : Boolean;
begin
  Result := False;
  if (( product.majorVersion = StrToInt('{#Major}') ) 
    and ( product.minorVersion = StrToInt('{#Minor}') ) 
    and ( product.buildVersion = StrToInt('{#Build}') )) then
    Result := True;
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
