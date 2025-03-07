program httpd;

uses
  Forms,
  main in 'main.pas' {Form1},
  httpd_pl in 'httpd_pl.pas',
  config in 'config.pas',
  lib1 in 'lib1.pas',
  server_cgi in 'server_cgi.pas',
  gateway_cgi in 'gateway_cgi.pas',
  Node_pm in 'Node_pm.pas',
  NodeList_pm in 'NodeList_pm.pas',
  newtype in 'newtype.pas',
  RegularExp in 'RegularExp.pas',
  Util_pm in 'Util_pm.pas',
  client_cgi in 'client_cgi.pas',
  Cache_pm in 'Cache_pm.pas',
  CacheStat_pm in 'CacheStat_pm.pas',
  gateway_pm in 'gateway_pm.pas',
  Signature_pm in 'Signature_pm.pas',
  list_cgi in 'list_cgi.pas',
  thread_cgi in 'thread_cgi.pas',
  note_cgi in 'note_cgi.pas',
  Hash in 'Hash.pas',
  message_pm in 'message_pm.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.ShowHint := False;
  Application.Run;
end.
