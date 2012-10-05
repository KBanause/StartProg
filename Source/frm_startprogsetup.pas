unit frm_StartProgSetup;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  ComCtrls, mrxml, Menus, ExtCtrls, Buttons, EditBtn, StdCtrls;

type
  TSPShowWindow = (spsShowMaximized = 7, spsShowMinimized = 8, spsShowNormal = 12);

  { TfrmStartProgSetup }

  TfrmStartProgSetup = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    bt_saveprog: TButton;
    cb_showwindow: TComboBox;
    chb_default: TCheckBox;
    dired_startupdir: TDirectoryEdit;
    ed_parameters: TEdit;
    fned_filename: TFileNameEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    mi_rename: TMenuItem;
    mi_delprog: TMenuItem;
    mi_delmenu: TMenuItem;
    mi_sep1: TMenuItem;
    mi_newprog: TMenuItem;
    mi_newmenu: TMenuItem;
    Panel1: TPanel;
    Panel2: TPanel;
    PopupMenu1: TPopupMenu;
    SelectDirectoryDialog1: TSelectDirectoryDialog;
    StatusBar1: TStatusBar;
    TreeView1: TTreeView;
    procedure bt_saveprogClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure mi_delprogClick(Sender: TObject);
    procedure mi_newmenuClick(Sender: TObject);
    procedure mi_newprogClick(Sender: TObject);
    procedure mi_renameClick(Sender: TObject);
    procedure PopupMenu1Popup(Sender: TObject);
    procedure TreeView1DragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure TreeView1DragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure TreeView1Edited(Sender: TObject; Node: TTreeNode; var S: string);
    procedure TreeView1Editing(Sender: TObject; Node: TTreeNode;
      var AllowEdit: Boolean);
    procedure TreeView1KeyUp(Sender: TObject; var Key: Word; Shift: TShiftState
      );
    procedure TreeView1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure TreeView1SelectionChanged(Sender: TObject);
  private
    { private declarations }
    selectedtnode: TTreeNode;

    function NameNotExist(RootNode: TMRXMLNode; AName: string): Boolean;
  public
    { public declarations }
    Config: TMRXMLClass;
    DefaultNode: TMRXMLNode;

    procedure FillTreeView;
  end; 

var
  frmStartProgSetup: TfrmStartProgSetup;

implementation

uses
  frm_StartProgInputBox,
  {$IFDEF WINDOWS}
    windows,
  {$ENDIF}
  process;

{ TfrmStartProgSetup }

procedure TfrmStartProgSetup.bt_saveprogClick(Sender: TObject);
  procedure CheckOldDefaults(RootNode: TMRXMLNode; NewDefault: TMRXMLNode);
  var
    node: TMRXMLNode;
  begin
    node := RootNode.GetFirstChild;

    while (node <> nil) do
    begin
      if (node.Attribute['art'].Value = 'menu') then
      begin
        CheckOldDefaults(node, NewDefault);
      end // if (node.Attribute['art'].Value = 'menu')
      else
      if (node <> NewDefault) then
      begin
        node.Attribute['default'].AsBoolean := False;
      end; // if (node <> NewDefault)

      node := node.GetNextSibling;
    end; // while (node <> nil)
  end;
var
  tnode: TTreeNode;
  xmlnode: TMRXMLNode;
begin
  tnode := TreeView1.Selected;
  xmlnode := TMRXMLNode(tnode.Data);
  xmlnode.Child('exename').Value := fned_filename.Text;
  xmlnode.Child('startdir').Value := dired_startupdir.Text;
  xmlnode.Child('parameter').Value := ed_parameters.Text;
  xmlnode.Child('startmethod').AsInteger := Integer(cb_showwindow.ItemIndex);
  xmlnode.Attribute['default'].AsBoolean := chb_default.Checked;

  if (chb_default.Checked) then
  begin
    CheckOldDefaults(Config.RootNode, xmlnode);
    DefaultNode := xmlnode;
  end;
end;

