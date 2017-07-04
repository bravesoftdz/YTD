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

unit downMediaSport;
{$INCLUDE 'ytd.inc'}

interface

uses
  SysUtils, Classes,
  uPCRE, uXml, HttpSend, SynaUtil,
  uDownloader, uCommonDownloader, uHttpDownloader;

type
  TDownloader_MediaSport = class(THttpDownloader)
    private
    protected
      QualitiesRegExp: TRegExp;
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

// http://www.mediasport.cz/rally-cz/video/09_luzicke_cerny_rz1.html
const
  URLREGEXP_BEFORE_ID = 'mediasport\.cz/';
  URLREGEXP_ID =        REGEXP_SOMETHING;
  URLREGEXP_AFTER_ID =  '';

const
  REGEXP_EXTRACT_TITLE = REGEXP_TITLE_H1;
  REGEXP_EXTRACT_URL = REGEXP_URL_ADDVARIABLE_FILE_RELATIVE;
  REGEXP_QUALITIES = '(?:''|;)(?P<URL>/.+?);@@;(?P<QUALITY>\d+)p(?:''|;#@#)';

{ TDownloader_MediaSport }

class function TDownloader_MediaSport.Provider: string;
begin
  Result := 'MediaSport.cz';
end;

class function TDownloader_MediaSport.UrlRegExp: string;
begin
  Result := Format(REGEXP_COMMON_URL, [URLREGEXP_BEFORE_ID, MovieIDParamName, URLREGEXP_ID, URLREGEXP_AFTER_ID]);
end;

constructor TDownloader_MediaSport.Create(const AMovieID: string);
begin
  inherited Create(AMovieID);
  InfoPageEncoding := peUTF8;
  MovieTitleRegExp := RegExCreate(REGEXP_EXTRACT_TITLE);
  MovieUrlRegExp := RegExCreate(REGEXP_EXTRACT_URL);
  QualitiesRegExp := RegExCreate(REGEXP_QUALITIES);
end;

destructor TDownloader_MediaSport.Destroy;
begin
  RegExFreeAndNil(MovieTitleRegExp);
  RegExFreeAndNil(MovieUrlRegExp);
  RegExFreeAndNil(QualitiesRegExp);
  inherited;
end;

function TDownloader_MediaSport.GetMovieInfoUrl: string;
begin
  Result := 'http://www.mediasport.cz/' + MovieID;
end;

function TDownloader_MediaSport.AfterPrepareFromPage(var Page: string; PageXml: TXmlDoc; Http: THttpSend): boolean;
var
  Url, BestUrl, sQuality: string;
  Quality, BestQuality: integer;
begin
  Result := inherited AfterPrepareFromPage(Page, PageXml, Http);
  if Result then
    begin
    BestUrl := MovieUrl;
    BestQuality := -1;
    if QualitiesRegExp.Match(Page) then
      repeat
        if QualitiesRegExp.SubexpressionByName('URL', Url) then
          if QualitiesRegExp.SubexpressionByName('QUALITY', sQuality) then
            begin
            Quality := StrToIntDef(sQuality, 0);
            if Quality > BestQuality then
              begin
              BestUrl := Url;
              BestQuality := Quality;
              end;
            end;
      until not QualitiesRegExp.MatchAgain;
    MovieUrl := 'http://www.mediasport.cz' + BestUrl;
    end;
end;

function TDownloader_MediaSport.GetFileNameExt: string;
begin
  Result := '.mp4';
end;

initialization
  RegisterDownloader(TDownloader_MediaSport);

end.
