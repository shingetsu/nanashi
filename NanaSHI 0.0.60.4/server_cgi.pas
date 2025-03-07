unit server_cgi;

interface

uses
  Classes, winsock, SysUtils, windows,synsock;

type
  TServerCgi = class(TObject)
  private
    ENV:TStringList;
    ans:string;
    mother : TObject;
  public
    Constructor Create(Sender:TObject);
    Destructor Destroy; override;
    function Execute(sender:TObject):string;
    function update(afile,astamp,aid,anode:string):boolean;
    function checkAddress(host,ip:string):boolean;
    procedure removeUpdate(idline:string);
  end;

implementation

uses
  httpd_pl,blcksock, config, lib1, RegularExp, NodeList_pm, Node_pm,
  util_pm, Cache_pm, main;


//---------------------------------------------------------------
//CONSTRUCTOR
Constructor TServerCgi.Create(Sender:TObject);
begin
  inherited Create;
  ENV := TStringList.Create;
  mother := ThttpdMain(TServerThrd(Sender).mother);

  inc(ThttpdMain(mother).SVCgiCount);
  inc(ThttpdMain(mother).SVCgiActive);

end;


//---------------------------------------------------------------
//DESTRUCTOR
Destructor TServerCgi.Destroy;
begin
  inherited;
  dec(ThttpdMain(mother).SVCgiActive);
  ENV.free;
end;

//---------------------------------------------------------------
function TServerCgi.Execute(sender:TObject):string;
var
  len,n:Integer; r:TRegularExp; z:TServerThrd; SIN:TextFile;
  tmp,path,ahost,aport,apath,acommand,afile,astamp,aid,anode,nport:string;
  suggest,alaststamp,abegin,aend,aip,s_,agent,me:string;ret,data:TStringList;
