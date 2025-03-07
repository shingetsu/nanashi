unit NodeList_pm;

interface

uses
  Classes, blcksock, winsock, Synautil, SysUtils, RegularExp, lib1;

function ExpandUrl(input:string; var ip,port,path:string):boolean;
function ExpandUrl2(input:string; var ip,port,path,agent:string):boolean;

function isOkHavingNode(anode:string): boolean;
function IsOkAgent(agent:string):boolean;
function AgentName(ENV:TSTringList):string; overload;
function AgentName(ENV:TSTringList; anode:string):string; overload;

function IsOkAddNode(node:string):boolean;
procedure SortNode;
function  FindNodeIndex(node:string):integer;
procedure LoadNode();
procedure SaveNode();
procedure DeleteNode(no:integer);
procedure ClearNode();
function GetNode(no:integer;AgentSW:boolean):string;
procedure SetNode(no:integer;node:string);
function NodeCount():integer;
function listFromNodeFile():TStringList;
function All():TStringList;

function randomNode():string;
function myself(ENV:TStringList;loadsw:boolean = True):string;
procedure NodeAdd(node:string;Agent:string);
function include(node:string):boolean;
function count():integer;
procedure remove(node:string);
procedure pingall(ENV:TStringList);
function joinRequest(node:string;ENV:TStringList):boolean;
function init(ENV:TStringList):boolean;


implementation


uses
  main,config,httpd_pl,Node_pm,Util_pm;

function isOkHavingNode(anode:string): boolean;
var
  s:string;
begin
  Result := False;
  if not Form1.CheckBox7.Checked then begin
    Result := True;
    exit;
  end;
  s := Form1.Memo5.lines.Values[anode];
  if pos(D_NODEMANAGER,s) <> 0 then
    exit;
  Result := True;
end;

//------------------------------------------------
//
function IsOkAgent(agent:string):boolean;
begin
  Result := False;
  if not Form1.CheckBox4.Checked then begin
    Result := True;
    exit;
  end;
  if pos(D_VERSION1,agent) <> 0 then
    exit;
  if agent = D_NONAGENT then
    exit;
  Result := True;
end;

//------------------------------------------------
//
function AgentName(ENV:TSTringList):string;   //overload
begin
  Result := ENV.Values['WGET_RETURN_X-SHINGETSU'];
  if not defined(Result) then
    Result := ENV.Values['WGET_RETURN_SERVER'];
  if not defined(Result) then
    Result := ENV.Values['WGET_RETURN_USER_AGENT'];
  if not defined(Result) then
    Result := ENV.Values['HTTP_USER_AGENT'];
  if not defined(Result) then
    Result := D_NONAGENT;
end;

function AgentName(ENV:TSTringList; anode:string):string;  //overload
begin
  Result := ENV.Values['WGET_RETURN_X-SHINGETSU'];
  if not defined(Result) then
    Result := ENV.Values['WGET_RETURN_SERVER'];
  if not defined(Result) then
    Result := ENV.Values['WGET_RETURN_USER_AGENT'];
  if not defined(Result) then
    Result := ENV.Values['HTTP_USER_AGENT'];
  if not defined(Result) then
    Result := D_NONAGENT;
  Form1.Memo5.lines.Values[anode] := Result;
end;

//------------------------------------------------
//
function IsOkAddNode(node:string):boolean;
var
  ip,port,path:string;
begin
  Result := False;
  try
    if node = mSERVER_ADDR then begin
      exit;
    end;
    if ExpandUrl(node,ip,port,path) then begin
      if not defined(ip) then exit;
      if not defined(port) then exit;
      if not defined(path) then exit;
      if pos('+', path) <> 0 then exit;
  //  if (path <> '/server.cgi') and (path <> '/node.cgi')
  //     and (path <> 'node.xcg') and (path <> '/index.cgi')then exit;
      Result:= True;
    end;
  finally
    if not Result then
      main.ErrorPrint('[NodeAdd()] can`t add. [ ' + node +' ] ');
  end;
end;



//------------------------------------------------
//
procedure SortNode;
begin
  nodeTable.Sort;    //OK,,
end;

//------------------------------------------------
//
function FindNodeIndex(node:string):integer;
begin
  Result := nodeTable.IndexOf(node);        //OK,,
end;

