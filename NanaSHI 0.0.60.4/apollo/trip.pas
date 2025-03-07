unit trip;
{
*********************************************************
新月&Crescent トリップ認証ルーチン
インタフェース
(元ファイル名apollo.pas)

  programmed by "replaceable anonymous"

/////////////////////////////////////////////////////////
内部で変換を行うのでBase64, MD5が必要です
*********************************************************

改版履歴
  ver 0.0.0 2004/02/12
    試験実装完成

  ver 0.1.0 2004/02/15
    gcc+gmp版との互換をとった
    桁数が小さくなることがあるのを修正
    1024bit版で配分が偏りすぎなのを変更
    (トリップ仕様ver0.2)

  ver 0.2.0 2004/02/17
    関数形式に書き換えた

  ver 0.3.0 2004/03/20
    1024bit版を復活、細部修正(トリップ仕様ver0.3)
    署名、認証での無駄なコピーを廃止

  ver 0.3.1 2004/03/24
    暗号化ルーチンを確定(暗号化仕様ver0.0)

*********************************************************
トリップ仕様ver0.3 2004/03/20

  ##apollo512-2 2004/02/16
	1)文字列変換ルール(base64.c)

		多倍長整数<->文字列
			最下位6bitからbase64テーブルに準拠して変換
			文字列の先頭文字が整数の最下位6bit
			文字列の最後尾が最上位

			想定される字数に足りない時は0が補充される
			(文字変換時にAが足される)

		鍵文字圧縮
			与えられた鍵文字列のMD5ハッシュをとり、
			そのbase64エンコードの先頭11文字をとる

	2)鍵の生成ルール

		素数テストにはミラーテストを使用し、最初の10個の
		素数に対してパスした擬素数を素数とみなす。

		公開乗数eは65537

		トリップ生成文字列から素数p,qを生成
			生成文字列依存のランダムなp,qのとり方
				hash1:  トリップ生成文字列($key)のMD5ハッシュ
				hash2:  $key + 'pad1'  のMD5ハッシュ
				hash3:  $key + 'pad2'  のMD5ハッシュ
				hash4:  $key + 'pad3'  のMD5ハッシュ

				とし、hashsをその連結とする。

				pのnum[0]-num[6] := hashs[0-27] (28byte)
				qのnum[0]-num[8] := hashs[28-63](36byte)
				(little-endianで処理する。つまりhashsの最初の
				バイトがpの最下位バイトになるように)

				pが216bitより小さな因数になるのを防ぐため
				p.num[6]の下から24bit目(216bit目、第215bit)を1にする
				qが280bitより小さな因数になるのを防ぐため
				q.num[8]の下から24bit目(280bit目、第279bit)を1にする
				これにより、nが496bitを下回ることはない

			p,qをRSAに適する素数にする変換則
				qをq以上で最小の擬素数とする
				pをp以上で最小の擬素数とする

				(p-1)(q-1)とe=65537が互いに素 かつ
				t = 0x7743,de ≡ 1 mod(p-1)(q-1),n = pq なるt,d,nに対し
				t^ed ≡ t (mod n)が成立

				を満たすp,qが出るまでp+=2,q+=2して素数テストから繰り返す
				ただし生成失敗回数(300=RSACreateGiveup)を超えるとエラー

		こうして生成したnを公開鍵、dを秘密鍵と称する
		文字列に変換する際は上記変換則を用いて86文字とする

	3)署名ルール
		RSA暗号化 m^d ≡ c (mod n)
		に使用するmの変換ルール

		与えられた署名対象ハッシュ文字列をMes[0-63]とする
		64byteに満たない場合、空きには0が仮定され、
		超える場合は超えた部分は無視される

		m.num[0-15] := Mes[0-63](64byte)
		(little-endianで処理する。Mesの最初のバイトはmの最下位バイト)


  ##apollo1024-3 2004/03/20
	1)文字列変換ルール
    apollo512-2 と同じ

	2)鍵の生成ルール

		素数テストにはミラーテストを使用し、最初の10個の
		素数に対してパスした擬素数を素数とみなす。

		公開乗数eは65537

		トリップ生成文字列から素数p,qを生成
			生成文字列依存のランダムなp,qのとり方
				hash1:  トリップ生成文字列($key)のMD5ハッシュ
				hash2:  $key + 'pad1'  のMD5ハッシュ
				hash3:  $key + 'pad2'  のMD5ハッシュ
				hash4:  $key + 'pad3'  のMD5ハッシュ
				hash5:  $key + 'pad4'  のMD5ハッシュ
				hash6:  $key + 'pad5'  のMD5ハッシュ
				hash7:  $key + 'pad6'  のMD5ハッシュ
				hash8:  $key + 'pad7'  のMD5ハッシュ

				とし、hashsをその連結とする。

				pのnum[0]-num[12] := hashs[0-51] (52byte)
				qのnum[0]-num[18] := hashs[52-127](76byte)
				(little-endianで処理する。つまりhashsの最初の
				バイトがpの最下位バイトになるように)

				pが410bitより小さな因数になるのを防ぐため
				p.num[12]の下から26bit目(410bit目、第409bit)を1にする
				qが602bitより小さな因数になるのを防ぐため
				q.num[18]の下から26bit目(602bit目、第601bit)を1にする
				これにより、nが1012bitを下回ることはない

			p,qをRSAに適する素数にする変換則
				qをq以上で最小の擬素数とする
				pをp以上で最小の擬素数とする

				(p-1)(q-1)とe=65537が互いに素 かつ
				t = 0x7743,de ≡ 1 mod(p-1)(q-1),n = pq なるt,d,nに対し
				t^ed ≡ t (mod n)が成立

				を満たすp,qが出るまでp+=2,q+=2して素数テストから繰り返す
				ただし生成失敗回数(300=RSACreateGiveup)を超えるとエラー

		こうして生成したnを公開鍵、dを秘密鍵と称する
		文字列に変換する際は上記変換則を用いて171文字とする

	3)署名ルール
		apollo512-2 と同じ

