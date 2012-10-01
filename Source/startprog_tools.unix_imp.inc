uses
  unix, baseunix;

function HibernateAllowed: Boolean;
begin
  Result := False;
  Result := (fpgeteuid = 0);
end;

function SetSuspendState(Hibernate, ForceCritical, DisableWakeEvent: Boolean
  ): Boolean;
begin
  Result := False;
end;

function SuspendAllowed: Boolean;
begin
  Result := False;
  Result := (fpgeteuid = 0);
end;

function ExitOS(RebootParam: LongWord): Boolean;
begin
  Result := False;
end;

function FileVersionInfo(const sAppNamePath: TFileName): TFileVersionInfo;
begin
  // Initialize the Result
  with Result do
  begin
    FileType         := '';
    CompanyName      := '';
    FileDescription  := '';
    FileVersion      := '';
    InternalName     := '';
    LegalCopyRight   := '';
    LegalTradeMarks  := '';
    OriginalFileName := '';
    ProductName      := '';
    ProductVersion   := '';
    Comments         := '';
    SpecialBuildStr  := '';
    PrivateBuildStr  := '';
    FileFunction     := '';
    DebugBuild       := False;
    Patched          := False;
    PreRelease       := False;
    SpecialBuild     := False;
    PrivateBuild     := False;
    InfoInferred     := False;
  end;

  Result.FileVersion := SPVERSION;
end;

function LockWorkStation: Boolean;
begin
  Result := False;
end;

function GetDefaultBrowser: string;
begin
  Result := '';
end;
