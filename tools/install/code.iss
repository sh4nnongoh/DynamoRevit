
////////////////////////////////////////////////////////////////////////////////////////
// Global Variables ................................................................. //
type
  TRegistry = record
  productName           : String;
  uninstallPath         : String;
  installLocation       : String;
  parentInstallLocation : String;
  version               : String;
  majorVersion          : Cardinal;
  minorVersion          : Cardinal;
  buildVersion          : Cardinal;
  revVersion            : Cardinal;
  uninstallParam        : String;
  uninstallString       : String;
end;

var
  DynamoCoreDirectory   : String;
  DynamoRevitDirectory  : String;
  InstallDynamoCore     : Boolean;
  InstallDynamoRevit    : Boolean;
  DynamoCoreRegistry    : TRegistry;
  DynamoRevitRegistry   : TRegistry;
  OldDynamoCoreRegistry : TRegistry;
  //OldDynamoRevitRegistry : TRegistry;


// (1) SETUP PHASE ================================================================== //
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
  productRegistry.parentInstallLocation := copy(productRegistry.installLocation,
                                                1,
                                                length(productRegistry.installLocation)-length(productRegistry.productName)-2);
  
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

/// Primary Function
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

  
  MsgBox( DynamoCoreRegistry.productName + #13#10
        + DynamoCoreRegistry.uninstallPath + #13#10
        + DynamoCoreRegistry.installLocation + #13#10
        + DynamoCoreRegistry.parentInstallLocation + #13#10
        + IntToStr(DynamoCoreRegistry.revVersion) + #13#10
        + DynamoCoreRegistry.uninstallParam + #13#10
        + DynamoCoreRegistry.uninstallString + #13#10
        + DynamoCoreRegistry.version + #13#10
        + IntToStr(DynamoCoreRegistry.majorVersion) + #13#10
        + IntToStr(DynamoCoreRegistry.minorVersion) + #13#10
        + IntToStr(DynamoCoreRegistry.buildVersion) + #13#10
        ,mbConfirmation, MB_OK);
  
  
end;

// (2) COMPONENT SELECTION PHASE ========================================================== //
/// Check if the components exists, if they do enable the component for installation
procedure CurPageChanged(CurPageID: Integer);
begin
  if CurPageID = wpSelectComponents then
    if not RevitInstallationExists('Revit2015') then
    begin
      WizardForm.ComponentsList.Checked[1] := False;
      WizardForm.ComponentsList.ItemEnabled[1] := False;
    end;
    if not RevitInstallationExists('Revit2016') then
    begin
      WizardForm.ComponentsList.Checked[2] := False;
      WizardForm.ComponentsList.ItemEnabled[2] := False;
    end;
    if not RevitInstallationExists('Revit2017') then
    begin
      WizardForm.ComponentsList.Checked[3] := False;
      WizardForm.ComponentsList.ItemEnabled[3] := False;
    end;
end;

// (3) PRE-INSTALL PHASE ================================================================== //
/// Uninstalls a product based on the specified uninstall path
/// The var keyword means that the parameter is passed by reference.
/// http://wiki.freepascal.org/Variable_parameter
procedure UninstallProduct(var productRegistry: TRegistry);
var 
  iResultCode: Integer;
begin
  Exec(productRegistry.uninstallString, productRegistry.uninstallParam, '', SW_HIDE, ewWaitUntilTerminated, iResultCode);	
  // Set uninstallPath to empty string to state the product is uninstalled.
  productRegistry.uninstallPath := '';
end;

/// Based on the user's decision,
/// uninstall previous installations if they are located in a different folder.
function InstallPath(productRegistry: TRegistry): String;
var 
  iBuildVersionPos: Integer;
  iBuildVersion: Integer;
