unit Cache_pm;

interface

uses
  SysUtils, Classes, winsock, windows,synsock,RegularExp,lib1,CacheStat_pm,
  Synautil,blcksock;



procedure newFile();
procedure sync(ENV:TStringList);
procedure tellupdate(afile,astamp,aid,anode:string;ENV:TStringList);
function  getData(afile,astamp,aid,anode,path:string;ENV:TStringList):integer;
procedure getRegion(afile,anode:string;ENV:TStringList);
function  search(afile:string;ENV:TStringList):string;
procedure addData(afile:string; newData,ENV:TStringList);
function  removeRecord(afile,astamp,aid:string):boolean;


implementation


uses
  main, Config, NodeList_pm, node_pm, util_pm,Signature_pm;


//------------------------------------------------
function  removeRecord(afile,astamp,aid:string):boolean;
var
  SIN,SOUT:TextFile; tmp,sss:string; ret,res:integer;
begin
  Result := False;

  sss := astamp+'<>'+aid+'<>';

  AssignFile(SIN, DataPath(afile));
  Reset(SIN);
  util_pm.lock();
  try
    AssignFile(SOUT, TempPath(afile));
    rewrite(SOUT);
    while not Eof(SIN) do begin
      Readln2(SIN,tmp);
      chomp(tmp);
      if (copy(tmp,1,length(sss)) = sss) then begin
        tmp := sss; //�폜�͖{��������, astamp + adi
      end;
      tmp := tmp + LF;
      Write(SOUT,tmp);

    end;
    closeFile(SIN);
    closeFile(SOUT);
    sysutils.DeleteFile(DataPath(afile));
    sysutils.RenameFile(TempPath(afile), DataPath(afile));

  finally
    util_pm.unlock();

  end;

  Result := True;
end;

//------------------------------------------------
// new file
//
procedure newFile();
var
  m:integer; r:TRegularExp; od, s_,afile:string;
  stat,ans:TStringList; size:integer;

begin
//dprint('Cache_pm.newFile()........IN');
  stat := TStringList.Create;
  ans := TStringList.Create;
  r := TRegularExp.Create;

  glob(D_DATADIR + '/' + '*.new', ans);
  try
    if (ans.count > 0) then begin
      CacheStat_pm.list(stat);  // <<<<< list()
    end;
    m := 0;
    while (m < ans.count)  do begin
      od := ans.Strings[m];
      size := _GetFileSize(od);
      s_ := od;
      s_ := r.RegReplace(s_,'\.new$','');
      RenameFile(od,s_);
      afile := s_;
      afile := r.RegReplace(afile,'^'+D_DATADIR+'/','');
      afile := r.RegReplace(afile,'\.dat$','');
      stat.Values[__stamp(afile)]   := '0';
      stat.Values[__records(afile)] := '1';
      stat.Values[__size(afile)]    :=  IntToStr(size);
      inc(m);
    end;
    if (ans.count > 0) then
      CacheStat_pm.stat_sync(stat);    // <<<<< sync()
  finally
    r.free;
    ans.free;
    stat.free;
//  dprint('Cache_pm.newFile()........OUT');
  end;
end;

//------------------------------------------------------
// sync
//
procedure sync(ENV:TStringList);
var
  afile:TStringList; m,mmx,n,i:integer; fname,s,node:string;
  r:TRegularExp;
begin
  r     := TRegularExp.create;
  afile := TStringList.Create;
  try
    glob(D_DATADIR + '/*.dat', afile);

    //�����V�F�C�N
    for n := 1 to afile.count do begin
      i := random(afile.count);
      s := afile.Strings[n-1];
      afile.Strings[n-1] := afile.Strings[i];
      afile.Strings[i] := s;
    end;

    //�����T�C�Y���̃t�@�C��������
    m := 0;
    mmx := afile.Count;
    while (m < mmx) do begin
      fname := afile.Strings[m];
      if (_GetFileSize(fname) <= (D_FILELIMIT * 1024 * 1024)) then begin
        fname := r.RegReplace(fname,'^'+D_DATADIR+'/','');
        fname := r.RegReplace(fname,'\.dat$','');
        node := search(fname,ENV);
        if defined(node) then begin
          getRegion(fname,node,ENV);
        end;
      end;
      mmx := afile.Count;    //�G���H�H
      inc(m);
    end;

  finally
    afile.Free;
    r.free;

  end;

end;

