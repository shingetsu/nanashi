unit CacheStat_pm;

interface

uses
  Classes, blcksock, winsock, Synautil, SysUtils, RegularExp, lib1, windows;


function isOkFile(s:string):Boolean;
function isOkRecord(s:string):Boolean;

function __stamp(key:string):string;
function __records(key:string):string;
function __size(key:string):string;

procedure list(res:TStringList);
procedure stat_sync(res:TStringList);
procedure dellist(res:TStringList;afile:string);
procedure Cache_update();





implementation


uses
  Config, util_pm, main;

//--------------------------------------------------------
//正しいレコードであるか判断する
//
function isOkRecord(s:string):Boolean;
var
  tmp:TStringList;
begin
  Result := False;
  tmp := TStringList.Create;
  try
    split(s, '<>', tmp);
    if (tmp.count < 2) then
      exit;
    Result := True;
  finally
    tmp.free;
  end;
end;

//--------------------------------------------------------
//正しいファイルであるか判断する
//
function isOkFile(s:string):Boolean;
var
  r:TRegularExp; fname:string;
begin
  Result := False;

  r := TRegularExp.create;

  //フルパスとフルパスでないネームをサポートする為、この処理を行う。
  fname := s;
  fname := r.RegReplace(fname,D_DATADIR+'/','');


  try
    if not FileExists(DataPath2(fname)) then begin
      if _GetFileSize(DataPath2(fname)) > (D_FILELIMIT*1024*1024) then
        exit;
    end;

    if r.RegCompCut(fname,'^list_(\S+).dat$',True) then begin
      Result := True;
      exit;
    end;
    if r.RegCompCut(fname,'^thread_(\S+).dat$',True) then begin
      Result := True;
      exit;
    end;
    if r.RegCompCut(fname,'^note_(\S+).dat$',True) then begin
      Result := True;
      exit;
    end;

  finally
    r.free;

  end;
  
end;


//--------------------------------------------------------
//オリジナルは,"<>"で区切られた１番目をハッシュ名、
//stamp=>2番目、records=>3番目、size=>4番目を
//そのハッシュのメンバとしていた。

//--->１番目をハッシュ名|1-stamp   = 値（2番目）
//    １番目をハッシュ名|2-records = 値（3番目）
//    １番目をハッシュ名|3-size|   = 値（4番目）
//
// 上記内容でTStringListにセットする
//

//-----------------
function __stamp(key:string):string;
begin
  Result := key + '|1-stamp';
end;

//-----------------
function __records(key:string):string;
begin
  Result := key + '|2-records';
end;

//-----------------
function __size(key:string):string;
begin
  Result := key + '|3-size';
end;

//-------------------------------------------------------
//stat.txtをメモリに読み込む
//
//finame<>stamp<>records<>size
//
procedure list(res:TStringList);
var
  SIN:File; tmp:string; buf:TStringList;
begin
  buf := TSTringList.Create;
  res.clear;

  try
    if not FileExists(D_STATFILE) then  exit;
    if _GetFileSize(D_STATFILE) <= 0 then exit;

    //stat.txtを読み込む
    AssignFile(SIN, D_STATFILE);
    Reset(SIN,1);
    while not Eof(SIN) do begin
      Readln3(SIN,tmp);
      split(tmp,'<>',buf);
      if (buf.count >=4) then begin
        res.Values[__stamp(buf.Strings[0])]   := buf.Strings[1];
        res.Values[__records(buf.Strings[0])] := buf.Strings[2];
        res.Values[__size(buf.Strings[0])]    := buf.Strings[3];
      end else begin
        //
      end;
    end;
    CloseFile(SIN);

  finally
    res.sort;
    buf.free;
  end;

end;


//--------------------------------------------------------
procedure dellist(res:TStringList;afile:string);
var
  z,m:integer; s:string;
begin
  z := res.count;
  m := 0;
  while (m < z) do begin
    s := copy(res.Strings[m],1,length(afile));
    if (s = afile) then begin
      res.delete(m);
    end else begin
      inc(m);
    end;
    z := res.count;
  end;


end;

//--------------------------------------------------------
//resをstat.txtに最終的に書き込むルーチン
//
//filename<>stamp<>records<>size
//
procedure stat_sync(res:TStringList);
var
  SIN:TextFile; m:integer; s,tmp:string; r:TRegularExp;
  afile,astamp,arecord,asize:string;
