unit longint;
{
*********************************************************

多倍長整数演算ルーチン longint

  programmed & arranged by "replaceable anonymous"
*********************************************************

原作:
  オリジナルは基数が100です
	http://www5.airnet.ne.jp/tomy/
		(Tomy's home page/技術計算用Cプログラムソース by Tomy)

参考図書 :
	コンピュータと素因子分解/和田秀男著/遊星社
	UBASICによるコンピュータ整数論/木田祐司・牧野潔夫著/日本評論社

*********************************************************


Delphi版改版履歴

ver 0.0.0 2004/01/19
    cベースからDelphiベースに移植開始
      ゼロクリアをFillCharに
      register呼び出し規約に変更

ver 0.0.1 2004/01/20
    1add移植。細部修正

ver 0.0.2 2004/01/22
    2mul移植。細部修正
      smuladd(d=d+a*b,lmulpで使用)を独立、細部修正
      lmul系で第1引数書き換え型の物も用意
        lmulp,lmulpb/lmul(overload)

ver 0.0.3 2004/01/25
    3div移植。細部修正
      文字列LINT変換ルーチンをStringを使用するようにした
    2mul修正
      lmulpでldivpと同様に内部バッファを動的確保するようにした
    計算ルーチンに関してTLINTのサイズよりも大きいバッファが与えて
    強引に計算させてもバッファが溢れないようになったはず

ver 0.0.4 2004/01/25
    4lib移植。細部修正
      lpwrの引数を変更(原作のに戻した)

ver 0.0.5 2004/02/10
    PCharLib(3divの変換ルーチンのPChar版)
    バグfix
      lmulpbで動的に確保したバッファのクリアミスを修正
      lfixbをlmulpb用に改良
      lmulpで内部バッファからの書き戻しミスを修正

ver 0.1.1 2004/02/15
    どっちでもいいことだがDWORDをCardinalに戻した。
    32bitの符号なし整数なら何でもいいわけで。
    さすがにそれが違うのは知らん

ver 0.1.2 2004/02/18
    aux1とalsubでキャリーフラグをクリアしてなかったのを修正

////////////////////////////////////////////////////////

C版改版履歴

ver 0.1 2003/09/12
	原作ルーチンをすべて2^32を基数に書き換え。
	その影響でアセンブラも使用。
	アセンブラルーチンは参考図書のアルゴリズムを使用しました。

ver 0.11 2003/10/01
	lwrite派生バージョン追加

ver 0.2 2003/10/02
	論理演算ルーチン追加

ver 0.3 2003/10/10
	lmulpmod追加
	ldivp修正
	lpwrmod修正

*********************************************************

}
interface

uses
  Types,SysUtils;

const
  LINTMaxLen = 32;        {多倍長可変部の最大長}


type
  PLINT = ^TLINT;

  TLINT = record
    Len: Integer;             {可変部の格納データ長;0のときは0}
    Sign: Integer;            {符号;正の時0,負の時非0}
    Num: array[0..LINTMaxLen+1] of Cardinal;
                              {データ部;MAXLEN+2(予備域)}
  end;

  TLINT2 = record             {2倍長バッファ、mod計算用}
    Len: Integer;
    Sign: Integer;
    Num: array[0..LINTMaxLen*2+1] of Cardinal;
  end;

  ELINTError = class(Exception);
  ELINTOverflow = class(ELINTError);
  ELINTIllegalFunctionCall = class(ELINTError);

{内部用定数}
const
  LINTSize = SizeOf(TLINT);   {TLINT型のサイズ(asmルーチン用)}

  LINTStrLen = Trunc(LINTMaxLen*32*0.301)+2;  {10進表示時最大桁数}
  LINTHexStrLen = LINTMaxLen*8+1;             {16進表示時最大桁数}

  LINTBase = 1000000000;  {10進変換時の基準値(10^xでint限界を超えない最大値)}
  LINTBaseLog = 9;        {10進変換時の基準値}
  Pow10 : array[0..9] of Integer = (1,10,100,1000,10000,100000,1000000
                                      ,10000000,100000000,1000000000);

  //1add
  function lfix(a: PLINT): PLINT;
  function lfixb(a: PLINT; len: Integer): PLINT;
  function lset(a: PLINT; n: Integer): PLINT;
  function alinc(a: PLINT; n: Cardinal): PLINT; register;
  function aldec(a: PLINT; n: Cardinal): PLINT; register;
  function lcmp(const a: PLINT; const b: PLINT): Integer; register;
  function aux1(d: PLINT; const s: PLINT): PLINT; register;
  function alsub(d: PLINT; const s: PLINT): PLINT; register;
  function ldec(a: PLINT; n: Integer): PLINT;
  function linc(a: PLINT; n: Integer): PLINT;
  function ladd(d: PLINT; const s: PLINT): PLINT;
  function lsub(d: PLINT; const s: PLINT): PLINT;
  //2mul
  function smul(a: PLINT; b: Cardinal; w: Cardinal = 0): PLINT; register;
  function smuladd(d: PLINT;const a: PLINT; b: Cardinal): PLINT; register;
  function lshl32(a: PLINT; c: Integer): PLINT; register;
  function lshr32(a: PLINT; c: Integer): PLINT; register;
  function lshl1(a: PLINT; c: Integer): PLINT; register;
  function lshr1(a: PLINT; c: Integer): PLINT; register;
  function lmulp(a: PLINT; const b: PLINT): PLINT; register;
  function lmulpb(w: PLINT; const a: PLINT; const b: PLINT): PLINT; register;
  function lmul(w: PLINT; const a: PLINT; const b: PLINT): PLINT; overload;
  function lmul(a: PLINT; const b: PLINT): PLINT; overload;
  //3div
  function sdiv(a: PLINT; n: Cardinal; out r: Cardinal): PLINT; register;
  function StrToLINT(var a:TLINT; str: String): PLINT;
  function LINTtoStr(a:TLINT): String; overload;
  function LINTtoStr(a:TLINT; divnum: Integer): String; overload;
  function HexStrToLINT(var a:TLINT; str: String): PLINT;
  function LINTtoHex(a:TLINT): String; overload;
  function LINTtoHex(a:TLINT; divnum: Integer): String; overload;
  function ldivp(a: PLINT; const b: PLINT; c: PLINT): PLINT; cdecl;
  function ldiv1(a: PLINT; const b: PLINT; c: PLINT): PLINT;
  //4lib
  function lgcd(gcd: PLINT; a: TLINT; b: TLINT): PLINT;
  function llcm(lcm: PLINT; const a: TLINT; const b: TLINT): PLINT;
  function linv(x: PLINT; s: TLINT; n: TLINT): PLINT;
  function lmulmod(a: PLINT; const b: PLINT; const n: PLINT): PLINT;
  function lpwr(x: PLINT; y: Cardinal): PLINT;
  function lpwrmod(x :PLINT; const y: PLINT; const n: PLINT): PLINT;
  //PCharLib
  function PStrToLINT(var a:TLINT; const str: PChar): PLINT;
  function LINTtoPStr(dest: PChar; a:TLINT): PChar; overload;
  function LINTtoPStr(dest: PChar; a:TLINT; divnum: Integer): PChar; overload;
  function HexPStrToLINT(var a:TLINT; const str: PChar): PLINT;
  function LINTtoPHex(dest: PChar; a:TLINT): PChar; overload;
  function LINTtoPHex(dest: PChar; a:TLINT; divnum: Integer): PChar; overload;


implementation

uses
  StrUtils;

(****************************************************
  1add
    基本操作、加算減算ルーチン
 ****************************************************)

//
//  LINT *lfix(LINT *a)
//    LINT型として不適切な長さ(データ長)を修正する
//    余剰部分をクリアする
//
//    注)この関数は定義されたLINTMaxLenでしか使えない
//       LINTの長さが異なるとバッファオーバフローや
//       ゴミが残ることがあります
//
//  LINT *lfixb(LINT *a,int len)
//    長さのチェックを弱く行う
//    LINTより長い長さを許容する
//    lenより長さが短ければlenをバッファ長とみてクリアする
//
function lfix(a: PLINT): PLINT;
var
  p: ^Cardinal;
begin
    if a.Len < 0 then
      a.Len := 0
    else if a.Len > LINTMaxLen then
      a.Len := LINTMaxLen;

    p := @(a.Num[a.Len]);
    FillChar(p^,SizeOf(Integer)*(High(a.Num)-a.Len+1),0);

    Result := a;
end;

function lfixb(a: PLINT; len: Integer): PLINT;
var
  p: ^Cardinal;
begin
    Result := a;

    if a.Len < 0 then
      a.Len := 0;
    if a.Len >= len then
      Exit;
    p := @(a.Num[a.Len]);
    FillChar(p^,SizeOf(Integer)*(len-a.Len),0);
end;

//
//  LINT *lset(LINT *a,int n)
//    int型整数をLINT型変数に代入する
//
//    注)この関数は定義されたLINTMaxLenまででしか使えない
//       LINTの長さが異なるとバッファオーバフローや
//       ゴミが残ることがあります
//
function lset(a: PLINT; n: Integer): PLINT;
begin
    FillChar(a^,SizeOf(TLINT),0);

    Result := a;
    if n = 0 then
      Exit;
    if n < 0 then
    begin
      a.Sign := -1;
      n := - n;
    end;

    a.Num[0] := n;
    a.Len := 1;
end;

//
//  LINT *alinc(LINT *a,unsigned int n)
//    対単整数絶対値加算(0 <= n <= 0xFFFFFFFF)
//      バッファオーバランはテストしないので呼び出し側で気をつけてください
//      オーバーフローで最大1桁増えます
//
//    eax = a; edx = n
//
function alinc(a: PLINT; n: Cardinal): PLINT; register;
asm
    push    ebx
    test    n,n {加算数の0テスト}
    jz      @IncEnd
  @IncMain:
    mov     ebx,a
    mov     ecx,TLINT[eax].len {a.len}
    test    ecx,ecx
    jnz     @IncMulti
  @IncSet:                     {a=0なのでセットして終わり}
    mov     DWORD PTR [TLINT[eax].num[0]],n    {num[0] = n}
    inc     ecx
    mov     TLINT[eax].len,ecx       {len = 1}
    jmp     @IncEnd
  @IncMulti:
    lea     eax,TLINT[eax].num[0] {edx = &(num[0])}
    add     edx,[eax]
    mov     [eax],edx
    jnc     @IncEnd
  @IncLoop:
    lea     eax,[eax+4]
    dec     ecx
    test    ecx,ecx
    jz      @IncKetaAge
    inc     DWORD PTR [eax]
    jnz     @IncEnd
    jmp     @IncLoop
  @IncKetaAge:
    xor     edx,edx                       {位上がり}
    inc     edx
    mov     [eax],edx                {最上位 = 1}
    inc     TLINT[ebx].len           {a.len++}
  @IncEnd:
    mov     eax,ebx
    pop     ebx
end;


//
//  LINT *aldec(LINT *a,unsigned int n)
//    対単整数絶対値減算(0 <= n <= 0xFFFFFFFF)
//      減算結果がが0をまたぐ時は、符号を反転します(aldec(-5,10) -> +5)
//
//    eax = a; edx = n
//
function aldec(a: PLINT; n: Cardinal): PLINT; register;
asm
    push    ebx
    test    n,n
    jz      @DecEnd  {n=0; そのまま終了}
  @DecMain:
    mov     ebx,a
    mov     ecx,TLINT[ebx].len
    test    ecx,ecx
    jz      @Decset  {a.len=0; 値をセットして終了}
    dec     ecx
    jnz     @DecMulti
    jmp     @DecOne  {a.len=1; 単桁,符号反転の可能性}
  @DecSet:
    mov     DWORD PTR [TLINT[ebx].num[0]],n {a.num[0] = n}
    xor     edx,edx
    dec     edx
    mov     TLINT[ebx].sign,edx  {a.sign=-1}
    inc     ecx
    mov     TLINT[ebx].len,ecx   {a.len = 1}
    jmp     @DecEnd
  @DecOne:
    mov     ecx,DWORD PTR [TLINT[ebx].num[0]]
    sub     ecx,n                           {a.num[0] - n}
    mov     DWORD PTR [TLINT[ebx].num[0]],ecx
    jc      @DecMinus
    jnz     @DecEnd
  @DecZero:                       {結果が0}
    mov     TLINT[ebx].sign,ecx   {a.sign = 0}
    mov     TLINT[ebx].len,ecx    {a.len  = 0}
    jmp     @DecEnd
  @DecMinus:
    neg     ecx
    not     TLINT[ebx].sign     {a.signを反転}
    mov     DWORD PTR [TLINT[ebx].num[0]],ecx  {a.num[0]を反転(正に)}
    jmp     @DecEnd
  @DecMulti:
    lea     ebx,DWORD PTR [TLINT[ebx].num[0]]
    sub     [ebx],edx
    mov     edx,1
    jnc     @DecEnd
  @DecLoop:
    dec     ecx
    lea     ebx,[ebx+4]
    sub     [ebx],edx
    jc      @DecLoop
    jnz     @DecEnd
    test    ecx,ecx
    jnz     @DecEnd
  @DecKetaSage:                     {位下がり}
    dec     TLINT[eax].len
  @DecEnd:
    pop     ebx
end;

//
//  int lcmp(const LINT *a,const LINT *b)
//    絶対値比較
//      返り値
//      |a|<|b| -1
//      |a|=|b|  0
//      |a|>|b|  1
//
function lcmp(const a: PLINT;const b: PLINT): Integer; register;
asm
      push    esi
      push    edi
      mov     esi,b
      mov     edi,a
      xor     eax,eax
      mov     ecx,TLINT[edi].len
      cmp     ecx,TLINT[esi].len    {lenを比較}
      jz      @CmpMain
      jb      @CmpL
  @CmpH:
      inc     eax                   {a>b : eax=1}
      jmp     @CmpEnd
  @CmpL:
      dec     eax                   {a<b : eax=-1}
      jmp     @CmpEnd
  @CmpMain:
      lea     edi,[edi+ecx*4+4]   {最上位から比較}
      lea     esi,[esi+ecx*4+4]
      std
      repe    cmpsd
      jb      @CmpH
      ja      @CmpL
  @CmpE:                            {a=b : eax=0}
  @CmpEnd:
      cld
      pop     edi
      pop     esi
end;

//
//  LINT *aux1(LINT *d,const LINT *s)
//    絶対値加算 d=d+s
//      (但し|d|>=|s|,dの桁数だけ計算される)
//    この演算で符号は操作されない
//
function aux1(d: PLINT;const s: PLINT): PLINT; register;
asm
      push    esi
      push    edi
      mov     esi,s
      mov     edi,d
      mov     ecx,TLINT[edi].len {d.lenだけ繰り返す}
      mov     edx,edi            {dを保存}
      lea     esi,TLINT[esi].num[0]
      lea     edi,TLINT[edi].num[0] {num[0]にポインタをセット}
      clc
  @Aux1Loop:
      mov     eax,[esi]             {下の桁から足していく}
      adc     [edi],eax
      lea     esi,[esi+4]
      lea     edi,[edi+4]
      dec     ecx
      jnz     @Aux1Loop
      jnc     @Aux1End
  @Aux1KetaAge:                     {位上がり}
      inc     DWORD PTR [TLINT[edx].len]
      inc     DWORD PTR [edi]
  @Aux1End:
      mov     eax,edx
      pop     edi
      pop     esi
end;

//
//  LINT *alsub(LINT *d,const LINT *s)
//    絶対値減算 d=d-s
//      (但し|d|>=|s|,dの桁までしか計算されない)
//    この演算で符号は操作されない
//
function alsub(d: PLINT;const s: PLINT): PLINT; register;
asm
      push    esi
      push    edi
      mov     esi,s
      mov     edi,d
      mov     ecx,TLINT[edi].len   {d.lenだけ繰り返す}
      mov     edx,edi              {dのポインタを保存}
      lea     esi,TLINT[esi].num[0]
      lea     edi,TLINT[edi].num[0]
      clc
  @Loop:
      mov     eax,[edi]            {下の桁から減算}
      sbb     eax,[esi]
      mov     [edi],eax
      lea     esi,[esi+4]
      lea     edi,[edi+4]
      dec     ecx
      jnz     @Loop
      test    eax,eax
      jnz     @End
  @KetaSage:
      mov     ecx,TLINT[edx].len   {位下がり}
      std
      lea     edi,[edi-4]          {最上位からはじめに0でない}
      repe    scasd                {桁を走査,(eax=0)}
      jz      @Zero
      inc     ecx                  {0の時のみ長さ0}
  @Zero:
      mov     TLINT[edx].len,ecx
  @End:
      cld
      mov     eax,edx
      pop     edi
      pop     esi
end;

//
//  LINT *ldec(LINT *a,int n)
//    対単整数減算(符号あり) a=a-n
//
function ldec(a: PLINT; n: Integer): PLINT;
begin
    Result := a;
    if n = 0 then
      Exit;

    if a.Len = 0 then
    begin
      lset(a,-n);
      Exit;
    end;
    if a.Sign = 0 then
    begin
      if n > 0 then
        aldec(a,n)
      else
        alinc(a,-n);
    end else
    begin
      if n > 0 then
        alinc(a,n)
      else
        aldec(a,-n);
    end;
end;

//
//  LINT *ldec(LINT *a,int n)
//    対単整数加算(符号あり) a=a-n
//
function linc(a: PLINT; n: Integer): PLINT;
begin
    Result := a;
    if n = 0 then
      Exit;

    if a.Len = 0 then
    begin
      lset(a,n);
      Exit;
    end;
    if a.Sign = 0 then
    begin
      if n > 0 then
        alinc(a,n)
      else
        aldec(a,-n);
    end else
    begin
      if n > 0 then
        aldec(a,n)
      else
        alinc(a,-n);
    end;
end;

//
//  LINT *ladd(LINT *d,const LINT *s)
//    加算(符号あり) d=d+s
//
function ladd(d: PLINT; const s: PLINT): PLINT;
var
  x: TLINT;
begin
    Result := d;

    if s.Len = 0 then
      Exit;
    if d.Len = 0 then
    begin
      d^ := s^;
      Exit;
    end;

    if d.Sign = s.Sign then
    begin
      if lcmp(d,s) >= 0 then
        aux1(d,s)
      else begin
        x := s^;
        aux1(@x,d);
        d^ := x;
      end;
    end else
    begin
      if lcmp(d,s) >= 0 then
        alsub(d,s)
      else begin
        x := s^;
        alsub(@x,d);
        d^ := x;
      end;
    end;
end;

//
//  LINT *ladd(LINT *d,const LINT *s)
//    減算(符号あり) d=d+s
//
function lsub(d: PLINT; const s: PLINT): PLINT;
var
  sign: Integer;
  x: TLINT;
begin
    Result := d;

    if s.Len = 0 then
      Exit;
    if d.Len = 0 then
    begin
      d^ := s^;
      d.Sign := not d.Sign;
      Exit;
    end;

    sign := lcmp(d,s);
    if (sign = 0) and (d.Sign = s.Sign) then
    begin
      lset(d,0);
      Exit;
    end;
    if d.Sign = s.Sign then
    begin
      if sign >= 0 then
        alsub(d,s)
      else begin
        x := s^;
        alsub(@x,d);
        x.Sign := not x.Sign;
        d^ := x;
      end;
    end else
    begin
      if sign >= 0 then
        aux1(d,s)
      else begin
        x := s^;
        aux1(@x,d);
        x.Sign := not x.Sign;
        d^ := x;
      end;
    end;
end;

(****************************************************
  2mul
    乗算、シフト操作ルーチン
 ****************************************************)

//
//  LINT *smul(LINT *a,unsigned int b,unsigned int w)
//    対単整数絶対値乗算 a=a*b+w
//      但しb=0のときはaをlfixしなければならない
//      (長さを0にするがフィールドをクリアしない)
//    オーバーフローで最大1桁増えますので呼び出し側で気をつけてください
//
function smul(a: PLINT; b: Cardinal; w: Cardinal): PLINT; register;
asm
      push    esi
      push    edi
      push    ebx
      push    a                     {destを退避}
      mov     esi,a
      mov     ebx,b
      mov     edi,w
      mov     ecx,TLINT[esi].len
      xor     eax,eax
      mov     TLINT[esi].len,eax    {bが0の時のためにlenをクリア}
      lea     esi,TLINT[esi].num[0]
      test    ebx,ebx
      jz      @KetaFix
      test    ecx,ecx
      jz      @KetaFix
      mov     [esi-8],ecx
  @Loop:                            {a.len回繰り返す}
      mov     eax,[esi]
      xor     edx,edx
      mul     ebx
      add     eax,edi
      adc     edx,0
      mov     [esi],eax
      mov     edi,edx
      lea     esi,[esi+4]
      dec     ecx
      jnz     @Loop
  @KetaFix:                         {桁上がり}
      pop     eax
      test    edi,edi
      jz      @End
      mov     [esi],edi
      inc     TLINT[eax].len
  @End:
      pop     ebx
      pop     edi
      pop     esi
end;

//
//  LINT *smuladd(LINT *d,const LINT *a,unsigned int b)
//    対単整数絶対値乗算加算 d=d+a*b
//      オーバーフロー時は最大2桁増えますので呼び出し側で注意してください
//
function smuladd(d: PLINT;const a: PLINT; b: Cardinal): PLINT; register;
asm
      push    esi
      push    edi
      push    ebx
      mov     ebx,b
      test    ebx,ebx  {b=0 then end}
      jz      @End
      mov     esi,a
      mov     edi,d
      mov     ecx,TLINT[esi].len
      test    ecx,ecx  {a.len=0 then end}
      jz      @End
      push    edi       {dを保存}
      lea     esi,TLINT[esi].num[0]
      lea     edi,TLINT[edi].num[0]
  @Loop:
      lodsd
      xor     edx,edx
      mul     ebx
      add     [edi],eax
      lea     edi,[edi+4]
      adc     [edi],edx
      jc      @Loop2Age
      dec     ecx
      jnz     @Loop
      jmp     @KetaFix
  @Loop2Age:
      mov     eax,1
      add     [edi+4],eax
      dec     ecx
      jnz     @Loop
      lea     edi,[edi+4]
  @KetaFix:
      pop     esi       {dを復元}
      mov     ecx,edi
      sub     ecx,esi
      sar     ecx,2
      dec     ecx       {ecx最大桁数}
      cmp     ecx,TLINT[esi].len
      jae     @KetaTest
      mov     ecx,TLINT[esi].len
    @KetaTest:
      std
      xor     eax,eax
      repz    scasd     {上からみていって0でないところが桁数}
      jz      @KetaSet
      inc     ecx       {すべて0の時以外は+1}
   @KetaSet:
      mov     TLINT[esi].len,ecx
      mov     eax,esi
  @End:
      cld
      pop     ebx
      pop     edi
      pop     esi
end;

//
//  LINT *lshl32(LINT *a,int c)
//    a=a<<c as DWORD           注)バッファオーバランはみません
//  LINT *lshr32(LINT *a,int c)
//    a=a>>c as DWORD           注)0以下の時はゴミが残るのでlfixを
//  LINT *lshl1(LINT *a,int c)
//    a=a<<c as bit             注)cは下位5bitが使用されます
//  LINT *lshr1(LINT *a,int c)
//    a=a>>c as bit             注)cは下位5bitが使用されます
//
//    オーバーフロー時はlshr1は最大1桁、lshr32は最大でc桁増えますので
//    呼び出し側で気をつけてください
//******************************************************************
// lshr32は引数によってはメモリ破壊を引き起こすので特に注意してください
//******************************************************************
function lshl32(a: PLINT; c: Integer): PLINT; register;
asm
      push    esi
      push    edi
      xchg    eax,edx
      test    eax,eax  {c=eax,a=edx}
      jz      @End
      mov     ecx,TLINT[edx].len
      test    ecx,ecx
      lea     esi,[edx+ecx*4+4]  {&a.num[a.len-1] 最上位}
      jz      @End
      add     TLINT[edx].len,eax {a.len+=c}
      lea     edi,[esi+eax*4]    {&a.num[c]}
      std
      rep     movsd
      mov     ecx,eax
      xor     eax,eax
      rep     stosd
  @End:
      mov     eax,edx
      cld
      pop     edi
      pop     esi
end;

function lshr32(a: PLINT; c: Integer): PLINT; register;
asm
      push    esi
      push    edi
      xchg    eax,edx
      test    eax,eax   {eax=c; edx=a}
      jz      @End
      mov     ecx,TLINT[edx].len
      test    ecx,ecx
      lea     edi,TLINT[edx].num[0]
      jz      @End
      lea     esi,[edi+eax*4] {&a.num[eax]}
      sub     ecx,eax
      jle     @Zero           {len<=0ならlen=0}
      mov     TLINT[edx].len,ecx
      rep     movsd
      mov     ecx,eax
      xor     eax,eax
      rep     stosd
      jmp     @End
  @Zero:
      xor     ecx,ecx
      mov     TLINT[edx].len,ecx
  @End:
      mov     eax,edx
      pop     edi
      pop     esi
end;

function lshl1(a: PLINT; c: Integer): PLINT; register;
asm
      push    esi
      push    edi
      push    ebx
      mov     ecx,c
      test    ecx,31
      mov     esi,a                {aを退避}
      jz      @End
      mov     ebx,TLINT[esi].len
      test    ebx,ebx
      lea     edi,TLINT[esi].num[0]
      jz      @End
      xor     edx,edx
  @Loop:
      mov     eax,[edi]
      shld    eax,edx,cl
      mov     edx,[edi]
      mov     [edi],eax
      lea     edi,[edi+4]
      dec     ebx
      jnz     @Loop
      xor     eax,eax
      shld    eax,edx,cl
      jz      @End
      mov     [edi],eax                   {位上がり}
      inc     DWORD PTR [TLINT[esi].len]
  @End:
      mov     eax,esi
      pop     ebx
      pop     edi
      pop     esi
end;

function lshr1(a: PLINT; c: Integer): PLINT; register;
asm
      push    esi
      push    edi
      push    ebx
      mov     ecx,c
      test    ecx,31
      mov     esi,a
      jz      @End
      mov     ebx,TLINT[esi].len
      test    ebx,ebx
      lea     edi,[esi+ebx*4+4]  {&a.num[a.len-1] 最上位}
      jz      @End
      mov     eax,[edi]
      xor     edx,edx
      shrd    eax,edx,cl
      mov     edx,[edi]
      mov     [edi],eax
      lea     edi,[edi-4]
      jnz     @Loop              {最上位が0なら桁下げ}
      dec     DWORD PTR [TLINT[esi].len]
  @Loop:
      dec     ebx
      jz      @End
      mov     eax,[edi]
      shrd    eax,edx,cl
      mov     edx,[edi]
      mov     [edi],eax
      lea     edi,[edi-4]
      jmp     @Loop
  @End:
      mov     eax,esi
      pop     ebx
      pop     edi
      pop     esi
end;

//
//  LINT *lmulp(LINT *a,const LINT *b)
//    絶対値乗算 a=a*b
//      (a=bを指定可)
//    最大でa.len+b.len桁までいくのでオーバフローに気をつけてください
//
//
//***************************************************************
//    引数によってはメモリ破壊を引き起こすので特に注意してください
//***************************************************************
function lmulp(a: PLINT; const b: PLINT): PLINT; register;
var
  tmp,tmpESP: Pointer;
asm
      push    esi
      push    edi
      push    ebx
      mov     tmpESP,esp
      mov     esi,a
      mov     ecx,TLINT[esi].len
      add     ecx,TLINT[edx].len
      add     ecx,4                     {a.len+b.lenを計算}
      lea     eax,[ecx*4]
      cmp     eax,LINTSize
      jg      @Alloc                    {デフォルトより小さければデフォルト値}
      mov     eax,LINTSize
      mov     ecx,LINTSize/4
    @Alloc:
      sub     esp,eax
      mov     tmp,esp
      mov     edi,esp
      xor     eax,eax
      rep     stosd                      {tmp=0:書き込み用領域確保}
      mov     edi,b
      mov     edx,TLINT[esi].len      {a.len}
      test    edx,edx
      jz      @Copy
      mov     ebx,TLINT[edi].len      {b.len}
      test    ebx,ebx
      jz      @Copy                {a=0 or b=0 then end}
      lea     edi,[edi+ebx*4+4]  {&b.num[b.len-1] 最上位}
      mov     eax,tmp
  @Loop:
      mov     edx,esi
      mov     ecx,[edi]
      call    smuladd             {[eax]=[edx]*ecx}
      dec     ebx
      jz      @Copy
      mov     edx,1
      call    lshl32              {1桁上げる}
      lea     edi,[edi-4]
      jmp     @Loop
  @Copy:
      mov     edi,esi
      mov     esi,tmp
      mov     ecx,TLINT[esi].len
      add     ecx,2
      mov     eax,edi
      rep     movsd                    {a^:=tmp 書き込み用領域から戻す}
  @End:
      mov     esp,tmpESP
      pop     ebx
      pop     edi
      pop     esi
end;

//
//  LINT *lmulpb(LINT *w,const LINT *a,const LINT *b)
//    絶対値乗算 w=a*b
//      wにa,bを指定してはなりません
//      最大でa.len+b.len桁までいくので
//      wで指定したバッファを越えないように注意してください
//
//    注)wをクリアする際にLINTMaxLenを使用します
//       wはLINTよりも大きく取る必要があります
//
//***************************************************************
//    引数によってはメモリ破壊を引き起こすので特に注意してください
//***************************************************************
function lmulpb(w: PLINT; const a: PLINT; const b: PLINT): PLINT; register;
asm
      push    esi
      push    edi
      push    ebx
      mov     esi,b
      mov     edi,w
      mov     ebx,w
      xor     eax,eax
      mov     ecx,LINTSize/4
      rep     stosd                      {w=0}
      mov     eax,ebx                 {w}
      mov     edi,esi                 {b}
      mov     esi,a
      mov     edx,TLINT[esi].len      {a.len}
      test    edx,edx
      jz      @End
      mov     ebx,TLINT[edi].len      {b.len}
      test    ebx,ebx
      jz      @End                {a=0 or b=0 then end}
      lea     edi,[edi+ebx*4+4]  {&b.num[b.len-1] 最上位}
  @Loop:
      mov     edx,esi
      mov     ecx,[edi]
      call    smuladd             {[eax]=[edx]*ecx}
      dec     ebx
      jz      @End
      mov     edx,1
      call    lshl32              {1桁上げる}
      lea     edi,[edi-4]
      jmp     @Loop
  @End:
      pop     ebx
      pop     edi
      pop     esi
end;

//
//  LINT *lmul(LINT *a,const LINT *b)
//    乗算 a=a*b
//      (a=bを指定可)
//    オーバーフローはみないので呼び出し側で責任を持つように
//
//  LINT *lmul(LINT *w,const LINT *a,const LINT *b)
//    乗算 w=a*b
//      wにa,bを指定してはなりません(a=bは可)
//      wで指定したバッファを越えないように注意すること
//
//    どちらも最大でa.len+b.len桁までいくのでオーバフローに気をつけてください
//**************************************************************************
// 引数によってはスタックまたはメモリ破壊を引き起こすので特に注意してください
//**************************************************************************
function lmul(a: PLINT; const b: PLINT): PLINT; overload;
begin
    if a.Sign = b.Sign then
    begin
      lmulp(a,b);
      a.Sign := 0;
    end else
    begin
      lmulp(a,b);
      if a.Len = 0 then
        a.Sign := 0
      else
        a.Sign := -1;
    end;
    Result := a;
end;

function lmul(w: PLINT; const a: PLINT; const b: PLINT): PLINT; overload;
begin
    lmulpb(w, a, b);
    if (w.Len = 0) or (a.Sign = b.Sign) then
      w.Sign := 0
    else
      w.Sign := -1;
    Result := w;
end;


(****************************************************
  3div
    除算、表示文字列変換ルーチン
 ****************************************************)

//
//  LINT *sdiv(LINT *a,unsigned int n,unsigned int *r)
//    対単整数絶対値除算 aをnで割り、商a余りr
//
function sdiv(a: PLINT; n: Cardinal; out r: Cardinal): PLINT;
asm
      push    esi
      push    edi
      push    ebx
      push    r             {余りへのポインタを保存}
      mov     edi,a
      mov     ebx,n
      mov     esi,edi
      mov     ecx,TLINT[edi].len
      test    ecx,ecx
      jnz     @Main
      xor     edx,edx            {a.len=0のとき余りr=0}
      jmp     @End
  @Main:
      lea     edi,[edi+ecx*4+4]   {&a.num[a.len-1] 最上位}
      xor     edx,edx
      mov     eax,[edi]
      div     ebx
      test    eax,eax
      mov     [edi],eax
      jnz     @Loop
      dec     TLINT[esi].len    {商の最上位が0の時のみ桁が1つだけ下がる}
  @Loop:
      dec     ecx
      jz      @End
      lea     edi,[edi-4]
      mov     eax,[edi]
      div     ebx
      mov     [edi],eax
      jmp     @Loop
  @End:
      pop     edi            {r}
      mov     [edi],edx      {*r=余り}
      mov     eax,esi
      pop     ebx
      pop     edi
      pop     esi
end;

//
//  function StrToLINT(var a:TLINT; str: String): PLINT;
//    文字列をLINT型に変換します
//      変換後格納するLINT型変数をaに指定してください
//      変換後変数をさすポインタを返します
//
//    注)この関数は定義されたLINTMaxLenまででしか使えない
//       オーバーフローした際はELINTOverflowを投げます
//
function StrToLINT(var a:TLINT; str: String): PLINT;
var
  max,len,i: Integer;
begin
    Result := @a;
    lset(@a,0);

    if Length(str) = 0 then
      Exit;

    if str[1] = '-' then
    begin
      a.Sign := -1;
      Delete(str,1,1);
    end
    else if str[1] = '+' then
    begin
      Delete(str,1,1);
    end;                            // 符号を除いた部分をコピーする。

    str := StringReplace(str,' ','',[rfReplaceAll]);
    str := StringReplace(str,#13#10,'',[rfReplaceAll]); //空白を除去
    max := length(str);         //字数を計算

    len := max;
    for i:= 1 to max do
    begin
      if not (str[i] in ['0'..'9']) then
      begin
        len := i-1;             //  数字でないところで打ちきる。
        Break;
      end;
    end;

    str := copy(str,1,len);
  	//始めからBASE2数字ずつ数値に直す
    for i := 1 to (len div LINTBaseLog) do
    begin
      smul(@a,LINTBase);
      if a.Len > LINTMaxLen then
        raise ELINTOverflow.Create('conversion Error: Overflow');
      alinc(@a,StrToInt(copy(str,1,LINTBaseLog)));
      Delete(str,1,LINTBaseLog);
    end;
    //端数
    if Length(str) <> 0 then
      smul(@a,Pow10[Length(str)],StrToInt(str));
    if a.Len > LINTMaxLen then
      raise ELINTOverflow.Create('conversion Error: Overflow');
end;

//
//  function LINTtoStr(a:TLINT): String;
//    LINT型変数を文字列にします
//      変換後の文字列を返します
//
//  function LINTtoStr(a:TLINT; divnum: Integer): String;
//    LINT型変数をdivnum文字ごとに区切って文字列にします
//
function LINTtoStr(a:TLINT): String;
var
  r: Cardinal;
begin
    if a.Len = 0 then
    begin
      Result := '0';
      Exit;
    end;
    Result := '';
    lfix(@a);
    while sdiv(@a,LINTBase,r).Len <> 0 do
    begin
      Result := Result + ReverseString(Format('%.*u',[LINTBaseLog,r]));
    end;
    if a.Sign = 0 then
      Result := Result + ReverseString(Format('%u',[r]))
    else
      Result := Result + ReverseString(Format('-%u',[r]));
    Result := ReverseString(Result);
end;

function LINTtoStr(a:TLINT; divnum: Integer): String;
var
  str: String;
begin
    Result := '';
    if divnum < 1 then Exit;

    str := ReverseString(LINTtoStr(a));
    while Length(str) > divnum do
    begin
      Result := Result + ' ' + copy(str,1,divnum);
      Delete(str,1,divnum);
      if str[1] = '-' then
      begin
        Result := Result + str;
        str := '';
      end;
    end;
    Result := Result + ' ' + str;
    Result := ReverseString(Trim(Result));
end;

//
//  function HexStrToLINT(var a:TLINT; str: String): PLINT;
//    16進数字文字列をLINT型に変換します
//      変換後格納するLINT型変数をaに指定してください
//      変換後変数をさすポインタを返します
//
//    注)この関数は定義されたLINTMaxLenまででしか使えない
//       オーバーフローした際はELINTOverflowを投げます
//
function HexStrToLINT(var a:TLINT; str: String): PLINT;
var
  max,len,i: Integer;
begin
    Result := @a;
    lset(@a,0);

    if Length(str) = 0 then
      Exit;

    if str[1] = '-' then
    begin
      a.Sign := -1;
      Delete(str,1,1);
    end
    else if str[1] = '+' then
    begin
      Delete(str,1,1);
    end;                            // 符号を除いた部分をコピーする。

    str := StringReplace(str,' ','',[rfReplaceAll]);
    str := StringReplace(str,#13#10,'',[rfReplaceAll]); //空白を除去
    str := LowerCase(str);
    max := length(str);         //字数を計算

    len := max;
    for i:= 1 to max do
    begin
      if not (str[i] in ['0'..'9','a'..'f']) then
      begin
        len := i-1;             //  16進数字でないところで打ちきる。
        Break;
      end;
    end;

    str := copy(str,1,len);
  	//始めから8数字ずつ数値に直す
    for i := 1 to (len div 8) do
    begin
      lshl32(@a,1);
      if a.Len > LINTMaxLen then
        raise ELINTOverflow.Create('conversion Error: Overflow');
      alinc(@a,StrToInt('$'+copy(str,1,8)));
      Delete(str,1,8);
    end;
    //端数
    if Length(str) <> 0 then
      linc(lshl1(@a,Length(str)*4),StrToInt('$'+str));
    if a.Len > LINTMaxLen then
      raise ELINTOverflow.Create('conversion Error: Overflow');
end;

//
//  function LINTtoHex(a:TLINT): String;
//    LINT型変数を文字列にします
//      変換後の文字列を返します
//
//  function LINTtoHex(a:TLINT; divnum: Integer): String;
//    LINT型変数をdivnum文字ごとに区切って文字列にします
//
function LINTtoHex(a:TLINT): String;
begin
    if a.Len = 0 then
    begin
      Result := '0';
      Exit;
    end;
    Result := '';
    lfix(@a);
    while a.Len > 1 do
    begin
      Result := Result + ReverseString(Format('%.8x',[a.Num[0]]));
      lshr32(@a,1);
    end;
    if a.Sign = 0 then
      Result := Result + ReverseString(Format('%x',[a.Num[0]]))
    else
      Result := Result + ReverseString(Format('-%x',[a.Num[0]]));
    Result := ReverseString(Result);
end;

function LINTtoHex(a:TLINT; divnum: Integer): String;
var
  str: String;
begin
    Result := '';
    if divnum < 1 then Exit;

    str := ReverseString(LINTtoHex(a));
    while Length(str) > divnum do
    begin
      Result := Result + ' ' + copy(str,1,divnum);
      Delete(str,1,divnum);
      if str[1] = '-' then
      begin
        Result := Result + str;
        str := '';
      end;
    end;
    Result := Result + ' ' + str;
    Result := ReverseString(Trim(Result));
end;

//
//  LINT *ldivp(LINT *a,const LINT *b,LINT *c)
//    絶対値除算 a/bを計算し、商c,余りa(返り値のポインタは余りのa)
//      引数の順序に注意してください
//
//    *この関数はcdecl呼び出し規約です
//
function ldivp(a: PLINT; const b: PLINT; c: PLINT): PLINT; cdecl;
var
  tmpB,tmpD: Pointer;
  tmpBlen,tmpDlen: Integer;
  tmpESP: Pointer;
  shift_d: Integer;
  Q_eax,D_nm: Integer;
begin
    Result := a;
    lset(c,0);          {cをクリア}
    if b.Len = 0 then
    begin               {bが0の時は0div例外を投げる}
      asm
        xor   edx,edx
        div   edx
      end;
      Exit;
    end;
    if lcmp(a,b) < 0 then  {a<bのときは商0余りaでリターン}
    begin
      Exit;
    end;
    if b.Len = 1 then      {b.len=1はsdivに委任}
    begin
      asm
        push  esi
        push  edi
        mov   eax,a
        mov   ecx,b
        mov   edx,DWORD PTR[TLINT[ecx].num[0]]
        sub   esp,4
        mov   ecx,esp
        call  sdiv               {sdiv(a,b.num[0],&[esp])}
        pop   edx                {余りを退避}
        mov   esi,eax
        mov   edi,c
        mov   ecx,TLINT[eax].len
        add   ecx,2              {cの余剰領域はクリアされているので}
        rep   movsd              {コピーするだけでいい}
        test  edx,edx
        jz    @ris0
        inc   ecx
        mov   TLINT[eax].len,ecx
        mov   DWORD PTR [TLINT[eax].num[0]],edx
        jmp   @sdivEnd
       @ris0:
        mov   TLINT[eax].len,ecx
       @sdivEnd:
        mov   edx,LINTMaxLen+2
        call  lfixb
        pop   edi
        pop   esi
      end;
      Exit;
    end;
    c.Len := a.Len-b.Len+1;
    asm
        push    esi
        push    edi
        push    ebx
        mov     tmpESP,esp
        mov     esi,b
        mov     edi,a
        mov     eax,TLINT[edi].len
        mov     tmpDlen,eax
        inc     tmpDlen
        inc     tmpDlen
      @tmpDAlloc:
        lea     eax,[eax*4+16]      {aをコピーできるサイズを確保}
        cmp     eax,LINTSize
        jg      @DAllocDo
        mov     eax,LINTSize
        mov     tmpDlen,LINTMaxLen+2
       @DAllocDo:
        sub     esp,eax             {MAXLEN+2+2(len+sign)}
        mov     tmpD,esp
        mov     tmpB,esi
      @ABfixTest:                   {a,bを正規化する}
        mov     ecx,TLINT[esi].len
        mov     ebx,[esi+ecx*4+4]   {b.num[b.len-1] 最上位の内容}
        bsr     edx,ebx
        neg     edx
        add     edx,31
        mov     shift_d,edx         {正規化のシフト量}
        jz      @ABnonshift         {最上位ビットがたってればシフトなし}
      @ABshift:
       @tmpBAlloc:
        lea     eax,[ecx*4+16]      {bをコピーできるサイズを確保}
        mov     tmpBlen,eax
        inc     tmpBlen
        inc     tmpBlen
        cmp     eax,LINTSize
        jg      @BAllocDo
        mov     eax,LINTSize
        mov     tmpBlen,LINTMaxLen+2
       @BAllocDo:
        sub     esp,eax             {MAXLEN+2+2(len+sign)}
        mov     tmpB,esp
        mov     edi,esp
        add     ecx,2
       @tmpBCopy:
        rep     movsd
       @ABshiftDo:
        mov     esi,tmpB
        mov     edi,a
        mov     eax,esi
        mov     edx,tmpBlen
        call    lfixb               {lfixb(tmpB)}
        mov     edx,shift_d
        call    lshl1               {lshl1(tmpB,edx)}
        mov     eax,edi
        mov     edx,shift_d
        call    lshl1               {lshl1(a,edx)}
      @ABnonshift:
        mov     eax,TLINT[edi].len
        mov     ecx,TLINT[esi].len
      @MainLoop:                    {以下bは b または tmpB}
        mov     edx,[edi+eax*4+4]   {a.num[a.len-1] 最上位の内容A[n]}
        mov     ebx,[esi+ecx*4+4]   {b.num[b.len-1] 最上位の内容B[m]}
        cmp     ebx,edx
        ja      @PreDiv             {B[m]>A[n]ならjmp}
      @NonPreDiv:
        mov     edi,tmpD
        mov     TLINT[edi].len,eax
        mov     ebx,ecx             {b.lenを退避}
        sub     eax,ecx             {a.len-b.len}
        mov     D_nm,eax
        mov     ecx,eax             {a: a5 a4 a3 a2 a1}
        lea     edi,[edi+8]         {d: b3 b2 b1 0  0  : = b*B^(a.len-b.len)}
        lea     esi,[esi+8]         {b:       b3 b2 b1   = b*B^2            }
        xor     eax,eax
        rep     stosd
        mov     ecx,ebx
        rep     movsd               {tmpD = b*B^(a.len-b.len)  b*B^(n-m)}
        mov     esi,tmpD
        mov     edi,a
        mov     eax,esi
        mov     edx,tmpDlen
        call    lfixb
        mov     edx,esi
        mov     eax,edi
        call    lcmp
        mov     edx,D_nm            {a.len-b.len}
        cmp     eax,0
        jl      @Qfix               {a<tmpBでjmp:eax=FFFFFFFF}
      @Qis1:
        mov     eax,1               {a>=tmpBのとき}
        mov     Q_eax,eax
        jmp     @Sub
      @PreDiv:
        mov     eax,[edi+eax*4]     {edx:eax=a.num[len-1]:a.num[len-2]}
        div     ebx
      @Qfix:
        mov     esi,tmpB
        mov     ecx,TLINT[esi].len  {b.len}
        mov     edi,a
        mov     edx,TLINT[edi].len  {a.len}
        sub     edx,ecx
        jna     @End                {a.len<=b.lenで終了(最上位A[n]<B[m]よりa<bが決定)}
        dec     edx
        add     ecx,2
        mov     edi,tmpD            {tmpD=b*eax(商)*B^(n-m-1)}
        rep     movsd
        mov     Q_eax,eax
        mov     D_nm,edx
        mov     eax,tmpD
        mov     edx,tmpDlen
        call    lfixb      {lfixb(tmpD)}
        mov     edx,Q_eax
        xor     ecx,ecx
        call    smul      {lsmul(tmpD,eax(商),0)}
        mov     edx,D_nm
        call    lshl32     {lshl32(tmpD,(n-m-1))}
      @QLoop:
        mov     edx,eax
        mov     esi,eax   {tmpD}
        mov     eax,a
        mov     edi,eax   {a}
        call    lcmp                {a>=tmpD(商が適正)ならjmp}
        cmp     eax,0
        jge     @Sub
        mov     eax,esi             {Q_eax--;tmpDを修正}
        mov     edx,D_nm
        call    lshr32     {lshr32(tmpD,(n-m-1))}
        mov     edx,tmpB
        call    alsub     {alsub(tmpD,tmpB)}
        mov     edx,D_nm
        call    lshl32     {lshl32(tmpD,(n-m-1))}
        dec     DWORD PTR [Q_eax]
        jmp     @QLoop
      @Sub:
        mov     edx,esi   {tmpD}
        mov     eax,edi   {a}
        call    alsub     {alsub(a,tmpD)}
        mov     edx,D_nm
        mov     eax,Q_eax
        mov     esi,c
        mov     [esi+edx*4+8],eax   {c.num[D_nm]=Q_eax}
        mov     esi,tmpB
        mov     eax,TLINT[edi].len
        mov     ecx,TLINT[esi].len
        cmp     eax,ecx
        jae     @MainLoop           {a.len>=b.lenでループ継続}
      @End:
        mov     esi,c
        mov     ecx,TLINT[esi].len
        mov     eax,[esi+ecx*4+4]   {c.num[c.len-1] 商の最上位}
        test    eax,eax
        jnz     @Afix
        dec     ecx                 {最上位が0なら桁を減らす}
        mov     TLINT[esi].len,ecx
      @Afix:
        mov     edx,shift_d
        test    edx,edx
        jz      @Quit
        mov     eax,edi
        call    lshr1
      @Quit:
        mov     esp,tmpESP
        pop     ebx
        pop     edi
        pop     esi
    end;
end;

//
//  LINT *ldiv1(LINT *a,const LINT *b,LINT *c)
//    除算 a/bを計算し、商c,余りa(返り値のポインタは余りのa)
//      引数の順序に注意してください
//
//    余りが0方向に一番近くなるように商と余りが選ばれます
//       10/3 = 3...1
//      -10/3 =-3...-1
//       10/-3=-3...1
//      -10/-3= 3...-1
//
function ldiv1(a: PLINT; const b: PLINT; c: PLINT): PLINT;
begin
    Result := a;

    ldivp(a,b,c);
    if a.Sign = 0 then
    begin
      if b.Sign = 0 then
      begin
        c.Sign := 0;
        a.Sign := 0;
      end else
      begin
        c.Sign := -1;
        a.Sign := 0;
      end;
    end else
    begin
      if b.Sign = 0 then
      begin
        c.Sign := -1;
        a.Sign := -1;
      end else
      begin
        c.Sign := 0;
        a.Sign := -1;
      end;
    end;
end;

//
//  LINT *lgcd(LINT *gcd,LINT a,LINT b)
//    gcd(a,b)最大公約数
//      但しa,bは正でなくてはなりません。
//      引数が不正のときはELINTIllegalFunctionCall例外が投げられます
//
function lgcd(gcd: PLINT; a: TLINT; b: TLINT): PLINT;
var
  tmp: TLINT;
begin
    lset(gcd,0);
    Result := gcd;
    if (a.Sign <> 0) or (b.Sign <> 0) or
        (a.Len = 0) or (b.Len = 0) then
    begin
      raise ELINTIllegalFunctionCall.Create('lgcd: Illegal parameter');
      Exit;
    end;
    repeat
      if ldiv1(@a,@b,@tmp).Len = 0 then
      begin
        gcd^ := b;
        Exit;
      end;
    until ldiv1(@b,@a,@tmp).Len = 0;
    gcd^ := a;
end;

//
//  LINT *llcm(LINT *lcm,const LINT a,const LINT b)
//    lcm(a,b)最小公倍数
//      内部ではa*b/gcd(a,b)を計算します
//
//      但しa,bは正でなくてはなりません。
//      引数が不正のときはELINTIllegalFunctionCall例外が投げられます
//
function llcm(lcm: PLINT; const a: TLINT; const b: TLINT): PLINT;
var
  tmp1,tmp2: TLINT;
begin
    Result := lcm;
    lset(lcm,0);

    if (a.Sign <> 0) or (b.Sign <> 0) or
        (a.Len = 0) or (b.Len = 0) then
    begin
      raise ELINTIllegalFunctionCall.Create('llcm: Illegal parameter');
      Exit;
    end;
    ldiv1(lmulpb(@tmp1,@a,@b),lgcd(@tmp2,a,b),lcm);
end;

//
//  LINT *linv(LINT *x,LINT s,LINT n)
//    法nでのsの逆数
//      x*s≡1 (mod n) なるxを求める
//      但しgcd(s,n)=1
//
//    求められない時はx=0が返る
//
function linv(x: PLINT; s: TLINT; n: TLINT): PLINT;
var
  ta,ua,q: TLINT;
  sn: TLINT;
begin
    lset(x,1);
    lset(@ta,0);
    sn := n;
    Result := x;
    while n.len > 0 do
    begin
      ldiv1(@s,@n,@q);
      ua := x^;
      lsub(@ua,lmul(x,@q,@ta));
      x^ := ta;
      ta := ua;
      if s.len = 0 then
      begin
        if (n.len <> 1) or (n.num[0] <> 1) then
        begin
          lset(x,0);
          Exit;
        end;
        if x.Sign <> 0 then
          ladd(x,@sn);
        Exit;
      end;

      ldiv1(@n,@s,@q);
      ua := x^;
      lsub(@ua,lmul(x,@q,@ta));
      x^ := ta;
      ta := ua;
    end;

    if (s.len <> 1) or (s.num[0] <> 1) then
    begin
      lset(x,0);
      Exit;
    end;

    if x.sign <> 0 then
      ladd(x,@sn);
end;

//
//  LINT *lmulmod(LINT *a,const LINT *b,const LINT *n)
//    法nでの絶対値乗算 a = a*b (mod n)
//      内部バッファは倍とっているので溢れることはない
//
//    注)この関数は定義されたLINTMaxLenまででしか使えない
//       それ以上が与えられることは想定されていません
//
function lmulmod(a: PLINT; const b: PLINT; const n: PLINT): PLINT;
var
  tmp: TLINT2;
begin
    FillChar(tmp,SizeOf(TLINT2),0);

    lmulpb(@tmp,a,b);
    ldivp(@tmp,n,a);
    a^ := PLINT(@tmp)^;
    Result := a;
end;

//
//  LINT *lpwr(LINT *x,unsigned int y)
//    べき乗 x = x^y
//      オーバーフローするとELINTOverflowが投げられます
//      オーバーフロー時の値は保証されません
//
//    注)この関数は定義されたLINTMaxLenまででしか使えない
//
function lpwr(x: PLINT; y: Cardinal): PLINT;
var
  tmp1: TLINT;
  tmp2: TLINT;

  procedure testOverflow(test: PLINT);
  begin
    if test.Len > LINTMaxLen then
      raise ELINTOverflow.Create('lpwr: Overflow');
  end;

begin
    tmp1 := x^;
    lset(x,1);
    Result := x;
    if y = 0 then
    begin
      if tmp1.Len = 0 then
        raise ELINTIllegalFunctionCall.Create('lpwr: Illegal parameter');
      Exit;
    end;
    if x.Len > LINTMaxLen then
      raise ELINTOverflow.Create('lpwr: Overflow');

    asm
      push  esi
      push  edi
      push  ebx
      mov   ebx,y
      mov   esi,x
      bsr   edi,ebx      {最上位ビット検索}
      inc   edi
    @Loop:
     @APart:
      shr   ebx,1
      jnc   @ANextmul
      lea   ecx,tmp1     {ビットが立っていれば掛ける}
      mov   edx,esi
      lea   eax,tmp2
      call  lmul
      call  testOverflow
      mov   edx,edi
      mov   eax,esi
      lea   edi,tmp2
      xchg  edi,esi
      mov   ecx,TLINT[esi].len
      add   ecx,2
      rep   movsd        {バッファからxに戻す}
      mov   edi,edx
      mov   esi,eax
     @ANextmul:
      dec   edi
      jz    @End
      lea   edx,tmp1     {二乗する}
      mov   ecx,edx
      lea   eax,tmp2
      call  lmul
      call  testOverflow
     @BPart:
      shr   ebx,1
      jnc   @BNextmul
      lea   ecx,tmp2
      mov   edx,esi
      lea   eax,tmp1
      call  lmul
      call  testOverflow
      mov   edx,edi
      mov   eax,esi
      lea   edi,tmp1
      xchg  edi,esi
      mov   ecx,TLINT[esi].len
      add   ecx,2
      rep   movsd
      mov   edi,edx
      mov   esi,eax
     @BNextmul:
      dec   edi
      jz    @End
      lea   edx,tmp2
      mov   ecx,edx
      lea   eax,tmp1
      call  lmul
      call  testOverflow
      jmp   @Loop
    @End:
      pop   ebx
      pop   edi
      pop   esi
    end;
end;

//
//  LINT *lpwrmod(LINT *x,const LINT *y,const LINT *n)
//    法nのもとでの累乗剰余 x = x^y(mod n)
//      但し、nは正,y>0またはxy<>0
//      引数以上はELINTIllegalFunctionCallが投げられます
//
//    注)この関数は定義されたLINTMaxLenまででしか使えない
//       x,nが溢れているとオーバーフローELINTOverflowが投げられます
//
function lpwrmod(x :PLINT; const y: PLINT; const n: PLINT): PLINT;
var
  tmp: TLINT;
  i: Integer;
begin
    Result := x;
    if (y.Sign <> 0) or (n.Len = 0) or (n.Sign <> 0) then
      raise ELINTIllegalFunctionCall.Create('lpwrmod: Illegal parameter');
    tmp := x^;
    if y.Len = 0 then
    begin
      if tmp.Len = 0 then
        raise ELINTIllegalFunctionCall.Create('lpwrmod: Illegal parameter');
      lset(x,1);
      Exit;
    end;
    if tmp.Len > LINTMaxLen then
      raise ELINTOverflow.Create('lpwr: Overflow');
    if n.Len > LINTMaxLen then
      raise ELINTOverflow.Create('lpwr: Overflow');
    if ldiv1(@tmp,n,x).Sign <> 0 then
      ladd(@tmp,n);
    lset(x,1);

    asm
      push  esi
      push  edi
      push  ebx
      mov   esi,y
      mov   ebx,TLINT[esi].len
      mov   i,ebx
      lea   esi,TLINT[esi].num[0]
    @MainLoop:
      dec   i
      jz    @LastLoop
      mov   ebx,[esi]
      mov   edi,32
     @MainBitLoop:
      shr   ebx,1
      jnc   @MainNext
      mov   ecx,n
      lea   edx,tmp
      mov   eax,x
      call  lmulmod
     @MainNext:
      lea   eax,tmp
      mov   ecx,n
      mov   edx,eax
      call  lmulmod
      dec   edi
      jnz   @MainBitLoop
      lea   esi,[esi+4]
      jmp   @MainLoop
    @LastLoop:
      mov   ebx,[esi]
      bsr   edi,ebx
      inc   edi
      mov   esi,n
     @LastBitLoop:
      shr   ebx,1
      jnc   @LastNext
      mov   ecx,esi
      lea   edx,tmp
      mov   eax,x
      call  lmulmod
     @LastNext:
      lea   eax,tmp
      mov   ecx,esi
      mov   edx,eax
      call  lmulmod
      dec   edi
      jnz   @LastBitLoop
    @End:
      pop   ebx
      pop   edi
      pop   esi
    end;
end;

//
//    function PStrToLINT(var a:TLINT; str: PChar): PLINT;
//    文字列をLINT型に変換します
//      変換後格納するLINT型変数をaに指定してください
//      変換後変数をさすポインタを返します
//
//    注)この関数は定義されたLINTMaxLenまででしか使えない
//       オーバーフローした際はELINTOverflowを投げます
//
function PStrToLINT(var a:TLINT; const str: PChar): PLINT;
var
  max,len,i: Integer;
  tmp: String;
begin
    Result := @a;
    lset(@a,0);

    tmp := str;
    if Length(tmp) = 0 then
      Exit;

    if tmp[1] = '-' then
    begin
      a.Sign := -1;
      Delete(tmp,1,1);
    end
    else if tmp[1] = '+' then
    begin
      Delete(tmp,1,1);
    end;                            // 符号を除いた部分をコピーする。

    tmp := StringReplace(tmp,' ','',[rfReplaceAll]);
    tmp := StringReplace(tmp,#13#10,'',[rfReplaceAll]); //空白を除去
    max := length(tmp);         //字数を計算

    len := max;
    for i:= 1 to max do
    begin
      if not (tmp[i] in ['0'..'9']) then
      begin
        len := i-1;             //  数字でないところで打ちきる。
        Break;
      end;
    end;

    tmp := copy(tmp,1,len);
  	//始めからBASE2数字ずつ数値に直す
    for i := 1 to (len div LINTBaseLog) do
    begin
      smul(@a,LINTBase);
      if a.Len > LINTMaxLen then
        raise ELINTOverflow.Create('conversion Error: Overflow');
      alinc(@a,StrToInt(copy(tmp,1,LINTBaseLog)));
      Delete(tmp,1,LINTBaseLog);
    end;
    //端数
    if Length(tmp) <> 0 then
      smul(@a,Pow10[Length(tmp)],StrToInt(tmp));
    if a.Len > LINTMaxLen then
      raise ELINTOverflow.Create('conversion Error: Overflow');
end;

//
//    function LINTtoPStr(dest: PChar; a:TLINT): PChar; overload;
//    LINT型変数をPChar文字列にします
//
//    function LINTtoPStr(dest: PChar; a:TLINT; divnum: Integer): PChar; overload;
//    LINT型変数をdivnum文字ごとに区切ってPChar文字列にします
//
//      変換後の格納領域をdestに指定してください。
//        サイズはチェックされません
//        log2*LINTMAXLEN*32 文字より大きくとってください
//      格納領域を指すポインタを返します
//
function LINTtoPStr(dest: PChar; a:TLINT): PChar; overload;
var
  r: Cardinal;
  tmp: String;
begin
    Result := dest;
    if a.Len = 0 then
    begin
      StrCopy(dest,'0');
      Exit;
    end;
    tmp := '';
    lfix(@a);
    while sdiv(@a,LINTBase,r).Len <> 0 do
    begin
      tmp := tmp + ReverseString(Format('%.*u',[LINTBaseLog,r]));
    end;
    if a.Sign = 0 then
      tmp := tmp + ReverseString(Format('%u',[r]))
    else
      tmp := tmp + ReverseString(Format('-%u',[r]));
    StrCopy(dest,PChar(ReverseString(tmp)));
end;

function LINTtoPStr(dest: PChar; a:TLINT; divnum: Integer): PChar; overload;
var
  str: String;
  tmp: String;
begin
    Result := dest;
    if divnum < 1 then
    begin
      StrCopy(dest,'');
      Exit;
    end;

    str := ReverseString(LINTtoStr(a));
    while Length(str) > divnum do
    begin
      tmp := tmp + ' ' + copy(str,1,divnum);
      Delete(str,1,divnum);
      if str[1] = '-' then
      begin
        tmp := tmp + str;
        str := '';
      end;
    end;
    tmp := tmp + ' ' + str;
    StrCopy(dest,PChar(ReverseString(Trim(tmp))));
end;

//
//  function HexPStrToLINT(var a:TLINT; str: PChar): PLINT;
//    16進数字PChar文字列をLINT型に変換します
//      変換後格納するLINT型変数をaに指定してください
//      変換後変数をさすポインタを返します
//
//    注)この関数は定義されたLINTMaxLenまででしか使えない
//       オーバーフローした際はELINTOverflowを投げます
//
function HexPStrToLINT(var a:TLINT; const str: PChar): PLINT;
var
  max,len,i: Integer;
  tmp: String;
begin
    Result := @a;
    lset(@a,0);

    tmp := str;
    if Length(tmp) = 0 then
      Exit;

    if tmp[1] = '-' then
    begin
      a.Sign := -1;
      Delete(tmp,1,1);
    end
    else if tmp[1] = '+' then
    begin
      Delete(tmp,1,1);
    end;                            // 符号を除いた部分をコピーする。

    tmp := StringReplace(tmp,' ','',[rfReplaceAll]);
    tmp := StringReplace(tmp,#13#10,'',[rfReplaceAll]); //空白を除去
    tmp := LowerCase(tmp);
    max := length(tmp);         //字数を計算

    len := max;
    for i:= 1 to max do
    begin
      if not (tmp[i] in ['0'..'9','a'..'f']) then
      begin
        len := i-1;             //  16進数字でないところで打ちきる。
        Break;
      end;
    end;

    tmp := copy(tmp,1,len);
  	//始めから8数字ずつ数値に直す
    for i := 1 to (len div 8) do
    begin
      lshl32(@a,1);
      if a.Len > LINTMaxLen then
        raise ELINTOverflow.Create('conversion Error: Overflow');
      alinc(@a,StrToInt('$'+copy(tmp,1,8)));
      Delete(tmp,1,8);
    end;
    //端数
    if Length(tmp) <> 0 then
      linc(lshl1(@a,Length(tmp)*4),StrToInt('$'+tmp));
    if a.Len > LINTMaxLen then
      raise ELINTOverflow.Create('conversion Error: Overflow');
end;

//
//    function LINTtoPHex(dest: PChar; a:TLINT): PChar; overload;
//    LINT型変数をPChar文字列にします
//
//    function LINTtoPHex(dest: PChar; a:TLINT; divnum: Integer): PChar; overload;
//    LINT型変数をdivnum文字ごとに区切ってPChar文字列にします
//
//      変換後の格納領域をdestに指定してください。
//        サイズはチェックされません
//        LINTMAXLEN*8 文字より大きくとってください
//      格納領域を指すポインタを返します
//
function LINTtoPHex(dest: PChar; a:TLINT): PChar; overload;
var
  tmp: String;
begin
    Result := dest;
    if a.Len = 0 then
    begin
      StrCopy(dest,'0');
      Exit;
    end;
    tmp := '';
    lfix(@a);
    while a.Len > 1 do
    begin
      tmp := tmp + ReverseString(Format('%.8x',[a.Num[0]]));
      lshr32(@a,1);
    end;
    if a.Sign = 0 then
      tmp := tmp + ReverseString(Format('%x',[a.Num[0]]))
    else
      tmp := tmp + ReverseString(Format('-%x',[a.Num[0]]));
    StrCopy(dest,PChar(ReverseString(tmp)));
end;

function LINTtoPHex(dest: PChar; a:TLINT; divnum: Integer): PChar; overload;
var
  str: String;
  tmp: String;
begin
    Result := dest;
    if divnum < 1 then
    begin
      StrCopy(dest,'');
      Exit;
    end;

    str := ReverseString(LINTtoHex(a));
    while Length(str) > divnum do
    begin
      tmp := tmp + ' ' + copy(str,1,divnum);
      Delete(str,1,divnum);
      if str[1] = '-' then
      begin
        tmp := tmp + str;
        str := '';
      end;
    end;
    tmp := tmp + ' ' + str;
    StrCopy(dest,PChar(ReverseString(Trim(tmp))));
end;


end.
