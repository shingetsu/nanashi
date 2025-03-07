unit thread_cgi;

interface

uses
  Classes, blcksock, winsock, Synautil, SysUtils, RegularExp, lib1, windows,
  timet, NodeList_pm;

type                                                                        
  TThreadCgi = class(TObject)
  private                                                                               
    timeout : integer;
    ENV     : TStringList;
    Sock    : TTCPBlockSocket;
    mother  : TObject;
    types   : TStringList;

  public
    Constructor Create(Sender:TObject);
    Destructor Destroy; override;
    function  ReadData(tout:integer):string;
    function  isSockError():boolean;
    procedure Execute(sender:TObject; aSock:TTCPBlockSocket);
    procedure printThread(thread:string;ENV:TStringList;mother:TObject);
    procedure printAttach(thread,id,stamp,suffix:string;ENV:TStringList;mother:TObject);



  end;

implementation

uses
  Config, httpd_pl, message_pm, gateway_pm, CacheStat_pm, Signature_pm, main,
  util_pm, Cache_pm;


//
//CONSTRUCTOR
//
constructor TThreadCgi.Create(Sender:TObject);
begin
  inherited Create;
  timeout := D_SVR_TIMEOUT;
  ENV   := TStringList.Create;
  types := TStringList.Create;
  types.add('list');
  types.add('thread');
  types.add('note');


end;


//-------------------------------------------------
//DESTRUCTOR
//
destructor TThreadCgi.Destroy;
begin
  inherited;
  types.free;
  ENV.free;
end;


//-------------------------------------------------
// socket error
//
function TThreadCgi.isSockError():boolean;
begin
  result := (sock.lasterror <> 0);
end;


//-------------------------------------------------
//READ DATA
//
function TThreadCgi.ReadData(tout:integer):string;
begin
  Result := sock.RecvString(timeout);  //read one line.
end;



//-------------------------------------------------
// main loop
//
procedure TThreadCgi.Execute(sender:TObject;aSock:TTCPBlockSocket);
var
  r:TRegularExp; ans,apath,ainput,aid,tmp,num,cmd,arecord,afile:string; n,m:integer;
  arg:TStringList; astamp,asuffix,query:string;
begin
  r      := TRegularExp.Create;
  arg    := TStringList.Create;
  mother := Sender;
  Sock   := aSock;
  ENV.Assign(TServerThrd(Sender).ENV);

  try
    if not readQuery(apath, ainput,ENV) then begin
      gateway_pm.print403(ENV,mother);
      exit;
    end;
    if ( defined(ENV.Values['CONTENT_TYPE']) and
             r.RegCompCut(ENV.Values['CONTENT_TYPE'], 'multipart/form-data', False) ) then
      gateway_pm.argsFromMulti(ainput,arg)
    else
      gateway_pm.args(ainput,arg);

    if defined(arg.values['cmd']) then cmd := arg.values['cmd'] else cmd := '';
    if defined(arg.values['file']) then afile := arg.values['file'] else afile := '';
    if defined(arg.values['record']) then arecord := arg.values['record'] else arecord := '';

    //main.dprint('thread.cgi[path|cmd]-->' + apath + '|' + cmd );

    if (cmd = 'post') and (r.RegCompCut(afile,'^thread_[0-9A-F]+$',False)) then begin
      aid := gateway_pm.post(afile,arg,ENV,mother);
      gateway_pm.print302(D_ROOT + 'thread.cgi/' + str_encode(file_decode(arg.Values['file']))+'#r'+aid,ENV,mother);

    end else if (cmd = 'check') then begin
      gateway_pm.checkSign(arg,ENV,mother);

    end else if (cmd = 'delete') then begin
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

    end else if (apath <> '') and (not (r.RegCompCut(apath,'/',False)) ) then begin
      printThread(apath,ENV,mother);

    end else if (r.RegCompCut(apath,'^([^/]+)/([0-9a-f]{32})/(\d+)\.(.*)',False)) then begin
      afile   := r.grps('$1');
      astamp  := r.grps('$2');
      aid     := r.grps('$3');
      asuffix := r.grps('$4');
      printAttach(afile,astamp,aid,asuffix,ENV,mother);

    end else begin
      gateway_pm.print404(apath,ENV,mother);

    end;

  finally
    arg.free;
    r.free;

  end;
