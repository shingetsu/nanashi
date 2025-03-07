unit message_pm;

interface

uses
  Classes, blcksock, winsock, Synautil, SysUtils, RegularExp, lib1, windows;

function amessage(id:string; ENV:TStringList):string;

implementation

uses
  config, gateway_pm;

var
  readed_flg:boolean;
  message_buff : TStringList;

function amessage(id:string; ENV:TStringList):string;
var
  lang,fname:string; p,n:integer; s:string;
begin
  Result := '';
  if not readed_flg then begin
    lang := ENV.Values['HTTP_ACCEPT_LANGUAGE'];
    fname := D_FILEDIR + '/message-' + lang + '.txt';
    if FileExists(fname) then begin
      message_buff.LoadFromFile(fname);
      readed_flg := True;
    end;
  end;
  if readed_flg then begin
    n := 0;
    while (n < message_buff.count) do begin
    //s := message_buff.Strings[n]; 
      s := gateway_pm.str_decode(message_buff.Strings[n]);  //2004/08/05 by tzr
      chomp(s);
      if copy(s,1,1) <> '#' then begin
        if copy(s,1,length(id)) = id then begin
          p := pos('<>',s);
          if p > 0 then begin
            Result := copy(s,p+2,length(s));
            exit;
          end;
        end;
      end;
      inc(n);
    end;
  end;
end;

initialization
  readed_flg := False;
  message_buff := TStringList.Create;

finalization
  message_buff.free;

end.
