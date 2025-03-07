unit longint;
{
*********************************************************

���{���������Z���[�`�� longint

  programmed & arranged by "replaceable anonymous"
*********************************************************

����:
  �I���W�i���͊��100�ł�
	http://www5.airnet.ne.jp/tomy/
		(Tomy's home page/�Z�p�v�Z�pC�v���O�����\�[�X by Tomy)

�Q�l�}�� :
	�R���s���[�^�Ƒf���q����/�a�c�G�j��/�V����
	UBASIC�ɂ��R���s���[�^�����_/�ؓc�S�i�E�q�쌉�v��/���{�]�_��

*********************************************************


Delphi�ŉ��ŗ���

ver 0.0.0 2004/01/19
    c�x�[�X����Delphi�x�[�X�ɈڐA�J�n
      �[���N���A��FillChar��
      register�Ăяo���K��ɕύX

ver 0.0.1 2004/01/20
    1add�ڐA�B�ו��C��

ver 0.0.2 2004/01/22
    2mul�ڐA�B�ו��C��
      smuladd(d=d+a*b,lmulp�Ŏg�p)��Ɨ��A�ו��C��
      lmul�n�ő�1�������������^�̕����p��
        lmulp,lmulpb/lmul(overload)

ver 0.0.3 2004/01/25
    3div�ڐA�B�ו��C��
      ������LINT�ϊ����[�`����String���g�p����悤�ɂ���
    2mul�C��
      lmulp��ldivp�Ɠ��l�ɓ����o�b�t�@�𓮓I�m�ۂ���悤�ɂ���
    �v�Z���[�`���Ɋւ���TLINT�̃T�C�Y�����傫���o�b�t�@���^����
    �����Ɍv�Z�����Ă��o�b�t�@�����Ȃ��悤�ɂȂ����͂�

ver 0.0.4 2004/01/25
    4lib�ڐA�B�ו��C��
      lpwr�̈�����ύX(����̂ɖ߂���)

ver 0.0.5 2004/02/10
    PCharLib(3div�̕ϊ����[�`����PChar��)
    �o�Ofix
      lmulpb�œ��I�Ɋm�ۂ����o�b�t�@�̃N���A�~�X���C��
      lfixb��lmulpb�p�ɉ���
      lmulp�œ����o�b�t�@����̏����߂��~�X���C��

ver 0.1.1 2004/02/15
    �ǂ����ł��������Ƃ���DWORD��Cardinal�ɖ߂����B
    32bit�̕����Ȃ������Ȃ牽�ł������킯�ŁB
    �������ɂ��ꂪ�Ⴄ�̂͒m���

ver 0.1.2 2004/02/18
    aux1��alsub�ŃL�����[�t���O���N���A���ĂȂ������̂��C��

////////////////////////////////////////////////////////

C�ŉ��ŗ���

ver 0.1 2003/09/12
	���샋�[�`�������ׂ�2^32����ɏ��������B
	���̉e���ŃA�Z���u�����g�p�B
	�A�Z���u�����[�`���͎Q�l�}���̃A���S���Y�����g�p���܂����B

ver 0.11 2003/10/01
	lwrite�h���o�[�W�����ǉ�

ver 0.2 2003/10/02
	�_�����Z���[�`���ǉ�

ver 0.3 2003/10/10
	lmulpmod�ǉ�
	ldivp�C��
	lpwrmod�C��

*********************************************************

}
interface

uses
  Types,SysUtils;

const
  LINTMaxLen = 32;        {���{���ϕ��̍ő咷}


type
  PLINT = ^TLINT;

  TLINT = record
    Len: Integer;             {�ϕ��̊i�[�f�[�^��;0�̂Ƃ���0}
    Sign: Integer;            {����;���̎�0,���̎���0}
    Num: array[0..LINTMaxLen+1] of Cardinal;
                              {�f�[�^��;MAXLEN+2(�\����)}
  end;

  TLINT2 = record             {2�{���o�b�t�@�Amod�v�Z�p}
    Len: Integer;
    Sign: Integer;
    Num: array[0..LINTMaxLen*2+1] of Cardinal;
  end;

  ELINTError = class(Exception);
  ELINTOverflow = class(ELINTError);
  ELINTIllegalFunctionCall = class(ELINTError);

{�����p�萔}
const
  LINTSize = SizeOf(TLINT);   {TLINT�^�̃T�C�Y(asm���[�`���p)}

  LINTStrLen = Trunc(LINTMaxLen*32*0.301)+2;  {10�i�\�����ő包��}
  LINTHexStrLen = LINTMaxLen*8+1;             {16�i�\�����ő包��}

  LINTBase = 1000000000;  {10�i�ϊ����̊�l(10^x��int���E�𒴂��Ȃ��ő�l)}
  LINTBaseLog = 9;        {10�i�ϊ����̊�l}
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
    ��{����A���Z���Z���[�`��
 ****************************************************)

//
//  LINT *lfix(LINT *a)
//    LINT�^�Ƃ��ĕs�K�؂Ȓ���(�f�[�^��)���C������
//    �]�蕔�����N���A����
//
//    ��)���̊֐��͒�`���ꂽLINTMaxLen�ł����g���Ȃ�
//       LINT�̒������قȂ�ƃo�b�t�@�I�[�o�t���[��
//       �S�~���c�邱�Ƃ�����܂�
//
//  LINT *lfixb(LINT *a,int len)
//    �����̃`�F�b�N���キ�s��
//    LINT��蒷�����������e����
//    len��蒷�����Z�����len���o�b�t�@���Ƃ݂ăN���A����
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
//    int�^������LINT�^�ϐ��ɑ������
//
//    ��)���̊֐��͒�`���ꂽLINTMaxLen�܂łł����g���Ȃ�
//       LINT�̒������قȂ�ƃo�b�t�@�I�[�o�t���[��
//       �S�~���c�邱�Ƃ�����܂�
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
//    �ΒP������Βl���Z(0 <= n <= 0xFFFFFFFF)
//      �o�b�t�@�I�[�o�����̓e�X�g���Ȃ��̂ŌĂяo�����ŋC�����Ă�������
//      �I�[�o�[�t���[�ōő�1�������܂�
//
//    eax = a; edx = n
//
function alinc(a: PLINT; n: Cardinal): PLINT; register;
asm
    push    ebx
    test    n,n {���Z����0�e�X�g}
    jz      @IncEnd
  @IncMain:
    mov     ebx,a
    mov     ecx,TLINT[eax].len {a.len}
    test    ecx,ecx
    jnz     @IncMulti
  @IncSet:                     {a=0�Ȃ̂ŃZ�b�g���ďI���}
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
    xor     edx,edx                       {�ʏオ��}
    inc     edx
    mov     [eax],edx                {�ŏ�� = 1}
    inc     TLINT[ebx].len           {a.len++}
  @IncEnd:
    mov     eax,ebx
    pop     ebx
end;


//
//  LINT *aldec(LINT *a,unsigned int n)
//    �ΒP������Βl���Z(0 <= n <= 0xFFFFFFFF)
//      ���Z���ʂ���0���܂������́A�����𔽓]���܂�(aldec(-5,10) -> +5)
//
//    eax = a; edx = n
//
function aldec(a: PLINT; n: Cardinal): PLINT; register;
asm
    push    ebx
    test    n,n
    jz      @DecEnd  {n=0; ���̂܂܏I��}
  @DecMain:
    mov     ebx,a
    mov     ecx,TLINT[ebx].len
    test    ecx,ecx
    jz      @Decset  {a.len=0; �l���Z�b�g���ďI��}
    dec     ecx
    jnz     @DecMulti
    jmp     @DecOne  {a.len=1; �P��,�������]�̉\��}
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
  @DecZero:                       {���ʂ�0}
    mov     TLINT[ebx].sign,ecx   {a.sign = 0}
    mov     TLINT[ebx].len,ecx    {a.len  = 0}
    jmp     @DecEnd
  @DecMinus:
    neg     ecx
    not     TLINT[ebx].sign     {a.sign�𔽓]}
    mov     DWORD PTR [TLINT[ebx].num[0]],ecx  {a.num[0]�𔽓](����)}
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
  @DecKetaSage:                     {�ʉ�����}
    dec     TLINT[eax].len
  @DecEnd:
    pop     ebx
end;

//
//  int lcmp(const LINT *a,const LINT *b)
//    ��Βl��r
//      �Ԃ�l
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
      cmp     ecx,TLINT[esi].len    {len���r}
      jz      @CmpMain
      jb      @CmpL
  @CmpH:
      inc     eax                   {a>b : eax=1}
      jmp     @CmpEnd
  @CmpL:
      dec     eax                   {a<b : eax=-1}
      jmp     @CmpEnd
  @CmpMain:
      lea     edi,[edi+ecx*4+4]   {�ŏ�ʂ����r}
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
//    ��Βl���Z d=d+s
//      (�A��|d|>=|s|,d�̌��������v�Z�����)
//    ���̉��Z�ŕ����͑��삳��Ȃ�
//
function aux1(d: PLINT;const s: PLINT): PLINT; register;
asm
      push    esi
      push    edi
      mov     esi,s
      mov     edi,d
      mov     ecx,TLINT[edi].len {d.len�����J��Ԃ�}
      mov     edx,edi            {d��ۑ�}
      lea     esi,TLINT[esi].num[0]
      lea     edi,TLINT[edi].num[0] {num[0]�Ƀ|�C���^���Z�b�g}
      clc
  @Aux1Loop:
      mov     eax,[esi]             {���̌����瑫���Ă���}
      adc     [edi],eax
      lea     esi,[esi+4]
      lea     edi,[edi+4]
      dec     ecx
      jnz     @Aux1Loop
      jnc     @Aux1End
  @Aux1KetaAge:                     {�ʏオ��}
      inc     DWORD PTR [TLINT[edx].len]
      inc     DWORD PTR [edi]
  @Aux1End:
      mov     eax,edx
      pop     edi
      pop     esi
end;

//
//  LINT *alsub(LINT *d,const LINT *s)
//    ��Βl���Z d=d-s
//      (�A��|d|>=|s|,d�̌��܂ł����v�Z����Ȃ�)
//    ���̉��Z�ŕ����͑��삳��Ȃ�
//
function alsub(d: PLINT;const s: PLINT): PLINT; register;
asm
      push    esi
      push    edi
      mov     esi,s
      mov     edi,d
      mov     ecx,TLINT[edi].len   {d.len�����J��Ԃ�}
      mov     edx,edi              {d�̃|�C���^��ۑ�}
      lea     esi,TLINT[esi].num[0]
      lea     edi,TLINT[edi].num[0]
      clc
  @Loop:
      mov     eax,[edi]            {���̌����猸�Z}
      sbb     eax,[esi]
      mov     [edi],eax
      lea     esi,[esi+4]
      lea     edi,[edi+4]
      dec     ecx
      jnz     @Loop
      test    eax,eax
      jnz     @End
  @KetaSage:
      mov     ecx,TLINT[edx].len   {�ʉ�����}
      std
      lea     edi,[edi-4]          {�ŏ�ʂ���͂��߂�0�łȂ�}
      repe    scasd                {���𑖍�,(eax=0)}
      jz      @Zero
      inc     ecx                  {0�̎��̂ݒ���0}
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
//    �ΒP�������Z(��������) a=a-n
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
//    �ΒP�������Z(��������) a=a-n
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
//    ���Z(��������) d=d+s
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
//    ���Z(��������) d=d+s
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
    ��Z�A�V�t�g���샋�[�`��
 ****************************************************)

//
//  LINT *smul(LINT *a,unsigned int b,unsigned int w)
//    �ΒP������Βl��Z a=a*b+w
//      �A��b=0�̂Ƃ���a��lfix���Ȃ���΂Ȃ�Ȃ�
//      (������0�ɂ��邪�t�B�[���h���N���A���Ȃ�)
//    �I�[�o�[�t���[�ōő�1�������܂��̂ŌĂяo�����ŋC�����Ă�������
//
function smul(a: PLINT; b: Cardinal; w: Cardinal): PLINT; register;
asm
      push    esi
      push    edi
      push    ebx
      push    a                     {dest��ޔ�}
      mov     esi,a
      mov     ebx,b
      mov     edi,w
      mov     ecx,TLINT[esi].len
      xor     eax,eax
      mov     TLINT[esi].len,eax    {b��0�̎��̂��߂�len���N���A}
      lea     esi,TLINT[esi].num[0]
      test    ebx,ebx
      jz      @KetaFix
      test    ecx,ecx
      jz      @KetaFix
      mov     [esi-8],ecx
  @Loop:                            {a.len��J��Ԃ�}
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
  @KetaFix:                         {���オ��}
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
//    �ΒP������Βl��Z���Z d=d+a*b
//      �I�[�o�[�t���[���͍ő�2�������܂��̂ŌĂяo�����Œ��ӂ��Ă�������
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
      push    edi       {d��ۑ�}
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
      pop     esi       {d�𕜌�}
      mov     ecx,edi
      sub     ecx,esi
      sar     ecx,2
      dec     ecx       {ecx�ő包��}
      cmp     ecx,TLINT[esi].len
      jae     @KetaTest
      mov     ecx,TLINT[esi].len
    @KetaTest:
      std
      xor     eax,eax
      repz    scasd     {�ォ��݂Ă�����0�łȂ��Ƃ��낪����}
      jz      @KetaSet
      inc     ecx       {���ׂ�0�̎��ȊO��+1}
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
//    a=a<<c as DWORD           ��)�o�b�t�@�I�[�o�����݂͂܂���
//  LINT *lshr32(LINT *a,int c)
//    a=a>>c as DWORD           ��)0�ȉ��̎��̓S�~���c��̂�lfix��
//  LINT *lshl1(LINT *a,int c)
//    a=a<<c as bit             ��)c�͉���5bit���g�p����܂�
//  LINT *lshr1(LINT *a,int c)
//    a=a>>c as bit             ��)c�͉���5bit���g�p����܂�
//
//    �I�[�o�[�t���[����lshr1�͍ő�1���Alshr32�͍ő��c�������܂��̂�
//    �Ăяo�����ŋC�����Ă�������
//******************************************************************
// lshr32�͈����ɂ���Ă̓������j��������N�����̂œ��ɒ��ӂ��Ă�������
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
      lea     esi,[edx+ecx*4+4]  {&a.num[a.len-1] �ŏ��}
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
      jle     @Zero           {len<=0�Ȃ�len=0}
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
      mov     esi,a                {a��ޔ�}
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
      mov     [edi],eax                   {�ʏオ��}
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
      lea     edi,[esi+ebx*4+4]  {&a.num[a.len-1] �ŏ��}
      jz      @End
      mov     eax,[edi]
      xor     edx,edx
      shrd    eax,edx,cl
      mov     edx,[edi]
      mov     [edi],eax
      lea     edi,[edi-4]
      jnz     @Loop              {�ŏ�ʂ�0�Ȃ猅����}
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
//    ��Βl��Z a=a*b
//      (a=b���w���)
//    �ő��a.len+b.len���܂ł����̂ŃI�[�o�t���[�ɋC�����Ă�������
//
//
//***************************************************************
//    �����ɂ���Ă̓������j��������N�����̂œ��ɒ��ӂ��Ă�������
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
      add     ecx,4                     {a.len+b.len���v�Z}
      lea     eax,[ecx*4]
      cmp     eax,LINTSize
      jg      @Alloc                    {�f�t�H���g��菬������΃f�t�H���g�l}
      mov     eax,LINTSize
      mov     ecx,LINTSize/4
    @Alloc:
      sub     esp,eax
      mov     tmp,esp
      mov     edi,esp
      xor     eax,eax
      rep     stosd                      {tmp=0:�������ݗp�̈�m��}
      mov     edi,b
      mov     edx,TLINT[esi].len      {a.len}
      test    edx,edx
      jz      @Copy
      mov     ebx,TLINT[edi].len      {b.len}
      test    ebx,ebx
      jz      @Copy                {a=0 or b=0 then end}
      lea     edi,[edi+ebx*4+4]  {&b.num[b.len-1] �ŏ��}
      mov     eax,tmp
  @Loop:
      mov     edx,esi
      mov     ecx,[edi]
      call    smuladd             {[eax]=[edx]*ecx}
      dec     ebx
      jz      @Copy
      mov     edx,1
      call    lshl32              {1���グ��}
      lea     edi,[edi-4]
      jmp     @Loop
  @Copy:
      mov     edi,esi
      mov     esi,tmp
      mov     ecx,TLINT[esi].len
      add     ecx,2
      mov     eax,edi
      rep     movsd                    {a^:=tmp �������ݗp�̈悩��߂�}
  @End:
      mov     esp,tmpESP
      pop     ebx
      pop     edi
      pop     esi
end;

//
//  LINT *lmulpb(LINT *w,const LINT *a,const LINT *b)
//    ��Βl��Z w=a*b
//      w��a,b���w�肵�Ă͂Ȃ�܂���
//      �ő��a.len+b.len���܂ł����̂�
//      w�Ŏw�肵���o�b�t�@���z���Ȃ��悤�ɒ��ӂ��Ă�������
//
//    ��)w���N���A����ۂ�LINTMaxLen���g�p���܂�
//       w��LINT�����傫�����K�v������܂�
//
//***************************************************************
//    �����ɂ���Ă̓������j��������N�����̂œ��ɒ��ӂ��Ă�������
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
      lea     edi,[edi+ebx*4+4]  {&b.num[b.len-1] �ŏ��}
  @Loop:
      mov     edx,esi
      mov     ecx,[edi]
      call    smuladd             {[eax]=[edx]*ecx}
      dec     ebx
      jz      @End
      mov     edx,1
      call    lshl32              {1���グ��}
      lea     edi,[edi-4]
      jmp     @Loop
  @End:
      pop     ebx
      pop     edi
      pop     esi
end;

//
//  LINT *lmul(LINT *a,const LINT *b)
//    ��Z a=a*b
//      (a=b���w���)
//    �I�[�o�[�t���[�݂͂Ȃ��̂ŌĂяo�����ŐӔC�����悤��
//
//  LINT *lmul(LINT *w,const LINT *a,const LINT *b)
//    ��Z w=a*b
//      w��a,b���w�肵�Ă͂Ȃ�܂���(a=b�͉�)
//      w�Ŏw�肵���o�b�t�@���z���Ȃ��悤�ɒ��ӂ��邱��
//
//    �ǂ�����ő��a.len+b.len���܂ł����̂ŃI�[�o�t���[�ɋC�����Ă�������
//**************************************************************************
// �����ɂ���Ă̓X�^�b�N�܂��̓������j��������N�����̂œ��ɒ��ӂ��Ă�������
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
    ���Z�A�\��������ϊ����[�`��
 ****************************************************)

//
//  LINT *sdiv(LINT *a,unsigned int n,unsigned int *r)
//    �ΒP������Βl���Z a��n�Ŋ���A��a�]��r
//
function sdiv(a: PLINT; n: Cardinal; out r: Cardinal): PLINT;
asm
      push    esi
      push    edi
      push    ebx
      push    r             {�]��ւ̃|�C���^��ۑ�}
      mov     edi,a
      mov     ebx,n
      mov     esi,edi
      mov     ecx,TLINT[edi].len
      test    ecx,ecx
      jnz     @Main
      xor     edx,edx            {a.len=0�̂Ƃ��]��r=0}
      jmp     @End
  @Main:
      lea     edi,[edi+ecx*4+4]   {&a.num[a.len-1] �ŏ��}
      xor     edx,edx
      mov     eax,[edi]
      div     ebx
      test    eax,eax
      mov     [edi],eax
      jnz     @Loop
      dec     TLINT[esi].len    {���̍ŏ�ʂ�0�̎��̂݌���1����������}
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
      mov     [edi],edx      {*r=�]��}
      mov     eax,esi
      pop     ebx
      pop     edi
      pop     esi