*********************************************************
暗号化仕様(ver0.0 2004/03/24)

  暗号化にはRSA公開鍵暗号とRC4共通鍵暗号を併用する。
  RC4の鍵をランダムに生成し、公開鍵暗号で暗号化して付加する。

  a)暗号化手順
    トリップ(pubkey)=nの桁数と同じ長さの乱数を用意する。
    ただし、数値化したときにnを超えてはならない(RSAでの要請)
    これをmとする。
    mをnとeで暗号化する(c = m^e mod n)
    RC4の鍵としてmを使い、与えられた平文を暗号化する。
    c(公開鍵で暗号化したRC4の鍵)+RC4の暗号文をBase64エンコードする

  b)復号手順
    暗号文をBase64デコードし、暗号化されたRC4鍵(=c)を得る。
    秘密鍵(=d)と公開鍵(=n)でcを復号し、RC4鍵を得る(m = c ^ d mod n)
    RC4の鍵としてmを使い、デコード済みの暗号文を復号する

*********************************************************
*********************************************************
説明書き
  procedure RSAkeycreate512(var publickey: String;var secretkey: String;const keystr: String);
  procedure RSAkeycreate1024(var publickey: String;var secretkey: String;const keystr: String);
  トリップ鍵ペア作成を作成
    keystr: トリップ元文字列
    publickey: 公開鍵文字列(法n)
    secretkey: 秘密鍵文字列(秘密鍵乗数d)

  以下のルーチンはどちらの仕様のトリップ鍵ペアであっても動きます

  function RSAsign(const mes: String;const publickey: String;const secretkey: String): String;
  署名
    返り値: 署名文字列
    mes:  署名対象(nよりも短いことが必要)
      mesには署名したい対象のMD5などを与えてください

  function RSAverify(const mes: String;const testsignature: String;const publickey: String): Boolean;
  認証
    返り値: 通ればtrue
    mes:  署名対象(nよりも短いことが必要)
    testsignature: 署名文字列

  function triphash(const keystr: String): String;
  鍵文字圧縮 みやすいように11文字に圧縮します
  (keystrのMD5ハッシュのBase64エンコード先頭11文字)


  function RSAencrypt(const plainmes: String;const publickey: String): String;
  公開鍵による暗号化 トリップキーを知っている人だけが開錠できる暗号化を施します
    返り値: 暗号化文
    plainmes: 暗号化したい文

  function RSAdecrypt(const cryptmes: String;const publickey: String;const secretkey: String): String;
  秘密鍵による復号 RSAencryptされた暗号化文を復号します
  処理には鍵ペアが必要です
    返り値: 復号された文
    cryptmes: 暗号化文
}
interface

  procedure RSAkeycreate512(var publickey: String;var secretkey: String;const keystr: String);
  procedure RSAkeycreate1024(var publickey: String;var secretkey: String;const keystr: String);
  //トリップ鍵ペア作成

  function RSAsign(const mes: String;const publickey: String;const secretkey: String): String;
  //署名

  function RSAverify(const mes: String;const testsignature: String;const publickey: String): Boolean;
  //認証

  function triphash(const keystr: String): String;
  //鍵文字圧縮 11文字に圧縮

  function RSAencrypt(const plainmes: String;const publickey: String): String;
  //公開鍵による暗号化

  function RSAdecrypt(const cryptmes: String;const publickey: String;const secretkey: String): String;
  //秘密鍵による復号(鍵ペアが必要)

