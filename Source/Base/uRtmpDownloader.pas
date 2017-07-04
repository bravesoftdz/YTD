(******************************************************************************

______________________________________________________________________________

YTD v1.00                                                    (c) 2009-12 Pepak
http://www.pepak.net/ytd                                  http://www.pepak.net
______________________________________________________________________________


Copyright (c) 2009-12 Pepak (http://www.pepak.net)
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Pepak nor the
      names of his contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL PEPAK BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

******************************************************************************)

unit uRtmpDownloader;
{$INCLUDE 'ytd.inc'}

interface

uses
  SysUtils, Classes, {$IFDEF DELPHI2007_UP} Windows, StrUtils, {$ENDIF}
  uFunctions, uOptions, uSystem,
  uDownloader, uCommonDownloader, uExternalDownloader,
  RtmpDump_DLL;

type
  ERtmpDownloaderError = class(EExternalDownloaderError);

  TRtmpDownloader = class(TExternalDownloader)
    private
      fRtmpDumpOptions: TRtmpDumpOptions;
      function GetFlashVer: string;
      function GetLive: boolean;
      function GetPageUrl: string;
      function GetPlaypath: string;
      function GetRealtime: boolean;
      function GetRtmpApp: string;
      function GetRtmpUrl: string;
      function GetSecureToken: string;
      function GetSwfUrl: string;
      function GetSwfVfy: string;
      function GetTcUrl: string;
      procedure SetFlashVer(const Value: string);
      procedure SetLive(const Value: boolean);
      procedure SetPageUrl(const Value: string);
      procedure SetPlaypath(const Value: string);
      procedure SetRealtime(const Value: boolean);
      procedure SetRtmpApp(const Value: string);
      procedure SetRtmpUrl(const Value: string);
      procedure SetSecureToken(const Value: string);
      procedure SetSwfUrl(const Value: string);
      procedure SetSwfVfy(const Value: string);
      procedure SetTcUrl(const Value: string);
    protected
      procedure ClearRtmpDumpOptions; {$IFNDEF MINIMIZESIZE} virtual; {$ENDIF}
      function IndexOfRtmpDumpOption(ShortOption: char; out Index: integer): boolean; {$IFNDEF MINIMIZESIZE} virtual; {$ENDIF}
      function GetRtmpDumpOption(ShortOption: char): string; {$IFNDEF MINIMIZESIZE} virtual; {$ENDIF}
      procedure SetRtmpDumpOption(ShortOption: char; const Argument: string = ''); {$IFNDEF MINIMIZESIZE} virtual; {$ENDIF}
      procedure DeleteRtmpDumpOption(ShortOption: char); {$IFNDEF MINIMIZESIZE} virtual; {$ENDIF}
      procedure AddRtmpDumpOption(ShortOption: char; const Argument: string = ''); {$IFNDEF MINIMIZESIZE} virtual; {$ENDIF}
      procedure OnRtmpDownloadProgress(DownloadedSize: integer; PercentDone: double; var DoAbort: integer); {$IFNDEF MINIMIZESIZE} virtual; {$ENDIF}
      function ParseErrorLog(const LogFileName: string; out Error: string): boolean;
      property RtmpDumpOptions: TRtmpDumpOptions read fRtmpDumpOptions write fRtmpDumpOptions;
      procedure SetProxyUrl;
      function UseTokenAsRtmpToken: boolean; {$IFDEF MINIMIZESIZE} dynamic; {$ELSE} virtual; {$ENDIF}
    protected
      function GetContentUrl: string; override;
      function GetFileNameExt: string; override;
    public
      class function CheckForPrerequisites: boolean;
      class function Features: TDownloaderFeatures; override;
      constructor Create(const AMovieID: string); override;
      destructor Destroy; override;
      function Prepare: boolean; override;
      function Download: boolean; override;
      // These properties translate to RTMPDUMP command-line options
      property RtmpUrl: string read GetRtmpUrl write SetRtmpUrl;
      //property RtmpProtocol: string read GetRtmpProtocol write SetRtmpProtocol;
      //property RtmpHost: string read GetRtmpHost write SetRtmpHost;
      //property RtmpPort: string read GetRtmpPort write SetRtmpPort;
      property RtmpApp: string read GetRtmpApp write SetRtmpApp;
      property Playpath: string read GetPlaypath write SetPlaypath;
      property SwfUrl: string read GetSwfUrl write SetSwfUrl;
      property TcUrl: string read GetTcUrl write SetTcUrl;
      property PageUrl: string read GetPageUrl write SetPageUrl;
      property SwfVfy: string read GetSwfVfy write SetSwfVfy;
      property FlashVer: string read GetFlashVer write SetFlashVer;
      property SecureToken: string read GetSecureToken write SetSecureToken;
      property Live: boolean read GetLive write SetLive;
      property Realtime: boolean read GetRealtime write SetRealtime;
    end;

implementation

uses
  uMessages, uCompatibility;

const
  OPTION_FLASHVER = 'f';
  OPTION_LIVE = 'v';
  OPTION_PAGEURL = 'p';
  OPTION_PLAYPATH = 'y';
  OPTION_REALTIME = 'R';
  OPTION_RTMPAPP = 'a';
  OPTION_RTMPURL = 'r';
  OPTION_TOKEN = 'T';
  OPTION_SWFURL = 's';
  OPTION_SWFVFY = 'W';
  OPTION_TCURL = 't';

procedure RtmpDumpDownloadProgressCallback(Tag, DownloadedSize: longint; PercentDone: double; var DoAbort: longint); cdecl;
begin
  TRtmpDownloader(Tag).OnRtmpDownloadProgress(DownloadedSize, PercentDone, DoAbort);
end;

{ TRtmpDownloader }

class function TRtmpDownloader.CheckForPrerequisites: boolean;
begin
  Result := RtmpDump_Init;
end;

class function TRtmpDownloader.Features: TDownloaderFeatures;
begin
  Result := inherited Features + [dfRtmpLiveStream, dfRtmpRealtime, dfPreferRtmpRealtime];
end;

constructor TRtmpDownloader.Create(const AMovieID: string);
begin
  inherited;
  Self.Live := (dfRtmpLiveStream in Features) and (dfPreferRtmpLiveStream in Features);
  Self.RealTime := (dfRtmpRealtime in Features) and (dfPreferRtmpRealtime in Features);
end;

destructor TRtmpDownloader.Destroy;
begin
  inherited;
end;

function TRtmpDownloader.GetContentUrl: string;
const
  PARAM_SEPARATOR = {$IFDEF DEBUG} #13#10 {$ELSE} ' ' {$ENDIF} ;
var
  s: string;
  i: integer;
begin
  SetProxyUrl;
  s := '';
  for i := 0 to Pred(Length(RtmpDumpOptions)) do
    if RtmpDumpOptions[i].Argument = '' then
      s := Format('%s' + PARAM_SEPARATOR + '-%s', [s, RtmpDumpOptions[i].ShortOption])
    else
      s := Format('%s' + PARAM_SEPARATOR + '-%s "%s"', [s, RtmpDumpOptions[i].ShortOption, RtmpDumpOptions[i].Argument]);
  Result := Format('rtmpdump %s' + PARAM_SEPARATOR + '-o "%s"', [s, FileName]);
end;

function TRtmpDownloader.GetFileNameExt: string;
begin
  Result := '';
  if (Playpath <> '') and (not IsFileNameExtOverride) then
    Result := ExtractUrlExt(Playpath);
  if Result = '' then
    Result := inherited GetFileNameExt;
end;

procedure TRtmpDownloader.SetProxyUrl;
begin
  if Options.ProxyActive and (Options.ProxyHost <> '') then
    SetRtmpDumpOption('S', Options.ProxyHost + ':' + Options.ProxyPort);
end;

procedure TRtmpDownloader.ClearRtmpDumpOptions;
begin
  SetLength(fRtmpDumpOptions, 0);
end;

function TRtmpDownloader.IndexOfRtmpDumpOption(ShortOption: char; out Index: integer): boolean;
var i: integer;
begin
  Result := False;
  for i := 0 to Pred(Length(fRtmpDumpOptions)) do
    if fRtmpDumpOptions[i].ShortOption = AnsiChar(ShortOption) then
      begin
      Index := i;
      Result := True;
      Exit;
      end;
end;

function TRtmpDownloader.GetRtmpDumpOption(ShortOption: char): string;
var Index: integer;
begin
  if IndexOfRtmpDumpOption(ShortOption, Index) then
    Result := string(fRtmpDumpOptions[Index].Argument)
  else
    Result := '';
end;

procedure TRtmpDownloader.SetRtmpDumpOption(ShortOption: char; const Argument: string);
var Index: integer;
begin
  if IndexOfRtmpDumpOption(ShortOption, Index) then
    fRtmpDumpOptions[Index].Argument := AnsiString(Argument)
  else
    AddRtmpDumpOption(ShortOption, Argument);
end;

procedure TRtmpDownloader.DeleteRtmpDumpOption(ShortOption: char);
var n, Index: integer;
begin
  if IndexOfRtmpDumpOption(ShortOption, Index) then
    begin
    n := Length(fRtmpDumpOptions);
    while Index < Pred(n) do
      begin
      fRtmpDumpOptions[Index] := fRtmpDumpOptions[Succ(Index)];
      Inc(Index);
      end;
    if n > 0 then
      SetLength(fRtmpDumpOptions, Pred(n));
    end;
end;

procedure TRtmpDownloader.AddRtmpDumpOption(ShortOption: char; const Argument: string);
var n: integer;
begin
  n := Length(fRtmpDumpOptions);
  SetLength(fRtmpDumpOptions, Succ(n));
  fRtmpDumpOptions[n].ShortOption := AnsiChar(ShortOption);
  fRtmpDumpOptions[n].Argument := AnsiString(Argument);
end;

function TRtmpDownloader.GetFlashVer: string;
begin
  Result := GetRtmpDumpOption(OPTION_FLASHVER);
end;

procedure TRtmpDownloader.SetFlashVer(const Value: string);
begin
  SetRtmpDumpOption(OPTION_FLASHVER, Value);
end;

function TRtmpDownloader.GetLive: boolean;
var Index: integer;
begin
  Result := IndexOfRtmpDumpOption(OPTION_LIVE, Index);
end;

procedure TRtmpDownloader.SetLive(const Value: boolean);
begin
  if Value then
    SetRtmpDumpOption(OPTION_LIVE, '')
  else
    DeleteRtmpDumpOption(OPTION_LIVE);
end;

function TRtmpDownloader.GetRealtime: boolean;
var Index: integer;
begin
  Result := IndexOfRtmpDumpOption(OPTION_REALTIME, Index);
end;

procedure TRtmpDownloader.SetRealtime(const Value: boolean);
begin
  if Value then
    SetRtmpDumpOption(OPTION_REALTIME, '')
  else
    DeleteRtmpDumpOption(OPTION_REALTIME);
end;

function TRtmpDownloader.GetPageUrl: string;
begin
  Result := GetRtmpDumpOption(OPTION_PAGEURL);
end;

procedure TRtmpDownloader.SetPageUrl(const Value: string);
begin
  SetRtmpDumpOption(OPTION_PAGEURL, Value);
end;

function TRtmpDownloader.GetPlaypath: string;
begin
  Result := GetRtmpDumpOption(OPTION_PLAYPATH);
end;

procedure TRtmpDownloader.SetPlaypath(const Value: string);
begin
  SetRtmpDumpOption(OPTION_PLAYPATH, Value);
end;

function TRtmpDownloader.GetRtmpApp: string;
begin
  Result := GetRtmpDumpOption(OPTION_RTMPAPP);
end;

procedure TRtmpDownloader.SetRtmpApp(const Value: string);
begin
  SetRtmpDumpOption(OPTION_RTMPAPP, Value);
end;

function TRtmpDownloader.GetRtmpUrl: string;
begin
  Result := GetRtmpDumpOption(OPTION_RTMPURL);
end;

procedure TRtmpDownloader.SetRtmpUrl(const Value: string);
begin
  SetRtmpDumpOption(OPTION_RTMPURL, Value);
end;

function TRtmpDownloader.GetSecureToken: string;
begin
  Result := GetRtmpDumpOption(OPTION_TOKEN);
end;

procedure TRtmpDownloader.SetSecureToken(const Value: string);
begin
  SetRtmpDumpOption(OPTION_TOKEN, Value);
end;

function TRtmpDownloader.GetSwfUrl: string;
begin
  Result := GetRtmpDumpOption(OPTION_SWFURL);
end;

procedure TRtmpDownloader.SetSwfUrl(const Value: string);
begin
  SetRtmpDumpOption(OPTION_SWFURL, Value);
end;

function TRtmpDownloader.GetSwfVfy: string;
begin
  Result := GetRtmpDumpOption(OPTION_SWFVFY);
end;

procedure TRtmpDownloader.SetSwfVfy(const Value: string);
begin
  SetRtmpDumpOption(OPTION_SWFVFY, Value);
end;

function TRtmpDownloader.GetTcUrl: string;
begin
  Result := GetRtmpDumpOption(OPTION_TCURL);
end;

procedure TRtmpDownloader.SetTcUrl(const Value: string);
begin
  SetRtmpDumpOption(OPTION_TCURL, Value);
end;

procedure TRtmpDownloader.OnRtmpDownloadProgress(DownloadedSize: integer; PercentDone: double; var DoAbort: integer);
begin
  DownloadedBytes := DownloadedSize;
  if PercentDone >= 99.9 then
    TotalBytes := DownloadedSize
  else if PercentDone > 0 then
    TotalBytes := Trunc(int64(DownloadedSize) * (100 / PercentDone))
  else
    TotalBytes := -1;
  DoProgress;
  if Aborted then
    DoAbort := 1
  else
    DoAbort := 0;
end;

function TRtmpDownloader.Prepare: boolean;
begin
  ClearRtmpDumpOptions;
  Self.Live := Self.Live or Options.ReadProviderOptionDef(Provider, OPTION_COMMONDOWNLOADER_RTMPLIVESTREAM, dfPreferRtmpLiveStream in Features);
  Self.RealTime := Self.RealTime or Options.ReadProviderOptionDef(Provider, OPTION_COMMONDOWNLOADER_RTMPREALTIME, dfPreferRtmpRealtime in Features);
  Result := inherited Prepare;
  if ([dfAcceptSecureToken, dfRequireSecureToken] * Features) <> [] then
    if Self.Token <> '' then
      if UseTokenAsRtmpToken then
        Self.SecureToken := Self.Token;
end;

function TRtmpDownloader.Download: boolean;
const
  MINIMUM_SIZE_TO_KEEP = 10240;
var LogFileName, ErrorMsg: string;
    RetCode: integer;
    FN, FinalFN: string;
begin
  inherited Download;
  DownloadedBytes := 0;
  TotalBytes := -1;
  Aborted := False;
  Result := False;
  {$IFDEF DEBUG}
  SetRtmpDumpOption('z');
  {$ENDIF}
  SetProxyUrl;
  FinalFN := FileName;
  PrepareDownload(FinalFN, FN, LogFileName);
  SetRtmpDumpOption('o', FN);
  if not RtmpDump_Init then
    SetLastErrorMsg(Format(ERR_FAILED_TO_LOAD_DLL, ['rtmpdump_dll.dll']))
  else
    begin
    SetLastErrorMsg(Format(ERR_SEE_LOGFILE, [LogFileName]));
    RetCode := RtmpDump_Download(Integer(Self), RtmpDumpDownloadProgressCallback, PAnsiChar(AnsiString(LogFileName)), RtmpDumpOptions);
    case RetCode of
      0: // Download complete
           Result := True;
      2: // Incomplete download
           Result := (100*DownloadedBytes div TotalBytes) > 96; // May report incomplete even though it is not
      end;
    if not Result then
      if ParseErrorLog(LogFileName, ErrorMsg) then
        SetLastErrorMsg(Format(ERR_RTMPDUMP_ERROR, [ErrorMsg]));
    FinalizeDownload(FinalFN, FN, Result, MINIMUM_SIZE_TO_KEEP);
    end;
end;

function TRtmpDownloader.ParseErrorLog(const LogFileName: string; out Error: string): boolean;
const
  CRLF {$IFDEF MINIMIZESIZE} : string {$ENDIF} = #13#10;
  RTMPDUMP_ERROR = 'ERROR: ';
  RTMPDUMP_ERROR_LENGTH = Length(RTMPDUMP_ERROR);
  RTMPDUMP_WARNING = 'WARNING: ';
  RTMPDUMP_WARNING_LENGTH = Length(RTMPDUMP_WARNING);
var
  L: TStringList;
  s: string;
  i: integer;
begin
  Result := False;
  Error := '';
  if FileExists(LogFileName) then
    begin
    L := TStringList.Create;
    try
      L.LoadFromFile(LogFileName);
      for i := Pred(L.Count) downto 0 do
        begin
        s := L[i];
        if StartsText(RTMPDUMP_ERROR, s) then
          if Error = '' then
            Error := Trim(Copy(s, Succ(RTMPDUMP_ERROR_LENGTH), MaxInt))
          else
            Error := Trim(Copy(s, Succ(RTMPDUMP_ERROR_LENGTH), MaxInt)) + CRLF + Error
        else if StartsText(RTMPDUMP_WARNING, s) then
          if Error = '' then
            Error := Trim(Copy(s, Succ(RTMPDUMP_WARNING_LENGTH), MaxInt))
          else
            Error := Trim(Copy(s, Succ(RTMPDUMP_WARNING_LENGTH), MaxInt)) + CRLF + Error
        else if Error <> '' then
          Break;
        end;
      Result := Error <> '';
    finally
      FreeAndNil(L);
      end;
    end;
end;

function TRtmpDownloader.UseTokenAsRtmpToken: boolean;
begin
  Result := True;
end;

end.
