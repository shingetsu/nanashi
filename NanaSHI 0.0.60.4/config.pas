(*
 0.0.0 20040509 Perlからの移植開始、Perlが難しくすすまない。
 0.0.1 20040515 正規表現を加える
 0.0.2 20040521 Perlをもう一度解析やりなおし。
 0.0.3 20040605 基本的な通信が可能となる。(httpd.pl)
 0.0.4 20040621 server.cgi（90%), client.cgi(70%)
 0.0.5 20040622 get|headの終端がCRLFになっていた --> LF
 0.0.6 20040624 gateway.cgiの組み込み開始
 0.0.7 20040627 apolloを組み込む。僕のスレッド表示にバグがある。
 0.0.8 20040628 apolloをdelphi5でコンパイルする為、ちょっとの間、未サポートとする。
 0.0.9 20040629 cache_pm.getRegion()の空データスタート時のバグ修正
 0.0.10 20040629 gateway_cgi.html_format()のurl処理のバグ修正。[[>>]]のバグ残す。
 0.0.10 20040629 KOL環境を、ちょっとの間、やめる。
 0.0.11 20040629 スレッド表示のバグを修正（すごく嬉しい）
 0.0.11 20040629 １バイト単位の処理をそのままにし、遅い状態で開発を続けることにする。
 0.0.12 20040630 (0.3.3互換) geteway_pm.pasのstr_encode(),
 0.0.12 20040630 (0.3.3互換) gateway_cgi.pasの/^searchのstr_encode()を削除,
 0.0.12 20040630 (0.3.3互換) gateway_cgi.pasのtradegw.cgiに対するロジックを削除
 0.0.12 20040630 (0.3.3互換) server_cgi.pasの"HEAD"に対するロジックを追加
 0.0.13 20040701 stat.txtへの書込み不具合を修正
 0.0.14 20040702 Note関連の移植開始。いまだに書込みは未サポート。
 0.0.14 20040702 へッダが連続着信する現象を確認。ヘッダ着信カウントを加える。
 0.0.15 20040703 Gateway_cgi.pasのprintNote()の移植完了。書込みは未サポート。
 0.0.16 20040703 WELCOMにEをつけてjoinを受け付けるようにした。
 0.0.16 20040703 gateway_cgi.pasのeditDialog()とeditForm()のテストをはじめる。
 0.0.17 20040704 node.txtにノードを重複する不具合を発見。（本家はすごい）
 0.0.17 20040704 list_ or thread_ 内の不正データへの対処を追加。
 0.0.18 20040706 NodeList_pm.pasのinit()にある/nodeプロトコルを修正。
 0.0.19 20040707 cache_pm.tellupdate()を実装する。
 0.0.20 20040708 cache_pm.getData()のバグ修正。
 0.0.21 20040709 cache_pm.telupdate()のfork()代替のThreadを実装を辞める。
 0.0.22 20040710 Noteの書込みルーチンの実装を始める。
 0.0.23 20040711 Crescentの/have/SJISをサポート
 0.0.24 20040714 ノートの書込み'^add/([0-9A-Za-z_]+)$'が書き込めるようになる。
 0.0.25 20040716 md5digest()がバイナリをそのままNoteにセットしていた（酷いバグ）
 0.0.26 20040716 touch()から0サイズのsearch()関連の不具合を修正。
 0.0.27 20040717 '^newelement/([0-9A-Za-z_]+)$'の実装開始
 0.0.28 20040718 gateway_pm.newElement()のバグ修正
 0.0.29 20040719 gateway_pm.addRecord()のCacheStat_pmを呼び出す不具合を修正。
 0.0.30 20040719 Noteの新規、追加、訂正、削除の運用テストを開始。
 0.0.31 20040722 CacheStat_pm.isOkFile()で扱うデータの整合性のチェック・・・
 0.0.32 20040722 CacheStat_pm.Cache_update(),Cache_pm.getRegion()のバグを修正
 0.0.33 20040724 CacheStat_pm.isOkRecord()をCache_pm.addData()に加える
 0.0.34 20040725 gateway_cgiのprintIndex(), printUpdate(), printChanges()を実装する
 0.0.35 20040725 talk()へわたす先頭のSCRIPT名を付け忘れるバグを修正
 0.0.36 20040727 Cache_pm.getRegion()、追加レコード取得ロジックの不具合修正
 0.0.37 20040727 readln()を改良し高速化した(バッファを１バイト処理から8Kバイトへ)
 0.0.38 20040728 主に化け防止の為isOKnode()を作成した。
 0.0.39 20040728 /searchを実装、この時点で、バグはあるだろうが、0.3.3は全て？移植した。
 0.0.40 20040729 投稿のバグを修正
 0.0.40 20040729 0.3.4の変更分を同様に行う
 0.0.41 20040730 0.4-beta1の変更分を同様に行う
 0.0.42 20040801 gateway_pm.pasのxdie()処理が化けるのでjaの場合、charset=UTF-8を追加
 0.0.42 20040801 gateway_pm.pasのxdie()で終了を維持する為、newElement()をboolean型とする。
 0.0.43 20040801 0.4-beta1移行からの目立つバグを修正
 0.0.43 20040801 削除レコード（本文空）表示をオプションにする
 0.0.43 20040801 message-XX.txt読み込みバグ修正
 0.0.43 20040801 default.css等が存在する/fileの最新情報を取得するロジック付加（将来やめるかも）
 0.0.43 20040801 /fileのguide.cgi,node.cgiの実装を開始（まだ動作しない）
 0.0.44 20040802 統計情報管理を追加
 0.0.45 20040803 CacheStat_pm.Cache_update()の日付設定のバグを修正、(ソート関連が不正のまま)
 0.0.46 20040804 printHeader()の不具合修正（0.4以前が残っていた）
 0.0.47 20040805 httpd_pl.pasのAccept-Language:処理にen,ja;q=0.5等のlangとプライオリティをサポート
 0.0.47 20040805 message_pm.pasのamessage()にstr_decode()処理を行っていなかった
 0.0.48 20040806 node_pm.pasの各コマンドで/server.cgiを固定していたが、node.txtのpathへ変更
 0.0.48 20040806 NodeList_pm.init()のping()の応答無しにremove(node)を加えた
 0.0.49 20040806 0.0.48の修正でjoin時に自分のパスで無く相手のパスを返すバグを作ってしまった。
 0.0.50 20040806 split()関数の個数指定は分割文字数(':')と 間違えていた(LINKのバグが直る)
 0.0.50 20040806 プログラム終了時に動作中スレッドが存在した場合は強制終了の確認を出すようにした。
 0.0.50 20040806 list_ のソート条件を修正（まだおかしい）
 0.0.51 20040807 gateway_pm.pasのCheckAdmin()が127.0.0.1をサポートしていなかった。
 0.0.52 20040808 表紙の「メニュー」のリンク先が/gateway.cgi/list になってた
 0.0.52 20040808 /gateway.cgi/thread/%52in%47%4Fch%E7%B7%8F%E5%90%88にアクセスすると/.cgi/threadへジャンプしていた。
 0.0.52 20040808 /+server.cgi等の存在しない？パスをnode.txtに書き込んでいた.
 0.0.52 20040808 gateway_pm.pasのpost()で不要なメンバをレコードに書いていた。
 0.0.52 20040808 プログラム終了時にclient.cgi動作等にメモリエラーがでる不具合が直せない・・・
 0.0.53 20040808 コンパイラ変更(D5-->D6)でレコード削除にLF+CRLF OR CRLF+LFになるバグがあった。
 0.0.54 20040809 Cache_pm.addData()のremove_stamp,remove_id処理を修正。(Signature_pm.pasはまだ不完全)
 0.0.55 20040810 0.0.54のバグへの対応。{target}が空であることが原因.リマークしたが良かったのか？
 0.0.56 20040810 gateway_pm.postDeleteMessage()の不具合発見.tellupdate()を呼んでいなかった。
 0.0.56 20040810 shinGETsu/0.4.1への対応作業を行う({target}の問題も調べる)
 0.0.56 20040810 タイムアウトを長くした。{target}はapollo組み込み後に行うこととする。リマークをやめる。
 0.0.57 20040811 ノード取得時の整合性チェックを強化し,ERRORLOGへ出力するよう変更
 0.0.57 20040811 server_cgi.pasの'^(get|head)\/([,,,辺りのlaststmp取得前にソートしていなかった.
 0.0.58 20040812 gateway_pm.pasのbracket_link()に"$1.cgi/"の文字連結が間違っていた
 0.0.58 20040812 バグなのか？プロトコル違いなのか？の区別用にVERSION CHECKオプションを追加
 0.0.58 20040812 ポートを変えることで2つ以上、起動できるようにした。
 0.0.58 20040812 起動時にpingall()を実行するように修正した。
 0.0.58 20040812 NodeManagerに/haveを送らないオプションを準備した。
 0.0.58 20040812 AgentCacheをList表示した
 0.0.59 20070819 デフォルトノードは./dat/default_node.txtの内容とした。
 0.0.59 20070819 Note記事内容が空で追加を押すと不正表示があった。
 0.0.60 20070829 Noteの履歴表示をサポート
 0.0.60.1 20040829 Shingetsu0.4.1 apolloの実装
 0.0.60.2 20040830 Shingetsu0.4.1 gateway_pm.checkSign()を移植
 0.0.60.3 20040918 タイムアウトを長めに変更
 0.0.60.4 20040918 Statusの浮動小数点をやめる（Delphiの浮動小数点はスレッドセーフじゃ？）


 *)

