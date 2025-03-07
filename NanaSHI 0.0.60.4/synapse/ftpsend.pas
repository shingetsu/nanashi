{==============================================================================|
| Project : Ararat Synapse                                       | 003.000.000 |
|==============================================================================|
| Content: FTP client                                                          |
|==============================================================================|
| Copyright (c)1999-2004, Lukas Gebauer                                        |
| All rights reserved.                                                         |
|                                                                              |
| Redistribution and use in source and binary forms, with or without           |
| modification, are permitted provided that the following conditions are met:  |
|                                                                              |
| Redistributions of source code must retain the above copyright notice, this  |
| list of conditions and the following disclaimer.                             |
|                                                                              |
| Redistributions in binary form must reproduce the above copyright notice,    |
| this list of conditions and the following disclaimer in the documentation    |
| and/or other materials provided with the distribution.                       |
|                                                                              |
| Neither the name of Lukas Gebauer nor the names of its contributors may      |
| be used to endorse or promote products derived from this software without    |
| specific prior written permission.                                           |
|                                                                              |
| THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"  |
| AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE    |
| IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE   |
| ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR  |
| ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL       |
| DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR   |
| SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER   |
| CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT           |
| LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY    |
| OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH  |
| DAMAGE.                                                                      |
|==============================================================================|
| The Initial Developer of the Original Code is Lukas Gebauer (Czech Republic).|
| Portions created by Lukas Gebauer are Copyright (c) 1999-2004.               |
| All Rights Reserved.                                                         |
|==============================================================================|
| Contributor(s):                                                              |
|   Petr Esner <petr.esner@atlas.cz>                                           |
|==============================================================================|
| History: see HISTORY.HTM from distribution package                           |
|          (Found at URL: http://www.ararat.cz/synapse/)                       |
|==============================================================================}

// RFC-959, RFC-2228, RFC-2428

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$H+}

unit ftpsend;

interface

uses
  SysUtils, Classes,
  {$IFDEF STREAMSEC}
  TlsInternalServer, TlsSynaSock,
  {$ENDIF}
  blcksock, synautil, synsock;

const
  cFtpProtocol = 'ftp';
  cFtpDataProtocol = 'ftp-data';

  FTP_OK = 255;
  FTP_ERR = 254;

type
  TLogonActions = array [0..17] of byte;

  TFTPStatus = procedure(Sender: TObject; Response: Boolean;
    const Value: string) of object;

  TFTPListRec = class(TObject)
  private
    FFileName: string;
    FDirectory: Boolean;
    FReadable: Boolean;
    FFileSize: Longint;
    FFileTime: TDateTime;
    FOriginalLine: string;
    FMask: string;
  public
    procedure Assign(Value: TFTPListRec); virtual;
  published
    property FileName: string read FFileName write FFileName;
    property Directory: Boolean read FDirectory write FDirectory;
    property Readable: Boolean read FReadable write FReadable;
    property FileSize: Longint read FFileSize write FFileSize;
    property FileTime: TDateTime read FFileTime write FFileTime;
    property OriginalLine: string read FOriginalLine write FOriginalLine;
    property Mask: string read FMask write FMask;
  end;

  TFTPList = class(TObject)
  protected
    FList: TList;
    FLines: TStringList;
    FMasks: TStringList;
    FUnparsedLines: TStringList;
    Monthnames: string;
    BlockSize: string;
    DirFlagValue: string;
    FileName: string;
    VMSFileName: string;
    Day: string;
    Month: string;
    ThreeMonth: string;
    YearTime: string;
    Year: string;
    Hours: string;
    HoursModif: string;
    Minutes: string;
    Seconds: string;
    Size: string;
    Permissions: string;
    DirFlag: string;
    function GetListItem(Index: integer): TFTPListRec; virtual;
    function ParseEPLF(Value: string): Boolean; virtual;
    procedure ClearStore; virtual;
    function ParseByMask(Value, NextValue, Mask: string): Integer; virtual;
    function CheckValues: Boolean; virtual;
    procedure FillRecord(const Value: TFTPListRec); virtual;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear; virtual;
    function Count: integer; virtual;
    procedure Assign(Value: TFTPList); virtual;
    procedure ParseLines; virtual;
    property List: TList read FList;
    property Items[Index: Integer]: TFTPListRec read GetListItem; default;
    property Lines: TStringList read FLines;
    property Masks: TStringList read FMasks;
    property UnparsedLines: TStringList read FUnparsedLines;
  end;

  TFTPSend = class(TSynaClient)
  protected
    FOnStatus: TFTPStatus;
    {$IFDEF STREAMSEC}
    FSock: TSsTCPBlockSocket;
    FDSock: TSsTCPBlockSocket;
    FTLSServer: TCustomTLSInternalServer;
    {$ELSE}
    FSock: TTCPBlockSocket;
    FDSock: TTCPBlockSocket;
    {$ENDIF}
    FResultCode: Integer;
    FResultString: string;
    FFullResult: TStringList;
    FAccount: string;
    FFWHost: string;
    FFWPort: string;
    FFWUsername: string;
    FFWPassword: string;
    FFWMode: integer;
    FDataStream: TMemoryStream;
    FDataIP: string;
    FDataPort: string;
    FDirectFile: Boolean;
    FDirectFileName: string;
    FCanResume: Boolean;
    FPassiveMode: Boolean;
    FForceDefaultPort: Boolean;
    FForceOldPort: Boolean;
    FFtpList: TFTPList;
    FBinaryMode: Boolean;
    FAutoTLS: Boolean;
    FIsTLS: Boolean;
    FIsDataTLS: Boolean;
    FTLSonData: Boolean;
    FFullSSL: Boolean;
    function Auth(Mode: integer): Boolean; virtual;
    function Connect: Boolean; virtual;
    function InternalStor(const Command: string; RestoreAt: integer): Boolean; virtual;
    function DataSocket: Boolean; virtual;
    function AcceptDataSocket: Boolean; virtual;
    procedure DoStatus(Response: Boolean; const Value: string); virtual;
  public
    CustomLogon: TLogonActions;
    constructor Create;
    destructor Destroy; override;
    function ReadResult: Integer; virtual;
    procedure ParseRemote(Value: string); virtual;
    procedure ParseRemoteEPSV(Value: string); virtual;
    function FTPCommand(const Value: string): integer; virtual;
    function Login: Boolean; virtual;
    function Logout: Boolean; virtual;
    procedure Abort; virtual;
    function List(Directory: string; NameList: Boolean): Boolean; virtual;
    function RetrieveFile(const FileName: string; Restore: Boolean): Boolean; virtual;
    function StoreFile(const FileName: string; Restore: Boolean): Boolean; virtual;
    function StoreUniqueFile: Boolean; virtual;
    function AppendFile(const FileName: string): Boolean; virtual;
    function RenameFile(const OldName, NewName: string): Boolean; virtual;
    function DeleteFile(const FileName: string): Boolean; virtual;
    function FileSize(const FileName: string): integer; virtual;
    function NoOp: Boolean; virtual;
    function ChangeWorkingDir(const Directory: string): Boolean; virtual;
    function ChangeToRootDir: Boolean; virtual;
    function DeleteDir(const Directory: string): Boolean; virtual;
    function CreateDir(const Directory: string): Boolean; virtual;
    function GetCurrentDir: String; virtual;
    function DataRead(const DestStream: TStream): Boolean; virtual;
    function DataWrite(const SourceStream: TStream): Boolean; virtual;
  published
    property ResultCode: Integer read FResultCode;
    property ResultString: string read FResultString;
    property FullResult: TStringList read FFullResult;
    property Account: string read FAccount Write FAccount;
    property FWHost: string read FFWHost Write FFWHost;
    property FWPort: string read FFWPort Write FFWPort;
    property FWUsername: string read FFWUsername Write FFWUsername;
    property FWPassword: string read FFWPassword Write FFWPassword;
    property FWMode: integer read FFWMode Write FFWMode;
{$IFDEF STREAMSEC}
    property Sock: TSsTCPBlockSocket read FSock;
    property DSock: TSsTCPBlockSocket read FDSock;
    property TLSServer: TCustomTLSInternalServer read FTLSServer write FTLSServer;
{$ELSE}
    property Sock: TTCPBlockSocket read FSock;
    property DSock: TTCPBlockSocket read FDSock;
{$ENDIF}
    property DataStream: TMemoryStream read FDataStream;
    property DataIP: string read FDataIP;
    property DataPort: string read FDataPort;
    property DirectFile: Boolean read FDirectFile Write FDirectFile;
    property DirectFileName: string read FDirectFileName Write FDirectFileName;
    property CanResume: Boolean read FCanResume;
    property PassiveMode: Boolean read FPassiveMode Write FPassiveMode;
    property ForceDefaultPort: Boolean read FForceDefaultPort Write FForceDefaultPort;
    property ForceOldPort: Boolean read FForceOldPort Write FForceOldPort;
    property OnStatus: TFTPStatus read FOnStatus write FOnStatus;
    property FtpList: TFTPList read FFtpList;
    property BinaryMode: Boolean read FBinaryMode Write FBinaryMode;
    property AutoTLS: Boolean read FAutoTLS Write FAutoTLS;
    property FullSSL: Boolean read FFullSSL Write FFullSSL;
    property IsTLS: Boolean read FIsTLS;
    property IsDataTLS: Boolean read FIsDataTLS;
    property TLSonData: Boolean read FTLSonData write FTLSonData;
  end;