procedure TfrmStartProgSetup.FillTreeView;
  procedure SetNodeItems(RootNode: TMRXMLNode; ParentNode: TTreeNode; var count: Integer);
  var
    attr: TMRXMLNodeAttributes;
    ismain: Boolean;
    mi: TTreeNode;
    node: TMRXMLNode;
    sl: TStringList;
  begin
    node := RootNode.GetFirstChild;
    sl := TStringList.Create;
    sl.Sorted := True;
    sl.Duplicates := dupAccept;

    // Erst die Einträge mit Submenüs
    while (node <> nil) do
    begin
      attr := node.Attribute['art'];
      ismain := (attr <> nil);

      if (attr <> nil) then
        ismain := (attr.Value = 'menu');

      if (ismain) then
      begin
        sl.AddObject('AAAAA' + node.Attribute['name'].Value, node);
        mi := TreeView1.Items.AddChildObject(ParentNode, '[' + node.Attribute['name'].Value + ']', node);
        count := count + 1;
        SetNodeItems(node, mi, count);
      end; // if (ismain)

      node := node.GetNextSibling;
    end; // while (node <> nil)


    // dann die Programme
    node := RootNode.GetFirstChild;

    while (node <> nil) do
    begin
      attr := node.Attribute['art'];
      ismain := (attr <> nil);

      if (attr <> nil) then
        ismain := (attr.Value = 'prog');

      if (ismain) then
      begin
        sl.AddObject('ZZZZZ' + node.Attribute['name'].Value, node);
        mi := TreeView1.Items.AddChildObject(ParentNode, node.Attribute['name'].Value, node);
        count := count + 1;
      end; // if (ismain)

      node := node.GetNextSibling;
    end; // while (node <> nil)

    sl.Free;
  end;
var
  c: Integer;
begin
  TreeView1.BeginUpdate;
  TreeView1.Items.Clear;
  c := 0;
  SetNodeItems(Config.RootNode.Child('Menu'), nil, c);
  TreeView1.AlphaSort;
  //TreeView1.FullExpand;
  TreeView1.EndUpdate;
end;

procedure TfrmStartProgSetup.FormCreate(Sender: TObject);
begin
  {$IFDEF UNIX}
  fned_filename.Filter := 'Script-Dateien|*.sh;*.pl;*.py|Alle Dateien|*';
  {$ENDIF}
  {$IFDEF WINDOWS}
  fned_filename.Filter := 'EXE-Files|*.exe|Script-Dateien|*.bat;*.cmd|COM-Dateien|*.com|Ausführbare Dateien|*.exe;*.bat;*.cmd;*.com|Alle Dateien|*.*';
  {$ENDIF}
end;

procedure TfrmStartProgSetup.mi_delprogClick(Sender: TObject);
const
  ARTTODEL: array[0..1]of string = ('Untermenü', 'Programm');

var
  res: LongInt;
  tnode: TTreeNode;
  xmlnode: TMRXMLNode;
  xmlp: TMRXMLNode;
  s: String;
begin
  tnode := TreeView1.Selected;
  xmlnode := TMRXMLNode(tnode.Data);
  s := xmlnode.Attribute['name'].Value;
  res := MessageDlg(Format('%s wirklich löschen?', [ARTTODEL[TMenuItem(Sender).Tag]]),
    Format('%s "%s" wirklich löschen?', [ARTTODEL[TMenuItem(Sender).Tag], s]), mtConfirmation, mbYesNo, 0);

  if (res = mrYes) then
  begin
    xmlp := xmlnode.ParentNode;
    xmlp.DeleteChild(xmlnode);
    TreeView1.Items.Delete(tnode);
  end; // if (res = mrYes)
end;

procedure TfrmStartProgSetup.mi_newmenuClick(Sender: TObject);
var
  NameIsOK: Boolean;
  node: TTreeNode;
  s: String;
  xmlnode: TMRXMLNode;
begin
  node := TreeView1.Selected;
  TreeView1.BeginUpdate;

  if (node <> nil) then
  begin
    s := node.Text;

    if ((s[1] <> '[') or (s[Length(s)] <> ']')) then
      node := node.Parent;
  end; // if (node <> nil)

  s := '';

  repeat
    if (not MRInputBox('Neues Untermenü', 'Name', s, s)) then
    begin
      TreeView1.EndUpdate;
      Exit;
    end;

    NameIsOK := True;

    if (node = nil) then
      xmlnode := Config.RootNode.Child('Menu')
    else
      xmlnode := TMRXMLNode(node.Data);

    NameIsOK := NameNotExist(xmlnode, s);

    if (not NameIsOK) then
      ShowMessage(Format('"%s" bereits vergeben. Bitte neuen Namen auswählen.', [s]));
  until (NameIsOK);

  xmlnode := Config.AddChild(xmlnode, 'Item');
  xmlnode.Attribute['art'].Value := 'menu';
  xmlnode.Attribute['name'].Value := s;
  node := TreeView1.Items.AddChildObject(node, '[' + s + ']', xmlnode);
  TreeView1.AlphaSort;
  node.Expand(False);
  TreeView1.Selected := node;
  TreeView1.EndUpdate;
end;

procedure TfrmStartProgSetup.mi_newprogClick(Sender: TObject);
var
  NameIsOK: Boolean;
  node: TTreeNode;
  s: String;
  xmlnode: TMRXMLNode;
