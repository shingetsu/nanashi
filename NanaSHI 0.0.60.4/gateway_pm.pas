unit gateway_pm;

interface

uses
  Classes, blcksock, winsock, Synautil, SysUtils, RegularExp, lib1, windows,timet;

const
  D_ROOT = '/';


function str_decode(a:string):string;
function str_encode(a:string):string;
function file_encode(atype,aname:string):string;
function file_decode(aname:string):string;
function rec(recdata:string;arec,ENV:TStringList):TStringList;
procedure xdie(mes:string;ENV:TStringList; mother:Tobject);
function  escape(s:string):string;
procedure args(ainput:string; arg:TStringList);
procedure argsFromMulti(ainput:string; arg:TStringList);
function xlocaltime(v:Extended):string;
procedure touch(afile:string;ENV:TStringList);
procedure readNote(afile:string; var buf, orphan:string;ENV:TStringList);
function addRecord(afile,astamp,abody:string):string;
function post(athread:string; arg:TStringList; ENV:TStringList; mother:TObject):string;
function newElement(afile:string;arg:TStringList;ENV:TStringList; mother:TObject):boolean;
function margeRecord(afile:string;arg:TStringList; ENV:TStringList; mother:TObject):Boolean;
procedure postDeleteMessage(afile, astamp, aid:string; arg,ENV:TStringList; mother:TObject);
function bracket_link(ss:string):string;
function CheckAdmin(ENV:TStringList;mother:TObject):Boolean;
procedure printHeader(title:string;ENV:TStringList;mother:TObject);
procedure print403(ENV:TStringList;mother:TObject);
procedure print404(fname:string;ENV:TStringList;mother:TObject);
procedure print302(anext:string;ENV:TStringList;mother:TObject);
function  html_format(data:string;ENV:TStringList):string;
function readQuery(var apath, ainput:string;ENV:TStringList):boolean;
procedure deleteRecordForm(arg,aarg,ENV:TStringList;mother:TObject);
procedure deleteFileForm(afile:string; buf,ENV:TStringList;mother:TObject);
procedure deleteRecordDialog(arg,ENV:TStringList;mother:TObject);
procedure deleteFile(afile:string;ENV:TStringList;mother:TObject);
procedure deleteRecord(afile,astamp,aid:string;arg,ENV:TStringList;mother:TObject);
procedure deleteDialog(arg,ENV:TStringList;mother:TObject);
procedure checkSign(arg,ENV:TStringList;mother:TObject);
procedure newElementForm(afile,achecked,adopost:string;ENV:TStringList;mother:TObject);


implementation


uses
  util_pm, CacheStat_pm, config,Cache_pm, message_pm,Signature_pm,httpd_pl,main;


//------------------------------------------------------
//
function str_decode(a:string):string;
var
  r:TRegularExp;
begin
  r := TRegularExp.Create;
  try
    Result := r.func001(a);  // s/%([A-Fa-f0-9][A-Fa-f0-9])/pack("C", hex($1))/eg
  finally
    r.free;
  end;
end;

//------------------------------------------------------
//
function str_encode(a:string):string;
var
  s:string; r:TRegularExp; n:integer; v: char;
begin

  r := TRegularExp.Create;
  try
    Result := '';
  //s := r.RegReplace(a,'[^\w]','''%''');  //0.4-beta
    s := a;
    for n := 1 to length(s) do begin
      v := s[n];
      if ('a' <= v) and (v <= 'z') then
      //Result := Result + UpperCase(v)
        Result := Result + v              //未完成
      else
        Result := Result + '%' + format('%0.2X',[Integer(v)]);
    end;


  finally
    r.free;
  end;
end;


//------------------------------------------------------
//
function file_encode(atype,aname:string):string;
var
  n,v:integer; s:string;
begin
  Result := '';
  s := '';
  for n := 1 to length(aname) do begin
    v := Integer(aname[n]);
  //s := s + format('%0.2X',[v]);
    s := s + format('%X',[v]);
  end;
  Result := atype + '_' + s;
end;



//------------------------------------------------------
//
function file_decode(aname:string):string;
var
  buf:string; ret:TStringList; r:TRegularExp;
begin
  Result := '';
  ret := TStringList.Create;
  r := TRegularExp.Create;
  try
    split(aname, '_', 2,ret);
    aname := ret.Strings[1];
    aname := r.func002(aname); // s/([A-Fa-f0-9][A-Fa-f0-9])/pack("C", hex($&))
    Result := gateway_pm.escape(aname);
  finally
    r.free;
    ret.free;
  end;
end;


//----------------------------------------------------------------------
// rec()
//
// util_pm.rec()をココでフックする （拡張その他用）
//
function rec(recdata:string;arec,ENV:TStringList):TStringList;
begin
  Result := util_pm.rec(recdata,arec,ENV);
end;


//----------------------------------------------------------------------
// xdie()
//
// 何らかの理由からの終了前のメッセージをソケットに出力する.
// この後は、呼び出し側は処理を終了することを想定している.
//
procedure xdie(mes:string;ENV:TStringList; mother:Tobject);
var
  buf,addtype:string;
begin
  if ENV.Values['HTTP_ACCEPT_LANGUAGE'] = D_JAPANESE_ID then
    addtype := 'charset=UTF-8'
  else
    addtype := '';

  buf := TServerThrd(mother).printHeader('200 OK', False);
  buf := buf
       + 'Content-Type: text/plain;' + addtype + CRLF     //  注意：charset=UTF-8を追加
       + 'X-Shingetsu: ' + ENV.Values['SERVER_SOFTWARE'] + CRLF
       + CRLF
       + mes + LF;
  TServerThrd(mother).SendData(buf);
end;


//----------------------------------------------------------------------
//
function escape(s:string):string;
var
  r:TRegularExp;
