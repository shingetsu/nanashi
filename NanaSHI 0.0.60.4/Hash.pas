unit Hash;

interface


uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls;


type
  THash = class;

  THashRec = record
    name  : PChar;
    value : PChar;
  end;
  THashRecs = array of THashRec;


  THash = class(TObject)
  private
    FValues : THashRecs;

    function  GetCount:integer;
    function  GetValues(const name: string): String;
    procedure SetValues(const name: string; const Value: String);
    function  IndexOfName(const Name: string): Integer;
    function  IndexOfName2(const Name: string): Integer;

  public
    constructor create;
    destructor  Destroy; override;
    procedure clear;
    procedure delete(const name:string);
    procedure SetHash(name:string; ha:THash);
    procedure GetHash(name:string; var ha: THash);
    property Values[const name:string]:String read GetValues write SetValues; default;
    property Count : integer read GetCount;
  end;


implementation


{ THash }


//---------------------------------------------------
//
constructor THash.create;
begin
  inherited;
end;


//---------------------------------------------------
//
destructor THash.Destroy;
var
  n:integer;
begin
  inherited;
  for n := GetCount - 1 downto 0 do begin
    FreeMem(FValues[n].name);   //���O�̊J��
    FreeMem(FValues[n].value);  //�l�̊J��
  end;
end;

//---------------------------------------------------
//
function THash.GetCount:integer;
begin
  Result := length(FValues);
end;

//---------------------------------------------------
//
procedure THash.clear;
var
  n:integer;
begin
  for n := GetCount - 1 downto 0 do begin
    delete(FValues[n].name);   //���O�̏���
    delete(FValues[n].value);  //�l�̏���
  end;
end;

//---------------------------------------------------
//
procedure THash.GetHash(name:string; var ha: THash);
begin
  ha.clear;

end;

//---------------------------------------------------
//
procedure THash.SetHash(name:string; ha: THash);
var
  n,i:integer;
begin

  n := IndexOfName(Name);
  if(n = -1) then begin
    if (IndexOfName2(Name) <> - 1) then
      exit;  //���ɉ��ʂ��o�^�ς�
  end;
  delete(Name);
  for i := 0 to ha.count-1 do begin
    SetValues(name + String(ha.FValues[i].name), String(ha.FValues[i].Value) );
  end;

end;


//-----------------------------------------------
//
function THash.IndexOfName(const Name: string): Integer;
var
  s: string;
begin
  for Result := 0 to GetCount - 1 do begin
    s := FValues[Result].name;
    if AnsiSameStr(s,name) then
      exit;
  end;
  Result := -1;
end;


//---------------------------------------------------
//
function THash.IndexOfName2(const Name: string): Integer;
var
  s: string; i:integer;
begin
  i := length(name);
  for Result := 0 to GetCount-1 do begin
    s := copy(FValues[Result].name, 1, i);
    if AnsiSameStr(s,name) then
      exit;
  end;
  Result := -1;
end;


//---------------------------------------------------
//
function THash.GetValues(const name: string): String;
var
  n:integer;
begin
  Result := '';
  n := IndexOfName(name);
  if (n <> -1) then begin
    Result := FValues[n].value;
  end;
end;

//---------------------------------------------------
//
procedure THash.SetValues(const name: string; const Value: String);
var
  n:integer;
begin
  n := IndexOfName(name);
  if (n = -1) then begin             //���o�^
    n := GetCount();
    SetLength(FValues,n+1);
    GetMem(FValues[n].name,length(name)+1);          //���O�̊m��
    StrPLCopy(FValues[n].name, name, length(name));  //���O�̃Z�b�g
    GetMem(FValues[n].value,length(value)+1);        //�l�̊m��
  end else begin                     //�o�^��
    FreeMem(FValues[n].value);                       //�l�̊J���i���T�C�Y�j
    GetMem(FValues[n].value,length(value)+1);        //�l�̊m�ہi�V�T�C�Y�j
  end;
  StrPLCopy(FValues[n].value, value, length(value)); //�l�̃Z�b�g
end;

//---------------------------------------------------
//
procedure THash.delete(const name: string);
var
  n,c:integer;
begin
  n := IndexOfName(Name);
  if (n = -1) then exit;
  FreeMem(Fvalues[n].name);   //���O�̊J��
  FreeMem(Fvalues[n].value);  //�l�̊J��

  Finalize(FValues[n]);       //�z��̏k��
  C := GetCount;
  if n < c then
    System.Move(FValues[n+1], FValues[n],(c - n) * SizeOf(THashRec));
  Dec(c);
  SetLength(FValues, c);
end;



end.