function FtpGetFile(const IP, Port, FileName, LocalFile,
  User, Pass: string): Boolean;
function FtpPutFile(const IP, Port, FileName, LocalFile,
  User, Pass: string): Boolean;
function FtpInterServerTransfer(
  const FromIP, FromPort, FromFile, FromUser, FromPass: string;
  const ToIP, ToPort, ToFile, ToUser, ToPass: string): Boolean;

implementation

constructor TFTPSend.Create;
begin
  inherited Create;
  FFullResult := TStringList.Create;
  FDataStream := TMemoryStream.Create;
{$IFDEF STREAMSEC}
  FTLSServer := GlobalTLSInternalServer;
  FSock := TSsTCPBlockSocket.Create;
  FSock.BlockingRead := True;
  FSock.ConvertLineEnd := True;
  FDSock := TSsTCPBlockSocket.Create;
  FDSock.BlockingRead := True;
{$ELSE}
  FSock := TTCPBlockSocket.Create;
  FSock.ConvertLineEnd := True;
  FDSock := TTCPBlockSocket.Create;
{$ENDIF}
  FFtpList := TFTPList.Create;
  FTimeout := 300000;
  FTargetPort := cFtpProtocol;
  FUsername := 'anonymous';
  FPassword := 'anonymous@' + FSock.LocalName;
  FDirectFile := False;
  FPassiveMode := True;
  FForceDefaultPort := False;
  FForceOldPort := false;
  FAccount := '';
  FFWHost := '';
  FFWPort := cFtpProtocol;
  FFWUsername := '';
  FFWPassword := '';
  FFWMode := 0;
  FBinaryMode := True;
  FAutoTLS := False;
  FFullSSL := False;
  FIsTLS := False;
  FIsDataTLS := False;
  FTLSonData := True;
end;

destructor TFTPSend.Destroy;
begin
  FDSock.Free;
  FSock.Free;
  FFTPList.Free;
  FDataStream.Free;
  FFullResult.Free;
  inherited Destroy;
end;

procedure TFTPSend.DoStatus(Response: Boolean; const Value: string);
begin
  if assigned(OnStatus) then
    OnStatus(Self, Response, Value);
end;

function TFTPSend.ReadResult: Integer;
var
  s, c: string;
begin
  Result := 0;
  FFullResult.Clear;
  c := '';
  repeat
    s := FSock.RecvString(FTimeout);
    if c = '' then
      if length(s) > 3 then
        if s[4] in [' ', '-'] then
          c :=Copy(s, 1, 3);
    FResultString := s;
    FFullResult.Add(s);
    DoStatus(True, s);
    if FSock.LastError <> 0 then
      Break;
  until (c <> '') and (Pos(c + ' ', s) = 1);
  Result := StrToIntDef(c, 0);
  FResultCode := Result;
end;

function TFTPSend.FTPCommand(const Value: string): integer;
begin
  FSock.SendString(Value + CRLF);
  DoStatus(False, Value);
  Result := ReadResult;
end;

