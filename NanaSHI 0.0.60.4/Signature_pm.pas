unit Signature_pm;

interface

uses
  Classes,synacode,lib1,trip;

function check(rec:TStringList):boolean;
function md5digest(body:string):string;
procedure generate(passwd,body:string; var pubkey,sign:string);
function pubkey2trip(id:string):string;
function base64decode(value:string):string;
function base64encode(value:string):string;


implementation

function check(rec:TStringList):boolean;
begin
  //ñ¢äÆê¨

  Result := True;
end;

function md5digest(body:string):string;
var
  n:integer; s:string;
begin
  s := MD5(body);
  Result := '';
  for n := 1 to Length(s) do begin
    Result := Result + Bin2ByteStr(byte(s[n]));
  end;
end;

procedure generate(passwd,body:string; var pubkey,sign:string);
begin
  //ñ¢äÆê¨

  pubkey := '';
  sign := '';

end;

function pubkey2trip(id:string):string;
begin
  Result := triphash(id);
//Result := 'None';
end;

function base64decode(value:string):string;
var
  ans:string;
begin
  Result := DecodeBase64(Value);
end;

function base64encode(value:string):string;
var
  ans:string;
begin
  Result := EncodeBase64(Value);
end;

end.
