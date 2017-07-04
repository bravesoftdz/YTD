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

unit downTVNoe;
{$INCLUDE 'ytd.inc'}

interface

uses
  SysUtils, Classes,
  uPCRE, uXml, HttpSend,
  uDownloader, uCommonDownloader, uHttpDownloader;

type
  TDownloader_TVNoe = class(THttpDownloader)
    private
    protected
      function GetMovieInfoUrl: string; override;
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

// http://tvnoe.tbsystem.cz/index.php?cs/videoarchiv/hlubinami-vesmiru-2010-04-12-mikulasek
// http://tvnoe.tbsystem.cz/index.php?cs/videoarchiv/hlubinami-vesmiru-2010-04-12-mikulasek/quality/high
// http://tvnoe.tbsystem.cz/asx/hlubinami-vesmiru-2010-04-12-mikulasek-low.asx
// http://tvnoe.tbsystem.cz/asx/hlubinami-vesmiru-2010-04-12-mikulasek-high.asx
const
  URLREGEXP_BEFORE_ID = '^https?://(?:[a-z0-9-]+\.)*tvnoe\.tbsystem\.cz/(?:asx/|.*?/videoarchiv/)';
  URLREGEXP_ID =        '[^/?&]+?';
  URLREGEXP_AFTER_ID =  '(?:-low|-high|/|$)';

{ TDownloader_TVNoe }

class function TDownloader_TVNoe.Provider: string;
begin
  Result := 'TVNoe.tbsystem,cz';
end;

class function TDownloader_TVNoe.UrlRegExp: string;
begin
  Result := Format(URLREGEXP_BEFORE_ID + '(?P<%s>' + URLREGEXP_ID + ')' + URLREGEXP_AFTER_ID, [MovieIDParamName]);;
end;

constructor TDownloader_TVNoe.Create(const AMovieID: string);
begin
  inherited;
  InfoPageEncoding := peUtf8;
  InfoPageIsXml := True;
end;

destructor TDownloader_TVNoe.Destroy;
begin
  inherited;
end;

function TDownloader_TVNoe.GetMovieInfoUrl: string;
begin
  Result := 'http://tvnoe.tbsystem.cz/asx/' + MovieID + '-high.asx';
end;

function TDownloader_TVNoe.AfterPrepareFromPage(var Page: string; PageXml: TXmlDoc; Http: THttpSend): boolean;
var Url, Title: string;
begin
  inherited AfterPrepareFromPage(Page, PageXml, Http);
  Result := False;
  if not GetXmlAttr(PageXml, 'entry/ref', 'href', Url) then
    SetLastErrorMsg(ERR_FAILED_TO_LOCATE_MEDIA_URL)
  else if not GetXmlVar(PageXml, 'entry/Title', Title) then
    SetLastErrorMsg(ERR_FAILED_TO_LOCATE_MEDIA_TITLE)
  else
    begin
    Name := Trim(Title);
    MovieUrl := Url;
    SetPrepared(True);
    Result := True;
    end;
end;

initialization
  RegisterDownloader(TDownloader_TVNoe);

end.
