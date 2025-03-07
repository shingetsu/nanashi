unit httpd_pl;

interface

uses
  Classes, blcksock, winsock, Synautil, SysUtils, RegularExp, lib1, windows,
  server_cgi, client_cgi, gateway_cgi, list_cgi, thread_cgi, note_cgi;

type
  TServerThrd = class;
  TClientThrd = class;

  //--------------------------------------------
  ThttpdMain = class(TThread)
  private
   Sock:TTCPBlockSocket;
   appQuit : boolean;
  public
    mother     : TObject;
    ListenCnt  : integer;
    ENV        : TStringList;

    SVThreadCount      : integer;
    SVThreadActive     : integer;

    SVCgiCount          : integer;
    SVCgiActive         : integer;
    SVCgiPingCount      : integer;
    SVCgiPingActive     : integer;
    SVCgiRecvJoinActive : integer;
    SVCgiRecvJoinCount  : integer;
    SVCgiWelcomeActive  : integer;
    SVCgiWelcomeCount   : integer;
    ClCgiActive         : integer;
    ClCgiCount          : integer;

    ping_sec : integer;
    sync_sec : integer;
    init_sec : integer;

    ping_mxx : integer;
    sync_mxx : integer;
    init_mxx : integer;

    Constructor Create(Sender:TObject);
    Destructor  Destroy; override;
    procedure StartMessage();
    procedure Execute; override;

    procedure ForceQuit();
    function isQuit():boolean;
    function isCanQuit():boolean;

    function isOkDoClinetCgi():boolean;
    function isOkDoServerCgi():boolean;

  end;


  //--------------------------------------------
  TClientThrd = class(TThread)
  private
    { Private 宣言 }
  public
    mother : ThttpdMain;
    ENV : TStringList;
    constructor Create (Sender:ThttpdMain; CreateSuspended:boolean);
    destructor Destroy; override;
    procedure Execute; override;
  end;


  //--------------------------------------------
  TServerThrd = class(TThread)
  private
    Sock : TTCPBlockSocket;
    Server_cgi  : TServerCgi;
    Gateway_cgi : TGatewayCgi;
    List_cgi    : TListCgi;
    Note_cgi    : TNoteCgi;
    Thread_cgi  : TThreadCgi;
  public
    timeout : integer;
    mother : ThttpdMain;
    ENV : TStringList;

    str_request,referer,agent,range : string;
    flag_error,gzip : boolean;
    content_length : integer;

    constructor Create (Sender:ThttpdMain; hsock:tSocket);
    destructor Destroy; override;
    procedure Execute; override;
    function isSockError():boolean;
    function printHeader(stat:string;sw:Boolean):string;
    function ReadData(tout:integer):string;
    function SendData(res:string):Boolean; overload;
    function SendData(head,body:string;gzip:boolean):Boolean; overload;
    function printResult(s:string):string;
    function printFile(fname:string):string;

  end;

var
  mSERVER_ADDR : string;


implementation


uses
  config, NodeList_pm, ZLibEx, CacheStat_pm, main;






//====================================================================
//====================================================================
{ThttpdMain}
//====================================================================
//====================================================================


//---------------------------------------------
// CREATE
//
constructor ThttpdMain.Create(Sender:TObject);
begin
  inherited Create(True);

  mother := Sender;
  ListenCnt := 0;
  ENV := TStringList.create;
  Sock := TTCPBlockSocket.create;

  appQuit := False;
  FreeOnTerminate := True;

  SVThreadCount  := 0;
  SVThreadActive := 0;

  SVCgiPingCount  := 0;
  SVCgiPingActive := 0;
  SVCgiCount  := 0;
  SVCgiActive := 0;
  SVCgiRecvJoinActive := 0;
  SVCgiRecvJoinCount := 0;
  SVCgiWelcomeActive := 0;
  SVCgiWelcomeCount := 0;
  ClCgiActive := 0;
  ClCgiCount := 0;

  ping_sec := 0;
  sync_sec := 0;
  init_sec := 0;

  ping_mxx := 0;
  sync_mxx := 0;
  init_mxx := 0;

  Resume;
