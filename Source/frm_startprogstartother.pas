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
    procedure FormCreate(Sender: TObject);
    procedure OpenDialog1Show(Sender: TObject);
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

procedure TfrmStartProgStartOther.FormCreate(Sender: TObject);
begin
  {$IFDEF UNIX}
  OpenDialog1.Filter := 'Script-Dateien|*.sh;*.pl;*.py|Alle Dateien|*';
  {$ENDIF}
  {$IFDEF WINDOWS}
  OpenDialog1.Filter := 'EXE-Files|*.exe|Script-Dateien|*.bat;*.cmd|COM-Dateien|*.com|Ausführbare Dateien|*.exe;*.bat;*.cmd;*.com|Alle Dateien|*.*';
  {$ENDIF}
end;

procedure TfrmStartProgStartOther.OpenDialog1Show(Sender: TObject);
begin
  {$IFDEF LINUX}
  OpenDialog1.Filter := 'Script-Dateien|*.sh;*.pl;*.py|Alle Dateien|*';
  {$ENDIF}
  {$IFDEF WINDOWS}
  OpenDialog1.Filter := 'EXE-Files|*.exe|Script-Dateien|*.bat;*.cmd|COM-Dateien|*.com|Ausführbare Dateien|*.exe;*.bat;*.cmd;*.com|Alle Dateien|*.*';
  {$ENDIF}
end;

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
