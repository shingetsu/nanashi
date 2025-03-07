unit RSAbase;
{
*********************************************************

RSA���J���Í��x�[�X���[�`��

Delphi�� RSAbase.pas
gcc+gmp�� RSAbase.h/RSAbase.c

  programmed by "replaceable anonymous"
*********************************************************

Delphi�ŉ��ŗ���
  ver 0.0.0 2004/02/11
    �Ƃ肠�����ł���

  ver 0.1.0 2004/02/15
    q-1�̈�����e���܂܂�Ă���Ɩ������[�v�ɂȂ�o�O���C��
    ���s����p,q�������C���N�������g����悤��

  ver 0.2.0 2004/02/16
    �֐������ɏ��������B
    gcc+gmp�łƂ��낦��

/////////////////////////////////////////////////////////

}

interface

uses
  SysUtils,
  longint;

const
  RSAe = $10001; {RSA�Ō��J�p�̎w��}
  RSACreateGiveup = 300; {�\�����s�܂ł̎��s��}

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
//  �^����ꂽ�����_����2��������RSA�ɓK������n,d���\������
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
      primize(q); {q����+�����Ɉ�ԋ߂��f����}
      q1 := q;
      aldec(@q1,1); {q1= q-1}
      primize(p); {p����+�����Ɉ�ԋ߂��f����}
      p1q1 := p;
      aldec(@p1q1,1);
      lmulp(@p1q1,@q1); {p1q1 = (p-1)(q-1)}
      lgcd(@g,p1q1,e);  {(p-1)(q-1)��e���݂��ɑf�łȂ��Ƌt���͑��݂��Ȃ�}
      if lcmp(@g,@n1) <> 0 then
      begin
        alinc(@q,2);
        alinc(@p,2);
        Continue;
      end;
      linv(@key.d,e,p1q1); {d��e�̖@(p-1)(q-1)�ł̋t��}
      lmulpb(@key.n,@p,@q); {�����An=pq}
      lset(@test1,7743); {�{���ɖ߂��Ă��邩����}
      test2 := test1;
      lpwrmod(@test2,@key.d,@key.n);
      lpwrmod(@test2,@e,@key.n);
      if lcmp(@test1,@test2) = 0 then {�����e�X�g�Ƀp�X������I��}
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