// based on idea by Petr Esner <petr.esner@atlas.cz>
function TFTPSend.Auth(Mode: integer): Boolean;
const
  //if not USER <username> then
  //  if not PASS <password> then
  //    if not ACCT <account> then ERROR!
  //OK!
  Action0: TLogonActions =
    (0, FTP_OK, 3,
     1, FTP_OK, 6,
     2, FTP_OK, FTP_ERR,
     0, 0, 0, 0, 0, 0, 0, 0, 0);

  //if not USER <FWusername> then
  //  if not PASS <FWPassword> then ERROR!
  //if SITE <FTPServer> then ERROR!
  //if not USER <username> then
  //  if not PASS <password> then
  //    if not ACCT <account> then ERROR!
  //OK!
  Action1: TLogonActions =
    (3, 6, 3,
     4, 6, FTP_ERR,
     5, FTP_ERR, 9,
     0, FTP_OK, 12,
     1, FTP_OK, 15,
     2, FTP_OK, FTP_ERR);

  //if not USER <FWusername> then
  //  if not PASS <FWPassword> then ERROR!
  //if USER <UserName>'@'<FTPServer> then OK!
  //if not PASS <password> then
  //  if not ACCT <account> then ERROR!
  //OK!
  Action2: TLogonActions =
    (3, 6, 3,
     4, 6, FTP_ERR,
     6, FTP_OK, 9,
     1, FTP_OK, 12,
     2, FTP_OK, FTP_ERR,
     0, 0, 0);

  //if not USER <FWusername> then
  //  if not PASS <FWPassword> then ERROR!
  //if not USER <username> then
  //  if not PASS <password> then
  //    if not ACCT <account> then ERROR!
  //OK!
  Action3: TLogonActions =
    (3, 6, 3,
     4, 6, FTP_ERR,
     0, FTP_OK, 9,
     1, FTP_OK, 12,
     2, FTP_OK, FTP_ERR,
     0, 0, 0);

  //OPEN <FTPserver>
  //if not USER <username> then
  //  if not PASS <password> then
  //    if not ACCT <account> then ERROR!
  //OK!
  Action4: TLogonActions =
    (7, 3, 3,
     0, FTP_OK, 6,
     1, FTP_OK, 9,
     2, FTP_OK, FTP_ERR,
     0, 0, 0, 0, 0, 0);

  //if USER <UserName>'@'<FTPServer> then OK!
  //if not PASS <password> then
  //  if not ACCT <account> then ERROR!
  //OK!
  Action5: TLogonActions =
    (6, FTP_OK, 3,
     1, FTP_OK, 6,
     2, FTP_OK, FTP_ERR,
     0, 0, 0, 0, 0, 0, 0, 0, 0);

  //if not USER <FWUserName>@<FTPServer> then
  //  if not PASS <FWPassword> then ERROR!
  //if not USER <username> then
  //  if not PASS <password> then
  //    if not ACCT <account> then ERROR!
  //OK!
  Action6: TLogonActions =
    (8, 6, 3,
     4, 6, FTP_ERR,
     0, FTP_OK, 9,
     1, FTP_OK, 12,
     2, FTP_OK, FTP_ERR,
     0, 0, 0);

  //if USER <UserName>@<FTPServer> <FWUserName> then ERROR!
  //if not PASS <password> then
  //  if not ACCT <account> then ERROR!
  //OK!
  Action7: TLogonActions =
    (9, FTP_ERR, 3,
     1, FTP_OK, 6,
     2, FTP_OK, FTP_ERR,
     0, 0, 0, 0, 0, 0, 0, 0, 0);

  //if not USER <UserName>@<FWUserName>@<FTPServer> then
  //  if not PASS <Password>@<FWPassword> then
  //    if not ACCT <account> then ERROR!
  //OK!
  Action8: TLogonActions =
    (10, FTP_OK, 3,
     11, FTP_OK, 6,
     2, FTP_OK, FTP_ERR,
     0, 0, 0, 0, 0, 0, 0, 0, 0);
var
  FTPServer: string;
  LogonActions: TLogonActions;
  i: integer;
  s: string;
  x: integer;
begin
  Result := False;
  if FFWHost = '' then
    Mode := 0;
  if (FTargetPort = cFtpProtocol) or (FTargetPort = '21') then
    FTPServer := FTargetHost
  else
    FTPServer := FTargetHost + ':' + FTargetPort;
  case Mode of
    -1:
      LogonActions := CustomLogon;
    1:
      LogonActions := Action1;
    2:
      LogonActions := Action2;
    3:
      LogonActions := Action3;
    4:
      LogonActions := Action4;
    5:
      LogonActions := Action5;
    6:
      LogonActions := Action6;
    7:
      LogonActions := Action7;
    8:
      LogonActions := Action8;
  else
    LogonActions := Action0;
  end;
  i := 0;
  repeat
    case LogonActions[i] of
      0:  s := 'USER ' + FUserName;
      1:  s := 'PASS ' + FPassword;
      2:  s := 'ACCT ' + FAccount;
      3:  s := 'USER ' + FFWUserName;
      4:  s := 'PASS ' + FFWPassword;
      5:  s := 'SITE ' + FTPServer;
      6:  s := 'USER ' + FUserName + '@' + FTPServer;
      7:  s := 'OPEN ' + FTPServer;
      8:  s := 'USER ' + FFWUserName + '@' + FTPServer;
      9:  s := 'USER ' + FUserName + '@' + FTPServer + ' ' + FFWUserName;
      10: s := 'USER ' + FUserName + '@' + FFWUserName + '@' + FTPServer;
      11: s := 'PASS ' + FPassword + '@' + FFWPassword;
    end;
    x := FTPCommand(s);
    x := x div 100;
    if (x <> 2) and (x <> 3) then
      Exit;
    i := LogonActions[i + x - 1];
    case i of
      FTP_ERR:
        Exit;
      FTP_OK:
        begin
          Result := True;
          Exit;
        end;
    end;
  until False;
end;


function TFTPSend.Connect: Boolean;
begin
  FSock.CloseSocket;
  FSock.Bind(FIPInterface, cAnyPort);
{$IFDEF STREAMSEC}
  if FFullSSL then
  begin
    if assigned(FTLSServer) then
      FSock.TLSServer := FTLSServer
    else
    begin
      result := False;
      Exit;
    end;
  end
  else
    FSock.TLSServer := nil;
{$ELSE}
  if FFullSSL then
    FSock.SSLEnabled := True;
{$ENDIF}
  if FSock.LastError = 0 then
    if FFWHost = '' then
      FSock.Connect(FTargetHost, FTargetPort)
    else
      FSock.Connect(FFWHost, FFWPort);
  Result := FSock.LastError = 0;
end;

function TFTPSend.Login: Boolean;
var
  x: integer;
