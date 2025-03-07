{==============================================================================|
| Project : Ararat Synapse                                       | 003.009.002 |
|==============================================================================|
| Content: HTTP client                                                         |
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
|==============================================================================|
| History: see HISTORY.HTM from distribution package                           |
|          (Found at URL: http://www.ararat.cz/synapse/)                       |
|==============================================================================}

//RFC-1867, RFC-1947, RFC-2388, RFC-2616

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$H+}

unit httpsend;

interface

uses
  SysUtils, Classes,
  {$IFDEF STREAMSEC}
  TlsInternalServer, TlsSynaSock,
  {$ENDIF}
  blcksock, synautil, synacode;

const
  cHttpProtocol = '80';

type
  TTransferEncoding = (TE_UNKNOWN, TE_IDENTITY, TE_CHUNKED);

  THTTPSend = class(TSynaClient)
  protected
    {$IFDEF STREAMSEC}
    FSock: TSsTCPBlockSocket;
    FTLSServer: TCustomTLSInternalServer;
    {$ELSE}
    FSock: TTCPBlockSocket;
    {$ENDIF}
    FTransferEncoding: TTransferEncoding;
    FAliveHost: string;
    FAlivePort: string;
    FHeaders: TStringList;
    FDocument: TMemoryStream;
    FMimeType: string;
    FProtocol: string;
    FKeepAlive: Boolean;
    FStatus100: Boolean;
    FProxyHost: string;
    FProxyPort: string;
    FProxyUser: string;
    FProxyPass: string;
    FResultCode: Integer;
    FResultString: string;
    FUserAgent: string;
    FCookies: TStringList;
    FDownloadSize: integer;
    FUploadSize: integer;
    FRangeStart: integer;
    FRangeEnd: integer;
    FContentLength: Integer; //$$+ 2004/06/16 by neko
    FRetServer: string;      //$$+ 2004/08/11 by tzr
    FRetXShingetsu: string;  //$$+ 2004/08/11 by tzr
    FRetAgent: string;       //$$+ 2004/08/11 by tzr
    function ReadUnknown: Boolean;
    function ReadIdentity(Size: Integer): Boolean;
    function ReadChunked: Boolean;
    procedure ParseCookies;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure DecodeStatus(const Value: string);
    function HTTPMethod(const Method, URL: string): Boolean;
    procedure Abort;
    property ContentLength: Integer read FContentLength; //$$+ 2004/06/16 by neko
    property RetServer: string read FRetServer;          //$$+ 2004/08/11 by tzr
    property RetXShingetsu: string read FRetXShingetsu;  //$$+ 2004/08/11 by tzr
    property RetAgent: string read FRetAgent;            //$$+ 2004/08/11 by tzr

  published
    property Headers: TStringList read FHeaders;
    property Cookies: TStringList read FCookies;
    property Document: TMemoryStream read FDocument;
    property RangeStart: integer read FRangeStart Write FRangeStart;
    property RangeEnd: integer read FRangeEnd Write FRangeEnd;
    property MimeType: string read FMimeType Write FMimeType;
    property Protocol: string read FProtocol Write FProtocol;
    property KeepAlive: Boolean read FKeepAlive Write FKeepAlive;
    property Status100: Boolean read FStatus100 Write FStatus100;
    property ProxyHost: string read FProxyHost Write FProxyHost;
    property ProxyPort: string read FProxyPort Write FProxyPort;
    property ProxyUser: string read FProxyUser Write FProxyUser;
    property ProxyPass: string read FProxyPass Write FProxyPass;
    property UserAgent: string read FUserAgent Write FUserAgent;
    property ResultCode: Integer read FResultCode;
    property ResultString: string read FResultString;
    property DownloadSize: integer read FDownloadSize;
    property UploadSize: integer read FUploadSize;
{$IFDEF STREAMSEC}
    property Sock: TSsTCPBlockSocket read FSock;
    property TLSServer: TCustomTLSInternalServer read FTLSServer write FTLSServer;
{$ELSE}
    property Sock: TTCPBlockSocket read FSock;
{$ENDIF}
  end;

function HttpGetText(const URL: string; const Response: TStrings): Boolean;
function HttpGetBinary(const URL: string; const Response: TStream): Boolean;
function HttpPostBinary(const URL: string; const Data: TStream): Boolean;
function HttpPostURL(const URL, URLData: string; const Data: TStream): Boolean;
function HttpPostFile(const URL, FieldName, FileName: string;
  const Data: TStream; const ResultData: TStrings): Boolean;