end;

//---------------------------------------------
// DESTROY
//
destructor ThttpdMain.Destroy;
begin
  ENV.free;
  Sock.free;

  inherited Destroy;
end;


//------------------------------------------------------
// 強制終了フラグをOnとする（強制終了を依頼する）
//
procedure ThttpdMain.ForceQuit();
begin
  appQuit := True;
end;


//------------------------------------------------------
// 強制終了要求を確認する
//
function ThttpdMain.isQuit():boolean;
begin
  try
    Result := appQuit;
  except
    //
  end;
end;


//------------------------------------------------------
// 終了可能であるか確認する
//
function ThttpdMain.isCanQuit():boolean;
begin
  Result := (SVThreadActive = 0) and (SVCgiActive = 0) and (ClCgiActive = 0);
end;


//------------------------------------------------------
// 起動時のメッセージ
//
procedure  ThttpdMain.StartMessage();
begin
  mprint('--------------------------------------------------');
  mprint('Server: ' + ENV.Values['SERVER_SOFTWARE']);
  mprint('Port:'+ENV.Values['SERVER_PORT']);
  mprint('bind: ' + ENV.Values['SERVER_BIND'] );
  mprint('Protocol: ' + ENV.Values['SERVER_PROTOCOL'] );
  mprint('initNode: ' + ENV.Values['X_INIT_NODE'] );
  mprint('--------------------------------------------------');
  mprint('');
  sleep(500);
end;


//------------------------------------------------------
// httpdMainのメインルーチン（スレッド）
//
procedure ThttpdMain.Execute;
var
  ServerSock:TSocket; ws:TClientThrd;
begin
  ENV.Values['SERVER_SOFTWARE']   := D_SOFTWARE + D_VER + D_SUBNAME;
  ENV.Values['GATEWAY_INTERFACE'] := 'CGI/1.1';
  ENV.Values['SERVER_PROTOCOL']   := 'HTTP/1.0';
  ENV.Values['SERVER_PORT']       := Form1.EditPort.Text;
  ENV.Values['SERVER_BIND']       := Form1.EditBind.Text;
  ENV.Values['X_INIT_NODE']       := lib1.join('+', __initNode);
  ENV.Values['SERVER_ADDR']       := ''; 

  //Client -----------------------
  ws := TClientThrd.Create(self,True);                   //True:サスペンド中
  ws.Priority := tpNormal;                               //tpLowest,tpHighest,tpNormal;

  ws.ENV.Values['REMOTE_ADDR'] := D_ADMINADDR + '.0.0.1';
  ws.ENV.Values['QUERY_STRING']   := '';
  ws.ENV.Values['PATH_INFO']      := '';
  ws.ENV.Values['REQUEST_METHOD'] := 'GET';
  ws.ENV.Values['SCRIPT_NAME']    := '/client.cgi';

  //Server ------------------------
  with sock do begin
    CreateSocket;
    SetLinger(True,10);
    bind(ENV.Values['SERVER_BIND'],ENV.Values['SERVER_PORT']);
    listen;

    //開始メッセージ
    StartMessage();

    //stat.txtを最新に更新する
    CacheStat_pm.Cache_update();

    //Pingallを実行しNode.txtを更新する。
    pingall(ENV);

    //Client -----------------------
    ws.Resume;     //サスペンドから実行へ

    repeat
      if terminated then
        break;
      if isQuit() then
        break;
      if (listencnt < D_MAXLISTEN) then begin
        if canread(1000) then begin
          ServerSock := accept;
          if (lastError = 0) then begin
            TServerThrd.create(self,ServerSock);
          end;
        end;
      end;
    until false;
  end;
end;


//------------------------------------------------------
// クライアントCGI動作可能チェック
//
function ThttpdMain.isOkDoClinetCgi():boolean;
begin
  Result := False;
  if TForm1(mother).CheckBox5.Checked then begin
  //if (SVCgiActive = 0) then begin   //Server_cgiと重複したくない場合、このリマークを外す。
      Result := True;
  //end;
  end;
end;