//------------------------------------------------
//
procedure LoadNode();
begin
  nodeTable.loadFromFile(D_NODELIST);   //OK,,
end;

//------------------------------------------------
//
procedure SaveNode();
begin
  nodeTable.SaveToFile(D_NODELIST);     //OK,,
end;

//------------------------------------------------
//
procedure DeleteNode(no:integer);
begin
  nodeTable.Delete(no);  //OK,,
end;


//------------------------------------------------
//
procedure ClearNode();
begin
  nodeTable.Clear;  //OK,,
end;

//------------------------------------------------
//
function GetNode(no:integer;AgentSW:boolean):string;
var
  tmp,ip,port,path,agent:string;
begin
  Result := '';
  if ((no+1) > nodeTable.Count) then
    exit;
  tmp := nodeTable.Strings[no];      //OK,,
  if ExpandUrl2(tmp,ip,port,path,agent) then begin
    Result := ip + ':' + port + path;
    //if AgentSW then
    //  Result := Result + '{}' + agent;
  end;

end;


//------------------------------------------------
//
procedure SetNode(no:integer;node:string);
begin
  if (no < 0) or (no >= nodeTable.Count) then
    exit;
  nodeTable.Strings[no] := node;    //OK,,
end;



//------------------------------------------------
//
function NodeCount():integer;
begin
  Result := nodeTable.count;       //OK,,
end;

//------------------------------------------------
//show all nodes     未完成
//
function listFromNodeFile():TStringList;
var
  m,n,iocnt:integer; bb,s:string;
begin
  iocnt := 0;
  Result := nodeTable;     //OK,,,

  Util_pm.lock();

  try
    if not FileExists(D_NODELIST) then begin
      //node.txtが存在しない場合は、
      //作成は起動時のみなのでする
      //終了する
      exit;
    end;
    ClearNode();
    LoadNode();

    SortNode();
    n := 0;
    m := NodeCount() - 1;
    if (n <= m) then
      bb := NodeList_pm.GetNode(n,True);
    n := 1;
    while (n <= m) do begin
      s := NodeList_pm.GetNode(n,True);
      chomp(s);
      if (not defined(s)) or (s = bb) then begin
        //空レコード削除、重複レコード削除
        inc(iocnt);
        DeleteNode(n);
        dec(m);
      end else if not NodeList_pm.isOKAddNode(s) then begin
        //不正ノードの削除
        inc(iocnt);
        DeleteNode(n);
        dec(m);
      end else begin
        bb := NodeList_pm.GetNode(n,True);
        inc(n);
      end;
    end;
  finally
    //ノード内容の変更があった時だけ書き込む
    if (iocnt > 0) then
      SaveNode();

    Util_pm.unlock();

  end;
end;


//------------------------------------------------
//show randmized all nodes
//
function All():TStringList;
var
  t,i:integer; s:string;
begin
  NodeList_pm.listFromNodeFile();
  Result := nodeTable;     //OK,,
  i := NodeCount();
  while (i > 0) do begin
    t := random(i);
    s := GetNode(i-1,True);
    SetNode(i-1,GetNode(t,True));
    SetNode(t,s);
    dec(i);
  end;
end;


//------------------------------------------------
//suggest random node
//
function randomNode():string;
var
  ans:TStringList;
begin
  //main.dprint('(IN) ....... randomNode() ');
  ans := listFromNodeFile();
  if (ans.count > 0) then
    Result := ans.Strings[random(ans.count)]
  else
    Result := '';
  //main.dprint('(OUT) ....... randomNode() ');
end;


//------------------------------------------------
// Expand URL
//
// in 192.168.1.1:6000/test.html
//
// out ip ----> 192.168.1.1
//     port --> 6000
//     path --> /test.html
//
function ExpandUrl(input:string; var ip, port, path:string):boolean;
var
  r:TRegularExp; ans:string;
begin
  Result := False;
  r := TRegularExp.create;
  try
    if r.RegCompCut(input,'([^:]+):(\d+)(/[^:]+$)',False) then begin
      Result := True;
      ip   := r.grps('$1');
      port := r.grps('$2');
      path := r.grps('$3');
    end else if r.RegCompCut(input,'([^:]+):(\d+)',False) then begin
      Result := True;
      ip   := r.grps('$1');
      port := r.grps('$2');
      path := '';
    end else if r.RegCompCut(input,'([^:]+)',False) then begin
      Result := True;
      ip   := r.grps('$1');
      port := '';
      path := '';
    end;
  finally
    r.free;
  end;
