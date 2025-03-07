unit client_cgi;

interface

uses
  Classes, winsock, SysUtils, windows,synsock,hash;

type
  TClientCgi = class(TObject)
  private
     ENV:TStringList;
     _time:THash;
  public
    mother : TObject;
    Constructor Create(Sender:TObject);
    Destructor Destroy; override;
    procedure Execute(sender:TObject);
    procedure save_time();


  end;


implementation

uses
  httpd_pl, blcksock, config, lib1, RegularExp, NodeList_pm, Node_pm, main,
  Cache_pm, CacheStat_pm;



//---------------------------------------------------------------
//CONSTRUCTOR
Constructor TClientCgi.Create(Sender:TObject);
begin
  inherited Create;
  ENV := TStringList.Create;
  mother := Sender;

  _time := THash.create;
end;


//---------------------------------------------------------------
//DESTRUCTOR
Destructor TClientCgi.Destroy;
begin
  inherited;
  _time.free;
  ENV.free;
end;

//---------------------------------------------------------------
procedure TClientCgi.Execute(sender:TObject);
var
  len,n,i,m:Integer; r:TRegularExp; z:TClientThrd; SIN:TextFile;
  tmp,path,ahost,aport,apath,acommand,afile,astamp,aid,anode:string;
  suggest,aip,alaststamp,abegin,aend,ans:string;ret,data:TStringList;
  sec,mxx:integer;

  procedure InitTimeHash();
  begin
    _time['ping'] := '0';
    _time['sync'] := '0';
    _time['init'] := '0';
  end;

begin
  z := TClientThrd(sender);
  ENV.Assign(TClientThrd(Sender).ENV);

  inc(ThttpdMain(TClientThrd(mother).mother).ClCgiCount);
  inc(ThttpdMain(TClientThrd(mother).mother).ClCgiActive);

  r    := TRegularExp.Create;
  ret  := TStringList.Create;
  data := TStringList.Create;

  try
    ans := 'Content-type: ' + mimeType.Values['txt']        + CRLF
         + 'X-Shingetsu: '  + ENV.Values['SERVER_SOFTWARE'] + CRLF
         + CRLF;

    tmp := ENV.Values['REMOTE_ADDR'];
    if not r.RegCompCut(tmp, '^' + D_ADMINADDR, False) then begin
      ans := ans + 'You are not the administrator.' + CRLF;
      TServerThrd(mother).SendData(ans);
      exit;
    end;

    if FileExists(D_CLIENT) then begin
      AssignFile(SIN, D_CLIENT);
      try
        Reset(SIN);
        Readln2(SIN,tmp); _time['ping'] := tmp;
        Readln2(SIN,tmp); _time['sync'] := tmp;
        Readln2(SIN,tmp); _time['init'] := tmp;
        CloseFile(SIN);
      except
        InitTimeHash();
      end;
    end else begin
      InitTimeHash();
    end;

    //----------------------
    //(1)
    Cache_pm.newFile();
    sec := (Trunc(sys_time()) - StrToIntDef(_time['ping'],0));
    ThttpdMain(TClientThrd(mother).mother).ping_sec := sec;

    mxx := D_PINGFREE * 60;
    ThttpdMain(TClientThrd(mother).mother).ping_mxx := mxx;
    if (sec >= mxx) then begin
      _time['ping'] := FloatToStr(sys_time());
      save_time();
      NodeList_pm.pingall(ENV);
      exit;
    end;

    //----------------------
    //(2)
    NodeList_pm.All();
    if (NodeList_pm.NodeCount = 0) then begin
      _time['init'] := FloatToStr(sys_time());
      save_time();
      NodeList_pm.init(ENV);
      _time['sync'] := FloatToStr(sys_time());
      save_time();
      CacheStat_pm.Cache_update();
      Cache_pm.sync(ENV);
      exit;
    end;

    //----------------------
    //(3)
    sec := (Trunc(sys_time()) - StrToIntDef(_time['init'],0));
    ThttpdMain(TClientThrd(mother).mother).init_sec := sec;

    n := NodeList_pm.NodeCount;
    mxx := D_INITFREC * n * 60;
    ThttpdMain(TClientThrd(mother).mother).init_mxx := mxx;

    if ( sec >= mxx) then begin
      _time['init'] := FloatToStr(sys_time());
      save_time();
      NodeList_pm.init(ENV);
      exit;
    end;

    //----------------------
    //(4)
    sec := (Trunc(sys_time()) - StrToIntDef(_time['sync'],0));
    ThttpdMain(TClientThrd(mother).mother).sync_sec := sec;

    mxx := D_SYNCFREC * 60;
    ThttpdMain(TClientThrd(mother).mother).sync_mxx := mxx;

    if (sec >= mxx) then begin
      n := 0;
      m := NodeList_pm.NodeCount;
      while (n < m) do begin
        anode := NodeList_pm.GetNode(n,True);
        NodeList_pm.joinRequest(anode,ENV);
        inc(n);
      end;
      _time['sync'] := FloatToStr(sys_time());
      save_time();
      CacheStat_pm.Cache_update();
      Cache_pm.sync(ENV);
      exit;
    end;


  finally
    dec(ThttpdMain(TClientThrd(mother).mother).ClCgiActive);
    data.free;
    ret.free;
    r.free;

  end;



end;

//-------------------------------------------------------
//
procedure TClientCgi.save_time();
var
  SIN:TextFile; s:string;
begin
  AssignFile(SIN, D_CLIENT);
  try
    ReWrite(SIN);
    s := string(_time['ping']);
    if s = '' then s := '0';
    Writeln(SIN, s);

    s := string(_time['sync']);
    if s = '' then s := '0';
    Writeln(SIN, s);

    s := string(_time['init']);
    if s = '' then s := '0';
    Writeln(SIN, s);

    CloseFile(SIN);
  except
    //
  end;
end;





end.
