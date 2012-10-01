program StartProg;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms
  { you can add units after this }, frm_StartProgMain,
frm_StartProgSetup, mrxml, frm_StartProgInputBox,
StartProg_Tools, StartProg_StartThread, frm_StartProgGetCredentials, 
frm_StartProgStartOther, MRFunktionen_System;

{$IFDEF WINDOWS}{$R startprog.rc}{$ENDIF}

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmStartProgMain, frmStartProgMain);
  Application.Run;
end.