//------------------------------------------------------
// サーバーCGI動作可能チェック
//
function ThttpdMain.isOkDoServerCgi():boolean;
begin
  Result := False;
  if TForm1(mother).CheckBox6.Checked then begin
  //if (ClCgiActive = 0) then begin  //Client_cgiと重複したくない場合、このリマークを外す
      Result := True;
  //end;
  end;
end;



//====================================================================
//====================================================================
{TClientThrd}
//====================================================================
//====================================================================


//------------------------------------------------------
// CREATE
//
constructor TClientThrd.Create(Sender:ThttpdMain; CreateSuspended: Boolean);
begin
  inherited Create(CreateSuspended);
  mother := ThttpdMain(Sender);

  ENV := TStringList.create;
  ENV.Assign(Sender.Env);

end;


//------------------------------------------------------
// DESTROY
//
destructor TClientThrd.Destroy;
begin
  dec(mother.ClCgiActive);
  ENV.Free;
  inherited Destroy;
end;


//------------------------------------------------------
// httpdMainのメインルーチンから1度だけ呼ばれる
// ことを想定したクライアントメインルーチン（スレッド）
//
procedure TClientThrd.Execute;
var
  client_cgi:TClientCgi;
begin
  while True do begin
    if mother.isQuit() then
      break;
    if Terminated then
      break;
    if mother.isOkDoClinetCgi() then begin
      client_cgi := TClientCgi.create(self);
      client_cgi.Execute(self);  //クライアント処理
    //client_cgi.free;
    end;
    if mother.isQuit() then
      break;
    sleep(D_CLIENTSLEEP);
  end;
end;



//====================================================================
//====================================================================
{TServerThrd}
//====================================================================
//====================================================================


//------------------------------------------------------
// CREATE
//
constructor TServerThrd.Create(Sender:ThttpdMain; Hsock:TSocket);
begin
  inherited Create(true);

  mother := Sender;
  inc(mother.listencnt);
  inc(mother.SVThreadActive);

  inc(mother.SVThreadCount);


  timeout := D_SVR_TIMEOUT;
  mother := Sender;
  ENV := TStringList.create;
  ENV.Assign(Sender.Env);

  Sock := TTCPBlockSocket.create;
  Sock.SSLEnabled := True;


  Server_cgi  := TServerCgi.create(Self);
  Gateway_cgi := TGatewayCgi.create(Self);
  List_cgi    := TListCgi.create(Self);
  Note_cgi    := TNoteCgi.create(Self);
  Thread_cgi  := TThreadCgi.create(Self);

  Sock.socket := HSock;

  str_request := '';
  referer := '';
  agent := '';
  range := '';
  content_length := 0;

  flag_error := False;
  gzip := False;

  FreeOnTerminate := True;
  Resume;

end;


//------------------------------------------------------
// DESTROY
//
destructor TServerThrd.Destroy;
begin
  dec(mother.listencnt);
  dec(mother.SVThreadActive);

  Server_cgi.free;
  Gateway_cgi.free;
  Note_cgi.free;
  List_cgi.free;
  Thread_cgi.free;
  ENV.Free;
  Sock.free;
  inherited Destroy;
end;


//------------------------------------------------------------
// httpdMainのメインルーチンから着信があるたびにけ呼ばれる
// ことを想定したサーバーメインルーチン（スレッド）
//
procedure TServerThrd.Execute;
var
  r:TRegularExp; s,res,tmp,LOGMSGG,ret:string;
  a:TStringList; m,i:integer;
