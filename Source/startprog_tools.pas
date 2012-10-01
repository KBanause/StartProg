unit StartProg_Tools;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, MRFunktionen;

{$IFDEF UNIX}
  {$I startprog_tools.unix_int.inc}
{$ENDIF}
{$IFDEF DARWIN}
  {$I startprog_tools.darwin_int.inc}
{$ENDIF}

const
  EWX_LOGOFF = 0;
  EWX_SHUTDOWN = 1;
  EWX_REBOOT = 2;
  EWX_FORCE = 4;
  EWX_POWEROFF = 8;
  EWX_FORCEIFHUNG = 16;
  SPVERSION = '3.0.4';

type
  TFileVersionInfo = record
    FileType,
    CompanyName,
    FileDescription,
    FileVersion,
    InternalName,
    LegalCopyRight,
    LegalTradeMarks,
    OriginalFileName,
    ProductName,
    ProductVersion,
    Comments,
    SpecialBuildStr,
    PrivateBuildStr,
    FileFunction: string;
    DebugBuild,
    PreRelease,
    SpecialBuild,
    PrivateBuild,
    Patched,
    InfoInferred: Boolean;
  end;

function ExitOS(RebootParam: LongWord): Boolean;
function FileVersionInfo(const sAppNamePath: TFileName): TFileVersionInfo;
function GetDefaultBrowser: string;
function HibernateAllowed: Boolean;
function LockWorkstation: Boolean;
function SetSuspendState(Hibernate, ForceCritical, DisableWakeEvent: Boolean): Boolean;
function SuspendAllowed: Boolean;

{$IFDEF WINDOWS}
  {$I StartProg_Tools.win_int.inc}
{$ENDIF}

implementation

{$IFDEF WINDOWS}
  {$I StartProg_Tools.win_imp.inc}
{$ENDIF}
{$IFDEF UNIX}
  {$I startprog_tools.unix_imp.inc}
{$ENDIF}
{$IFDEF DARWIN}
  {$I startprog_tools.darwin_imp.inc}
{$ENDIF}

end.