implementation

constructor THTTPSend.Create;
begin
  inherited Create;
  FHeaders := TStringList.Create;
  FCookies := TStringList.Create;
  FDocument := TMemoryStream.Create;
{$IFDEF STREAMSEC}
  FTLSServer := GlobalTLSInternalServer;
  FSock := TSsTCPBlockSocket.Create;
  FSock.BlockingRead := True;
{$ELSE}
  FSock := TTCPBlockSocket.Create;
{$ENDIF}
  FSock.ConvertLineEnd := True;
  FSock.SizeRecvBuffer := c64k;
  FSock.SizeSendBuffer := c64k;
  FTimeout := 90000;
  FTargetPort := cHttpProtocol;
  FProxyHost := '';
  FProxyPort := '8080';
  FProxyUser := '';
  FProxyPass := '';
  FAliveHost := '';
  FAlivePort := '';
  FProtocol := '1.0';
  FKeepAlive := True;
  FStatus100 := False;
  FUserAgent := 'Mozilla/4.0 (compatible; Synapse)';
  FDownloadSize := 0;
  FUploadSize := 0;
  Clear;
end;

destructor THTTPSend.Destroy;
begin
  FSock.Free;
  FDocument.Free;
  FCookies.Free;
  FHeaders.Free;
  inherited Destroy;
end;

procedure THTTPSend.Clear;
begin
  FRangeStart := 0;
  FRangeEnd := 0;
  FDocument.Clear;
  FHeaders.Clear;
  FContentLength := 0;   //$$+ 2004/06/16 by neko
  FRetServer := '';      //$$+ 2004/08/11 by tzr
  FRetXShingetsu := '';  //$$+ 2004/08/11 by tzr
  FRetAgent := '';       //$$+ 2004/08/11 by tzr
  FMimeType  := 'text/html';
end;

procedure THTTPSend.DecodeStatus(const Value: string);
var
  s, su: string;
begin
  s := Trim(SeparateRight(Value, ' '));
  su := Trim(SeparateLeft(s, ' '));
  FResultCode := StrToIntDef(su, 0);
  FResultString := Trim(SeparateRight(s, ' '));
  if FResultString = s then
    FResultString := '';
end;

function THTTPSend.HTTPMethod(const Method, URL: string): Boolean;
var
  Sending, Receiving: Boolean;
  status100: Boolean;
  status100error: string;
  ToClose: Boolean;
  Size: Integer;
  Prot, User, Pass, Host, Port, Path, Para, URI: string;
  s, su: string;
  HttpTunnel: Boolean;
  n: integer;
  Buf: array[0..32767] of Byte; //$$+ 2004/06/16 by neko
  bsize: Integer;               //$$+ 2004/06/16 by neko

begin
  {initial values}
  Result := False;
  FResultCode := 500;
  FResultString := '';
  FDownloadSize := 0;
  FUploadSize := 0;

  URI := ParseURL(URL, Prot, User, Pass, Host, Port, Path, Para);
  if User = '' then
  begin
    User := FUsername;
    Pass := FPassword;
  end;
  if UpperCase(Prot) = 'HTTPS' then
  begin
    HttpTunnel := FProxyHost <> '';
    FSock.HTTPTunnelIP := FProxyHost;
    FSock.HTTPTunnelPort := FProxyPort;
    FSock.HTTPTunnelUser := FProxyUser;
    FSock.HTTPTunnelPass := FProxyPass;
  end
  else
  begin
    HttpTunnel := False;
    FSock.HTTPTunnelIP := '';
    FSock.HTTPTunnelPort := '';
    FSock.HTTPTunnelUser := '';
    FSock.HTTPTunnelPass := '';
  end;

  Sending := Document.Size > 0;
  {Headers for Sending data}
  status100 := FStatus100 and Sending and (FProtocol = '1.1');
  if status100 then
    FHeaders.Insert(0, 'Expect: 100-continue');
  FHeaders.Insert(0, 'Content-Length: ' + IntToStr(FDocument.Size));
  if Sending then
  begin
