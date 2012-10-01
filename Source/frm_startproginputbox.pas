unit frm_StartProgInputBox;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, Buttons; 

type
  
  { TfrmStartProgInputBox }

  TfrmStartProgInputBox = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    Edit1: TEdit;
    Label1: TLabel;
    procedure FormActivate(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end; 

function MRInputBox(const ACaption, APrompt, ADefault: string; var AResult: String): Boolean;

var
  frmStartProgInputBox: TfrmStartProgInputBox;

implementation

uses frm_StartProgSetup;

function MRInputBox(const ACaption, APrompt, ADefault: string; var AResult: String): Boolean;
begin
  frmStartProgInputBox := TfrmStartProgInputBox.Create(frmStartProgSetup);
  frmStartProgInputBox.Caption := ACaption;
  frmStartProgInputBox.Label1.Caption := APrompt;
  frmStartProgInputBox.Edit1.Text := ADefault;
  Result := False;

  if (frmStartProgInputBox.ShowModal = mrOK) then
  begin
    AResult := frmStartProgInputBox.Edit1.Text;
    Result := True;
  end;

  frmStartProgInputBox.Free;
  frmStartProgInputBox := nil;
end;

{ TfrmStartProgInputBox }

procedure TfrmStartProgInputBox.FormActivate(Sender: TObject);
begin
  Self.OnActivate := nil;
  Self.BringToFront;
  Screen.MoveFormToZFront(Self);
  Edit1.SetFocus;
  Edit1.SelStart := 0;
  Edit1.SelLength := Length(Edit1.Text);
end;

initialization
  {$I frm_startproginputbox.lrs}

end.

