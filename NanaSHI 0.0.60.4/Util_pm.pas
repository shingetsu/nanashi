unit Util_pm;

interface

uses
  Classes, blcksock, winsock, Synautil, SysUtils, RegularExp,Config, httpsend,
  windows, Dialogs, SyncObjs;




function localtime():Extended;
procedure lock();
procedure unlock();
procedure addUpdate(stamp,id,filename:string);
function wget(url:string; ret,ENV:TStringList):TStringList;
function rec(recdata:string;arec,ENV:TStringList):TStringList;
function md5check(v:TStringList):TStringList;


implementation

uses
  main, CacheStat_pm,lib1;

var
  FLock: TCriticalSection;
  FLocked: TFileStream;


//-----------------------------------------
// time with error
//
function localtime():Extended;
begin
  Result := sys_time();
end;



//-------------------------------------
procedure Lock();
begin
  FLock.Enter;
  if FLocked <> nil then begin
    exit;
  end;
  while true do begin
    try
      FLocked := TFileStream.Create(D_LOCKFILE, fmCreate);
      if FLocked <> nil then
        exit;
    except
      //
    end;
    Sleep(D_LOCKWAIT);
  end;
end;

//-------------------------------------
procedure Unlock();
begin
  if FLocked <> nil then begin
    try
      FLocked.Free;
    except
      //
    end;
    FLocked := nil;
  end;
  FLock.Leave;
end;


//-----------------------------------------------------------------------------
//日付差が２４時間以内を維持しながら指定ファイルをupdate.txtへ追加
//
procedure addUpdate(stamp,id,filename:string);
var
  update,ret:TStringList; SIN:TextFile; tmp:string; n:integer; nw:Extended;
begin
  update := TStringList.Create;
  ret := TStringList.Create;
  lock();
  try
    //オリジナルと異なる
    if not FileExists(D_UPDATELIST) then begin
      AssignFile(SIN,D_UPDATELIST);
      rewrite(SIN);
      CloseFile(SIN);
    end;

    //update.txtを読み込む
    update.Clear;
    AssignFile(SIN,D_UPDATELIST);
    try
      Reset(SIN);
      while not Eof(SIN) do begin
        Readln2(SIN,tmp);
        update.add(tmp);
      end;
      CloseFile(SIN);
    except
      //
    end;

    //読み込んだバッファへ情報を追加する
    update.add(stamp + '<>' + id + '<>' + filename);

    //バッファをupdate.txtとして新規作成する
    nw := sys_time();
    AssignFile(SIN,D_UPDATELIST);
    try
      ReWrite(SIN);
      n := 0;
      while (n < update.count) do begin
        tmp := update.Strings[n];
        split(tmp,'<>',ret);
        if ((nw - StrToIntDef(ret.Strings[0],0)) <= (D_SAVEUPDATE * 60)) then begin
          //日付が１日以内の差だったらupdate.txtへ書き出す
          writeln(SIN,tmp);
        end;
        inc(n);
      end;
      CloseFile(SIN);
    except
      //
    end;
    
  finally
    unlock();
    ret.free;
    update.free;
  end;
end;


//-----------------------------------------------------------------------------
//
function rec(recdata:string; arec,ENV:TStringList):TStringList;
var
  a_,buf:TStringList; n:integer; s,idname:string; r:TRegularExp;
begin
  Result := arec;
  arec.clear;
  a_  := TStringList.Create;
  buf := TStringList.Create;
  r   := TRegularExp.Create;
  chomp(recdata);
  try
    if not CacheStat_pm.isOkRecord(recdata) then begin
      s := copy(recdata,1,32);
      if not defined(s) then
        s := 'BLANK';
   (*
      ErrorPrint('util_pm.rec() : can`t process! >>> ' + s
              + ' ip:' + ENV.Values['REMOTE_ADDR']
              + ' agent:'+ ENV.Values['HTTP_USER_AGENT'] );
   *)
      ErrorPrint('util_pm.rec() : can`t process! >>> ' + s );
      exit;
    end;

    split(recdata, '<>', a_);
    arec.Values['stamp'] := a_.Strings[0];   // tmpが空ならエラー？？
    arec.Values['id']    := a_.Strings[1];   //
    n := 0;
    while ( n < a_.Count ) do begin
      s := a_.strings[n];
      split( s, ':', 2, buf);
      if buf.Count >= 2 then begin
        idname := buf.Strings[0];
        s := buf.Strings[1];
        s := r.RegReplace(s,'<br>',#10,True);
	s := r.RegReplace(s,'<','&lt;',True);
	s := r.RegReplace(s,'>','&gt;',True);
	s := r.RegReplace(s,#10,'<br>',True);
        arec.Values[idname] := s;
      end;
      inc(n);
    end;

  finally
    r.free;
    a_.free;
    buf.free;

  end;


end;





//-----------------------------------------------------------------------------
//wget
//
function wget(url:string; ret,ENV:TStringList):TStringList;
var
  HTTP: THTTPSend; s:string;
begin
  Result := ret;

  ret.clear;
  HTTP := THTTPSend.Create;
  with HTTP do begin
    Timeout   := D_WGET_TIMEOUT;
    UserAgent := ENV.Values['SERVER_SOFTWARE'];
    MimeType  := config.mimeType.Values['txt'];
    KeepAlive := False;
  //Headers.Insert(0, 'Accept-Encoding: gzip');
  end;
  try
    HTTP.HTTPMethod('GET', url);
    ret.LoadFromStream(HTTP.Document);
    ENV.Values['WGET_RETURN_SERVER']      := HTTP.RetServer;
    ENV.Values['WGET_RETURN_X-SHINGETSU'] := HTTP.RetXShingetsu;
    ENV.Values['WGET_RETURN_USER_AGENT']  := HTTP.RetAgent;

  finally
    HTTP.Free;
  end;

end;


function md5check(v:TStringList):TStringList;
begin
  //未完成
  Result := v;
end;



///////////////////////////////////////////////////
///////////////////////////////////////////////////
///////////////////////////////////////////////////



initialization
  FLock := TCriticalSection.Create;
  FLocked := nil;

finalization
  if FLocked <> nil then begin
    try
      FLocked.Free;
    except
    end;
    FLocked := nil;
  end;
  FLock.free;

end.

