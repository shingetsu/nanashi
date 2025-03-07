{==============================================================================|
| Project : Ararat Synapse                                       | 002.004.001 |
|==============================================================================|
| Content: MIME message object                                                 |
|==============================================================================|
| Copyright (c)1999-2003, Lukas Gebauer                                        |
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
| Portions created by Lukas Gebauer are Copyright (c)2000-2003.                |
| All Rights Reserved.                                                         |
|==============================================================================|
| Contributor(s):                                                              |
|==============================================================================|
| History: see HISTORY.HTM From distribution package                           |
|          (Found at URL: http://www.ararat.cz/synapse/)                       |
|==============================================================================}

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$H+}

unit mimemess;

interface

uses
  Classes, SysUtils,
  mimepart, synachar, synautil, mimeinln;

type

  TMessPriority = (MP_unknown, MP_low, MP_normal, MP_high);

  TMessHeader = class(TObject)
  private
    FFrom: string;
    FToList: TStringList;
    FCCList: TStringList;
    FSubject: string;
    FOrganization: string;
    FCustomHeaders: TStringList;
    FDate: TDateTime;
    FXMailer: string;
    FCharsetCode: TMimeChar;
    FReplyTo: string;
    FMessageID: string;
    FPriority: TMessPriority;
    Fpri: TMessPriority;
    Fxpri: TMessPriority;
    Fxmspri: TMessPriority;
  protected
    function ParsePriority(value: string): TMessPriority;
    function DecodeHeader(value: string): boolean; virtual;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Clear;
    procedure EncodeHeaders(const Value: TStrings); virtual;
    procedure DecodeHeaders(const Value: TStrings);
    function FindHeader(Value: string): string;
    procedure FindHeaderList(Value: string; const HeaderList: TStrings);
  published
    property From: string read FFrom Write FFrom;
    property ToList: TStringList read FToList;
    property CCList: TStringList read FCCList;
    property Subject: string read FSubject Write FSubject;
    property Organization: string read FOrganization Write FOrganization;
    property CustomHeaders: TStringList read FCustomHeaders;
    property Date: TDateTime read FDate Write FDate;
    property XMailer: string read FXMailer Write FXMailer;
    property ReplyTo: string read FReplyTo Write FReplyTo;
    property MessageID: string read FMessageID Write FMessageID;
    property Priority: TMessPriority read FPriority Write FPriority;
    property CharsetCode: TMimeChar read FCharsetCode Write FCharsetCode;
  end;

  TMessHeaderClass = class of TMessHeader;

  TMimeMess = class(TObject)
  private
    FMessagePart: TMimePart;
    FLines: TStringList;
    FHeader: TMessHeader;
  public
    constructor Create;
    constructor CreateAltHeaders(HeadClass: TMessHeaderClass);
    destructor Destroy; override;
    procedure Clear;
    function AddPart(const PartParent: TMimePart): TMimePart;
    function AddPartMultipart(const MultipartType: String; const PartParent: TMimePart): TMimePart;
    function AddPartText(const Value: TStrings; const PartParent: TMimePart): TMimepart;
    function AddPartHTML(const Value: TStrings; const PartParent: TMimePart): TMimepart;
    function AddPartTextFromFile(const FileName: String; const PartParent: TMimePart): TMimepart;
    function AddPartHTMLFromFile(const FileName: String; const PartParent: TMimePart): TMimepart;
    function AddPartBinary(const Stream: TStream; const FileName: string; const PartParent: TMimePart): TMimepart;
    function AddPartBinaryFromFile(const FileName: string; const PartParent: TMimePart): TMimepart;
    function AddPartHTMLBinary(const Stream: TStream; const FileName, Cid: string; const PartParent: TMimePart): TMimepart;
    function AddPartHTMLBinaryFromFile(const FileName, Cid: string; const PartParent: TMimePart): TMimepart;
    function AddPartMess(const Value: TStrings; const PartParent: TMimePart): TMimepart;
    function AddPartMessFromFile(const FileName: string; const PartParent: TMimePart): TMimepart;
    procedure EncodeMessage;
    procedure DecodeMessage;
  published
    property MessagePart: TMimePart read FMessagePart;
    property Lines: TStringList read FLines;
    property Header: TMessHeader read FHeader;
  end;

