unit gateway_cgi;

interface

uses
  Classes, blcksock, winsock, Synautil, SysUtils, RegularExp, lib1, windows,
  timet, NodeList_pm;

const
  D_ROOT = '/';

type                                                                        
  TGatewayCgi = class(TObject)
  private
    timeout : integer;
    ENV:TStringList;
    Sock:TTCPBlockSocket;
    mother : TObject;
    types:TStringList;

  public
    Constructor Create(Sender:TObject);
    Destructor Destroy; override;
    function  ReadData(tout:integer):string;
    function  isSockError():boolean;
    procedure printTitle();
    procedure printMotd();
    procedure printIndex();
    procedure printChanges();
    procedure printUpdate();
    procedure searchForm(query:string);
    procedure printSearchResult(query:string);
    procedure Execute(sender:TObject; aSock:TTCPBlockSocket);

  end;


implementation


uses
  Config, httpd_pl, message_pm, gateway_pm, CacheStat_pm, Signature_pm, main,
  util_pm, Cache_pm;


//
//CONSTRUCTOR
//
constructor TGatewayCgi.Create(Sender:TObject);
begin
  inherited Create;
  timeout := D_SVR_TIMEOUT;
  ENV   := TStringList.Create;
  types := TStringList.Create;
  types.add('list');
  types.add('thread');
  types.add('note');


end;


//
//DESTRUCTOR
//
destructor TGatewayCgi.Destroy;
begin
  inherited;
  types.free;
  ENV.free;
end;


//
// socket error
//
function TGatewayCgi.isSockError():boolean;
begin
  result := (sock.lasterror <> 0);
end;


//
//READ DATA
//
function TGatewayCgi.ReadData(tout:integer):string;
begin
  Result := sock.RecvString(timeout);  //read one line.
end;


//------------------------------------------
//print Title
//
procedure TGatewayCgi.printTitle();
var
  body2:string;
begin
  printHeader(amessage('logo',ENV),ENV,mother);
  body2 := '<p>' + amessage('license',ENV) + '</p>' + LF
         + '<ul><li><em><a href=''' + D_ROOT+ 'list.cgi' + '''' + '>' + amessage('menu',ENV) + '</a></em></li>' + LF;
  if not TServerThrd(mother).SendData(body2) then exit;

  body2 := '<li><a href='+''''+ 'http://shingetsu.sourceforge.net/' +''''+ '>'
         + amessage('site',ENV)+'</a></li>'+LF
         + '<li><a href=' + '''' + D_ROOT + ENV.Values['SCRIPT_NAME']+ '/motd' + ''''+ '>' + amessage('agreement',ENV) + '</a></li></ul>'
         + '</body></html>'+LF;
  if not TServerThrd(mother).SendData(body2) then exit;

end;


//-----------------------------------------------
// print MOTD
//
procedure TGatewayCgi.printMotd();
var
  buf,tmp:string; SIN:TextFile;
begin
  buf := TServerThrd(mother).printHeader('200 OK', False)
       + 'Content-type: text/plain; charset=euc-jp' + CRLF
       + 'X-Shingetsu: ' + ENV.Values['SERVER_SOFTWARE'] + CRLF
       + CRLF;

  AssignFile(SIN, D_FILEDIR + '/' + D_MOTD);
  Reset(SIN);
  while not Eof(SIN) do begin
    Readln2(SIN,tmp);
    buf := buf + tmp + CRLF;
  end;
  closeFile(SIN);

  if not TServerThrd(mother).SendData(buf) then exit;

end;


//-------------------------------------
//
// print index page
//
procedure TGatewayCgi.printIndex();
var
  ans,s_,atype,x,y,records,size:string; stat,member:TStringList; n,m:integer;
  r:TRegularExp;
