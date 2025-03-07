
unit Base64;

interface

uses
  SysUtils, WinTypes, Classes;

function base64encode(Stream: TStream; Size: Integer): string;
function base64decode(Stream: TStream; Text: string): Integer;

implementation

// ３バイト分のバイトオーダーを修正する（Kylixでは不要のはず）
function exchange_0_2(Src: DWORD): DWORD;
type
  TTemp = array[0..3]of BYTE;
begin
  Result := Src;
  TTemp(Result)[2] := TTemp(Src)[0];
  TTemp(Result)[0] := TTemp(Src)[2];
end;

// StreamからSizeバイトを読み込み、エンコードした文字列を返す
function base64encode(Stream: TStream; Size: Integer): string;
const
  Table: PChar =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
var
  Buffer, Src: Pointer;
  Dst: PChar;
  I: Integer;

  procedure doNbyte(N: Integer);
  var
    Value: DWORD;
    I: Integer;
  begin
    if not(N in [1..3]) then Exit;
    Value := 0;
    // SrcからＮバイトをValueに読み込む
    Move(PBYTE(Src)^, Value, N);
    // バイトオーダーを修正（Kylixでは不要のはず）
    Value := exchange_0_2(Value);
    // Srcの読み込み位置を進める
    Inc(Integer(Src), N);
    // 6ビットずつエンコード×４回
    for I := 3 downto 0 do
    begin
      if I > N then
        Dst[I] := '=' // 変換しない分は‘=’でパディングする
      else
        Dst[I] := Table[Value and $3f];
      Value := Value shr 6;
    end;
    // 次の書き込み位置にする
    Inc(Integer(Dst), 4);
  end;

begin
  Buffer := AllocMem(Size);
  try
    Size := Stream.Read(PBYTE(Buffer)^, Size);
    // エンコード後の文字列の長さにする
    SetLength(Result, (Size + 2) div 3 * 4);
    if Size > 0 then
    begin
      // 読み込み元のポインタ
      Src := Buffer;
      // 書き込み先のポインタ
      Dst := PChar(Result);
      // ３バイトずつ書き込む
      for I := 0 to Size div 3 - 1 do
        doNbyte(3);
      if (Size mod 3) > 0 then
        doNbyte(Size mod 3);
    end;
  finally
    FreeMem(Buffer);
  end;
end;

// TextをデコードしてStreamに書き込み、書き込んだバイト数を返す
function base64decode(Stream: TStream; Text: string): Integer;
var
  Src: PChar;
  I: Integer;

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

  function doNbyte: Integer;
  var
    I, N: Integer;
    Value: DWORD;
  begin
    // パディング文字‘=’の有無を調べる
    N := 3; // デコード後のバイト数をNにセット
    for I := 2 to 3 do
    begin
      if Src[I] = '=' then
      begin
        N := I - 1;
        break;
      end;
    end;
    // ４文字をデコードする
    value := 0;
    for I := 0 to 3 do
    begin
      // １文字を６ビットに変換×４回
      Value := Value shl 6;
      Inc(Value, decode(PBYTE(Src)^));
      Inc(Integer(Src));
    end;
    // バイトオーダーを修正（Kylixでは不要のはず）
    Value := exchange_0_2(Value);
    // デコードしたデータの書き込み
    Result := Stream.Write(Value, N);
  end;

begin
  Result := 0;
  Src := PChar(Text);
  // ４文字ずつデコード
  for I := 0 to (Length(Text) div 4) - 1 do
    // 書き込んだバイト数をResultにカウントする
    Inc(Result, doNbyte);
end;

end.

