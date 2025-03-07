unit timet;

//
// 時間形式の変換サポートルーチン集
//
// Copyright (C) 1999 Ayakawa,Marinosuke & MarleySoft
//
// HGD00106@nifty.ne.jp / ayakawa@ac.mbn.or.jp
//
// 使用・改良・転載・配布
//　 このユニットについて、使用・転載・配布はご自由になさってください。
// 　でも、転載・配布するときはアーカイブの構成は変えないでね。
//   事前・事後の連絡はいりません。
//   改良したものも、ご自由に使用・配布・転載してください（ってするか
//   どうかは改良した人の意思ですが）。ただし、そのユニットについての
//   諸権利・義務は綾川には「無い」ことは明記しておいてください。
//
// お約束ごと
// 　このユニット、又は改変・改良されたユニットの使用により、なんらか
//   の被害を被っても作者　綾川鞠乃介（市丸　剛）は、一切責任を負いま
//   せん。御使用になられる方の責任の元に、その結果を負ってください。
//
// rev 1999/01/18
//     *作成
// rev 1999/01/19
//     *UTC関連をアセンブラで書き直す
//     *DateTimeToDosTimeを例外を送出するように変更
// rev 1999/02/03
//     *DosTimeの上限のミスを修正(2099→2079)
// rev 1999/06/06
//     *例外を出さないバージョンを幾つか追加
//

interface

uses
  windows,sysutils;

  
type
  // time_t
  PTime_t = ^TTime_t;
  TTime_t = Integer;

// OSのFileTime FormatからDelphiのTDateTimeへのコンバート（奇数秒対策）
// 間にLocalTimeへの変換をかましてあるので注意してね～
function FileTimeToDateTime(ft:TFileTime):TDateTime;
function DateTimeToFileTime(dt:TDateTime):TFileTime;
// 例外なし版
function FileTimeToDateTime2(ft:TFileTime; ADefault:TDateTime):TDateTime;
function DateTimeToFileTime2(dt:TDateTime; ADefault:TFileTime):TFileTime;

// LocalTime－DateTime相互変換
function LocalTimeToDateTime(lt:TFileTime):TDateTime;
function DateTimeToLocalTime(dt:TDateTime):TFileTime;

// TimeStampをMS-DOS形式に切り上げる(Delphiのだと切り捨てになる)
function DateTimeToDosTime(dt:TDateTime):TDateTime;
function DateTimeToDosTime2(dt:TDateTime; ADefault:TDateTime):TDateTime; // 例外を出さない

// UTC/FileTime/DateTime Convert
function Time_TtoFileTime(utc:TTime_t):TFileTime; // GST -> GST
function FileTimeToTime_T(ft:TFileTime):TTime_t;  // GST -> GST
function Time_TtoDateTime(utc:TTime_t):TDateTime; // LocalTimeにしてます
function DateTimeToTime_T(dt:TDateTime):TTime_t;  // Localなdt値だと仮定しています

implementation

//
// TFILETIME  ... 1601/01/01 00:00:00を起点 0.1μ秒単位
// TTimt_t    ... 1970/01/01 00:00:00を起点 1秒単位
// TDateTime  ... 1899/12/30 00:00:00を起点 ?秒単位(不明)
// TTimeStamp ...    1/01/01 00:00:00を起点 １ミリ秒単位
//

const
  // 1970/01/01をTFileTimeで現した場合
  UTCDelta : TFileTime = ( dwLowDateTime:$D53E8000;
                           dwHighDateTime:$19DB1DE ;);

//
// UTC <-> FILETIME
//
function Time_TtoFILETIME(utc:TTime_t):TFILETIME;
var
  w : TFileTime;
begin
  // result:=utc*10000000+('1601/01/01から1970/01/01までの差分');
  asm
    mov  eax,utc
    mov  ecx,10000000
    mul  ecx                  // 13 clock
    add  eax,$D53E8000
    adc  edx,$19DB1DE
    mov  w.dwLowDateTime,eax
    mov  w.dwHighDateTime,edx
  end;
  result:=w;
end;

function FILETIMEtoTime_T(ft:TFILETIME):TTime_t;
var
  u : TTime_t;
begin
  // 1970/01/01以前なら変換できない
  IF CompareFileTime(ft,UTCDelta)<0 THEN
    raise EConvertError.Create('before 1970/01/01');
  // (ft-('1601/01/01から1970/01/01までの差分'))/10000000;
  asm
    mov  eax,ft.dwLowDateTime
    mov  edx,ft.dwHighDateTime
    mov  ecx,10000000
    sub  eax,$D53E8000
    sbb  edx,$19DB1DE
    div  ecx              // 40 clock ...
    mov  u,eax            // 余りは無視する
  end;
  result:=u;
end;

//
//  UTC <-> DATETIME(localコンバート済)
//
function Time_TtoDATETIME(utc:TTime_t):TDateTime;
begin
  result:=FileTimeToDateTime(Time_TtoFileTime(utc));
end;

function DateTimeToTime_T(dt:TDateTime):TTime_t;
begin
  result:=FileTimeToTime_T(DateTimeToFileTime(dt));
end;

//
// FileTime <-> DateTime(localコンバート済)
//
function FileTimeToDateTime(ft:TFileTime):TDateTime;
var
  lft : TFileTime;
  st  : TSystemTime;
  dwork,twork : TDateTime;
begin
  IF (ft.dwLowDateTime=0) AND (ft.dwHighDateTime=0) THEN
    raise EConvertError.Create('ERR:value=0');
  IF NOT FileTimeToLocalFileTime(ft,lft) THEN
    raise EConvertError.Create('ERR:FileTimeToLocalFileTime');
  IF NOT FileTimeToSystemTime(lft,st) THEN
    raise EConvertError.Create('ERR:FileTimeToSystemTime');
  WITH st DO BEGIN
    dwork:=EncodeDate(wYear,wMonth,wDay);
    twork:=EncodeTime(wHour,wMinute,wSecond,wMilliseconds);
  END;
  result:=dwork+twork;