begin
  Result := False;
  FCanResume := False;
  if not Connect then
    Exit;
  FIsTLS := FFullSSL;
  FIsDataTLS := False;
  repeat
    x := ReadResult div 100;
  until x <> 1;
  if x <> 2 then
    Exit;
  if FAutoTLS and not(FIsTLS) then
    if (FTPCommand('AUTH TLS') div 100) = 2 then
    begin
{$IFDEF STREAMSEC}
      if Assigned(FTLSServer) then
      begin
        Fsock.TLSServer := FTLSServer;
        Fsock.Connect('','');
        FIsTLS := FSock.LastError = 0;
      end;
{$ELSE}
      FSock.SSLDoConnect;
      FIsTLS := FSock.LastError = 0;
      FDSock.SSLCertificateFile := FSock.SSLCertificateFile;
      FDSock.SSLPrivateKeyFile := FSock.SSLPrivateKeyFile;
      FDSock.SSLCertCAFile := FSock.SSLCertCAFile;
{$ENDIF}
      if not FIsTLS then
      begin
        Result := False;
        Exit;
      end;
    end;
  if not Auth(FFWMode) then
    Exit;
  if FIsTLS then
  begin
    FTPCommand('PBSZ 0');
    if FTLSonData then
      FIsDataTLS := (FTPCommand('PROT P') div 100) = 2;
    if not FIsDataTLS then
      FTPCommand('PROT C');
  end;
  FTPCommand('TYPE I');
  FTPCommand('STRU F');
  FTPCommand('MODE S');
  if FTPCommand('REST 0') = 350 then
    if FTPCommand('REST 1') = 350 then
    begin
      FTPCommand('REST 0');
      FCanResume := True;
    end;
  Result := True;
end;

function TFTPSend.Logout: Boolean;
begin
  Result := (FTPCommand('QUIT') div 100) = 2;
  FSock.CloseSocket;
end;

procedure TFTPSend.ParseRemote(Value: string);
var
  n: integer;
  nb, ne: integer;
  s: string;
  x: integer;
begin
  Value := trim(Value);
  nb := Pos('(',Value);
  ne := Pos(')',Value);
  if (nb = 0) or (ne = 0) then
  begin
    nb:=RPos(' ',Value);
    s:=Copy(Value, nb + 1, Length(Value) - nb);
  end
  else
  begin
    s:=Copy(Value,nb+1,ne-nb-1);
  end;
  for n := 1 to 4 do
    if n = 1 then
      FDataIP := Fetch(s, ',')
    else
      FDataIP := FDataIP + '.' + Fetch(s, ',');
  x := StrToIntDef(Fetch(s, ','), 0) * 256;
  x := x + StrToIntDef(Fetch(s, ','), 0);
  FDataPort := IntToStr(x);
end;

procedure TFTPSend.ParseRemoteEPSV(Value: string);
var
  n: integer;
  s, v: string;
begin
  s := SeparateRight(Value, '(');
  s := Trim(SeparateLeft(s, ')'));
  Delete(s, Length(s), 1);
  v := '';
  for n := Length(s) downto 1 do
    if s[n] in ['0'..'9'] then
      v := s[n] + v
    else
      Break;
  FDataPort := v;
  FDataIP := FTargetHost;
end;

function TFTPSend.DataSocket: boolean;
var
  s: string;
begin
  Result := False;
  if FPassiveMode then
  begin
    if FSock.IP6used then
      s := '2'
    else
      s := '1';
    if not(FForceOldPort) and ((FTPCommand('EPSV ' + s) div 100) = 2) then
    begin
      ParseRemoteEPSV(FResultString);
    end
    else
      if FSock.IP6used then
        Exit
      else
      begin
        if (FTPCommand('PASV') div 100) <> 2 then
          Exit;
        ParseRemote(FResultString);
      end;
    FDSock.CloseSocket;
    FDSock.Bind(FIPInterface, cAnyPort);
    FDSock.Connect(FDataIP, FDataPort);
    Result := FDSock.LastError = 0;
  end
  else
  begin
    FDSock.CloseSocket;
    if FForceDefaultPort then
      s := cFtpDataProtocol
    else
      s := '0';
    //data conection from same interface as command connection
    FDSock.Bind(FSock.GetLocalSinIP, s);
    if FDSock.LastError <> 0 then
      Exit;
    FDSock.SetLinger(True, 10);
    FDSock.Listen;
    FDSock.GetSins;
    FDataIP := FDSock.GetLocalSinIP;
    FDataIP := FDSock.ResolveName(FDataIP);
    FDataPort := IntToStr(FDSock.GetLocalSinPort);
    if not FForceOldPort then
    begin
      if IsIp6(FDataIP) then
        s := '2'
      else
        s := '1';
      s := 'EPRT |' + s +'|' + FDataIP + '|' + FDataPort + '|';
      Result := (FTPCommand(s) div 100) = 2;
    end;
    if not Result and IsIP(FDataIP) then
    begin
      s := ReplaceString(FDataIP, '.', ',');
      s := 'PORT ' + s + ',' + IntToStr(FDSock.GetLocalSinPort div 256)
        + ',' + IntToStr(FDSock.GetLocalSinPort mod 256);
      Result := (FTPCommand(s) div 100) = 2;
    end;
  end;
end;

function TFTPSend.AcceptDataSocket: Boolean;
var
  x: TSocket;
begin
  if FPassiveMode then
    Result := True
  else
  begin
    Result := False;
    if FDSock.CanRead(FTimeout) then
    begin
      x := FDSock.Accept;
      if not FDSock.UsingSocks then
        FDSock.CloseSocket;
      FDSock.Socket := x;
      Result := True;
    end;
  end;
  if Result and FIsDataTLS then
  begin
{$IFDEF STREAMSEC}
    if Assigned(FTLSServer) then
    begin
      FDSock.TLSServer := FTLSServer;
      FDSock.Connect('','');
      Result := FDSock.LastError = 0;
    end
    else
      Result := False;
{$ELSE}
    FDSock.SSLDoConnect;
    Result := FDSock.LastError = 0;
{$ENDIF}
  end;
end;

function TFTPSend.DataRead(const DestStream: TStream): Boolean;
var
  x: integer;
  buf: string;
begin
  Result := False;
  try
    if not AcceptDataSocket then
      Exit;
    FDSock.RecvStreamRaw(DestStream, FTimeout);
    FDSock.CloseSocket;
    x := ReadResult;
    Result := (x div 100) = 2;
  finally
    FDSock.CloseSocket;
  end;
end;

function TFTPSend.DataWrite(const SourceStream: TStream): Boolean;
var
  x: integer;
begin
  Result := False;
  try
    if not AcceptDataSocket then
      Exit;
    FDSock.SendStreamRaw(SourceStream);
    if FDSock.LastError <> 0 then
      Exit;
    FDSock.CloseSocket;
    x := ReadResult;
    Result := (x div 100) = 2;
  finally
    FDSock.CloseSocket;
  end;
end;

function TFTPSend.List(Directory: string; NameList: Boolean): Boolean;
var
  x: integer;
begin
  Result := False;
  FDataStream.Clear;
  FFTPList.Clear;
  if Directory <> '' then
    Directory := ' ' + Directory;
  FTPCommand('TYPE A');
  if not DataSocket then
    Exit;
  if NameList then
    x := FTPCommand('NLST' + Directory)
  else
    x := FTPCommand('LIST' + Directory);
  if (x div 100) <> 1 then
    Exit;
  Result := DataRead(FDataStream);
  if (not NameList) and Result then
  begin
    FDataStream.Seek(0, soFromBeginning);
    FFTPList.Lines.LoadFromStream(FDataStream);
    FFTPList.ParseLines;
  end;
  FDataStream.Seek(0, soFromBeginning);