begin

  // Default install location is the one specified by user in Wizard
  Result := WizardDirValue;

  if (productRegistry.installLocation<>'') then
  begin
    // Need to check BUILD field of version number.
    (*
    iBuildVersionPos := pos('{#Major}.{#Minor}.',productRegistry.version);
    if (iBuildVersionPos=0) then
      Exit;
    iBuildVersion := StrToInt(Copy(productRegistry.version, 
                                   Length(productRegistry.version) - iBuildVersionPos + 1,
                                   Length(productRegistry.version))
                              );
    *)
    if (productRegistry.buildVersion > StrToInt('{#Build}')) then
      Exit;
    
    if (productRegistry.parentInstallLocation<>WizardDirValue) then
    begin
      // Ask the user a Yes/No question
      // If YES Uninstall existing product & INSTALLDIR = WizardDirValue, else INSTALLDIR = Parent Directory
      if MsgBox(productRegistry.productName + ' is already installed at ' 
                + productRegistry.parentInstallLocation + '.' + #13#10#13#10 
                + 'Do you want to reinstall into the new location specified?', 
                mbConfirmation, MB_YESNO) = IDYES then
        UninstallProduct(productRegistry)
      else
        Result := productRegistry.parentInstallLocation;
    end;
  end;
end;

/// Checks if the already installed product has the same product version but different revision.
/// Returns the ReinstallString stating if reinstallation is to happen or not.
function CheckInstall(productRegistry: TRegistry): Boolean;
var
  iCurrentRevision : Cardinal;
begin
  Result := true;
  iCurrentRevision := StrToInt('{#Rev}');
  if (productRegistry.version='{#Major}.{#Minor}.{#Build}') then
  begin
    if (productRegistry.revVersion<>iCurrentRevision) then
    begin
      if (productRegistry.revVersion>iCurrentRevision) then
      begin
        // Ask the user a Yes/No question
        // If YES Uninstall existing product, else ABORT installation
        if MsgBox(productRegistry.productName + ' with Revision ' + IntToStr(productRegistry.revVersion) + ' is already installed.' 
                  + #13#10#13#10 + 'Do you want to reinstall with Revision {#Rev}?', 
                  mbConfirmation, MB_YESNO) = IDYES then
          UninstallProduct(productRegistry)
        else
          Result := false;
      end
      else
        UninstallProduct(productRegistry);
    end
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  // Invoked at the beginning of the install phase
  if (CurStep=ssInstall) then
  begin
    // By default install both DynamoCore and DynamoRevit
    InstallDynamoCore := true;
    InstallDynamoRevit := true;

    // Uninstalls the Dynamo created by old installer if found.
    if (OldDynamoCoreRegistry.uninstallPath<>'') then
      UninstallProduct(OldDynamoCoreRegistry);
    
    // (1) Check if product(s) are already installed.  
    // (2) Check if there is same product version but different revision.
    //     If the installed product(s) have the same product version (ie. MAJOR.MINOR.BUILD) but different revision,
    //     asks user if they want to reinstall with the new revision.
    // (3) Obtain Install Path.
    //     If already installed in a certain path, asks user if want to change to the specified path.      
    if (DynamoCoreRegistry.uninstallPath<>'') then
    begin
      InstallDynamoCore := CheckInstall(DynamoCoreRegistry);
      if (InstallDynamoCore) then
        DynamoCoreDirectory := InstallPath(DynamoCoreRegistry);    
    end;
    if (DynamoRevitRegistry.uninstallPath<>'') then
    begin
      InstallDynamoRevit := CheckInstall(DynamoRevitRegistry);
      if (InstallDynamoRevit) then
        DynamoRevitDirectory := InstallPath(DynamoRevitRegistry);
    end;
  end;
end;

// SCRIPTED CONSTANTS & CHECK FUNCTIONS ................................................... //
// These functions are called from the [Run] section of the script.
function CheckRevit2015(Value: string): String;
begin
  Result := '0';
  if (WizardForm.ComponentsList.Checked[1]) then
    Result := '1';
end;
function CheckRevit2016(Value: string): String;
begin
  Result := '0';
  if (WizardForm.ComponentsList.Checked[2]) then
    Result := '1';
end;
function CheckRevit2017(Value: string): String;
begin
  Result := '0';
  if (WizardForm.ComponentsList.Checked[3]) then
    Result := '1';
end;

function DynamoCoreInstallPath(Value: string): String;
begin
  Result := DynamoCoreDirectory;
end;
function DynamoRevitInstallPath(Value: string): String;
begin
  Result := DynamoRevitDirectory;
end;

function CheckInstallDynamoCore: Boolean;
begin
  Result := InstallDynamoCore;
end;
function CheckInstallDynamoRevit: Boolean;
begin
  Result := InstallDynamoRevit;
end;