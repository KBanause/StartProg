uses
  windows, shellapi, jwawinuser, registry, strutils, Dialogs, winsock;

type
  TStartupInfoW = record
    cb: DWORD;
    lpReserved: LPWSTR;
    lpDesktop: LPWSTR;
    lpTitle: LPWSTR;
    dwX: DWORD;
    dwY: DWORD;
    dwXSize: DWORD;
    dwYSize: DWORD;
    dwXCountChars: DWORD;
    dwYCountChars: DWORD;
    dwFillAttribute: DWORD;
    dwFlags: DWORD;
    wShowWindow: WORD;
    cbReserved2: WORD;
    lpReserved2: LPBYTE;
    hStdInput: THANDLE;
    hStdOutput: THANDLE;
    hStdError: THANDLE;
  end;
  PStartupInfoW = ^TStartupInfoW;

const
  LOGON_WITH_PROFILE = $00000001;
  LOGON_NETCREDENTIALS_ONLY = $00000002;
  LOGON_ZERO_PASSWORD_BUFFER = DWORD($80000000);

function CreateProcessWithLogonW(lpUsername, lpDomain, lpPassword: LPWSTR; dwLogonFlags: dword;
  lpApplicationName, lpCommandLine: LPWSTR; dwCreationFlags: dword; lpEnvironment: pointer;
  lpCurrentDirectory: LPWSTR; lpStartupInfo: PStartUpInfoW;
  lpProcessInfo: PProcessInformation): boolean; stdcall; external 'advapi32.dll';

function HibernateAllowed: Boolean;
type
  TIsPwrHibernateAllowed = function: Boolean;
  stdcall;
var
  hPowrprof: HMODULE;
  IsPwrHibernateAllowed: TIsPwrHibernateAllowed;
begin
  Result := False;
  hPowrprof := LoadLibrary('powrprof.dll');
  if hPowrprof <> 0 then
  begin
    try
      IsPwrHibernateAllowed := TIsPwrHibernateAllowed(GetProcAddress(hPowrprof, 'IsPwrHibernateAllowed'));
      if @IsPwrHibernateAllowed <> nil then
      begin
        Result := IsPwrHibernateAllowed();
      end;
    finally
      FreeLibrary(hPowrprof);
    end;
  end;
end;

function SetSuspendState(Hibernate, ForceCritical, DisableWakeEvent: Boolean
  ): Boolean;
type
  T_SetSuspendState = function (Hibernate, ForceCritical, DisableWakeEvent: BOOL): BOOL;

  function LinkAPI(const module, functionname: string): Pointer;
  var
    hLib: HMODULE;
  begin
    hLib := GetModulehandle(PChar(module));
    if hLib = 0 then
      hLib := LoadLibrary(PChar(module));
    if hLib <> 0 then
      Result := getProcAddress(hLib, PChar(functionname))
    else
      Result := nil;
  end;

var
  _SetSuspendState: T_SetSuspendState;
begin
  if not Assigned(_SetSuspendState) then
    _SetSuspendState := T_SetSuspendState(LinkAPI('POWRPROF.dll', 'SetSuspendState'));
  if Assigned(_SetSuspendState) then
    Result := _SetSuspendState(Hibernate, ForceCritical,
      DisableWakeEvent)
  else
    Result := False;
end;

function SuspendAllowed: Boolean;
type
  TIsPwrSuspendAllowed = function: Boolean;
  stdcall;
var
  hPowrprof: HMODULE;
  IsPwrSuspendAllowed: TIsPwrSuspendAllowed;
begin
  Result := False;
  hPowrprof := LoadLibrary('powrprof.dll');
  if hPowrprof <> 0 then
  begin
    try
      IsPwrSuspendAllowed := TIsPwrSuspendAllowed(GetProcAddress(hPowrprof, 'IsPwrSuspendAllowed'));
      if @IsPwrSuspendAllowed <> nil then
      begin
        Result := IsPwrSuspendAllowed();
      end;
    finally
      FreeLibrary(hPowrprof);
    end;
  end;
end;

function ExitOS(RebootParam: LongWord): Boolean;
const
  SE_SHUTDOWN_NAME = 'SeShutdownPrivilege';
var
  TTokenHd: THandle;
  TTokenPvg: TTokenPrivileges;
  cbtpPrevious: DWORD;
  rTTokenPvg: TTokenPrivileges;
  pcbtpPreviousRequired: DWORD;
  tpResult: Boolean;
