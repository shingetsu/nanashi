unit Node_pm;

interface

uses
  Classes,blcksock,winsock,Synautil,SysUtils,RegularExp,Config,util_pm,
  NodeList_pm;

procedure talk(node,mes,path:string; ret,ENV:TStringList);
function toString(node:string):string;
function toXString(node:string):string;
function ping(node:string; ENV:TStringList):boolean;
function join(node:string; ENV:TStringList; ret:TStringList):TStringList;
function bye(node:string;ENV:TStringList):boolean;


implementation


uses
  main,lib1;


//--------------------------------------
// get body
// path := path + '/' + mes
// node + path

procedure talk(node,mes,path:string; ret,ENV:TStringList);
var
  r:TRegularExp; tmp,ip,port,apath,agent,mmm:string;
begin
  ExpandUrl2(node,ip,port,apath,agent);
  if not defined(apath) then
    apath := path;

  r := TRegularExp.create;
  mes := r.RegReplace(mes,'^[/?]','');
  if r.RegCompCut(apath,'[/?]$',False) then
    apath := apath + mes
  else
    apath := apath + '/' + mes;

  try
    tmp := ip + ':' + port + apath;
    ret.clear;
    mmm := 'talk('+tmp+')';
    wget(tmp, ret, ENV);           // azip = 1 等、未完成  ×　後で、、

  finally
    mmm := mmm + ' >> ' + copy(ret.text,1,128);
    mmm := StringReplace(mmm, #13, ',', [rfReplaceAll]);
    mmm := StringReplace(mmm, #10, ',', [rfReplaceAll]);
    dprint(mmm);
    r.free;

  end;
end;


//--------------------------------------
function toString(node:string):string;
var
  ip,port,path,agent:string;
begin
  //未完成
  Result := '';
  if ExpandUrl2(node,ip,port,path,agent) then begin
    Result := ip + ':' + port + path;
  end;
end;


//--------------------------------------
function toXString(node:string):string;
var
  ip,port,path,agent:string;
begin
  //未完成
  Result := '';
  if ExpandUrl2(node,ip,port,path,agent) then begin
    Result := ip + ':' + port + path;
  end;
end;


//--------------------------------------
function ping(node:string; ENV:TStringList):boolean;
var
  buf:TStringList; okstr,ip,port,apath,s:string;
begin
  Result := False;
//dprint('ping< '+node+' >');

  okstr := 'PONG';
  buf := TStringList.create;
  try
    talk(node,'/ping', '/server.cgi', buf, ENV);
    if (buf.Count <= 0) then begin
      exit;
    end;
    if (copy(buf.Strings[0],1,length(okstr)) = okstr) then
      s := AgentName(ENV,node);
      if not IsOkAgent(s) then begin
        Result := False;
        exit;
      end;
      Result := True;
  finally
    buf.free;
  end;
end;

//--------------------------------------
function join(node:string; ENV:TStringList; ret:TStringList):TStringList;
var
  agent,myport,port,path,mypath,ip,tmp:string; r:TRegularExp;
begin
  Result := ret;
  ExpandUrl2(node,ip,port,path,agent);
  if not defined(path) then
    path := D_PATH;
  mypath := D_PATH;         //2004/08/06 by tzr. (^^;

  myport := ENV.Values['SERVER_PORT'];

  r := TRegularExp.create;
  try
    tmp  := r.RegReplace(mypath,'^/','');  //先頭の/を削る
    talk(node,'/join/:' + myport + '+' + tmp, path, ret, ENV);
  finally
    r.free;
  end;
end;


//--------------------------------------
function bye(node:string;ENV:TStringList):boolean;
var
  agent,aport,apath,ip:string; r:TRegularExp; ret:TStringList;
begin
  Result := False;

  ExpandUrl2(node,ip,aport,apath,agent);
  if not defined(apath) then
    apath := D_PATH;

  r   := TRegularExp.create;
  ret := TStringList.create;
  try
    r.RegReplace(apath,'/','+');
    talk(node,'byte/:'+aport, apath,ret,ENV);
    if (ret.count > 0) then
      Result := (ret[0] = 'BYEBYE');
  finally
    ret.free;
    r.free;
  end;

end;


end.