end;


//------------------------------------------------
// Expand URL 2
//
// in 192.168.1.1:6000/test.html<>xxxxx
//
// out ip ----> 192.168.1.1
//     port --> 6000
//     path --> /test.html
//     agent --> xxxxx
//
function ExpandUrl2(input:string; var ip,port,path,agent:string):boolean;
var
  r:TRegularExp; ans:string;
begin
  Result := False;
  r := TRegularExp.create;
  try
    if r.RegCompCut(input,'([^:]+):(\d+)(/[^:]+){}(\S+$)',False) then begin
      Result := True;
      ip     := r.grps('$1');
      port   := r.grps('$2');
      path   := r.grps('$3');
      agent  := r.grps('$4');
    end else if r.RegCompCut(input,'([^:]+):(\d+)(/[^:]+$)',False) then begin
      Result := True;
      ip     := r.grps('$1');
      port   := r.grps('$2');
      path   := r.grps('$3');
      agent  := '';
    end else if r.RegCompCut(input,'([^:]+):(\d+)',False) then begin
      Result := True;
      ip     := r.grps('$1');
      port   := r.grps('$2');
      path   := '';
      agent  := '';
    end else if r.RegCompCut(input,'([^:]+)',False) then begin
      Result := True;
      ip     := r.grps('$1');
      port   := '';
      path   := '';
      agent  := '';
    end;
  finally
    r.free;
  end;
end;


//------------------------------------------------
//who am i
//
function myself(ENV:TStringList;loadsw:boolean = True):string;
var
  alladdr,body:TStringList;sname,ip,path,port,tmp: string;
  r:TRegularExp; n:integer;
begin
  Result := '';
  port := ENV.Values['SERVER_PORT'];
  path := D_PATH;
  alladdr  := All();          //-----> nodeはfreeする必要なし

//sname := ENV.Values['SERVER_ADDR'];
  sname := mSERVER_ADDR;

  if defined(sname) then begin
    Result := sname + ':' + port + path;
    exit;
  end;

  r := TRegularExp.Create;
  body := TStringList.Create;
  try
    n := 0;
    while (n < alladdr.count) do begin
      tmp := alladdr.strings[n];
      talk( tmp, '/ping', '/server.cgi', body,ENV);
      if (body.Count >= 2) then begin
        if (defined(body.strings[1])) and (body.strings[0] = 'PONG') then begin
          tmp := body.strings[1];
          if ExpandUrl(tmp, ip, port, path) then begin
            //相手から返されたポートは無視していることに注意
            Result := ip + ':' + ENV.Values['SERVER_PORT'] + D_PATH;
            mSERVER_ADDR := ip;
            ENV.Values['SERVER_ADDR'] := ip;
            break;
          end;
        end;
      end;
      inc(n);
    end;
  finally
    r.free;
    body.free;
  end;

end;

//------------------------------------------------
//ノードをファイルとメモリへ追加
//
procedure NodeAdd(node:string;Agent:String);
var
  s:string; n:integer;
begin
  s := node_pm.toString(node);
  if not IsOkAddNode(s) then begin
    exit;
  end;

  if not include(s) then begin
    Util_pm.lock();
    nodeTable.Add(s);    //  OK,,, Node_pm.new(s);
    SaveNode();
    Util_pm.unlock();
  end;

end;


//------------------------------------------------
// include node
// args: node
//
function include(node:string):boolean;
var
  a_:TStringList;
begin
  Result := False;
  a_ := listFromNodeFile();
  if defined(a_.Values[node]) then
    Result := True;
end;


//------------------------------------------------
// count node
//
function count():integer;
begin
  Result := (listFromNodeFile()).count;
end;


//------------------------------------------------
// ノードをメモリとファイルから削除
//
procedure remove(node:string);
var
  n:integer; s:string;
begin
  s  := toString(node);
  listFromNodeFile();
  n  := FindNodeIndex(s);
  if n >= 0 then begin
    Util_pm.lock();
    DeleteNode(n);
    SaveNode();
    Util_pm.unlock();
  end;
