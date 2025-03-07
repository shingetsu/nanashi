
unit MD5;

interface

uses
  Windows, SysUtils;

type
  MD5Context = packed record
    buf: array[0..3] of UINT;
    bits: array[0..1] of UINT;
    indata: array[0..63]of Char;
  end;

procedure MD5Init(var ctx: MD5Context);
procedure MD5Update(var ctx: MD5Context; buf: PBYTE; len: UINT);
procedure MD5Final(var ctx: MD5Context; digest: PChar);
function MD5String(S: string): string;

implementation

procedure MD5Init(var ctx: MD5Context);
begin
  ctx.buf[0] := $67452301;
  ctx.buf[1] := $efcdab89;
  ctx.buf[2] := $98badcfe;
  ctx.buf[3] := $10325476;
  ctx.bits[0] := 0;
  ctx.bits[1] := 0;
end;

function F1(x, y, z: UINT): UINT;
//var
//  a:UINT;
begin
  Result := (z xor (x and (y xor z)));
//  a := y xor z;
//  a := x and a;
//  Result := z xor a;
end;

function F2(x, y, z: UINT): UINT;
begin
  Result := F1(z, x, y);
end;

function F3(x, y, z: UINT): UINT;
begin
  Result := (x xor y xor z);
end;

function F4(x, y, z: UINT): UINT;
begin
  Result := (y xor (x or (not z)));
end;

procedure MD5STEP(var w: UINT; x, y, z, data, s: UINT);
begin
  Inc(w, data);
  w := (w shl s) or (w shr (32-s));
  Inc(w, x);
end;

procedure MD5Transform(var ctx: MD5Context);
type
  UINTARRAY = array[0..999]of UINT;
  PUINTARRAY = ^UINTARRAY;
var
  a, b, c, d: UINT;
  indata: PUINTARRAY;
  buf: PUINTARRAY;