unit config;

interface

uses
  Classes, blcksock, winsock, Synautil, SysUtils, RegExpr;

const
  D_NONAGENT    = 'unknown';
  D_NODEMANAGER = 'NodeManager';

//D_CLIENTSLEEP = 2500;   //msec;
  D_CLIENTSLEEP = 1000;   //msec;
  D_SUBNAME     = '(NanaSHI 0.0.60.4)';
//D_SUBNAME     = '';

  D_VER         = '0.4.1';
  D_SOFTWARE    = 'shinGETsu/';
  D_VERSION1    = D_SOFTWARE + '0.1';

  D_PORT        = '9000';

  D_BIND        = '0.0.0.0';
//D_SVR_TIMEOUT = 180 * 1000;
//D_SVR_TIMEOUT =   5 * 1000;
  D_SVR_TIMEOUT = 120 * 1000;
//D_WGET_TIMEOUT = 2 * 1024;
  D_WGET_TIMEOUT = 30 * 1000;

  D_ADMINADDR   = '192.168.';
  D_LOCALIP     = '127';
  D_FILELIMIT   = 10;               //M byte.
  D_RETRYSEARCH = 5;
  D_JAPANESE_ID = 'ja';
  D_INDEX       = 'gateway.cgi';
  D_CGIDIR      = './cgi-bin';
  D_FILEDIR     = './file';
  D_DATADIR     = './dat';
  D_MOTD        = 'motd.txt';
  D_PATH        = '/server.cgi';
  D_LOCKWAIT    = 100;
  D_NODES       = 20;
  D_MAXLISTEN   = 5;
  D_OVER_FIELD  = 3;         //3以上の項目を表示（レコードを削除すると日付とIDの２つになる）

  D_DEFAULT_NODE= D_DATADIR + '/default_node.txt';
  D_NODELIST    = D_DATADIR + '/node.txt';
  D_NODELIST_A  = D_DATADIR + '/node_a.txt';
  D_NODELIST_B  = D_DATADIR + '/node_b.txt';

  D_CLIENT      = D_DATADIR + '/client.txt';
  D_LOCKFILE    = D_DATADIR + '/lock.txt';
  D_UPDATELIST  = D_DATADIR + '/update.txt';
  D_STATFILE    = D_DATADIR + '/stat.txt';
  D_SAVEUPDATE  = 1440;     // 24 * 60
  D_PINGFREE    = 10;
  D_INITFREC    = 25;
  D_SYNCFREC    = 60;
  D_SYNCAFETY   = 240;
  D_FRIENDADDR  = '.';
  D_CSS         = '/default.css';
  D_MENUFILE    = 'menu';
  D_ROOT        = '../';
  D_REDIRECT    = True;
  D_SEARCHDEPTH = 30;
  D_GOOGLE	= 'http://www.google.co.jp/search';