implementation

uses SysUtils, Classes, longint, RSAbase, Base64, MD5, RC4;

procedure little_endian_copy(var dest;const s: PChar; count: Integer);
type
  TNum = array[0..MaxListSize+2] of Cardinal;
var
  i,j,max: Integer;
  tmp: Cardinal;
begin
    max := count shr 2;
    j := 0;
    for i := 0 to max-1 do
    begin
      j := i shl 2;
      TNum(dest)[i] := (((((Cardinal(s[j+3]) shl 8)+Cardinal(s[j+2])) shl 8)
                        +Cardinal(s[j+1])) shl 8) + Cardinal(s[j]);
    end;
    tmp := 0;
    for i := count-1 downto j+4 do
    begin
      tmp := tmp shl 8;
      tmp := tmp + Cardinal(s[i]);
    end;
    TNum(dest)[max] := tmp;
end;

function base64encodeLINT(n: TLINT; len: Integer): string;
const
  CTable: PChar =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
var
  i,j: Integer;
begin
    Result := '';
    if n.Len = 0 then
    begin
      Exit;
    end;

    SetLength(Result,len);
    i := 0;
    repeat
      Inc(i);
      Result[i] := Char(n.Num[0] and $3f);
    until lshr1(@n,6).Len = 0;

    for j := i+1 to len do
      Result[j] := Char(0);

    for i := 1 to len do
    begin
      Result[i] := CTable[Byte(Result[i])];
    end;
end;

function base64decodeLINT(var n: TLINT;const Str: string; len: Integer): PLINT;

  // 各文字を６ビットデータに変換する
  function decode(code: BYTE): BYTE;
  begin
    case Char(code) of
    'A'..'Z': Result := code - BYTE('A');
    'a'..'z': Result := code - BYTE('a') + 26;
    '0'..'9': Result := code - BYTE('0') + 52;
    '+': Result := 62;
    '/': Result := 63;
    else Result := 0; // ‘=’の場合も‘0’を返す
    end;
  end;

var
  i: Integer;
  Data: String;
begin
    Result := @n;
    lset(@n,0);
    Data := Str;

    SetLength(Data,len);
    for i := length(Data)+1 to len do
      Data[i] := 'A';

    for i := len downto 1 do
    begin
      lshl1(@n,6);
      if n.Len > LINTMaxLen then
        raise ELINTOverflow.Create('overflow');
      alinc(@n,decode(Byte(Data[i])));
    end;
end;

function triphash(const keystr: String): String;
var
  ctx: MD5Context;
  digest: array[0..15]of char;
  mStream: TMemoryStream;
