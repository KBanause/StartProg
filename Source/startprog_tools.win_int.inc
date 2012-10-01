function ServiceGetStatus(sMachine, sService: PChar): DWORD;
function ServiceRunning(sMachine, sService: PChar): Boolean;
function CreateProcessAsLogon(const User, PW, Application, CmdLine: WideString): DWORD;
function CreateProcessAsLogon(const User, PW, Application, CmdLine, StartDir: WideString): DWORD;
