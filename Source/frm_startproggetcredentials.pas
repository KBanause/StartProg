unit frm_StartProgGetCredentials;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, Buttons; 

type
  
  { TfrmStartProgGetCredentials }

  TfrmStartProgGetCredentials = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    cbox_usernames: TComboBox;
    ed_password: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    procedure FormCreate(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  frmStartProgGetCredentials: TfrmStartProgGetCredentials = nil;

implementation

uses
  {$IFDEF WINDOWS}
    windows,
  {$ENDIF WINDOWS}
  MRFunktionen_System;

{ TfrmStartProgGetCredentials }

procedure TfrmStartProgGetCredentials.FormCreate(Sender: TObject);
var
  i: LongInt;
  s: String;
  l: DWORD;
begin
  GetUserNamesOnSystem(cbox_usernames.Items);
  i := cbox_usernames.Items.IndexOf('__vmware_user__');

  if (i > -1) then
    cbox_usernames.Items.Delete(i);

  {$IFDEF WINDOWS}
    s := '';
    l := 1024;
    SetLength(s, l);
    GetUserName(PChar(s), l);
    SetLength(s, l - 1);
    i := cbox_usernames.Items.IndexOf(s);

    if (i > -1) then
      cbox_usernames.Items.Delete(i);
  {$ENDIF WINDOWS}

  if (cbox_usernames.Items.Count > 0) then
    cbox_usernames.ItemIndex := 0;
end;

initialization
  {$I frm_startproggetcredentials.lrs}

end.