begin
  stat := TStringList.Create;
  member := TStringList.Create;
  r := TRegularExp.create;
  try
    printHeader(amessage('index',ENV),ENV,mother);
    ans := '<form method=''get'' action=''' + D_ROOT + ENV.Values['SCRIPT_NAME'] + '/delete''>'+LF;
    CacheStat_pm.list(stat);
    m := 0;
    while (m < types.count) do begin
      atype := types.Strings[m];
      ans := ans + '<h2>'+ amessage(atype,ENV) + '</h2><ul>' + LF;
      if not TServerThrd(mother).SendData(ans) then exit;

      glob(D_DATADIR+'/' + atype + '_*.dat', member);
      member.sort;
      n := 0;
      while (n < member.count) do begin
        s_ := member.Strings[n];
        s_ := r.RegReplace(s_, '^' + D_DATADIR + '/','');
        s_ := r.RegReplace(s_, '.dat$','');
        x := gateway_pm.file_decode(s_);
        y := gateway_pm.str_encode(x);
        records := stat.values[__records(s_)];
        size := IntToStr((StrToIntDef(stat.values[__size(s_)],0) div 1024) div 1024);
	ans := '<li><input type=''radio'' name=''file'' value='+ s_ + ' tabindex=''1'' accesskey=''s'' />'
	     + '<a href=''' + D_ROOT + atype + '.cgi/' + y + '''>' + x + '</a>('+records + '/' + size + amessage('mb',ENV)+')</li>' + LF;
        if not TServerThrd(mother).SendData(ans) then exit;
        inc(n);
      end;
      ans := '</ul>';
      if not TServerThrd(mother).SendData(ans) then exit;
      inc(m);
    end;

    ans := '<p><input type=''submit'' value=''' + amessage('del_file',ENV) + ''' tabindex=''2'' accesskey=''d'' /></p></form>';
    if not TServerThrd(mother).SendData(ans) then exit;
    gateway_pm.newElementForm('','','',ENV,mother);
    ans := '</body></html>'+LF;
    if not TServerThrd(mother).SendData(ans) then exit;

  finally
    r.free;
    member.free;
    stat.free;

  end;

end;



//----------------------------------------------
// print recent changes
//
procedure TGatewayCgi.printChanges();
var
  ans,s_,atype,x,y,date,records,size,tmp:string; stat,buf,stamp,a_:TStringList;
  m,n,i:integer; r:TRegularExp;
begin
  stat := TStringList.Create;
  buf  := TStringList.Create;
  stamp := TStringList.Create;
  a_ := TStringList.Create;
  r := TRegularExp.Create;
  printHeader(amessage('changes',ENV),ENV,mother);
  ans := '<form method=''get'' action=''' + ENV.Values['SCRIPT_NAME'] + '/delete''>' + LF;
  try
    CacheStat_pm.list(stat);
    m := 0;
    while (m < types.count) do begin
      atype := types.Strings[m];
      ans := '<h2>' + amessage(atype,ENV) + '</h2><ul>' + LF;
      buf.clear;
      stamp.Clear;
      glob(D_DATADIR+'/' + atype + '_*.dat',a_);
      n := 0;
      while (n < a_.count ) do begin
        s_ := a_.Strings[n];
        s_ := r.RegReplace(s_, '^' + D_DATADIR + '/','');
        s_ := r.RegReplace(s_, '.dat$','');
        x := gateway_pm.file_decode(s_);
        y := gateway_pm.str_encode(x);

        tmp := stat.Values[__stamp(s_)];
        date := gateway_pm.xlocaltime(StrToFloatDef(tmp,0));

        records := stat.Values[__records(s_)];
        if not defined(records) then records := '0';
        size := IntToStr((StrToIntDef(stat.Values[__size(s_)],0) div 1024) div 1024);
	ans := '<li><input type=''radio'' name=''file'' value=''' + s_ + ''' tabindex=''1'' accesskey=''s'' />' + date
             + ' <a href=''' + D_ROOT + atype + '.cgi/' + y + '''>' + x + '</a>(' + records + '/' + size + amessage('mb',ENV) + ')</li>' + LF;
	stamp.Values[ans] := stat.Values[__stamp(s_)];
	buf.add(ans);
        buf.sort;
        i := 0;
        ans := '';
        while (i < buf.count) do begin
          ans := ans + buf.Strings[i];
          inc(i);
        end;
        if not TServerThrd(mother).SendData(ans+'</ul>') then exit;
        inc(n);
      end;
      inc(m);
    end;
    ans := '<p><input type=''submit'' value=''' + amessage('del_file',ENV) + ''''
         + ' tabindex=''2'' accesskey=''d'' /></p></form>';
    if not TServerThrd(mother).SendData(ans) then exit;
    gateway_pm.newElementForm('','','',ENV,mother);
    ans := '</body></html>' + LF;
    if not TServerThrd(mother).SendData(ans) then exit;

  finally
    r.free;
    a_.free;
    stamp.free;
    buf.free;
    stat.free;

  end;

end;


//-------------------------------------
// print recent update
//
procedure TGatewayCgi.printUpdate();
var
  s_,atype,ans,x,y,ymd:string; stamp,stat,a_,buf,aaa:TStringList; SIN:TextFile;
  r:TRegularExp; m,n,i,ret:integer; records,size,ss:string;
begin
  stamp := TStringList.Create;
  stat  := TStringList.Create;
  a_    := TStringList.Create;
  r     := TRegularExp.create;
  buf   := TStringList.create;
  aaa   := TStringList.create;
  try
    stamp.clear;
    a_.clear;
    if FileExists(D_UPDATELIST) then begin
      AssignFile(SIN,D_UPDATELIST);
      Reset(SIN);
      while not Eof(SIN) do begin
        Readln2(SIN,s_);
        chomp(s_);
        split(s_,'<>',a_);
        if (a_.count > 2) then begin
          if r.RegCompCut(a_[2],'^(list|thread|note)_',False) then begin
            stamp.values[a_[2]] := a_[0];
          end;
        end;
      end;
      CloseFile(SIN);
    end else begin
      print404(amessage('update',ENV),ENV,mother);
      exit;
    end;

    printHeader(amessage('update',ENV),ENV,mother);
    m := 0;
    while (m < types.count) do begin
      ans := '<h2>'+amessage('type',ENV)+'</h2><ul>'+LF;
      if not TServerThrd(mother).SendData(ans) then exit;

      n := 0;
      buf.clear;
      while ( n < types.count ) do begin
        if grep('^' + types[n] + '_',stamp,aaa) then begin
          i := 0;
          while ( i < aaa.count) do begin
            s_ := aaa.Strings[i];
            x := file_decode(copy(s_,1, pos('=',s_) - 1));
            y := str_encode(x);
            ss := aaa.values[copy(s_,1, pos('=',s_) - 1)];
            ymd := gateway_pm.xlocaltime(StrToFloatDef(ss,0));
            if defined(stat.values[__records(s_)]) then
              records := stat.values[__records(s_)]
            else
              records := '?';
            if defined(stat.values[__size(s_)]) then
              size := IntToStr((StrToIntDef(stat.values[__size(s_)],0) div 1024) div 1024)
            else
              size := '?';
            ans := '<li>' + ymd + ' <a href=''' + D_ROOT + types[n] + '.cgi/' + y +'''>' + x + '</a>('
                 + records + '/'+ size + amessage('mb',ENV) + ')</li>'+LF;
            if not TServerThrd(mother).SendData(ans) then exit;
            inc(i);
          end;

          ans := '</ul>';
          if not TServerThrd(mother).SendData(ans) then exit;

        end;
        inc(n);
      end;

      inc(m);
    end;

    newElementForm('','','',ENV,mother);
    ans := '</body></html>'+LF;
    if not TServerThrd(mother).SendData(ans) then exit;

  finally
    aaa.free;
    buf.free;
    r.free;
    a_.free;
    stat.free;
    stamp.free;

  end;

end;


//-----------------------------------------------
// search form
//
procedure TGatewayCgi.searchForm(query:string);
var
  gquery,xquery,ans:string;  r:TRegularExp;
begin
  r := TRegularExp.Create;
  try
    //my $query = (@_)? $_[0]: "";
    //if defined(query) then       ñ¢äÆê¨
    //  query :=
    query := '';

    xquery := query;
    xquery := r.RegReplace(xquery,'"','&quot;',True );
    ans := '<form method=''get'' action=''/' + ENV.Values['SCRIPT_NAME']+'/search''><p>'
         + '<input name=''query'' size=''19'' value="'+ xquery+'" tabindex=''1'' accesskey=''q'' />'
	 + '<input type=''submit'' value="' + amessage('search',ENV) + '"'
         + ' name=''submit'' tabindex=''1'' accesskey=''s'' /></p></form>';
    if not TServerThrd(mother).SendData(ans) then exit;

    gquery := query;
    gquery := r.RegReplace(gquery,'\|',' OR ',True );
    gquery := r.RegReplace(gquery,'\.[+*]?',' ',True );
    gquery := r.RegReplace(gquery,'"','&quot;',True );
    ans := '<form method=''get'' action=''' + D_GOOGLE + '''><p>'
	 + '<input name=''q'' size=''19'' value="' + gquery + '" tabindex=''1'' accesskey=''g'' />'
	 + '<input type=''hidden'' name=''ie'' value=''UTF-8'' />'
	 + '<input type=''submit'' name=''google'' value="' + amessage('google',ENV) + '"'
         + ' tabindex=''1'' accesskey=''g'' /></p></form>';
    if not TServerThrd(mother).SendData(ans) then exit;


  finally
    r.free;

  end;

end;


//---------------------------------------------------
// search result
//
procedure TGatewayCgi.printSearchResult(query:string);
var
  s_,atype,afile,ans,x,y,records,size:string; stat,ret:TStringList; m,n:integer;
begin
  stat := TStringList.Create;
  ret := TStringList.Create;
  try
    printHeader(amessage('search',ENV),ENV,mother);
    if not TServerThrd(mother).SendData(LF) then exit;
    CacheStat_pm.list(stat);
    n := 0;
    while (n < types.Count) do begin
      ans := '<h2>' + amessage(types.Strings[n],ENV) + '</h2><ul>' + LF;
      cache_pm.search(atype, ret);
      m := 0;
      while (m < ret.count) do begin
        afile := ret.Strings[m];
        x := file_decode(afile);
	y := str_encode(x);
        records := stat.values[__records(afile)];
	size    := stat.values[ IntToStr((StrToIntDef(__size(afile),0) div 1024) div 1024) ];
        ans := '<li><a href=''/' + ENV.Values['SCRIPT_NAME'] + '/'
             + atype + '/' + y + '''>' + x + '</a>( ' + records + '/ ' + size
             + amessage('mb',ENV) + '</li>'+LF;
          if not TServerThrd(mother).SendData(LF) then exit;
        inc(m);
      end;
      ans := '</ul>';
      if not TServerThrd(mother).SendData(ans) then exit;
      inc(n);
    end;
    searchForm(query);
    ans := '</body></html>';
    if not TServerThrd(mother).SendData(ans) then exit;

  finally
    ret.free;
    stat.free;

  end;

end;



//-------------------------------------------------
// main loop
//
procedure TGatewayCgi.Execute(sender:TObject;aSock:TTCPBlockSocket);
var
  r:TRegularExp; ans,apath,ainput,aid,tmp,num,cmd:string; n,m:integer;
  arg:TStringList; query:string;
begin
  r := TRegularExp.Create;
  arg := TStringList.Create;
  mother := Sender;
  Sock := aSock;
  ENV.Assign(TServerThrd(Sender).ENV);

  try
    if not readQuery(apath, ainput,ENV) then begin
      gateway_pm.print403(ENV,mother);
      exit;
    end;
    gateway_pm.args(ainput,arg);

    if defined(arg.values['cmd']) then cmd := arg.values['cmd'] else cmd := '';

    if (cmd = 'new') then begin
      if not defined(arg.values['name']) then xdie(amessage('null_name',ENV),ENV,mother);
      if (r.RegCompCut(apath,'/',False)) then xdie(amessage('bad_name',ENV),ENV,mother);
      if (r.RegCompCut(apath,'\]\]',False)) then xdie(amessage('bad_name',ENV),ENV,mother);
      if not defined(arg.values['type']) then xdie(amessage('null_type',ENV),ENV,mother);
      if (r.RegCompCut(arg.values['type'],'^(list|thread|note)$',False)) then begin
        gateway_pm.print302(D_ROOT + arg.values['type']+'.cgi/' + str_encode(arg.values['name']),ENV,mother);

      end else begin
        print404(arg.values['file'],ENV,mother);
      end;

    end else if (apath = 'delete') then begin
      if not gateway_pm.checkAdmin(ENV,mother) then
        exit;
      gateway_pm.deleteDialog(arg,ENV,mother);

    end else if (cmd = 'xdelete') then begin
      if not defined(arg.values['file']) then begin
        print404(arg.values['file'],ENV,mother);
        exit;
      end else if defined(arg.Values['stamp']) and defined(arg.values['id']) then begin
        gateway_pm.deleteRecord(arg.values['file'], arg.values['stamp'], arg.values['id'],arg,ENV,mother);
      end else begin
        gateway_pm.deleteFile(arg.values['file'],ENV,mother);
      end;

    end else if (apath = '') or (apath = 'title') then begin
      printTitle();

    end else if (apath = 'list') then begin
      print302(D_ROOT + 'list.cgi',ENV,mother);

    end else if( apath = 'motd') then begin
      printMotd();

    end else if (r.RegCompCut(apath,'^(list|thread|note)/([^/]+)$',False)) then begin
      print302(D_ROOT + r.grps('$1') + '.cgi/'+str_encode(r.grps('$2')),ENV,mother);

    end else if (apath = 'new') then begin
      gateway_pm.args(ainput,arg);
      printHeader(amessage('new',ENV),ENV,mother);
      gateway_pm.newElementForm(arg.values['submit'],arg.values['type'],arg.values['name'],ENV,mother);
      ans := '</body></html>' + LF;
      if not TServerThrd(mother).SendData(ans) then exit;

    end else if (apath = 'index') then begin
      if not checkAdmin(ENV,mother) then
        exit;
      printIndex();

    end else if (apath = 'changes') then begin
      if not checkAdmin(ENV,mother) then
        exit;
      printChanges();

    end else if (apath = 'update') then begin
      if not checkAdmin(ENV,mother) then
        exit;
      printUpdate();

    end else if r.RegCompCut(apath,'^search',False) then begin
      query := r.grps('$''');
      if not checkAdmin(ENV,mother) then
        exit;
      if (defined(query) and r.RegCompCut(query,'^/(.+)',False)) then begin
        printSearchResult(query);
      end else if(defined(ainput)) and (ainput <> '') then begin
        args(ainput,arg);
        printSearchResult(arg.values['query']);
      end else begin
        printHeader(amessage('search',ENV),ENV,mother);
        searchForm(query);
        ans := '</body></html>' + LF;
        if not TServerThrd(mother).SendData(ans) then exit;
       end;

    end else if (apath = 'edittrust') then begin
      //ñ¢äÆê¨


    end else begin
      gateway_pm.print404(apath,ENV,mother);

    end;


  finally
    arg.free;
    r.free;

  end;
end;


end.

