{==============================================================================|
| Project : Ararat Synapse                                       | 002.000.001 |
|==============================================================================|
| Content: Socket Independent Platform Layer - Linux definition include        |
|==============================================================================|
| Copyright (c)1999-2003, Lukas Gebauer                                        |
| All rights reserved.                                                         |
|                                                                              |
| Redistribution and use in source and binary forms, with or without           |
| modification, are permitted provided that the following conditions are met:  |
|                                                                              |
| Redistributions of source code must retain the above copyright notice, this  |
| list of conditions and the following disclaimer.                             |
|                                                                              |
| Redistributions in binary form must reproduce the above copyright notice,    |
| this list of conditions and the following disclaimer in the documentation    |
| and/or other materials provided with the distribution.                       |
|                                                                              |
| Neither the name of Lukas Gebauer nor the names of its contributors may      |
| be used to endorse or promote products derived from this software without    |
| specific prior written permission.                                           |
|                                                                              |
| THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"  |
| AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE    |
| IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE   |
| ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR  |
| ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL       |
| DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR   |
| SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER   |
| CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT           |
| LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY    |
| OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH  |
| DAMAGE.                                                                      |
|==============================================================================|
| The Initial Developer of the Original Code is Lukas Gebauer (Czech Republic).|
| Portions created by Lukas Gebauer are Copyright (c)2003.                     |
| All Rights Reserved.                                                         |
|==============================================================================|
| Contributor(s):                                                              |
|==============================================================================|
| History: see HISTORY.HTM from distribution package                           |
|          (Found at URL: http://www.ararat.cz/synapse/)                       |
|==============================================================================}

{$IFDEF LINUX}

//{$DEFINE FORCEOLDAPI}
{Note about define FORCEOLDAPI:
If you activate this compiler directive, then is allways used old socket API
for name resolution. If you leave this directive inactive, then the new API
is used, when running system allows it.

For IPv6 support you must have new API!
}

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$H+}
interface

uses
  SyncObjs, SysUtils,
  {$IFDEF FPC}
  synafpc,
  {$ENDIF}
  Libc;

function InitSocketInterface(stack: string): Boolean;
function DestroySocketInterface: Boolean;

const
  WinsockLevel = $0202;
  
type
  u_char = Char;
  u_short = Word;
  u_int = Integer;
  u_long = Longint;
  pu_long = ^u_long;
  pu_short = ^u_short;
  TSocket = u_int;

  TMemory = pointer;


const
  DLLStackName = 'libc.so.6';

type
  DWORD = Integer;
  __fd_mask = LongWord;
const
  __FD_SETSIZE    = 1024;
  __NFDBITS       = 8 * sizeof(__fd_mask);
type
  __fd_set = {packed} record
    fds_bits: packed array[0..(__FD_SETSIZE div __NFDBITS)-1] of __fd_mask;
  end;
  TFDSet = __fd_set;
  PFDSet = ^TFDSet;

const
  FIONREAD        = $541B;
  FIONBIO         = $5421;
  FIOASYNC        = $5452;

type
  PTimeVal = ^TTimeVal;
  TTimeVal = packed record
    tv_sec: Longint;
    tv_usec: Longint;
  end;

const
  IPPROTO_IP     =   0;		{ Dummy					}
  IPPROTO_ICMP   =   1;		{ Internet Control Message Protocol }
  IPPROTO_IGMP   =   2;		{ Internet Group Management Protocol}
  IPPROTO_TCP    =   6;		{ TCP           			}
  IPPROTO_UDP    =   17;	{ User Datagram Protocol		}
  IPPROTO_IPV6   =   41;
  IPPROTO_ICMPV6 =   58;

  IPPROTO_RAW    =   255;
  IPPROTO_MAX    =   256;

