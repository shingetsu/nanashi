unit RC4;
{
*********************************************************

RC4���ʌ��Í����[�`��
Delphi��

  programmed by "replaceable anonymous"
*********************************************************

�I���W�i���v���O����

  "Winny �m�[�h��񕜍�(winnyaddrdec)"
  http://www.geocities.co.jp/SiliconValley-Sunnyvale/7511/
    SIWITA by hikobae

  ���̃v���O�����͏�L�I���W�i���v���O�����̂Ȃ���
  RC4���[�`�������ɍ쐬���܂����B

http://www.geocities.co.jp/SiliconValley-Sunnyvale/7511/readme.html
>���쌠
>���̃T�C�g���̕��͂�A���̃T�C�g�Ŕz�z���Ă���c�[�����̒��쌠��
>���i hikobae �j���ێ����܂��B�t���[�Ŕz�z���Ă��܂������쌠�����
>���Ă���킯�ł͂���܂���B�e�c�[�����ɂ͌����Ƃ��ă\�[�X�t�@�C����
>�������Ă��܂����A����ɂ��Ă����l�ł��B
>�\�[�X�t�@�C���͎��R�ɗ��p���Ă��������Ă��܂��܂��񂪁A�\�[�X�t�@�C����
>���p���č쐬�����c�[����\�t�g�����J����ۂɂ́A���̃T�C�g���̃\�[�X�t�@�C����
>���p�������Ƃ� readme.txt ���ɖ��L���Ă��������B
>���̃T�C�g���̕��͂�A���̃T�C�g�Ŕz�z���Ă���c�[�����̓]�ځE�Ĕz�z�E�~���[��
>�͌����Ƃ��ċ֎~���܂��B

�Ƃ���܂��̂ŁA�\�[�X�t�@�C���𗘗p�����Ă��������܂��B
*********************************************************
Delphi�ŉ��ŗ���

  ver 0.0.0   2004/02/12
    c�ł���ڐA

  ver 0.1.0   2004/03/21
    �X�g���[���o�[�W������������B
    1byte�����Ȃ�o�O���C��

  ver 0.1.1   2004/03/24
    �����w��ł���悤�ɉ���

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