begin
    MD5Init(ctx);
    MD5Update(ctx, PBYTE(PChar(keystr)), Length(keystr));
    MD5Final(ctx, digest);
    mStream := TMemoryStream.Create;
    mStream.Position := 0;
    mStream.Write(digest,16);
    mStream.Position := 0;
    Result := copy(base64encode(mStream,mStream.Size),1,11);
    mStream.Free;
end;

function RSAsign(const mes: String;const publickey: String;const secretkey: String): String;
var
  keypair: TRSAkeybase;
  len,keylen: Integer;
  m: TLINT;
begin
    len := length(mes);
    keylen := length(publickey);
    if(len*4 > keylen*3) then
      len := keylen*3 div 4;
    if(len > LINTMaxLen*4) then
      raise ERSAError.Create('overflow: too long publickey');
    if(len = 0) then
      raise ERSAError.Create('sign.HashToLINT: null input');
    lset(@m,0);
    Move(mes[1],m.num[0],len);
    m.Len := ((len-1) shr 2) + 1;
    base64decodeLINT(keypair.n,publickey,keylen);
    base64decodeLINT(keypair.d,secretkey,keylen);
    RSAbase_encrypt(m,keypair);
    Result := base64encodeLINT(m,keylen);
end;

function RSAverify(const mes: String;const testsignature: String;const publickey: String): Boolean;
var
  len,keylen: Integer;
  m,c,n: TLINT;
begin
    len := length(mes);
    keylen := length(publickey);
    if(len*4 > keylen*3) then
      len := keylen*3 div 4;
    if(len > LINTMaxLen*4) then
      raise ERSAError.Create('overflow: too long publickey');
    if(len = 0) then
      raise ERSAError.Create('sign.HashToLINT: null input');
    lset(@m,0);
    Move(mes[1],m.num[0],len);
    m.Len := ((len-1) shr 2) + 1;
    base64decodeLINT(n,publickey,keylen);
    base64decodeLINT(c,testsignature,keylen);
    RSAbase_decrypt(c,n);
    Result := (lcmp(@c,@m) = 0);
end;

///////////////////////////////////////////////////////////////////////
// 512bit RSA (apollo512-2) 2004/02/16
///////////////////////////////////////////////////////////////////////
procedure Make512pq(out a1: TLINT; out a2: TLINT; const Seed: string);
var
  ctx: MD5Context;
  keystr: String;
  hashs: array[0..63] of Char;
begin
    if LINTMaxLen < 16 then
      raise ERSAError.Create('overflow: need 512bit(len:16)');
    lset(@a1,0);
    lset(@a2,0);
    keystr := Seed;
    MD5Init(ctx);
    MD5Update(ctx, PBYTE(PChar(keystr)), Length(keystr));
    MD5Final(ctx, @hashs[0]);
    keystr := Seed + 'pad1';
    MD5Init(ctx);
    MD5Update(ctx, PBYTE(PChar(keystr)), Length(keystr));
    MD5Final(ctx, @hashs[16]);
    keystr := Seed + 'pad2';
    MD5Init(ctx);
    MD5Update(ctx, PBYTE(PChar(keystr)), Length(keystr));
    MD5Final(ctx, @hashs[32]);
    keystr := Seed + 'pad3';
    MD5Init(ctx);
    MD5Update(ctx, PBYTE(PChar(keystr)), Length(keystr));
    MD5Final(ctx, @hashs[48]);

    Move(hashs[0],a1.num[0],28);
    Move(hashs[28],a2.num[0],36);
    a1.Num[6] := a1.Num[6] or $800000;
    a2.Num[8] := a2.Num[8] or $800000;
    a1.Len := 7;
    a2.Len := 9;
end;

procedure RSAkeycreate512(var publickey: String;var secretkey: String;const keystr: String);
var
  keypair: TRSAkeybase;
  p,q: TLINT;
begin
    Make512pq(p,q,keystr);
    RSAbase_generate(keypair,p,q);
    publickey := base64encodeLINT(keypair.n,86);
    secretkey := base64encodeLINT(keypair.d,86);
end;