begin
  buf := PUINTARRAY(@(ctx.buf));
  indata := PUINTARRAY(@(ctx.indata));
  
  a := buf[0];
  b := buf[1];
  c := buf[2];
  d := buf[3];
  
  MD5STEP(a, b, c, d, F1(b, c, d) + indata[0] + $d76aa478, 7);
  MD5STEP(d, a, b, c, F1(a, b, c) + indata[1] + $e8c7b756, 12);
  MD5STEP(c, d, a, b, F1(d, a, b) + indata[2] + $242070db, 17);
  MD5STEP(b, c, d, a, F1(c, d, a) + indata[3] + $c1bdceee, 22);
  MD5STEP(a, b, c, d, F1(b, c, d) + indata[4] + $f57c0faf, 7);
  MD5STEP(d, a, b, c, F1(a, b, c) + indata[5] + $4787c62a, 12);
  MD5STEP(c, d, a, b, F1(d, a, b) + indata[6] + $a8304613, 17);
  MD5STEP(b, c, d, a, F1(c, d, a) + indata[7] + $fd469501, 22);
  MD5STEP(a, b, c, d, F1(b, c, d) + indata[8] + $698098d8, 7);
  MD5STEP(d, a, b, c, F1(a, b, c) + indata[9] + $8b44f7af, 12);
  MD5STEP(c, d, a, b, F1(d, a, b) + indata[10] + $ffff5bb1, 17);
  MD5STEP(b, c, d, a, F1(c, d, a) + indata[11] + $895cd7be, 22);
  MD5STEP(a, b, c, d, F1(b, c, d) + indata[12] + $6b901122, 7);
  MD5STEP(d, a, b, c, F1(a, b, c) + indata[13] + $fd987193, 12);
  MD5STEP(c, d, a, b, F1(d, a, b) + indata[14] + $a679438e, 17);
  MD5STEP(b, c, d, a, F1(c, d, a) + indata[15] + $49b40821, 22);
  
  MD5STEP(a, b, c, d, F2(b, c, d) + indata[1] + $f61e2562, 5);
  MD5STEP(d, a, b, c, F2(a, b, c) + indata[6] + $c040b340, 9);
  MD5STEP(c, d, a, b, F2(d, a, b) + indata[11] + $265e5a51, 14);
  MD5STEP(b, c, d, a, F2(c, d, a) + indata[0] + $e9b6c7aa, 20);
  MD5STEP(a, b, c, d, F2(b, c, d) + indata[5] + $d62f105d, 5);
  MD5STEP(d, a, b, c, F2(a, b, c) + indata[10] + $02441453, 9);
  MD5STEP(c, d, a, b, F2(d, a, b) + indata[15] + $d8a1e681, 14);
  MD5STEP(b, c, d, a, F2(c, d, a) + indata[4] + $e7d3fbc8, 20);
  MD5STEP(a, b, c, d, F2(b, c, d) + indata[9] + $21e1cde6, 5);
  MD5STEP(d, a, b, c, F2(a, b, c) + indata[14] + $c33707d6, 9);
  MD5STEP(c, d, a, b, F2(d, a, b) + indata[3] + $f4d50d87, 14);
  MD5STEP(b, c, d, a, F2(c, d, a) + indata[8] + $455a14ed, 20);
  MD5STEP(a, b, c, d, F2(b, c, d) + indata[13] + $a9e3e905, 5);
  MD5STEP(d, a, b, c, F2(a, b, c) + indata[2] + $fcefa3f8, 9);
  MD5STEP(c, d, a, b, F2(d, a, b) + indata[7] + $676f02d9, 14);
  MD5STEP(b, c, d, a, F2(c, d, a) + indata[12] + $8d2a4c8a, 20);
  
  MD5STEP(a, b, c, d, F3(b, c, d) + indata[5] + $fffa3942, 4);
  MD5STEP(d, a, b, c, F3(a, b, c) + indata[8] + $8771f681, 11);
  MD5STEP(c, d, a, b, F3(d, a, b) + indata[11] + $6d9d6122, 16);
  MD5STEP(b, c, d, a, F3(c, d, a) + indata[14] + $fde5380c, 23);
  MD5STEP(a, b, c, d, F3(b, c, d) + indata[1] + $a4beea44, 4);
  MD5STEP(d, a, b, c, F3(a, b, c) + indata[4] + $4bdecfa9, 11);
  MD5STEP(c, d, a, b, F3(d, a, b) + indata[7] + $f6bb4b60, 16);
  MD5STEP(b, c, d, a, F3(c, d, a) + indata[10] + $bebfbc70, 23);
  MD5STEP(a, b, c, d, F3(b, c, d) + indata[13] + $289b7ec6, 4);
  MD5STEP(d, a, b, c, F3(a, b, c) + indata[0] + $eaa127fa, 11);
  MD5STEP(c, d, a, b, F3(d, a, b) + indata[3] + $d4ef3085, 16);
  MD5STEP(b, c, d, a, F3(c, d, a) + indata[6] + $04881d05, 23);
  MD5STEP(a, b, c, d, F3(b, c, d) + indata[9] + $d9d4d039, 4);
  MD5STEP(d, a, b, c, F3(a, b, c) + indata[12] + $e6db99e5, 11);
  MD5STEP(c, d, a, b, F3(d, a, b) + indata[15] + $1fa27cf8, 16);
  MD5STEP(b, c, d, a, F3(c, d, a) + indata[2] + $c4ac5665, 23);
  
  MD5STEP(a, b, c, d, F4(b, c, d) + indata[0] + $f4292244, 6);
  MD5STEP(d, a, b, c, F4(a, b, c) + indata[7] + $432aff97, 10);
  MD5STEP(c, d, a, b, F4(d, a, b) + indata[14] + $ab9423a7, 15);
  MD5STEP(b, c, d, a, F4(c, d, a) + indata[5] + $fc93a039, 21);
  MD5STEP(a, b, c, d, F4(b, c, d) + indata[12] + $655b59c3, 6);
  MD5STEP(d, a, b, c, F4(a, b, c) + indata[3] + $8f0ccc92, 10);
  MD5STEP(c, d, a, b, F4(d, a, b) + indata[10] + $ffeff47d, 15);
  MD5STEP(b, c, d, a, F4(c, d, a) + indata[1] + $85845dd1, 21);
  MD5STEP(a, b, c, d, F4(b, c, d) + indata[8] + $6fa87e4f, 6);
  MD5STEP(d, a, b, c, F4(a, b, c) + indata[15] + $fe2ce6e0, 10);
  MD5STEP(c, d, a, b, F4(d, a, b) + indata[6] + $a3014314, 15);
  MD5STEP(b, c, d, a, F4(c, d, a) + indata[13] + $4e0811a1, 21);
  MD5STEP(a, b, c, d, F4(b, c, d) + indata[4] + $f7537e82, 6);
  MD5STEP(d, a, b, c, F4(a, b, c) + indata[11] + $bd3af235, 10);
  MD5STEP(c, d, a, b, F4(d, a, b) + indata[2] + $2ad7d2bb, 15);
  MD5STEP(b, c, d, a, F4(c, d, a) + indata[9] + $eb86d391, 21);
  
  Inc(buf[0], a);
  Inc(buf[1], b);
  Inc(buf[2], c);
  Inc(buf[3], d);