end;



//-----------------------------------------------------------------
//
// print Thread
//
procedure TThreadCgi.printThread(thread:string;ENV:TStringList;mother:TObject);
var
  buf,xstamp,mail,file_thread,tmp:string; SIN:File; fff,rec:TStringList;
  count,size:integer; r:TRegularExp; aattach,acheck,aremove:string;
  xid:string; afilesize,n,k,m: integer; achecked, areadonly, xx : string;

begin
  rec  := TStringList.Create;
  fff  := TStringList.Create;
  r := TRegularExp.Create;

  thread := escape(thread);
  file_thread := file_encode('thread',thread);
  touch(file_thread,ENV);

  try
    if not FileExists(DataPath(file_thread)) then
      exit;

    fff.LoadFromFile(DataPath(file_thread));
    printHeader(thread,ENV,mother);
    buf := '<form method=''get'' action=''/' + ENV.Values['SCRIPT_NAME'] + '''>'
	 + '<p><input type=''hidden'' name=''cmd'' value=''delete'' />'
         + '<input type=''hidden'' name=''file'' value=''' +file_thread + '''  /></p><dl>' + LF;
    if not TServerThrd(mother).SendData(buf) then exit;

    m := 0;
    count := 0;
    while (m < fff.Count) do begin
      inc(count);
      tmp := fff.Strings[m];
      util_pm.rec(tmp,rec,ENV);
      if rec.count >= D_OVER_FIELD then begin
        xstamp := gateway_pm.xlocaltime(StrToFloatDef(rec.values['stamp'],0));
        if((not defined(rec.values['name']) or (rec.values['name'] = ''))) then
          rec.values['name'] := amessage('anonymous',ENV);

        mail := '';
        if(defined(rec.values['mail'])) then
          mail := rec.values['mail'];
        if(not defined(rec.values['body'])) then begin
          rec.values['body']  := '';
        end else begin
          rec.values['body'] := gateway_pm.html_format(rec.Values['body'],ENV);
          if D_REDIRECT then
            rec.values['body'] := r.RegReplace(rec.values['body'],'<a href=''http://shingetsu\.p2p/','<a href=''/',True);
        end;

        aattach := '';
        acheck  := '';
        aremove := '';
        if defined(rec.values['attach']) then begin
          aattach := rec.values['attach'];
          size := StrToInt(FloatToStr( trunc(length(aattach) / 4 * 3 / 1024)));
          aattach := '<a href='''+D_ROOT+ENV.Values['SCRIPT_NAME']+'/'
                   + str_encode(thread) + '/' + rec.values['id'] + '/' + rec.values['stamp'] + '.' + rec.values['suffix'] + '''>'
                   + rec.values['stamp'] + '.' + rec.values['suffix'] + '</a> (' + IntToStr(size) + amessage('kb',ENV)+')';

        end;
        if defined(rec.Values['pubkey']) then begin
          acheck := '<a href='''+D_ROOT+ENV.Values['SCRIPT_NAME'] + '?cmd=check&amp;'
                  + 'file=' + file_encode('thread', thread) + '&amp;'
                  + 'stamp='+rec.values['stamp'] + '&amp;id=' + rec.values['id']+ '''>'
                  + Signature_pm.pubkey2trip(rec.values['pubkey']) + '</a>';

        end;
        if (defined(rec.values['remove_id']) and defined(rec.values['remove_stamp'])) then begin
          xid := copy(rec.values['remove_id'], 1, 8);
//        aremove := '[[' + amessage('remove',ENV) + ': <a href=''' + '#r' + xid + '</a>]]<br/>';
          aremove := '[[' + amessage('remove',ENV) + ': <a href=''' + '#r' + xid + '''>' + xid + '</a>]]<br/>';
        end;
        xid := copy(rec.Values['id'],1,8);
        buf := '<dt id=''r'+ xid + '''><input type=''radio'' name=''record'' value='''
             + rec.values['stamp']+'/' + rec.values['id'] + ''''
             + ' tabindex=''1'' accesskey=''s'' />'
	     + xid + ' <span class=''name''>' + rec.values['name'] + '</span> '
	     + mail + ' ' + acheck + ' ' + xstamp + ' ' + aattach + '</dt><dd>'
             + rec.values['body']+'<br />' + aremove + '<br /></dd>'+LF;
        if not TServerThrd(mother).SendData(buf) then exit;

      end;  // end of if rec.count >= D_OVER_FIELD then begin
      inc(m);
    end; // end of while not Eof(SIN)
    fff.clear;

    buf := '</dl><p><input type=''submit'' value=''' + amessage('del_record',ENV) + '''' + ' tabindex=''2'' accesskey=''d'' />'
         + '<input type=''hidden'' name=''mode'' value=''thread'' /></p></form>';
    if not TServerThrd(mother).SendData(buf) then exit;

    afilesize := _GetFileSize(DataPath(file_thread));
    afilesize := (afilesize div 1024 div 1024*10) div 10;
    if (count > 0) then achecked := 'checked="checked"' else achecked := '';
    if copy(ENV.Values['REMOTE_ADDR'],1,length(D_ADMINADDR)) = D_ADMINADDR then
      areadonly := ''
    else
      areadonly := 'readonly="readonly"';

    if (afilesize <= D_FILELIMIT) then begin
      buf := '<form method=''post'' action='''+D_ROOT+ENV.values['SCRIPT_NAME'] + ''' enctype=''multipart/form-data''><p>'
           + '<input type=''hidden'' value=''post'' name=''cmd'' />'
           + '<input type=''hidden'' value=''' + file_thread + ''' name=''file'' />'
           + '<input type=''submit'' value=''' + amessage('post',ENV) + ''' name=''submit'' tabindex=''1'' accesskey=''w'' />'
	   + ' <input type=''checkbox'' value=''dopost'' name=''dopost'''
	   + ' ' + achecked +' tabindex=''2'' accesskey=''s'' />'
           + amessage('send',ENV)
	   + ' <input type=''checkbox'' value=''error'' name=''error'''
	   + ' checked=''checked'' tabindex=''2'' accesskey=''e'' />'
	   + amessage('error',ENV) + '<br />'
	   + ' ' + amessage('name',ENV) + ':<input name=''name'' size=''15'' value='''' tabindex=''3'' accesskey=''n'' />'
           + ' ' + amessage('mail',ENV) + ':<input name=''mail'' size=''15'' value='''' tabindex=''4'' accesskey=''m'' />'
	   + ' ' + amessage('signature',ENV) + ':<input type=''password'' name=''passwd'' size=''15'' ' + areadonly + ' value='''' tabindex=''5'' accesskey=''p'' /><br />'
	   + ' ' + amessage('attach',ENV) + ':<input type=''file'' name=''attach'' size=''19'' value='''' tabindex=''6'' accesskey=''a'' />'
	   + ' ' + amessage('suffix',ENV) + ':<select name=''suffix'' size=''1'' tabindex=''7''>'
	   + '<option>AUTO</option>';
      if not TServerThrd(mother).SendData(buf) then exit;

        mimeType.sort;
        buf := '';
        for n := 1 to mimeType.Count do begin
          xx := mimeType.Strings[n-1];
          k := pos('=',xx);
          if (k > 0) then begin
            xx := copy(xx,1,k-1);
            buf := buf + '<option>' + xx + '</option>';
          end;
        end;
        if not TServerThrd(mother).SendData(buf) then exit;

	buf := '</select> (' + amessage('limit',ENV) +': '+ IntToStr(D_FILELIMIT) + amessage('mb',ENV) + ')<br />'
	     + '<textarea rows=''5'' cols=''70'' name=''body'' tabindex=''8'' accesskey=''c''></textarea>'
	     + '</p></form>';
        if not TServerThrd(mother).SendData(buf) then exit;

    end; // end of if (afilesize <= D_FILELIMIT) then begin

    buf := '<form method=''get'' action=''/' + ENV.Values['SCRIPT_NAME'] + '''>'
	 + '<p><input type=''submit'' value=''' + amessage('del_file',ENV)+ ''' tabindex=''9'' accesskey=''d'' />'
         + '<input type=''hidden'' name=''cmd'' value=''delete'' />'
         + '<input type=''hidden'' name=''file'' value=''' + file_thread + ''' />'
	 + ' ' + IntToStr(afilesize) + amessage('mb',ENV)+'</p></form></body></html>'+LF;
    if not TServerThrd(mother).SendData(buf) then exit;

  finally
    r.free;
    fff.free;
    rec.free;

  end;

end;


(*
//-----------------------------------------------------------------
//
// print Thread
//
procedure TThreadCgi.printThread(thread:string;ENV:TStringList;mother:TObject);
var
  buf,xstamp,mail,file_thread,tmp:string; SIN:File; rec:TStringList;
  count,size:integer; r:TRegularExp; aattach,acheck,aremove:string;
  xid:string; afilesize,n,k: integer; achecked, areadonly, xx : string;

begin
  rec  := TStringList.Create;
  r := TRegularExp.Create;

  thread := escape(thread);
  file_thread := file_encode('thread',thread);
  touch(file_thread,ENV);

  try
    AssignFile(SIN, DataPath(file_thread));

    if not FileExists(DataPath(file_thread)) then
      exit;

    Reset(SIN,1);
    printHeader(thread,ENV,mother);
    buf := '<form method=''get'' action=''/' + ENV.Values['SCRIPT_NAME'] + '''>'
	 + '<p><input type=''hidden'' name=''cmd'' value=''delete'' />'
         + '<input type=''hidden'' name=''file'' value=''' +file_thread + '''  /></p><dl>' + LF;
    if not TServerThrd(mother).SendData(buf) then exit;

    count := 0;
    while not Eof(SIN) do begin
      inc(count);
      Readln3(SIN,tmp);
      util_pm.rec(tmp,rec);
      if rec.count >= D_OVER_FIELD then begin
        xstamp := gateway_pm.xlocaltime(StrToFloatDef(rec.values['stamp'],0));
        if((not defined(rec.values['name']) or (rec.values['name'] = ''))) then
          rec.values['name'] := amessage('anonymous',ENV);

        mail := '';
        if(defined(rec.values['mail'])) then
          mail := rec.values['mail'];
        if(not defined(rec.values['body'])) then begin
          rec.values['body']  := '';
        end else begin
          rec.values['body'] := gateway_pm.html_format(rec.Values['body'],ENV);
          if D_REDIRECT then
            rec.values['body'] := r.RegReplace(rec.values['body'],'<a href=''http://shingetsu\.p2p/','<a href=''/',True);
        end;

        aattach := '';
        acheck  := '';
        aremove := '';
        if defined(rec.values['attach']) then begin
          aattach := rec.values['attach'];
          size := StrToInt(FloatToStr( trunc(length(aattach) / 4 * 3 / 1024)));
          aattach := '<a href='''+D_ROOT+ENV.Values['SCRIPT_NAME']+'/'
                   + str_encode(thread) + '/' + rec.values['id'] + '/' + rec.values['stamp'] + '.' + rec.values['suffix'] + '''>'
                   + rec.values['stamp'] + '.' + rec.values['suffix'] + '</a> (' + IntToStr(size) + amessage('kb',ENV)+')';

        end;
        if defined(rec.Values['pubkey']) then begin
          acheck := '<a href='''+D_ROOT+ENV.Values['SCRIPT_NAME'] + '?cmd=check&amp;'
                  + 'file=' + file_encode('thread', thread) + '&amp;'
                  + 'stamp='+rec.values['stamp'] + '&amp;id=' + rec.values['id']+ '''>'
                  + Signature_pm.pubkey2trip(rec.values['pubkey']) + '</a>';

        end;
        if (defined(rec.values['remove_id']) and defined(rec.values['remove_stamp'])) then begin
          xid := copy(rec.values['remove_id'], 1, 8);
//        aremove := '[[' + amessage('remove',ENV) + ': <a href=''' + '#r' + xid + '</a>]]<br/>';
          aremove := '[[' + amessage('remove',ENV) + ': <a href=''' + '#r' + xid + '''>' + xid + '</a>]]<br/>';
        end;
        xid := copy(rec.Values['id'],1,8);
        buf := '<dt id=''r'+ xid + '''><input type=''radio'' name=''record'' value='''
             + rec.values['stamp']+'/' + rec.values['id'] + ''''
             + ' tabindex=''1'' accesskey=''s'' />'
	     + xid + ' <span class=''name''>' + rec.values['name'] + '</span> '
	     + mail + ' ' + acheck + ' ' + xstamp + ' ' + aattach + '</dt><dd>'
             + rec.values['body']+'<br />' + aremove + '<br /></dd>'+LF;
        if not TServerThrd(mother).SendData(buf) then exit;

      end;  // end of if rec.count >= D_OVER_FIELD then begin
    end; // end of while not Eof(SIN)
    closeFile(SIN);

    buf := '</dl><p><input type=''submit'' value=''' + amessage('del_record',ENV) + '''' + ' tabindex=''2'' accesskey=''d'' />'
         + '<input type=''hidden'' name=''mode'' value=''thread'' /></p></form>';
    if not TServerThrd(mother).SendData(buf) then exit;

    afilesize := _GetFileSize(DataPath(file_thread));
    afilesize := (afilesize div 1024 div 1024*10) div 10;
    if (count > 0) then achecked := 'checked="checked"' else achecked := '';
    if copy(ENV.Values['REMOTE_ADDR'],1,length(D_ADMINADDR)) = D_ADMINADDR then
      areadonly := ''
    else
      areadonly := 'readonly="readonly"';

    if (afilesize <= D_FILELIMIT) then begin
      buf := '<form method=''post'' action='''+D_ROOT+ENV.values['SCRIPT_NAME'] + ''' enctype=''multipart/form-data''><p>'
           + '<input type=''hidden'' value=''post'' name=''cmd'' />'
           + '<input type=''hidden'' value=''' + file_thread + ''' name=''file'' />'
           + '<input type=''submit'' value=''' + amessage('post',ENV) + ''' name=''submit'' tabindex=''1'' accesskey=''w'' />'
	   + ' <input type=''checkbox'' value=''dopost'' name=''dopost'''
	   + ' ' + achecked +' tabindex=''2'' accesskey=''s'' />'
           + amessage('send',ENV)
	   + ' <input type=''checkbox'' value=''error'' name=''error'''
	   + ' checked=''checked'' tabindex=''2'' accesskey=''e'' />'
	   + amessage('error',ENV) + '<br />'
	   + ' ' + amessage('name',ENV) + ':<input name=''name'' size=''15'' value='''' tabindex=''3'' accesskey=''n'' />'
           + ' ' + amessage('mail',ENV) + ':<input name=''mail'' size=''15'' value='''' tabindex=''4'' accesskey=''m'' />'
	   + ' ' + amessage('signature',ENV) + ':<input type=''password'' name=''passwd'' size=''15'' ' + areadonly + ' value='''' tabindex=''5'' accesskey=''p'' /><br />'
	   + ' ' + amessage('attach',ENV) + ':<input type=''file'' name=''attach'' size=''19'' value='''' tabindex=''6'' accesskey=''a'' />'
	   + ' ' + amessage('suffix',ENV) + ':<select name=''suffix'' size=''1'' tabindex=''7''>'
	   + '<option>AUTO</option>';
      if not TServerThrd(mother).SendData(buf) then exit;

        mimeType.sort;
        buf := '';
        for n := 1 to mimeType.Count do begin
          xx := mimeType.Strings[n-1];
          k := pos('=',xx);
          if (k > 0) then begin
            xx := copy(xx,1,k-1);
            buf := buf + '<option>' + xx + '</option>';
          end;
        end;
        if not TServerThrd(mother).SendData(buf) then exit;

	buf := '</select> (' + amessage('limit',ENV) +': '+ IntToStr(D_FILELIMIT) + amessage('mb',ENV) + ')<br />'
	     + '<textarea rows=''5'' cols=''70'' name=''body'' tabindex=''8'' accesskey=''c''></textarea>'
	     + '</p></form>';
        if not TServerThrd(mother).SendData(buf) then exit;

    end; // end of if (afilesize <= D_FILELIMIT) then begin

    buf := '<form method=''get'' action=''/' + ENV.Values['SCRIPT_NAME'] + '''>'
	 + '<p><input type=''submit'' value=''' + amessage('del_file',ENV)+ ''' tabindex=''9'' accesskey=''d'' />'
         + '<input type=''hidden'' name=''cmd'' value=''delete'' />'
         + '<input type=''hidden'' name=''file'' value=''' + file_thread + ''' />'
	 + ' ' + IntToStr(afilesize) + amessage('mb',ENV)+'</p></form></body></html>'+LF;
    if not TServerThrd(mother).SendData(buf) then exit;

  finally
    r.free;
    rec.free;
  end;
end;

*)




//------------------------------------------------
// Print Attach
//
procedure TThreadCgi.printAttach(thread,id,stamp,suffix:string;ENV:TStringList;mother:TObject);
var
  ver,atype,fname,value,tmp,buf:string; SIN:File; fff,rec:TStringList; m:integer;
begin
  thread := gateway_pm.file_encode('thread', thread);
  fname  := DataPath(thread);
  ver    := D_VER;
  suffix := lowercase(suffix);
  atype  := config.mimeType.Values[suffix];
  if not defined(atype) then atype := 'text/plain';

  rec := TStringList.Create;
  fff := TStringList.Create;

  try
    value := '';
    gateway_pm.touch(thread,ENV);

    fff.LoadFromFile(fname);
    try
      m := 0;
      while (m < fff.count) do begin
        tmp := fff.Strings[m];
        util_pm.rec(tmp,rec,ENV);
        if defined(rec.values['attach']) and (rec.values['stamp'] = stamp)
              and (rec.values['id'] = id) then begin
          value := rec.Values['attach'];
          break;
        end;
        inc(m);
      end;
      fff.clear;
    except
      //
    end;

    if defined(value) then begin
      buf := TServerThrd(mother).printHeader('200 OK', False)
           + 'Content-Type: ' + atype + CRLF
           + 'X-Shingetsu: ' + ENV.Values['SERVER_SOFTWARE'] + CRLF
           + CRLF
           + Signature_pm.base64decode(value);

      if not TServerThrd(mother).SendData(buf) then exit;
    end else begin
      print404(thread,ENV,mother);
    end;

  finally
    fff.free;
    rec.free;

  end;
end;


(*
//------------------------------------------------
// Print Attach
//
procedure TThreadCgi.printAttach(thread,id,stamp,suffix:string;ENV:TStringList;mother:TObject);
var
  ver,atype,fname,value,tmp,buf:string; SIN:File; rec:TStringList;
begin
  thread := gateway_pm.file_encode('thread', thread);
  fname  := DataPath(thread);
  ver    := D_VER;
  suffix := lowercase(suffix);
  atype  := config.mimeType.Values[suffix];
  if not defined(atype) then atype := 'text/plain';

  rec := TStringList.Create;

  try
    value := '';
    gateway_pm.touch(thread,ENV);
    AssignFile(SIN, fname);
    try
      Reset(SIN,1);
      while not Eof(SIN) do begin
        Readln3(SIN,tmp);
        util_pm.rec(tmp,rec);

        if defined(rec.values['attach']) and (rec.values['stamp'] = stamp)
              and (rec.values['id'] = id) then begin
          value := rec.Values['attach'];
          break;
        end;

      end;
      CloseFile(SIN);
    except
      //
    end;

    if defined(value) then begin
      buf := TServerThrd(mother).printHeader('200 OK', False)
           + 'Content-Type: ' + atype + CRLF
           + 'X-Shingetsu: ' + ENV.Values['SERVER_SOFTWARE'] + CRLF
           + CRLF
           + Signature_pm.base64decode(value);

      if not TServerThrd(mother).SendData(buf) then exit;
    end else begin
      print404(thread,ENV,mother);
    end;

  finally
    rec.free;

  end;
end;
*)


end.