begin
  if Win32Platform = VER_PLATFORM_WIN32_NT then
  begin
    tpResult := OpenProcessToken(GetCurrentProcess(),
      TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY,
      TTokenHd);
    if tpResult then
    begin
      tpResult := LookupPrivilegeValue(nil,
                                       SE_SHUTDOWN_NAME,
                                       TTokenPvg.Privileges[0].Luid);
      TTokenPvg.PrivilegeCount := 1;
      TTokenPvg.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED;
      cbtpPrevious := SizeOf(rTTokenPvg);
      pcbtpPreviousRequired := 0;
      if tpResult then
        Windows.AdjustTokenPrivileges(TTokenHd,
                                      False,
                                      TTokenPvg,
                                      cbtpPrevious,
                                      rTTokenPvg,
                                      pcbtpPreviousRequired);
    end;
  end;
  Result := ExitWindowsEx(RebootParam, 0);
end;

function FileVersionInfo(const sAppNamePath: TFileName): TFileVersionInfo;
var
  rSHFI: TSHFileInfo;
  iRet: Integer;
  VerSize: Integer;
  VerBuf: PChar;
  VerBufValue: Pointer;
  VerHandle: Cardinal;
  VerBufLen: Cardinal;
  VerKey: string;
  FixedFileInfo: PVSFixedFileInfo;

  // dwFileType, dwFileSubtype
  function GetFileSubType(FixedFileInfo: PVSFixedFileInfo): string;
  begin
    case FixedFileInfo^.dwFileType of

      VFT_UNKNOWN: Result    := 'Unknown';
      VFT_APP: Result        := 'Application';
      VFT_DLL: Result        := 'DLL';
      VFT_STATIC_LIB: Result := 'Static-link Library';

      VFT_DRV:
        case
          FixedFileInfo^.dwFileSubtype of
          VFT2_UNKNOWN: Result         := 'Unknown Driver';
          VFT2_DRV_COMM: Result        := 'Communications Driver';
          VFT2_DRV_PRINTER: Result     := 'Printer Driver';
          VFT2_DRV_KEYBOARD: Result    := 'Keyboard Driver';
          VFT2_DRV_LANGUAGE: Result    := 'Language Driver';
          VFT2_DRV_DISPLAY: Result     := 'Display Driver';
          VFT2_DRV_MOUSE: Result       := 'Mouse Driver';
          VFT2_DRV_NETWORK: Result     := 'Network Driver';
          VFT2_DRV_SYSTEM: Result      := 'System Driver';
          VFT2_DRV_INSTALLABLE: Result := 'InstallableDriver';
          VFT2_DRV_SOUND: Result       := 'Sound Driver';
        end;
      VFT_FONT:
        case FixedFileInfo^.dwFileSubtype of
          VFT2_UNKNOWN: Result       := 'Unknown Font';
          VFT2_FONT_RASTER: Result   := 'Raster Font';
          VFT2_FONT_VECTOR: Result   := 'Vector Font';
          VFT2_FONT_TRUETYPE: Result := 'Truetype Font';
          else;
        end;
      VFT_VXD: Result := 'Virtual Defice Identifier = ' +
          IntToHex(FixedFileInfo^.dwFileSubtype, 8);
    end;
  end;


  function HasdwFileFlags(FixedFileInfo: PVSFixedFileInfo; Flag: Word): Boolean;
  begin
    Result := (FixedFileInfo^.dwFileFlagsMask and
      FixedFileInfo^.dwFileFlags and
      Flag) = Flag;
  end;

  function GetFixedFileInfo: PVSFixedFileInfo;
  begin
    if not VerQueryValue(VerBuf, '', Pointer(Result), VerBufLen) then
      Result := nil
  end;

  function GetInfo(const aKey: string): string;
  begin
    Result := '';
    VerKey := Format('\StringFileInfo\%.4x%.4x\%s',
      [LoWord(Integer(VerBufValue^)),
      HiWord(Integer(VerBufValue^)), aKey]);
    if VerQueryValue(VerBuf, PChar(VerKey), VerBufValue, VerBufLen) then
      Result := StrPas(VerBufValue);
  end;

  function QueryValue(const aValue: string): string;
  begin
    Result := '';
    // obtain version information about the specified file
    if GetFileVersionInfo(PChar(sAppNamePath), VerHandle, VerSize, VerBuf) and
      // return selected version information
      VerQueryValue(VerBuf, '\VarFileInfo\Translation', VerBufValue, VerBufLen) then
      Result := GetInfo(aValue);
  end;
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
  // Get the file type
  if SHGetFileInfo(PChar(sAppNamePath), 0, rSHFI, SizeOf(rSHFI), SHGFI_TYPENAME) <> 0 then
  begin
    Result.FileType := rSHFI.szTypeName;
  end;

  iRet := SHGetFileInfo(PChar(sAppNamePath), 0, rSHFI, SizeOf(rSHFI), SHGFI_EXETYPE);
  if iRet <> 0 then
  begin
    // determine whether the OS can obtain version information
    VerSize := GetFileVersionInfoSize(PChar(sAppNamePath), VerHandle);
    if VerSize > 0 then
    begin
      VerBuf := AllocMem(VerSize);
      try
        with Result do
        begin
          CompanyName      := QueryValue('CompanyName');
          FileDescription  := QueryValue('FileDescription');
          FileVersion      := QueryValue('FileVersion');
          InternalName     := QueryValue('InternalName');
          LegalCopyRight   := QueryValue('LegalCopyRight');
          LegalTradeMarks  := QueryValue('LegalTradeMarks');
          OriginalFileName := QueryValue('OriginalFileName');
          ProductName      := QueryValue('ProductName');
          ProductVersion   := QueryValue('ProductVersion');
          Comments         := QueryValue('Comments');
          SpecialBuildStr  := QueryValue('SpecialBuild');
          PrivateBuildStr  := QueryValue('PrivateBuild');
          // Fill the VS_FIXEDFILEINFO structure
          FixedFileInfo := GetFixedFileInfo;
          DebugBuild    := HasdwFileFlags(FixedFileInfo, VS_FF_DEBUG);
          PreRelease    := HasdwFileFlags(FixedFileInfo, VS_FF_PRERELEASE);
          PrivateBuild  := HasdwFileFlags(FixedFileInfo, VS_FF_PRIVATEBUILD);
          SpecialBuild  := HasdwFileFlags(FixedFileInfo, VS_FF_SPECIALBUILD);
          Patched       := HasdwFileFlags(FixedFileInfo, VS_FF_PATCHED);
          InfoInferred  := HasdwFileFlags(FixedFileInfo, VS_FF_INFOINFERRED);
          FileFunction  := GetFileSubType(FixedFileInfo);
        end;
      finally
        FreeMem(VerBuf, VerSize);
      end
    end;
  end;