begin
  r := TRegularExp.Create;
  try
    s := r.RegReplace(s,'&','&amp;');

    //s := r.RegReplace(s,'&amp;(#\d+|#[Xx][0-9A-Fa-f]+|[A-Za-z0-9]+);','&$1;',True);
    //&amp;(#\d+|#[Xx][0-9A-Fa-f]+|[A-Za-z0-9]+);
    s := r.func004(s);

    s := r.RegReplace(s,'<','&lt;');
    s := r.RegReplace(s,'>','&gt;');
    s := r.RegReplace(s,#13,'');        //(s,'\r','')
    s := r.RegReplace(s,#10,'<br>');    //(s,'\n','<br>')
    Result := s;
  finally
    r.free;
  end;
end;


//----------------------------------------------------------------------
// unescape arguments
//
procedure args(ainput:string; arg:TStringList);
var
  tmp,s_:string; n:integer;
  ret,buf:TStringList; r:TRegularExp;
begin
  ret := TStringList.create;
  buf := TStringList.create;
  r := TRegularExp.Create;
  try
    arg.clear;
    split(ainput,'&', ret);
    n := 0;
    while ( n < ret.count ) do begin
      tmp := ret.Strings[n];
      split(tmp,'=',buf);
      if buf.count > 1 then begin
        tmp := buf.Strings[1];
        tmp := r.RegReplace(tmp,'\+', ' ', True);
        tmp := r.func001(tmp);  // s/%([A-Fa-f0-9][A-Fa-f0-9])/pack("C", hex($1))/eg
        arg.Values[buf.Strings[0]] := escape(tmp);
      end else begin
        arg.Values[buf.Strings[0]] := '';
      end;
      inc(n);
    end;
  finally
    r.free;
    buf.free;
    ret.free;
  end;
end;


//----------------------------------------------------------------------
// unescape arguments(multipart/form-data)
//
procedure argsFromMulti(ainput:string; arg:TStringList);
var
  r:TRegularExp; tmp,boundary:string; _input,buf:TStringList;
  m:integer; key,s:String;
begin
  arg.clear;
  r := TRegularExp.Create;
  _input := TStringList.Create;
  buf := TStringList.Create;
  try
    r.RegCompCut(ainput,'([^\s]+)',False);   // $input =~ /\s/  LIBが$`を未サポート？
    boundary := r.grps('$1');
    split(ainput, boundary,_input);
    shift(_input);          //先頭の不要な項目を削除（先頭のboundaryで空の項目ができる）
    m := 0;
    while (m < _input.count) do begin
      tmp := _input.Strings[m];
      split(tmp, CRLF,buf);
      if (buf.count > 1) then begin
        shift(buf);        //先頭の不要な項目を削除（先頭のCRLFで空の項目ができる）
        s := buf.strings[0];
        if r.RegCompCut(s,'Content-Disposition: form-data; name="([^"]+)"',True) then begin
          key := r.grps('$1');
          if r.RegCompCut(s,'filename="([^"]+)"',True) then begin
            arg.values['auto_suffix'] := r.grps('$1');
            arg.values['auto_suffix'] := r.RegReplace(arg.values['auto_suffix'],'.*[\/\\]', '', True);
            if r.RegCompCut(arg.values['auto_suffix'],'\.([^.]*)$',True) then begin
              arg.values['auto_suffix'] := r.grps('$1');
              arg.values['auto_suffix'] := lowercase(r.grps('$1'));
            end else begin
              arg.values['auto_suffix'] := '';
            end;
          end;
          repeat
            tmp := shift(buf);
          until (not defined(tmp));
          s := join(CRLF,buf);
          arg.values[key] := s;
          if (key <> 'attach') then
            arg.values[key] := escape(arg.values[key]);
        end;       // end of if r.RegCompCut(s,'Content-Disposition:
      end;       // end of if (buf.count > 1) then begin
      inc(m);
    end;     // end of while (m < _input.count) do begin
  finally
    buf.free;
    _input.free;
    r.free;
  end;
end;


//------------------------------------------------------
// date
//
function xlocaltime(v:Extended):string;
var
  dd:TDateTime; i:integer;
begin
  i := StrToInt(FloatToStr(v));
//dd := Time2DT(v);
  dd := Time_TtoDateTime(TTime_t(i));
  Result := FormatDateTime('yyyy/mm/dd hh:nn',dd);
end;


//-------------------------------
// touch
//
procedure touch(afile:string;ENV:TStringList);
var
  stat:TStringList; SIN: TextFile;
  fname,anode:string;
begin
  stat := TStringList.Create;
  try
    CacheStat_pm.list(stat);
    fname := DataPath(afile);
    if not FileExists(fname) then begin
      //表示するファイルが存在しない場合、
      //空のファイルを作成する(ファイル名を決定する)
      Util_pm.Lock();
      AssignFile(SIN,fname);
      try
        Rewrite(SIN);
        write(SIN,'');
        CloseFile(SIN);    //0サイズファイル作成
      except
        ;
      end;
      Util_pm.Unlock();
      CacheStat_pm.list(stat);
      stat.values[__stamp(afile)]   := '0';
      stat.values[__records(afile)] := '0';
      stat.values[__size(afile)]    := '0';
      CacheStat_pm.stat_sync(stat);
    end;
    if (_GetFileSize(fname) = 0) then begin
      //サイズが０だったら、他のノードに要求する
      //注意：サイズが-1はエラーなので何もしないこととなる。
      anode := Cache_pm.search(afile,ENV);
      if defined(anode) then begin
        Cache_pm.getRegion(afile,anode,ENV);
      end;
    end;
  finally
    stat.free;
  end;
end;

//------------------------
// read note history
//
procedure readNote(afile:string; var buf, orphan:string;ENV:TStringList);
var
  s_,tmp:string; ref,rec:TStringList; SIN:TextFile; m,i:integer;
begin
  ref := TStringList.Create;
  rec := TStringList.Create;
  try
    AssignFile(SIN, DataPath(afile));
    try
      Reset(SIN);
      ref.clear;
      while not Eof(SIN) do begin
        Readln2(SIN,s_);
        chomp(s_);
        util_pm.rec(s_,rec,ENV);
        if not ((rec.count <= 2) or (defined(rec.Values['remove_stamp']))) then begin
          buf := s_;

          if defined(rec.Values['base_stamp']) then
            ref.values[ rec.values['stamp'] + '_' + rec.values['id'] ] := '0';

          if( defined(rec.values['base_stamp']) and
              (defined(ref.values[rec.values['base_stamp']+'_'+rec.values['base_id']]))) then begin

            tmp :=  rec.values['base_stamp'] + '_' + rec.values['base_id'];
            i := StrToIntDef(ref.values[tmp],0);
            inc(i);
            ref.values[tmp] := IntToStr(i);

          end;
        end;
      end;
      CloseFile(SIN);

      //ノートの衝突検知？？
      i := 0;
      m := 0;
      while (m < ref.Count) do begin
        if ref.Strings[m] = '0' then
          inc(i);
        inc(m);
      end;
      orphan := intToStr(i);
      if orphan = '1' then  orphan := '0';  //
      if orphan = '0' then  orphan := '';   //注意：苦しいロジック
    except
       //
    end;
  finally
    rec.free;
    ref.free;
  end;
end;


//--------------------------------------------
// add record
//
function addRecord(afile,astamp,abody:string):string;
var
  id,fname,s:string; AOUT:TextFile; stat:TStringList; i:integer;
begin
  Result := '';
  stat := TStringList.Create;
  try
    //MD5で識別子(ID)を作成
    id := Signature_pm.md5digest(abody);
    //レコードを追加する stamp<>id<>body
    Util_pm.lock();
    try
      fname := DataPath(afile);
      AssignFile(AOUT, fname);
      Append(AOUT);
      s := astamp + '<>' + id + '<>' + abody;
      Writeln(AOUT, s);
      closeFile(AOUT);
    finally
      Util_pm.unlock();
    end;
    //stat.txtを読み込む finame<>stamp<>records<>size
    CacheStat_pm.list(stat);
    //stampをリストへ
    stat.Values[__stamp(afile)]   := astamp;
    //recordsをリストへ
    s := stat.Values[__records(afile)];
    i := StrToIntDef(s,0) + 1;
    stat.Values[__records(afile)] := IntToStr(i);
    //sizeをリストへ
    stat.Values[__size(afile)]    := IntToStr((_GetFileSize(fname) div 1024) div 1024);
    CacheStat_pm.stat_sync(stat);
    Result := id;
  finally
    stat.free;
  end;
end;

//---------------------------------
//
// post
//
function post(athread:string; arg:TStringList; ENV:TStringList; mother:TObject):string;
var
  r:TRegularExp; suffix,attach,stamp,tmp:string;
  body,target,pubkey,sign,id:string; len:integer;

  procedure func1(s_:string);
  begin
    if defined(arg.Values[s_]) then begin
      body   := body   + '<>' + s_ + ':' + arg.values[s_];
      target := target + ','  + s_;
    end;
  end;

begin
  r := TRegularExp.Create;
  try
    suffix := '';
    attach := '';
    if not defined(arg.values['name']) then arg.values['name'] := '';
    if not defined(arg.values['mail']) then arg.values['mail'] := '';
    if not defined(arg.values['passwd']) then arg.values['passwd'] := '';

    tmp := arg.values['attach'];
    if defined(tmp)  then begin
      len := length(tmp);
      if (len > (D_FILELIMIT * 1024 * 1024) ) then begin
	xdie(amessage('big_file',ENV),ENV,mother);
        exit;
      end;
      attach := Signature_pm.base64encode(arg.values['attach']);
      if (arg.values['suffix'] <> 'AUTO') then
        suffix := arg.values['suffix']
      else if defined(arg.Values['auto_suffix']) then
	suffix	:= arg.values['auto_suffix']
      else
	suffix := 'txt';
    end;

    if defined(arg.values['error']) then           //
      stamp := FloatToStr(util_pm.localtime())     //  未完成：自信なし
    else                                           //
      stamp := FloatToStr(sys_time());             //

    body   := '';
    target := '';
    arg.values['suffix'] := suffix;
    arg.values['attach'] := attach;
    func1('base_stamp');
    func1('base_id');
    func1('name');
    func1('mail');
    func1('body');
    func1('suffix');
    func1('attach');
    body := r.RegReplace(body,'^<>','');
    target := r.RegReplace(target,'^,','');
    if not defined(body) then begin
      xdie(amessage('null_article',ENV),ENV,mother);
      exit;
    end;
    if defined(arg.values['passwd']) then begin
      Signature_pm.generate(arg.values['passwd'],body,pubkey,sign);
      body := 'pubkey:'+pubkey+'<>sign:'+sign+'<>target:'+target+'<>'+ body;
    end;
    id := addRecord(athread, stamp, body);
    if defined(arg.values['dopost']) then begin
      Util_pm.addUpdate(stamp, id, athread);
      Cache_pm.tellupdate(athread, stamp, id, '',ENV);
    end;
    Result := copy(id,1,8);
  finally
    r.free;
  end;
end;

//---------------------------------------------------------------------
// make new list element
//
function newElement(afile:string;arg:TStringList; ENV:TStringList; mother:TObject):boolean;
var
  r:TRegularExp; body,id:string; stamp:Extended;
begin
  Result := False;
  r := TRegularExp.Create;
  try
    stamp := util_pm.localtime();
    if not defined(arg.values['name']) then begin
      xdie(amessage('null_name',ENV),ENV,mother);
      exit;
    end;
  //if r.RegCompCut(arg.values['name'],'[/#]',True) then begin
  //m/\/|\]\]/
  //if r.RegCompCut(arg.values['name'],'/',True) then begin         // 0.3.4へ変更
    if r.RegCompCut(arg.values['name'],'\/|\]\]',True) then begin   // 0.4-betaへ変更
      xdie(amessage('bad_name',ENV),ENV,mother);
      exit;
    end;
    if r.RegCompCut(arg.values['name'],'\]\]',True) then begin
      xdie(amessage('bad_name',ENV),ENV,mother);
      exit;
    end;
    if not defined(arg.values['type']) then begin
      xdie(amessage('null_type',ENV),ENV,mother);
      exit;
    end;
    body := 'type:' + arg.values['type'] + '<>link:' + arg.values['name'];
    id := gateway_pm.addRecord(afile,FloatToStr(stamp),body);
    if defined(arg.Values['dopost']) then begin
      util_pm.addUpdate(FloatToStr(stamp),id,afile);
      Cache_pm.tellupdate(afile,FloatToStr(stamp),id,'',ENV);
    end;
    Result := True;
  finally
    r.free;
  end;
end;


//---------------------------------------------------------------------
//
// add new record and marge that and last record (for note)
//
function margeRecord(afile:string;arg:TStringList; ENV:TStringList; mother:TObject):Boolean;
var
  rec:TStringList; astamp,base_stamp,base_id,s_,buf,conflict:string;
  r:TRegularExp; body,id:string;
begin
//Result := '';
  Result := False;
  rec := TStringList.Create;
  r := TRegularExp.Create;
  try
    astamp := FloatToStr(util_pm.localtime());
    body := arg.Values['message'];
    base_stamp := '';
    base_id    := '';
    gateway_pm.readNote(afile,buf,conflict,ENV);
    if defined(buf) then begin
      gateway_pm.rec(buf,rec,ENV);
      if (rec.values['body'] <> '') then begin
        if (r.RegCompCut(rec.Values['body'],'<br>$',False)) then begin
          body := rec.Values['body']+'<br>'+body;
        end else begin
          body := rec.Values['body']+'<br><br>'+body;
        end;
      end;
      base_stamp := rec.Values['stamp'];
      base_id    := rec.Values['id'];
    end;
    if body = '' then begin
      xdie(amessage('null_article',ENV),ENV,mother);
      exit;
    end;
    body := 'body:' + body;
    if defined(base_stamp) then
      body := body + '<>base_stamp:'+ base_stamp + '<>base_id:' + base_id;
    id := addRecord(afile, astamp, body);
    if defined(arg.values['dopost']) then begin
      Util_pm.addUpdate(astamp, id, afile);
      Cache_pm.tellupdate(afile, astamp, id, '', ENV);
    end;
 // Result :=  copy(id, 1, 8);
    Result :=  True;
  finally
    rec.free;
    r.free;
  end;
end;


//---------------------------------------------------------------------
// post delete message to other nodes
//
procedure postDeleteMessage(afile, astamp, aid:string; arg,ENV:TStringList; mother:TObject);
var
  newstamp:extended; body,target,newid:string; r:TRegularExp;
  pubkey,sign:string;
begin
  r := TRegularExp.Create;
  try
    if not defined(arg.values['name']) then arg.values['name'] := '';
    if not defined(arg.values['mail']) then arg.values['mail'] := '';
    if not defined(arg.values['passwd']) then arg.values['passwd'] := '';
    newstamp := Util_pm.localtime();
    body := '';
    target := '';
    if defined(arg.values['name']) then begin
      body   := body   + '<>name:'+arg.values['name'];
      target := target + ',name';
    end;
    if defined(arg.values['message']) then begin
      body   := body   + '<>body:'+arg.values['message'];
      target := target + ',body';
    end;
    body   := body   + '<>remove_stamp:' +  astamp;
    target := target + ',remove_stamp';
    body   := body   + '<>remove_id:' +  aid;
    target := target + ',remove_id';
    body := r.RegReplace(body,'^<>','');
    target := r.RegReplace(target,'^,','');
    if not defined(body) then begin
      xdie(amessage('nullarticle',ENV),ENV,mother);
      exit;
    end;
    if defined(arg.Values['passwd']) then begin
      Signature_pm.generate(arg.Values['passwd'],body,pubkey,sign);
      body := 'pubkey:'+pubkey+'<>sign:'+sign+'<>target:'+target+'+<>'+body;
    end;
    newid := addRecord(afile,FloatToStr(newstamp),body);
    Util_pm.addUpdate(FloatToStr(newstamp),newid,afile);
    Cache_pm.tellupdate(afile,FloatToStr(newstamp),newid, '',ENV);
  finally
    r.free;
  end;
end;


//----------------------------------------------------------------------
// encode bracket string to link          LINK関連の重要関数
//
function bracket_link(ss:string):string;
var
  link,s1,s2,s3:string; r:TRegularExp;
begin
  Result := '';
  link := ss;
  r := TRegularExp.Create;
  try
  //if r.RegCompCut(link,'^/(list|thread|note)/([^/]+)/([0-9a-f]{8})$',False) then begin
    if r.RegCompCut(link,'^/(thread)/([^/]+)/([0-9a-f]{8})$',False) then begin //0.4.1
      s1 := r.grps('$1');
      s2 := r.grps('$2');
      s3 := r.grps('$3');
      link := D_ROOT + s1 + '.cgi/' + str_encode(s2) + '#r' + s3;
      Result := '<a href=''' + link + '''>[[' + ss + ']]</a>';

    end else if r.RegCompCut(link,'^/(list|thread|note)/([^/]+)$',False) then begin
      s1 := r.grps('$1');
      s2 := r.grps('$2');
      link := D_ROOT + s1 + '.cgi/' + str_encode(s2);
      Result := '<a href=''' + link + '''>[[' + ss + ']]</a>';

    end else if r.RegCompCut(link,'^([^/]+)/([0-9a-f]{8})$',False) then begin
      s1 := r.grps('$1');
      s2 := r.grps('$2');
      link := str_encode(s1) + '#r' + s2;
      Result := '<a href='''+ link + '''>[[' + ss + ']]</a>';

    end else if r.RegCompCut(link,'^([^/]+)$',False) then begin
      s1 := r.grps('$1');
      link := str_encode(s1);
      Result := '<a href=''' + link + '''>[[' + ss + ']]</a>';

    end else begin
      Result := '[[' + ss + ']]';
    end

  finally
    r.free;
  end;
end;


//--------------------------------------------------------
// check admin address
//
function CheckAdmin(ENV:TStringList;mother:TObject):Boolean;
var
  s:string;
begin
  s := ENV.Values['REMOTE_ADDR'];
  if copy(s,1,length(D_LOCALIP)) = D_LOCALIP then begin
    Result := True;
    exit;
  end;
//NodeList_pm.myself(ENV);
//if (mSERVER_ADDR <> '') and ( mSERVER_ADDR <> s) or then begin
  if copy(s,1,length(D_ADMINADDR)) <> D_ADMINADDR then begin
    Print403(ENV,mother);
    Result := False;
  end else begin
    Result := True;
  end;

end;


//--------------------------------------------------------
// print header
//
// タイトルはヘッダとボディを途中まで送る汎用ルーチンである
// 理由から、Content-Length はセットしていない
//
//
procedure printHeader(title:string;ENV:TStringList;mother:TObject);
var
  ans,head,body:string;
begin
  head := TServerThrd(mother).printHeader('200 OK', False)
       + 'Content-Type: text/html; charset=UTF-8' + CRLF
       + 'Content-Language: ' + amessage('lang', ENV) + CRLF
       + 'X-Shingetsu: ' + ENV.Values['SERVER_SOFTWARE']+ CRLF
       + CRLF;
  if not TServerThrd(mother).SendData(head) then exit;

  body := '<?xml version="1.0" encoding="UTF-8"?>'
        + '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"'
        + ' "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">'
        + '<html xmlns=''http://www.w3.org/1999/xhtml'' xml:lang=''' + amessage('lang',ENV)+'''>'
        + '<head>'
        + '<meta http-equiv=''Content-Language'' content=''' + amessage('lang',ENV)+''' />'
        + '<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />'
    //  + '<meta http-equiv=''Content-Style-Type'' content=''text/css'' />'
        + '<title>' + title + '</title>'
        + '<link rev=''made'' href=''mailto:fuktommy@users.sourceforge.net'' />'
        + '<link rel=''contents'' href=''' + D_ROOT + 'list.cgi'' />'
        + '<link rel=''stylesheet'' type=''text/css'' href=''' + D_CSS + ''' />'
   //   + '<link rel=''shortcut icon'' href=''/favicon.ico'' />'
        + '</head>';
  if not TServerThrd(mother).SendData(body) then exit;

  body := '<body><p class=''head''>'   //0.3.4
        + '<a href=''' + D_ROOT + 'gateway.cgi''>'         + amessage('top',ENV)     + '</a> | '
        + '<a href=''' + D_ROOT + 'list.cgi''>'            + amessage('menu',ENV)    + '</a> | '
        + '<a href=''' + D_ROOT + 'gateway.cgi/new''>'     + amessage('new',ENV)     + '</a> | '
        + '<a href=''' + D_ROOT + 'gateway.cgi/index''>'   + amessage('index',ENV)   + '</a> | '
        + '<a href=''' + D_ROOT + 'gateway.cgi/changes''>' + amessage('changes',ENV) + '</a> | '
        + '<a href=''' + D_ROOT + 'gateway.cgi/update''>'  + amessage('update',ENV)  + '</a> | '
        + '<a href=''' + D_ROOT + 'gateway.cgi/search''>'  + amessage('search',ENV)  + '</a>'
        + '</p>'
        + '<h1><a href=''' + D_ROOT + 'gateway.cgi/search/' + str_encode(title)
        + ''' class=''title'' title=''' + amessage('search',ENV) + '''>' + title + '</a></h1>';

  if not TServerThrd(mother).SendData(body) then exit;

end;


//----------------------------------------------------
// print 403 status
//
procedure print403(ENV:TStringList;mother:TObject);
var
  res:string;
begin
  printHeader(amessage('403',ENV),ENV,mother);
  res := '</body></html>' + LF;
  if not TServerThrd(mother).SendData(res) then exit;
end;


//----------------------------------------------------
// print 404 status
//
procedure print404(fname:string;ENV:TStringList;mother:TObject);
var
  res:string;
begin
  printHeader(amessage('404',ENV),ENV,mother);
  res := '<p>' + amessage('try_later',ENV) + '</p>';
  if defined(fname) then begin
    res := '<form method=''get'' action=''' + D_ROOT + ENV.Values['SCRIPT_NAME']
         + '/delete?file=''' + fname + '''>'
	 + '<p><input type=''submit'' value='''
         + amessage('del_file',ENV) + ''' tabindex=''1'' accesskey=''d'' /></p></form>'
	 + '</body></html>' + LF;
    if not TServerThrd(mother).SendData(res) then exit;
  end;
end;


//-----------------------------------------------------
// print 302
//
procedure print302(anext:string;ENV:TStringList;mother:TObject);
var
  atitle,buf,script:string;
begin
  script := ENV.Values['SCRIPT_NAME'];
  atitle := anext;
  buf := TServerThrd(mother).printHeader('200 OK', False);
  buf := buf + 'Content-Type: text/html; charset=UTF-8' + CRLF
    // + 'Content-Language: ' + ENV.Values['HTTP_ACCEPT_LANGUAGE'] + CRLF
       + 'Content-Language: en' + CRLF
       + 'X-Shingetsu: ' + ENV.Values['SERVER_SOFTWARE'] + CRLF
       + CRLF

       + '<?xml version="1.0" encoding="UTF-8"?>'
       + '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"'
       + ' "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">'
       + '<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">'

       + '<head>'
       + '<meta http-equiv="Content-Language" content="en" />'
       + '<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />'
       + '<meta http-equiv="Content-Script-Type" content="text/javascript" />'
       + '<title>moved</title>'
       + '<link rev=''made'' href=''mailto:fuktommy\@users.sourceforge.net'' />'
       + '<link rel=''contents'' href=''' + D_ROOT + script +'/list'' />'
       + '</head>'
       + '<body><p>Click and jump to <a href=''' + anext + '''>' + anext + '</a></p>' + LF

       + '<script type=''text/javascript''>window.location.href = ''' + anext + ''';</script>'
       + '</body></html>' + LF;
  if not TServerThrd(mother).SendData(buf) then exit;
end;


//------------------------------------------------
// HTML Format     LINK関連の重要関数
//
function html_format(data:string;ENV:TStringList):string;
var
  s_,tmp,v,ans:string; r:TRegularExp;
begin
  Result := data;
  if not defined(Result) then
   exit;
  r := TRegularExp.Create;
  try
    s_ := data;
    s_ := r.RegReplace(s_,'<br>','<br />');
    s_ := r.RegReplace(s_,'(&gt;&gt;)([0-9A-Za-z]+)','<a href=''#r$2''>$&</a>',True);
    s_ := r.RegReplace(s_,'https?://[\.\:\&\+\|\-\?\/\%0-9A-Za-z]{2,}','<a href=''$&''>$&</a>',true);
    s_ := r.RegReplace(s_,'\[\[<a.*?>(.*?)\]\]</a>','[[$1]]',True);
    s_ := r.func003(s_);    // s|\[\[([^<>]+?)\]\]|bracket_link($1)|eg;   // 0.3.4
    if D_REDIRECT then
      s_ := r.RegReplace(s_,'<a href=''http://shingetsu\.p2p/','<a href=''/');
    Result := s_;
  finally
    r.free;
  end;
end;



//-------------------------------------------------
// read Query
//
function readQuery(var apath, ainput:string;ENV:TStringList):boolean;
var
  r :TRegularExp;
begin
  Result := False;
  r := TRegularExp.Create;
  try
    //path
    if not r.RegCompCut(ENV.Values['REMOTE_ADDR'], D_FRIENDADDR,False) then begin
      exit;
    end else if defined(ENV.Values['PATH_INFO']) then begin
    //apath := r.RegReplace(ENV.Values['PATH_INFO'],'^/+','');
      apath := r.RegReplace(ENV.Values['PATH_INFO'],'^/','');  // 0.4-beta1
    end else begin
      apath := '';
    end;
    //input
    if (ENV.Values['REQUEST_METHOD'] = 'POST') then begin
      ainput := ENV.Values['POST_STRING'];
    end else begin
      ainput := ENV.Values['QUERY_STRING'];
    end;
    Result := True;
  finally
    r.free;
  end;
end;

//-----------------------------------------------
// delete Record dialog
//
procedure deleteRecordForm(arg,aarg,ENV:TStringList;mother:TObject);
var
  afile,abuf,astamp,aid,ans:string; r:TRegularExp;
begin
  afile  := arg.Strings[0];
  abuf   := arg.Strings[1];
  astamp := arg.Strings[2];
  aid    := arg.Strings[3];
  r := TRegularExp.Create;
  try
    abuf := r.RegReplace(abuf,'<','&lt;',True);
    abuf := r.RegReplace(abuf,'>','&gt;',True);
    ans  := '<p>'+amessage('del_record_q',ENV)+'</p>'
	  + '<form method=''post'' action=''' + D_ROOT + ENV.Values['SCRIPT_NAME'] +'''><p>'
          + '<input type=''hidden'' value=''xdelete'' name=''cmd'' />'
	  + '<input type=''hidden'' value=''' + afile + ''' name=''file'' />'
	  + '<input type=''hidden'' value=''' + astamp +''' name=''stamp'' />'
	  + '<input type=''hidden'' value=''' + aid + ''' name=''id'' />'
	  + '<input type=''submit'' value=''' + amessage('yes',ENV) + ''' name=''submit'' tabindex=''1'' accesskey=''w'' />'
	  + '<input type=''checkbox'' value=''dopost'' name=''dopost'' tabindex=''2'' accesskey=''s'' />'
	  + amessage('send',ENV)
	  + ' <input type=''checkbox'' value=''error'' name=''error'''
	  + ' checked=''checked'' tabindex=''2'' accesskey=''e'' />'
	  + ' ' + amessage('error',ENV) +'<br />'
	  + ' ' + amessage('name',ENV) + ':<input name=''name'' size=''15'' value='''' tabindex=''3'' accesskey=''n'' />'
	  + ' ' + amessage('signature',ENV) + ':<input type=''password'' name=''passwd'' size=''15'' value='''' tabindex=''4'' accesskey=''p'' />'
	  + ' ' + amessage('comment',ENV) + ':<input name=''message'' size=''15'' value='''' tabindex=''5'' accesskey=''m'' />'
	  + '<input type=''hidden'' name=''mode'' value='''+ aarg.Values['mode']+ ''' />'
	  + '</p></form>'+LF
	  + '<p>'+ abuf + '</p>';
    if not TServerThrd(mother).SendData(ans) then exit;
  finally
    r.free;
  end;
end;


//-----------------------------------------------
// delete File form
//
procedure deleteFileForm(afile:string;buf,ENV:TStringList;mother:TObject);
var
  ans:string; r:TRegularExp; m:integer;
begin
  r := TRegularExp.Create;
  try
    ans := '<p>' + amessage('del_file_q',ENV) + ' '
         + '<a href=''' + D_ROOT + ENV.Values['SCRIPT_NAME'] + '?cmd=xdelete&amp;file=' + afile + '''>'
         + amessage('yes',ENV) + '</a></p>'+LF;
    if not TServerThrd(mother).SendData(ans) then exit;

    if (r.RegCompCut(afile,'_',False)) then begin
      ans := '<p>' + file_decode(afile) + amessage(r.grps('$`'),ENV)+ '</p>'+LF;
      if not TServerThrd(mother).SendData(ans) then exit;
    end;
    m := 0;
    while ( m < buf.count ) do begin
      ans := buf.Strings[m];
      chomp(ans);
      ans := r.RegReplace(ans,'<','&lt;',True);
      ans := r.RegReplace(ans,'>','&gt;',True);
      ans := '<p>' + ans +'</p>' + LF;
      if not TServerThrd(mother).SendData(ans) then exit;
      inc(m);
    end;
  finally
    r.free;
  end;
end;


//-----------------------------------------------
// delete record dialog
//
procedure deleteRecordDialog(arg,ENV:TStringList;mother:TObject);
var
  ans,afile,astamp,aid,tmp,sss,buf:string; ret,inp:TStringList;
  SIN:TextFile;
begin
  ret := TStringList.Create;
  inp := TStringList.Create;
  try
    afile := arg.values['file'];
    printHeader(amessage('del_record',ENV),ENV,mother);
    if not TServerThrd(mother).SendData(LF) then exit;
    split(arg.values['record'],'/',ret);
    astamp := ret.Strings[0];
    aid    := ret.Strings[1];
    if FileExists(DataPath(afile)) then begin
      AssignFile(SIN, DataPath(afile));
      try
        Reset(SIN);
        buf := '';
        sss := astamp + '<>' + aid + '<>';
        while not Eof(SIN) do begin
          Readln2(SIN,tmp);
          if (copy(tmp,1,length(sss)) = sss) then begin
            buf := tmp;
            break;
          end;
        end;
        CloseFile(SIN);
      except
        //
      end;
      if not defined(buf) then begin
        ans := '<p>'+amessage('no_record',ENV)+'</p></body></html>'+LF;
        if not TServerThrd(mother).SendData(ans) then exit;
      end else begin
        inp.add(afile);
        inp.add(buf);
        inp.add(astamp);
        inp.add(aid);
        gateway_pm.deleteRecordForm(inp,arg,ENV,mother);
        ans := '</body></html>'+LF;
        if not TServerThrd(mother).SendData(ans) then exit;
      end;
    end else begin
      ans := '<p>'+afile + ': '+amessage('no_file',ENV)+'</p></body></html>'+LF;
      if not TServerThrd(mother).SendData(ans) then exit;
    end;
  finally
    inp.free;
    ret.free;
  end;
end;


//-----------------------------------------------
// delete File dialog
//
procedure deleteFileDialog(arg,ENV:TStringList;mother:TObject);
var
  afile,tmp:string; buf:TStringList; SIN:TextFile;
begin
  buf := TStringList.Create;
  try
    afile := arg.values['file'];
    printHeader(amessage('del_file',ENV),ENV,mother);
    if not TServerThrd(mother).SendData(LF) then exit;
    if FileExists(DataPath(afile)) then begin
      AssignFile(SIN, DataPath(afile));
      try
        Reset(SIN);
        buf.clear;
        while not Eof(SIN) do begin
          Readln2(SIN,tmp);
          buf.add(tmp);
          break;
        end;
        CloseFile(SIN);
      except
        //
      end;
      deleteFileForm(afile,buf,ENV,mother);
      if not TServerThrd(mother).SendData('</body></html>'+LF) then exit;

    end else begin
      if not TServerThrd(mother).SendData('<p>'+ 'BB' + afile + ': '+amessage('no_file',ENV)+'</p></body></html>'+LF ) then exit;
    end;
  finally
    buf.free;
  end;
end;



//-----------------------------------------------
// delete File
//
procedure deleteFile(afile:string;ENV:TStringList;mother:TObject);
var
  ans:string; stat:TStringList;
begin
  stat := TStringList.Create;
  try
    if SysUtils.deleteFile(DataPath(afile)) then begin
      CacheStat_pm.list(stat);
      dellist(stat,afile);
      CacheStat_pm.stat_sync(stat);
      print302( D_ROOT + ENV.Values['SCRIPT_NAME'],ENV,mother);
    end else begin
      ans := 'Content-Type: text/plain' + CRLF
           + CRLF
           + 'failed !'+ LF;
      if not TServerThrd(mother).SendData(ans) then exit;
    end;
  finally
    stat.free;
  end;
end;


//-----------------------------------------------
// delete record
//
procedure deleteRecord(afile,astamp,aid:string;arg,ENV:TStringList;mother:TObject);
var
  ans,xfile:string;
begin
  try
    if (not Cache_pm.removeRecord(afile,astamp,aid)) then begin
      ans := 'Content-Type: text/plain'+CRLF+CRLF
           + 'failed !'+LF;
      if not TServerThrd(mother).SendData(ans) then exit;
    end else if defined(arg.Values['dopost']) then begin
      postDeleteMessage(afile,astamp,aid,arg,ENV,mother);
    end;
    if defined(arg.Values['mode']) then begin
      xfile := str_encode(file_decode(afile));
      print302(D_ROOT+ENV.Values['SCRIPT_NAME']+'/'+xfile,ENV,mother);
    end;
  finally
    //
  end;
end;


//-----------------------------------------------
// delete note dialog
//
procedure deleteDialog(arg,ENV:TStringList;mother:TObject);
begin
  try
    if not defined(arg.values['file']) then begin
      Print404(arg.values['file'],ENV,mother);
      exit;
    end else if defined(arg.values['record']) then begin
      gateway_pm.deleteRecordDialog(arg,ENV,mother);
    end else begin
      gateway_pm.deleteFileDialog(arg,ENV,mother);
    end;
  finally
    //
  end;
end;

//-----------------------------------------------
//
procedure checkSign(arg,ENV:TStringList;mother:TObject);
var
  afile,astamp,aid,s_,value,fname,ans:string; SIN:TextFile; recs,ret:TStringList;
  r:TRegularExp; trip,atype,afilename:string;
begin
  if not (defined(arg.values['file']) and defined(arg.values['stamp'])
            and defined(arg.values['id'])) then begin
    Print404('',ENV,mother);
    exit;
  end;

  recs := TStringList.Create;
  ret := TStringList.Create;
  r := TRegularExp.Create;
  try
    afile := arg.values['file'];
    gateway_pm.touch(afile,ENV);
    fname := DataPath(afile);
    if FileExists(fname) then begin
      AssignFile(SIN,fname);
      Reset(SIN);
      readln(SIN,s_);  //1レコード目を読み込む
      CloseFile(SIN);

      util_pm.rec(s_,recs,ENV);

      if (not (defined(recs.Values['pubkey'])
           and defined(recs.Values['sign']) and defined(recs.values['target']))) then begin
        ans := 'Content-Type: text/plain; charset=UTF-8'+CRLF
             + 'X-Shingetsu: ' + ENV.Values['SERVER_SOFTWARE'] + CRLF
             + CRLF
             + amessage('not_signed',ENV)+LF
             + s_ + LF;
        if not TServerThrd(mother).SendData(ans) then exit;

      end else if Signature_pm.check(recs) then begin

        s_ := r.RegReplace(s_,'<','&lt;');
        s_ := r.RegReplace(s_,'>','&gt;');

        trip := Signature_pm.pubkey2trip(recs.values['pubkey']);
        split(afile,'_',2,ret);
        if (ret.Count = 2) then begin
          atype := ret.Strings[0];
          afilename := ret.Strings[1];
        end else begin
          atype := '';
          afilename := '';
        end;

        gateway_pm.printHeader(amessage('check_sign',ENV),ENV,mother);
        ans := '<p>' + amessage('protected',ENV)+'('+recs.values['target']+').</p>'
             + '<form method=''get'' action='''+ D_ROOT + 'gateway.cgi/edittrust''><p>'
             + '<input type=''submit'' name=''button'' value=''' + amessage('add',ENV)+ ''' tabindex=''1'' accesskey=''a'' />'
             + '<input type=''submit'' name =''button'' value=''' + amessage('delete',ENV) + ''' tabindex=''2'' accesskey=''d'' />'
             + '<input type=''hidden'' name=''trip'' value=''' + trip + ''' />'
             + '<input type=''hidden'' name=''type'' value=''' + atype + ''' />'
             + '<input type=''hidden'' name=''file'' value=''' + afilename + ''' />'
             + amessage('to_from_trust_list',ENV) + ': '+ trip + '</p></form>'
             + '<p>' + s_ + '</p>'
             + '</body></html>';
        if not TServerThrd(mother).SendData(ans) then exit;

      end else begin
        ans := 'Content-Type: text/plain; charset=UTF-8' + CRLF
             + 'X-Shingetsu: ' +  ENV.Values['SERVER_SOFTWARE'] + CRLF
             + CRLF
             + amessage('wrong_sign',ENV) + LF
             + s_ + LF;
        if not TServerThrd(mother).SendData(ans) then exit;

      end;

    end else begin
      Print404(afile,ENV,mother);

    end;

  finally
    r.free;
    ret.free;
    recs.free;

  end;
end;



//--------------------------------------------------
// new element form
//
// $opt{file}, $opt{checked}, $opt{dopost}
//
procedure newElementForm(afile,achecked,adopost:string;ENV:TStringList;mother:TObject);
var
  ans:string;
begin
  ans := '<form method=''get'' action='''+D_ROOT+ENV.Values['SCRIPT_NAME'] + '''><p>'
       + '<input type=''hidden'' name=''cmd'' value=''new'' />'
       + '<input type=''hidden'' name=''file'' value=''' + afile + ''' />'
       + '<input type=''submit'' value=''' + amessage('new',ENV) + ''''  + ' name=''submit'' tabindex=''1'' accesskey=''w'' />'

        + '<input type=''radio'' value=''list'' name=''type'' tabindex=''2'' accesskey=''t'' />'
       + amessage('list',ENV)

       + ' <input type=''radio'' value=''thread'' name=''type'' tabindex=''2'' accesskey=''t'' />'
       + amessage('thread',ENV)

       + ' <input type=''radio'' value=''note'' name=''type'' tabindex=''2'' accesskey=''t'' />'
       + amessage('note',ENV);

  if not TServerThrd(mother).SendData(ans) then exit;

  ans := ' <input type=''checkbox'' value=''dopost'' name=''dopost'''
       + ' ' + achecked + ' tabindex=''2'' accesskey=''s'' />';
  if defined(adopost) then ans := ans + amessage('send',ENV);
  if not TServerThrd(mother).SendData(ans) then exit;

  ans := '<br />' + amessage('name',ENV) + ': <input name=''name'' size=''19''' + 'value='''' tabindex=''3'' accesskey=''t'' />'
       + '</p></form>';
  if not TServerThrd(mother).SendData(ans) then exit;
end;



end.