implementation

{==============================================================================}

constructor TMessHeader.Create;
begin
  inherited Create;
  FToList := TStringList.Create;
  FCCList := TStringList.Create;
  FCustomHeaders := TStringList.Create;
  FCharsetCode := GetCurCP;
end;

destructor TMessHeader.Destroy;
begin
  FCustomHeaders.Free;
  FCCList.Free;
  FToList.Free;
  inherited Destroy;
end;

{==============================================================================}

procedure TMessHeader.Clear;
begin
  FFrom := '';
  FToList.Clear;
  FCCList.Clear;
  FSubject := '';
  FOrganization := '';
  FCustomHeaders.Clear;
  FDate := 0;
  FXMailer := '';
  FReplyTo := '';
  FMessageID := '';
  FPriority := MP_unknown;
end;

procedure TMessHeader.EncodeHeaders(const Value: TStrings);
var
  n: Integer;
  s: string;
begin
  if FDate = 0 then
    FDate := Now;
  for n := FCustomHeaders.Count - 1 downto 0 do
    if FCustomHeaders[n] <> '' then
      Value.Insert(0, FCustomHeaders[n]);
  if FPriority <> MP_unknown then
    case FPriority of
      MP_high:
        begin
          Value.Insert(0, 'X-MSMAIL-Priority: High');
          Value.Insert(0, 'X-Priority: 1');
          Value.Insert(0, 'Priority: urgent');
        end;
      MP_low:
        begin
          Value.Insert(0, 'X-MSMAIL-Priority: low');
          Value.Insert(0, 'X-Priority: 5');
          Value.Insert(0, 'Priority: non-urgent');
        end;
    end;
  if FReplyTo <> '' then
    Value.Insert(0, 'Reply-To: ' + GetEmailAddr(FReplyTo));
  if FMessageID <> '' then
    Value.Insert(0, 'Message-ID: <' + trim(FMessageID) + '>');
  if FXMailer = '' then
    Value.Insert(0, 'X-mailer: Synapse - Pascal TCP/IP library by Lukas Gebauer')
  else
    Value.Insert(0, 'X-mailer: ' + FXMailer);
  Value.Insert(0, 'MIME-Version: 1.0 (produced by Synapse)');
  if FOrganization <> '' then
    Value.Insert(0, 'Organization: ' + InlineCodeEx(FOrganization, FCharsetCode));
  s := '';
  for n := 0 to FCCList.Count - 1 do
    if s = '' then
      s := InlineEmailEx(FCCList[n], FCharsetCode)
    else
      s := s + ' , ' + InlineEmailEx(FCCList[n], FCharsetCode);
  if s <> '' then
    Value.Insert(0, 'CC: ' + s);
  Value.Insert(0, 'Date: ' + Rfc822DateTime(FDate));
  if FSubject <> '' then
    Value.Insert(0, 'Subject: ' + InlineCodeEx(FSubject, FCharsetCode));
  s := '';
  for n := 0 to FToList.Count - 1 do
    if s = '' then
      s := InlineEmailEx(FToList[n], FCharsetCode)
    else
      s := s + ' , ' + InlineEmailEx(FToList[n], FCharsetCode);
  if s <> '' then
    Value.Insert(0, 'To: ' + s);
  Value.Insert(0, 'From: ' + InlineEmailEx(FFrom, FCharsetCode));
end;

function TMessHeader.ParsePriority(value: string): TMessPriority;
var
  s: string;
  x: integer;
begin
  Result := MP_unknown;
  s := Trim(separateright(value, ':'));
  s := Separateleft(s, ' ');
  x := StrToIntDef(s, -1);
  if x >= 0 then
    case x of
      1, 2:
        Result := MP_High;
      3:
        Result := MP_Normal;
      4, 5:
        Result := MP_Low;
    end
  else
  begin
    s := lowercase(s);
    if (s = 'urgent') or (s = 'high') or (s = 'highest') then
      Result := MP_High;
    if (s = 'normal') or (s = 'medium') then
      Result := MP_Normal;
    if (s = 'low') or (s = 'lowest')
      or (s = 'no-priority')  or (s = 'non-urgent') then
      Result := MP_Low;
  end;