end;

function LockWorkstation: Boolean;
begin
  Result := jwawinuser.LockWorkStation;
end;

function GetDefaultBrowser: string;
var
  reg: TRegistry;
  s: string;
  i: Integer;
  tosearch: Char;
begin
  Result := '';

  try
    reg := TRegistry.Create(KEY_READ);
    reg.RootKey := HKEY_CLASSES_ROOT;
    reg.OpenKeyReadOnly('\htmlfile\shell\open\command');
    s := reg.ReadString('');
    tosearch := ' ';
    i := 1;

    if (s[1] = '"') then
    begin
      i := 2;
      tosearch := '"';
    end; // if (s[1] = '"')

    i := PosEx(tosearch, s, i);
    s := Trim(Copy(s, 1, i));

    if (Length(s) > 0) then
    begin
      if (s[1] = '"') then
      begin
        Delete(s, 1, 1);
        Delete(s, Length(s), 1);
      end; // if (s[1] = '"')
    end;

    reg.CloseKey;
    reg.Free;
    Result := s;
  except
    ShowMessage('Geht nicht');
    Result := '';
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// Procedure : ServiceGetStatus
// Comment   : Author: DieHardMan

function ServiceGetStatus(sMachine, sService: PChar): DWORD;
  //{******************************************}
  //{*** Parameters: ***}
  //{*** sService: specifies the name of the service to open
  //{*** sMachine: specifies the name of the target computer
  //{*** ***}
  //{*** Return Values: ***}
  //{*** -1 = Error opening service ***}
  //{*** 1 = SERVICE_STOPPED ***}
  //{*** 2 = SERVICE_START_PENDING ***}
  //{*** 3 = SERVICE_STOP_PENDING ***}
  //{*** 4 = SERVICE_RUNNING ***}
  //{*** 5 = SERVICE_CONTINUE_PENDING ***}
  //{*** 6 = SERVICE_PAUSE_PENDING ***}
  //{*** 7 = SERVICE_PAUSED ***}
  //{******************************************}