begin
  node := TreeView1.Selected;
  TreeView1.BeginUpdate;

  if (node <> nil) then
  begin
    s := node.Text;

    if ((s[1] <> '[') or (s[Length(s)] <> ']')) then
      node := node.Parent;
  end; // if (node <> nil)

  s := 'DEFAULT';

  repeat
    if (not MRInputBox('Neues Programm', 'Name', s, s)) then
    begin
      TreeView1.EndUpdate;
      Exit;
    end;

    NameIsOK := True;

    if (node = nil) then
      xmlnode := Config.RootNode.Child('Menu')
    else
      xmlnode := TMRXMLNode(node.Data);

    NameIsOK := NameNotExist(xmlnode, s);

    if (not NameIsOK) then
      ShowMessage(Format('"%s" bereits vergeben. Bitte neuen Namen auswählen.', [s]));
  until (NameIsOK);

  xmlnode := Config.AddChild(xmlnode, 'Item');
  xmlnode.Attribute['art'].Value := 'prog';
  xmlnode.Attribute['name'].Value := s;
  xmlnode.Attribute['default'].AsBoolean := False;
  Config.AddChild(xmlnode, 'exename');
  Config.AddChild(xmlnode, 'startdir');
  Config.AddChild(xmlnode, 'parameter');
  Config.AddChild(xmlnode, 'startmethod').AsInteger := Integer(swoShowNormal);
  node := TreeView1.Items.AddChildObject(node, s, xmlnode);
  TreeView1.AlphaSort;
  node.Expand(False);
  TreeView1.Selected := node;
  TreeView1.EndUpdate;
end;

procedure TfrmStartProgSetup.mi_renameClick(Sender: TObject);
var
  node: TTreeNode;
  xmlnode: TMRXMLNode;
  NameIsOK: Boolean;
  s: String;
begin
  TreeView1.BeginUpdate;
  node := TreeView1.Selected;
  xmlnode := TMRXMLNode(node.Data);
  NameIsOK := True;
  s := xmlnode.Attribute['name'].Value;

  repeat
    if (MRInputBox('Umbenennen', 'Neuer Name', s, s)) then
    begin
      if (AnsiStrIComp(PChar(s), PChar(xmlnode.Attribute['name'].Value)) = 0) then
      begin
        Exit;
      end; // if (AnsiStrIComp(PChar(s), PChar(xmlnode.Attribute['name'].Value)) = 0)

      NameIsOK := NameNotExist(xmlnode.ParentNode, s);

      if (not NameIsOK) then
        ShowMessage(Format('"%s" bereits vergeben. Bitte neuen Namen auswählen.', [s]));
    end // if (MRInputBox('Umbenennen', 'Neuer Name', s, s))
    else
      Exit;
  until (NameIsOK);

  xmlnode.Attribute['name'].Value := s;

  if (xmlnode.Attribute['art'].Value = 'menu') then
    s := '[' + s + ']';

  node.Text := s;
  TreeView1.AlphaSort;
  TreeView1.Selected := node;
  TreeView1.EndUpdate;
end;

procedure TfrmStartProgSetup.PopupMenu1Popup(Sender: TObject);
var
  node: TTreeNode;
  xmlnode: TMRXMLNode;
begin
  node := TreeView1.Selected;
  mi_newprog.Visible := True;
  mi_newmenu.Visible := True;
  mi_delmenu.Visible := (node <> nil);
  mi_delprog.Visible := (node <> nil);
  mi_sep1.Visible := (node <> nil);
  mi_rename.Visible := (node <> nil);

  if (node <> nil) then
  begin
    xmlnode := TMRXMLNode(node.Data);

    if (xmlnode.Attribute['art'].Value = 'prog') then
    begin
      mi_newmenu.Visible := False;
      mi_delmenu.Visible := False;
    end
    else
    begin
      mi_delprog.Visible := False;
    end;
  end; // if (node <> nil)
end;

procedure TfrmStartProgSetup.TreeView1DragDrop(Sender, Source: TObject; X,
  Y: Integer);
var
  tn: TTreeNode;
  xmlnode: TMRXMLNode;
  xmln: TMRXMLNode;
begin
  tn := TreeView1.GetNodeAt(x, y);
  xmlnode := TMRXMLNode(selectedtnode.Data);

  if (tn <> nil) then
    xmln := TMRXMLNode(tn.Data)
  else
    xmln := Config.RootNode.Child('Menu');

  Config.MoveNode(xmlnode, xmln);
  FillTreeView;
end;

procedure TfrmStartProgSetup.TreeView1DragOver(Sender, Source: TObject; X,
  Y: Integer; State: TDragState; var Accept: Boolean);
var
  tn: TTreeNode;
  xmlnode: TMRXMLNode;
begin
  tn := TreeView1.GetNodeAt(x, y);
  Accept := (tn = nil);

  if (tn <> nil) then
  begin
    xmlnode := TMRXMLNode(tn.Data);
    Accept := (xmlnode.Attribute['art'].Value = 'menu');
  end; // if (tn <> nil)

  Accept := (Accept and (selectedtnode <> nil));
