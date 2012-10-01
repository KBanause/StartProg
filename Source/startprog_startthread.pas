unit StartProg_StartThread;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, process, Dialogs;

type

  { TSPStartThread }

  TSPStartThread = class(TThread)
  protected
    procedure Execute; override;
  public
    ExeName: string;
    Parameters: string;
    StartDir: string;
    WindowState: TShowWindowOptions;

    constructor Create(CreateSuspended: Boolean;
                       const StackSize: SizeUInt = DefaultStackSize);
  end;

  { TSPRunAsThread }

  TSPRunAsThread = class(TThread)
  protected
    procedure Execute; override;
  public
    Benutzername: string;
    ExeName: string;
    Parameters: string;
    Password: string;
    StartDir: string;
    WindowState: TShowWindowOptions;
    LastError: LongWord;

    constructor Create(CreateSuspended: Boolean;
                       const StackSize: SizeUInt = DefaultStackSize);

    procedure ShowLastError;
  end;

implementation

uses StartProg_Tools;

{ TSPStartThread }

procedure TSPStartThread.Execute;
var
  Process1: TProcess;
  s: String;
begin
  if (FileExists(ExeName)) then
  begin
    Process1 := TProcess.Create(nil);
    Process1.CommandLine := Format('"%s" %s', [ExeName, Parameters]);
    s := Process1.CommandLine;

    if ((Length(StartDir) < 3) and (not DirectoryExists(StartDir))) then
      StartDir := ExtractFilePath(ExeName);

    Process1.CurrentDirectory := StartDir;
    Process1.ShowWindow := WindowState;

    try
      Process1.Execute;
      Process1.WaitOnExit;
    except
      s := Process1.CommandLine + LineEnding + Process1.CurrentDirectory;
      ShowMessage(s);
    end;

    Process1.Free;
  end; // if (FileExists(ExeName))
end;

constructor TSPStartThread.Create(CreateSuspended: Boolean;
  const StackSize: SizeUInt);
begin
  inherited Create(CreateSuspended, StackSize);
  Self.FreeOnTerminate := True;
end;

{ TSPRunAsThread }

constructor TSPRunAsThread.Create(CreateSuspended: Boolean;
  const StackSize: SizeUInt);
begin
  inherited Create(CreateSuspended, StackSize);
  Self.FreeOnTerminate := True;
end;

{$IFDEF WINDOWS}
procedure TSPRunAsThread.Execute;
var
  Appl: Widestring;
  Params: WideString;
  PW: WideString;
  SDir: WideString;
  User: WideString;
begin
  Appl := UTF8Decode(ExeName);
  Params := UTF8Decode(Parameters);
  PW := UTF8Decode(Password);
  SDir := UTF8Decode(StartDir);
  User := UTF8Decode(Benutzername);
  LastError := CreateProcessAsLogon(User, PW, Appl, Params, SDir);

  if (LastError > 0) then
  begin
    Synchronize(@ShowLastError);
  end; // if (i > 0)
end;
{$ELSE}
procedure TSPRunAsThread.Execute;
begin
end;
{$ENDIF}

procedure TSPRunAsThread.ShowLastError;
begin
  ShowMessage(SysErrorMessage(LastError));
end;


end.