end;

function TFTPSend.RetrieveFile(const FileName: string; Restore: Boolean): Boolean;
var
  RetrStream: TStream;
begin
  Result := False;
  if FileName = '' then
    Exit;
  if not DataSocket then
    Exit;
  Restore := Restore and FCanResume;
  if FDirectFile then
    if Restore and FileExists(FDirectFileName) then
      RetrStream := TFileStream.Create(FDirectFileName,
        fmOpenReadWrite  or fmShareExclusive)
    else
      RetrStream := TFileStream.Create(FDirectFileName,
        fmCreate or fmShareDenyWrite)
  else
    RetrStream := FDataStream;
  try
    if FBinaryMode then
      FTPCommand('TYPE I')
    else
      FTPCommand('TYPE A');
    if Restore then
    begin
      RetrStream.Seek(0, soFromEnd);
      if (FTPCommand('REST ' + IntToStr(RetrStream.Size)) div 100) <> 3 then
        Exit;
    end
    else
      if RetrStream is TMemoryStream then
        TMemoryStream(RetrStream).Clear;
    if (FTPCommand('RETR ' + FileName) div 100) <> 1 then
      Exit;
    Result := DataRead(RetrStream);
    if not FDirectFile then
      RetrStream.Seek(0, soFromBeginning);
  finally
    if FDirectFile then
      RetrStream.Free;
  end;
end;

function TFTPSend.InternalStor(const Command: string; RestoreAt: integer): Boolean;
var
  SendStream: TStream;
  StorSize: integer;
begin
  Result := False;
  if FDirectFile then
    if not FileExists(FDirectFileName) then
      Exit
    else
      SendStream := TFileStream.Create(FDirectFileName,
        fmOpenRead or fmShareDenyWrite)
  else
    SendStream := FDataStream;
  try
    if not DataSocket then
      Exit;
    if FBinaryMode then
      FTPCommand('TYPE I')
    else
      FTPCommand('TYPE A');
    StorSize := SendStream.Size;
    if not FCanResume then
      RestoreAt := 0;
    if (StorSize > 0) and (RestoreAt = StorSize) then
    begin
      Result := True;
      Exit;
    end;
    if RestoreAt > StorSize then
      RestoreAt := 0;
    FTPCommand('ALLO ' + IntToStr(StorSize - RestoreAt));
    if FCanResume then
      if (FTPCommand('REST ' + IntToStr(RestoreAt)) div 100) <> 3 then
        Exit;
    SendStream.Seek(RestoreAt, soFromBeginning);
    if (FTPCommand(Command) div 100) <> 1 then
      Exit;
    Result := DataWrite(SendStream);
  finally
    if FDirectFile then
      SendStream.Free;
  end;
end;

function TFTPSend.StoreFile(const FileName: string; Restore: Boolean): Boolean;
var
  RestoreAt: integer;
begin
  Result := False;
  if FileName = '' then
    Exit;
  RestoreAt := 0;
  Restore := Restore and FCanResume;
  if Restore then
  begin
    RestoreAt := Self.FileSize(FileName);
    if RestoreAt < 0 then
      RestoreAt := 0;
  end;
  Result := InternalStor('STOR ' + FileName, RestoreAt);
end;

function TFTPSend.StoreUniqueFile: Boolean;
begin
  Result := InternalStor('STOU', 0);
end;

function TFTPSend.AppendFile(const FileName: string): Boolean;
begin
  Result := False;
  if FileName = '' then
    Exit;
  Result := InternalStor('APPE '+FileName, 0);
end;

function TFTPSend.NoOp: Boolean;
begin
  Result := (FTPCommand('NOOP') div 100) = 2;
end;

function TFTPSend.RenameFile(const OldName, NewName: string): Boolean;
begin
  Result := False;
  if (FTPCommand('RNFR ' + OldName) div 100) <> 3  then
    Exit;
  Result := (FTPCommand('RNTO ' + NewName) div 100) = 2;
end;

function TFTPSend.DeleteFile(const FileName: string): Boolean;
begin
  Result := (FTPCommand('DELE ' + FileName) div 100) = 2;
end;

function TFTPSend.FileSize(const FileName: string): integer;
var
  s: string;
begin
  Result := -1;
  if (FTPCommand('SIZE ' + FileName) div 100) = 2 then
  begin
    s := Trim(SeparateRight(ResultString, ' '));
    s := Trim(SeparateLeft(s, ' '));
    Result := StrToIntDef(s, -1);
  end;
end;

function TFTPSend.ChangeWorkingDir(const Directory: string): Boolean;
begin
  Result := (FTPCommand('CWD ' + Directory) div 100) = 2;
end;

function TFTPSend.ChangeToRootDir: Boolean;
begin
  Result := (FTPCommand('CDUP') div 100) = 2;
end;

function TFTPSend.DeleteDir(const Directory: string): Boolean;
begin
  Result := (FTPCommand('RMD ' + Directory) div 100) = 2;
end;

function TFTPSend.CreateDir(const Directory: string): Boolean;
begin
  Result := (FTPCommand('MKD ' + Directory) div 100) = 2;
end;

function TFTPSend.GetCurrentDir: String;
begin
  Result := '';
  if (FTPCommand('PWD') div 100) = 2 then
  begin
    Result := SeparateRight(FResultString, '"');
    Result := Trim(Separateleft(Result, '"'));
  end;
end;

procedure TFTPSend.Abort;
begin
  FDSock.StopFlag := True;
end;

{==============================================================================}

procedure TFTPListRec.Assign(Value: TFTPListRec);
begin
  FFileName := Value.FileName;
  FDirectory := Value.Directory;
  FReadable := Value.Readable;
  FFileSize := Value.FileSize;
  FFileTime := Value.FileTime;
  FOriginalLine := Value.OriginalLine;
  FMask := Value.Mask;
end;