end;

procedure TfrmStartProgSetup.TreeView1Edited(Sender: TObject; Node: TTreeNode;
  var S: string);
var
  xmlnode: TMRXMLNode;
  NameIsOK: Boolean;
  t: String;
begin
  xmlnode := TMRXMLNode(Node.Data);
  NameIsOK := True;
  t := xmlnode.Attribute['name'].Value;

  if (AnsiStrIComp(PChar(s), PChar(t)) = 0) then
  begin
    s := t;
    Exit;
  end; // if (AnsiStrIComp(PChar(s), PChar(t)) = 0)

  NameIsOK := NameNotExist(xmlnode.ParentNode, s);

  if (not NameIsOK) then
  begin
    ShowMessage(Format('"%s" bereits vergeben. Bitte neuen Namen auswählen.', [s]));
    s := t;
    Exit;
  end; // if (not NameIsOK)

  TreeView1.BeginUpdate;
  xmlnode.Attribute['name'].Value := s;

  if (xmlnode.Attribute['art'].Value = 'menu') then
    s := '[' + s + ']';
end;

procedure TfrmStartProgSetup.TreeView1Editing(Sender: TObject; Node: TTreeNode;
  var AllowEdit: Boolean);
var
  xmlnode: TMRXMLNode;
begin
  xmlnode := TMRXMLNode(Node.Data);
  Node.Text := xmlnode.Attribute['name'].Value;
  AllowEdit := True;
end;

procedure TfrmStartProgSetup.TreeView1KeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  xmlnode: TMRXMLNode;
begin
  if ((TreeView1.Selected <> nil) and (Shift = [])) then
  begin
  {$IFDEF WINDOWS}
    if (Key = VK_F2) then
    begin
      Key := 0;
      mi_rename.Click;
    end; // if (Key = VK_F2)

    if (Key = VK_DELETE) then
    begin
      Key := 0;
      xmlnode := TMRXMLNode(TreeView1.Selected.Data);

      if (xmlnode.Attribute['art'].Value = 'prog') then
        mi_delprog.Click
      else
        mi_delmenu.Click;
    end; // if (Key = VK_DELETE)
  {$ENDIF}
  end; // if ((TreeView1.Selected <> nil) and (Shift = []))
end;

procedure TfrmStartProgSetup.TreeView1MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  selectedtnode := TreeView1.GetNodeAt(X, Y);
  TreeView1.BeginDrag(False);
end;

procedure TfrmStartProgSetup.TreeView1SelectionChanged(Sender: TObject);
var
  tnode: TTreeNode;
  xmlnode: TMRXMLNode;
begin
  tnode := TreeView1.Selected;
  Panel2.Visible := False;

  if (tnode <> nil) then
  begin
    xmlnode := TMRXMLNode(tnode.Data);

    if (xmlnode.Attribute['art'].Value = 'prog') then
    begin
      Panel2.Visible := True;

      if (xmlnode.Child('exename') = nil) then
        Config.AddChild(xmlnode, 'exename');

      fned_filename.Text := xmlnode.Child('exename').Value;

      if (xmlnode.Child('startdir') = nil) then
        Config.AddChild(xmlnode, 'startdir');

      dired_startupdir.Text := xmlnode.Child('startdir').Value;

      if (xmlnode.Child('parameter') = nil) then
        Config.AddChild(xmlnode, 'parameter');

      ed_parameters.Text := xmlnode.Child('parameter').Value;

      if (xmlnode.Child('startmethod') = nil) then
        Config.AddChild(xmlnode, 'startmethod').AsInteger := Integer(swoShowNormal);

      cb_showwindow.ItemIndex := xmlnode.Child('startmethod').AsInteger;
      chb_default.Checked := xmlnode.Attribute['default'].AsBooleanDef(False);
      fned_filename.SetFocus;
    end; // if (xmlnode.Attribute['art'].Value = 'menu')
  end; // if (tnode <> nil)
end;

function TfrmStartProgSetup.NameNotExist(RootNode: TMRXMLNode; AName: string): Boolean;
var
  node: TMRXMLNode;
  s: String;
begin
  node := RootNode.GetFirstChild;
  Result := True;

  while (node <> nil) do
  begin
    s := node.Attribute['name'].Value;

    if (AnsiStrIComp(PChar(s), PChar(AName)) = 0) then
    begin
      Result := False;
      Exit;
    end; // if (AnsiStrIComp(PChar(s), PChar(AName)) = 0)

    node := node.GetNextSibling;
  end; // while (node <> nil)
end;

initialization
  {$I frm_startprogsetup.lrs}

end.

