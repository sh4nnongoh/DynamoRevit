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