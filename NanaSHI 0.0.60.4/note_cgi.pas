unit note_cgi;

interface

uses
  Classes, blcksock, winsock, Synautil, SysUtils, RegularExp, lib1, windows,
  timet, NodeList_pm;

type                                                                        
  TNoteCgi = class(TObject)
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
    procedure printNote(note:string; ENV:TStringList;mother:TObject);
    procedure editForm(afile:string; arec,ENV:TStringList;mother:TObject);
    procedure printHistory(aname,atype:string; ENV:TStringList;mother:TObject);
    procedure editDialog(aname,atype:string; ENV:TStringList;mother:TObject);

  end;

implementation

uses
  Config, httpd_pl, message_pm, gateway_pm, CacheStat_pm, Signature_pm, main,
  util_pm, Cache_pm;


//
//CONSTRUCTOR
//
constructor TNoteCgi.Create(Sender:TObject);
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
destructor TNoteCgi.Destroy;
begin
  inherited;
  types.free;
  ENV.free;
end;


//-------------------------------------------------
// socket error
//
function TNoteCgi.isSockError():boolean;
begin
  result := (sock.lasterror <> 0);
end;


//-------------------------------------------------
//READ DATA
//
function TNoteCgi.ReadData(tout:integer):string;
begin
  Result := sock.RecvString(timeout);  //read one line.
end;



//-------------------------------------------------
// main loop
//
procedure TNoteCgi.Execute(sender:TObject;aSock:TTCPBlockSocket);
var
  r:TRegularExp; ans,apath,ainput,aid,tmp,num,cmd,arecord,afile:string; n,m:integer;
  arg:TStringList; query:string;
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
    gateway_pm.args(ainput,arg);

    if defined(arg.values['cmd']) then cmd := arg.values['cmd'] else cmd := '';
    if defined(arg.values['file']) then afile := arg.values['file'] else afile := '';
    if defined(arg.values['record']) then arecord := arg.values['record'] else arecord := '';

    //main.dprint('note.cgi[path|cmd]-->' + apath + '|' + cmd );

    if (cmd = 'post') and (r.RegCompCut(afile,'^note_[0-9A-F]+',False)) then begin
      post(afile,arg,ENV,mother);
      gateway_pm.print302(D_ROOT + 'note.cgi/' + str_encode(file_decode(arg.Values['file'])),ENV,mother);

    end else if (cmd = 'add') and (r.RegCompCut(afile,'^note_[0-9A-F]+',False)) then begin
      if not margeRecord(afile,arg,ENV,mother) then
        exit;
      gateway_pm.print302(D_ROOT + 'note.cgi/' + str_encode(file_decode(arg.Values['file'])),ENV,mother);

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

    end else if (apath <> '') and (not r.RegCompCut(apath,'/',False)) then begin
      if( not defined(arg.values['mode']) or (arg.values['mode'] = '')) then begin
        printNote(apath,ENV,mother);
      end else if (arg.values['mode'] = 'edit') then begin
        editDialog(apath, 'note', ENV,mother);
      end else if (arg.values['mode'] = 'history') then begin
        printHistory(apath, 'note',ENV,mother);
      end else begin
        printNote(apath,ENV,mother);
      end;

    end else begin
      gateway_pm.print404(apath,ENV,mother);

    end;


  finally
    arg.free;
    r.free;

  end;
end;



//------------------------------------------------
// printNote
//
procedure TNoteCgi.printNote(note:string;ENV:TStringList;mother:TObject);
var
  file_note:string; buf,conflict,body,ans:string; rec:TStringList;
  filesize:integer;