//    FHeaders.Insert(0, 'Content-Length: ' + IntToStr(FDocument.Size));
    if FMimeType <> '' then
      FHeaders.Insert(0, 'Content-Type: ' + FMimeType);
  end;
  { setting User-agent }
  if FUserAgent <> '' then
    FHeaders.Insert(0, 'User-Agent: ' + FUserAgent);
  { setting Ranges }
  if FRangeEnd > 0 then
    FHeaders.Insert(0, 'Range: bytes=' + IntToStr(FRangeStart) + '-' + IntToStr(FRangeEnd));
  { setting Cookies }
  s := '';
  for n := 0 to FCookies.Count - 1 do
  begin
    if s <> '' then
      s := s + '; ';
    s := s + FCookies[n];
  end;
  if s <> '' then
    FHeaders.Insert(0, 'Cookie: ' + s);
  { setting KeepAlives }
  if not FKeepAlive then
    FHeaders.Insert(0, 'Connection: close');
  { set target servers/proxy, authorizations, etc... }
  if User <> '' then
    FHeaders.Insert(0, 'Authorization: Basic ' + EncodeBase64(User + ':' + Pass));
  if (FProxyHost <> '') and (FProxyUser <> '') and not(HttpTunnel) then
    FHeaders.Insert(0, 'Proxy-Authorization: Basic ' +
      EncodeBase64(FProxyUser + ':' + FProxyPass));
//if isIP6(Host) then           // //$$+ 2004/07/16 by neko
//  s := '[' + Host + ']'       //
//else                          //
    s := Host;
  if Port<>'80' then
     FHeaders.Insert(0, 'Host: ' + s + ':' + Port)
  else
     FHeaders.Insert(0, 'Host: ' + s);
  if (FProxyHost <> '') and not(HttpTunnel)then
    URI := Prot + '://' + s + ':' + Port + URI;
  if URI = '/*' then
    URI := '*';
  if FProtocol = '0.9' then
    FHeaders.Insert(0, UpperCase(Method) + ' ' + URI)
  else
    FHeaders.Insert(0, UpperCase(Method) + ' ' + URI + ' HTTP/' + FProtocol);
  if (FProxyHost <> '') and not(HttpTunnel) then
  begin
    FTargetHost := FProxyHost;
    FTargetPort := FProxyPort;
  end
  else
  begin
    FTargetHost := Host;
    FTargetPort := Port;
  end;
  if FHeaders[FHeaders.Count - 1] <> '' then
    FHeaders.Add('');

  { connect }
  if (FAliveHost <> FTargetHost) or (FAlivePort <> FTargetPort) then
  begin
    FSock.CloseSocket;
    FSock.Bind(FIPInterface, cAnyPort);
    if FSock.LastError <> 0 then
      Exit;
{$IFDEF STREAMSEC}
    FSock.TLSServer := nil;
    if UpperCase(Prot) = 'HTTPS' then
      if assigned(FTLSServer) then
        FSock.TLSServer := FTLSServer
      else
        exit;
{$ELSE}
    FSock.SSLEnabled := UpperCase(Prot) = 'HTTPS';
{$ENDIF}
    if FSock.LastError <> 0 then
      Exit;
    FSock.Connect(FTargetHost, FTargetPort);
    if FSock.LastError <> 0 then
      Exit;
    FAliveHost := FTargetHost;
    FAlivePort := FTargetPort;
  end
  else
  begin
    if FSock.CanRead(0) then
    begin
      FSock.CloseSocket;
      FSock.Bind(FIPInterface, cAnyPort);
      if FSock.LastError <> 0 then
        Exit;
{$IFDEF STREAMSEC}
      FSock.TLSServer := nil;
      if UpperCase(Prot) = 'HTTPS' then
        if assigned(FTLSServer) then
          FSock.TLSServer := FTLSServer
        else
          exit;
{$ELSE}
      FSock.SSLEnabled := UpperCase(Prot) = 'HTTPS';
{$ENDIF}
      if FSock.LastError <> 0 then
        Exit;
      FSock.Connect(FTargetHost, FTargetPort);
      if FSock.LastError <> 0 then
        Exit;
    end;
  end;

  { send Headers }
  if FProtocol = '0.9' then
    FSock.SendString(FHeaders[0] + CRLF)
  else
{$IFDEF LINUX}
    FSock.SendString(AdjustLineBreaks(FHeaders.Text, tlbsCRLF));
{$ELSE}
    FSock.SendString(FHeaders.Text);
{$ENDIF}
  if FSock.LastError <> 0 then
    Exit;

  { reading Status }
  Status100Error := '';
  if status100 then
  begin
    repeat
      s := FSock.RecvString(FTimeout);
      if s <> '' then
        Break;
    until FSock.LastError <> 0;
    DecodeStatus(s);
    if (FResultCode >= 100) and (FResultCode < 200) then
      repeat
        s := FSock.recvstring(FTimeout);
        if s = '' then
          Break;
      until FSock.LastError <> 0
    else
    begin
      Sending := False;
      Status100Error := s;
    end;
  end;

  { send document }
  if Sending then
  begin
    FUploadSize := FDocument.Size;
{   //$$- 2004/06/16 by neko
    FSock.SendBuffer(FDocument.Memory, FDocument.Size);
    if FSock.LastError <> 0 then
      Exit;
}
    //$$+ ‚±‚±‚Ü‚Å 2004/06/16 by neko
    FDocument.Seek(0, soFromBeginning);
    repeat
      bsize := FDocument.Read(Buf, SizeOf(Buf));
      if FSock.LastError <> 0 then
        Exit;
      FSock.SendBuffer(@Buf[0], bsize);
    until (bsize < SizeOf(Buf));
    //$$+ ‚±‚±‚Ü‚Å 2004/06/16 by neko
  end;

  Clear;
  Size := -1;
  FTransferEncoding := TE_UNKNOWN;

  { read status }
  if Status100Error = '' then
  begin
    repeat
      s := FSock.RecvString(FTimeout);
      if s <> '' then
        Break;
    until FSock.LastError <> 0;
    if Pos('HTTP/', UpperCase(s)) = 1 then
    begin
      FHeaders.Add(s);
      DecodeStatus(s);
    end
    else
    begin
      { old HTTP 0.9 and some buggy servers not send result }
      s := s + CRLF;
      WriteStrToStream(FDocument, s);