begin
  Result := '';

  z := TServerThrd(sender);
  ENV.Assign(TServerThrd(Sender).ENV);
  agent := ENV.Values['HTTP_USER_AGENT'];

  r := TRegularExp.Create;
  ret := TStringList.Create;
  data := TStringList.Create;
  try
    ans := 'Content-type: ' + mimeType.Values['txt']        + CRLF
         + 'X-Shingetsu: '  + ENV.Values['SERVER_SOFTWARE'] + CRLF;

    if (defined(ENV.Values['PATH_INFO'])and(ENV.Values['PATH_INFO']<>'')) then begin
      path := r.RegReplace(ENV.Values['PATH_INFO'],'^/','');
    end else if (defined(ENV.Values['QUERY_STRING'])and(ENV.Values['QUERY_STRING']<>'')) then begin
      path := ENV.Values['QUERY_STRING'];
    end else begin
      path := '';
    end;


    if ((ENV.Values['REQUEST_METHOD'] <> 'GET') and (ENV.Values['REQUEST_METHOD'] <> 'HEAD')) then begin begin
      Result := 'No GET|HEAD';
      exit;
    end;

    end else if(path = '')and(FileExists(D_FILEDIR+'/'+D_MOTD)) then begin
      z.printFile(D_MOTD);
      Result := 'z.printFile(D_MOTD)';

    end else if(path = 'ping') then begin
      inc(ThttpdMain(mother).SVCgiPingCount);
      inc(ThttpdMain(mother).SVCgiPingActive);
      try
        tmp := 'PONG' + LF
             + ENV.Values['REMOTE_ADDR'] + LF;
        len := length(tmp);
        ans := z.printHeader('200 OK', False)
             + 'Content-Length: ' + IntToStr(len) + CRLF
             + ans
             + CRLF
             + tmp;
        if not z.SendData(ans) then exit;
        Result := 'PONG';
      finally
        dec(ThttpdMain(mother).SVCgiPingActive);
      end;

    end else if(path = 'node') then begin
      try
        anode := NodeList_pm.randomNode();
        if defined(anode) then begin
          len := length(anode);
          ans := z.printHeader('200 OK', False)
               + 'Content-Length: ' + IntToStr(len) + CRLF
               + ans
               + CRLF
               + anode;
          if not z.SendData(ans) then exit;
          Result := anode;
        end;
      finally
        //
      end;

    end else if r.RegCompCut(path,'^join/([^:]*):(\d+)(.*)',False) then begin
      inc(ThttpdMain(mother).SVCgiRecvJoinActive);
      inc(ThttpdMain(mother).SVCgiRecvJoinCount);
      try
        ahost := r.grps('$1');
        if ahost = '' then
          ahost := ENV.Values['REMOTE_ADDR'];
        aport := r.grps('$2');
        apath := r.grps('$3');
        anode := ahost+':'+aport+'/'+trim(apath);

        aip := ENV.Values['REMOTE_ADDR'];
        if not (checkaddress(ahost,aip) and Node_pm.ping(anode,ENV)) then begin
          // join直後のping無応答はありえないので、通信上のトラブルとして無視
          ErrorPrint('[server.cgi] Join request, but no PONG --> '+anode);
        end else if (include(anode)) or (NodeList_pm.count() < D_NODES) then begin
          NodeList_pm.NodeAdd(anode,agent);
          tmp := 'WELCOME' + LF;
          len := length(tmp);
          ans := z.printHeader('200 OK', False)
               + 'Content-Length: ' + IntToStr(len) + CRLF
               + ans
               + CRLF
               + tmp;
          inc(ThttpdMain(mother).SVCgiWelcomeCount);
          inc(ThttpdMain(mother).SVCgiWelcomeActive);
          if not z.SendData(ans) then exit;
          Result := 'WELECOME';
          dec(ThttpdMain(mother).SVCgiWelcomeActive);
          NodeList_pm.NodeAdd(toString(anode),agent);

        end else begin
          suggest := NodeList_pm.randomNode();
          NodeList_pm.remove(suggest);
          Node_pm.bye(suggest,ENV);
          tmp := 'WELCOME' + LF;
          len := length(tmp);
          ans := z.printHeader('200 OK', False)
               + 'Content-Length: ' + IntToStr(len) + CRLF
               + ans
               + CRLF
               + tmp;
          inc(ThttpdMain(mother).SVCgiWelcomeCount);
          inc(ThttpdMain(mother).SVCgiWelcomeActive);
          if not z.SendData(ans) then exit;
          Result := 'WELECOME';
          dec(ThttpdMain(mother).SVCgiWelcomeActive);
          NodeList_pm.NodeAdd(toString(anode),agent);
        end;
      finally
        dec(ThttpdMain(mother).SVCgiRecvJoinActive);
      end;

    end else if r.RegCompCut(path,'^bye/([^:]*):(\d+)(.*)',False) then begin
      try
        ahost := r.grps('$1');
        aport := r.grps('$2');
        apath := r.grps('$3');
        if not defined(ahost) then
          ahost := ENV.Values['REMOTE_ADDR'];
        anode := ahost + ':' + aport + apath;
        if checkaddress(ahost,aip) then begin
          NodeList_pm.remove(anode);
          tmp := 'BYEBYE' + LF;
          len := length(tmp);
          ans := z.printHeader('200 OK', False)
               + 'Content-Length: ' + IntToStr(len) + CRLF
               + ans
               + CRLF
               + tmp;
          if not z.SendData(ans) then exit;
          Result := 'BYEBYE';
        end;
      finally
        //
      end;

    end else if r.RegCompCut(path,'^have/([0-9A-Za-z_]+)$',False) then begin   //ShinGETsu
      afile := r.grps('$1');
      if FileExists(DataPath(afile)) then begin
        tmp := 'YES' + LF;
      end else begin
        tmp := 'NO' + LF;
      end;
      len := length(tmp);
      ans := z.printHeader('200 OK', False)
           + 'Content-Length: ' + IntToStr(len) + CRLF
           + ans
           + CRLF
           + tmp;
      if not z.SendData(ans) then exit;
      Result := tmp;

    end else if r.RegCompCut(path,'^(get|head)\/([0-9A-Za-z_]+)\/([-0-9A-Za-z\/]*)$',False) then begin
      try
        acommand  := r.grps('$1');
        afile     := r.grps('$2');
        astamp    := r.grps('$3');
        if FileExists(DataPath(afile)) then begin
          AssignFile(SIN,DataPath(afile));
          try
            Reset(SIN);
            data.clear;
            while not Eof(SIN) do begin
              Readln2(SIN,tmp);
              data.add(tmp);
            end;
            CloseFile(SIN);
          except
            ErrorPrint('server.cgi get|head: open error...');
            exit;
          end;

          if data.Count > 0 then begin           //for error of zero size file. 2004/06/20 by kakashi.
            tmp := data.Strings[data.Count-1];   //last record.
            lib1.split(tmp,'<>',ret);
            if (ret.Count > 0) then begin        //for errr. 2004/08/01 by daikoku
              alaststamp := ret.Strings[0];      //
              if (astamp = '') then begin
                abegin := '0';                   //(A)----
                aend := alaststamp;
                aid := '';
              end else if r.RegCompCut(astamp,'^(\d+)$',False) then begin
                abegin := r.grps('$1');          //(B)----
                aend := r.grps('$1');
                aid := '';
              end else if r.RegCompCut(astamp,'^-(\d+)$',False) then begin
                abegin := '0';                   //(C)----
                aend := r.grps('$1');
                aid := '';
              end else if r.RegCompCut(astamp,'^(\d+)-$',False) then begin
                abegin := r.grps('$1');          //(D)----
                aend := alaststamp;
                aid := '';
              end else if r.RegCompCut(astamp,'^(\d+)-(\d+)$',False) then begin
                abegin := r.grps('$1');          //(E)----
                aend := r.grps('$2');
                aid := '';
              end else if r.RegCompCut(astamp,'^(\d+)/([0-9A-Za-z]+)',False) then begin
                abegin := r.grps('$1');          //(F)----
                aend := r.grps('$1');
                aid := r.grps('$2');
              end else begin
                abegin := '';          //(F)----
                aend := '';
                aid := '';
              end;

              if defined(abegin) then begin
                n := 0;
                tmp := '';
                while ( n < data.Count ) do begin
                  s_ := data.Strings[n];
                  split(s_,'<>',ret);
                  if ret.Count > 2 then begin
                    //タイムスタンプ<>識別<>本文
                    if (acommand = 'head') then
                      s_ := ret.Strings[0] + '<>' + ret.Strings[1] + LF
                   else
                      s_ := s_ + LF;  //注意！！！
                    if (abegin <= ret.Strings[0]) and (ret.Strings[0] <= aend) then begin
                      if defined(aid) then begin
                        if (ret.Strings[1] = aid) then
                          tmp := tmp + s_;
                      end else begin
                        tmp := tmp + s_;
                      end;
                    end else begin
                      //
                    end;
                  end else begin
                    //タイムスタンプ<>識別 ---> 削除したデータなので無視・・・
                  end;
                  inc(n);
                end;
                ans := z.printHeader('200 OK', False)
                     + ans;
                if not z.SendData(ans,tmp,True) then exit;
                Result := 'send record.';

              end;  // end of if defined(abegin) then begin

            end else begin // end of if (ret.Count > 0) then begin
              main.ErrorPrint('server.cgi warning! get|head of non record file.  ');
              Result := 'warning! get|head of non record file.'
            end;
          end;
        end;

      finally
        //

      end;

