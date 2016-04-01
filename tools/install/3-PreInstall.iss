{ Function prototypes of helper methods. }
procedure UninstallProduct(var productRegistry: TRegistry); forward;
function InstallPath(productRegistry: TRegistry): String; forward;
function CheckInstall(productRegistry: TRegistry): Boolean; forward;

{ Primary Method - Invoked immediately after user clicks install. }
procedure CurStepChanged(CurStep: TSetupStep);
begin
  // Invoked at the beginning of the install phase
  if (CurStep=ssInstall) then
  begin
    // (1) Uninstalls the Dynamo created by old installer if found.
    if (OldDynamoCoreRegistry.uninstallKey<>'') then
      UninstallProduct(OldDynamoCoreRegistry);
      
    // (2) Uninstall Dynamo Core/Revit if flagged
    if (UninstallDynamoCore) then
      UninstallProduct(DynamoCoreRegistry);
    if (UninstallDynamoRevit) then
      UninstallProduct(DynamoRevitRegistry);

    // (3) Obtain Install Path.
    // If already installed in a certain path, asks user if want to change to the specified path. 
    // If existing product is already going to be uninstalled ignore this check.
    if (InstallDynamoCore and (not UninstallDynamoCore)) then
      DynamoCoreDirectory := InstallPath(DynamoCoreRegistry);    
    if (InstallDynamoRevit and (not UninstallDynamoRevit)) then
      DynamoRevitDirectory := InstallPath(DynamoRevitRegistry);
  end;
end;

{ Uninstalls a product based on the specified uninstall path. }
{ The var keyword means that the parameter is passed by reference. }
{ http://wiki.freepascal.org/Variable_parameter }
procedure UninstallProduct(var productRegistry: TRegistry);
var 
  iResultCode: Integer;
begin
  Exec(productRegistry.uninstallString, productRegistry.uninstallParam, '', SW_HIDE, ewWaitUntilTerminated, iResultCode);	
  // Set uninstallPath to empty string to state the product is uninstalled.
  productRegistry.uninstallKey := '';
end;

{ Based on the user's decision, }
{ uninstall previous installations if they are located in a different folder. }
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
    //if (productRegistry.buildVersion > StrToInt('{#Build}')) then
    //  Exit;
    
    if (productRegistry.parentInstallLocation<>WizardDirValue) then
    begin
      //  Ask the user a Yes/No question
      //  If YES Uninstall existing product & INSTALLDIR = WizardDirValue, else INSTALLDIR = Parent Directory
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

{ Checks if the already installed product has the same product version but different revision. }
{ Returns the ReinstallString stating if reinstallation is to happen or not. }
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
        //  Ask the user a Yes/No question
        //  If YES Uninstall existing product, else ABORT installation
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
