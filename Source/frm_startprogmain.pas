unit frm_StartProgMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, Menus, mrxml, process, StdCtrls;

type
  { TfrmStartProgMain }

  TfrmStartProgMain = class(TForm)
    ApplicationProperties1: TApplicationProperties;
    mi_lock: TMenuItem;
    mi_run: TMenuItem;
    mi_reboot: TMenuItem;
    mi_logoff: TMenuItem;
    mi_standby: TMenuItem;
    mi_hibernate: TMenuItem;
    mi_shutdown: TMenuItem;
    mi_system: TMenuItem;
    mi_sep2: TMenuItem;
    mi_beenden: TMenuItem;
    mi_sep1: TMenuItem;
    mi_setup: TMenuItem;
    PopupMenu1: TPopupMenu;
    TrayIcon1: TTrayIcon;
    procedure ApplicationProperties1Exception(Sender: TObject; E: Exception);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure mi_beendenClick(Sender: TObject);
    procedure mi_hibernateClick(Sender: TObject);
    procedure mi_lockClick(Sender: TObject);
    procedure mi_logoffClick(Sender: TObject);
    procedure mi_rebootClick(Sender: TObject);
    procedure mi_runClick(Sender: TObject);
    procedure mi_setupClick(Sender: TObject);
    procedure mi_shutdownClick(Sender: TObject);
    procedure mi_standbyClick(Sender: TObject);
    procedure PopupMenu1Popup(Sender: TObject);
    procedure TrayIcon1DblClick(Sender: TObject);
  private
    FAllProgs: TList;
    FConfigFileName: string;
    FConfXML: TMRXMLClass;
    FDefaultNode: TMRXMLNode;
    FDoCompress: Boolean;
    FDoEncrypt: Boolean;
    FPID: LongWord;

    procedure LoadConfig;
    procedure mi_programmClick(Sender: TObject);
    procedure RunAsProgListChange(Sender: TObject);
    procedure SaveConfig;
    procedure SetConfigFileName(const AValue: string);
    procedure SetMenu;
    procedure StartProgramm(node: TMRXMLNode);
    { private declarations }
  public
    { public declarations }
  published
    property ConfigFileName: string read FConfigFileName write SetConfigFileName;
  end; 

var
  frmStartProgMain: TfrmStartProgMain;

implementation

uses
  {$IFDEF UNIX}
    baseunix, unix,
  {$ENDIF}
  frm_StartProgSetup, StartProg_StartThread, StartProg_Tools,
  frm_StartProgStartOther, frm_StartProgGetCredentials, MRFunktionen;

{ TfrmStartProgMain }

procedure TfrmStartProgMain.ApplicationProperties1Exception(Sender: TObject;
  E: Exception);
begin
  ShowMessage(E.Message);
end;

procedure TfrmStartProgMain.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  if (GetProcessID = FPID) then
    SaveConfig;

  FAllProgs.Free;
  FConfXML.Free;
end;

procedure TfrmStartProgMain.FormCreate(Sender: TObject);
var
  s: String;
begin
  FPID := GetProcessID;
  FDoCompress := False;
  FDoEncrypt := False;
  FAllProgs := TList.Create;

  FConfXML := nil;
  FDefaultNode := nil;
  Randomize;
  //FConfigFileName := ChangeFileExt(GetAppConfigFile(False, True), '.xml');
  FConfigFileName := GetConfigFileName('.xml');
  s := ExtractFilePath(FConfigFileName);

  if (not DirectoryExists(s)) then
  begin
    if (not ForceDirectories(s)) then
    begin
      ShowMessage(Format('Could not create configfile directory "%s".%sTerminating...', [s, LineEnding]));
      Application.Terminate;
      Exit;
    end;
  end; // if (not DirectoryExists(s))

  if (not FileExists(FConfigFileName)) then
  begin
    FConfXML := TMRXMLClass.Create;
    FConfXML.CreateRoot(Application.Title);
    SaveConfig;
    FConfXML.Free;
    FConfXML := nil;
  end; // if (not FileExists(FConfigFileName))

  LoadConfig;