begin
  try
    str_request := '';
    r := TRegularExp.Create;
    a := TStringList.Create;
    try
      ENV.Values['REMOTE_HOST'] := sock.GetRemoteSinIP;
      ENV.Values['REMOTE_ADDR'] := sock.GetRemoteSinIP;
      ENV.Values['REMOTE_PORT'] := IntToStr(sock.GetRemoteSinPort);

      //HEADER DATA......
      while True do begin
        if mother.isQuit() then
          exit;
        if Terminated then
          break;
        s := ReadData(timeout);  //read one line.
        if not defined(s) then break;
        if isSockError() then exit;
        s := r.RegReplace(s,'[\n|\r]','');
        if r.RegCompCut(s,'^(\S+)\s+(\S+)',False) and (not defined(ENV.Values['REQUEST_METHOD'])) then begin
          str_request := s;
          ENV.Values['REQUEST_METHOD'] := r.grps('$1');
          ENV.Values['REQUEST_URI']    := r.grps('$2');
          ENV.Values['REQUEST_URI']    := r.RegReplace(ENV.Values['REQUEST_URI'],'^//+','/');
        end else if r.RegCompCut(s,'^Host:\s+(.*)',True) then begin
          ENV.Values['HTTP_HOST'] := r.grps('$1');
        end else if (r.RegCompCut(s,'^Accept-Encoding:.*gzip',True) and  r.RegCompCut(s,D_ADMINADDR,False)) then begin
          gzip := True;
        end else if r.RegCompCut(s,'^Accept-Language:\s+(.*)',True) then begin
          s := r.grps('$1');
          //プライオリティの高い言語を採用する
          DecodeLanguage(s,a);
          i := a.count;
          m := 0;
          while (m < a.count) do begin
            s := a.Strings[i-1];
            if (m = 0)  then
              ENV.Values['HTTP_ACCEPT_LANGUAGE'] := s
            else
              ENV.Values['HTTP_ACCEPT_LANGUAGE'+IntToStr(m)] := s;
            inc(m);
            dec(i);
          end;
        end else if r.RegCompCut(s,'^Range:\s*bytes\s*=\s*(\d+)\s*-',True) then begin
          range := r.grps('$1');
        end else if r.RegCompCut(s,'^Content-Length:\s+(\d+)',True) then begin
          ENV.Values['CONTENT_LENGTH'] := r.grps('$1');
          self.content_length := StrToIntDef(r.grps('$1'),0);
        end else if r.RegCompCut(s,'^Referer:\s+(.*)',True) then begin
          ENV.Values['HTTP_REFERER'] := r.grps('$1');
          referer := r.grps('$1');
        end else if r.RegCompCut(s,'^User-Agent:\s+(.*)',True) then begin
          ENV.Values['HTTP_USER_AGENT'] := r.grps('$1');
          agent := r.grps('$1');
        end else if r.RegCompCut(s,'^Content-Type:\s+([^;]+)',True) then begin
          ENV.Values['CONTENT_TYPE'] := r.grps('$1');
        end;
      end;  // end of while True do begin


      if (not defined(ENV.Values['CONTENT_LENGTH'])) then begin
        self.content_length := 0;
      end else if (self.content_length > D_FILELIMIT * 1024 * 1024) then begin
       flag_error := True;
      end else begin
        if self.content_length > 0 then begin
          ENV.Values['POST_STRING'] := sock.RecvBufferStr(self.content_length, timeout);
        end;
      end;

      if r.RegCompCut(ENV.Values['REQUEST_URI'],'^[a-z]+://([^/]+)(.*)',False) then begin
        ENV.Values['HTTP_HOST']   := r.grps('$1');
        ENV.Values['REQUEST_URI'] := r.grps('$2');
      end;

      if (ENV.Values['REQUEST_URI'] = '') then
        ENV.Values['REQUEST_URI'] := '/';

      if r.RegCompCut(ENV.Values['REQUEST_URI'],'^/([0-9a-zA-Z]+)\.cgi(.*)',True) then begin
        ENV.Values['SCRIPT_NAME'] := r.grps('$1') + '.cgi';
        ENV.Values['PATH_INFO']   := r.grps('$2');
        if r.RegCompCut(ENV.Values['PATH_INFO'],'(.*)\?(.*)',False) then begin
          ENV.Values['QUERY_STRING'] := r.grps('$2');
          ENV.Values['PATH_INFO'] := r.grps('$1');
        end else begin
          ENV.Values['QUERY_STRING'] := '';
        end;
        ENV.Values['PATH_INFO'] := UrlDecode(ENV.Values['PATH_INFO']);

      end else if (ENV.Values['REQUEST_URI'] = '/')  then begin
        ENV.Values['SCRIPT_NAME'] := D_INDEX;
        ENV.Values['QUERY_STRING'] := '';

      end;

      //下位プロトコルへのフィルタ
    //s := AgentName(ENV);
      s := agent;
      if not IsOkAgent(s) then begin
      //dprint('[HTTPD]' + s + ' is non support agent.');
        res := printHeader('404 Not Found',True);
        res := res
             + 'Bad arguments or No data.(x)' + CRLF
             + 'Try later.' + CRLF;
        if not SendData(res) then exit;
        exit;
      end;

      //Disp infomation.
    //dprint('[HTTPD]'+ENV.Values['REMOTE_ADDR']+'<>'+Rfc822DateTime(now)+'<>'+str_request+'<>'+agent+'<>'+referer);
    //dprint('[HTTPD]'+agent+'<>'+ENV.Values['REMOTE_ADDR']+'<>'+str_request+'<>'+referer);
      LOGMSGG := '[HTTPD]'+agent+'<>'+ENV.Values['REMOTE_ADDR']+'<>'+copy(str_request,1,40) + ' ... ' +'<>'+referer + ' ';

      if (ENV.Values['SCRIPT_NAME'] <> 'server.cgi') then
        gzip := False;

      if flag_error then begin
        res := printHeader('404 Not Found',True);
        res := res
             + 'Bad arguments or No data.(1)' + CRLF
             + 'Try later.' + CRLF;
        if not SendData(res) then exit;
        dprint(LOGMSGG+'>> '+'404 Not Found');

      end else if(ENV.Values['REQUEST_METHOD'] = 'OPTIONS') then begin
        res := printHeader('200 OK',True);
        res := res
             + 'Allow: GET, HEAD, POST, OPTIONS.' + CRLF
             + 'Content-Length: 0' + CRLF;
        if not SendData(res) then exit;
        dprint(LOGMSGG+'>> '+'200 OK');

      end else if(not r.RegCompCut(ENV.Values['REQUEST_METHOD'],'^(GET|HEAD|POST)$',False)) then begin
        res := printHeader('501 Not Implemented',True);
        if not SendData(res) then exit;
        dprint(LOGMSGG+'>> '+'501 Not Implemented');

      end else if (defined(ENV.Values['SCRIPT_NAME'])) then begin
        tmp := ENV.Values['SCRIPT_NAME'];
        if tmp = 'server.cgi' then begin
          if mother.isOkDoServerCgi() then begin
            ret := Server_cgi.execute(self);
            dprint(LOGMSGG + '>> ' + tmp + ' >>> ' + ret);
          end else begin
            dprint(LOGMSGG+'>> '+' No anther! isOkDoServerCgi() = False');
          end;

        end else if tmp = 'gateway.cgi' then begin
          Gateway_cgi.execute(self,sock);
          dprint(LOGMSGG + '>> '+tmp);

        end else if tmp = 'note.cgi' then begin
          note_cgi.execute(self,sock);
          dprint(LOGMSGG+'>> '+tmp);

        end else if tmp = 'list.cgi' then begin
          list_cgi.execute(self,sock);
          dprint(LOGMSGG+'>> '+tmp);

        end else if tmp = 'thread.cgi' then begin
          thread_cgi.execute(self,sock);
          dprint(LOGMSGG+'>> '+tmp);

        end else begin
          res := printHeader('404 Not Found',True);
          res := res
               + 'Bad arguments or No data.(2)' + CRLF
               + 'Try later.' + CRLF;
          if not SendData(res) then exit;
          dprint(LOGMSGG+'>> '+ tmp + ' / 404 Not Found');

        end;

      end else if r.RegCompCut(ENV.Values['REQUEST_URI'],'^/[0-9A-Za-z._]+$',False) then begin
        tmp := r.grps('$&');
        printFile(tmp);
        dprint(LOGMSGG+'>> '+ tmp + ' / printFile()');


      end else begin
        res := printHeader('404 Not Found',True);
        res := res
             + 'Bad arguments or No data.(3)' + CRLF
             + 'Try later.' + CRLF;
        if not SendData(res) then exit;
        dprint(LOGMSGG+'>> ' + ENV.Values['REQUEST_METHOD'] + ' / bad script name / 404 Not Found');

      end;

    finally
      a.free;
      r.free;
    end;

  finally
    if not mother.isQuit() then
      sleep(D_CLIENTSLEEP);
    sock.CloseSocket;
  end;

