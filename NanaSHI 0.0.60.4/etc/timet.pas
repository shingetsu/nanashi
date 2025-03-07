unit timet;

//
// ���Ԍ`���̕ϊ��T�|�[�g���[�`���W
//
// Copyright (C) 1999 Ayakawa,Marinosuke & MarleySoft
//
// HGD00106@nifty.ne.jp / ayakawa@ac.mbn.or.jp
//
// �g�p�E���ǁE�]�ځE�z�z
//�@ ���̃��j�b�g�ɂ��āA�g�p�E�]�ځE�z�z�͂����R�ɂȂ����Ă��������B
// �@�ł��A�]�ځE�z�z����Ƃ��̓A�[�J�C�u�̍\���͕ς��Ȃ��łˁB
//   ���O�E����̘A���͂���܂���B
//   ���ǂ������̂��A�����R�Ɏg�p�E�z�z�E�]�ڂ��Ă��������i���Ă��邩
//   �ǂ����͉��ǂ����l�̈ӎv�ł����j�B�������A���̃��j�b�g�ɂ��Ă�
//   �������E�`���͈���ɂ́u�����v���Ƃ͖��L���Ă����Ă��������B
//
// ���񑩂���
// �@���̃��j�b�g�A���͉��ρE���ǂ��ꂽ���j�b�g�̎g�p�ɂ��A�Ȃ�炩
//   �̔�Q�����Ă���ҁ@����f�T��i�s�ہ@���j�́A��ؐӔC�𕉂���
//   ����B��g�p�ɂȂ�����̐ӔC�̌��ɁA���̌��ʂ𕉂��Ă��������B
//
// rev 1999/01/18
//     *�쐬
// rev 1999/01/19
//     *UTC�֘A���A�Z���u���ŏ�������
//     *DateTimeToDosTime���O�𑗏o����悤�ɕύX
// rev 1999/02/03
//     *DosTime�̏���̃~�X���C��(2099��2079)
// rev 1999/06/06
//     *��O���o���Ȃ��o�[�W����������ǉ�
//

interface

uses
  windows,sysutils;

  
type
  // time_t
  PTime_t = ^TTime_t;
  TTime_t = Integer;

// OS��FileTime Format����Delphi��TDateTime�ւ̃R���o�[�g�i��b�΍�j
// �Ԃ�LocalTime�ւ̕ϊ������܂��Ă���̂Œ��ӂ��Ăˁ`
function FileTimeToDateTime(ft:TFileTime):TDateTime;
function DateTimeToFileTime(dt:TDateTime):TFileTime;
// ��O�Ȃ���
function FileTimeToDateTime2(ft:TFileTime; ADefault:TDateTime):TDateTime;
function DateTimeToFileTime2(dt:TDateTime; ADefault:TFileTime):TFileTime;

// LocalTime�|DateTime���ݕϊ�
function LocalTimeToDateTime(lt:TFileTime):TDateTime;
function DateTimeToLocalTime(dt:TDateTime):TFileTime;

// TimeStamp��MS-DOS�`���ɐ؂�グ��(Delphi�̂��Ɛ؂�̂ĂɂȂ�)
function DateTimeToDosTime(dt:TDateTime):TDateTime;
function DateTimeToDosTime2(dt:TDateTime; ADefault:TDateTime):TDateTime; // ��O���o���Ȃ�

// UTC/FileTime/DateTime Convert
function Time_TtoFileTime(utc:TTime_t):TFileTime; // GST -> GST
function FileTimeToTime_T(ft:TFileTime):TTime_t;  // GST -> GST
function Time_TtoDateTime(utc:TTime_t):TDateTime; // LocalTime�ɂ��Ă܂�
function DateTimeToTime_T(dt:TDateTime):TTime_t;  // Local��dt�l���Ɖ��肵�Ă��܂�

implementation

//
// TFILETIME  ... 1601/01/01 00:00:00���N�_ 0.1�ʕb�P��
// TTimt_t    ... 1970/01/01 00:00:00���N�_ 1�b�P��
// TDateTime  ... 1899/12/30 00:00:00���N�_ ?�b�P��(�s��)
// TTimeStamp ...    1/01/01 00:00:00���N�_ �P�~���b�P��
//

const
  // 1970/01/01��TFileTime�Ō������ꍇ
  UTCDelta : TFileTime = ( dwLowDateTime:$D53E8000;
                           dwHighDateTime:$19DB1DE ;);

//
// UTC <-> FILETIME
//
function Time_TtoFILETIME(utc:TTime_t):TFILETIME;
var
  w : TFileTime;
begin
  // result:=utc*10000000+('1601/01/01����1970/01/01�܂ł̍���');
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
  // 1970/01/01�ȑO�Ȃ�ϊ��ł��Ȃ�
  IF CompareFileTime(ft,UTCDelta)<0 THEN
    raise EConvertError.Create('before 1970/01/01');
  // (ft-('1601/01/01����1970/01/01�܂ł̍���'))/10000000;
  asm
    mov  eax,ft.dwLowDateTime
    mov  edx,ft.dwHighDateTime
    mov  ecx,10000000
    sub  eax,$D53E8000
    sbb  edx,$19DB1DE
    div  ecx              // 40 clock ...
    mov  u,eax            // �]��͖�������
  end;
  result:=u;
end;

//
//  UTC <-> DATETIME(local�R���o�[�g��)
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
// FileTime <-> DateTime(local�R���o�[�g��)
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
    // �������炪DateTimeToFileDate�ƈႤ
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
  // �������炪DateTimeToFileDate�ƈႤ
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
