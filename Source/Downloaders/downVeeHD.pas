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

unit downVeeHD;
{$INCLUDE 'ytd.inc'}

interface

uses
  SysUtils, Classes,
  uPCRE, uXml, HttpSend,
  uDownloader, uCommonDownloader, uHttpDownloader;

type
  TDownloader_VeeHD = class(THttpDownloader)
    private
    protected
      MovieInfoUrlRegExp: TRegExp;
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

// http://veehd.com/video/4639434_Solar-Sinter
const
  URLREGEXP_BEFORE_ID = 'veehd\.com/video/';
  URLREGEXP_ID =        REGEXP_SOMETHING;
  URLREGEXP_AFTER_ID =  '';

const
  REGEXP_MOVIE_TITLE =  '<title>(?P<TITLE>.*?)(\s+on Veehd)?</title>';
  REGEXP_MOVIE_URL =    '"url"\s*:\s*"(?P<URL>http.+?)"';
  REGEXP_MOVIE_INFO_URL = '\bfunction\s+load_stream.*?\{\s*src\s*:\s*"(?P<URL>.+?)"';

{ TDownloader_VeeHD }

class function TDownloader_VeeHD.Provider: string;
begin
  Result := 'VeeHD.com';
end;

class function TDownloader_VeeHD.UrlRegExp: string;
begin
  Result := Format(REGEXP_COMMON_URL, [URLREGEXP_BEFORE_ID, MovieIDParamName, URLREGEXP_ID, URLREGEXP_AFTER_ID]);
end;

constructor TDownloader_VeeHD.Create(const AMovieID: string);
begin
  inherited Create(AMovieID);
  InfoPageEncoding := peUtf8;
  MovieTitleRegExp := RegExCreate(REGEXP_MOVIE_TITLE);
  MovieUrlRegExp := RegExCreate(REGEXP_MOVIE_URL);
  MovieInfoUrlRegExp := RegExCreate(REGEXP_MOVIE_INFO_URL);
end;

destructor TDownloader_VeeHD.Destroy;
begin
  RegExFreeAndNil(MovieTitleRegExp);
  RegExFreeAndNil(MovieUrlRegExp);
  RegExFreeAndNil(MovieInfoUrlRegExp);
  inherited;
end;

function TDownloader_VeeHD.GetMovieInfoUrl: string;
begin
  Result := 'http://www.veehd.com/video/' + MovieID;
end;

function TDownloader_VeeHD.AfterPrepareFromPage(var Page: string; PageXml: TXmlDoc; Http: THttpSend): boolean;
var
  Url, InfoPage: string;
begin
  inherited AfterPrepareFromPage(Page, PageXml, Http);
  Result := False;
  if not GetRegExpVar(MovieInfoUrlRegExp, Page, 'URL', Url) then
    SetLastErrorMsg(ERR_FAILED_TO_LOCATE_MEDIA_INFO_PAGE)
  else if not DownloadPage(Http, 'http://veehd.com' + Url, InfoPage) then
    SetLastErrorMsg(ERR_FAILED_TO_DOWNLOAD_MEDIA_INFO_PAGE)
  else if not GetRegExpVar(MovieUrlRegExp, InfoPage, 'URL', Url) then
    SetLastErrorMsg(ERR_FAILED_TO_LOCATE_MEDIA_URL)
  else
    begin
    MovieUrl := UrlDecode(Url);
    SetPrepared(True);
    Result := True;
    end;
end;

initialization
  RegisterDownloader(TDownloader_VeeHD);

end.
