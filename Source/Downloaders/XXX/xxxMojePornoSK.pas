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

unit xxxMojePornoSK;
{$INCLUDE 'ytd.inc'}

interface

uses
  SysUtils, Classes,
  uPCRE, uXml, HttpSend, 
  uDownloader, uCommonDownloader, uHttpDownloader;

type
  TDownloader_MojePornoSK = class(THttpDownloader)
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

const
  URLREGEXP_BEFORE_ID = 'mojeporno\.sk/video/';
  URLREGEXP_ID =        REGEXP_PATH_COMPONENT;
  URLREGEXP_AFTER_ID =  '';

{ TDownloader_MojePornoSK }

class function TDownloader_MojePornoSK.Provider: string;
begin
  Result := 'MojePorno.sk';
end;

class function TDownloader_MojePornoSK.UrlRegExp: string;
begin
  Result := Format(REGEXP_COMMON_URL, [URLREGEXP_BEFORE_ID, MovieIDParamName, URLREGEXP_ID, URLREGEXP_AFTER_ID]);
end;

constructor TDownloader_MojePornoSK.Create(const AMovieID: string);
begin
  inherited;
  InfoPageEncoding := peUtf8;
  InfoPageIsXml := True;
end;

destructor TDownloader_MojePornoSK.Destroy;
begin
  inherited;
end;

function TDownloader_MojePornoSK.GetMovieInfoUrl: string;
begin
  Result := Format('http://www.mojeporno.sk/download/%s/xml/', [MovieID]);
end;

function TDownloader_MojePornoSK.AfterPrepareFromPage(var Page: string; PageXml: TXmlDoc; Http: THttpSend): boolean;
var
  Node: TXmlNode;
  Url, Title: string;
begin
  inherited AfterPrepareFromPage(Page, PageXml, Http);
  Result := False;
  if not XmlNodeByPath(PageXml, 'trackList/track', Node) then
    SetLastErrorMsg(ERR_FAILED_TO_LOCATE_MEDIA_INFO)
  else if not GetXmlVar(Node, 'location', Url) then
    SetLastErrorMsg(ERR_FAILED_TO_LOCATE_MEDIA_URL)
  else if not GetXmlVar(Node, 'title', Title) then
    SetLastErrorMsg(ERR_FAILED_TO_LOCATE_MEDIA_TITLE)
  else
    begin
    Name := Title;
    MovieUrl := Url;
    SetPrepared(True);
    Result := True;
    end;
end;

initialization
  {$IFDEF XXX}
  RegisterDownloader(TDownloader_MojePornoSK);
  {$ENDIF}

end.