///////////////////////////////////////////////////////////////////////
// 1024bit RSA (apollo1024-3) 2004/03/30
///////////////////////////////////////////////////////////////////////
procedure Make1024pq(out a1: TLINT; out a2: TLINT; const Seed: string);
const
  pads: array[0..7] of PChar = ('','pad1','pad2','pad3','pad4','pad5','pad6','pad7');
var
  ctx: MD5Context;
  keystr: String;
  hashs: array[0..127] of Char;
  i: Integer;
begin
    if LINTMaxLen < 32 then
      raise ERSAError.Create('overflow: need 1024bit(len:32)');
    lset(@a1,0);
    lset(@a2,0);
    for i := 0 to 7 do
    begin
      keystr := Seed + string(pads[i]);
      MD5Init(ctx);
      MD5Update(ctx, PBYTE(PChar(keystr)), Length(keystr));
      MD5Final(ctx, @hashs[i shl 4]);
    end;

    Move(hashs[0],a1.num[0],52);
    Move(hashs[52],a2.num[0],76);
    a1.Num[12] := a1.Num[12] or $2000000;
    a2.Num[18] := a2.Num[18] or $2000000;
    a1.Len := 13;
    a2.Len := 19;
end;

procedure RSAkeycreate1024(var publickey: String;var secretkey: String;const keystr: String);
var
  keypair: TRSAkeybase;
  p,q: TLINT;
begin
    Make1024pq(p,q,keystr);
    RSAbase_generate(keypair,p,q);
    publickey := base64encodeLINT(keypair.n,171);
    secretkey := base64encodeLINT(keypair.d,171);
end;


function RSAencrypt(const plainmes: String;const publickey: String): String;
var
  keylen: Integer;
  m,c,n: TLINT;
  RC4salt: String;
  RC4crypt: TRC4Crypt;
  i: Integer;
  mStream: TMemoryStream;
begin
    keylen := length(publickey);
    base64decodeLINT(n,publickey,keylen);
    lset(@m,0);
    lset(@c,0);
    m.Len := n.Len;
    for i := 0 to n.Len-2 do
    begin
      m.Num[i] := Random($ffffffff);
    end;
    m.Num[n.Len-1] := Random(n.Num[n.Len-1]);
    if m.Num[n.Len-1] = 0 then
      m.Num[n.Len-1] := 1;
    SetLength(RC4salt,m.Len*4);
    Move(m.Num[0],RC4salt[1],m.Len*4);
    RSAbase_decrypt(m,n);
    RC4crypt := TRC4Crypt.Create(RC4salt);
    mStream := TMemoryStream.Create;
    mStream.Position := 0;
    mStream.Write(m.num[0],m.Len*4);
    mStream.Write(RC4crypt.Encrypt(plainmes)[1],length(plainmes));
    mStream.Position := 0;
    Result := base64encode(mStream,mStream.Size);
    mStream.Free;
    RC4crypt.Free;
end;

function RSAdecrypt(const cryptmes: String;const publickey: String;const secretkey: String): String;
var
  keylen: Integer;
  keypair: TRSAkeybase;
  c: TLINT;
  RC4salt: String;
  RC4crypt: TRC4Crypt;
  mStream: TMemoryStream;
begin
    keylen := length(publickey);
    base64decodeLINT(keypair.n,publickey,keylen);
    base64decodeLINT(keypair.d,secretkey,keylen);
    lset(@c,0);
    c.Len := keypair.n.Len;
    mStream := TMemoryStream.Create;
    mStream.Position := 0;
    base64decode(mStream,cryptmes);
    mStream.Position := 0;
    mStream.Read(c.num[0],c.Len*4);
    RSAbase_encrypt(c,keypair);
    SetLength(RC4salt,c.Len*4);
    Move(c.Num[0],RC4salt[1],c.Len*4);
    RC4crypt := TRC4Crypt.Create(RC4salt);
    Result := RC4crypt.Encrypt(mStream);
    mStream.Free;
    RC4crypt.Free;
end;

initialization
    Randomize;

end.