type
  SunB = packed record
    s_b1, s_b2, s_b3, s_b4: u_char;
  end;

  SunW = packed record
    s_w1, s_w2: u_short;
  end;

  PInAddr = ^TInAddr;
  TInAddr = packed record
    case integer of
      0: (S_un_b: SunB);
      1: (S_un_w: SunW);
      2: (S_addr: u_long);
  end;

  PSockAddrIn = ^TSockAddrIn;
  TSockAddrIn = packed record
    case Integer of
      0: (sin_family: u_short;
          sin_port: u_short;
          sin_addr: TInAddr;
          sin_zero: array[0..7] of Char);
      1: (sa_family: u_short;
          sa_data: array[0..13] of Char)
  end;

  TIP_mreq =  record
    imr_multiaddr: TInAddr;     { IP multicast address of group }
    imr_interface: TInAddr;     { local IP address of interface }
  end;

  SunB6 = packed record
    s_b1,  s_b2,  s_b3,  s_b4,
    s_b5,  s_b6,  s_b7,  s_b8,
    s_b9,  s_b10, s_b11, s_b12,
    s_b13, s_b14, s_b15, s_b16: u_char;
  end;

  SunW6 = packed record
    s_w1, s_w2, s_w3, s_w4,
    s_w5, s_w6, s_w7, s_w8: u_short;
  end;

  SunDW6 = packed record
    s_dw1, s_dw2, s_dw3, s_dw4: longint;
  end;

  S6_Bytes   = SunB6;
  S6_Words   = SunW6;
  S6_DWords  = SunDW6;
  S6_Addr    = SunB6;

  PInAddr6 = ^TInAddr6;
  TInAddr6 = packed record
    case integer of
      0: (S_un_b:  SunB6);
      1: (S_un_w:  SunW6);
      2: (S_un_dw: SunDW6);
  end;

  PSockAddrIn6 = ^TSockAddrIn6;
  TSockAddrIn6 = packed record
		sin6_family:   u_short;     // AF_INET6
		sin6_port:     u_short;     // Transport level port number
		sin6_flowinfo: u_long;	    // IPv6 flow information
		sin6_addr:     TInAddr6;    // IPv6 address
		sin6_scope_id: u_long;      // Scope Id: IF number for link-local
                                //           SITE id for site-local
  end;

  TIPv6_mreq = record
    ipv6mr_multiaddr: TInAddr6; // IPv6 multicast address.
    ipv6mr_interface: u_long;   // Interface index.
    padding: u_long;
  end;

  hostent = record
    h_name: PChar;
    h_aliases: PPChar;
    h_addrtype: Integer;
    h_length: Cardinal;
    case Byte of
      0: (h_addr_list: PPChar);
      1: (h_addr: PPChar);
  end;

  PNetEnt = ^TNetEnt;
  TNetEnt = record
    n_name: PChar;
    n_aliases: PPChar;
    n_addrtype: Integer;
    n_net: uint32_t;
  end;

  PServEnt = ^TServEnt;
  TServEnt = record
    s_name: PChar;
    s_aliases: PPChar;
    s_port: Integer;
    s_proto: PChar;
  end;

  PProtoEnt = ^TProtoEnt;
  TProtoEnt = record
    p_name: PChar;
    p_aliases: ^PChar;
    p_proto: u_short;
  end;

const
  INADDR_ANY       = $00000000;
  INADDR_LOOPBACK  = $7F000001;
  INADDR_BROADCAST = $FFFFFFFF;
  INADDR_NONE      = $FFFFFFFF;
  ADDR_ANY		 = INADDR_ANY;
  INVALID_SOCKET		= TSocket(NOT(0));
  SOCKET_ERROR			= -1;

