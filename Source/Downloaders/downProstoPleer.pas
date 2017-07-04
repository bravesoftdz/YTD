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

unit downProstoPleer;
{$INCLUDE 'ytd.inc'}

interface

uses
  SysUtils, Classes,
  uPCRE, uXml, HttpSend,
  uDownloader, uCommonDownloader, uHTTPDownloader;

type
  TDownloader_ProstoPleer = class(THTTPDownloader)
    private
    protected
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

// http://prostopleer.com/tracks/503102372y2
// http://prostopleer.com/#/tracks/503102372y2
const
  URLREGEXP_BEFORE_ID = 'prostopleer\.com/(?:#/)?tracks/';
  URLREGEXP_ID =        REGEXP_PATH_COMPONENT;
  URLREGEXP_AFTER_ID =  '';

const
  REGEXP_MOVIE_TITLE =  '<div\s+class="results">\s*' + REGEXP_TITLE_H1;
  REGEXP_MOVIE_URL =    '"track_link"\s*:\s*"(?P<URL>https?://.+?)"';

{ TDownloader_ProstoPleer }

class function TDownloader_ProstoPleer.Provider: string;
begin
  Result := 'ProstoPleer.com';
end;

class function TDownloader_ProstoPleer.UrlRegExp: string;
begin
  Result := Format(REGEXP_COMMON_URL, [URLREGEXP_BEFORE_ID, MovieIDParamName, URLREGEXP_ID, URLREGEXP_AFTER_ID]);
end;

constructor TDownloader_ProstoPleer.Create(const AMovieID: string);
begin
  inherited Create(AMovieID);
  InfoPageEncoding := peUTF8;
  MovieTitleRegExp := RegExCreate(Format(REGEXP_MOVIE_TITLE, [MovieID]));
  MovieUrlRegExp := RegExCreate(REGEXP_MOVIE_URL);
end;

destructor TDownloader_ProstoPleer.Destroy;
begin
  RegExFreeAndNil(MovieTitleRegExp);
  RegExFreeAndNil(MovieUrlRegExp);
  inherited;
end;

function TDownloader_ProstoPleer.GetMovieInfoUrl: string;
begin
  Result := 'http://prostopleer.com/tracks/' + MovieID;
end;

function TDownloader_ProstoPleer.AfterPrepareFromPage(var Page: string; PageXml: TXmlDoc; Http: THttpSend): boolean;
const
  PROSTOPLEER_POST_DATA_URL = 'http://prostopleer.com/site_api/files/get_url';
var
  Info, Url: String;
begin
  inherited AfterPrepareFromPage(Page, PageXml, Http);
  Result := False;
  if not DownloadPage(Http, PROSTOPLEER_POST_DATA_URL, {$IFDEF UNICODE} AnsiString {$ENDIF} ('action=download&id=' + MovieID), HTTP_FORM_URLENCODING_UTF8, Info) then
    SetLastErrorMsg(ERR_FAILED_TO_DOWNLOAD_MEDIA_INFO_PAGE)
  else if not GetRegExpVar(MovieUrlRegExp, Info, 'URL', Url) then
    SetLastErrorMsg(ERR_FAILED_TO_LOCATE_MEDIA_URL)
  else
    begin
    MovieUrl := Url;
    SetPrepared(True);
    Result := True;
    end;
end;

function TDownloader_ProstoPleer.GetFileNameExt: string;
begin
  Result := '.mp3';
end;

initialization
  RegisterDownloader(TDownloader_ProstoPleer);

end.