//-----------------------------------------------------------
// tell update
//
// �ێ����Ă���S�m�[�h�Ɏw��t�@�C����update�R�}���h�𑗐M����
//
// gateway_pm��post()����'dopost'����`����Ă��鎞�A�Ăяo�����B
// server_cgi��update()����Ăяo�����B
//
// ���ӁF�I���W�i����fork()���������Ă���B
//
// /server.cgi/update + /�t�@�C���� + /�^�C���X�^���v + /id + /�t�@�C���̏ꏊ(ip:port) + '+server.cgi'
//
// GET /server.cgi/update/list_6D656E75/1090749023/7187e2b4661b105dcbdafaed5fe5c0a7/192.168.99.36:8000+server.cgi HTTP/1.0
//
//
procedure tellupdate(afile,astamp,aid,anode:string;ENV:TStringList);
var
  node,ret:TStringList; m:integer; xnode,xip,xport,xpath,xgent:string;
begin
  ret := TStringList.Create;
  try
    node := NodeList_pm.all();
    if not defined(anode) then begin
      anode := NodeList_pm.myself(ENV);
    end;
    if not defined(anode) then begin
      exit;
    end;

    xnode := toXString(anode);
    ExpandUrl2(anode, xip,xport,xpath,xgent);

    m := 0;
    while (m < node.count) do begin
      Node_pm.talk(node.strings[m],'/update/'+afile+'/'+astamp+'/'+aid+'/' + xip + ':' + xport + '+server.cgi', '/server.cgi', ret,ENV);
      inc(m);
    end;

  finally
    ret.free;

  end;

end;

//-----------------------------------------------------------
//
function getData(afile,astamp,aid,anode,path:string;ENV:TStringList):integer;
var
  newdata:TStringList;
begin
  Result := 0;
  dprint('#### IN ######## Cache_pm.getData() ################## ');
  newdata := TStringList.Create;
  try
    Node_pm.talk(anode,'/get/'+afile+'/'+astamp+'/'+aid,path,newdata,ENV);  //������ '#' ??
    util_pm.md5check(newdata);
    addData(afile,newdata,ENV);
    Result := newdata.count;
  finally
    newdata.free;
    dprint('#### OUT ######## Cache_pm.getData() ################## ');
  end;
end;

//-----------------------------------------------------------
// getRegion
//
procedure getRegion(afile,anode:string;ENV:TStringList);
var
  newdata,stat,head,data,ans,buf:TStringList; abegin,anow:extended;
  SIN,SOUT:TextFile; h,tmp,astamp,aid:string;n,m,i,ret:integer;
begin
  if not defined(afile) then begin
    ErrorPrint('getRegion() filename is null.');
    exit;
  end;
  if not defined(afile) then begin
    ErrorPrint('getRegion() node is null.');
    exit;
  end;

//dprint('Cache_pm.getRegion()');
  stat := TStringList.Create;
  head := TStringList.Create;
  newdata := TStringList.Create;
  data := TStringList.Create;
  ans  := TStringList.Create;
  buf  := TStringList.Create;

  try
    CacheStat_pm.list(stat);
    abegin := 0;
    if defined(stat.values[__stamp(afile)]) then begin
      if (_GetFileSize(DataPath(afile))>0) then begin
        abegin := StrToFloatDef(stat.Values[__stamp(afile)],0);
      end;
    end;

    anow := sys_time() - (D_SYNCAFETY * 60 * 60);
    if (anow < abegin) then abegin := anow;
    newdata.clear;
    if (abegin <= 0) then begin
      talk(anode,'/get/'+afile+'/0-', '/server.cgi', newdata,ENV);
      util_pm.md5check(newdata);

      //�������F�I���W�i���ƈقȂ�F�����炱����ֈړ������B
      addData(afile,newData,ENV);

    end else begin

      //�^�[�Q�b�g�m�[�h����ړI�t�@�C���̃w�b�_�����擾(head) ---> stamp<>id
      talk(anode,'/head/'+afile+'/'+IntToStr(trunc(abegin))+'-', '/server.cgi', head,ENV);

      if not FileExists(DataPath(afile)) then begin // ���ӁF�I���W�i���ƈقȂ�
        ErrorPrint('getRegion() filename not found.');
        exit;                                       //
      end;

    //chomp(head);
      //���ݎ��Ă���ړI�t�@�C����ǂݍ���(data)
      AssignFile(SIN, DataPath(afile));
      try
        Reset(SIN);
        data.clear;
        while not Eof(SIN) do begin
          Readln2(SIN,tmp);
          data.add(tmp);
        end;
        CloseFile(SIN);
        //chomp(data);
      except
      //dprint('Cache_pm getRegin(),head read error...');
        exit;
      end;
      n := 0;
      while (n < head.count) do begin
        h := head.Strings[n];
        //head��stamp<>id�����݂��Ȃ� ----> �V�������R�[�h�Ȃ̂Œǉ�����
        //�i���ӁF���R�[�h�C���������d�l�ł���. by neko�j
        if not grep( '^' + h +'(<>|$)', data) then begin
          split(h,'<>',ans);
          if (ans.count > 1) then begin
            astamp := ans.Strings[0];
            aid    := ans.Strings[1];
            talk(anode,'/get/' + afile + '/' + astamp + '/' + aid, '/server.cgi', buf,ENV);
            if buf.Count > 0 then begin
              util_pm.md5check(buf);
              if FileExists(DataPath(afile)) then begin
                util_pm.lock();
                AssignFile(SOUT, DataPath(afile));
                try
                //Reset(SOUT);
                  Append(SOUT);
                  m := 0;
                  while m < buf.Count do begin
                    tmp := buf.Strings[m] + LF;
                    write(SOUT,tmp);
                    inc(m);
                  end;
                  CloseFile(SOUT);
                except
                  //
                end;
                util_pm.unlock();
              end;  // end of if FileExists(DataPath(afile)) then begin
            end;  // end of if buf.Count > 0 then begin
          end;  // end of if (ans.count > 0) then begin
        end;  // end of if not grep( '^' + h +'(<>|$)', data) then begin
        inc(n);
      end;  // end of while (n < data.count) do begin
    end;

    //�������FnewData���Z�b�g���Ă��Ȃ��̂ɌĂяo���Ă��邱�Ƃ�����H�H
    //��Ɉړ��F�I���W�i���ƈقȂ�
    //addData(afile,newData);

  finally
    buf.free;
    ans.free;
    data.free;
    newdata.free;
    head.free;
    stat.free;

  end;