end;

function DateTimeToFileTime(dt:TDateTime):TFileTime;
var
  lft,ft : TFileTime;
  st     : TSystemTime;
begin
  IF dt<=0.0 THEN
    raise EConvertError.Create('ERR:TDateTime<=0.0');
  WITH st DO BEGIN
    DecodeDate(dt,wYear,wMonth,wDay);
    DecodeTime(dt,wHour,wMinute,wSecond,wMilliseconds);
  END;
  IF NOT SystemTimeToFileTime(st,lft) THEN
    raise EConvertError.Create('ERR:SystemTimeToFileTime');
  IF NOT LocalFileTimeToFileTime(lft,ft) THEN
    raise EConvertError.Create('ERR:LocalTimeToFileTime');
  result:=ft;
end;

function FileTimeToDateTime2(ft:TFileTime; ADefault:TDateTime):TDateTime;
var
  lft : TFileTime;
  st  : TSystemTime;
  dwork,twork : TDateTime;
begin
  result:=ADefault;
  IF (ft.dwLowDateTime=0) AND (ft.dwHighDateTime=0) THEN Exit;
  IF NOT FileTimeToLocalFileTime(ft,lft) THEN Exit;
  IF NOT FileTimeToSystemTime(lft,st) THEN Exit;
  WITH st DO BEGIN
    dwork:=EncodeDate(wYear,wMonth,wDay);
    twork:=EncodeTime(wHour,wMinute,wSecond,wMilliseconds);
  END;
  result:=dwork+twork;
end;

function DateTimeToFileTime2(dt:TDateTime; ADefault:TFileTime):TFileTime;
var
  lft,ft : TFileTime;
  st     : TSystemTime;
begin
  result:=ADefault;
  IF dt<=0.0 THEN Exit;
  WITH st DO BEGIN
    DecodeDate(dt,wYear,wMonth,wDay);
    DecodeTime(dt,wHour,wMinute,wSecond,wMilliseconds);
  END;
  IF NOT SystemTimeToFileTime(st,lft) THEN Exit;
  IF NOT LocalFileTimeToFileTime(lft,ft) THEN Exit;
  result:=ft;
end;

//
// LocalTime <-> DateTime
//
function LocalTimeToDateTime(lt:TFileTime):TDateTime;
var
  st  : TSystemTime;
  dwork,twork : TDateTime;
begin
  IF (lt.dwLowDateTime=0) AND (lt.dwHighDateTime=0) THEN
    raise EConvertError.Create('ERR:value=0');
  IF NOT FileTimeToSystemTime(lt,st) THEN
    raise EConvertError.Create('ERR:FileTimeToSystemTime');
  WITH st DO BEGIN
    dwork:=EncodeDate(wYear,wMonth,wDay);
    twork:=EncodeTime(wHour,wMinute,wSecond,wMilliseconds);
  END;
  result:=dwork+twork;
end;

function DateTimeToLocalTime(dt:TDateTime):TFileTime;
var
  lt : TFileTime;
  st : TSystemTime;
begin
  IF dt<=0.0 THEN
    raise EConvertError.Create('ERR:TDateTime<=0.0');
  WITH st DO BEGIN
    DecodeDate(dt,wYear,wMonth,wDay);
    DecodeTime(dt,wHour,wMinute,wSecond,wMilliseconds);
  END;
  IF NOT SystemTimeToFileTime(st,lt) THEN
    raise EConvertError.Create('ERR:SystemTimeToFileTime');
  result:=lt;
end;

//
// DateTime -> DosTime
//
function DateTimeToDosTime(dt:TDateTime):TDateTime;
var
  Year, Month, Day, Hour, Min, Sec, MSec: Word;
begin
  DecodeDate(dt, Year, Month, Day);
  //if (Year < 1980) or (Year > 2079) then Result := 0 else
  IF Year < 1980 THEN raise EConvertError.Create('before 1980');
  IF Year > 2079 THEN raise EConvertError.Create('after 2079');
  begin
    DecodeTime(dt, Hour, Min, Sec, MSec);
    // ここからがDateTimeToFileDateと違う
    IF (msec>0) OR Odd(sec) THEN BEGIN
      IF Msec>0 THEN BEGIN
        Msec:=1000-MSec; INC(sec);
      END;
      IF Odd(Sec) THEN Sec:=1 ELSE Sec:=0;
      result:=dt+EncodeTime(0,0,Sec,MSec);
    END ELSE
      result:=dt;
  end;
end;

function DateTimeToDosTime2(dt:TDateTime; ADefault:TDateTime):TDateTime;
var
  Year, Month, Day, Hour, Min, Sec, MSec: Word;
begin
  result:=ADefault;
  DecodeDate(dt, Year, Month, Day);
  //if (Year < 1980) or (Year > 2079) then Result := 0 else
  IF Year < 1980 THEN Exit;
  IF Year > 2079 THEN Exit;
  DecodeTime(dt, Hour, Min, Sec, MSec);
  // ここからがDateTimeToFileDateと違う
  IF (msec>0) OR Odd(sec) THEN BEGIN
    IF Msec>0 THEN BEGIN
      Msec:=1000-MSec; INC(sec);
    END;
    IF Odd(Sec) THEN Sec:=1 ELSE Sec:=0;
    result:=dt+EncodeTime(0,0,Sec,MSec);
  END ELSE
    result:=dt;
end;

end.
