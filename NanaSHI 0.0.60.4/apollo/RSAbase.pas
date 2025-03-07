unit RSAbase;
{
*********************************************************

RSA公開鍵暗号ベースルーチン

Delphi版 RSAbase.pas
gcc+gmp版 RSAbase.h/RSAbase.c

  programmed by "replaceable anonymous"
*********************************************************

Delphi版改版履歴
  ver 0.0.0 2004/02/11
    とりあえずできた

  ver 0.1.0 2004/02/15
    q-1の因数にeが含まれていると無限ループになるバグを修正
    失敗時にp,q両方をインクリメントするように

  ver 0.2.0 2004/02/16
    関数実装に書き換え。
    gcc+gmp版とそろえた

/////////////////////////////////////////////////////////

}

interface

uses
  SysUtils,
  longint;

const
  RSAe = $10001; {RSAで公開用の指数}
  RSACreateGiveup = 300; {構成失敗までの試行回数}

type
  TRSAkeybase = record
    n: TLINT;
    d: TLINT;
  end;

  ERSAError = class(Exception);

  procedure RSAbase_generate(var key: TRSAkeybase; p: TLINT; q: TLINT);
  procedure RSAbase_encrypt(var m: TLINT;const key: TRSAkeybase);
  procedure RSAbase_decrypt(var m: TLINT;const n: TLINT);

implementation

uses factor;

//
//  与えられたランダムな2整数からRSAに適合するn,dを構成する
//
procedure RSAbase_generate(var key: TRSAkeybase; p: TLINT; q: TLINT);
var
  test1,test2: TLINT;
  e,n1: TLINT;
  q1,p1q1: TLINT;
  g: TLINT;
  i: Integer;
begin
    lset(@e,RSAe);
    lset(@n1,1);
    for i := 0 to RSACreateGiveup do
    begin
      primize(q); {qから+方向に一番近い素数に}
      q1 := q;
      aldec(@q1,1); {q1= q-1}
      primize(p); {pから+方向に一番近い素数に}
      p1q1 := p;
      aldec(@p1q1,1);
      lmulp(@p1q1,@q1); {p1q1 = (p-1)(q-1)}
      lgcd(@g,p1q1,e);  {(p-1)(q-1)とeが互いに素でないと逆元は存在しない}
      if lcmp(@g,@n1) <> 0 then
      begin
        alinc(@q,2);
        alinc(@p,2);
        Continue;
      end;
      linv(@key.d,e,p1q1); {dはeの法(p-1)(q-1)での逆元}
      lmulpb(@key.n,@p,@q); {完成、n=pq}
      lset(@test1,7743); {本当に戻ってくるか実験}
      test2 := test1;
      lpwrmod(@test2,@key.d,@key.n);
      lpwrmod(@test2,@e,@key.n);
      if lcmp(@test1,@test2) = 0 then {署名テストにパスしたら終了}
        Exit;
      alinc(@p,2);
      alinc(@q,2);
    end;

    raise ERSAError.Create('Fail to Create RSA-Keys: Retry-limit Over');
end;

procedure RSAbase_encrypt(var m: TLINT;const key: TRSAkeybase);
begin
    lpwrmod(@m,@key.d,@key.n);
end;

procedure RSAbase_decrypt(var m: TLINT;const n: TLINT);
var
  e: TLINT;
begin
    lpwrmod(@m,lset(@e,RSAe),@n);
end;

end.