end;

function TMessHeader.DecodeHeader(value: string): boolean;
var
  s, t: string;
  cp: TMimeChar;
begin
  Result := True;
  cp := FCharsetCode;
  s := uppercase(value);
  if Pos('X-MAILER:', s) = 1 then
  begin
    FXMailer := Trim(SeparateRight(Value, ':'));
    Exit;
  end;
  if Pos('FROM:', s) = 1 then
  begin
    FFrom := InlineDecode(Trim(SeparateRight(Value, ':')), cp);
    Exit;
  end;
  if Pos('SUBJECT:', s) = 1 then
  begin
    FSubject := InlineDecode(Trim(SeparateRight(Value, ':')), cp);
    Exit;
  end;
  if Pos('ORGANIZATION:', s) = 1 then
  begin
    FOrganization := InlineDecode(Trim(SeparateRight(Value, ':')), cp);
    Exit;
  end;
  if Pos('TO:', s) = 1 then
  begin
    s := Trim(SeparateRight(Value, ':'));
    repeat
      t := InlineDecode(Trim(FetchEx(s, ',', '"')), cp);
      if t <> '' then
        FToList.Add(t);
    until s = '';
    Exit;
  end;
  if Pos('CC:', s) = 1 then
  begin
    s := Trim(SeparateRight(Value, ':'));
    repeat
      t := InlineDecode(Trim(FetchEx(s, ',', '"')), cp);
      if t <> '' then
        FCCList.Add(t);
    until s = '';
    Exit;
  end;
  if Pos('DATE:', s) = 1 then
  begin
    FDate := DecodeRfcDateTime(Trim(SeparateRight(Value, ':')));
    Exit;
  end;
  if Pos('REPLY-TO:', s) = 1 then
  begin
    FReplyTo := InlineDecode(Trim(SeparateRight(Value, ':')), cp);
    Exit;
  end;
  if Pos('MESSAGE-ID:', s) = 1 then
  begin
    FMessageID := GetEmailAddr(Trim(SeparateRight(Value, ':')));
    Exit;
  end;
  if Pos('PRIORITY:', s) = 1 then
  begin
    FPri := ParsePriority(value);
    Exit;
  end;
  if Pos('X-PRIORITY:', s) = 1 then
  begin
    FXPri := ParsePriority(value);
    Exit;
  end;
  if Pos('X-MSMAIL-PRIORITY:', s) = 1 then
  begin
    FXmsPri := ParsePriority(value);
    Exit;
  end;
  if Pos('MIME-VERSION:', s) = 1 then
    Exit;
  if Pos('CONTENT-TYPE:', s) = 1 then
    Exit;
  if Pos('CONTENT-DESCRIPTION:', s) = 1 then
    Exit;
  if Pos('CONTENT-DISPOSITION:', s) = 1 then
    Exit;
  if Pos('CONTENT-ID:', s) = 1 then
    Exit;
  if Pos('CONTENT-TRANSFER-ENCODING:', s) = 1 then
    Exit;
  Result := False;
end;

procedure TMessHeader.DecodeHeaders(const Value: TStrings);
var
  s: string;
  x: Integer;
begin
  Clear;
  Fpri := MP_unknown;
  Fxpri := MP_unknown;
  Fxmspri := MP_unknown;
  x := 0;
  while Value.Count > x do
  begin
    s := NormalizeHeader(Value, x);
    if s = '' then
      Break;
    if not DecodeHeader(s) then
      FCustomHeaders.Add(s);
  end;
  if Fpri <> MP_unknown then
    FPriority := Fpri
  else
    if Fxpri <> MP_unknown then
      FPriority := Fxpri
    else
      if Fxmspri <> MP_unknown then
        FPriority := Fxmspri
end;

function TMessHeader.FindHeader(Value: string): string;
var
  n: integer;
