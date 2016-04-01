{ Function prototypes of helper methods. }
procedure UninstallProduct(var productRegistry: TRegistry); forward;
function InstallPath(productRegistry: TRegistry): String; forward;

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
    // By default install directory is WizardDirValue.
    DynamoCoreDirectory := WizardDirValue;
    DynamoRevitDirectory := WizardDirValue;
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
begin
  // Default install location is the one specified by user in Wizard
  Result := WizardDirValue;

  if (productRegistry.installLocation<>'') then
  begin
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
