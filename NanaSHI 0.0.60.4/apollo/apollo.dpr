program apollo;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  trip in 'trip.pas',
  RSAbase in 'RSAbase.pas',
  factor in 'factor.pas',
  longint in 'longint.pas',
  MD5 in 'MD5.pas',
  RC4 in 'RC4.pas',
  Base64 in 'Base64.pas';

var
  parm: String;
  KeyGenerator: String;
  PublicKeyStr: String;
  SecretKeyStr: String;
  SignTarget: String;
  SignatureStr: String;
  SuspectSignature: String;
  KeyStr: String;
  ShortKeyStr: String;


procedure usage;
begin
    Writeln('apollo (win console) - ver 0.3.1(2004/06/09)');
    Writeln(' trip ver 0.3 2004/03/20 - apollo512-2(2004/02/16)');
    Writeln('                         & apollo1024-3(2004/03/20) not used');
    Writeln('                         & crypt-0.0(2004/03/24) not used');
    Writeln;
    Writeln(' -g  Generate KeyPair');
    Writeln('      input(stdin)  : KeyGenerator');
    Writeln('      output(stdout): PublicKeyStr');
    Writeln('                      SecretKeyStr');
    Writeln(' -s  Sign Message');
    Writeln('      input(stdin)  : SignTarget');
    Writeln('                      PublicKeyStr');
    Writeln('                      SecretKeyStr');
    Writeln('      output(stdout): SignatureStr');
    Writeln(' -v  Verify Signature');
    Writeln('      input(stdin)  : SignTarget');
    Writeln('                      SuspectSignature');
    Writeln('                      PublicKeyStr');
    Writeln('      output(stdout): True / False');
    Writeln(' -c  Cut KeyStr to 11words');
    Writeln('      input(stdin)  : KeyStr');
    Writeln('      output(stdout): ShortKeyStr');
end;

begin
    if ParamCount < 1 then
    begin
      usage;
      Exit;
    end;
    parm := ParamStr(1);
    if (parm[1] <> '-') and (parm[1] <> '/') then
    begin
      usage;
      Exit;
    end;

    case parm[2] of
      'g','G':
        begin
          Readln(KeyGenerator);
          RSAkeycreate512(PublicKeyStr,SecretKeyStr,KeyGenerator);
          Write(PublicKeyStr);
          Write(#$0a);
          Write(SecretKeyStr);
          Write(#$0a);
        end;
      's','S':
        begin
          Readln(SignTarget);
          Readln(PublicKeyStr);
          Readln(SecretKeyStr);
          SignatureStr := RSAsign(SignTarget,PublicKeyStr,SecretKeyStr);
          Write(SignatureStr);
          Write(#$0a);
        end;
      'v','V':
        begin
          Readln(SignTarget);
          Readln(SuspectSignature);
          Readln(PublicKeyStr);
          if RSAverify(SignTarget,SuspectSignature,PublicKeyStr) then
            Write('True')
          else
            Write('False');
          Write(#$0a);
        end;
      'c','C':
        begin
          Readln(KeyStr);
          ShortKeyStr := triphash(KeyStr);
          Write(ShortKeyStr);
          Write(#$0a);
        end;
      else
        usage;
    end;
end.