begin
  Result := '';
  for n := 0 to FCustomHeaders.Count - 1 do
    if Pos(UpperCase(Value), UpperCase(FCustomHeaders[n])) = 1 then
    begin
      Result := Trim(SeparateRight(FCustomHeaders[n], ':'));
      break;
    end;
end;

procedure TMessHeader.FindHeaderList(Value: string; const HeaderList: TStrings);
var
  n: integer;
begin
  HeaderList.Clear;
  for n := 0 to FCustomHeaders.Count - 1 do
    if Pos(UpperCase(Value), UpperCase(FCustomHeaders[n])) = 1 then
    begin
      HeaderList.Add(Trim(SeparateRight(FCustomHeaders[n], ':')));
    end;
end;

{==============================================================================}

constructor TMimeMess.Create;
begin
  CreateAltHeaders(TMessHeader);
end;

constructor TMimeMess.CreateAltHeaders(HeadClass: TMessHeaderClass);
begin
  inherited Create;
  FMessagePart := TMimePart.Create;
  FLines := TStringList.Create;
  FHeader := HeadClass.Create;
end;

destructor TMimeMess.Destroy;
begin
  FMessagePart.Free;
  FHeader.Free;
  FLines.Free;
  inherited Destroy;
end;

{==============================================================================}

procedure TMimeMess.Clear;
begin
  FMessagePart.Clear;
  FLines.Clear;
  FHeader.Clear;
end;

{==============================================================================}

function TMimeMess.AddPart(const PartParent: TMimePart): TMimePart;
begin
  if PartParent = nil then
    Result := FMessagePart
  else
    Result := PartParent.AddSubPart;
  Result.Clear;
end;

{==============================================================================}

function TMimeMess.AddPartMultipart(const MultipartType: String; const PartParent: TMimePart): TMimePart;
begin
  Result := AddPart(PartParent);
  with Result do
  begin
    Primary := 'Multipart';
    Secondary := MultipartType;
    Description := 'Multipart message';
    Boundary := GenerateBoundary;
    EncodePartHeader;
  end;
end;

function TMimeMess.AddPartText(const Value: TStrings; const PartParent: TMimePart): TMimepart;
begin
  Result := AddPart(PartParent);
  with Result do
  begin
    Value.SaveToStream(DecodedLines);
    Primary := 'text';
    Secondary := 'plain';
    Description := 'Message text';
    Disposition := 'inline';
    CharsetCode := IdealCharsetCoding(Value.Text, TargetCharset,
      [ISO_8859_1, ISO_8859_2, ISO_8859_3, ISO_8859_4, ISO_8859_5,
      ISO_8859_6, ISO_8859_7, ISO_8859_8, ISO_8859_9, ISO_8859_10]);
    EncodingCode := ME_QUOTED_PRINTABLE;
    EncodePart;
    EncodePartHeader;
  end;
end;

function TMimeMess.AddPartHTML(const Value: TStrings; const PartParent: TMimePart): TMimepart;
begin
  Result := AddPart(PartParent);
  with Result do
  begin
    Value.SaveToStream(DecodedLines);
    Primary := 'text';
    Secondary := 'html';
    Description := 'HTML text';
    Disposition := 'inline';
    CharsetCode := UTF_8;
    EncodingCode := ME_QUOTED_PRINTABLE;
    EncodePart;
    EncodePartHeader;
  end;
end;

function TMimeMess.AddPartTextFromFile(const FileName: String; const PartParent: TMimePart): TMimepart;
var
  tmp: TStrings;
begin
  tmp := TStringList.Create;
  try
    tmp.LoadFromFile(FileName);
    Result := AddPartText(tmp, PartParent);
  Finally
    tmp.Free;
  end;
end;

function TMimeMess.AddPartHTMLFromFile(const FileName: String; const PartParent: TMimePart): TMimepart;
var
  tmp: TStrings;
begin
  tmp := TStringList.Create;
  try
    tmp.LoadFromFile(FileName);
    Result := AddPartHTML(tmp, PartParent);
  Finally
    tmp.Free;
  end;
end;

