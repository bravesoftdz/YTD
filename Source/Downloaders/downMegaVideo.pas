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

unit downMegaVideo;
{$INCLUDE 'ytd.inc'}
{
  Based on http://userscripts.org/scripts/show/40269
}
interface

uses
  SysUtils, Classes,
  uPCRE, uXml, HttpSend,
  uDownloader, uCommonDownloader, uHttpDownloader;

type
  TDownloader_MegaVideo = class(THttpDownloader)
    private
    protected
      function MasterDomain: string; virtual;
      function LocateMegaVideoParams(const Page: string; PageXml: TXmlDoc; Http: THttpSend; out Title, Server: string; out Key1, Key2: integer; out EncryptedFileID: string): boolean; virtual;
      function DecryptFileID(const FileID: string; Key1, Key2: integer): string; virtual;
      function GetMovieInfoUrl: string; override;
      function GetFileNameExt: string; override;
      function AfterPrepareFromPage(var Page: string; PageXml: TXmlDoc; Http: THttpSend): boolean; override;
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

// http://www.megavideo.com/?v=2MJBY4HB
const
  URLREGEXP_BEFORE_ID = '^https?://(?:[a-z0-9-]+\.)*megavideo\.com/.+?[?&]v=';
  URLREGEXP_ID =        '[^/?&]+';
  URLREGEXP_AFTER_ID =  '';

{ TDownloader_MegaVideo }

class function TDownloader_MegaVideo.Provider: string;
begin
  Result := 'MegaVideo.com';
end;

class function TDownloader_MegaVideo.UrlRegExp: string;
begin
  Result := Format(URLREGEXP_BEFORE_ID + '(?P<%s>' + URLREGEXP_ID + ')' + URLREGEXP_AFTER_ID, [MovieIDParamName]);;
end;

constructor TDownloader_MegaVideo.Create(const AMovieID: string);
begin
  inherited;
  InfoPageEncoding := peUTF8;
  InfoPageIsXml := True;
end;

destructor TDownloader_MegaVideo.Destroy;
begin
  inherited;
end;

function TDownloader_MegaVideo.MasterDomain: string;
begin
  Result := 'megavideo.com';
end;

function TDownloader_MegaVideo.GetMovieInfoUrl: string;
begin
  Result := 'http://www.' + MasterDomain + '/xml/videolink.php?v=' + MovieID;
end;

function TDownloader_MegaVideo.LocateMegaVideoParams(const Page: string; PageXml: TXmlDoc; Http: THttpSend; out Title, Server: string; out Key1, Key2: integer; out EncryptedFileID: string): boolean;
var Node: TXmlNode;
    sKey1, sKey2: string;
begin
  Result := False;
  if not PageXml.NodeByPath('ROW', Node) then
    SetLastErrorMsg(ERR_FAILED_TO_LOCATE_MEDIA_INFO)
  else if not GetXmlAttr(Node, '', 'title', Title) then
    SetLastErrorMsg(ERR_FAILED_TO_LOCATE_MEDIA_TITLE)
  else if not GetXmlAttr(Node, '', 's', Server) then
    SetLastErrorMsg(Format(ERR_VARIABLE_NOT_FOUND, ['Server']))
  else if not GetXmlAttr(Node, '', 'k1', sKey1) then
    SetLastErrorMsg(Format(ERR_VARIABLE_NOT_FOUND, ['Key1']))
  else if not GetXmlAttr(Node, '', 'k2', sKey2) then
    SetLastErrorMsg(Format(ERR_VARIABLE_NOT_FOUND, ['Key2']))
  else if not GetXmlAttr(Node, '', 'un', EncryptedFileID) then
    SetLastErrorMsg(Format(ERR_VARIABLE_NOT_FOUND, ['EncryptedFileID']))
  else
    begin
    Key1 := StrToIntDef(sKey1, -1);
    Key2 := StrToIntDef(sKey2, -1);
    Result := (Key1 > 0) and (Key2 > 0) and (Server <> '') and (EncryptedFileID <> '');
    if not Result then
      SetLastErrorMsg(ERR_FAILED_TO_LOCATE_MEDIA_INFO);
    end;
end;

function TDownloader_MegaVideo.DecryptFileID(const FileID: string; Key1, Key2: integer): string;
const HexChars = '0123456789abcdef';
var BinID: array of byte;
    KeySwap: array[0..383] of byte;
    n, i, ix1, ix2: integer;
    c: char;
    b: byte;
begin
  n := Length(FileID);
  SetLength(Result, n);
  SetLength(BinID, 4*n);
  for i := 1 to n do
    begin
    c := Upcase(FileID[i]);
    case c of
      '0'..'9':
        b := Ord(c) - Ord('0');
      'A'..'F':
        b := Ord(c) - Ord('A') + 10;
      else
        Raise EConvertError.Create('Invalid hexadecimal character.');
      end;
    BinID[i*4-4] := (b shr 3) and 1;
    BinID[i*4-3] := (b shr 2) and 1;
    BinID[i*4-2] := (b shr 1) and 1;
    BinID[i*4-1] := (b shr 0) and 1;
    end;
  for i := 0 to Pred(Length(KeySwap)) do
    begin
    Key1 := (Key1 * 11 + 77213) mod 81371;
    Key2 := (Key2 * 17 + 92717) mod 192811;
    KeySwap[i] := (Key1 + Key2) and $7f;
    end;
  for i := 256 downto 0 do
    begin
    ix1 := KeySwap[i];
    ix2 := i and $7f;
    b := BinID[ix1];
    BinID[ix1] := BinID[ix2];
    BinID[ix2] := b;
    end;
  for i := 0 to 127 do
    BinID[i] := BinID[i] xor (KeySwap[256+i] and 1);
  for i := 1 to n do
    begin
    b := ((BinID[4*i-4] and 1) shl 3) or
         ((BinID[4*i-3] and 1) shl 2) or
         ((BinID[4*i-2] and 1) shl 1) or
         ((BinID[4*i-1] and 1) shl 0);
    c := HexChars[b + 1];
    Result[i] := c;
    end;
end;

function TDownloader_MegaVideo.AfterPrepareFromPage(var Page: string; PageXml: TXmlDoc; Http: THttpSend): boolean;
var Title, Server, FileID: string;
    Key1, Key2: integer;
begin
  inherited AfterPrepareFromPage(Page, PageXml, Http);
  Result := False;
  if LocateMegaVideoParams(Page, PageXml, Http, Title, Server, Key1, Key2, FileID) then
    begin
    Name := UrlDecode(Title);
    MovieUrl := 'http://www' + Server + '.' + MasterDomain + '/files/' + DecryptFileID(FileID, Key1, Key2) + '/';
    SetPrepared(True);
    Result := True;
    end;
end;

function TDownloader_MegaVideo.GetFileNameExt: string;
begin
  Result := '.flv';
end;

initialization
  RegisterDownloader(TDownloader_MegaVideo);

end.
