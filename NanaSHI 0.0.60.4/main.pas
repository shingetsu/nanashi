unit main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, httpd_pl, Menus, Synautil,util_pm, ComCtrls, RegularExp,
  ExtCtrls, inifiles, Buttons;

const
  INIPARA = 'NANASHI';

type
  TForm1 = class(TForm)
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    Menu_Start1: TMenuItem;
    N1: TMenuItem;
    Exit1: TMenuItem;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    Memo1: TMemo;
    Timer1: TTimer;
    TabSheet2: TTabSheet;
    Memo2: TMemo;
    TabSheet3: TTabSheet;
    Panel1: TPanel;
    GroupBox1: TGroupBox;
    SvThreadActive: TLabel;
    SvThreadCount: TLabel;
    Label4: TLabel;
    GroupBox2: TGroupBox;
    Label6: TLabel;
    Label2: TLabel;
    Label8: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label3: TLabel;
    Label1: TLabel;
    Label7: TLabel;
    Label9: TLabel;
    Label5: TLabel;
    Label10: TLabel;
    Label13: TLabel;
    GroupBox3: TGroupBox;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    TabSheet4: TTabSheet;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    Memo3: TMemo;
    CheckBox3: TCheckBox;
    Button3: TButton;
    Label17: TLabel;
    Memo4: TMemo;
    Label18: TLabel;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    TabSheet5: TTabSheet;
    CheckBox4: TCheckBox;
    EditBind: TEdit;
    Label19: TLabel;
    Label20: TLabel;
    EditPort: TEdit;
    Label22: TLabel;
    Label23: TLabel;
    Label24: TLabel;
    Label25: TLabel;
    Label26: TLabel;
    Label27: TLabel;
    Label28: TLabel;
    Label29: TLabel;
    Label30: TLabel;
    Label31: TLabel;
    CheckBox5: TCheckBox;
    CheckBox6: TCheckBox;
    Button2: TButton;
    Button7: TButton;
    Button8: TButton;
    Button9: TButton;
    Button10: TButton;
    GroupBox4: TGroupBox;
    Memo5: TMemo;
    Label21: TLabel;
    CheckBox7: TCheckBox;
    procedure Menu_Start1Click(Sender: TObject);
    procedure Exit1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Timer1Timer(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure Button9Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure Button10Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormActivate(Sender: TObject);
  private
    { Private declarations }
    exeflg : integer;
  public
    { Public declarations }
    sv : ThttpdMain;
    procedure LoadEnv();
    procedure SaveEnv();
    function ProgramCanQuit():boolean;
  end;

var
  Form1: TForm1;

procedure mPrint(s:string);
procedure ErrorPrint(s:string);
procedure dprint(s:string);
procedure dprint1(s:string);



implementation

uses
  config, lib1, NodeList_pm, Gateway_pm, timet, CacheStat_pm, Cache_pm;

{$R *.DFM}


//------------------------------------------------------------------
procedure mPrint(s:string);
var
  NowLine,LastLine:integer;
begin
  if Form1.sv.isQuit() then
    exit;
  with Form1.Memo1.lines do begin
    BeginUpdate;
    try
      add(s);
      NowLine  := Form1.Memo1.Perform(EM_LINEFROMCHAR,Form1.Memo1.SelStart,0);
      LastLine := Form1.Memo1.Perform(EM_GETLINECOUNT,0,0);
      Form1.Memo1.Perform(EM_LINESCROLL,0,LastLine-NowLine);
      Form1.Memo1.SelStart := Form1.Memo1.Perform(EM_LINEINDEX,LastLine-1,0);
    finally
      EndUpdate;
    end;
  end;
end;



//------------------------------------------------------------------
procedure ErrorPrint(s:string);
var
  NowLine,LastLine:integer;
begin
  if Form1.sv.isQuit() then
    exit;
  if not Form1.CheckBox3.Checked then
    Exit;
  with Form1.Memo2 do begin
    lines.BeginUpdate;
    try
      if Count > 500 then  begin
        Clear;
        lines.add('(#):cleared this log.......................');
      end;
      lines.add(s);
      NowLine  := Perform(EM_LINEFROMCHAR,SelStart,0);
      LastLine := Perform(EM_GETLINECOUNT,0,0);
      Perform(EM_LINESCROLL,0,LastLine-NowLine);
      SelStart := Perform(EM_LINEINDEX,LastLine-1,0);
    finally
      lines.EndUpdate;
    end;
  end;
end;


//------------------------------------------------------------------
procedure dprint(s:string);
var
  NowLine,LastLine:integer;
begin
  if Form1.sv.isQuit() then
    exit;
  if not Form1.CheckBox1.Checked then
    Exit;
  with Form1.Memo1.lines do begin
    BeginUpdate;
    try
      if Count > 500 then  begin
        Clear;
        add('(#):cleared this log.......................');
      end;
      add(s);
      NowLine  := Form1.Memo1.Perform(EM_LINEFROMCHAR,Form1.Memo1.SelStart,0);
      LastLine := Form1.Memo1.Perform(EM_GETLINECOUNT,0,0);
      Form1.Memo1.Perform(EM_LINESCROLL,0,LastLine-NowLine);
      Form1.Memo1.SelStart := Form1.Memo1.Perform(EM_LINEINDEX,LastLine-1,0);
    finally
      EndUpdate;
    end;
  end;
end;


//------------------------------------------------------------------
procedure dprint1(s:string);
begin
  if Form1.sv.isQuit() then
    exit;
  if not Form1.CheckBox2.Checked then
    Exit;
  with Form1.Memo1.lines do begin
    BeginUpdate;
    try
      if Count > 500 then  begin
        Clear;
        add('(#):cleared this log.......................');
      end;
      add(s);
    finally
      EndUpdate;
    end;
  end;
end;


procedure TForm1.Menu_Start1Click(Sender: TObject);
begin
  Memo5.Clear;
  self.caption := self.caption + 'BindIP:'+EditBind.Text + ' Port:'+EditPort.Text;
  PageControl1.ActivePage := TabSheet1;
  Menu_Start1.Enabled := False;
  sv := ThttpdMain.create(Form1);
  Timer1.Enabled := True;
end;


//-----------------------------
//
function TForm1.ProgramCanQuit():boolean;
var
  ret,n:integer;
begin
  Result := True;
  if not assigned(sv) then
    exit;
  if not sv.isCanQuit() then begin
    messagebeep(0);
    ret := MessageDlg('現在処理中のスレッドが存在します。強制終了しますか？',mtInformation,[mbYes,mbNo],0);
    if (mrYes <> ret) then begin
      Result := False;
      exit;
    end;
    n := 0;
    sv.ForceQuit();
    while n < 3 do begin
      Application.processmessages;
      sleep(1000);
      if sv.isCanQuit() then begin
        exit;
      end;
      inc(n);
    end;
  end;
end;


//-----------------------------
//
procedure TForm1.Exit1Click(Sender: TObject);
begin
  close;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Timer1.Enabled := False;
  if assigned(sv) then begin
    if not ProgramCanQuit() then begin
      Action := caNone;
      exit;
    end;
    sv.Terminate;
//  sv.WaitFor;  //---> 未完成：D5はOKなのに、D6はエラーになる、なんで？
  end;
  SaveEnv();
end;




procedure TForm1.Timer1Timer(Sender: TObject);
begin
  SvThreadActive.Caption := Format('%0.2d',[sv.SVThreadActive]);
  SvThreadCount.Caption  := Format('%d',[sv.SVThreadCount]);

  Label6.Caption := Format('%0.2d',[sv.SVCgiActive]);
  Label3.Caption := Format('%d',[sv.SVCgiCount]);

  Label12.Caption := Format('%0.2d',[sv.SVCgiPingActive]);
  Label11.Caption := Format('%d',[sv.SVCgiPingCount]);

  Label7.Caption := Format('%0.2d',[sv.SVCgiRecvJoinActive]);
  Label9.Caption := Format('%d',[sv.SVCgiRecvJoinCount]);

  Label13.Caption := Format('%0.2d',[sv.SVCgiWelcomeActive]);
  Label10.Caption := Format('%d',[sv.SVCgiWelcomeCount]);

  Label14.Caption := Format('%0.2d',[sv.ClCgiActive]);
  Label15.Caption := Format('%d',[sv.ClCgiCount]);

  Label24.Caption := Format('%d',[sv.ping_sec]);
  Label25.Caption := Format('%d',[sv.init_sec]);
  Label26.Caption := Format('%d',[sv.sync_sec]);

  Label27.Caption := Format('%d',[sv.ping_mxx]);
  Label28.Caption := Format('%d',[sv.init_mxx]);
  Label29.Caption := Format('%d',[sv.sync_mxx]);

  Label31.Caption := IntToStr(NodeCount());

end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  if not FileExists(D_DEFAULT_NODE) then begin
    MessageBeep(0);
    ShowMessage('file not found. ( '+D_DEFAULT_NODE+' )');
    exit;
  end;
  Memo3.clear;
  Memo3.lines.LoadFromFile(D_DEFAULT_NODE);

end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  if (Memo3.lines.Count <= 0) then begin
    MessageBeep(0);
    ShowMessage('blank! DEFAULT LIST');
    exit;
  end;
  Memo3.lines.SaveToFile(D_DEFAULT_NODE);

end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  if not FileExists(D_NODELIST) then begin
    MessageBeep(0);
    ShowMessage('file not found. ( '+D_NODELIST+' )');
    exit;
  end;
  Memo4.clear;
  Memo4.lines.LoadFromFile(D_NODELIST);

end;

procedure TForm1.Button5Click(Sender: TObject);
begin
  if (Memo4.lines.Count <= 0) then begin
    MessageBeep(0);
    ShowMessage('blank! NODE LIST');
    exit;
  end;
  Memo4.lines.SaveToFile(D_NODELIST);

end;

procedure TForm1.Button6Click(Sender: TObject);
var
  n:integer;
begin
  if (Memo3.lines.Count <= 0) then begin
    MessageBeep(0);
    ShowMessage('blank! DEFAULT LIST');
    exit;
  end;
  Memo4.clear;
  for n := 1 to Memo3.lines.Count do
    Memo4.lines.add(Memo3.lines.Strings[n-1]);
  
end;

procedure TForm1.Button7Click(Sender: TObject);
begin
  if not FileExists(D_NODELIST_A) then begin
    MessageBeep(0);
    ShowMessage('file not found. ( '+D_NODELIST_A+' )');
    exit;
  end;
  Memo4.clear;
  Memo4.lines.LoadFromFile(D_NODELIST_A);

end;

procedure TForm1.Button9Click(Sender: TObject);
begin
  if not FileExists(D_NODELIST_B) then begin
    MessageBeep(0);
    ShowMessage('file not found. ( '+D_NODELIST_B+' )');
    exit;
  end;
  Memo4.clear;
  Memo4.lines.LoadFromFile(D_NODELIST_B);

end;

procedure TForm1.Button8Click(Sender: TObject);
begin
  if (Memo4.lines.Count <= 0) then begin
    MessageBeep(0);
    ShowMessage('blank! NODE LIST');
    exit;
  end;
  Memo4.lines.SaveToFile(D_NODELIST_A);

end;

procedure TForm1.Button10Click(Sender: TObject);
begin
  if (Memo4.lines.Count <= 0) then begin
    MessageBeep(0);
    ShowMessage('blank! NODE LIST');
    exit;
  end;
  Memo4.lines.SaveToFile(D_NODELIST_B);

end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  exeflg := 0;
  Form1.Caption := D_SOFTWARE + D_VER + D_SUBNAME;
  LoadEnv();

end;

//--------------------------------
procedure TForm1.LoadEnv();
var
  ini: TMemIniFile;
begin
  ini := TMemIniFile.Create(changefileExt(Application.ExeName, '.ini'));
  EditBind.Text     := ini.ReadString(INIPARA, 'BindIP', '0.0.0.0'   );
  EditPort.Text     := ini.ReadString(INIPARA, 'EditPort', '9000'    );
  CheckBox1.Checked := ini.ReadBool  (INIPARA, 'LOG_LEVEL_1',           True  );
  CheckBox2.Checked := ini.ReadBool  (INIPARA, 'LOG_LEVEL_2',           False );
  CheckBox3.Checked := ini.ReadBool  (INIPARA, 'ERROR_LOG',             True  );
  CheckBox4.Checked := ini.ReadBool  (INIPARA, 'VERSIONCHECK',          False );
  CheckBox5.Checked := ini.ReadBool  (INIPARA, 'CLIENT_CGI',            True  );
  CheckBox6.Checked := ini.ReadBool  (INIPARA, 'SERVER_CGI',            True  );
  CheckBox7.Checked := ini.ReadBool  (INIPARA, 'NO_SEARCH_NODE_SERVER', False );
  ini.Free;
end;

//--------------------------------
procedure TForm1.SaveEnv();
var
  ini: TMemIniFile;
begin
  ini := TMemIniFile.Create(ChangeFileExt(application.exename, '.ini'));
  ini.WriteString(INIPARA, 'BindIP',                EditBind.Text);
  ini.WriteString(INIPARA, 'EditPort',              EditPort.Text);
  ini.WriteBool  (INIPARA, 'LOG_LEVEL_1',           CheckBox1.Checked);
  ini.WriteBool  (INIPARA, 'LOG_LEVEL_2',           CheckBox2.Checked);
  ini.WriteBool  (INIPARA, 'ERROR_LOG',             CheckBox3.Checked);
  ini.WriteBool  (INIPARA, 'VERSIONCHECK',          CheckBox4.Checked);
  ini.WriteBool  (INIPARA, 'CLIENT_CGI',            CheckBox5.Checked);
  ini.WriteBool  (INIPARA, 'SERVER_CGI',            CheckBox6.Checked);
  ini.WriteBool  (INIPARA, 'NO_SEARCH_NODE_SERVER', CheckBox7.Checked);
  ini.UpdateFile;
  ini.Free;
end;


procedure TForm1.FormActivate(Sender: TObject);
begin
  if exeflg > 0 then
    exit;
  inc(exeflg);
  PageControl1.ActivePage := TabSheet1;

end;

end.