end;

//-----------------------------------------------------------
// search
//
// �w��t�@�C�����l�b�g�Ō������m�[�h���擾����
//
// gateway_pm.touch()����Ă΂��
// Cache_pm.sync()����Ă΂��
//
function search(afile:string;ENV:TStringList):string;
var
  ret:TStringList; myself,anode,s:string; x,m:integer;
begin
  ret  := TStringList.Create;
  try
    Result := '';
    NodeList_pm.All();     // Node���X�g�̃����_���V�F�C�N
    myself := NodeList_pm.myself(ENV);
    m := 0;
    x := NodeList_pm.NodeCount();
    while (m < x) and (m <= D_SEARCHDEPTH) do begin
      anode := GetNode(m,false);
      Node_pm.talk(anode,'/have/'+afile,'/server.cgi',ret,ENV);
      if NodeList_pm.isOkHavingNode(anode) then begin
        //Have�𑗂��ėǂ��m�[�h��������A�A
        if (ret.count > 0 ) then  begin
          //�����Ă���
          if (ret.Strings[0] = 'YES') then begin
            Result := anode;
            break;
          end else if (ret.Strings[0] = 'NO') then begin
            //�����Ă��Ȃ�
            Node_pm.talk(anode,'/node','/server.cgi', ret,ENV);
            if (ret.count > 0) then begin
              s := ret.strings[0];
              if ( defined(s) and (s<>myself) ) then begin
                NodeList_pm.NodeAdd(s,'');
              end;
            end;
          end else begin
            //YES,NO�ȊO�̉���
            NodeList_pm.remove(anode);  //�m�[�h������
            x := NodeList_pm.NodeCount();
            ErrorPrint('[search()] bad answer, remove ' + anode + '(' + AgentName(ENV)+ ')');
            dec(m);
          end;
        end else begin
          //������
          NodeList_pm.remove(anode);  //�m�[�h������
          x := NodeList_pm.NodeCount();
          dec(m);
          ErrorPrint('[search()] no answer, remove ' + anode + '(' + AgentName(ENV)+ ')');
        end;
      end else begin
        //Have�𑗂��Ă͂����Ȃ��m�[�h.
        DPrint(' >>Canceled /have, It`s NodeManager');
        Node_pm.talk(anode,'/node','/server.cgi', ret,ENV);
        if (ret.count > 0) then begin
          s := ret.strings[0];
          if ( defined(s) and (s<>myself) ) then begin
            NodeList_pm.NodeAdd(s,'');
          end;
        end;
      end;
      inc(m);
    end;
  finally
    ret.free;
  end;
end;


(*
//-----------------------------------------------------------
// search
//
// �w��t�@�C�����l�b�g�Ō������m�[�h���擾����
//
//
function  search(afile:string;ENV:TStringList):string;
var
  node,ret:TStringList; myself,anode,s:string; m:integer;
begin
  ret  := TStringList.Create;
  try
    Result := '';
    node := NodeList_pm.All();
    myself := NodeList_pm.myself(ENV);
    m   := 0;
    while (m < node.count) and (m <= D_SEARCHDEPTH) do begin
      anode := GetNode(m,false);
      Node_pm.talk(anode,'/have/'+afile,'/server.cgi',ret,ENV);
      if (ret.count > 0 ) then  begin
        //�����Ă���
        if (ret.Strings[0] = 'YES') then begin
          Result := anode;
          break;
        end;
      end else  begin
        //�����Ă��Ȃ�
        Node_pm.talk(anode,'/node','/server.cgi', ret,ENV);
        if (ret.count > 1) then begin
          s := ret.strings[0];
          if (defined(s) and (s<>myself)) then begin
            NodeAdd(s,'');
          end;
        end;
      end;
      inc(m);
    end;
  finally
    ret.free;
  end;
end;
*)










