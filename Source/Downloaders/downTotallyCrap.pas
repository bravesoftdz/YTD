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

unit downTotallyCrap;
{$INCLUDE 'ytd.inc'}
{.$DEFINE USE_RTMP}

interface

uses
  SysUtils, Classes,
  uPCRE, uXml, HttpSend,
  uDownloader, uCommonDownloader, {$IFDEF USE_RTMP} uRtmpDownloader {$ELSE} uHttpDownloader {$ENDIF} ;

type
  TDownloader_TotallyCrap = class( {$IFDEF USE_RTMP} TRtmpDownloader {$ELSE} THttpDownloader {$ENDIF} )
    private
    protected
      InfoUrlRegExp: TRegExp;
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

// http://www.totallycrap.com/videos/videos_man_tries_to_commit_suicide_by_laying_under_a_truck/
const
  URLREGEXP_BEFORE_ID = '^https?://(?:[a-z0-9-]+\.)*totallycrap\.com/videos/videos_';
  URLREGEXP_ID =        '[^/?&]+';
  URLREGEXP_AFTER_ID =  '';

const
  REGEXP_MOVIE_TITLE = '<h2>(?P<TITLE>.*?)</h2>';
  REGEXP_INFO_URL = '\bso\.addVariable\s*\(\s*''config''\s*,\s*''(?P<URL>https?://.+?)''';

{ TDownloader_TotallyCrap }

class function TDownloader_TotallyCrap.Provider: string;
begin
  Result := 'TotallyCrap.com';
end;

class function TDownloader_TotallyCrap.UrlRegExp: string;
begin
  Result := Format(URLREGEXP_BEFORE_ID + '(?P<%s>' + URLREGEXP_ID + ')' + URLREGEXP_AFTER_ID, [MovieIDParamName]);;
end;

constructor TDownloader_TotallyCrap.Create(const AMovieID: string);
begin
  inherited;
  InfoPageEncoding := peUtf8;
  MovieTitleRegExp := RegExCreate(REGEXP_MOVIE_TITLE);
  InfoUrlRegExp := RegExCreate(REGEXP_INFO_URL);
end;

destructor TDownloader_TotallyCrap.Destroy;
begin
  RegExFreeAndNil(MovieTitleRegExp);
  RegExFreeAndNil(InfoUrlRegExp);
  inherited;
end;

function TDownloader_TotallyCrap.GetMovieInfoUrl: string;
begin
  Result := 'http://www.totallycrap.com/videos/videos_' + MovieID + '/';
end;

function TDownloader_TotallyCrap.AfterPrepareFromPage(var Page: string; PageXml: TXmlDoc; Http: THttpSend): boolean;
var Url, {$IFDEF USE_RTMP} BasePath, {$ENDIF} PlayPath: string;
    Xml: TXmlDoc;
begin
  inherited AfterPrepareFromPage(Page, PageXml, Http);
  Result := False;
  if not GetRegExpVar(InfoUrlRegExp, Page, 'URL', Url) then
    SetLastErrorMsg(ERR_FAILED_TO_LOCATE_MEDIA_INFO_PAGE)
  else if not DownloadXml(Http, Url, Xml) then
    SetLastErrorMsg(ERR_FAILED_TO_DOWNLOAD_MEDIA_INFO_PAGE)
  else
    try
      {$IFDEF USE_RTMP}
      if not GetXmlVar(Xml, 'streamer', BasePath) then
        SetLastErrorMsg(ERR_INVALID_MEDIA_INFO_PAGE)
      else
      {$ENDIF}
      if not GetXmlVar(Xml, 'file', PlayPath) then
        SetLastErrorMsg(ERR_INVALID_MEDIA_INFO_PAGE)
      else
        begin
        {$IFDEF USE_RTMP}
        MovieUrl := BasePath + '/mp4:' + PlayPath;
        AddRtmpDumpOption('r', MovieURL);
        AddRtmpDumpOption('y', 'mp4:' + PlayPath);
        {$ELSE}
        MovieUrl := PlayPath;
        {$ENDIF}
        Result := True;
        SetPrepared(True);
        end;
    finally
      Xml.Free;
      end;
end;

initialization
  RegisterDownloader(TDownloader_TotallyCrap);

end.
