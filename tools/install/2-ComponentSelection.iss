var
  ComponentsFormID : Integer;
  Label1: TLabel;
  DynamoCoreCheckBox: TNewCheckBox; 
  DynamoRevit2015CheckBox: TNewCheckBox; 
  DynamoRevit2016CheckBox: TNewCheckBox; 
  DynamoRevit2017CheckBox: TNewCheckBox; 
  SamplesCheckBox: TNewCheckBox; 

function ComponentsFormCreatePage(PreviousPageId: Integer): Integer;
var
  Page: TWizardPage;
begin
  Page := CreateCustomPage(
    PreviousPageId,
    CustomMessage('ComponentsFormCaption'),
    CustomMessage('ComponentsFormDescription')
  );
 
  Label1 := TLabel.Create(Page);
  with Label1 do
  begin
    Parent := Page.Surface;
    Caption := CustomMessage('ComponentsFormLabelCaption1');
    WordWrap := True;    
    Left := ScaleX(6);
    Top := ScaleY(4);
    Width := ScaleX(400);
    Height := ScaleY(37);
  end;

  DynamoCoreCheckBox := TNewCheckBox.Create(Page);
  with DynamoCoreCheckBox do
  begin
    Parent := Page.Surface;
    Caption := CustomMessage('ComponentsFormCheckBoxCaption1');
    Left := ScaleX(Label1.Left);
    Top := ScaleY(Label1.Top + 45);
    Width := ScaleX(300);
    Height := ScaleY(17);
  end;
  DynamoRevit2015CheckBox := TNewCheckBox.Create(Page);
  with DynamoRevit2015CheckBox do
  begin
    Parent := Page.Surface;
    Caption := CustomMessage('ComponentsFormCheckBoxCaption2');
    Left := ScaleX(DynamoCoreCheckBox.Left);
    Top := ScaleY(DynamoCoreCheckBox.Top + 20);
    Width := ScaleX(DynamoCoreCheckBox.Width);
    Height := ScaleY(DynamoCoreCheckBox.Height);
  end;
  DynamoRevit2016CheckBox := TNewCheckBox.Create(Page);
  with DynamoRevit2016CheckBox do
  begin
    Parent := Page.Surface;
    Caption := CustomMessage('ComponentsFormCheckBoxCaption3');
    Left := ScaleX(DynamoCoreCheckBox.Left);
    Top := ScaleY(DynamoRevit2015CheckBox.Top + 20);
    Width := ScaleX(DynamoCoreCheckBox.Width);
    Height := ScaleY(DynamoCoreCheckBox.Height);
  end;
  DynamoRevit2017CheckBox := TNewCheckBox.Create(Page);
  with DynamoRevit2017CheckBox do
  begin
    Parent := Page.Surface;
    Caption := CustomMessage('ComponentsFormCheckBoxCaption4');
    Left := ScaleX(DynamoCoreCheckBox.Left);
    Top := ScaleY(DynamoRevit2016CheckBox.Top + 20);
    Width := ScaleX(DynamoCoreCheckBox.Width);
    Height := ScaleY(DynamoCoreCheckBox.Height);
  end;
  (*
  SamplesCheckBox := TNewCheckBox.Create(Page);
  with SamplesCheckBox do
  begin
    Parent := Page.Surface;
    Caption := CustomMessage('ComponentsFormCheckBoxCaption5');
    Left := ScaleX(DynamoCoreCheckBox.Left);
    Top := ScaleY(DynamoRevit2017CheckBox.Top + 20);
    Width := ScaleX(DynamoCoreCheckBox.Width);
    Height := ScaleY(DynamoCoreCheckBox.Height);
  end;
  *)
  Result := Page.ID;
end;

procedure InitializeWizard();
begin
  ComponentsFormID := ComponentsFormCreatePage(wpSelectComponents);
end;

/// Check if the components exists, if they do enable the component for installation
procedure CurPageChanged(CurPageID: Integer);
begin  
  if CurPageID = ComponentsFormID then
  begin
    // Default
    DynamoCoreCheckBox.State := cbChecked;
    DynamoCoreCheckBox.Enabled := False;
    DynamoRevit2015CheckBox.State := cbChecked;
    DynamoRevit2015CheckBox.Enabled := True;
    DynamoRevit2016CheckBox.State := cbChecked;
    DynamoRevit2016CheckBox.Enabled := True;
    DynamoRevit2017CheckBox.State := cbChecked;
    DynamoRevit2017CheckBox.Enabled := True;
    
    // Checks
    if not InstallDynamoCore then
    begin
      DynamoCoreCheckBox.State := cbUnchecked;
    end;
    if not InstallDynamoRevit then
    begin
      DynamoRevit2015CheckBox.State := cbUnchecked;
      DynamoRevit2015CheckBox.Enabled := False;
      DynamoRevit2016CheckBox.State := cbUnchecked;
      DynamoRevit2016CheckBox.Enabled := False;
      DynamoRevit2017CheckBox.State := cbUnchecked;
      DynamoRevit2017CheckBox.Enabled := False;
    end
    else
    begin 
      if not RevitInstallationExists('Revit2015') then
      begin
        DynamoRevit2015CheckBox.State := cbUnchecked;
        DynamoRevit2015CheckBox.Enabled := False;
      end;
      if not RevitInstallationExists('Revit2016') then
      begin
        DynamoRevit2016CheckBox.State := cbUnchecked;
        DynamoRevit2016CheckBox.Enabled := False;
      end;
      if not RevitInstallationExists('Revit2017') then
      begin
        DynamoRevit2017CheckBox.State := cbUnchecked;
        DynamoRevit2017CheckBox.Enabled := False;
      end;
    end;
  end;
end;