function TMimeMess.AddPartBinary(const Stream: TStream; const FileName: string; const PartParent: TMimePart): TMimepart;
begin
  Result := AddPart(PartParent);
  Result.DecodedLines.LoadFromStream(Stream);
  Result.MimeTypeFromExt(FileName);
  Result.Description := 'Attached file: ' + FileName;
  Result.Disposition := 'attachment';
  Result.FileName := FileName;
  Result.EncodingCode := ME_BASE64;
  Result.EncodePart;
  Result.EncodePartHeader;
end;

function TMimeMess.AddPartBinaryFromFile(const FileName: string; const PartParent: TMimePart): TMimepart;
var
  tmp: TMemoryStream;
begin
  tmp := TMemoryStream.Create;
  try
    tmp.LoadFromFile(FileName);
    Result := AddPartBinary(tmp, ExtractFileName(FileName), PartParent);
  finally
    tmp.Free;
  end;
end;

function TMimeMess.AddPartHTMLBinary(const Stream: TStream; const FileName, Cid: string; const PartParent: TMimePart): TMimepart;
begin
  Result := AddPart(PartParent);
  Result.DecodedLines.LoadFromStream(Stream);
  Result.MimeTypeFromExt(FileName);
  Result.Description := 'Included file: ' + FileName;
  Result.Disposition := 'inline';
  Result.ContentID := Cid;
  Result.FileName := FileName;
  Result.EncodingCode := ME_BASE64;
  Result.EncodePart;
  Result.EncodePartHeader;
end;

function TMimeMess.AddPartHTMLBinaryFromFile(const FileName, Cid: string; const PartParent: TMimePart): TMimepart;
var
  tmp: TMemoryStream;
begin
  tmp := TMemoryStream.Create;
  try
    tmp.LoadFromFile(FileName);
    Result :=AddPartHTMLBinary(tmp, ExtractFileName(FileName), Cid, PartParent);
  finally
    tmp.Free;
  end;
end;

function TMimeMess.AddPartMess(const Value: TStrings; const PartParent: TMimePart): TMimepart;
var
  part: Tmimepart;
begin
  Result := AddPart(PartParent);
  part := AddPart(result);
  part.lines.addstrings(Value);
  part.DecomposeParts;
  with Result do
  begin
    Primary := 'message';
    Secondary := 'rfc822';
    Description := 'E-mail Message';
    EncodePart;
    EncodePartHeader;
  end;
end;

function TMimeMess.AddPartMessFromFile(const FileName: String; const PartParent: TMimePart): TMimepart;
var
  tmp: TStrings;
begin
  tmp := TStringList.Create;
  try
    tmp.LoadFromFile(FileName);
    Result := AddPartMess(tmp, PartParent);
  Finally
    tmp.Free;
  end;
end;

{==============================================================================}

procedure TMimeMess.EncodeMessage;
var
  l: TStringList;
  x: integer;
begin
  //merge headers from THeaders and header field from MessagePart
  l := TStringList.Create;
  try
    FHeader.EncodeHeaders(l);
    x := IndexByBegin('CONTENT-TYPE', FMessagePart.Headers);
    if x >= 0 then
      l.add(FMessagePart.Headers[x]);
    x := IndexByBegin('CONTENT-DESCRIPTION', FMessagePart.Headers);
    if x >= 0 then
      l.add(FMessagePart.Headers[x]);
    x := IndexByBegin('CONTENT-DISPOSITION', FMessagePart.Headers);
    if x >= 0 then
      l.add(FMessagePart.Headers[x]);
    x := IndexByBegin('CONTENT-ID', FMessagePart.Headers);
    if x >= 0 then
      l.add(FMessagePart.Headers[x]);
    x := IndexByBegin('CONTENT-TRANSFER-ENCODING', FMessagePart.Headers);
    if x >= 0 then
      l.add(FMessagePart.Headers[x]);
    FMessagePart.Headers.Assign(l);
  finally
    l.Free;
  end;
  FMessagePart.ComposeParts;
  FLines.Assign(FMessagePart.Lines);
end;

{==============================================================================}

procedure TMimeMess.DecodeMessage;
begin
  FHeader.Clear;
  FHeader.DecodeHeaders(FLines);
  FMessagePart.Lines.Assign(FLines);
  FMessagePart.DecomposeParts;
end;

end.