end;

procedure TfrmStartProgMain.LoadConfig;
var
  fs: TMemoryStream;
begin
  if (FConfXML <> nil) then
    FConfXML.Free;

  FConfXML := TMRXMLClass.Create;
  fs := TMemoryStream.Create;
  fs.LoadFromFile(FConfigFileName);
  fs.Position := 0;
  FConfXML.LoadFromStream(fs);
  fs.Free;
  SetMenu;
end;

procedure TfrmStartProgMain.mi_beendenClick(Sender: TObject);
begin
  if (frmStartProgSetup = nil) then
    Close;
end;

procedure TfrmStartProgMain.mi_hibernateClick(Sender: TObject);
begin
  SetSuspendState(True, False, False);
end;

procedure TfrmStartProgMain.mi_lockClick(Sender: TObject);
begin
  LockWorkstation;
end;

procedure TfrmStartProgMain.mi_logoffClick(Sender: TObject);
begin
  ExitOS(EWX_LOGOFF or EWX_FORCE);
end;

procedure TfrmStartProgMain.mi_rebootClick(Sender: TObject);
begin
  ExitOS(EWX_REBOOT or EWX_FORCE);
end;

procedure TfrmStartProgMain.mi_runClick(Sender: TObject);
  procedure AddRunOtherToXML(Pfad: string; Params: string);
  var
    i: Integer;
    node: TMRXMLNode;
    node2: TMRXMLNode;
    node3: TMRXMLNode;
    oldvalue: Int64;
    s: String;
  begin
    node := FConfXML.RootNode.Child('MRU');

    if (node = nil) then
      node := FConfXML.AddChild(FConfXML.RootNode, 'MRU');

    node2 := node.GetFirstChild;

    while (node2 <> nil) do
    begin
      s := node2.Value;

      if (UpperCase(s) = UpperCase(Pfad)) then
        Break;

      node2 := node2.GetNextSibling;
    end; // while (node2 <> nil)

    if (node2 = nil) then
    begin
      node2 := FConfXML.AddChild(node, 'Item');
      node2.Value := frmStartProgStartOther.ed_filename.Text;
      node2.Attribute['lastrun'].AsInteger := 0;
    end;

    oldvalue := node2.Attribute['lastrun'].AsInteger;
    node2.Attribute['lastrun'].AsInteger := 0;
    node2.Attribute['params'].Value := Params;
    node2 := node.GetFirstChild;

    while (node2 <> nil) do
    begin
      i := node2.Attribute['lastrun'].AsInteger;
      i := i + Integer((i < oldvalue) or (oldvalue = 0));
      node2.Attribute['lastrun'].AsInteger := i;

      if (i > 10) then
      begin
        node3 := node2.GetNextSibling;
        node.DeleteChild(node2);
        node2 := node3;
      end // if (i > 10)
      else
        node2 := node2.GetNextSibling;
    end; // while (node2 <> nil)

    FConfXML.SaveToFile(FConfigFileName);
  end;

var
  i: Integer;
  NewPassword: String;
  NewUser: String;
  node: TMRXMLNode;
  node2: TMRXMLNode;
  runasthread: TSPRunAsThread;
  runthread: TSPStartThread;
  s: String;
  sl: TStringList;
  node3: TMRXMLNode;