Const
  IP_TOS             = 1;  { int; IP type of service and precedence.  }
  IP_TTL             = 2;  { int; IP time to live.  }
  IP_HDRINCL         = 3;  { int; Header is included with data.  }
  IP_OPTIONS         = 4;  { ip_opts; IP per-packet options.  }
  IP_ROUTER_ALERT    = 5;  { bool }
  IP_RECVOPTS        = 6;  { bool }
  IP_RETOPTS         = 7;  { bool }
  IP_PKTINFO         = 8;  { bool }
  IP_PKTOPTIONS      = 9;
  IP_PMTUDISC        = 10; { obsolete name? }
  IP_MTU_DISCOVER    = 10; { int; see below }
  IP_RECVERR         = 11; { bool }
  IP_RECVTTL         = 12; { bool }
  IP_RECVTOS         = 13; { bool }
  IP_MULTICAST_IF    = 32; { in_addr; set/get IP multicast i/f }
  IP_MULTICAST_TTL   = 33; { u_char; set/get IP multicast ttl }
  IP_MULTICAST_LOOP  = 34; { i_char; set/get IP multicast loopback }
  IP_ADD_MEMBERSHIP  = 35; { ip_mreq; add an IP group membership }
  IP_DROP_MEMBERSHIP = 36; { ip_mreq; drop an IP group membership }

  SOL_SOCKET    = 1;

  SO_DEBUG      = 1;
  SO_REUSEADDR  = 2;
  SO_TYPE       = 3;
  SO_ERROR      = 4;
  SO_DONTROUTE  = 5;
  SO_BROADCAST  = 6;
  SO_SNDBUF     = 7;
  SO_RCVBUF     = 8;
  SO_KEEPALIVE  = 9;
  SO_OOBINLINE  = 10;
  SO_NO_CHECK   = 11;
  SO_PRIORITY   = 12;
  SO_LINGER     = 13;
  SO_BSDCOMPAT  = 14;
  SO_REUSEPORT  = 15;
  SO_PASSCRED   = 16;
  SO_PEERCRED   = 17;
  SO_RCVLOWAT   = 18;
  SO_SNDLOWAT   = 19;
  SO_RCVTIMEO   = 20;
  SO_SNDTIMEO   = 21;
{ Security levels - as per NRL IPv6 - don't actually do anything }
  SO_SECURITY_AUTHENTICATION       = 22;
  SO_SECURITY_ENCRYPTION_TRANSPORT = 23;
  SO_SECURITY_ENCRYPTION_NETWORK   = 24;
  SO_BINDTODEVICE                  = 25;
{ Socket filtering }
  SO_ATTACH_FILTER = 26;
  SO_DETACH_FILTER = 27;

  SOMAXCONN       = 128;

  IPV6_UNICAST_HOPS     = 16;
  IPV6_MULTICAST_IF     = 17;
  IPV6_MULTICAST_HOPS   = 18;
  IPV6_MULTICAST_LOOP   = 19;
  IPV6_JOIN_GROUP       = 20;
  IPV6_LEAVE_GROUP      = 21;

  MSG_NOSIGNAL  = $4000;                // Do not generate SIGPIPE.

  // getnameinfo constants
  NI_MAXHOST	   = 1025;
  NI_MAXSERV	   = 32;
  NI_NOFQDN 	   = $4;
  NI_NUMERICHOST = $1;
  NI_NAMEREQD	   = $8;
  NI_NUMERICSERV = $2;
  NI_DGRAM       = $10;

const
  SOCK_STREAM     = 1;               { stream socket }
  SOCK_DGRAM      = 2;               { datagram socket }
  SOCK_RAW        = 3;               { raw-protocol interface }
  SOCK_RDM        = 4;               { reliably-delivered message }
  SOCK_SEQPACKET  = 5;               { sequenced packet stream }

{ TCP options. }
  TCP_NODELAY     = $0001;

{ Address families. }

  AF_UNSPEC       = 0;               { unspecified }
  AF_INET         = 2;               { internetwork: UDP, TCP, etc. }
  AF_INET6        = 10;              { Internetwork Version 6 }
  AF_MAX          = 24;

{ Protocol families, same as address families for now. }
  PF_UNSPEC       = AF_UNSPEC;
  PF_INET         = AF_INET;
  PF_INET6        = AF_INET6;
  PF_MAX          = AF_MAX;

type
  { Structure used by kernel to store most addresses. }
  PSockAddr = ^TSockAddr;
  TSockAddr = TSockAddrIn;

  { Structure used by kernel to pass protocol information in raw sockets. }
  PSockProto = ^TSockProto;
  TSockProto = packed record
    sp_family: u_short;
    sp_protocol: u_short;
  end;

type
  PAddrInfo = ^TAddrInfo;
  TAddrInfo = record
                ai_flags: integer;    // AI_PASSIVE, AI_CANONNAME, AI_NUMERICHOST.
                ai_family: integer;   // PF_xxx.
                ai_socktype: integer; // SOCK_xxx.
                ai_protocol: integer; // 0 or IPPROTO_xxx for IPv4 and IPv6.
                ai_addrlen: u_int;    // Length of ai_addr.
                ai_addr: PSockAddr;   // Binary address.
                ai_canonname: PChar;  // Canonical name for nodename.
                ai_next: PAddrInfo;     // Next structure in linked list.
              end;

const
  // Flags used in "hints" argument to getaddrinfo().
  AI_PASSIVE     = $1;  // Socket address will be used in bind() call.
  AI_CANONNAME   = $2;  // Return canonical name in first ai_canonname.
  AI_NUMERICHOST = $4;  // Nodename must be a numeric address string.

type
{ Structure used for manipulating linger option. }
  PLinger = ^TLinger;
  TLinger = packed record
    l_onoff: u_short;
    l_linger: u_short;
  end;

const

  MSG_OOB       = $01;                  // Process out-of-band data.
  MSG_PEEK      = $02;                  // Peek at incoming messages.

const
  WSAEINTR = EINTR;
  WSAEBADF = EBADF;
  WSAEACCES = EACCES;
  WSAEFAULT = EFAULT;
  WSAEINVAL = EINVAL;
  WSAEMFILE = EMFILE;
  WSAEWOULDBLOCK = EWOULDBLOCK;
  WSAEINPROGRESS = EINPROGRESS;
  WSAEALREADY = EALREADY;
  WSAENOTSOCK = ENOTSOCK;
  WSAEDESTADDRREQ = EDESTADDRREQ;
  WSAEMSGSIZE = EMSGSIZE;
  WSAEPROTOTYPE = EPROTOTYPE;
  WSAENOPROTOOPT = ENOPROTOOPT;
  WSAEPROTONOSUPPORT = EPROTONOSUPPORT;
  WSAESOCKTNOSUPPORT = ESOCKTNOSUPPORT;
  WSAEOPNOTSUPP = EOPNOTSUPP;
  WSAEPFNOSUPPORT = EPFNOSUPPORT;
  WSAEAFNOSUPPORT = EAFNOSUPPORT;
  WSAEADDRINUSE = EADDRINUSE;
  WSAEADDRNOTAVAIL = EADDRNOTAVAIL;
  WSAENETDOWN = ENETDOWN;
  WSAENETUNREACH = ENETUNREACH;
  WSAENETRESET = ENETRESET;
  WSAECONNABORTED = ECONNABORTED;
  WSAECONNRESET = ECONNRESET;
  WSAENOBUFS = ENOBUFS;
  WSAEISCONN = EISCONN;
  WSAENOTCONN = ENOTCONN;
  WSAESHUTDOWN = ESHUTDOWN;
  WSAETOOMANYREFS = ETOOMANYREFS;
  WSAETIMEDOUT = ETIMEDOUT;
  WSAECONNREFUSED = ECONNREFUSED;
  WSAELOOP = ELOOP;
  WSAENAMETOOLONG = ENAMETOOLONG;
  WSAEHOSTDOWN = EHOSTDOWN;
  WSAEHOSTUNREACH = EHOSTUNREACH;
  WSAENOTEMPTY = ENOTEMPTY;
  WSAEPROCLIM = -1;
  WSAEUSERS = EUSERS;
  WSAEDQUOT = EDQUOT;
  WSAESTALE = ESTALE;
  WSAEREMOTE = EREMOTE;
  WSASYSNOTREADY = -2;
  WSAVERNOTSUPPORTED = -3;
  WSANOTINITIALISED = -4;
  WSAEDISCON = -5;
  WSAHOST_NOT_FOUND = HOST_NOT_FOUND;
  WSATRY_AGAIN = TRY_AGAIN;
  WSANO_RECOVERY = NO_RECOVERY;
  WSANO_DATA = -6;

  EAI_BADFLAGS    = -1;   { Invalid value for `ai_flags' field.  }
  EAI_NONAME      = -2;   { NAME or SERVICE is unknown.  }
  EAI_AGAIN       = -3;   { Temporary failure in name resolution.  }
  EAI_FAIL        = -4;   { Non-recoverable failure in name res.  }
  EAI_NODATA      = -5;   { No address associated with NAME.  }
  EAI_FAMILY      = -6;   { `ai_family' not supported.  }
  EAI_SOCKTYPE    = -7;   { `ai_socktype' not supported.  }
  EAI_SERVICE     = -8;   { SERVICE not supported for `ai_socktype'.  }
  EAI_ADDRFAMILY  = -9;   { Address family for NAME not supported.  }
  EAI_MEMORY      = -10;  { Memory allocation failure.  }
  EAI_SYSTEM      = -11;  { System error returned in `errno'.  }

const
  WSADESCRIPTION_LEN     =   256;
  WSASYS_STATUS_LEN      =   128;
type
  PWSAData = ^TWSAData;
  TWSAData = packed record
    wVersion: Word;
    wHighVersion: Word;
    szDescription: array[0..WSADESCRIPTION_LEN] of Char;
    szSystemStatus: array[0..WSASYS_STATUS_LEN] of Char;
    iMaxSockets: Word;
    iMaxUdpDg: Word;
    lpVendorInfo: PChar;
  end;

  function IN6_IS_ADDR_UNSPECIFIED(const a: PInAddr6): boolean;
  function IN6_IS_ADDR_LOOPBACK(const a: PInAddr6): boolean;
  function IN6_IS_ADDR_LINKLOCAL(const a: PInAddr6): boolean;
  function IN6_IS_ADDR_SITELOCAL(const a: PInAddr6): boolean;
  function IN6_IS_ADDR_MULTICAST(const a: PInAddr6): boolean;
  function IN6_ADDR_EQUAL(const a: PInAddr6; const b: PInAddr6):boolean;
  procedure SET_IN6_IF_ADDR_ANY (const a: PInAddr6);
  procedure SET_LOOPBACK_ADDR6 (const a: PInAddr6);
var
  in6addr_any, in6addr_loopback : TInAddr6;

procedure FD_CLR(Socket: TSocket; var FDSet: TFDSet);
function FD_ISSET(Socket: TSocket; var FDSet: TFDSet): Boolean;
procedure FD_SET(Socket: TSocket; var FDSet: TFDSet);
procedure FD_ZERO(var FDSet: TFDSet);

{=============================================================================}

type
  TWSAStartup = function(wVersionRequired: Word; var WSData: TWSAData): Integer;
    cdecl;
  TWSACleanup = function: Integer;
    cdecl;
  TWSAGetLastError = function: Integer;
    cdecl;
  TGetServByName = function(name, proto: PChar): PServEnt;
    cdecl;
  TGetServByPort = function(port: Integer; proto: PChar): PServEnt;
    cdecl;
  TGetProtoByName = function(name: PChar): PProtoEnt;
    cdecl;
  TGetProtoByNumber = function(proto: Integer): PProtoEnt;
    cdecl;
  TGetHostByName = function(name: PChar): PHostEnt;
    cdecl;
  TGetHostByAddr = function(addr: Pointer; len, Struc: Integer): PHostEnt;
    cdecl;
  TGetHostName = function(name: PChar; len: Integer): Integer;
    cdecl;
  TShutdown = function(s: TSocket; how: Integer): Integer;
    cdecl;
  TSetSockOpt = function(s: TSocket; level, optname: Integer; optval: PChar;
    optlen: Integer): Integer;
    cdecl;
  TGetSockOpt = function(s: TSocket; level, optname: Integer; optval: PChar;
    var optlen: Integer): Integer;
    cdecl;
  TSendTo = function(s: TSocket; const Buf; len, flags: Integer; addrto: PSockAddr;
    tolen: Integer): Integer;
    cdecl;
  TSend = function(s: TSocket; const Buf; len, flags: Integer): Integer;
    cdecl;
  TRecv = function(s: TSocket; var Buf; len, flags: Integer): Integer;
    cdecl;
  TRecvFrom = function(s: TSocket; var Buf; len, flags: Integer; from: PSockAddr;
    var fromlen: Integer): Integer;
    cdecl;
  Tntohs = function(netshort: u_short): u_short;
    cdecl;
  Tntohl = function(netlong: u_long): u_long;
    cdecl;
  TListen = function(s: TSocket; backlog: Integer): Integer;
    cdecl;
  TIoctlSocket = function(s: TSocket; cmd: DWORD; var arg: u_long): Integer;
    cdecl;
  TInet_ntoa = function(inaddr: TInAddr): PChar;
    cdecl;
  TInet_addr = function(cp: PChar): u_long;
    cdecl;
  Thtons = function(hostshort: u_short): u_short;
    cdecl;
  Thtonl = function(hostlong: u_long): u_long;
    cdecl;
  TGetSockName = function(s: TSocket; name: PSockAddr; var namelen: Integer): Integer;
    cdecl;
  TGetPeerName = function(s: TSocket; name: PSockAddr; var namelen: Integer): Integer;
    cdecl;
  TConnect = function(s: TSocket; name: PSockAddr; namelen: Integer): Integer;
    cdecl;
  TCloseSocket = function(s: TSocket): Integer;
    cdecl;
  TBind = function(s: TSocket; addr: PSockAddr; namelen: Integer): Integer;
    cdecl;
  TAccept = function(s: TSocket; addr: PSockAddr; var addrlen: Integer): TSocket;
    cdecl;
  TTSocket = function(af, Struc, Protocol: Integer): TSocket;
    cdecl;
  TSelect = function(nfds: Integer; readfds, writefds, exceptfds: PFDSet;
    timeout: PTimeVal): Longint;
    cdecl;

  TGetAddrInfo = function(NodeName: PChar; ServName: PChar; Hints: PAddrInfo;
    var Addrinfo: PAddrInfo): integer;
    cdecl;
  TFreeAddrInfo = procedure(ai: PAddrInfo);
    cdecl;
  TGetNameInfo = function( addr: PSockAddr; namelen: Integer; host: PChar;
    hostlen: DWORD; serv: PChar; servlen: DWORD; flags: integer): integer;
    cdecl;

var
  WSAStartup: TWSAStartup = nil;
  WSACleanup: TWSACleanup = nil;
  WSAGetLastError: TWSAGetLastError = nil;
  GetServByName: TGetServByName = nil;
  GetServByPort: TGetServByPort = nil;
  GetProtoByName: TGetProtoByName = nil;
  GetProtoByNumber: TGetProtoByNumber = nil;
  GetHostByName: TGetHostByName = nil;
  GetHostByAddr: TGetHostByAddr = nil;
  ssGetHostName: TGetHostName = nil;
  Shutdown: TShutdown = nil;
  SetSockOpt: TSetSockOpt = nil;
  GetSockOpt: TGetSockOpt = nil;
  ssSendTo: TSendTo = nil;
  ssSend: TSend = nil;
  ssRecv: TRecv = nil;
  ssRecvFrom: TRecvFrom = nil;
  ntohs: Tntohs = nil;
  ntohl: Tntohl = nil;
  Listen: TListen = nil;
  IoctlSocket: TIoctlSocket = nil;
  Inet_ntoa: TInet_ntoa = nil;
  Inet_addr: TInet_addr = nil;
  htons: Thtons = nil;
  htonl: Thtonl = nil;
  ssGetSockName: TGetSockName = nil;
  ssGetPeerName: TGetPeerName = nil;
  ssConnect: TConnect = nil;
  CloseSocket: TCloseSocket = nil;
  ssBind: TBind = nil;
  ssAccept: TAccept = nil;
  Socket: TTSocket = nil;
  Select: TSelect = nil;

  GetAddrInfo: TGetAddrInfo = nil;
  FreeAddrInfo: TFreeAddrInfo = nil;
  GetNameInfo: TGetNameInfo = nil;

function LSWSAStartup(wVersionRequired: Word; var WSData: TWSAData): Integer; cdecl;
function LSWSACleanup: Integer; cdecl;
function LSWSAGetLastError: Integer; cdecl;

var
  SynSockCS: SyncObjs.TCriticalSection;
  SockEnhancedApi: Boolean;
  SockWship6Api: Boolean;

type
  TVarSin = packed record
    case integer of
      0: (AddressFamily: u_short);
      1: (
        case sin_family: u_short of
          AF_INET: (sin_port: u_short;
                    sin_addr: TInAddr;
                    sin_zero: array[0..7] of Char);
          AF_INET6: (sin6_port:     u_short;
                		sin6_flowinfo: u_long;
      	    	      sin6_addr:     TInAddr6;
      		          sin6_scope_id: u_long);
          );
  end;

function SizeOfVarSin(sin: TVarSin): integer;

function Bind(s: TSocket; const addr: TVarSin): Integer;
function Connect(s: TSocket; const name: TVarSin): Integer;
function GetSockName(s: TSocket; var name: TVarSin): Integer;
function GetPeerName(s: TSocket; var name: TVarSin): Integer;
function GetHostName: string;
function Send(s: TSocket; Buf: TMemory; len, flags: Integer): Integer;
function Recv(s: TSocket; Buf: TMemory; len, flags: Integer): Integer;
function SendTo(s: TSocket; Buf: TMemory; len, flags: Integer; addrto: TVarSin): Integer;
function RecvFrom(s: TSocket; Buf: TMemory; len, flags: Integer; from: TVarSin): Integer;
function Accept(s: TSocket; addr: TVarSin): TSocket;

{==============================================================================}
implementation

var
  SynSockCount: Integer = 0;
  LibHandle: THandle = 0;
  Libwship6Handle: THandle = 0;

function IN6_IS_ADDR_UNSPECIFIED(const a: PInAddr6): boolean;
begin
  Result := ((a^.s_un_dw.s_dw1 = 0) and (a^.s_un_dw.s_dw2 = 0) and
             (a^.s_un_dw.s_dw3 = 0) and (a^.s_un_dw.s_dw4 = 0));
end;

function IN6_IS_ADDR_LOOPBACK(const a: PInAddr6): boolean;
begin
  Result := ((a^.s_un_dw.s_dw1 = 0) and (a^.s_un_dw.s_dw2 = 0) and
             (a^.s_un_dw.s_dw3 = 0) and
             (a^.s_un_b.s_b13 = char(0)) and (a^.s_un_b.s_b14 = char(0)) and
             (a^.s_un_b.s_b15 = char(0)) and (a^.s_un_b.s_b16 = char(1)));
end;

function IN6_IS_ADDR_LINKLOCAL(const a: PInAddr6): boolean;
begin
  Result := ((a^.s_un_b.s_b1 = u_char($FE)) and (a^.s_un_b.s_b2 = u_char($80)));
end;

function IN6_IS_ADDR_SITELOCAL(const a: PInAddr6): boolean;
begin
  Result := ((a^.s_un_b.s_b1 = u_char($FE)) and (a^.s_un_b.s_b2 = u_char($C0)));
end;

function IN6_IS_ADDR_MULTICAST(const a: PInAddr6): boolean;
begin
  Result := (a^.s_un_b.s_b1 = char($FF));
end;

function IN6_ADDR_EQUAL(const a: PInAddr6; const b: PInAddr6): boolean;
begin
  Result := (CompareMem( a, b, sizeof(TInAddr6)));
end;

procedure SET_IN6_IF_ADDR_ANY (const a: PInAddr6);
begin
  FillChar(a^, sizeof(TInAddr6), 0);
end;

procedure SET_LOOPBACK_ADDR6 (const a: PInAddr6);
begin
  FillChar(a^, sizeof(TInAddr6), 0);
  a^.s_un_b.s_b16 := char(1);
end;

{=============================================================================}
var
{$IFNDEF FPC}
  errno_loc: function: PInteger cdecl = nil;
{$ELSE}
  errno_loc: function: PInteger = nil; cdecl;
{$ENDIF}

function LSWSAStartup(wVersionRequired: Word; var WSData: TWSAData): Integer;
begin
  with WSData do
  begin
    wVersion := wVersionRequired;
    wHighVersion := $202;
    szDescription := 'Synsock - Synapse Platform Independent Socket Layer';
    szSystemStatus := 'Running on Linux';
    iMaxSockets := 32768;
    iMaxUdpDg := 8192;
  end;
  Result := 0;
end;

function LSWSACleanup: Integer;
begin
  Result := 0;
end;

function LSWSAGetLastError: Integer;
var
  p: PInteger;
begin
  p := errno_loc;
  Result := p^;
end;

function __FDELT(Socket: TSocket): Integer;
begin
  Result := Socket div __NFDBITS;
end;

function __FDMASK(Socket: TSocket): __fd_mask;
begin
  Result := 1 shl (Socket mod __NFDBITS);
end;

function FD_ISSET(Socket: TSocket; var fdset: TFDSet): Boolean;
begin
  Result := (fdset.fds_bits[__FDELT(Socket)] and __FDMASK(Socket)) <> 0;
end;

procedure FD_SET(Socket: TSocket; var fdset: TFDSet);
begin
  fdset.fds_bits[__FDELT(Socket)] := fdset.fds_bits[__FDELT(Socket)] or __FDMASK(Socket);
end;

procedure FD_CLR(Socket: TSocket; var fdset: TFDSet);
begin
  fdset.fds_bits[__FDELT(Socket)] := fdset.fds_bits[__FDELT(Socket)] and (not __FDMASK(Socket));
end;

procedure FD_ZERO(var fdset: TFDSet);
var
  I: Integer;
begin
  with fdset do
    for I := Low(fds_bits) to High(fds_bits) do
      fds_bits[I] := 0;
end;

{=============================================================================}

function SizeOfVarSin(sin: TVarSin): integer;
begin
  case sin.sin_family of
    AF_INET:
            Result := SizeOf(TSockAddrIn);
    AF_INET6:
            Result := SizeOf(TSockAddrIn6);
  else
    Result := 0;
  end;
end;

{=============================================================================}

function Bind(s: TSocket; const addr: TVarSin): Integer;
begin
  Result := ssBind(s, @addr, SizeOfVarSin(addr));
end;

function Connect(s: TSocket; const name: TVarSin): Integer;
begin
  Result := ssConnect(s, @name, SizeOfVarSin(name));
end;

function GetSockName(s: TSocket; var name: TVarSin): Integer;
var
  len: integer;
begin
  len := SizeOf(name);
  FillChar(name, len, 0);
  Result := ssGetSockName(s, @name, Len);
end;

function GetPeerName(s: TSocket; var name: TVarSin): Integer;
var
  len: integer;
begin
  len := SizeOf(name);
  FillChar(name, len, 0);
  Result := ssGetPeerName(s, @name, Len);
end;

function GetHostName: string;
var
  s: string;
begin
  Result := '';
  setlength(s, 255);
  ssGetHostName(pchar(s), Length(s) - 1);
  Result := Pchar(s);
end;

function Send(s: TSocket; Buf: TMemory; len, flags: Integer): Integer;
begin
  Result := ssSend(s, Buf^, len, flags);
end;

function Recv(s: TSocket; Buf: TMemory; len, flags: Integer): Integer;
begin
  Result := ssRecv(s, Buf^, len, flags);
end;

function SendTo(s: TSocket; Buf: TMemory; len, flags: Integer; addrto: TVarSin): Integer;
begin
  Result := ssSendTo(s, Buf^, len, flags, @addrto, SizeOfVarSin(addrto));
end;

function RecvFrom(s: TSocket; Buf: TMemory; len, flags: Integer; from: TVarSin): Integer;
var
  x: integer;
begin
  x := SizeOf(from);
  Result := ssRecvFrom(s, Buf^, len, flags, @from, x);
end;

function Accept(s: TSocket; addr: TVarSin): TSocket;
var
  x: integer;
begin
  x := SizeOf(addr);
  Result := ssAccept(s, @addr, x);
end;

{=============================================================================}

function InitSocketInterface(stack: string): Boolean;
begin
  Result := False;
  SockEnhancedApi := False;
  if stack = '' then
    stack := DLLStackName;
  SynSockCS.Enter;
  try
    if SynSockCount = 0 then
    begin
      SockEnhancedApi := False;
      SockWship6Api := False;
      Libc.Signal(Libc.SIGPIPE, TSignalHandler(Libc.SIG_IGN));
      LibHandle := LoadLibrary(PChar(Stack));
      if LibHandle <> 0 then
      begin
        errno_loc := GetProcAddress(LibHandle, PChar('__errno_location'));
        CloseSocket := GetProcAddress(LibHandle, PChar('close'));
        IoctlSocket := GetProcAddress(LibHandle, PChar('ioctl'));
        WSAGetLastError := LSWSAGetLastError;
        WSAStartup := LSWSAStartup;
        WSACleanup := LSWSACleanup;
        ssAccept := GetProcAddress(LibHandle, PChar('accept'));
        ssBind := GetProcAddress(LibHandle, PChar('bind'));
        ssConnect := GetProcAddress(LibHandle, PChar('connect'));
        ssGetPeerName := GetProcAddress(LibHandle, PChar('getpeername'));
        ssGetSockName := GetProcAddress(LibHandle, PChar('getsockname'));
        GetSockOpt := GetProcAddress(LibHandle, PChar('getsockopt'));
        Htonl := GetProcAddress(LibHandle, PChar('htonl'));
        Htons := GetProcAddress(LibHandle, PChar('htons'));
        Inet_Addr := GetProcAddress(LibHandle, PChar('inet_addr'));
        Inet_Ntoa := GetProcAddress(LibHandle, PChar('inet_ntoa'));
        Listen := GetProcAddress(LibHandle, PChar('listen'));
        Ntohl := GetProcAddress(LibHandle, PChar('ntohl'));
        Ntohs := GetProcAddress(LibHandle, PChar('ntohs'));
        ssRecv := GetProcAddress(LibHandle, PChar('recv'));
        ssRecvFrom := GetProcAddress(LibHandle, PChar('recvfrom'));
        Select := GetProcAddress(LibHandle, PChar('select'));
        ssSend := GetProcAddress(LibHandle, PChar('send'));
        ssSendTo := GetProcAddress(LibHandle, PChar('sendto'));
        SetSockOpt := GetProcAddress(LibHandle, PChar('setsockopt'));
        ShutDown := GetProcAddress(LibHandle, PChar('shutdown'));
        Socket := GetProcAddress(LibHandle, PChar('socket'));
        GetHostByAddr := GetProcAddress(LibHandle, PChar('gethostbyaddr'));
        GetHostByName := GetProcAddress(LibHandle, PChar('gethostbyname'));
        GetProtoByName := GetProcAddress(LibHandle, PChar('getprotobyname'));
        GetProtoByNumber := GetProcAddress(LibHandle, PChar('getprotobynumber'));
        GetServByName := GetProcAddress(LibHandle, PChar('getservbyname'));
        GetServByPort := GetProcAddress(LibHandle, PChar('getservbyport'));
        ssGetHostName := GetProcAddress(LibHandle, PChar('gethostname'));

{$IFNDEF FORCEOLDAPI}
        GetAddrInfo := GetProcAddress(LibHandle, PChar('getaddrinfo'));
        FreeAddrInfo := GetProcAddress(LibHandle, PChar('freeaddrinfo'));
        GetNameInfo := GetProcAddress(LibHandle, PChar('getnameinfo'));
        SockEnhancedApi := Assigned(GetAddrInfo) and Assigned(FreeAddrInfo)
          and Assigned(GetNameInfo);
{$ENDIF}
        Result := True;
      end;
    end
    else Result := True;
    if Result then
      Inc(SynSockCount);
  finally
    SynSockCS.Leave;
  end;
end;

function DestroySocketInterface: Boolean;
begin
  SynSockCS.Enter;
  try
    Dec(SynSockCount);
    if SynSockCount < 0 then
      SynSockCount := 0;
    if SynSockCount = 0 then
    begin
      if LibHandle <> 0 then
      begin
        FreeLibrary(libHandle);
        LibHandle := 0;
      end;
      if LibWship6Handle <> 0 then
      begin
        FreeLibrary(LibWship6Handle);
        LibWship6Handle := 0;
      end;
    end;
  finally
    SynSockCS.Leave;
  end;
  Result := True;
end;

initialization
begin
  SynSockCS := SyncObjs.TCriticalSection.Create;
  SET_IN6_IF_ADDR_ANY (@in6addr_any);
  SET_LOOPBACK_ADDR6  (@in6addr_loopback);
end;

finalization
begin
  SynSockCS.Free;
end;

{$ENDIF}