constructor TFTPList.Create;
begin
  inherited Create;
  FList := TList.Create;
  FLines := TStringList.Create;
  FMasks := TStringList.Create;
  FUnparsedLines := TStringList.Create;
  //various UNIX
  FMasks.add('pppppppppp $!!!S*$TTT$DD$hh mm ss$YYYY$n*');
  FMasks.add('pppppppppp $!!!S*$DD$TTT$hh mm ss$YYYY$n*');
  FMasks.add('pppppppppp $!!!S*$TTT$DD$UUUUU$n*');  //mostly used UNIX format
  FMasks.add('pppppppppp $!!!S*$DD$TTT$UUUUU$n*');
  //MacOS
  FMasks.add('pppppppppp $!!S*$TTT$DD$UUUUU$n*');
  FMasks.add('pppppppppp $!S*$TTT$DD$UUUUU$n*');
  //Novell
  FMasks.add('d            $!S*$TTT$DD$UUUUU$n*');
  //Windows
  FMasks.add('MM DD YY  hh mmH $ d!n*');
  FMasks.add('MM DD YY  hh mmH !S* n*');
  FMasks.add('MM DD YYYY  hh mmH $ d!n*');
  FMasks.add('MM DD YYYY  hh mmH !S* n*');
  FMasks.add('DD MM YYYY  hh mmH $ d!n*');
  FMasks.add('DD MM YYYY  hh mmH !S* n*');
  //VMS
  FMasks.add('v*$  DD TTT YYYY hh mm');
  FMasks.add('v*$!DD TTT YYYY hh mm');
  //AS400
  FMasks.add('!S*$MM DD YY hh mm ss !n*');
  FMasks.add('!S*$DD MM YY hh mm ss !n*');
  FMasks.add('n*!S*$MM DD YY hh mm ss d');
  FMasks.add('n*!S*$DD MM YY hh mm ss d');
  //Distinct
  FMasks.add('d    $S*$TTT DD YYYY  hh mm$n*');
  FMasks.add('d    $S*$TTT DD$hh mm$n*');
  //PC-NFSD
  FMasks.add('nnnnnnnn.nnn  dSSSSSSSSSSS MM DD YY  hh mmH');
  //VOS
  FMasks.add('-   SSSSS            YY MM DD hh mm ss  n*');
  FMasks.add('- d=  SSSSS  YY MM DD hh mm ss  n*');
  //Unissys ClearPath
  FMasks.add('nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn               SSSSSSSSS MM DD YYYY hh mm');
  FMasks.add('n*\x                                               SSSSSSSSS MM DD YYYY hh mm');
  //IBM
  FMasks.add('-     SSSSSSSSSSSS           d   MM DD YYYY   hh mm  n*');
  //OS9
  FMasks.add('-         YY MM DD hhmm d                        SSSSSSSSS n*');
  //tandem
  FMasks.add('nnnnnnnn                   SSSSSSS DD TTT YY hh mm ss');
  //MVS
  FMasks.add('-             YYYY MM DD                     SSSSS   d=O  n*');
  //BullGCOS8
  FMasks.add('             $S* MM DD YY hh mm ss  !n*');
  FMasks.add('d            $S* MM DD YY           !n*');
  //BullGCOS7
  FMasks.add('                                         TTT DD  YYYY n*');
  FMasks.add('  d                                                   n*');
end;

destructor TFTPList.Destroy;
begin
  Clear;
  FList.Free;
  FLines.Free;
  FMasks.Free;
  FUnparsedLines.Free;
  inherited Destroy;
end;

procedure TFTPList.Clear;
var
  n:integer;
begin
  for n := 0 to FList.Count - 1 do
    if Assigned(FList[n]) then
      TFTPListRec(FList[n]).Free;
  FList.Clear;
  FLines.Clear;
  FUnparsedLines.Clear;
end;

function TFTPList.Count: integer;
begin
  Result := FList.Count;
end;

function TFTPList.GetListItem(Index: integer): TFTPListRec;
begin
  Result := nil;
  if Index < Count then
    Result := TFTPListRec(FList[Index]);
end;

procedure TFTPList.Assign(Value: TFTPList);
var
  flr: TFTPListRec;
  n: integer;
begin
  Clear;
  for n := 0 to Value.Count - 1 do
  begin
    flr := TFTPListRec.Create;
    flr.Assign(Value[n]);
    Flist.Add(flr);
  end;
  Lines.Assign(Value.Lines);
  Masks.Assign(Value.Masks);
  UnparsedLines.Assign(Value.UnparsedLines);
end;

procedure TFTPList.ClearStore;
begin
  Monthnames := '';
  BlockSize := '';
  DirFlagValue := '';
  FileName := '';
  VMSFileName := '';
  Day := '';
  Month := '';
  ThreeMonth := '';
  YearTime := '';
  Year := '';
  Hours := '';
  HoursModif := '';
  Minutes := '';
  Seconds := '';
  Size := '';
  Permissions := '';
  DirFlag := '';
end;

function TFTPList.ParseByMask(Value, NextValue, Mask: string): Integer;
var
  Ivalue, IMask: integer;
  MaskC, LastMaskC: Char;
  c: char;
  s: string;