var
  SCManHandle, SvcHandle: SC_Handle;
  SS: TServiceStatus;
  dwStat: DWORD;
begin
  dwStat := 0;
  // Open service manager handle.
  SCManHandle := OpenSCManager(sMachine, nil, SC_MANAGER_CONNECT);
  if (SCManHandle > 0) then
  begin
    SvcHandle := OpenService(SCManHandle, sService, SERVICE_QUERY_STATUS);
    // if Service installed
    if (SvcHandle > 0) then
    begin
      // SS structure holds the service status (TServiceStatus);
      if (QueryServiceStatus(SvcHandle, SS)) then
        dwStat := ss.dwCurrentState;
      CloseServiceHandle(SvcHandle);
    end;
    CloseServiceHandle(SCManHandle);
  end;
  Result := dwStat;
end;

function ServiceRunning(sMachine, sService: PChar): Boolean;
begin
  Result := SERVICE_RUNNING = ServiceGetStatus(sMachine, sService);
end;

function CreateProcessAsLogon(const User, PW, Application, CmdLine: WideString): DWORD;
begin
  Result := CreateProcessAsLogon(User, PW, Application, CmdLine, UTF8Decode(GetCurrentDir));
end;

function CreateProcessAsLogon(const User, PW, Application, CmdLine, StartDir: WideString): DWORD;
var
  si                : TStartupInfoW;
  pif               : TProcessInformation;
  s                 : WideString;
  sa                : TStrArray;
  TokenHandle       : THandle;
  domain: PWideChar;
  sdir: PWideChar;
begin
  ZeroMemory(@si, sizeof(si));
  si.cb := sizeof(si);
  si.dwFlags := STARTF_USESHOWWINDOW;
  si.wShowWindow := 1;

  if CmdLine = '' then
    s := '"' + Application + '"'
  else
    s := '"' + Application + '" ' + CmdLine;

  if (ServiceRunning('', 'seclogon')) then
  begin
    SetLastError(0);
    Explode(UTF8Encode(User), '\', sa);

    if (Length(sa) = 1) then
    begin
      SetLength(sa, 2);
      sa[1] := sa[0];
      sa[0] := '';
    end; // if (Length(sa) = 1)

    domain := nil;
    sdir := nil;

    if (sa[0] <> '') then
      domain := PWideChar(sa[0]);

    if (StartDir <> '') then
      sdir := PWideChar(StartDir);

    if (CreateProcessWithLogonW(PWideChar(UTF8Decode(sa[1])), domain, PWideChar(PW), 0, nil, PWideChar(s),
      CREATE_DEFAULT_ERROR_MODE, nil, sdir, @si, @pif)) then
    begin
      WaitForSingleObject(pif.hProcess, INFINITE);
      CloseHandle(pif.hProcess);
      CloseHandle(pif.hThread);
    end;

    Result := GetLastError;
  end // if (ServiceRunning('', 'seclogon'))
  else
  begin
    Explode(UTF8Encode(User), '\', sa);

    if (Length(sa) = 1) then
    begin
      SetLength(sa, 2);
      sa[1] := sa[0];
      sa[0] := '';
    end; // if (Length(sa) = 1)

    Result := 0;

    if (LogonUserW(PWideChar(UTF8Decode(sa[1])), PWideChar(UTF8Decode(sa[0])),
      PWideChar(PW), LOGON32_LOGON_INTERACTIVE, LOGON32_PROVIDER_DEFAULT or LOGON32_PROVIDER_WINNT50,
      TokenHandle)) then
    begin
      SetLastError(0);

      if (CreateProcessAsUser(TokenHandle, nil, PChar(UTF8Encode(s)),
        nil, nil, False, NORMAL_PRIORITY_CLASS, nil, PChar(UTF8Encode(StartDir)), @si, @pif)) then
      begin
        WaitForSingleObject(pif.hProcess, INFINITE);
        CloseHandle(pif.hProcess);
        CloseHandle(pif.hThread);
      end;
    end;

    Result := GetLastError;
  end; // else (if (ServiceRunning('', 'seclogon')))
end;
