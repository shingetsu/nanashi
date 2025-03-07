unit RegularExp;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls,
  StdCtrls, Buttons, ExtCtrls, RegExpr;

type
  TRegularExp = class(TObject)
  private
    RegExp : TRegExpr;
  public
    Constructor Create;
    Destructor  Destroy; override;

    function RegCompCut(buf,exp:string; isw:boolean):boolean;
    function RegReplace(buf,exp,ns:string; sw:boolean = True):string;
    function grps(exp:string):string;

    function func001(buf:string):string;
    function func002(buf:string):string;
    function func003(buf:string):string;
    function func004(buf:string):string;

    function callback_func001(ARegExpr: TRegExpr):string;
    function callback_func002(ARegExpr: TRegExpr):string;
    function callback_func003(ARegExpr: TRegExpr):string;
    function callback_func004(ARegExpr: TRegExpr):string;

  end;


implementation

uses
  lib1,gateway_pm;


Constructor TRegularExp.Create;
begin
  inherited;
  RegExp := TRegExpr.Create;
end;


Destructor TRegularExp.Destroy; //override;
begin
  RegExp.Free;
  inherited;
end;


function TRegularExp.RegCompCut(buf,exp:string; isw:boolean):boolean;
begin
  RegExp.Expression := exp;
  RegExp.ModifierI  := not isw;

  Result := RegExp.Exec(buf);
end;

function TRegularExp.RegReplace(buf,exp,ns:string; sw:boolean = True):string;
begin
  RegExp.Expression := exp;
  Result := RegExp.Replace (buf, ns, sw);
end;

function TRegularExp.grps(exp:string):string;
begin
  Result := RegExp.Substitute(exp);
end;

// s/%([A-Fa-f0-9][A-Fa-f0-9])/pack("C", hex($1))
function TRegularExp.func001(buf:string):string;
var
  r:TRegExpr;
begin
  r := TRegExpr.Create;
  try
    r.Expression := '%([A-Fa-f0-9][A-Fa-f0-9])';
    r.ModifierI := True;
    Result := r.ReplaceEx(buf, callback_func001);
  finally
    r.free;
  end;
end;

// s/[A-Fa-f0-9][A-Fa-f0-9]/pack("C", hex($&))
function TRegularExp.func002(buf:string):string;
var
  r:TRegExpr;
begin
  r := TRegExpr.Create;
  try
    r.Expression := '[A-Fa-f0-9][A-Fa-f0-9]';
    r.ModifierI := True;
    Result := r.ReplaceEx(buf, callback_func002);
  finally
    r.free;
  end;
end;

// s|\[\[([^<>]+?)\]\]|bracket_link($1)|eg;   // 0.3.4
function TRegularExp.func003(buf:string):string;
var
  r:TRegExpr;
begin
  r := TRegExpr.Create;
  try
    r.Expression := '\[\[([^<>]+?)\]\]';
    r.ModifierI := True;
    Result := r.ReplaceEx(buf, callback_func003);
  finally
    r.free;
  end;
end;


//&amp;(#\d+|#[Xx][0-9A-Fa-f]+|[A-Za-z0-9]+);
function TRegularExp.func004(buf:string):string;
var
  r:TRegExpr;
begin
  r := TRegExpr.Create;
  try
    r.Expression := '&amp;(#\d+|#[Xx][0-9A-Fa-f]+|[A-Za-z0-9]+);';
    r.ModifierI := True;
    Result := r.ReplaceEx(buf, callback_func004);
  finally
    r.free;
  end;
end;


function TRegularExp.callback_func001(ARegExpr : TRegExpr): string;
var
  s:string; b:uchar;
begin
  //hex($1) ------------ 16進数文字列→10進数
  //pack("C", $1) ------ 10進数をバイナリ文字列へ 65 ---> 'A'
  s := AregExpr.Substitute('$1');
  b := ByteStr2Bin(s);
  Result := Chr(b);
end;


function TRegularExp.callback_func002(ARegExpr : TRegExpr): string;
var
  s:string; b:uchar;
begin
  //hex($&) ------------ 16進数文字列→10進数
  //pack("C", $&) ------ 10進数をバイナリ文字列へ 65 ---> 'A'
  s := AregExpr.Substitute('$&');
  b := ByteStr2Bin(s);
  Result := Chr(b);
end;


function TRegularExp.callback_func003(ARegExpr : TRegExpr): string;
var
  s:string; b:uchar;
begin
  s := AregExpr.Substitute('$1');
  Result := gateway_pm.bracket_link(s);
end;

function TRegularExp.callback_func004(ARegExpr : TRegExpr): string;
var
  s:string; b:uchar;
begin
  s := AregExpr.Substitute('$1');
  Result := '&' + s;
end;

end.