begin
  if (Assigned(frmStartProgStartOther)) then
    exit;

  Application.CreateForm(TfrmStartProgStartOther, frmStartProgStartOther);
  frmStartProgStartOther.ed_filename.OnChange := @RunAsProgListChange;
  node := FConfXML.RootNode.Child('MRU');

  if (node = nil) then
    FConfXML.AddChild(FConfXML.RootNode, 'MRU')
  else
  begin
    node2 := node.GetFirstChild;
    sl := TStringList.Create;

    while (node2 <> nil) do
    begin
      i := node2.Attribute['lastrun'].AsIntegerDef(0);
      sl.AddObject(Format('%.2d %s', [i, node2.Value]), node2);
      node2 := node2.GetNextSibling;
    end; // while (node2 <> nil)

    if (sl.Count > 0) then
    begin
      sl.Sort;

      for i := 0 to sl.Count - 1 do
      begin
        s := sl[i];
        Delete(s, 1, 3);
        sl[i] := s;
      end; // for i := 0 to sl.Count - 1

      frmStartProgStartOther.ed_filename.Items.Assign(sl);
      sl.Free;
    end; // if (frmStartProgStartOther.ed_filename.Items.Count > 0)
  end;

  if (frmStartProgStartOther.ShowModal = mrOK) then
  begin
    if (frmStartProgStartOther.chb_runas.Checked) then
    begin
      Application.CreateForm(TfrmStartProgGetCredentials, frmStartProgGetCredentials);
      NewUser := '';
      NewPassword := '';

      if (frmStartProgGetCredentials.ShowModal = mrOK) then
      begin
        NewUser := frmStartProgGetCredentials.cbox_usernames.Text;
        NewPassword := frmStartProgGetCredentials.ed_password.Text;
        runasthread := TSPRunAsThread.Create(True);
        runasthread.ExeName := frmStartProgStartOther.ed_filename.Text;
        runasthread.StartDir := '';
        runasthread.Parameters := frmStartProgStartOther.ed_params.Text;
        runasthread.Benutzername := NewUser;
        runasthread.Password := NewPassword;
        AddRunOtherToXML(frmStartProgStartOther.ed_filename.Text, frmStartProgStartOther.ed_params.Text);
        frmStartProgGetCredentials.Free;
        frmStartProgGetCredentials := nil;
        frmStartProgStartOther.Free;
        frmStartProgStartOther := nil;
        runasthread.Resume;
      end // if (frmStartProgGetCredentials.ShowModal = mrOK)
      else
      begin
        frmStartProgGetCredentials.Free;
        frmStartProgGetCredentials := nil;
        frmStartProgStartOther.Free;
        frmStartProgStartOther := nil;
      end;
    end // if (frmStartProgStartOther.chb_runas.Checked)
    else
    begin
      runthread := TSPStartThread.Create(True);
      runthread.ExeName := frmStartProgStartOther.ed_filename.Text;
      runthread.StartDir := '';
      runthread.Parameters := frmStartProgStartOther.ed_params.Text;
      AddRunOtherToXML(frmStartProgStartOther.ed_filename.Text, frmStartProgStartOther.ed_params.Text);
      frmStartProgStartOther.Free;
      frmStartProgStartOther := nil;
      runthread.Resume;
    end;
  end // if (frmStartProgStartOther.ShowModal = mrOK)
  else
  begin
    frmStartProgStartOther.Free;
    frmStartProgStartOther := nil;
  end;
end;

procedure TfrmStartProgMain.mi_programmClick(Sender: TObject);
var
  mi: TMenuItem;
  node: TMRXMLNode;
begin
  mi := TMenuItem(Sender);
  node := TMRXMLNode(FAllProgs[mi.Tag]);
  StartProgramm(node);
end;

procedure TfrmStartProgMain.RunAsProgListChange(Sender: TObject);
var
  cb: TComboBox;
  i: LongInt;
  node: TMRXMLNode;
begin
  cb := TComboBox(Sender);
  i := cb.ItemIndex;
  node := TMRXMLNode(cb.Items.Objects[i]);
  frmStartProgStartOther.ed_params.Text := node.Attribute['params'].Value;
end;