//-----------------------------------------------------
//
// addData
//
//
procedure addData(afile:string; newData:TStringList;ENV:TStringList);
var
  stat,data,rec,ans:TStringList; SIN:TextFile; records,m,mm:integer; base,tmp,
  laststamp:string;
begin

  if NewData.Count <= 0 then               //  �������F�ǉ������B�I���W�i���ƈقȂ�
    exit;                                  //

  if not FileExists(DataPath(afile)) then  //  �������F�ǉ������B�I���W�i���ƈقȂ�
    exit;                                  //


  data := TStringList.Create;
  rec  := TStringList.Create;
  stat := TStringList.Create;
  ans  := TStringList.Create;
  try
    //�ǉ����e�f�[�^�������`�F�b�N 2004/07/24 by tzr
    m := 0;
    mm := newData.Count;
    while (m < mm) do begin
      if not isOkRecord(newData.Strings[m]) then begin
        newData.Delete(m);
        mm := newData.Count;
      end else begin
        inc(m);
      end;
    end;

    //�w��t�@�C���̌��ݒl��ǂݍ���
    AssignFile(SIN, DataPath(afile));
    try
      data.clear;
      Reset(SIN);
      while not Eof(SIN) do begin
        readln2(SIN,tmp);
        data.add(tmp);
      end;
      CloseFile(SIN);
    except
      //
    end;


    //�t�@�C�����b�N     //---------------------------------------
    Util_pm.Lock();

    //�����t�@�C���̌��ݒl�ɒǉ����e��������
    m := 0;
    while ( m < newdata.count ) do begin
       tmp := newdata.Strings[m];
       data.add(tmp);
      inc(m);
    end;

    //�\�[�g����
    data.sort;

    try
      SysUtils.DeleteFile(DataPath(afile)+'.tmp');
    except
      ;
    end;

    //�d�����Ă��Ȃ��f�[�^�����[�N�t�@�C���֏o�͂���
    AssignFile(SIN, DataPath(afile)+'.tmp');
    try
      Rewrite(SIN);
      records := 0;
      base := '';
      m := 0;
      while m < data.count do begin
        tmp := data.Strings[m];
        if (base <> tmp) then begin   //
          write(SIN,tmp + LF);        //�d�����Ă��Ȃ��f�[�^�̂ݏ����o��
          base := tmp;                //
        end;
        inc(records);
        inc(m);
      end;
      CloseFile(SIN);
    except
      //
    end;

    //���[�N�t�@�C����{�Ԗ��ɕύX
    try
      SysUtils.DeleteFile(DataPath(afile));
    except
      ;
    end;
    RenameFile(DataPath(afile)+'.tmp', DataPath(afile) );

    //�t�@�C���A�����b�N
    Util_pm.Unlock();    //---------------------------------------

    m := 0;
    while (m < newdata.count) do begin
      tmp := newdata.Strings[m];
      if defined(tmp) then begin     //''�������̂Œǉ�
        util_pm.rec(tmp,rec,ENV);

        if defined(rec.Values['remove_id']) and defined(rec.Values['remove_stamp']) then begin

          // ������
          split(rec.Values['target'],',',ans);
          if grep('remove_stamp', ans) then begin
            if grep('remove_id', ans) then begin
              if include(Signature_pm.pubkey2trip(rec.Values['pubkey'])) then begin
                if Signature_pm.check(rec) then begin
                  Cache_pm.removeRecord(afile,rec.Values['remove_stamp'],rec.Values['remove_id']);
                end;
              end;
            end;
          end;

        end;
      end;
      inc(m);
    end;

    if (data.count > 0) then begin
      split( data.Strings[data.count-1], '<>', rec);
      if rec.count >= 1 then begin
        laststamp := rec.Strings[0];
        CacheStat_pm.list(stat);
        stat.Values[__stamp(afile)]   := laststamp;
        stat.Values[__records(afile)] := IntToStr(records);
        stat.Values[__size(afile)]    := IntToStr((_GetFileSize(DataPath(afile)) div 1024) div 1024);
        CacheStat_pm.stat_sync(stat);
      end else begin
        ErrorPrint('Cache_pm.addData() -- count error !');
      end;
    end;


  finally
    ans.free;
    data.free;
    rec.free;
    stat.free;

  end;


end;



end.