//      FDocument.Write(Pointer(s)^, Length(s));
      FResultCode := 0;
    end;
  end
  else
    FHeaders.Add(Status100Error);

  { if need receive headers, receive and parse it }
  ToClose := FProtocol <> '1.1';
  if FHeaders.Count > 0 then
    repeat
      s := FSock.RecvString(FTimeout);
      FHeaders.Add(s);
      if s = '' then
        Break;
      su := UpperCase(s);
      if Pos('CONTENT-LENGTH:', su) = 1 then
      begin
        Size := StrToIntDef(Trim(SeparateRight(s, ' ')), -1);
        FContentLength := Size; //$$+ 2004/06/16 by neko
        if Size <> -1 then
          FTransferEncoding := TE_IDENTITY;
      end;
      if Pos('CONTENT-TYPE:', su) = 1 then
        FMimeType := Trim(SeparateRight(s, ' '));
      if Pos('TRANSFER-ENCODING:', su) = 1 then
      begin
        s := Trim(SeparateRight(su, ' '));
        if Pos('CHUNKED', s) > 0 then
          FTransferEncoding := TE_CHUNKED;
      end;
      if Pos('CONNECTION: CLOSE', su) = 1 then
        ToClose := True;

      if POS('SERVER:', su) = 1 then begin              //$$+
        FRetServer := Trim(SeparateRight(s, ' '));      //$$+ 2004/08/11 by tzr
      end;                                              //$$+
      if POS('X-SHINGETSU:', su) = 1 then begin         //$$+
        FRetXShingetsu := Trim(SeparateRight(s, ' '));  //$$+ 2004/08/11 by tzr
      end;                                              //$$+
      if POS('USER-AGENT:', su) = 1 then begin          //$$+
        FRetAgent := Trim(SeparateRight(s, ' '));       //$$+ 2004/08/11 by tzr
      end;                                              //$$+

    until FSock.LastError <> 0;
  Result := FSock.LastError = 0;

  {if need receive response body, read it}
  Receiving := Method <> 'HEAD';
  Receiving := Receiving and (FResultCode <> 204);
  Receiving := Receiving and (FResultCode <> 304);
  if Receiving then
    case FTransferEncoding of
      TE_UNKNOWN:
        Result := ReadUnknown;
      TE_IDENTITY:
        Result := ReadIdentity(Size);
      TE_CHUNKED:
        Result := ReadChunked;
    end;

  FDocument.Seek(0, soFromBeginning);
  if ToClose then
  begin
    FSock.CloseSocket;
    FAliveHost := '';
    FAlivePort := '';
  end;
  ParseCookies;
end;

function THTTPSend.ReadUnknown: Boolean;
var
  s: string;
begin
  repeat
    s := FSock.RecvPacket(FTimeout);
    if FSock.LastError = 0 then
      WriteStrToStream(FDocument, s);
  until FSock.LastError <> 0;
  Result := True;
end;

