unit RC4;
{
*********************************************************

RC4共通鍵暗号ルーチン
Delphi版

  programmed by "replaceable anonymous"
*********************************************************

オリジナルプログラム

  "Winny ノード情報復号(winnyaddrdec)"
  http://www.geocities.co.jp/SiliconValley-Sunnyvale/7511/
    SIWITA by hikobae

  このプログラムは上記オリジナルプログラムのなかの
  RC4ルーチンを元に作成しました。

http://www.geocities.co.jp/SiliconValley-Sunnyvale/7511/readme.html
>著作権
>このサイト内の文章や、このサイトで配布しているツール等の著作権は
>私（ hikobae ）が保持します。フリーで配布していますが著作権を放棄
>しているわけではありません。各ツール等には原則としてソースファイルを
>同梱していますが、それについても同様です。
>ソースファイルは自由に利用していただいてかまいませんが、ソースファイルを
>利用して作成したツールやソフトを公開する際には、このサイト内のソースファイルを
>利用したことを readme.txt 等に明記してください。
>このサイト内の文章や、このサイトで配布しているツール等の転載・再配布・ミラー等
>は原則として禁止します。

とありますので、ソースファイルを利用させていただきます。
*********************************************************
Delphi版改版履歴

  ver 0.0.0   2004/02/12
    c版から移植

  ver 0.1.0   2004/03/21
    ストリームバージョンも作った。
    1byte多くなるバグを修正

  ver 0.1.1   2004/03/24
    長さ指定できるように改良

/////////////////////////////////////////////////////////

}

interface

uses
  SysUtils, Classes;

type
  TRC4Crypt = class(TObject)
  private
    FTable: array[0..255] of Byte;
  public
    constructor Create(key: String);
    function Encrypt(const source: String): String; overload;
    function Encrypt(source: TStream; len: Integer = -1): String; overload;
    procedure Encrypt(source: TStream; dest: TStream; len: Integer = -1); overload;
  end;

  ERC4CreateError = class(Exception);

implementation

constructor TRC4Crypt.Create(key: String);
var
  keylen: Integer;
  tmpkey: array[0..255] of Byte;
  i,j: Integer;
  tmp,a: Byte;
begin
    keylen := length(key);
    if keylen < 1 then
      raise ERC4CreateError.Create('keylen = 0');

    j := 0;
    for i := 0 to 255 do
    begin
      FTable[i] := i;
      Inc(j);
      tmpkey[i] := Byte(key[j]);
      if j >= keylen then
        j := 0;
    end;

    a := 0;
    for i := 0 to 255 do
    begin
      a := a + FTable[i] + tmpkey[i];
		  tmp := FTable[i];
		  FTable[i] := FTable[a];
		  FTable[a] := tmp;
    end;
end;

function TRC4Crypt.Encrypt(const source: String): String;
var
  a,b,tmp,t: Byte;
  i: Integer;
begin
    a := 0;
    b := 0;
    SetLength(Result,length(source));
    for i := 1 to length(source) do
    begin
      Inc(a);
      b := b + FTable[a];
      tmp := FTable[a];
      FTable[a] := FTable[b];
      FTable[b] := tmp;
      t := FTable[a] + FTable[b];
      Byte(Result[i]) := (Byte(source[i]) xor FTable[t]);
    end;
end;

function TRC4Crypt.Encrypt(source: TStream; len: Integer = -1): String;
var
  a,b,tmp,t: Byte;
  s_byte: Byte;
  i: Integer;
begin
    a := 0;
    b := 0;
    if (len < 0) or (len > (source.Size-source.Position)) then
      len := source.Size-source.Position;
    SetLength(Result,len);
    for i := 1 to len do
    begin
      Inc(a);
      b := b + FTable[a];
      tmp := FTable[a];
      FTable[a] := FTable[b];
      FTable[b] := tmp;
      t := FTable[a] + FTable[b];
      source.Read(s_byte,1);
      Byte(Result[i]) := (s_byte xor FTable[t]);
    end;
end;

procedure TRC4Crypt.Encrypt(source: TStream; dest: TStream; len: Integer = -1);
var
  a,b,tmp,t: Byte;
  d_byte,s_byte: Byte;
  i: Integer;
begin
    a := 0;
    b := 0;
    if (len < 0) or (len > (source.Size-source.Position)) then
      len := source.Size-source.Position;
    for i := 1 to len do
    begin
      Inc(a);
      b := b + FTable[a];
      tmp := FTable[a];
      FTable[a] := FTable[b];
      FTable[b] := tmp;
      t := FTable[a] + FTable[b];
      source.Read(s_byte,1);
      d_byte := s_byte xor FTable[t];
      dest.Write(d_byte,1);
    end;
end;

end.