end;

//
//  function StrToLINT(var a:TLINT; str: String): PLINT;
//    �������LINT�^�ɕϊ����܂�
//      �ϊ���i�[����LINT�^�ϐ���a�Ɏw�肵�Ă�������
//      �ϊ���ϐ��������|�C���^��Ԃ��܂�
//
//    ��)���̊֐��͒�`���ꂽLINTMaxLen�܂łł����g���Ȃ�
//       �I�[�o�[�t���[�����ۂ�ELINTOverflow�𓊂��܂�
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
    end;                            // �������������������R�s�[����B

    str := StringReplace(str,' ','',[rfReplaceAll]);
    str := StringReplace(str,#13#10,'',[rfReplaceAll]); //�󔒂�����
    max := length(str);         //�������v�Z

    len := max;
    for i:= 1 to max do
    begin
      if not (str[i] in ['0'..'9']) then
      begin
        len := i-1;             //  �����łȂ��Ƃ���őł�����B
        Break;
      end;
    end;

    str := copy(str,1,len);
  	//�n�߂���BASE2���������l�ɒ���
    for i := 1 to (len div LINTBaseLog) do
    begin
      smul(@a,LINTBase);
      if a.Len > LINTMaxLen then
        raise ELINTOverflow.Create('conversion Error: Overflow');
      alinc(@a,StrToInt(copy(str,1,LINTBaseLog)));
      Delete(str,1,LINTBaseLog);
    end;
    //�[��
    if Length(str) <> 0 then
      smul(@a,Pow10[Length(str)],StrToInt(str));
    if a.Len > LINTMaxLen then
      raise ELINTOverflow.Create('conversion Error: Overflow');
end;

//
//  function LINTtoStr(a:TLINT): String;
//    LINT�^�ϐ��𕶎���ɂ��܂�
//      �ϊ���̕������Ԃ��܂�
//
//  function LINTtoStr(a:TLINT; divnum: Integer): String;
//    LINT�^�ϐ���divnum�������Ƃɋ�؂��ĕ�����ɂ��܂�
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
//    16�i�����������LINT�^�ɕϊ����܂�
//      �ϊ���i�[����LINT�^�ϐ���a�Ɏw�肵�Ă�������
//      �ϊ���ϐ��������|�C���^��Ԃ��܂�
//
//    ��)���̊֐��͒�`���ꂽLINTMaxLen�܂łł����g���Ȃ�
//       �I�[�o�[�t���[�����ۂ�ELINTOverflow�𓊂��܂�
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
    end;                            // �������������������R�s�[����B

    str := StringReplace(str,' ','',[rfReplaceAll]);
    str := StringReplace(str,#13#10,'',[rfReplaceAll]); //�󔒂�����
    str := LowerCase(str);
    max := length(str);         //�������v�Z

    len := max;
    for i:= 1 to max do
    begin
      if not (str[i] in ['0'..'9','a'..'f']) then
      begin
        len := i-1;             //  16�i�����łȂ��Ƃ���őł�����B
        Break;
      end;
    end;

    str := copy(str,1,len);
  	//�n�߂���8���������l�ɒ���
    for i := 1 to (len div 8) do
    begin
      lshl32(@a,1);
      if a.Len > LINTMaxLen then
        raise ELINTOverflow.Create('conversion Error: Overflow');
      alinc(@a,StrToInt('$'+copy(str,1,8)));
      Delete(str,1,8);
    end;
    //�[��
    if Length(str) <> 0 then
      linc(lshl1(@a,Length(str)*4),StrToInt('$'+str));
    if a.Len > LINTMaxLen then
      raise ELINTOverflow.Create('conversion Error: Overflow');
end;

//
//  function LINTtoHex(a:TLINT): String;
//    LINT�^�ϐ��𕶎���ɂ��܂�
//      �ϊ���̕������Ԃ��܂�
//
//  function LINTtoHex(a:TLINT; divnum: Integer): String;
//    LINT�^�ϐ���divnum�������Ƃɋ�؂��ĕ�����ɂ��܂�
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
//    ��Βl���Z a/b���v�Z���A��c,�]��a(�Ԃ�l�̃|�C���^�͗]���a)
//      �����̏����ɒ��ӂ��Ă�������
//
//    *���̊֐���cdecl�Ăяo���K��ł�
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
    lset(c,0);          {c���N���A}
    if b.Len = 0 then
    begin               {b��0�̎���0div��O�𓊂���}
      asm
        xor   edx,edx
        div   edx
      end;
      Exit;
    end;
    if lcmp(a,b) < 0 then  {a<b�̂Ƃ��͏�0�]��a�Ń��^�[��}
    begin
      Exit;
    end;
    if b.Len = 1 then      {b.len=1��sdiv�ɈϔC}
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
        pop   edx                {�]���ޔ�}
        mov   esi,eax
        mov   edi,c
        mov   ecx,TLINT[eax].len
        add   ecx,2              {c�̗]��̈�̓N���A����Ă���̂�}
        rep   movsd              {�R�s�[���邾���ł���}
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
        lea     eax,[eax*4+16]      {a���R�s�[�ł���T�C�Y���m��}
        cmp     eax,LINTSize
        jg      @DAllocDo
        mov     eax,LINTSize
        mov     tmpDlen,LINTMaxLen+2
       @DAllocDo:
        sub     esp,eax             {MAXLEN+2+2(len+sign)}
        mov     tmpD,esp
        mov     tmpB,esi
      @ABfixTest:                   {a,b�𐳋K������}
        mov     ecx,TLINT[esi].len
        mov     ebx,[esi+ecx*4+4]   {b.num[b.len-1] �ŏ�ʂ̓��e}
        bsr     edx,ebx
        neg     edx
        add     edx,31
        mov     shift_d,edx         {���K���̃V�t�g��}
        jz      @ABnonshift         {�ŏ�ʃr�b�g�������Ă�΃V�t�g�Ȃ�}
      @ABshift:
       @tmpBAlloc:
        lea     eax,[ecx*4+16]      {b���R�s�[�ł���T�C�Y���m��}
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
      @MainLoop:                    {�ȉ�b�� b �܂��� tmpB}
        mov     edx,[edi+eax*4+4]   {a.num[a.len-1] �ŏ�ʂ̓��eA[n]}
        mov     ebx,[esi+ecx*4+4]   {b.num[b.len-1] �ŏ�ʂ̓��eB[m]}
        cmp     ebx,edx
        ja      @PreDiv             {B[m]>A[n]�Ȃ�jmp}
      @NonPreDiv:
        mov     edi,tmpD
        mov     TLINT[edi].len,eax
        mov     ebx,ecx             {b.len��ޔ�}
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
        jl      @Qfix               {a<tmpB��jmp:eax=FFFFFFFF}
      @Qis1:
        mov     eax,1               {a>=tmpB�̂Ƃ�}
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
        jna     @End                {a.len<=b.len�ŏI��(�ŏ��A[n]<B[m]���a<b������)}
        dec     edx
        add     ecx,2
        mov     edi,tmpD            {tmpD=b*eax(��)*B^(n-m-1)}
        rep     movsd
        mov     Q_eax,eax
        mov     D_nm,edx
        mov     eax,tmpD
        mov     edx,tmpDlen
        call    lfixb      {lfixb(tmpD)}
        mov     edx,Q_eax
        xor     ecx,ecx
        call    smul      {lsmul(tmpD,eax(��),0)}
        mov     edx,D_nm
        call    lshl32     {lshl32(tmpD,(n-m-1))}
      @QLoop:
        mov     edx,eax
        mov     esi,eax   {tmpD}
        mov     eax,a
        mov     edi,eax   {a}
        call    lcmp                {a>=tmpD(�����K��)�Ȃ�jmp}
        cmp     eax,0
        jge     @Sub
        mov     eax,esi             {Q_eax--;tmpD���C��}
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
        jae     @MainLoop           {a.len>=b.len�Ń��[�v�p��}
      @End:
        mov     esi,c
        mov     ecx,TLINT[esi].len
        mov     eax,[esi+ecx*4+4]   {c.num[c.len-1] ���̍ŏ��}
        test    eax,eax
        jnz     @Afix
        dec     ecx                 {�ŏ�ʂ�0�Ȃ猅�����炷}
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
//    ���Z a/b���v�Z���A��c,�]��a(�Ԃ�l�̃|�C���^�͗]���a)
//      �����̏����ɒ��ӂ��Ă�������
//
//    �]�肪0�����Ɉ�ԋ߂��Ȃ�悤�ɏ��Ɨ]�肪�I�΂�܂�
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
//    gcd(a,b)�ő����
//      �A��a,b�͐��łȂ��Ă͂Ȃ�܂���B
//      �������s���̂Ƃ���ELINTIllegalFunctionCall��O���������܂�
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
//    lcm(a,b)�ŏ����{��
//      �����ł�a*b/gcd(a,b)���v�Z���܂�
//
//      �A��a,b�͐��łȂ��Ă͂Ȃ�܂���B
//      �������s���̂Ƃ���ELINTIllegalFunctionCall��O���������܂�
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
//    �@n�ł�s�̋t��
//      x*s��1 (mod n) �Ȃ�x�����߂�
//      �A��gcd(s,n)=1
//
//    ���߂��Ȃ�����x=0���Ԃ�
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
//    �@n�ł̐�Βl��Z a = a*b (mod n)
//      �����o�b�t�@�͔{�Ƃ��Ă���̂ň��邱�Ƃ͂Ȃ�
//
//    ��)���̊֐��͒�`���ꂽLINTMaxLen�܂łł����g���Ȃ�
//       ����ȏオ�^�����邱�Ƃ͑z�肳��Ă��܂���
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
//    �ׂ��� x = x^y
//      �I�[�o�[�t���[�����ELINTOverflow���������܂�
//      �I�[�o�[�t���[���̒l�͕ۏ؂���܂���
//
//    ��)���̊֐��͒�`���ꂽLINTMaxLen�܂łł����g���Ȃ�
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
      bsr   edi,ebx      {�ŏ�ʃr�b�g����}
      inc   edi
    @Loop:
     @APart:
      shr   ebx,1
      jnc   @ANextmul
      lea   ecx,tmp1     {�r�b�g�������Ă���Ί|����}
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
      rep   movsd        {�o�b�t�@����x�ɖ߂�}
      mov   edi,edx
      mov   esi,eax
     @ANextmul:
      dec   edi
      jz    @End
      lea   edx,tmp1     {��悷��}
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
//    �@n�̂��Ƃł̗ݏ��] x = x^y(mod n)
//      �A���An�͐�,y>0�܂���xy<>0
//      �����ȏ��ELINTIllegalFunctionCall���������܂�
//
//    ��)���̊֐��͒�`���ꂽLINTMaxLen�܂łł����g���Ȃ�
//       x,n�����Ă���ƃI�[�o�[�t���[ELINTOverflow���������܂�
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
//    �������LINT�^�ɕϊ����܂�
//      �ϊ���i�[����LINT�^�ϐ���a�Ɏw�肵�Ă�������
//      �ϊ���ϐ��������|�C���^��Ԃ��܂�
//
//    ��)���̊֐��͒�`���ꂽLINTMaxLen�܂łł����g���Ȃ�
//       �I�[�o�[�t���[�����ۂ�ELINTOverflow�𓊂��܂�
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
    end;                            // �������������������R�s�[����B

    tmp := StringReplace(tmp,' ','',[rfReplaceAll]);
    tmp := StringReplace(tmp,#13#10,'',[rfReplaceAll]); //�󔒂�����
    max := length(tmp);         //�������v�Z

    len := max;
    for i:= 1 to max do
    begin
      if not (tmp[i] in ['0'..'9']) then
      begin
        len := i-1;             //  �����łȂ��Ƃ���őł�����B
        Break;
      end;
    end;

    tmp := copy(tmp,1,len);
  	//�n�߂���BASE2���������l�ɒ���
    for i := 1 to (len div LINTBaseLog) do
    begin
      smul(@a,LINTBase);
      if a.Len > LINTMaxLen then
        raise ELINTOverflow.Create('conversion Error: Overflow');
      alinc(@a,StrToInt(copy(tmp,1,LINTBaseLog)));
      Delete(tmp,1,LINTBaseLog);
    end;
    //�[��
    if Length(tmp) <> 0 then
      smul(@a,Pow10[Length(tmp)],StrToInt(tmp));
    if a.Len > LINTMaxLen then
      raise ELINTOverflow.Create('conversion Error: Overflow');
end;

//
//    function LINTtoPStr(dest: PChar; a:TLINT): PChar; overload;
//    LINT�^�ϐ���PChar������ɂ��܂�
//
//    function LINTtoPStr(dest: PChar; a:TLINT; divnum: Integer): PChar; overload;
//    LINT�^�ϐ���divnum�������Ƃɋ�؂���PChar������ɂ��܂�
//
//      �ϊ���̊i�[�̈��dest�Ɏw�肵�Ă��������B
//        �T�C�Y�̓`�F�b�N����܂���
//        log2*LINTMAXLEN*32 �������傫���Ƃ��Ă�������
//      �i�[�̈���w���|�C���^��Ԃ��܂�
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
//    16�i����PChar�������LINT�^�ɕϊ����܂�
//      �ϊ���i�[����LINT�^�ϐ���a�Ɏw�肵�Ă�������
//      �ϊ���ϐ��������|�C���^��Ԃ��܂�
//
//    ��)���̊֐��͒�`���ꂽLINTMaxLen�܂łł����g���Ȃ�
//       �I�[�o�[�t���[�����ۂ�ELINTOverflow�𓊂��܂�
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
    end;                            // �������������������R�s�[����B

    tmp := StringReplace(tmp,' ','',[rfReplaceAll]);
    tmp := StringReplace(tmp,#13#10,'',[rfReplaceAll]); //�󔒂�����
    tmp := LowerCase(tmp);
    max := length(tmp);         //�������v�Z

    len := max;
    for i:= 1 to max do
    begin
      if not (tmp[i] in ['0'..'9','a'..'f']) then
      begin
        len := i-1;             //  16�i�����łȂ��Ƃ���őł�����B
        Break;
      end;
    end;

    tmp := copy(tmp,1,len);
  	//�n�߂���8���������l�ɒ���
    for i := 1 to (len div 8) do
    begin
      lshl32(@a,1);
      if a.Len > LINTMaxLen then
        raise ELINTOverflow.Create('conversion Error: Overflow');
      alinc(@a,StrToInt('$'+copy(tmp,1,8)));
      Delete(tmp,1,8);
    end;
    //�[��
    if Length(tmp) <> 0 then
      linc(lshl1(@a,Length(tmp)*4),StrToInt('$'+tmp));
    if a.Len > LINTMaxLen then
      raise ELINTOverflow.Create('conversion Error: Overflow');
end;

//
//    function LINTtoPHex(dest: PChar; a:TLINT): PChar; overload;
//    LINT�^�ϐ���PChar������ɂ��܂�
//
//    function LINTtoPHex(dest: PChar; a:TLINT; divnum: Integer): PChar; overload;
//    LINT�^�ϐ���divnum�������Ƃɋ�؂���PChar������ɂ��܂�
//
//      �ϊ���̊i�[�̈��dest�Ɏw�肵�Ă��������B
//        �T�C�Y�̓`�F�b�N����܂���
//        LINTMAXLEN*8 �������傫���Ƃ��Ă�������
//      �i�[�̈���w���|�C���^��Ԃ��܂�
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