function THTTPSend.ReadIdentity(Size: Integer): Boolean;
begin
  if Size > 0 then
  begin
    FDownloadSize := Size;
    FSock.RecvStreamSize(FDocument, FTimeout, Size);
    FDocument.Seek(0, soFromEnd);
    Result := FSock.LastError = 0;
  end
  else
    Result := true;
end;

function THTTPSend.ReadChunked: Boolean;
var
  s: string;
  Size: Integer;
begin
  repeat
    repeat
      s := FSock.RecvString(FTimeout);
    until (s <> '') or (FSock.LastError <> 0);
    if FSock.LastError <> 0 then
      Break;
    s := Trim(SeparateLeft(s, ' '));
    Size := StrToIntDef('$' + s, 0);
    if Size = 0 then
      Break;
    if not ReadIdentity(Size) then
      break;
  until False;
  Result := FSock.LastError = 0;
end;

procedure THTTPSend.ParseCookies;
var
  n: integer;
  s: string;
  sn, sv: string;
begin
  for n := 0 to FHeaders.Count - 1 do
    if Pos('set-cookie:', lowercase(FHeaders[n])) = 1 then
    begin
      s := SeparateRight(FHeaders[n], ':');
      s := trim(SeparateLeft(s, ';'));
      sn := trim(SeparateLeft(s, '='));
      sv := trim(SeparateRight(s, '='));
      FCookies.Values[sn] := sv;
    end;
end;

procedure THTTPSend.Abort;
begin
  FSock.StopFlag := True;
end;

{==============================================================================}

function HttpGetText(const URL: string; const Response: TStrings): Boolean;
var
  HTTP: THTTPSend;
begin
  HTTP := THTTPSend.Create;
  try
    Result := HTTP.HTTPMethod('GET', URL);
    Response.LoadFromStream(HTTP.Document);
  finally
    HTTP.Free;
  end;
end;

function HttpGetBinary(const URL: string; const Response: TStream): Boolean;
var
  HTTP: THTTPSend;
begin
  HTTP := THTTPSend.Create;
  try
    Result := HTTP.HTTPMethod('GET', URL);
    Response.Seek(0, soFromBeginning);
    Response.CopyFrom(HTTP.Document, 0);
  finally
    HTTP.Free;
  end;
end;

function HttpPostBinary(const URL: string; const Data: TStream): Boolean;
var
  HTTP: THTTPSend;
begin
  HTTP := THTTPSend.Create;
  try
    HTTP.Document.CopyFrom(Data, 0);
    HTTP.MimeType := 'Application/octet-stream';
    Result := HTTP.HTTPMethod('POST', URL);
    Data.Seek(0, soFromBeginning);
    Data.CopyFrom(HTTP.Document, 0);
  finally
    HTTP.Free;
  end;
end;

function HttpPostURL(const URL, URLData: string; const Data: TStream): Boolean;
var
  HTTP: THTTPSend;
begin
  HTTP := THTTPSend.Create;
  try
    WriteStrToStream(HTTP.Document, URLData);
//    HTTP.Document.Write(Pointer(URLData)^, Length(URLData));
    HTTP.MimeType := 'application/x-www-form-urlencoded';
    Result := HTTP.HTTPMethod('POST', URL);
    Data.CopyFrom(HTTP.Document, 0);
  finally
    HTTP.Free;
  end;
end;

function HttpPostFile(const URL, FieldName, FileName: string;
  const Data: TStream; const ResultData: TStrings): Boolean;
var
  HTTP: THTTPSend;
  Bound, s: string;
begin
  Bound := IntToHex(Random(MaxInt), 8) + '_Synapse_boundary';
  HTTP := THTTPSend.Create;
  try
    s := '--' + Bound + CRLF;
    s := s + 'content-disposition: form-data; name="' + FieldName + '";';
    s := s + ' filename="' + FileName +'"' + CRLF;
    s := s + 'Content-Type: Application/octet-string' + CRLF + CRLF;
    WriteStrToStream(HTTP.Document, s);
//    HTTP.Document.Write(Pointer(s)^, Length(s));
    HTTP.Document.CopyFrom(Data, 0);
    s := CRLF + '--' + Bound + '--' + CRLF;
    WriteStrToStream(HTTP.Document, s);
//    HTTP.Document.Write(Pointer(s)^, Length(s));
    HTTP.MimeType := 'multipart/form-data; boundary=' + Bound;
    Result := HTTP.HTTPMethod('POST', URL);
    ResultData.LoadFromStream(HTTP.Document);
  finally
    HTTP.Free;
  end;
end;

end.