end;


//READ DATA
function TServerThrd.ReadData(tout:integer):string;
begin
  Result := sock.RecvString(timeout);  //read one line.
end;


//-------------------------------------------------
// Send data
//
function TServerThrd.SendData(head,body:string;gzip:boolean):Boolean; //overload;
var
  ans,buf:string; len:integer;
begin
  Result := False;
  if gzip then begin
    buf  := body;
    ans := ZCompressStr2(buf, zcDefault, 16 + 15, 8, zsDefault);
    body := ans;
  end;
  len  := length(body);
  head := head  + 'Content-Length: ' + IntToStr(len) + CRLF;
  if gzip then begin
    head := head + 'Content-Encoding: gzip' + CRLF
  end;
  head := head + CRLF;

  sock.SendString(head);
  if isSockError() then exit;

  sock.SendString(body);
  if isSockError() then exit;
  Result := True;
end;

//-------------------------------------------------
// Send data
//
function TServerThrd.SendData(res:string):Boolean;  //overload;
begin
  Result := False;
//main.dprint1('SendData: ' + res);
  sock.SendString(res);
  if isSockError() then exit;
  Result := True;
end;


function TServerThrd.printResult(s:string):string;
begin
  //未完成 ×　今回は移植しない！

end;

function TServerThrd.printFile(fname:string):string;
var
  r:TRegularExp; ff,suffix,mtype,res:string; len,po,SIN,fs:Integer;