begin
  rec := TStringList.Create;

  try
    note := gateway_pm.escape(note);
    file_note := gateway_pm.file_encode('note',note);
    gateway_pm.touch(file_note,ENV);
    printHeader(note,ENV,mother);
    gateway_pm.readNote(file_note, buf, conflict,ENV);
    util_pm.rec(buf,rec,ENV);

    if not defined(rec.values['body']) then rec.values['body'] := '';
    body := gateway_pm.html_format(rec.values['body'],ENV);

  //ans := '<p>' + body + '</p>';
    ans := LF+'<p>' + body + '</p>'+LF;
    if defined(conflict) then ans := ans + '<p><em>'+ amessage('conflict',ENV) + '</em></p>';
    if not TServerThrd(mother).SendData(ans) then exit;

    filesize := _GetFileSize(DataPath(file_note));
    filesize := (filesize div 1024) div 1024;

    if (filesize <= D_FILELIMIT) then begin
      ans := '<form method=''post'' action=''/' + ENV.Values['SCRIPT_NAME'] + '''' + '><p>'
           + '<input type=''hidden'' name=''cmd'' value=''add'' />'
           + '<input type=''hidden'' name=''file'' value=''' + file_note + ''' />'
	   + '<input type=''submit'' value=''' + amessage('add',ENV) + ''' name=''submit'' tabindex=''1'' accesskey=''w'' />'
	   + ' <input type=''checkbox'' value=''dopost'' name=''dopost'''
	   + ' checked=''checked'' tabindex=''2'' accesskey=''s'' />'
	   + amessage('send',ENV)
           + ' <input type=''checkbox'' value=''error'' name=''error'''
	   + ' checked=''checked'' tabindex=''2'' accesskey=''e'' />'
	   + amessage('error',ENV) + '<br />'
	   + '<textarea rows=''5'' cols=''70'' name=''message'' tabindex=''8'' accesskey=''c''></textarea>'
	   + '<br /><a href=''/' + ENV.Values['SCRIPT_NAME'] + '/' + str_encode(note) + '?mode=edit''>'   + amessage('edit',ENV)+'</a>'
	   +    ' | <a href=''/' + ENV.Values['SCRIPT_NAME'] + '/' + str_encode(note) + '?mode=history''>'+ amessage('history',ENV) + '</a>'
	   + '</p></form>';
     end else begin
       ans := '<p><a href=''/' + ENV.Values['SCRIPT_NAME'] + '/' + str_encode(note) + '?mode=history''>' + amessage('history',ENV) + '</a></p>'
     end;

     ans := ans + '<form method=''get'' action=''/' + ENV.Values['SCRIPT_NAME'] + '''>'
	  + '<p><input type=''submit'' value=''' + amessage('del_file',ENV) + ''' tabindex=''9'' accesskey=''d'' />'
          + '<input type=''hidden'' name=''cmd'' value=''delete'' />'
	  + '<input type=''hidden'' name=''file'' value=''' + file_note + ''' /> '
	  + IntToStr(filesize) + amessage('mb',ENV) + '</p></form></body></html>'+LF;

     if not TServerThrd(mother).SendData(ans) then exit;

  finally
    rec.free;

  end;

end;


//-----------------------------------------------
// edit form
//
procedure TNoteCgi.editForm(afile:string; arec,ENV:TStringList;mother:TObject);
var
  body,buf:string; r:TRegularExp;
begin
  r := TRegularExp.Create;
  try
    if defined(arec.values['body']) then body := arec.values['body'] else body := '';
    body := r.RegReplace(body,'<br>',LF);
    buf := '<form method=''post'' action=''/'+ ENV.Values['SCRIPT_NAME']+'''><p>'
	 + '<input type=''hidden'' name=''cmd'' value=''post'' />'
         + '<input type=''hidden'' name=''file'' value=''' + afile + ''' />'
         + '<input type=''submit'' value='''+amessage('post',ENV)+''' name=''submit'' tabindex=''1'' accesskey=''w'' />'
	 + '<input type=''checkbox'' value=''dopost'' name=''dopost'''
	 + ' checked=''checked'' tabindex=''2'' accesskey=''s'' /> '
         + amessage('send',ENV)
	 + ' <input type=''checkbox'' value=''error'' name=''error'''
	 + ' checked=''checked'' tabindex=''2'' accesskey=''e'' />'
	 + amessage('error',ENV) + '<br />'
	 + '<textarea rows=''20'' cols=''75'' name=''body'' tabindex=''8'' accesskey=''c''>' + body + '</textarea>'
	 + '<input type=''hidden'' value=''' + arec.Values['stamp'] + ''' name=''base_stamp'' />'
	 + '<input type=''hidden'' value=''' + arec.Values['id'] + ''' name=''base_id'' />'
         + '</p></form>';
    if not TServerThrd(mother).SendData(buf) then exit;

  finally
    r.free;

  end;
end;


//------------------------------------------------
// print History
procedure TNoteCgi.printHistory(aname,atype:string; ENV:TStringList;mother:TObject);
var
  s_,afile,tmp,last,ss,ans:string; SIN:TextFile; buf,recs,ref:TStringList; m:integer;
  last_record, xstamp, base, aremove,xid,conflict,_buf:string; r:TRegularExp;
  afilesize:integer;
begin
  aname := gateway_pm.escape(aname);
  afile := file_encode(atype,aname);
  gateway_pm.touch(afile,ENV);
  if not fileExists(DataPath(afile)) then exit;

  gateway_pm.printHeader(aname,ENV,mother);
  ss := '<form method=''get'' action=''' + ENV.Values['SCRIPT_NAME'] + '''>'
      + '<p><input type=''hidden'' name=''cmd'' value=''delete'' />'
      + '<input type=''hidden'' name=''file'' value=''' + afile + ''' /></p><dl>' + LF;
  if not TServerThrd(mother).SendData(ss) then exit;

  buf  := TStringList.Create;
  recs := TStringList.Create;
  ref  := TStringList.Create;
  r    := TRegularExp.Create;
  try
    AssignFile(SIN,DataPath(afile));
    try
      Reset(SIN);
      buf.clear;
      while not Eof(SIN) do begin
        Readln2(SIN,tmp);
        buf.add(tmp);
      end;
      CloseFile(SIN);
    except
      exit;
    end;
    ref.clear;
    last := '';
    m := 0;
    while (m < buf.Count) do begin
      s_ := buf[m];
      util_pm.rec(s_,recs,ENV);
      if (recs.Count > 2) then begin
        ref.values[recs.values['stamp'] + '_' + recs.values['id']] := '0';
        if not defined(ref.values['base_stamp']) then begin
          ref.values[recs.values['stamp'] + '_' + recs.values['id']] := '1';
        end else if defined( ref.values[ recs.values['base_stamp'] + '_' + recs.values['base_id'] ]) then begin
          ss := ref.values[ recs.values['base_stamp'] + '_' + recs.values['base_id'] ];
          ss := IntToStr(StrToIntDef(ss,0)+1);
          ref.values[ recs.values['base_stamp'] + '_' + recs.values['base_id'] ] := ss;
        end;
        last := s_;
      end;
      inc(m);
    end;
    if defined(last) then begin
      util_pm.rec(last,recs,ENV);
      ref.values[recs.values['stamp'] + '_' + recs.values['id']] := '1';
    end;

    m := 0;
    while (m < buf.count) do begin
      s_ := buf[m];
      util_pm.rec(s_,recs,ENV);
      if recs.count > 2 then begin
        //ñ¢äÆê¨
        //my $xstamp = xlocaltime $rec{stamp};
        xstamp := xlocaltime(StrToFloat(recs.values['stamp']));
        if not defined(recs.values['body']) then recs.values['body'] := '';
        recs.values['body'] := gateway_pm.html_format(recs.values['body'],ENV);
        base := '';
        if defined(recs.values['base_id']) then begin
          base := copy(recs.values['base_id'], 1, 8);
          base := r.RegReplace(base,'"','&quot;');
          if defined(base) then
            base := '(<a href="#r' + base + '">&gt;&gt;' + base + ')</a>';
        end;
        aremove := '';
        if defined(recs.Values['remove_id']) and defined(recs.Values['remove_stamp']) then begin
          xid := copy(recs.values['remove_id'],1,8);
          aremove := '[['+amessage('remove',ENV) + ': <a href=''#r' + xid + '''>' + xid + '</a>]]<br />';
        end;
        xid := copy(recs.values['id'],1,8);
        if defined(ref.values[recs.Values['stamp']+'_'+recs.Values['id']]) then
          conflict := ''
        else
          conflict := ' <em>'+ amessage('conflict',ENV)+'</em>';
        ss := '<dt id=''r' + xid + '''><input type=''radio'' name=''record'' value='''+ recs.values['stamp'] + '/' + recs.values['id'] + ''' '
            + ' tabindex=''1'' accesskey=''s'' />'
            + xid + ' ' + xstamp + ' ' + base + conflict + '</dt><dd>' + recs.values['body']+ '<br />' + aremove + '<br /></dd>' + LF;
        if not TServerThrd(mother).SendData(ss) then exit;
      end;
      inc(m);
    end;
    ss := '</dl><p><input type=''submit'' value='''+ amessage('del_record',ENV) + ' tabindex=''2'' accesskey=''d'' />'
      	+ '<input type=''hidden'' name=''mode'' value=''' + atype + ''' /></p></form>';
    if not TServerThrd(mother).SendData(ss) then exit;
    gateway_pm.readNote(afile, _buf, conflict,ENV);
    util_pm.rec(_buf,recs,ENV);
    editForm(afile,recs,ENV,mother);
    afilesize := (_GetFileSize(DataPath(afile)) div 1024) div 1024;
    ss := '<form method=''get'' action=''/' + ENV.Values['SCRIPT_NAME'] + '''>'
	+ '<p><input type=''submit'' value=''' + amessage('del_file',ENV) + ''' tabindex=''9'' accesskey=''d'' />'
	+ '<input type=''hidden'' name=''cmd'' value=''delete'' />'
	+ '<input type=''hidden'' name=''file'' value=''' + afile + ''' />'
	+ ' ' + IntToStr(afilesize) + amessage('mb',ENV) + '</p></form></body></html>' + LF;
    if not TServerThrd(mother).SendData(ss) then exit;

  finally
    r.free;
    ref.free;
    recs.free;
    buf.free;

  end;






end;


//------------------------------------------------
// edit dialog (Note)
//
procedure TNoteCgi.editDialog(aname,atype:string; ENV:TStringList;mother:TObject);
var
  afile,buf,conflict,xbody,ans:string; rec:TStringList; filesize:integer;
begin
  rec := TStringList.Create;
  try
    aname := gateway_pm.escape(aname);
    afile := gateway_pm.file_encode(atype,aname);
    gateway_pm.touch(afile,ENV);
    gateway_pm.readNote(afile, buf, conflict,ENV);
    util_pm.rec(buf,rec,ENV);
    if not defined(rec.values['body']) then
      rec.values['body'] := '';
    xbody := gateway_pm.html_format(rec.values['body'],ENV);

    printHeader(aname,ENV,mother);
    ans := LF + '<p>' + xbody + '</p>' + LF;
    if not TServerThrd(mother).SendData(ans) then exit;

    if defined(conflict) then begin
      ans := '<p><em>'+amessage('conflict',ENV)+'</em></p>';
      if not TServerThrd(mother).SendData(ans) then exit;
    end;
    editForm(afile,rec,ENV,mother);

    filesize := _GetFileSize(DataPath(afile));
    filesize := ((filesize div 1024) div 1024 * 10) div 10;
    ans := '<form method=''get'' action=''/' + ENV.Values['SCRIPT_NAME'] + '/delete''>'
	 + '<p><input type=''submit'' value=''' + amessage('del_file',ENV) + ''' tabindex=''9'' accesskey=''d'' />'
	 + '<input type=''hidden'' name=''file'' value=' + afile + ' /> '
	 + IntToStr(filesize) + amessage('mb',ENV) + '</p></form></body></html>'+LF;
    if not TServerThrd(mother).SendData(ans) then exit;

  finally
    rec.free;

  end;


end;




end.