begin
  ClearStore;
  Result := 0;
  if Value = '' then
    Exit;
  if Mask = '' then
    Exit;
  Ivalue := 1;
  IMask := 1;
  Result := 1;
  LastMaskC := ' ';
  while Imask <= Length(mask) do
  begin
    if (Mask[Imask] <> '*') and (Ivalue > Length(Value)) then
    begin
      Result := 0;
      Exit;
    end;
    MaskC := Mask[Imask];
    c := Value[Ivalue];
    case MaskC of
      'n':
        FileName := FileName + c;
      'v':
        VMSFileName := VMSFileName + c;
      '.':
        begin
          if c in ['.', ' '] then
            FileName := TrimSP(FileName) + '.'
          else
          begin
            Result := 0;
            Exit;
          end;
        end;
      'D':
        Day := Day + c;
      'M':
        Month := Month + c;
      'T':
        ThreeMonth := ThreeMonth + c;
      'U':
        YearTime := YearTime + c;
      'Y':
        Year := Year + c;
      'h':
        Hours := Hours + c;
      'H':
        HoursModif := HoursModif + c;
      'm':
        Minutes := Minutes + c;
      's':
        Seconds := Seconds + c;
      'S':
        Size := Size + c;
      'p':
        Permissions := Permissions + c;
      'd':
        DirFlag := DirFlag + c;
      'x':
        if c <> ' ' then
          begin
            Result := 0;
            Exit;
          end;
      '*':
        begin
          s := '';
          if LastMaskC in ['n', 'v'] then
          begin
            if Imask = Length(Mask) then
              s := Copy(Value, IValue, Maxint)
            else
              while IValue <= Length(Value) do
              begin
                if Value[Ivalue] = ' ' then
                  break;
                s := s + Value[Ivalue];
                Inc(Ivalue);
              end;
            if LastMaskC = 'n' then
              FileName := FileName + s
            else
              VMSFileName := VMSFileName + s;
          end
          else
          begin
            while IValue <= Length(Value) do
            begin
              if not(Value[Ivalue] in ['0'..'9']) then
                break;
              s := s + Value[Ivalue];
              Inc(Ivalue);
            end;
            case LastMaskC of
              'S':
                Size := Size + s;
            end;
          end;
          Dec(IValue);
        end;
      '!':
        begin
          while IValue <= Length(Value) do
          begin
            if Value[Ivalue] = ' ' then
              break;
            Inc(Ivalue);
          end;
          while IValue <= Length(Value) do
          begin
            if Value[Ivalue] <> ' ' then
              break;
            Inc(Ivalue);
          end;
          Dec(IValue);
        end;
      '$':
        begin
          while IValue <= Length(Value) do
          begin
            if not(Value[Ivalue] in [' ', #9]) then
              break;
            Inc(Ivalue);
          end;
          Dec(IValue);
        end;
      '=':
        begin
          s := '';
          case LastmaskC of
            'S':
              begin
                while Imask <= Length(Mask) do
                begin
                  if not(Mask[Imask] in ['0'..'9']) then
                    break;
                  s := s + Mask[Imask];
                  Inc(Imask);
                end;
                Dec(Imask);
                BlockSize := s;
              end;
            'T':
              begin
                Monthnames := Copy(Mask, IMask, 12 * 3);
                Inc(IMask, 12 * 3);
              end;
            'd':
              begin
                Inc(Imask);
                DirFlagValue := Mask[Imask];
              end;
          end;
        end;
      '\':
        begin
          Value := NextValue;
          IValue := 0;
          Result := 2;
        end;
    end;
    Inc(Ivalue);
    Inc(Imask);
    LastMaskC := MaskC;
  end;
end;

function TFTPList.CheckValues: Boolean;
var
  x, n: integer;
begin
  Result := false;
  if FileName <> '' then
  begin
    if pos('?', VMSFilename) > 0 then
      Exit;
    if pos('*', VMSFilename) > 0 then
      Exit;
  end;
  if VMSFileName <> '' then
    if pos(';', VMSFilename) <= 0 then
      Exit;
  if (FileName = '') and (VMSFileName = '') then
    Exit;
  if Permissions <> '' then
  begin
    if length(Permissions) <> 10 then
      Exit;
    for n := 1 to 10 do
      if not(Permissions[n] in
        ['a', 'b', 'c', 'd', 'h', 'l', 'p', 'r', 's', 'w', 'x', 'y', '-']) then
        Exit;
  end;
  if Day <> '' then
  begin
    Day := TrimSP(Day);
    x := StrToIntDef(day, -1);
    if (x < 1) or (x > 31) then
      Exit;
  end;
  if Month <> '' then
  begin
    Month := TrimSP(Month);
    x := StrToIntDef(Month, -1);
    if (x < 1) or (x > 12) then
      Exit;
  end;
  if Hours <> '' then
  begin
    Hours := TrimSP(Hours);
    x := StrToIntDef(Hours, -1);
    if (x < 0) or (x > 24) then
      Exit;
  end;
  if HoursModif <> '' then
  begin
    if not (HoursModif[1] in ['a', 'A', 'p', 'P']) then
      Exit;
  end;
  if Minutes <> '' then
  begin
    Minutes := TrimSP(Minutes);
    x := StrToIntDef(Minutes, -1);
    if (x < 0) or (x > 59) then
      Exit;
  end;
  if Seconds <> '' then
  begin
    Seconds := TrimSP(Seconds);
    x := StrToIntDef(Seconds, -1);
    if (x < 0) or (x > 59) then
      Exit;
  end;
  if Size <> '' then
  begin
    Size := TrimSP(Size);
    for n := 1 to Length(Size) do
      if not (Size[n] in ['0'..'9']) then
        Exit;
  end;

  if length(Monthnames) = (12 * 3) then
    for n := 1 to 12 do
      CustomMonthNames[n] := Copy(Monthnames, ((n - 1) * 3) + 1, 3);
  if ThreeMonth <> '' then
  begin
    x := GetMonthNumber(ThreeMonth);
    if (x = 0) then
      Exit;
  end;
  if YearTime <> '' then
  begin
    YearTime := ReplaceString(YearTime, '-', ':');
    if pos(':', YearTime) > 0 then
    begin
      if (GetTimeFromstr(YearTime) = -1) then
        Exit;
    end
    else
    begin
      YearTime := TrimSP(YearTime);
      x := StrToIntDef(YearTime, -1);
      if (x = -1) then
        Exit;
      if (x < 1900) or (x > 2100) then
        Exit;
    end;
  end;
  if Year <> '' then
  begin
    Year := TrimSP(Year);
    x := StrToIntDef(Year, -1);
    if (x = -1) then
      Exit;
    if not(((x > 1900) and (x < 2100)) or ((x >= 0) and (x <= 99))) then
      Exit;
  end;
  Result := True;
end;

procedure TFTPList.FillRecord(const Value: TFTPListRec);
var
  s: string;
  x: integer;
  myear: Word;
  mmonth: Word;
  mday: Word;
  mhours, mminutes, mseconds: word;
  n: integer;
begin
  s := DirFlagValue;
  if s = '' then
    s := 'D';
  s := Uppercase(s);
  Value.Directory :=  s = Uppercase(DirFlag);
  if FileName <> '' then
    Value.FileName := SeparateLeft(Filename, ' -> ');
  if VMSFileName <> '' then
  begin
    Value.FileName := VMSFilename;
    Value.Directory := Pos('.DIR;',VMSFilename) > 0;
  end;
  Value.FileName := TrimSPRight(Value.FileName);
  Value.Readable := not Value.Directory;
  if BlockSize <> '' then
    x := StrToIntDef(BlockSize, 1)
  else
    x := 1;
  Value.FileSize := x * StrToIntDef(Size, 0);

  DecodeDate(Date,myear,mmonth,mday);
  mhours := 0;
  mminutes := 0;
  mseconds := 0;

  if Day <> '' then
    mday := StrToIntDef(day, 1);
  if Month <> '' then
    mmonth := StrToIntDef(Month, 1);
  if length(Monthnames) = (12 * 3) then
    for n := 1 to 12 do
      CustomMonthNames[n] := Copy(Monthnames, ((n - 1) * 3) + 1, 3);
  if ThreeMonth <> '' then
    mmonth := GetMonthNumber(ThreeMonth);
  if Year <> '' then
  begin
    myear := StrToIntDef(Year, 0);
    if (myear <= 99) and (myear > 50) then
      myear := myear + 1900;
    if myear <= 50 then
      myear := myear + 2000;
  end;
  if YearTime <> '' then
  begin
    if pos(':', YearTime) > 0 then
    begin
      mhours := StrToIntDef(Separateleft(YearTime, ':'), 0);
      mminutes := StrToIntDef(SeparateRight(YearTime, ':'), 0);
      if (Encodedate(myear, mmonth, mday)
        + EncodeTime(mHours, mminutes, 0, 0)) > now then
        Dec(mYear);
    end
    else
      myear := StrToIntDef(YearTime, 0);
  end;
  if Minutes <> '' then
    mminutes := StrToIntDef(Minutes, 0);
  if Seconds <> '' then
    mseconds := StrToIntDef(Seconds, 0);
  if Hours <> '' then
  begin
    mHours := StrToIntDef(Hours, 0);
    if HoursModif <> '' then
      if Uppercase(HoursModif[1]) = 'P' then
        if mHours <> 12 then
          mHours := MHours + 12;
  end;
  Value.FileTime := Encodedate(myear, mmonth, mday)
    + EncodeTime(mHours, mminutes, mseconds, 0);
  if Permissions <> '' then
  begin
    Value.Readable := Uppercase(permissions)[2] = 'R';
    if Uppercase(permissions)[1] = 'D' then
    begin
      Value.Directory := True;
      Value.Readable := false;
    end
    else
      if Uppercase(permissions)[1] = 'L' then
        Value.Directory := True;
  end;
end;

function TFTPList.ParseEPLF(Value: string): Boolean;
var
  s, os: string;
  flr: TFTPListRec;
begin
  Result := False;
  if Value <> '' then
    if Value[1] = '+' then
    begin
      os := Value;
      flr := TFTPListRec.create;
      s := Fetch(Value, ',');
      while s <> '' do
      begin
        if s[1] = #9 then
        begin
          flr.FileName := Copy(s, 2, Length(s) - 1);
        end;
        case s[1] of
          '/':
            flr.Directory := true;
          'r':
            flr.Readable := true;
          's':
            flr.FileSize := StrToIntDef(Copy(s, 2, Length(s) - 1), 0);
          'm':
            flr.FileTime := (StrToIntDef(Copy(s, 2, Length(s) - 1), 0) / 86400)
              + 25569;
        end;
        s := Fetch(Value, ',');
      end;
      if flr.FileName <> '' then
      if (flr.Directory and ((flr.FileName = '.') or (flr.FileName = '..')))
        or (flr.FileName = '') then
        flr.free
      else
      begin
        flr.OriginalLine := os;
        flr.Mask := 'EPLF';
        Flist.Add(flr);
        Result := True;
      end;
    end;
end;

procedure TFTPList.ParseLines;
var
  flr: TFTPListRec;
  n, m: Integer;
  S: string;
  x: integer;
  b: Boolean;
begin
  n := 0;
  while n < Lines.Count do
  begin
    if n = Lines.Count - 1 then
      s := ''
    else
      s := Lines[n + 1];
    b := False;
    x := 0;
    if ParseEPLF(Lines[n]) then
    begin
      b := True;
      x := 1;
    end
    else
      for m := 0 to Masks.Count - 1 do
      begin
        x := ParseByMask(Lines[n], s, Masks[m]);
        if x > 0 then
          if CheckValues then
          begin
            flr := TFTPListRec.create;
            FillRecord(flr);
            flr.OriginalLine := Lines[n];
            flr.Mask := Masks[m];
            if flr.Directory and ((flr.FileName = '.') or (flr.FileName = '..')) then
              flr.free
            else
              Flist.Add(flr);
            b := True;
            Break;
          end;
      end;
    if not b then
      FUnparsedLines.Add(Lines[n]);
    Inc(n);
    if x > 1 then
      Inc(n, x - 1);
  end;
end;

{==============================================================================}

function FtpGetFile(const IP, Port, FileName, LocalFile,
  User, Pass: string): Boolean;
begin
  Result := False;
  with TFTPSend.Create do
  try
    if User <> '' then
    begin
      Username := User;
      Password := Pass;
    end;
    TargetHost := IP;
    TargetPort := Port;
    if not Login then
      Exit;
    DirectFileName := LocalFile;
    DirectFile:=True;
    Result := RetrieveFile(FileName, False);
    Logout;
  finally
    Free;
  end;
end;

function FtpPutFile(const IP, Port, FileName, LocalFile,
  User, Pass: string): Boolean;
begin
  Result := False;
  with TFTPSend.Create do
  try
    if User <> '' then
    begin
      Username := User;
      Password := Pass;
    end;
    TargetHost := IP;
    TargetPort := Port;
    if not Login then
      Exit;
    DirectFileName := LocalFile;
    DirectFile:=True;
    Result := StoreFile(FileName, False);
    Logout;
  finally
    Free;
  end;
end;

function FtpInterServerTransfer(
  const FromIP, FromPort, FromFile, FromUser, FromPass: string;
  const ToIP, ToPort, ToFile, ToUser, ToPass: string): Boolean;
var
  FromFTP, ToFTP: TFTPSend;
  s: string;
  x: integer;
begin
  Result := False;
  FromFTP := TFTPSend.Create;
  toFTP := TFTPSend.Create;
  try
    if FromUser <> '' then
    begin
      FromFTP.Username := FromUser;
      FromFTP.Password := FromPass;
    end;
    if ToUser <> '' then
    begin
      ToFTP.Username := ToUser;
      ToFTP.Password := ToPass;
    end;
    FromFTP.TargetHost := FromIP;
    FromFTP.TargetPort := FromPort;
    ToFTP.TargetHost := ToIP;
    ToFTP.TargetPort := ToPort;
    if not FromFTP.Login then
      Exit;
    if not ToFTP.Login then
      Exit;
    if (FromFTP.FTPCommand('PASV') div 100) <> 2 then
      Exit;
    FromFTP.ParseRemote(FromFTP.ResultString);
    s := ReplaceString(FromFTP.DataIP, '.', ',');
    s := 'PORT ' + s + ',' + IntToStr(StrToIntDef(FromFTP.DataPort, 0) div 256)
      + ',' + IntToStr(StrToIntDef(FromFTP.DataPort, 0) mod 256);
    if (ToFTP.FTPCommand(s) div 100) <> 2 then
      Exit;
    x := ToFTP.FTPCommand('RETR ' + FromFile);
    if (x div 100) <> 1 then
      Exit;
    x := FromFTP.FTPCommand('STOR ' + ToFile);
    if (x div 100) <> 1 then
      Exit;
    FromFTP.Timeout := 21600000;
    x := FromFTP.ReadResult;
    if (x  div 100) <> 2 then
      Exit;
    ToFTP.Timeout := 21600000;
    x := ToFTP.ReadResult;
    if (x div 100) <> 2 then
      Exit;
    Result := True;
  finally
    ToFTP.Free;
    FromFTP.Free;
  end;
end;

end.
