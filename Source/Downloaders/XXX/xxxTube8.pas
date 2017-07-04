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

unit xxxTube8;
{$INCLUDE 'ytd.inc'}

interface

uses
  SysUtils, Classes,
  {$ifdef mswindows}
    Windows,
  {$ELSE}
    LCLIntf, LCLType, LMessages,
  {$ENDIF}
  uPCRE, uXml, HttpSend, SynaCode,
  {uCrypto,} uStrings, uFunctions, 
  uDownloader, uCommonDownloader, uHttpDownloader;

type
  TDownloader_Tube8 = class(THttpDownloader)
    private
    protected
      FlashVarsRegExp: TRegExp;
      FlashVarsItemsRegExp: TRegExp;
    protected
      function GetMovieInfoUrl: string; override;
      function AfterPrepareFromPage(var Page: string; PageXml: TXmlDoc; Http: THttpSend): boolean; override;
      function Decrypt(const Data, Password: AnsiString): AnsiString;
    public
      class function Provider: string; override;
      class function UrlRegExp: string; override;
      constructor Create(const AMovieID: string); override;
      destructor Destroy; override;
    end;

implementation

uses
  uStringConsts,
  uDownloadClassifier,
  uMessages;

const
  URLREGEXP_BEFORE_ID = 'tube8\.com/';
  URLREGEXP_ID =        REGEXP_SOMETHING;
  URLREGEXP_AFTER_ID =  '';

const
  REGEXP_MOVIE_TITLE = '\bvideotitle\s*=\s*"(?P<TITLE>.*?)"';
  REGEXP_FLASHVARS = REGEXP_FLASHVARS_JS;
  REGEXP_FLASHVARS_ITEMS = REGEXP_PARSER_FLASHVARS_JS;

{ TDownloader_Tube8 }

class function TDownloader_Tube8.Provider: string;
begin
  Result := 'Tube8.com';
end;

class function TDownloader_Tube8.UrlRegExp: string;
begin
  Result := Format(REGEXP_COMMON_URL, [URLREGEXP_BEFORE_ID, MovieIDParamName, URLREGEXP_ID, URLREGEXP_AFTER_ID]);
end;

constructor TDownloader_Tube8.Create(const AMovieID: string);
begin
  inherited;
  InfoPageEncoding := peUTF8;
  MovieTitleRegExp := RegExCreate(REGEXP_MOVIE_TITLE);
  FlashVarsRegExp := RegExCreate(REGEXP_FLASHVARS);
  FlashVarsItemsRegExp := RegExCreate(REGEXP_FLASHVARS_ITEMS);
end;

destructor TDownloader_Tube8.Destroy;
begin
  RegExFreeAndNil(MovieTitleRegExp);
  RegExFreeAndNil(FlashVarsRegExp);
  RegExFreeAndNil(FlashVarsItemsRegExp);
  inherited;
end;

function TDownloader_Tube8.GetMovieInfoUrl: string;
begin
  Result := 'http://www.tube8.com/' + MovieID;
end;

function TDownloader_Tube8.AfterPrepareFromPage(var Page: string; PageXml: TXmlDoc; Http: THttpSend): boolean;
var
  FlashVars, Title, Url, Encrypted: string;
begin
  inherited AfterPrepareFromPage(Page, PageXml, Http);
  Result := False;
  if not GetRegExpVar(FlashVarsRegExp, Page, 'FLASHVARS', FlashVars) then
    SetLastErrorMsg(ERR_FAILED_TO_LOCATE_MEDIA_INFO)
  else if not GetRegExpVarPairs(FlashVarsItemsRegExp, FlashVars, ['video_title', 'video_url', 'encrypted'], [@Title, @Url, @Encrypted]) then
    SetLastErrorMsg(ERR_FAILED_TO_LOCATE_MEDIA_INFO)
  else
    begin
    Url := JSDecode(Url);
    if Url <> '' then
      if AnsiCompareText(Encrypted, 'true') = 0 then
        if Title <> '' then
          Url := {$IFDEF UNICODE} string {$ENDIF} (Decrypt(DecodeBase64( {$IFDEF UNICODE} AnsiString {$ENDIF} (Url)), {$IFDEF UNICODE} AnsiString {$ENDIF} (StringToUtf8(StringReplace(Title, '+', ' ', [rfReplaceAll])))));
    if not IsHttpProtocol(Url) then
      SetLastErrorMsg(ERR_FAILED_TO_LOCATE_MEDIA_URL)
    else
      begin
      MovieUrl := Url;
      //SetName(UrlDecode(Title));
      SetPrepared(True);
      Result := True;
      end;
    end;
end;

function TDownloader_Tube8.Decrypt(const Data, Password: AnsiString): AnsiString;

  procedure DebugPrint(const Description: string; const Input: array of Byte);
    var
      i: integer;
    begin
      Write(Description);
      for i := 0 to Pred(Length(Input)) do
        Write(Format(' %02.2x', [Input[i]]));
      Writeln;
    end;

const
  KEY_LENGTH_BITS = 256;
  KEY_LENGTH_BYTES = KEY_LENGTH_BITS shr 3;
  BLOCK_LENGTH_BITS = 128;
  BLOCK_LENGTH_BYTES = BLOCK_LENGTH_BITS shr 3;
type
  TKey = array[0..KEY_LENGTH_BYTES-1] of byte;
  TBlock = array[0..BLOCK_LENGTH_BYTES-1] of byte;
var
  Key: TKey;
  EncBlock: TBlock;
  Decrypted: AnsiString;
  i, pwLength: integer;
begin
  // The URL is encrypted by AES256 in CTR mode, where the first block is the
  // initial CTR value.
  // For further details, search the Flash for _getDecryptedVideoUrl.
  Result := '';
  // 1. Get the actual encryption key from the password
  pwLength := Length(Password);
  for i := 0 to Pred(KEY_LENGTH_BYTES) do
    if i >= pwLength then
      Key[i] := 0
    else
      Key[i] := Ord(Password[Succ(i)]);
  ///if not AES_Encrypt_ECB(@Key[0], @EncBlock[0], @Key[0], KEY_LENGTH_BITS) then
  ///  Exit;
  for i := 0 to Pred(KEY_LENGTH_BYTES) do
    Key[i] := EncBlock[i mod BLOCK_LENGTH_BYTES];
  // 2. Decrypt URL in counter mode
  ///if not AES_Decrypt_CTR(Copy(Data, 1, 8), Copy(Data, 9, MaxInt), Decrypted, @Key[0], KEY_LENGTH_BITS) then
  ///  Exit;
  Result := Decrypted;
end;

initialization
  {$IFDEF XXX}
  RegisterDownloader(TDownloader_Tube8);
  {$ENDIF}

end.
