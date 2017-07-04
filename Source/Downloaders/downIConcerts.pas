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

unit downiConcerts;
{$INCLUDE 'ytd.inc'}

interface

uses
  SysUtils, Classes,
  uPCRE, uXml, HttpSend,
  uDownloader, uCommonDownloader, uRtmpDownloader;

type
  TDownloader_iConcerts = class(TRtmpDownloader)
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

// http://www.i-concerts.com/#/?q=en/concert/black-kids-nme-awards-shows-en
const
  URLREGEXP_BEFORE_ID = '^https?://(?:[a-z0-9-]+\.)*i-concerts\.com/.*[?&]q=';
  URLREGEXP_ID =        '[^#]+';
  URLREGEXP_AFTER_ID =  '';

const
  REGEXP_EXTRACT_TITLE = '<h1[^>]*>(?P<TITLE>.*?)</h1>';
  REGEXP_EXTRACT_URL = '\.addVariable\s*\(\s*''file''\s*,\s*''(?P<URL>.+?)''';

{ TDownloader_iConcerts }

class function TDownloader_iConcerts.Provider: string;
begin
  Result := 'iConcerts.com';
end;

class function TDownloader_iConcerts.UrlRegExp: string;
begin
  Result := Format(URLREGEXP_BEFORE_ID + '(?P<%s>' + URLREGEXP_ID + ')' + URLREGEXP_AFTER_ID, [MovieIDParamName]);;
end;

constructor TDownloader_iConcerts.Create(const AMovieID: string);
begin
  inherited Create(AMovieID);
  InfoPageEncoding := peUtf8;
  MovieTitleRegExp := RegExCreate(REGEXP_EXTRACT_TITLE);
  MovieUrlRegExp := RegExCreate(REGEXP_EXTRACT_URL);
end;

destructor TDownloader_iConcerts.Destroy;
begin
  RegExFreeAndNil(MovieTitleRegExp);
  RegExFreeAndNil(MovieUrlRegExp);
  inherited;
end;

function TDownloader_iConcerts.GetMovieInfoUrl: string;
begin
  Result := 'http://www.i-concerts.com/index2.php?q=' + MovieID;
end;

function TDownloader_iConcerts.AfterPrepareFromPage(var Page: string; PageXml: TXmlDoc; Http: THttpSend): boolean;
begin
  inherited AfterPrepareFromPage(Page, PageXml, Http);
  Result := False;
  if MovieUrl <> '' then
    begin
    MovieUrl := 'rtmp://iconcerts.infomaniak.ch/icpreview/' + MovieUrl;
    Self.RtmpUrl := MovieUrl;
    SetPrepared(True);
    Result := True;
    end;
end;

initialization
  RegisterDownloader(TDownloader_iConcerts);

end.