//-------------------------------------------------
//0.4-beta1
//} elsif ($path =~ m|^update/([0-9A-Za-z_]+)/(\d+)/([0-9A-Za-z]+)/(.+)|) {
//	my ($file, $stamp, $id, $node) = ($1, $2, $3, $4);
//	$node = new Shingetsu::Node($node);
//
(*    end else if r.RegCompCut(path,'^update/([0-9A-Za-z_]+)/(\d+)/([0-9A-Za-z]+)/(.+)',False) then begin
      //   'dopost'が定義されている時、他のノードからお知らせが飛んでくる！
      afile  := r.grps('$1');
      astamp := r.grps('$2');
      aid    := r.grps('$3');
      anode  := r.grps('$4');
      me := myself(ENV);
      if not defined(me) then begin
        main.dprint('### updateとでmyself()が未確定だった');
        exit;
      end;
      if (me = anode) then begin
        main.dprint('### updateとでmyself()と同じアドレスから要求があった');
        exit;
      end;
*)

//-------------------------------------------------
//0.4.1
//} elsif ($path =~ m|^update/([0-9A-Za-z_]+)/(\d+)/([0-9A-Za-z]+)/([^:]*):(\d+)(.*)|) {
//	my ($file, $stamp, $id, $host, $nport, $path) = ($1, $2, $3, $4, $5, $6);
//	$host = $ENV{REMOTE_ADDR} if ($host eq "");
//	$node = new Shingetsu::Node($host, $nport, $path);
//
    end else if r.RegCompCut(path,'^update/([0-9A-Za-z_]+)/(\d+)/([0-9A-Za-z]+)/([^:]*):(\d+)(.*)|',False) then begin
      //   'dopost'が定義されている時、他のノードからお知らせが飛んでくる！
      afile  := r.grps('$1');
      astamp := r.grps('$2');
      aid    := r.grps('$3');
      ahost  := r.grps('$4');
      nport  := r.grps('$5');
      apath  := r.grps('$6');
      if not defined(ahost) then
        ahost := ENV.Values['REMOTE_ADDR'];

      tmp := '';
      anode := ahost + ':' + nport + '/' + trim(apath);
      if isOkAddNode(anode) then begin
        if update(afile,astamp,aid,anode) then
          tmp := 'OK';
      end;
      len := length(tmp);
      ans := z.printHeader('200 OK', False)
           + 'Content-Length: ' + IntToStr(len) + CRLF
           + ans
           + CRLF
           + tmp
           + CRLF;
      if len > 0 then begin
        if not z.SendData(ans) then exit;
        Result := tmp + 'update data';

      end else begin
        Result := 'no update';

      end;

    end else begin
      main.ErrorPrint('Server_cgi UNKNOWN agent:'+ agent + ' path:' + path + ' ip:'+ENV.Values['REMOTE_ADDR']);
      Result := 'unkown...';

    end;

  finally
    r.free;
    ret.free;
    data.free;

  end;