var
  mimeType : TStringList;
  nodeTable : TStringList;


  __initNode : TStringList;


//  __initNode : array[0.._N_Max] of string =
//  (


//    'shingetsu.s45.xrea.com:80/index.cgi'
//   ,'fuktommy.ddo.jp:8000/server.cgi'
//   ,'yanga.s51.xrea.com:80/shingetsu/node.xcg'


 // ,'prinprin.ath.cx:9000/server.cgi'
(*
    '192.168.1.50:8000/server.cgi'
   ,'192.168.1.50:9000/server.cgi'
   ,'192.168.1.157:8000/server.cgi'
*)
(*
    '192.168.99.34:8000/server.cgi'
   ,'192.168.99.35:8000/server.cgi'
   ,'192.168.99.36:8000/server.cgi'
*)

//  );


function DataPath(afile:string):string;
function DataPath2(afile:string):string;
function TempPath(afile:string):string;


implementation

const
  _I_Max1 = 34;    // count - 1
  _I_Max2 = 1;     // count - 1

  _I_suffix_buff : array[0.._I_Max1,0.._I_Max2] of string =
  (
    ('avi', 'video/x-msvideo'),
    ('bin', 'application/octet-stream'),
    ('bmp', 'image/bmp'),
    ('cpio','application/x-cpio'),
    ('css', 'text/css'),
    ('csv', 'text/comma-separated-values'),
    ('dvi', 'application/x-dvi'),
    ('gif', 'image/gif'),
    ('html','text/html'),
    ('ico', 'image/x-icon'),
    ('jar', 'application/x-java-archive'),
    ('jpg', 'image/jpeg'),
    ('lzh', 'application/x-lzh'),
    ('mid', 'audio/midi'),
    ('mov', 'video/quicktime'),
    ('mp3', 'audio/mpeg'),
    ('mpg', 'video/mpeg'),
    ('ogg', 'application/x-ogg'),
    ('pdf', 'application/pdf'),
    ('pgp', 'application/pgp-signature'),
    ('png', 'image/png'),
    ('ps',  'application/postscript'),
    ('ra',  'audio/x-realaudio'),
    ('rpm', 'application/x-redhat-package-manager'),
    ('swf', 'application/x-shockwave-flash'),
    ('tar', 'application/x-tar'),
    ('tex', 'application/x-tex'),
    ('tif', 'image/tiff'),
    ('txt', 'text/plain'),
    ('log', 'text/plain'),
    ('tgz', 'application/x-gtar'),
    ('wav', 'audio/x-wav'),
    ('xml', 'text/xml'),
    ('zip', 'application/zip'),
    ('rar', 'application/rar')
  );