end;

procedure MD5Update(var ctx: MD5Context; buf: PBYTE; len: UINT);
var
  t: UINT;
  p: PBYTE;
begin
  t := ctx.bits[0];
  ctx.bits[0] := t + (len shl 3);
  if (ctx.bits[0] < t) then Inc(ctx.bits[1]);
  Inc(ctx.bits[1], len shr 29);
  t := (t shr 3) and $3f;
  if (t <> 0) then
  begin
    p := PBYTE(PCHAR(@(ctx.indata)) + t);
    t := 64 - t;
    if (len < t) then
    begin
      CopyMemory(p, buf, len);
      exit;
    end;
    CopyMemory(p, buf, t);
    MD5Transform(ctx);
    Inc(buf, t);
    Dec(len, t);
  end;
  
  while (len >= 64) do
  begin
    CopyMemory(@(ctx.indata), buf, 64);
    MD5Transform(ctx);
    Inc(buf, 64);
    Dec(len, 64);
  end;
  
  CopyMemory(@(ctx.indata), buf, len);
end;

procedure MD5Final(var ctx: MD5Context; digest: PChar);
var
  count: UINT;
  p: PBYTE;
begin
  count := (ctx.bits[0] shr 3) and $3F;
  p := PBYTE(ctx.indata + count);
  p^ := $80;
  Inc(p);
  count := 64 - 1 - count;
  if (count < 8) then
  begin
    FillChar(PBYTE(P)^, count, 0);
    MD5Transform(ctx);
    FillChar(ctx.indata, 56, 0);
  end
  else FillChar(PBYTE(p)^, count - 8, 0);
  
  PUINT(PChar(@(ctx.indata))+14 * sizeof(UINT))^ := ctx.bits[0];
  PUINT(PChar(@(ctx.indata))+15 * sizeof(UINT))^ := ctx.bits[1];
  MD5Transform(ctx);
  CopyMemory(digest, @(ctx.buf), 16);
  FillChar(ctx, sizeof(ctx), 0);
end;

function MD5String(S: string): string;
var
  ctx: MD5Context;
  digest: array[0..15]of char;
  I: integer;
begin
  MD5Init(ctx);
  MD5Update(ctx, PBYTE(PChar(S)), Length(S));
  MD5Final(ctx, digest);
  result := '';
  for i := 0 to 15 do begin
    result := Result + LowerCase(IntToHex(BYTE(digest[i]), 2));
  end;
end;

{

Crescent作者:

このソースは下記を利用しています。
http://forum.nifty.com/fdelphi/samples/01242.html

下記は上記サイトに書かれている利用条件の抜粋

　このソフトウェアは http://www.fourmilab.ch/md5/ でパブリックド
　メインとして公開されているソフトウェアのソースコード（C言語用）
　を ObjectPascal に翻訳したものです。よって誰でも無料かつ無条件
　で利用できます。
　　翻訳については私（河邦 正、GCC02240@nifty.com）に著作権が発生
　しますが、これによる使用条件などの制限は一切追加しません。

}

end.