procedure TfrmStartProgMain.mi_setupClick(Sender: TObject);
begin
  if (frmStartProgSetup <> nil) then
    Exit;

  Application.CreateForm(TfrmStartProgSetup, frmStartProgSetup);
  frmStartProgSetup.Config := FConfXML;
  frmStartProgSetup.DefaultNode := FDefaultNode;
  frmStartProgSetup.StatusBar1.SimpleText := FConfigFileName;
  frmStartProgSetup.FillTreeView;

  if (frmStartProgSetup.ShowModal = mrOK) then
  begin
    FDefaultNode := frmStartProgSetup.DefaultNode;
    SaveConfig;
    SetMenu;
  end;

  frmStartProgSetup.Free;
  frmStartProgSetup := nil;
end;

procedure TfrmStartProgMain.mi_shutdownClick(Sender: TObject);
begin
  ExitOS(EWX_POWEROFF or EWX_FORCE);
end;

procedure TfrmStartProgMain.mi_standbyClick(Sender: TObject);
begin
  SetSuspendState(False, False, False);
end;

procedure TfrmStartProgMain.PopupMenu1Popup(Sender: TObject);
begin
  mi_hibernate.Visible := HibernateAllowed;
  mi_standby.Visible := SuspendAllowed;
end;

procedure TfrmStartProgMain.SaveConfig;
var
  confstream: TMemoryStream;
begin
  confstream := TMemoryStream.Create;
  FConfXML.SaveToStream(confstream, FDoCompress);
  confstream.Position := 0;
  confstream.SaveToFile(FConfigFileName);
  confstream.Free;
end;

procedure TfrmStartProgMain.SetConfigFileName(const AValue: string);
begin
  if FConfigFileName = AValue then exit;
  FConfigFileName := AValue;
end;

procedure TfrmStartProgMain.SetMenu;
const
  OSBIT = 32{$IFDEF CPU64} + 32{$ENDIF};

  procedure SetMenuItems(RootNode: TMRXMLNode; ParentMenu: TMenuItem; var count: Integer);
  var
    attr: TMRXMLNodeAttributes;
    dosep: Boolean;
    dosep2: Boolean;
    i: LongInt;
    ismain: Boolean;
    mi: TMenuItem;
    node: TMRXMLNode;
    sl: TStringList;
  begin
    node := RootNode.GetFirstChild;
    sl := TStringList.Create;
    sl.Sorted := True;
    sl.Duplicates := dupAccept;
    ParentMenu.Visible := (node <> nil);
    dosep := False;

    // Erst die Einträge mit Submenüs
    while (node <> nil) do
    begin
      attr := node.Attribute['art'];
      ismain := (attr <> nil);

      if (attr <> nil) then
        ismain := (attr.Value = 'menu');

      if (ismain) then
      begin
        dosep := True;
        sl.AddObject('AAAAA' + node.Attribute['name'].Value, node);
        i := sl.IndexOfObject(node);
        mi := TMenuItem.Create(ParentMenu);
        mi.Name := Format('mi_menu%.4d', [count]);
        mi.Caption := node.Attribute['name'].Value;
        count := count + 1;
        ParentMenu.Insert(i, mi);
        SetMenuItems(node, mi, count);
      end; // if (ismain)

      node := node.GetNextSibling;
    end; // while (node <> nil)


    // dann die Programme
    if (dosep) then
    begin
      mi := TMenuItem.Create(ParentMenu);
      i := sl.AddObject('AAAAAZZZZZ', mi);
      mi.Name := Format('mi_menu%.4d', [count]);
      mi.Caption := '-';
      ParentMenu.Insert(i, mi);
      count := count + 1;
    end; // if (dosep)

    dosep2 := False;
    node := RootNode.GetFirstChild;

    while (node <> nil) do
    begin
      attr := node.Attribute['art'];
      ismain := (attr <> nil);

      if (attr <> nil) then
        ismain := (attr.Value = 'prog');

      if (ismain) then
      begin
        dosep2 := True;
        sl.AddObject('ZZZZZ' + node.Attribute['name'].Value, node);
        i := sl.IndexOfObject(node);
        mi := TMenuItem.Create(ParentMenu);
        mi.Name := Format('mi_menu%.4d', [count]);
        mi.Caption := node.Attribute['name'].Value;
        mi.Default := node.Attribute['default'].AsBooleanDef(False);

        if (mi.Default) then
          FDefaultNode := node;

        FAllProgs.Add(node);
        mi.Tag := FAllProgs.Count - 1;
        mi.OnClick := @mi_programmClick;
        count := count + 1;
        ParentMenu.Insert(i, mi);
      end; // if (ismain)

      node := node.GetNextSibling;
    end; // while (node <> nil)

    if ((dosep xor dosep2) and dosep) then
    begin
      i := sl.IndexOf('AAAAAZZZZZ');
      mi := TMenuItem(sl.Objects[i]);
      mi.Free;
      sl.Delete(i);
    end; // if ((dosep xor dosep2) and dosep)

    sl.Free;
  end;

  procedure ClearMenu;
  var
    mi: TMenuItem;
    s: String;
    i: Integer;
    sl: TList;
  begin
    sl := TList.Create;

    for i := PopupMenu1.Items.Count - 1 downto 0 do
    begin
      mi := PopupMenu1.Items.Items[i];
      s := mi.Name;

      if (Pos('mi_menu', s) = 1) then
      begin
        sl.Add(mi);
      end; // if (Pos('mi_menu', s) = 1)
    end; // for i := 0 to PopupMenu1.Items.Count - 1

    if (sl.Count = 0) then
    begin
      sl.Free;
      exit;
    end;


    for i := 0 to sl.Count - 1 do
    begin
      TMenuItem(sl[i]).Free;
    end; // for i := 0 to sl.Count - 1

    sl.Free;
    FDefaultNode := nil;
  end;
