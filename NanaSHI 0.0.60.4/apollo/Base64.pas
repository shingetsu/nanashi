
unit Base64;

interface

uses
  SysUtils, WinTypes, Classes;

function base64encode(Stream: TStream; Size: Integer): string;
function base64decode(Stream: TStream; Text: string): Integer;

implementation

// �R�o�C�g���̃o�C�g�I�[�_�[���C������iKylix�ł͕s�v�̂͂��j
function exchange_0_2(Src: DWORD): DWORD;
type
  TTemp = array[0..3]of BYTE;
begin
  Result := Src;
  TTemp(Result)[2] := TTemp(Src)[0];
  TTemp(Result)[0] := TTemp(Src)[2];
end;

// Stream����Size�o�C�g��ǂݍ��݁A�G���R�[�h�����������Ԃ�
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
    // Src����m�o�C�g��Value�ɓǂݍ���
    Move(PBYTE(Src)^, Value, N);
    // �o�C�g�I�[�_�[���C���iKylix�ł͕s�v�̂͂��j
    Value := exchange_0_2(Value);
    // Src�̓ǂݍ��݈ʒu��i�߂�
    Inc(Integer(Src), N);
    // 6�r�b�g���G���R�[�h�~�S��
    for I := 3 downto 0 do
    begin
      if I > N then
        Dst[I] := '=' // �ϊ����Ȃ����́e=�f�Ńp�f�B���O����
      else
        Dst[I] := Table[Value and $3f];
      Value := Value shr 6;
    end;
    // ���̏������݈ʒu�ɂ���
    Inc(Integer(Dst), 4);
  end;

begin
  Buffer := AllocMem(Size);
  try
    Size := Stream.Read(PBYTE(Buffer)^, Size);
    // �G���R�[�h��̕�����̒����ɂ���
    SetLength(Result, (Size + 2) div 3 * 4);
    if Size > 0 then
    begin
      // �ǂݍ��݌��̃|�C���^
      Src := Buffer;
      // �������ݐ�̃|�C���^
      Dst := PChar(Result);
      // �R�o�C�g����������
      for I := 0 to Size div 3 - 1 do
        doNbyte(3);
      if (Size mod 3) > 0 then
        doNbyte(Size mod 3);
    end;
  finally
    FreeMem(Buffer);
  end;
end;

// Text���f�R�[�h����Stream�ɏ������݁A�������񂾃o�C�g����Ԃ�
function base64decode(Stream: TStream; Text: string): Integer;
var
  Src: PChar;
  I: Integer;

  // �e�������U�r�b�g�f�[�^�ɕϊ�����
  function decode(code: BYTE): BYTE;
  begin
    case Char(code) of
    'A'..'Z': Result := code - BYTE('A');
    'a'..'z': Result := code - BYTE('a') + 26;
    '0'..'9': Result := code - BYTE('0') + 52;
    '+': Result := 62;
    '/': Result := 63;
    else Result := 0; // �e=�f�̏ꍇ���e0�f��Ԃ�
    end;
  end;

  function doNbyte: Integer;
  var
    I, N: Integer;
    Value: DWORD;
  begin
    // �p�f�B���O�����e=�f�̗L���𒲂ׂ�
    N := 3; // �f�R�[�h��̃o�C�g����N�ɃZ�b�g
    for I := 2 to 3 do
    begin
      if Src[I] = '=' then
      begin
        N := I - 1;
        break;
      end;
    end;
    // �S�������f�R�[�h����
    value := 0;
    for I := 0 to 3 do
    begin
      // �P�������U�r�b�g�ɕϊ��~�S��
      Value := Value shl 6;
      Inc(Value, decode(PBYTE(Src)^));
      Inc(Integer(Src));
    end;
    // �o�C�g�I�[�_�[���C���iKylix�ł͕s�v�̂͂��j
    Value := exchange_0_2(Value);
    // �f�R�[�h�����f�[�^�̏�������
    Result := Stream.Write(Value, N);
  end;

begin
  Result := 0;
  Src := PChar(Text);
  // �S�������f�R�[�h
  for I := 0 to (Length(Text) div 4) - 1 do
    // �������񂾃o�C�g����Result�ɃJ�E���g����
    Inc(Result, doNbyte);
end;

end.