begin
  r := TRegularExp.Create;
  util_pm.lock();
  try
    AssignFile(SIN, D_STATFILE);
    ReWrite(SIN);
    res.sort;
    m := 0;
    while m < res.count do begin
      tmp := '';
      s := res.Strings[m];   //1-stamp の存在を確認するべきかも･･･
      r.RegCompCut(s,'^(\S+)\|(\S+)=(\S+)',True);
      afile  := r.grps('$1');
      astamp := r.grps('$3');

      inc(m);
      if m >= res.count then break;      //error となったので加えた
      s := res.Strings[m];   //2-record の存在を確認するべきかも･･･
      r.RegCompCut(s,'^(\S+)\|\S+=(\S+)',True);
      arecord := r.grps('$2');

      inc(m);
      if m >= res.count then break;      //error となったので加えた
      s := res.Strings[m];  //3-size の存在を確認するべきかも･･･
      r.RegCompCut(s,'^(\S+)\|\S+=(\S+)',True);
      asize:= r.grps('$2');

      //★TStringListの書込みソート条件で異なるので注意
      tmp := afile + '<>' + ccc(astamp) + '<>' + arecord + '<>' + asize;   //マーク

      writeln(SIN,tmp); 

      inc(m);
    end;
    CloseFile(SIN);

  finally
    r.free;
    util_pm.unlock();

  end;

end;



//--------------------------------------------------------
// update();
//
// *.datをstat.txtへ書き出すルーチン
//
// 起動時に１度、実行する
// client_cgiで(NodeList_pm.NodeCount=0)の時、呼び出される
// client_cgiでD_SYNCFRECの時、呼び出される
//
procedure Cache_update();
var
  stat,ret,ans,dat:TStringList; cnt,m:integer; s_,fname,lastrec,nname:string;
  r:TRegularExp; SIN:TextFile; GetDate: TDateTime;
begin
  main.dprint('*** CACHE STAT UPDATE (IN) ********************** ');

  r    := TRegularExp.Create;
  ret  := TStringList.Create;
  stat := TStringList.Create;
  ans  := TStringList.Create;
  dat  := TStringList.Create;

  try
    glob(D_DATADIR+'/*.dat',ret);
    stat.clear;

    util_pm.lock();

    m := 0;
    while ( m < ret.count) do begin
      s_ := ret.Strings[m];
      fname := DataPath2(s_);
      if isOkFile(fname) then begin

        //登録件数(cnt)と最終レコード情報(lastrec)を取得
        fname := s_;
        fname := r.RegReplace(fname,D_DATADIR+'/','');
        fname := r.RegReplace(fname,'\.dat$','');
        dat.LoadFromFile(D_DATADIR+'/'+s_);
        cnt := dat.Count;
        if cnt > 0 then
          lastrec := dat[cnt-1]
        else
          lastrec := '';

        //stamp 最終レコードが正常ならばstampを取得
        if (dat.Count > 0) then begin
          split(lastrec,'<>',ans);
          if ans.count > 0 then
            stat.values[__stamp(fname)] := ans.strings[0]   //stamp<>id<>body
          else
            stat.values[__stamp(fname)] := '0';
        end else begin
          stat.values[__stamp(fname)] := '0';
        end;

        nname := D_DATADIR+'/' + fname + '.dat';

        //注意：stamp無しは物理ファイルのスタンプをセット：オリジナルと異なる
        if stat.values[__stamp(fname)] = '0' then begin
          GetFileDate(nname,GetDate);
          stat.values[__stamp(fname)] := FloatToStr(DT2Time(GetDate));
        end;


        //records レコード件数
        stat.values[__records(fname)] := IntToStr(cnt);

        //size ファイルサイズ
        stat.values[__size(fname)]    := IntToStr((_GetFileSize(nname) div 1024) div 1024);

      end; // if isOkFile(s_) then begin

      inc(m);
    end;

  finally
    util_pm.unlock();

    //statをstat.txtに最終的に書き込むルーチン  filename<>stamp<>records<>size
    CacheStat_pm.stat_sync(stat);

    ans.free;
    r.free;
    ret.free;
    stat.free;
    dat.free; //##

    main.dprint('*** CACHE STAT UPDATE (OUT) ******************** ');

  end;

end;



end.
