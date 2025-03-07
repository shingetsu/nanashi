unit list_cgi;

interface

uses
  Classes, blcksock, winsock, Synautil, SysUtils, RegularExp, lib1, windows,
  timet, NodeList_pm;

const
  D_ROOT = '/';

type                                                                        
//TStringListSortCompare = function(List: TStringList; Index1, Index2: Integer): Integer;
  TListCgi = class(TObject)
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
    procedure printList(list:string;ENV:TStringList;mother:TObject);

  end;


implementation


uses
  Config, httpd_pl, message_pm, gateway_pm, CacheStat_pm, Signature_pm, main,
  util_pm, Cache_pm;


//-------------------------------------------------
//CONSTRUCTOR
//
constructor TListCgi.Create(Sender:TObject);
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
destructor TListCgi.Destroy;
begin
  inherited;
  types.free;
  ENV.free;
end;


//-------------------------------------------------
// socket error
//
function TListCgi.isSockError():boolean;
begin
  result := (sock.lasterror <> 0);
end;


//-------------------------------------------------
//READ DATA
//
function TListCgi.ReadData(tout:integer):string;
begin
  Result := sock.RecvString(timeout);  //read one line.
end;


//-------------------------------------------------
// main loop
//
procedure TListCgi.Execute(sender:TObject;aSock:TTCPBlockSocket);
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

    if (cmd = 'new') and (r.RegCompCut(afile,'^list_[0-9A-F]+$',False)) then begin
      if not gateway_pm.newElement(afile,arg,ENV,mother) then exit;
      gateway_pm.print302(D_ROOT + 'list.cgi/' + str_encode(file_decode(arg.Values['file'])),ENV,mother);

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

    end else if (apath = '') then begin
      printList(D_MENUFILE,ENV,mother);

    end else if (not r.RegCompCut(apath,'/',False)) then begin
      printList(apath,ENV,mother);

    end else begin
      gateway_pm.print404(apath,ENV,mother);

    end;

  finally
    arg.free;
    r.free;

  end;
end;

//------------------------------------------------------------
function comp1(List:TStringList;Index1,Index2:Integer):integer;
begin
  if (List.Strings[Index1] = List.Strings[Index2]) then begin
    Result := 0;
    exit;
  end else if (List.Strings[Index1] > List.Strings[Index2]) then begin
    Result := -1;
    exit;
  end else begin
    Result := 1;
    exit;
  end;

end;

//------------------------------------------------------------
//
// print list
//
procedure TListCgi.printList(list:string;ENV:TStringList;mother:TObject);
var
  buf,buffer,astamp, file_list,tmp:string; SIN:File; bufs,stat,fff:TStringList;
  count,asize:integer; rec:TStringList; file_child,afile:string;
  arecords,str,achild,check,checked, anchor : string; filesize:Integer;
  r:TRegularExp; m:integer;

