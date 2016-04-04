/// Function prototypes of helper methods.
function RevitInstallationExists(Version: String): Boolean; forward;
procedure GetRegistryValues(var productRegistry : TRegistry); forward;
function CompareNewer(product : TRegistry) : Boolean; forward;
function CompareSame(product : TRegistry) : Boolean; forward;
function SameVersionExist(): Boolean; forward;
function UninstallCurrentRevision(): Boolean; forward;
function NewerVersionsExist(): Boolean; forward;
function ReverseGuid(sGuid : String): String; forward;

/// Primary Method - Invoked immediately after EXE is run.
function InitializeSetup(): Boolean;
var
  sUpgradeKey                     : String;
  sReverseDynamoRevitProductCode  : String;
  sTemp                           : String;
begin
  Log('[INITIALIZE SETUP PHASE]');
  // By Default, initilize setup.
  Result := True
  
  // (1) Check for Revit Installation.
  // To check for a revit installation 
  ExtractTemporaryFile('RevitInstallDetective.exe');
  ExtractTemporaryFile('RevitAddinUtility.dll');
  // Check if there is a valid revit installation on this machine, if not - fail
  (*
  if not (RevitInstallationExists('Revit2017') or RevitInstallationExists('Revit2016') or RevitInstallationExists('Revit2015')) then
  begin
	MsgBox('Dynamo requires an installation of Revit 2015 or Revit 2016 or Revit 2017 in order to proceed!', mbCriticalError, MB_OK);
    Result := False;
    Log('Error: Revit not installed.');
    Log('InitializeSetup = ' + IntToStr(Integer(Result)));
    Exit;
  end;
  *)
  
  // (2) Get Registry values of existing related products.
  Log('(Obtaining the registry of existing products)');
  DynamoCoreRegistry.productName := '{#CoreProductName} {#Major}.{#Minor}';
  GetRegistryValues(DynamoCoreRegistry);
  DynamoRevitRegistry.productName := '{#ProductName} {#Major}.{#Minor}';
  GetRegistryValues(DynamoRevitRegistry);
  OldDynamoCoreRegistry.productName := 'Dynamo {#Major}.{#Minor}';
  GetRegistryValues(OldDynamoCoreRegistry);
  
  // (3) Set Global Flags to default values.
  // By default install both DynamoCore and DynamoRevit
  InstallDynamoCore := True;
  InstallDynamoRevit := True;
  // If Old Dynamo Revit with wrong UpgradeCode is installed, it will be set to True.
  // If Dynamo Core/Revit already installed with same product version, it will be set to True.
  UninstallDynamoRevit := False;
  UninstallDynamoCore := False;
  
  Log('(Default Flag values)');
  Log('InstallDynamoCore = ' + IntToStr(Integer(InstallDynamoCore)));
  Log('InstallDynamoRevit = ' + IntToStr(Integer(InstallDynamoRevit)));
  Log('UninstallDynamoRevit = ' + IntToStr(Integer(UninstallDynamoRevit)));
  Log('UninstallDynamoCore = ' + IntToStr(Integer(UninstallDynamoCore)));
  
  // (4) Check for newer Build versions already installed.
  // NewerVersionsExist() returns True only when both Dynamo Core and Dynamo Revit are of newer Version.
  if ( NewerVersionsExist() ) then
  begin
    Result := False;
    Log('InitializeSetup = ' + IntToStr(Integer(Result)));
    Exit;
  end;
  
  // (5) Compare Revision field
  // (5a) Checks if same version already installed. Uninstall flag will be set if found.
  // (5b) Double checks with user if want to uninstall if a higher revision is already installed.
  if ( (SameVersionExist()) and (not UninstallCurrentRevision()) ) then
  begin
    Result := False;
    Log('InitializeSetup = ' + IntToStr(Integer(Result)));
    Exit;
  end;

  // This section will be deleted before release. 
  // (6) Check for Old Dynamo Revit
  // Check UpgradeCode for Old Dynamo Revit with the same Dynamo Core UpgradeCode.   
  if ((not UninstallDynamoRevit) and (DynamoRevitRegistry.uninstallKey<>'')) then
  begin
    sReverseDynamoRevitProductCode := ReverseGuid('{584B3E06-FE7A-4341-8C22-339B00ABD58A}');
    sUpgradeKey := ExpandConstant('SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UpgradeCodes\' + sReverseDynamoRevitProductCode);
    if(RegQueryStringValue(HKLM64, sUpgradeKey, sReverseDynamoRevitProductCode, sTemp)) then
    begin
      // Since Old Dynamo Revit found, uninstall it.
      UninstallDynamoRevit := True;
      Log('Old Dynamo Revit found.');
      Log('UninstallDynamoRevit = ' + IntToStr(Integer(UninstallDynamoRevit)));
    end;
  end;
  
  Log('InitializeSetup = ' + IntToStr(Integer(Result)));
end;

/// Checks if same version already installed. Uninstall flag will be set if found.
function SameVersionExist(): Boolean;
begin
  Result := False;
  Log('(Check for same version)');
  if (CompareSame(DynamoCoreRegistry)) then
  begin
    UninstallDynamoCore := True;
    Log('UninstallDynamoCore = ' + IntToStr(Integer(UninstallDynamoCore)));
    Result := True;
  end;
  if (CompareSame(DynamoRevitRegistry)) then
  begin
    UninstallDynamoRevit := True;
    Log('UninstallDynamoRevit = ' + IntToStr(Integer(UninstallDynamoRevit)));
    Result := True;
  end;
end;

/// Double checks with user if want to uninstall if a higher revision is already installed.
function UninstallCurrentRevision(): Boolean;
var
  sTemp : String;
begin

  Result := True;
  if ((DynamoCoreRegistry.uninstallKey='') and (DynamoRevitRegistry.uninstallKey='')) then
    Exit;

  // sTemp will contain the Display String which will be displayed in the Popup box.
  sTemp := '';
  if (( UninstallDynamoCore and UninstallDynamoRevit )
    and ( DynamoCoreRegistry.revVersion > StrToInt('{#Rev}') )
    and ( DynamoRevitRegistry.revVersion > StrToInt('{#Rev}') )) then
    sTemp := DynamoCoreRegistry.productName + ' & ' + DynamoRevitRegistry.productName
  else if (( UninstallDynamoCore )
    and ( DynamoCoreRegistry.revVersion > StrToInt('{#Rev}') )) then
    sTemp := DynamoCoreRegistry.productName
  else if (( UninstallDynamoRevit )
    and ( DynamoRevitRegistry.revVersion > StrToInt('{#Rev}') )) then
    sTemp := DynamoRevitRegistry.productName;
    
  // As long as user clicks no, Setup will end.
  if (( sTemp <> '' )
    and ( MsgBox('A newer Revision of ' + sTemp + ' is already installed.'
            + #13#10#13#10 + 'Do you wish to uninstall it?'
            + #13#10#13#10 + 'Choosing "No" will end the setup.'
            , mbError, MB_YESNO) = IDNO )) then
      Result := False;    
end;

/// Check for newer Build versions already installed.
function NewerVersionsExist(): Boolean;
begin

  Result := False;
  if ((DynamoCoreRegistry.uninstallKey='') and (DynamoRevitRegistry.uninstallKey='')) then
    Exit;
    
  // Set flags. If newer version already installed, do not install product.
  Log('(Check for newer versions)');
  if (CompareNewer(DynamoCoreRegistry)) then
  begin
    InstallDynamoCore := False;
    Log('InstallDynamoCore = ' + IntToStr(Integer(InstallDynamoCore)));
  end;
  if (CompareNewer(DynamoRevitRegistry)) then
  begin
    InstallDynamoRevit := False;
    Log('InstallDynamoRevit = ' + IntToStr(Integer(InstallDynamoRevit)));
  end;
  
  // Inform User.
  if ((not InstallDynamoCore) and (not InstallDynamoRevit)) then
  begin
    MsgBox('Newer versions of Dynamo Core & Dynamo Revit already installed! Exiting Setup...', mbCriticalError, MB_OK);
    Result := True;
    Exit;
  end
  else if (not InstallDynamoCore) then
  begin
    MsgBox('Newer version of Dynamo Core already installed! It will not be installed.', mbInformation, MB_OK);
  end
  else if (not InstallDynamoRevit) then
  begin
    MsgBox('Newer version of Dynamo Revit already installed! It will not be installed.', mbInformation, MB_OK);
  end
  
end;

/// Procedure to obtain registry values of the specified product type. 
/// The var keyword means that the parameter is passed by reference. 
procedure GetRegistryValues(var productRegistry : TRegistry);
var
  sTempVersion   : String;
  iTempPeriodPos : Integer;
begin
  productRegistry.uninstallKey := ExpandConstant('Software\Microsoft\Windows\CurrentVersion\Uninstall\' + productRegistry.productName);
  if (NOT RegKeyExists(HKLM64, productRegistry.uninstallKey)) then
  begin
    productRegistry.uninstallKey := '';
    Log( productRegistry.productName + ' not found in registry.');
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

  Log(productRegistry.productName + ' Uninstall Key = ' + productRegistry.uninstallKey);
  Log(productRegistry.productName + ' Install Location = ' + productRegistry.installLocation);
  Log(productRegistry.productName + ' Uninstall Parameters = ' + productRegistry.uninstallParam);
  Log(productRegistry.productName + ' Uninstall String = ' + productRegistry.uninstallString);
  Log(productRegistry.productName + ' Version = ' + productRegistry.version);
  Log(productRegistry.productName + ' Revision = ' + IntToStr(productRegistry.revVersion));
end;

/// Compare Versions - Newer
function CompareNewer(product : TRegistry) : Boolean;
begin
  Result := False;
  if ( (product.uninstallKey <> '')
    and (product.majorVersion = StrToInt('{#Major}')) 
    and (product.minorVersion = StrToInt('{#Minor}')) 
    and (product.buildVersion > StrToInt('{#Build}'))) then
    Result := True;
end;

/// Compare Versions - Same
function CompareSame(product : TRegistry) : Boolean;
begin
  Result := False;
  if ( (product.uninstallKey <> '')
    and ( product.majorVersion = StrToInt('{#Major}') ) 
    and ( product.minorVersion = StrToInt('{#Minor}') ) 
    and ( product.buildVersion = StrToInt('{#Build}') )) then
    Result := True;
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

/// Reverses the specified GUID based on the registry pattern
function ReverseGuid(sGuid : String): String;
var
  i,j,base : Integer;
  sTempReverseGuid : String;
  aReversePattern : Array[1..11] of Integer;
begin
  if (sGuid='') then
    Exit;
  // Remove '-' 
  StringChangeEx(sGuid, '-', '', True);
  // Remove Brackets 
  sGuid := Copy(sGuid,2,32);
  // GUID Reversal Pattern: 8, 4, 4, 2, 2, 2, 2, 2, 2, 2, 2 
  // http://stackoverflow.com/questions/17936064/how-can-i-find-the-upgrade-code-for-an-installed-application-in-c
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
  // Reverse GUID 
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
