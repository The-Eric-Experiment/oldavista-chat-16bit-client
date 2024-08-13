{*_* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

Author:       Fran�ois PIETTE
Description:  This unit encapsulate the ICMP.DLL into an object of type TICMP.
              Using this object, you can easily ping any host on your network.
              Works only in 32 bits mode (no Delphi 1) under NT or 95.
              TICMP is perfect for a console mode program, but if you build a
              GUI program, you could use the TPing object wich is a true VCL
              encapsulating the TICMP object. Then you can use object inspector
              to change properties or event handler. This is much simpler to
              use for a GUI program.
Creation:     January 6, 1997
Version:      1.05
EMail:        francois.piette@overbyte.be  http://www.overbyte.be
              francois.piette@rtfm.be      http://www.rtfm.be/fpiette
                                           francois.piette@pophost.eunet.be
Support:      Use the mailing list twsocket@elists.org
              Follow "support" link at http://www.overbyte.be for subscription.
Legal issues: Copyright (C) 1997-2005 by Fran�ois PIETTE
              Rue de Grady 24, 4053 Embourg, Belgium. Fax: +32-4-365.74.56
              <francois.piette@overbyte.be>

              This software is provided 'as-is', without any express or
              implied warranty.  In no event will the author be held liable
              for any  damages arising from the use of this software.

              Permission is granted to anyone to use this software for any
              purpose, including commercial applications, and to alter it
              and redistribute it freely, subject to the following
              restrictions:

              1. The origin of this software must not be misrepresented,
                 you must not claim that you wrote the original software.
                 If you use this software in a product, an acknowledgment
                 in the product documentation would be appreciated but is
                 not required.

              2. Altered source versions must be plainly marked as such, and
                 must not be misrepresented as being the original software.

              3. This notice may not be removed or altered from any source
                 distribution.

              4. You must register this software by sending a picture postcard
                 to the author. Use a nice stamp and mention your name, street
                 address, EMail address and any comment you like to say.

Updates:
Dec 13, 1997 V1.01 Added OnEchoRequest and OnEchoReply events and removed the
             corresponding OnDisplay event. This require to modify existing
             programs.
Mar 15, 1998 V1.02 Deplaced address resolution just before use
Sep 24, 1998 V1.02a Changed TIPAddr and others to LongInt to avoid range error
             problems with Delphi 4
Jan 24, 1999 V1.03 Surfaced Flags property to allow fragmentation check
             (Flags = IP_FLAG_DF to enable fragmentation check)
Jan 19, 2004 V1.04 Added property ICMPDLLHandle.
May 32, 2004 V1.05 Used ICSDEFS.INC


 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
unit Icmp;

interface

{$B-}           { Enable partial boolean evaluation   }
{$T-}           { Untyped pointers                    }
{$X+}           { Enable extended syntax              }
{$I ICSDEFS.INC}
{$IFDEF DELPHI6_UP}
    {$WARN SYMBOL_PLATFORM   OFF}
    {$WARN SYMBOL_LIBRARY    OFF}
    {$WARN SYMBOL_DEPRECATED OFF}
{$ENDIF}
{$IFNDEF VER80}   { Not for Delphi 1                    }
    {$H+}         { Use long strings                    }
    {$J+}         { Allow typed constant to be modified }
{$ENDIF}
{$IFDEF BCB3_UP}
    {$ObjExportAll On}
{$ENDIF}
{$IFDEF VER80}
{*// This source file is *NOT* compatible with Delphi 1 because it uses
// Win 32 features.*}
{$ENDIF}

uses
{$IFDEF USEWINDOWS}
    Windows,
{$ELSE}
    WinTypes, WinProcs,
{$ENDIF}
    SysUtils, Classes, WinSock;

const
  IcmpVersion = 105;
  CopyRight : String   = ' TICMP (c) 1997-2005 F. Piette V1.05 ';
  IcmpDLL     = 'icmp.dll';

  IP_SUCCESS                  = 0;
  IP_STATUS_BASE              = 11000;
  IP_BUF_TOO_SMALL            = (IP_STATUS_BASE + 1);
  IP_DEST_NET_UNREACHABLE     = (IP_STATUS_BASE + 2);
  IP_DEST_HOST_UNREACHABLE    = (IP_STATUS_BASE + 3);
  IP_DEST_PROT_UNREACHABLE    = (IP_STATUS_BASE + 4);
  IP_DEST_PORT_UNREACHABLE    = (IP_STATUS_BASE + 5);
  IP_NO_RESOURCES             = (IP_STATUS_BASE + 6);
  IP_BAD_OPTION               = (IP_STATUS_BASE + 7);
  IP_HW_ERROR                 = (IP_STATUS_BASE + 8);
  IP_PACKET_TOO_BIG           = (IP_STATUS_BASE + 9);
  IP_REQ_TIMED_OUT            = (IP_STATUS_BASE + 10);
  IP_BAD_REQ                  = (IP_STATUS_BASE + 11);
  IP_BAD_ROUTE                = (IP_STATUS_BASE + 12);
  IP_TTL_EXPIRED_TRANSIT      = (IP_STATUS_BASE + 13);
  IP_TTL_EXPIRED_REASSEM      = (IP_STATUS_BASE + 14);
  IP_PARAM_PROBLEM            = (IP_STATUS_BASE + 15);
  IP_SOURCE_QUENCH            = (IP_STATUS_BASE + 16);
  IP_OPTION_TOO_BIG           = (IP_STATUS_BASE + 17);
  IP_BAD_DESTINATION          = (IP_STATUS_BASE + 18);

  
  IP_ADDR_DELETED             = (IP_STATUS_BASE + 19);
  IP_SPEC_MTU_CHANGE          = (IP_STATUS_BASE + 20);
  IP_MTU_CHANGE               = (IP_STATUS_BASE + 21);

  IP_GENERAL_FAILURE          = (IP_STATUS_BASE + 50);

  MAX_IP_STATUS               = IP_GENERAL_FAILURE;

  IP_PENDING                  = (IP_STATUS_BASE + 255);

  
  IP_FLAG_DF                  = $02;         

  
  IP_OPT_EOL                  = $00;         
  IP_OPT_NOP                  = $01;         
  IP_OPT_SECURITY             = $82;         
  IP_OPT_LSRR                 = $83;         
  IP_OPT_SSRR                 = $89;         
  IP_OPT_RR                   = $07;         
  IP_OPT_TS                   = $44;         
  IP_OPT_SID                  = $88;         
  MAX_OPT_SIZE                = $40;

type
  
  TIPAddr   = LongInt;   
  TIPMask   = LongInt;   
  TIPStatus = LongInt;   

  PIPOptionInformation = ^TIPOptionInformation;
  TIPOptionInformation = packed record
     TTL:         Byte;      
     TOS:         Byte;      
     Flags:       Byte;      
     OptionsSize: Byte;      
     OptionsData: PChar;     
  end;

  PIcmpEchoReply = ^TIcmpEchoReply;
  TIcmpEchoReply = packed record
     Address:       TIPAddr;              
     Status:        DWord;                
     RTT:           DWord;                
     DataSize:      Word;                 
     Reserved:      Word;                 
     Data:          Pointer;              
     Options:       TIPOptionInformation; 
  end;

  
  
  
  
  
  
  
  TIcmpCreateFile  = function: THandle; stdcall;

  
  
  
  
  
  
  
  TIcmpCloseHandle = function(IcmpHandle: THandle): Boolean; stdcall;

  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  TIcmpSendEcho    = function(IcmpHandle:          THandle;
                              DestinationAddress:  TIPAddr;
                              RequestData:         Pointer;
                              RequestSize:         Word;
                              RequestOptions:      PIPOptionInformation;
                              ReplyBuffer:         Pointer;
                              ReplySize:           DWord;
                              Timeout:             DWord
                             ): DWord; stdcall;

  
  TICMPDisplay = procedure(Sender: TObject; Msg : String) of object;
  TICMPReply   = procedure(Sender: TObject; Error : Integer) of object;

  
  TICMP = class(TObject)
  private
    hICMPdll :        HModule;                    
    IcmpCreateFile :  TIcmpCreateFile;
    IcmpCloseHandle : TIcmpCloseHandle;
    IcmpSendEcho :    TIcmpSendEcho;
    hICMP :           THandle;                    
    FReply :          TIcmpEchoReply;             
    FAddress :        String;                     
    FHostName :       String;                     
    FHostIP :         String;                     
    FIPAddress :      TIPAddr;                    
    FSize :           Integer;                    
    FTimeOut :        Integer;                    
    FTTL :            Integer;                    
    FFlags :          Integer;                    
    FOnDisplay :      TICMPDisplay;               
    FOnEchoRequest :  TNotifyEvent;
    FOnEchoReply :    TICMPReply;
    FLastError :      DWORD;                      
    FAddrResolved :   Boolean;
    procedure ResolveAddr;
  public
    constructor Create; virtual;
    destructor  Destroy; override;
    function    Ping : Integer;
    procedure   SetAddress(Value : String);
    function    GetErrorString : String;

    property Address       : String         read  FAddress   write SetAddress;
    property Size          : Integer        read  FSize      write FSize;
    property Timeout       : Integer        read  FTimeout   write FTimeout;
    property Reply         : TIcmpEchoReply read  FReply;
    property TTL           : Integer        read  FTTL       write FTTL;
    Property Flags         : Integer        read  FFlags     write FFlags;
    property ErrorCode     : DWORD          read  FLastError;
    property ErrorString   : String         read  GetErrorString;
    property HostName      : String         read  FHostName;
    property HostIP        : String         read  FHostIP;
    property ICMPDLLHandle : HModule        read  hICMPdll;
    property OnDisplay     : TICMPDisplay   read  FOnDisplay write FOnDisplay;
    property OnEchoRequest : TNotifyEvent   read  FOnEchoRequest
                                            write FOnEchoRequest;
    property OnEchoReply   : TICMPReply     read  FOnEchoReply
                                            write FOnEchoReply;
  end;

  TICMPException = class(Exception);

implementation

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
constructor TICMP.Create;
var
    WSAData: TWSAData;
begin
    hICMP    := INVALID_HANDLE_VALUE;
    FSize    := 56;
    FTTL     := 64;
    FTimeOut := 4000;

    
    if WSAStartup($101, WSAData) <> 0 then
        raise TICMPException.Create('Error initialising Winsock');

    
    hICMPdll := LoadLibrary(icmpDLL);
    if hICMPdll = 0 then
        raise TICMPException.Create('Unable to register ' + icmpDLL);

    @ICMPCreateFile  := GetProcAddress(hICMPdll, 'IcmpCreateFile');
    @IcmpCloseHandle := GetProcAddress(hICMPdll, 'IcmpCloseHandle');
    @IcmpSendEcho    := GetProcAddress(hICMPdll, 'IcmpSendEcho');

    if (@ICMPCreateFile = Nil) or
       (@IcmpCloseHandle = Nil) or
       (@IcmpSendEcho = Nil) then
          raise TICMPException.Create('Error loading dll functions');

    hICMP := IcmpCreateFile;
    if hICMP = INVALID_HANDLE_VALUE then
        raise TICMPException.Create('Unable to get ping handle');
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
destructor TICMP.Destroy;
begin
    if hICMP <> INVALID_HANDLE_VALUE then
        IcmpCloseHandle(hICMP);
    if hICMPdll <> 0 then
        FreeLibrary(hICMPdll);
    WSACleanup;
    inherited Destroy;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function MinInteger(X, Y: Integer): Integer;
begin
    if X >= Y then
        Result := Y
    else
        Result := X;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TICMP.ResolveAddr;
var
    Phe : PHostEnt;             
begin
    
    FIPAddress := inet_addr(PChar(FAddress));
    if FIPAddress <> LongInt(INADDR_NONE) then
        
        FHostName := FAddress
    else begin
        
        Phe := GetHostByName(PChar(FAddress));
        if Phe = nil then begin
            FLastError := GetLastError;
            if Assigned(FOnDisplay) then
                FOnDisplay(Self, 'Unable to resolve ' + FAddress);
            Exit;
        end;

        FIPAddress := longint(plongint(Phe^.h_addr_list^)^);
        FHostName  := Phe^.h_name;
    end;

    FHostIP       := StrPas(inet_ntoa(TInAddr(FIPAddress)));
    FAddrResolved := TRUE;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TICMP.SetAddress(Value : String);
begin
    
    if FAddress = Value then
        Exit;
    FAddress      := Value;
    FAddrResolved := FALSE;

end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TICMP.GetErrorString : String;
begin
    case FLastError of
    IP_SUCCESS:               Result := 'No error';
    IP_BUF_TOO_SMALL:         Result := 'Buffer too small';
    IP_DEST_NET_UNREACHABLE:  Result := 'Destination network unreachable';
    IP_DEST_HOST_UNREACHABLE: Result := 'Destination host unreachable';
    IP_DEST_PROT_UNREACHABLE: Result := 'Destination protocol unreachable';
    IP_DEST_PORT_UNREACHABLE: Result := 'Destination port unreachable';
    IP_NO_RESOURCES:          Result := 'No resources';
    IP_BAD_OPTION:            Result := 'Bad option';
    IP_HW_ERROR:              Result := 'Hardware error';
    IP_PACKET_TOO_BIG:        Result := 'Packet too big';
    IP_REQ_TIMED_OUT:         Result := 'Request timed out';
    IP_BAD_REQ:               Result := 'Bad request';
    IP_BAD_ROUTE:             Result := 'Bad route';
    IP_TTL_EXPIRED_TRANSIT:   Result := 'TTL expired in transit';
    IP_TTL_EXPIRED_REASSEM:   Result := 'TTL expired in reassembly';
    IP_PARAM_PROBLEM:         Result := 'Parameter problem';
    IP_SOURCE_QUENCH:         Result := 'Source quench';
    IP_OPTION_TOO_BIG:        Result := 'Option too big';
    IP_BAD_DESTINATION:       Result := 'Bad Destination';
    IP_ADDR_DELETED:          Result := 'Address deleted';
    IP_SPEC_MTU_CHANGE:       Result := 'Spec MTU change';
    IP_MTU_CHANGE:            Result := 'MTU change';
    IP_GENERAL_FAILURE:       Result := 'General failure';
    IP_PENDING:               Result := 'Pending';
    else
        Result := 'ICMP error #' + IntToStr(FLastError);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function TICMP.Ping : Integer;
var
  BufferSize:        Integer;
  pReqData, pData:   Pointer;
  pIPE:              PIcmpEchoReply;       
  IPOpt:             TIPOptionInformation; 
  Msg:               String;
begin
    Result     := 0;
    FLastError := 0;

    if not FAddrResolved then
        ResolveAddr;

    if FIPAddress = LongInt(INADDR_NONE) then begin
        FLastError := IP_BAD_DESTINATION;
        if Assigned(FOnDisplay) then
            FOnDisplay(Self, 'Invalid host address');
        Exit;
    end;

    
    BufferSize := SizeOf(TICMPEchoReply) + FSize;
    GetMem(pReqData, FSize);
    GetMem(pData,    FSize);
    GetMem(pIPE,     BufferSize);

    try
        
        FillChar(pReqData^, FSize, $20);
        Msg := 'Pinging from Delphi code written by F. Piette';
        Move(Msg[1], pReqData^, MinInteger(FSize, Length(Msg)));

        pIPE^.Data := pData;
        FillChar(pIPE^, SizeOf(pIPE^), 0);

        if Assigned(FOnEchoRequest) then
            FOnEchoRequest(Self);

        FillChar(IPOpt, SizeOf(IPOpt), 0);
        IPOpt.TTL   := FTTL;
        IPOpt.Flags := FFlags;
        Result      := IcmpSendEcho(hICMP, FIPAddress, pReqData, FSize,
                                    @IPOpt, pIPE, BufferSize, FTimeOut);
        FLastError  := GetLastError;
        FReply      := pIPE^;

        if Assigned(FOnEchoReply) then
            FOnEchoReply(Self, Result);
    finally
        
        FreeMem(pIPE);
        FreeMem(pData);
        FreeMem(pReqData);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

end.