//----------------------
// data full path.
//
function DataPath(afile:string):string;
begin
  Result := D_DATADIR + '/' + afile + '.dat';
end;

function DataPath2(afile:string):string;
begin
  Result := D_DATADIR + '/' + afile;
end;

function TempPath(afile:string):string;
begin
  Result := D_DATADIR + '/' + afile + '.dat.tmp';
end;



var
  _n:integer;

initialization
  //MITE TYPE-----------------------------
  mimeType := TStringList.Create;
  for _n := 0 to _I_Max1 do begin
    mimeType.Values[_I_suffix_buff[_n,0]] := _I_suffix_buff[_n,1];
  end;

  //DEFAULT NODE TABLE---------------------
  __initNode := TStringList.Create;
  if FileExists(D_DEFAULT_NODE) then begin
    __initNode.LoadFromFile(D_DEFAULT_NODE);
  end;

  //NODE TABLE-----------------------------
  nodeTable := TStringList.Create;
  if not FileExists(D_NODELIST) then begin
    //node.txtが存在しない
    if FileExists(D_DEFAULT_NODE) then begin
      //default_node.txtが存在した
      nodeTable.LoadFromFile(D_DEFAULT_NODE);
      nodeTable.SaveToFile(D_NODELIST);
    end else begin
      //default_node.txtが存在しない
      for _n := 0 to __initNode.Count-1 do begin
        nodeTable.Add(__initNode[_n]);       //###$$$
      end;
      nodeTable.SaveToFile(D_NODELIST);
    end;
  end;
  //node.txtの読み込み
  nodeTable.loadFromFile(D_NODELIST);

finalization
  __initNode.free;
  nodeTable.free;
  mimeType.free;

end.
