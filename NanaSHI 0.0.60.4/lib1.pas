//==============================================================================
// The basic library which anyone can use. for Windows.
//
// (C) TZR 1.0.0 2004/06/11
//
// This opens to the public as an open source.
// Please use it on your responsibility.
// This was created with many friends. Please do not forget.
// Thank you.
//
//==============================================================================

unit lib1;                                   

interface

uses
  Classes, Windows, SysUtils, Dialogs, newtype, timet;


procedure DecodeLanguage(input:string;ret:TStringList);
function StrToFloatDef(s:string;v:extended):extended;
function ccc(instr:string):string;
function Bin2ByteStr(c:uchar):string;
function ByteStr2Bin(c:string):uchar;
function grep(exp:string;data:TStringList):boolean; overload;
function grep(exp:string;data,ret:TStringList):boolean; overload;
function localtime(tm:TFileTime):TTime_t; overload;
function localtime():TTime_t; overload;

function before_month( yyyymm : longint ) : longint;
function next_month( yyyymm : longint ) : longint;
function month_days( yyyymm : longint ) : longint;
function def_day( yyyymmdd_a, yyyymmdd_b : longint ) : longint;

function glob(file_patarn:string;ret:TStringList):TStringList;
function split(input:string;sstr:string;ret:TStringList):TStringList; overload;
function split(input:string;sstr:string;limit:integer; ret:TStringList):TStringList; overload
function defined(v:string):boolean; overload;
function defined(v:integer):boolean; overload;
function defined(v:tline):boolean; overload;

procedure chomp(var s:string);
function  join(sepa:string; buf:array of string):string; overload;
function  join(sepa:string; buf:TStringList):string;  overload;
procedure push(var buf:tline; v:string);
function  shift(var buf:tline):string; overload;
function  shift(buf:TStringList):string; overload;
function  sys_time():Extended;
function  DT2Time(DT: TDateTime): extended;
function  Time2DT(time_t: extended): TDateTime;
function  HexToInt(HexStr: String): Int64;
function  UrlEncode(const DecodedStr: String; Pluses: Boolean): String;
function  UrlDecode(const EncodedStr: String): String;

function  p_open(var Handle: Integer; const FileName: string):boolean;
procedure p_close(var Handle: Integer);
function  p_read(const Handle: Integer; var Buffer:string; Count: Integer):Integer;

procedure readln2(var f:Textfile; var buf:string);
function ReadLn3(var F: File; var buf: string): Boolean;


function  GetFileDate(const FileName: String; var GetDate: TDateTime): Boolean;
function  SetFileDate(const FileName: String; const NewDate: TDateTime): Boolean;
function  _GetFileSize(const FileName: String): Integer;

function  IsNewFile(const ThisFileName, ThatFileName: String): Boolean;

function  _open(const FileName: string; const mode: word):integer;
procedure _close(var Handle: Integer);



implementation


uses
  RegExpr, Synautil,RegularExp, main;



//---------------------------------------------------------------------
// WWWで使用する言語情報を優先順の低い方から並べて求める
//
// en,ja;q=0.5 ----> en;q=1.0,ja;q=0.5 q=が無い場合は1.0と判断する
//
procedure DecodeLanguage(input:string;ret:TStringList);
var
  a,b:TStringList; s,id,pi:string; m,p:integer;
begin
  a := TStringList.Create;
  b := TStringList.Create;
  try
    //id;q=xxx--->q=xxx;idへ変更し、プライオリティでソート
    b.clear;
    split(input,',',a);
    m := 0;
    while (m < a.count) do begin
      s := a.Strings[m];
      p := pos(';',s);
      if (p = 0) then begin
        s := 'q=1.0;' + s;
      end else begin
        id := copy(s,1,p-1);
        pi := copy(s,p+1,length(s));
        s := pi + ';' + id;
      end;
      b.add(s);
      inc(m);
    end;

    //プライオリティの低い順に言語idだけを返す
    b.sort;
    ret.Clear;
    m := 0;
    while (m < b.count) do begin
      s := b.Strings[m];
      s := copy(s,pos(';',s)+1,length(s));
      ret.add(s);
      inc(m);
    end;
  finally
    b.free;
    a.free;
  end;
end;


function StrToFloatDef(s:string;v:extended):extended;
begin
  Result := v;
  if s = '' then
    s := '0';
  try
    Result := StrToFloat(s);
  except
    //
  end;
end;