var
  c: Integer;
  def: String;
  rn: TMRXMLNode;
  s: String;
  FvI: TFileVersionInfo;
begin
  FAllProgs.Clear;
  ClearMenu;
  rn := FConfXML.RootNode.Child('Menu');
  c := 0;
  SetMenuItems(rn, PopupMenu1.Items, c);
  mi_sep1.Visible := (rn.CountChildren > 0);
  mi_setup.Default := (FDefaultNode = nil);
  FvI := FileVersionInfo(ParamStr(0));
  s := '';
  s := FvI.FileVersion;

  if (FDefaultNode <> nil) then
    def := FDefaultNode.Attribute['name'].Value;

  TrayIcon1.Hint := Format('StartProg v%s - %dbit%sDefault: %s', [s, OSBIT, LineEnding, def]);
end;

procedure TfrmStartProgMain.StartProgramm(node: TMRXMLNode);
var
  s: String;
  sdir: String;
  StartThread: TSPStartThread;
  t: String;
begin
  s := node.Child('exename').Value;

  if (s = 'DEFBRO') then
    s := GetDefaultBrowser;

  if (s <> '') then
  begin
    t := node.Child('parameter').Value;

    if (t = #0) then
      t := '';

    if (UpperCase(s) = 'DEFBRO') then
      s := GetDefaultBrowser;

    sdir := node.Child('startdir').Value;

    if (sdir = #0) then
      sdir := ExtractFilePath(s);


    StartThread := TSPStartThread.Create(True);
    StartThread.ExeName := s;
    StartThread.StartDir := sdir;
    StartThread.Parameters:=t;
    StartThread.WindowState:=TShowWindowOptions(node.Child('startmethod').AsInteger);
    StartThread.Resume;
  end;
end;

procedure TfrmStartProgMain.TrayIcon1DblClick(Sender: TObject);
begin
  if (FDefaultNode = nil) then
    mi_setup.Click
  else
    StartProgramm(FDefaultNode);
end;

initialization
  {$I frm_startprogmain.lrs}

end.

