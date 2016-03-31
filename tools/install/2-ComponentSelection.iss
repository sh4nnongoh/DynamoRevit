{ Check if the components exists, if they do enable the component for installation }
procedure CurPageChanged(CurPageID: Integer);
begin
  if CurPageID = wpSelectComponents then
    // Default
    WizardForm.ComponentsList.Checked[0] := True;
    WizardForm.ComponentsList.ItemEnabled[0] := False;
    WizardForm.ComponentsList.Checked[1] := True;
    WizardForm.ComponentsList.ItemEnabled[1] := True;
    WizardForm.ComponentsList.Checked[2] := True;
    WizardForm.ComponentsList.ItemEnabled[2] := True;
    WizardForm.ComponentsList.Checked[3] := True;
    WizardForm.ComponentsList.ItemEnabled[3] := True;
    
    // Checks
    if not InstallDynamoCore then
    begin
      WizardForm.ComponentsList.Checked[0] := False;
    end;
    if not InstallDynamoRevit then
    begin
      WizardForm.ComponentsList.Checked[1] := False;
      WizardForm.ComponentsList.ItemEnabled[1] := False;
      WizardForm.ComponentsList.Checked[2] := False;
      WizardForm.ComponentsList.ItemEnabled[2] := False;
      WizardForm.ComponentsList.Checked[3] := False;
      WizardForm.ComponentsList.ItemEnabled[3] := False;
    end
    else
    begin
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
end;