function ccc(instr:string):string;
var
  n,i:integer; c:char;
begin
  Result := '';
  i := length(instr);
  n := 0;
  while ( n < i ) do begin
    c := instr[n+1];
    if (c >= #32) then begin
      Result := Result + c;
    end else begin
      //エラートラップ
      Result := Result;

    end;
    inc(n);
  end;
 

end;

//----------------
function ByteStr2Bin(c:string):uchar;

  function stob(u:uchar):uchar;
  var
    a : uchar;
  begin
    case u of
      uchar('0')..uchar('9'): a := u - $30;
      uchar('A')..uchar('F'): a := u - $41 + $a;
      uchar('a')..uchar('f'): a := u - $61 + $a;
    else
      a := $0;
    end;
    Result := a;
  end;

begin
  Result := (stob(uchar(c[1])) shl 4) or stob(uchar(c[2]));
end;


//----------------
function Bin2ByteStr(c:uchar):string;

  function btos(u:uchar):string;
  var
    a : uchar;
  begin
    case u of
      $0..$9: a := u + $30;
      $a..$f: a := u + $61 - $a;
    else
      a := $0;
    end;
    Result := Char(a);
  end;
var
  c1,c2:uchar;
begin
  c1 := c shr 4;
  c2 := c and $f;
  Result := btos(c1) + btos(c2);
end;


//----------------
function grep(exp:string;data:TStringList):Boolean;  // overload
var
  r:TRegularExp; s:string; m:integer;
begin
  Result := False;
  r := TRegularExp.Create;
  try
    m := 0;
    while (m < data.count) do begin
      s := data.Strings[m];
      Result := r.RegCompCut(s,exp,True);
      if Result then
        break;
      inc(m);
    end;
  finally
    r.free;
  end;
end;

//----------------
function grep(exp:string;data,ret:TStringList):Boolean;  // overload
var
  r:TRegularExp; s:string; m:integer;
begin
  Result := False;
  r   := TRegularExp.Create;
  ret.clear;
  try
    m := 0;
    while (m < data.count) do begin
      s := data.Strings[m];
      if r.RegCompCut(s,exp,True) then begin
        Result := True;
        ret.add(s);
      end;
      inc(m);
    end;
  finally
    r.free;
  end;
end;

//----------------
function localtime(tm:TFileTime):TTime_t; //overload;
begin
  result := FileTimeToTime_T(tm);
end;

//----------------
function localtime():TTime_t; //overload;
begin
  result := FileTimeToTime_T(DateTimeToFileTime(now));
end;



//----------------------------------------------------
function before_month( yyyymm : longint ) : longint;
var
  nen, tuki : longint;
begin
  nen  := yyyymm div 100;
  tuki := yyyymm mod 100;
  if (tuki = 1 ) then begin
    tuki := 12;
    dec(nen);
  end else begin
    dec(tuki);
  end;
  Result := nen * 100 + tuki;
end;

//----------------------------------------------------
function next_month( yyyymm : longint ) : longint;
var
  nen, tuki : longint;
begin
  nen := yyyymm div 100;
  tuki := yyyymm mod 100;
  if ( tuki = 12 ) then begin
    tuki := 1;
    inc(nen);
  end else begin
    inc(tuki);
  end;
  result := nen * 100 + tuki;
end;

//----------------------------------------------------
function month_days( yyyymm : longint ) : longint;
var
  nen, tuki : longint;
const
  day_suu : array[0..11] of longint =
    (31, 0,31,30,31,30,31,31,30,31,30,31);
  //  1  2  3  4  5  6  7  8  9 10 11 12
begin
  Result := 0;
  if yyyymm < 100 then Exit;
  nen  := yyyymm div 100;
  tuki := yyyymm mod 100;
  Result := day_suu[tuki-1];
  if tuki = 2 then begin
    if ( (nen mod 4 = 0) and (nen mod 100 <> 0) or (nen mod 400 = 0) ) then begin
      Result := 29;
    end else begin
      Result := 28;
    end;
  end;
end;

//----------------------------------------------------
function def_day( yyyymmdd_a, yyyymmdd_b : longint ) : longint;
var
  now_day, nokori_day, hi, days: longint;
  nengappi_a, nengappi_b : longint;
begin
  days := 0;
  if ( yyyymmdd_a <> yyyymmdd_b ) then begin
    if ( yyyymmdd_a > yyyymmdd_b ) then begin
      nengappi_a := yyyymmdd_b;
      nengappi_b := yyyymmdd_a;
    end else begin
      nengappi_a := yyyymmdd_a;
      nengappi_b := yyyymmdd_b;
    end;
    while True do begin
      if ( (nengappi_a div 100) = (nengappi_b div 100) ) then begin
        now_day := nengappi_a mod 100;
        hi := nengappi_b mod 100;
        nokori_day := hi - now_day;
        days := days + nokori_day;
        break;
      end else begin
        now_day := nengappi_a mod 100;
        hi := month_days(nengappi_a div 100 );
        nokori_day := hi - now_day;
        days := days + nokori_day;
        nengappi_a := next_month(nengappi_a div 100 ) * 100;
      end;
    end;
  end;
  result := days;
end;


//----------------------------------------------------------------------------
// glob
//
function glob(file_patarn:string;ret:TStringList):TStringList;
var
  sr:TSearchRec; ans:integer; r:TRegularExp;
begin
  r := TRegularExp.Create;
  try
    ret.clear;
    ans := FindFirst(file_patarn, faAnyFile,sr);
    while (ans = 0) do begin
      ret.add(sr.Name);
      ans := FindNext(sr);
    end;
    FindClose(sr);
  finally
    r.free;
  end;
end;


//----------------------------------------------------------------------------
// splist
//
function split(input:string;sstr:string;ret:TStringList):TStringList;
var
  m,i,p:integer; schop, s: string;
begin
  Result := ret;
  Result.clear;
  m := length(input);
  while(m > 0) do begin
    p := pos(sstr,input);
    if p <= 0 then begin
      ret.add(input);
      break;
    end;
    s := copy(input,1,p-1);
    ret.add(s);
    input := copy(input,p+length(sstr),m);
    m := length(input);
  end;
end;


//----------------------------------------------------------------------------
// splist
//
function split(input:string;sstr:string;limit:integer; ret:TStringList):TStringList;
var
  q,m,i,p:integer; schop: string;
begin
  Result := ret;
  Result.clear;
  q := 1;
  m := length(input);
  while ((m > 0) and (q < limit)) do begin
    p := pos(sstr,input);
    if p <= 0 then begin
      m := 0;
      ret.add(input);
      break;
    end;
    ret.add(copy(input,1,p-1));
    input := copy(input,p+length(sstr),m);
    m := length(input);
    inc(q);
  end;
  if (m > 0) then
    ret.add(input);
end;


(*
//----------------------------------------------------------------------------
// splist
//
function split(input:string;sstr:string;limit:integer; ret:TStringList):TStringList;
var
  q,m,i,p:integer; schop: string;
begin
  Result := ret;
  Result.clear;
  q := 0;
  m := length(input);
  while ((m > 0) and (q < limit)) do begin
    p := pos(sstr,input);
    if p <= 0 then begin
      m := 0;
      ret.add(input);
      break;
    end;
    ret.add(copy(input,1,p-1));
    input := copy(input,p+length(sstr),m);
    m := length(input);
    inc(q);
  end;
  if (m > 0) then
    ret.Strings[ret.Count-1] := ret.Strings[ret.Count-1] + input;
end;
*)



//----------------------------------------------------------------------------
function defined(v:string):boolean; //overload;
begin
  Result := (v <> '');
end;

function defined(v:integer):boolean; //overload;
begin
  Result := (v <> 0);
end;

function defined(v:tline):boolean; //overload;
begin
  Result := (v <> nil);
end;


//----------------------------------------------------------------------------
procedure chomp(var s:string);
var
  i : integer;
begin
  while (length(s) > 0) do begin
    i := length(s);
    if (s[i] = #13) or (s[i] = #10) then
      s := copy(s,1,i-1)
    else
      break;
  end;
end;


//----------------------------------------------------------------------------
function join(sepa:string; buf:array of string):string; //overload
var
  m,n:integer;
begin
  Result := '';
  m := length(buf)-1;
  if m < 0 then
    exit;
  Result := buf[0];
  for n := 1 to m do
     Result := Result + sepa + buf[n];
end;

//----------------------------------------------------------------------------
function join(sepa:string; buf:TStringList):string;  //overload
var
  m,n:integer;
begin
  Result := '';
  m := buf.count - 1;
  if m < 0 then
    exit;
  Result := buf[0];
  for n := 1 to m do
     Result := Result + sepa + buf.Strings[n];
end;

//----------------------------------------------------------------------------
procedure push(var buf:tline; v:string);
var
  n:integer;
begin
  n := length(buf);
  inc(n);
  SetLength(buf,n);
  buf[n-1] := v;
end;

//----------------------------------------------------------------------------
function shift(var buf:tline):string; // overload;
var
  n:integer;
begin
  Result := '';
  if buf = Nil then
    exit;
  n := length(buf);
  Result := buf[0];
  buf := copy(buf,1,n-1);
end;


//----------------------------------------------------------------------------
function shift(buf:TStringList):string; // overload;
var
  n:integer;
begin
  Result := '';
  if buf = Nil then
    exit;
  n := buf.Count;
  Result := buf.Strings[0];
  buf.delete(0);
end;


//----------------------------------------------------------------------------
function sys_time():extended;
begin
  Result := DT2Time(now);
end;

//----------------------------------------------------------------------------
function DT2Time(DT: TDateTime): extended;      // Thanks Crescent.
var
  tz: TTimeZoneInformation; DTb: TDateTime;
begin
  GetTimeZoneInformation(tz);
  DTb := 365 * 70 + 19 - (tz.bias / (60 * 24));
  Result := Trunc((DT - DTb) * (24 * 60 * 60));
end;

//----------------------------------------------------------------------------
function Time2DT(time_t: extended): TDateTime;  // Thanks Crescent.
var
  tz: TTimeZoneInformation; DTb: TDateTime;
begin
  GetTimeZoneInformation(tz);
  DTb := 365 * 70 + 19 - (tz.bias / (60 * 24));
  Result := time_t / (24 * 60 * 60) + DTb;
end;

//----------------------------------------------------------------------------
function HexToInt(HexStr: String): Int64;
var
  RetVar : Int64;i : byte;
begin
  HexStr := UpperCase(HexStr);
  if HexStr[length(HexStr)] = 'H' then
     Delete(HexStr,length(HexStr),1);
  RetVar := 0;

  for i := 1 to length(HexStr) do begin
      RetVar := RetVar shl 4;
      if HexStr[i] in ['0'..'9'] then
         RetVar := RetVar + (byte(HexStr[i]) - 48)
      else
         if HexStr[i] in ['A'..'F'] then
            RetVar := RetVar + (byte(HexStr[i]) - 55)
         else begin
            Retvar := 0;
            break;
         end;
  end;

  Result := RetVar;
end;

//----------------------------------------------------------------------------
function UrlEncode(const DecodedStr: String; Pluses: Boolean): String;
var
  I: Integer;
begin
  Result := '';
  if Length(DecodedStr) > 0 then
    for I := 1 to Length(DecodedStr) do begin
      if not (DecodedStr[I] in ['0'..'9', 'a'..'z', 'A'..'Z', ' ']) then
        Result := Result + '%' + IntToHex(Ord(DecodedStr[I]), 2)
      else if not (DecodedStr[I] = ' ') then
        Result := Result + DecodedStr[I]
      else begin
        if not Pluses then
          Result := Result + '%20'
        else
          Result := Result + '+';
      end;
    end;
end;

//----------------------------------------------------------------------------
function UrlDecode(const EncodedStr: String): String;
var
  I: Integer;
begin
  Result := '';
  if Length(EncodedStr) > 0 then begin
    I := 1;
    while I <= Length(EncodedStr) do begin
      if EncodedStr[I] = '%' then begin
          Result := Result + Chr(HexToInt(EncodedStr[I+1] + EncodedStr[I+2]));
          I := Succ(Succ(I));
      end else if EncodedStr[I] = '+' then
        Result := Result + ' '
      else
        Result := Result + EncodedStr[I];

      I := Succ(I);
    end;
  end;
end;


//----------------------------------------------------------------------------
function p_open(var Handle: Integer; const FileName: string):boolean;
var
  mode:word;
begin
  mode := fmOpenRead or fmShareDenyNone;
  Handle := _open(FileName,mode);
  Result := (Handle <> -1);
end;

//----------------------------------------------------------------------------
procedure p_close(var Handle: Integer);
begin
  _close(Handle);
end;

//----------------------------------------------------------------------------
function p_read(const Handle: Integer; var Buffer: string; Count: Integer): Integer;
var
  sizeR: Integer; tmp: array[0..1024] of Char;
begin
  if FileSeek(Handle,0,1) = -1 then begin
    Result := -1;
    Exit;
  end;

  Result := 0;
  while (Result < Count) do begin
    sizeR := FileRead(Handle, tmp, 1024);
    if sizeR <= 0 then
      Break;

    SetLength(Buffer, Result + sizeR);
    Move(tmp, Pointer(@Buffer[Result+1])^, sizeR);

    Inc(Result, sizeR);
  end;
end;


(*
const
  BBB_SIZE = 1024*8;
procedure readln2(var f:File; var buf:string);
var
  b:Char; n, len, max:Integer; bbb : array [0..BBB_SIZE] of char ;
begin
  buf := '';
  while Not Eof(f) do begin
    BlockRead(f, bbb, BBB_SIZE, len);
    n := 0;
    while(n < len) do begin
      if bbb[n] = #10 then begin
        seek(f, n - len);
        buf := buf + Copy(bbb, 1, n);
        exit;
      end;
      inc(n);
    end;
    buf := buf + Copy(bbb, 1, len);
  end;

end;
*)

procedure readln2(var f:textFile; var buf:string);
var
  b:Char;
begin
  buf := '';
  while Not Eof(f) do begin
    read(f,b);
    if b >= ' ' then
      buf := buf + b;
    if b = #10 then
      break;
  end;

end;


function ReadLn3(var F: File; var buf: string): Boolean;
var
  b: array[0..1024*128] of char; i,len, P: Integer;
begin
  buf := '';
  repeat
    P := FilePos(F);
    BlockRead(F, b, SizeOf(b), len);
    for i := 0 to len - 1 do begin
      if b[i] in [#0, #10, #13] then begin
        buf := buf + Copy(b, 1, i);
        if (i < len - 1) and (b[i+1] in [#0, #10, #13]) then Inc(P);
        Seek(F, P + i + 1);
        Result := not Eof(F);
        Exit;
      end;
    end;
    buf := buf + Copy(b, 1, len);
  until (len < SizeOf(b));
  Result := False;
end;


//============================================================================
//============================================================================
//============================================================================
//============================================================================


//----------------------------------------------------------------------------
// FILE OPEN
// IN  FileName
//     mode   (fmOpenRead or fmOpenWrite or fmOpenReadWrite )
//          + (fmShareExclusive or fmShareDenyWrite or fmShareDenyRead
//             or fmShareDenyNone)
// Result Handle (error: -1)
//----------------------------------------------------------------------------
function _open(const FileName: string; const mode: word): Integer;
begin
 Result := FileOpen(FileName,mode);
end;

//----------------------------------------------------------------------------
//FILE CLOSE
procedure _close(var Handle: Integer);
begin
  if Handle <> 0 then
    CloseHandle(Handle);
  Handle := 0;
end;




//----------------------------------------------------------------------------
//
function GetFileDate(const FileName: String; var GetDate: TDateTime): Boolean;
var
  hF: Integer;
begin
  Result := False;
  GetDate := Now;
  if (not FileExists(FileName)) then exit;
  hF := FileOpen(FileName, fmShareDenyWrite);
  try
    GetDate := FileDateToDateTime(FileGetDate(hF));
    Result := True;
  finally
    FileClose(hF);
  end;
end;


//----------------------------------------------------------------------------
//
function SetFileDate(const FileName: String; const NewDate: TDateTime): Boolean;
var
  hF, Age: Integer;
begin
  Result := False;
  if (not FileExists(FileName)) then exit;
  Age := DateTimeToFileDate(NewDate);
  hF := FileOpen(FileName, fmOpenReadWrite);
  try
    Result := (FileSetDate(hF, Age) = 0);
  finally
    FileClose(hF);
  end;
end;


//----------------------------------------------------------------------------
function _GetFileSize(const FileName: String): Integer;
var
  sRec: TSearchRec;
begin
  if FindFirst(FileName, faAnyFile, sRec) = 0 then
    Result := sRec.Size
  else
    Result := -1;
  FindClose(sRec);
end;


//----------------------------------------------------------------------------
//True will be returned if "ThisFileName" is a date newer than "ThatFileName".
//
function IsNewFile(const ThisFileName, ThatFileName : String): Boolean;
var
  ThatYMD, ThisYMD: TDateTime;
begin
  Result := False;
  if (not FileExists(ThatFileName)) then exit;
  if (not FileExists(ThisFileName)) then exit;
  if (not GetFileDate(ThatFileName, ThatYMD)) then exit;
  if (not GetFileDate(ThisFileName, ThisYMD)) then exit;
  Result := (ThisYMD > ThatYMD);
end;



end.