begin
  list := gateway_pm.escape(list);
  file_list := gateway_pm.file_encode('list',list);
  gateway_pm.touch(file_list,ENV);
  gateway_pm.printHeader(list,ENV,mother);
  buf := '<form method=''get'' action=''' +D_ROOT+ENV.Values['SCRIPT_NAME'] + '''>'
       + '<p><input type=''hidden'' name=''cmd'' value=''delete'' />'
       + '<input type=''hidden'' name=''file'' value=''' + file_list + ''' />'
       + '</p><ul>' + LF;
  if not TServerThrd(mother).SendData(buf) then exit;

  r    := TRegularExp.Create;
  stat := TStringList.Create;
  rec  := TStringList.Create;
  fff  := TStringList.Create;
  bufs := TStringList.Create;

  CacheStat_pm.list(stat);

  if not FileExists(DataPath(file_list)) then exit;
  try
    buffer := '';
    CacheStat_pm.list(stat);

    fff.LoadFromFile(DataPath(file_list));     //list_ファイルの読み込み
    count := 0;
    m := 0;
    while m < fff.count do begin
      inc(count);
      tmp := fff.Strings[m];
      if defined(tmp) then begin
        util_pm.rec(tmp,rec,ENV);
        if rec.count >= D_OVER_FIELD then begin
          if not defined(rec.values['body']) then rec.values['body'] := '';
          astamp := rec.Values['stamp'];
          if defined(rec.values['type']) then begin
            file_child := file_encode(rec.Values['type'], rec.Values['link']);
            afile := DataPath(file_child);
            arecords := '0';
            asize := 0;
            if (_GetFileSize(afile) > 0) then begin
              //タイムスタンプ、レコード件数、サイズはstat.txtの内容
              astamp   := stat.values[__stamp(file_child)];
              arecords := stat.values[__records(file_child)];
              asize    := StrToIntDef(stat.values[__size(file_child)],0);
              asize    := (asize div 1024) div 1024;
            end;
            if (arecords <= '0') then arecords := '?';
            str := gateway_pm.xlocaltime(StrToFloatDef(astamp,0));
            achild := str_encode(rec.Values['link']);
            anchor := rec.values['link'];
            if (r.RegCompCut(rec.values['type'],'^(list|thread|note)$',False)) then
              anchor := '<a href='''+D_ROOT+rec.values['type']+'.cgi/' + achild + '''>'+rec.Values['link']+'</a>(';
            buf := '<li><input type=''radio'' name=''record'' value='''+ rec.Values['stamp']+'/'+ rec.Values['id']+ ''''
                 + ' tabindex=''1'' accesskey=''s'' />'
                 + str + ': '+ anchor
                 + amessage(rec.values['type'],ENV)+'/' + arecords + '/' + IntToStr(asize) + amessage('mb',ENV) + rec.Values['body'] + ')</li>';

          end else if defined(rec.values['remove_stamp']) then begin
            astamp := rec.values['remove_stamp'];
            str := gateway_pm.xlocaltime(StrToFloatDef(astamp,0));
            check := '';
            if not defined(rec.values['name']) then
              rec.values['name'] := '';
            if defined(rec.values['pubkey']) then begin
              check := '<a href=''' +D_ROOT+ENV.Values['SCRIPT_NAME']+'?cmd=check&amp;'
                     + 'file=' + file_encode('list', list) + '&amp;'
                     + 'stamp='+ rec.values['stamp'] + '&amp;id=' + rec.values['id'] + '''>'
                     + Signature_pm.pubkey2trip(rec.Values['pubkey']) + '</a>';
            end;
            buf := '<li><input type=''radio'' name=''record'' value=''' + rec.Values['stamp'] + '/'+ rec.Values['id']+ ''''
                 + ' tabindex=''1'' accesskey=''s'' />'
                 + str + ':' + rec.values['name'] + ' ' + check + ' ' + amessage('remove',ENV) + ': ' + rec.Values['body']+ '</li>'+LF;
          end;
          bufs.add(astamp + buf);

        end;  // end of if rec.count >= D_OVER_FIELD then begin
      end else begin
        ErrorPrint('list.cgi : bad record in ' + DataPath(file_list));
      end;
      inc(m);
    end;  // end of while not Eof(SIN) do begin
    fff.clear;

    bufs.CustomSort(comp1);      // 2004/08/06 by neko
    m := 0;
    while (m < bufs.count ) do begin
      buf := copy(bufs.Strings[m],11,length(bufs.Strings[m]));
      bufs.Strings[m] := buf;
      inc(m);
    end;
    if not TServerThrd(mother).SendData(bufs.text) then exit;


    buf := '</ul><p><input type=''submit'' value=''' + amessage('del_record',ENV) + '''' + ' tabindex=''2'' accesskey=''d'' />'
	 + '<input type=''hidden'' name=''mode'' value=''list'' /></p></form>';
    if not TServerThrd(mother).SendData(buf) then exit;

    filesize := _GetFileSize(DataPath(file_list));
    filesize := (Filesize div 1024) div 1024;
    if (count > 0) then checked := 'checked=''checked''' else checked :=  '';
    if (filesize <= D_FILELIMIT) then begin
      //未完成
      gateway_pm.newElementForm(file_list, checked, '1',ENV,mother);
    end;

     buf := '<form action='''+D_ROOT+ENV.Values['SCRIPT_NAME'] + '''>'
	  + '<p><input type=''submit'' value=''' + amessage('del_file',ENV) + '''' + ' tabindex=''6'' accesskey=''d'' />'
          + '<input type=''hidden'' name=''cmd'' value=''delete'' />'
	  + '<input type=''hidden'' name=''file'' value='''+ file_list+''''+' />'
	  + ' ' + IntToStr(filesize) + amessage('mb',ENV)+ '</p></form></body></html>'+LF;
    if not TServerThrd(mother).SendData(buf) then exit;

  finally
    bufs.free;
    fff.free;
    rec.free;
    stat.free;
    r.free;

  end;

end;


(*
//------------------------------------------------------------
//
// print list
//
procedure TListCgi.printList(list:string;ENV:TStringList;mother:TObject);
var
  buf,buffer,astamp, file_list,tmp:string; SIN:File; bufs,stat:TStringList;
  count,asize:integer; rec:TStringList; file_child,afile:string;
  arecords,str,achild,check,checked, anchor : string; filesize:Integer;
  r:TRegularExp;

begin
  list := gateway_pm.escape(list);
  file_list := gateway_pm.file_encode('list',list);
  gateway_pm.touch(file_list,ENV);
  gateway_pm.printHeader(list,ENV,mother);
  buf := '<form method=''get'' action=''' +D_ROOT+ENV.Values['SCRIPT_NAME'] + '''>'
       + '<p><input type=''hidden'' name=''cmd'' value=''delete'' />'
       + '<input type=''hidden'' name=''file'' value=''' + file_list + ''' />'
       + '</p><ul>' + LF;
  if not TServerThrd(mother).SendData(buf) then exit;

  r    := TRegularExp.Create;
  stat := TStringList.Create;
  bufs := TStringList.Create;
  rec  := TStringList.Create;
  CacheStat_pm.list(stat);
  if not FileExists(DataPath(file_list)) then exit;
  AssignFile(SIN, DataPath(file_list));
  try
    buffer := '';
    CacheStat_pm.list(stat);
    count := 0;
    bufs.clear;
    Reset(SIN,1);
    while not Eof(SIN) do begin
      inc(count);
      Readln3(SIN,tmp);
      util_pm.rec(tmp,rec);
      if rec.count >= D_OVER_FIELD then begin
        if not defined(rec.values['body']) then rec.values['body'] := '';
        astamp := rec.Values['stamp'];
        if defined(rec.values['type']) then begin
          file_child := file_encode(rec.Values['type'], rec.Values['link']);
          afile := DataPath(file_child);
          arecords := '0';
          asize := 0;
          if (_GetFileSize(afile) > 0) then begin
            astamp   := stat.values[__stamp(file_child)];
            arecords := stat.values[__records(file_child)];
            asize    := StrToIntDef(stat.values[__size(file_child)],0);
            asize    := (asize div 1024) div 1024;
          end;
          if (arecords <= '0') then arecords := '?';
          str := gateway_pm.xlocaltime(StrToFloatDef(astamp,0));
          achild := str_encode(rec.Values['link']);
          anchor := rec.values['link'];
          if (r.RegCompCut(rec.values['type'],'^(list|thread|note)$',False)) then
            anchor := '<a href='''+D_ROOT+rec.values['type']+'.cgi/' + achild + '''>'+rec.Values['link']+'</a>(';
	  buf := '<li><input type=''radio'' name=''record'' value='''+ rec.Values['stamp']+'/'+ rec.Values['id']+ ''''
	       + ' tabindex=''1'' accesskey=''s'' />'
	       + str + ': '+ anchor
	       + amessage(rec.values['type'],ENV)+'/' + arecords + '/' + IntToStr(asize) + amessage('mb',ENV) + rec.Values['body'] + ')</li>';
        end else if defined(rec.values['remove_stamp']) then begin
          astamp := rec.values['remove_stamp'];
          str := gateway_pm.xlocaltime(StrToFloatDef(astamp,0));
          check := '';
          if not defined(rec.values['name']) then
            rec.values['name'] := '';
          if defined(rec.values['pubkey']) then begin
            check := '<a href=''' +D_ROOT+ENV.Values['SCRIPT_NAME']+'?cmd=check&amp;'
		   + 'file=' + file_encode('list', list) + '&amp;'
		   + 'stamp='+ rec.values['stamp'] + '&amp;id=' + rec.values['id'] + '''>'
		   + Signature_pm.pubkey2trip(rec.Values['pubkey']) + '</a>';
          end;
	  buf := '<li><input type=''radio'' name=''record'' value=''' + rec.Values['stamp'] + '/'+ rec.Values['id']+ ''''
	       + ' tabindex=''1'' accesskey=''s'' />'
	       + str + ':' + rec.values['name'] + ' ' + check + ' ' + amessage('remove',ENV) + ': ' + rec.Values['body']+ '</li>'+LF;
        end;
        bufs.add(buf);
      end;  // end of if rec.count >= D_OVER_FIELD then begin
    end;  // end of while not Eof(SIN) do begin
    closeFile(SIN);
    bufs.sort;          //ソート（未完成：ソート順が逆）
    buffer := bufs.text;
    if defined(buffer) then
      if not TServerThrd(mother).SendData(buffer) then exit;

    buf := '</ul><p><input type=''submit'' value=''' + amessage('del_record',ENV) + '''' + ' tabindex=''2'' accesskey=''d'' />'
	 + '<input type=''hidden'' name=''mode'' value=''list'' /></p></form>';
    if not TServerThrd(mother).SendData(buf) then exit;

    filesize := _GetFileSize(DataPath(file_list));
    filesize := (Filesize div 1024) div 1024;
    if (count > 0) then checked := 'checked=''checked''' else checked :=  '';
    if (filesize <= D_FILELIMIT) then begin
      //未完成
      gateway_pm.newElementForm(file_list, checked, '1',ENV,mother);
    end;

     buf := '<form action='''+D_ROOT+ENV.Values['SCRIPT_NAME'] + '''>'
	  + '<p><input type=''submit'' value=''' + amessage('del_file',ENV) + '''' + ' tabindex=''6'' accesskey=''d'' />'
          + '<input type=''hidden'' name=''cmd'' value=''delete'' />'
	  + '<input type=''hidden'' name=''file'' value='''+ file_list+''''+' />'
	  + ' ' + IntToStr(filesize) + amessage('mb',ENV)+ '</p></form></body></html>'+LF;
    if not TServerThrd(mother).SendData(buf) then exit;

  finally
    rec.free;
    bufs.free;
    stat.free;
    r.free;

  end;

end;
*)

end.