end;



//-------------------------------------------
//Update
function TServerCgi.update(afile,astamp,aid,anode:string):boolean;

  function v(s:string):extended;
  begin
    if s = '' then s := '0';
    Result := StrToFloatDef(s,0);
  end;

var
  aupdate :TStringList; SIN:TextFile; tmp,idline:string; flag : integer;

begin
  Result := False;

  //日付差が２４時間を越えている場合は処理しない
  if (v(astamp) < (sys_time() - D_SAVEUPDATE * 60)) then
    exit;

  aupdate := TStringList.Create;
  try
    //update.txtを読み込む
    idline := astamp + '<>' + aid + '<>' + afile;
    if not FileExists(D_UPDATELIST) then exit;
    aupdate.Clear;
    AssignFile(SIN,D_UPDATELIST);
    try
      Reset(SIN);
      while not Eof(SIN) do begin
        Readln2(SIN,tmp);
        aupdate.add(tmp);
      end;
      CloseFile(SIN);
    except
      //
    end;

    //update.txtに同じ情報があるかチェック
    if (aupdate.IndexOf(idline) <> -1) then begin
      Result := True;
      exit;
    end;

    //日付差が２４時間以内を維持しながら指定ファイルをupdate.txtへ追加
    util_pm.addUpdate(astamp,aid,afile);

    if not FileExists(DataPath(afile)) then begin
      // ファイルを持っていない場合、、、、
      // 保持している全ノードに指定ファイルのupdateコマンドを送信する
      Cache_pm.tellupdate(afile,astamp,aid,anode,ENV);
      exit;
    end;

    //これ以降、ファイルが存在する・・・・・
    if _GetFileSize(DataPath(afile)) > 0 then begin
      //内容を更新する
      flag := Cache_pm.getData(afile,astamp,aid,anode,'/server.cgi',ENV);
    end else begin
      //ファイルサイズが０
      Cache_pm.getRegion(afile,anode,ENV);
      flag := _GetFileSize(DataPath(afile));
    end;

    if (flag > 0) then begin
      Cache_pm.tellupdate(afile,astamp,aid,'',ENV);
      if not ((NodeList_pm.include(anode)) or  (NodeList_pm.Count() > D_NODES)) then begin
        NodeList_pm.joinRequest(anode,ENV);
      end;
      Result := True;
    end else begin
      removeUpdate(idline);
      Result := False;
    end;

  finally

    aupdate.free;

  end;

end;




//-------------------------------------------
//check address
//
function TServerCgi.checkAddress(host,ip:string):boolean;
var
  h:PhostEnt; s:string;
begin
  Result := True;

  s := myself(ENV);

  if (host = ip) then
    exit;
  h := gethostbyname(PChar(host));
  if (h.h_name = ip) then
    exit;
  Result := False;
end;

//---------------------------------------------------------------------
//update.txtから指定情報を削除する
//
procedure TServerCgi.removeUpdate(idline:string);
var
  update :TStringList; SIN:TextFile; tmp:string; n:integer;
begin
  update := TStringList.Create;
  try
    //update.txtをバッファへ読み込む
    if not FileExists(D_UPDATELIST) then exit;
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

    //idline以外のバッファを書き出す
    Util_pm.lock();
    AssignFile(SIN,D_UPDATELIST);
    try
      Rewrite(SIN);
      n := 0;
      while n < update.Count do begin
        tmp := update.strings[n];
        if (tmp <> idline) then
          writeln(SIN,tmp);
        inc(n);
      end;
      CloseFile(SIN);
    except
      //
    end;
    Util_pm.unlock();

  finally
    update.free;

  end;

end;


end.