begin
  r := TRegularExp.Create;
  try
    fname := r.RegReplace(fname,'^/+','');
    r.RegCompCut(fname,'\.([^.]+)$',False);
    suffix := r.grps('$1');
    if not defined(suffix) then suffix := 'txt';
    mtype := mimeType.Values[suffix];
    if not defined(mtype) then suffix := 'text/plain';

    ff := D_FILEDIR+'/'+fname;
    if not FileExists(ff) then exit;
    if p_open(SIN,ff) then begin
      fs  := _GetFileSize(ff);
      res := printHeader('200 OK',False);
      res := res
           + 'Content-Type: ' + mtype + CRLF;
      if( ENV.Values['REQUEST_METHOD'] = 'HEAD') then begin
        res := res + 'Content-Length: 0' + CRLF
             + CRLF;
        if not SendData(res) then exit;
        exit;
        
      end else if (range > '0' ) then begin
        len := fs - StrToInt(range);
        fileseek(SIN,StrToIntDef(range,0),0);
	res := res + 'Content-Range: bytes ' + range + '-'
                   + '('+ IntToStr(fs-1) + ')' +  '/' + IntToStr(fs) + CRLF
		   + 'Content-Length: ' + IntToStr(len) + CRLF
                   + CRLF;
        if not SendData(res) then exit;

      end else begin
        res := res + 'Content-Length: ' + IntToStr(fs) + CRLF
             + CRLF;
        if not SendData(res) then exit;
      end;

      po := 0;
      while (po < fs) and (not Terminated) do begin
        len := p_read(SIN,res,1024);
        if (len <= 0) then
          break;
        if not SendData(res) then exit;
        po := po + len;
      end;

    end else begin
      res := printHeader('404 Not Found',True);
      res := res
           + 'Bad arguments or No data.(4)' + CRLF
           + 'Try later.' + CRLF;
      if not SendData(res) then exit;

    end;

  finally
    p_close(SIN);
    r.free;
  end;

end;


function TServerThrd.isSockError():boolean;
begin
  result := (sock.lasterror <> 0);
end;

//PRINT HEADER
function TServerThrd.printHeader(stat:string;sw:boolean):string;
begin
  Result := 'HTTP/1.0 ' + stat             + CRLF
          + 'Server: ' + ENV.Values['SERVER_SOFTWARE']   + CRLF
          + 'Connection: Close'             + CRLF;
  if sw then
    Result := Result + '' + CRLF;
end;



end.