end;


//--------------------------------------------------
//ノードテーブルの取得（同時に無効アドレスの削除）
//
procedure Pingall(ENV:TStringList);
var
  tb:TStringList; s_:string; m,n:integer;
begin
  try
    tb := NodeList_pm.All();
    n := 0;
    m := tb.count;
    while(n < m) do begin
      s_ := tb.Strings[n];
      if not NodeList_pm.isOkAddNode(s_) then   //2004/08/02 by tzr
        remove(s_)
      else if not Node_pm.ping(s_,ENV) then
        remove(s_);                             //回答無しは削除
      m := tb.count;
      inc(n);
    end;
  finally
    //
  end;
end;


//------------------------------------------------
//ネットワークへ参加をノードへ要求する
//
function joinRequest(node:string;ENV:TStringList):boolean;
var
  ret_agent,s:string; ret:TStringList;
begin
  Result := False;
  ret := TStringList.Create;
  try
  //s := toString(node);          //通信情報だけにする
    s := node;
    Node_pm.join(s,ENV,ret);      //参加要求を送信
    ret_agent := ENV.Values['WGET_RETURN_SERVER'];
    if ret.count <= 0 then
      exit;
    if (ret.Strings[0] = 'WELCOME') then begin
      Result := True;
      NodeAdd(s,ret_agent);
      if (ret.count = 2) then begin
        s := ret.Strings[1];
        if isOkAddNode(s) then begin
          if ping(s,ENV) then begin
            NodeAdd(s,ret_agent);
          end else begin
            ErrorPrint('[joinRequest()] ' + s + ' no PONG, from ' + node );
          end;
        end;
      end;
    end;

  finally
    ret.free;

  end;

end;

//--------------------------------------------
//init
//
function init(ENV:TStringList):boolean;
var
  port,s,inode,me:string; mmx,m,n:integer; ret,initN,nodes:TStringList;
  r:TRegularExp;
begin
  //main.DPrint('INIT    (IN)');

  Result := False;

//nodes := TStringList.Create;
  ret   := TStringList.Create;
  initN := TStringList.Create;
  r     := TRegularExp.Create;

  try
    //初期ノードから１つだけPONGを返すノードを確認する.
    port := ENV.Values['SERVER_PORT'];
    split(ENV.Values['X_INIT_NODE'],'+',initN);
    m := 0;
    mmx := initN.count;
    while (m < mmx) do begin
      inode := initN.Strings[m];
      if Node_pm.ping(inode,ENV) then begin
        joinRequest(inode,ENV);
        break;
      end else begin
        remove(inode);  //2004/08/06 by tzr
      end;
      mmx := initN.count;
      inc(m);
    end;

    //自分自身をリストから削除.
    me := myself(ENV);
    if defined(me) then
      remove(me);

    //node.txtをnodeTableへ読み込み混ぜる.
    nodes := All();
    if NodeCount <= 0 then
      exit;

    //nodeコマンドで新しいノードを追加する
    m := 0;
    while m < D_RETRYSEARCH do begin
      inode := GetNode(random(NodeCount),True);
      //main.DPrint('INIT    send /node');
      talk(inode,'/node','/server.cgi',ret,ENV);
      if (ret.Count > 0)  then begin
        s := ret.Strings[0];
        if r.RegCompCut(s,':\d+/[^: ]+$',False) then begin  
          if not include(s) then begin
            joinRequest(s,ENV);    // join request and add table.
          end;
        end;
      end;
      inc(m);
    end;

    //登録されていないノードはJOINする
    //m := 0;
    //while (m < nodes.count) do begin
    //  s := nodes.strings[m];
    //  if not include(s) then
    //    NodeList_pm.joinRequest(s,ENV);
    //  inc(m);
    //end;

    //ノード制限数を超えている場合byebye処理
    //未完成


    //自分自身をリストから削除.
    me := myself(ENV);
    if defined(me) then
      remove(me);

    //最大数以上の登録済みノードは消す
    while (NodeCount() > D_NODES) do begin
      s := GetNode(random(NodeCount),True);
      Node_pm.bye(s,ENV);
      remove(s);
    end;

  finally
  //nodes.free;
    r.free;
    initN.free;
    ret.free;
    //main.DPrint('INIT    (OUT)');

  end;


end;





end.
