unit frm_StartProgStartOther;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, Buttons;

type

  { TfrmStartProgStartOther }

  TfrmStartProgStartOther = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    chb_runas: TCheckBox;
    ed_params: TEdit;
    ed_filename: TComboBox;
    Label1: TLabel;
    Label2: TLabel;
    OpenDialog1: TOpenDialog;
    SpeedButton1: TSpeedButton;
    procedure SpeedButton1Click(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  frmStartProgStartOther: TfrmStartProgStartOther = nil;

implementation

{ TfrmStartProgStartOther }

procedure TfrmStartProgStartOther.SpeedButton1Click(Sender: TObject);
begin
  OpenDialog1.FileName := ed_filename.Text;

  if (OpenDialog1.Execute) then
  begin
    ed_filename.Text := OpenDialog1.FileName;
  end; // if (OpenDialog1.Execute)
end;

initialization
  {$I frm_startprogstartother.lrs}

end.

