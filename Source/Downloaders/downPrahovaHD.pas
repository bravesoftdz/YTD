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

unit downPrahovaHD;
{$INCLUDE 'ytd.inc'}
{.DEFINE LOW_QUALITY}

interface

uses
  SysUtils, Classes,
  {$ifdef mswindows}
    Windows,
  {$ELSE}
    LCLIntf, LCLType, LMessages,
  {$ENDIF}

  uPCRE, uXml, HttpSend,
  uDownloader, uCommonDownloader, uRtmpDownloader;

type
  TDownloader_PrahovaHD = class(TRtmpDownloader)
    private
    protected
      MovieVariablesRegExp: TRegExp;
    protected
      function GetMovieInfoUrl: string; override;
      function AfterPrepareFromPage(var Page: string; PageXml: TXmlDoc; Http: THttpSend): boolean; override;
    public
      class function Provider: string; override;
      class function Features: TDownloaderFeatures; override;
      class function UrlRegExp: string; override;
      constructor Create(const AMovieID: string); override;
      destructor Destroy; override;
    end;

implementation

uses
  uStringConsts,
  uDownloadClassifier,
  uMessages;

// http://live.prahovahd.ro/playondemand.php?server=193.238.58.18&playfile=food.mp4&subtitrare=http://live.prahovahd.ro/food.srt&categ=Documentare&subcateg=Film
const
  URLREGEXP_BEFORE_ID = '^https?://(?:[a-z0-9-]+\.)*live\.prahovahd\.ro/playondemand\.php';
  URLREGEXP_ID =        '.+';
  URLREGEXP_AFTER_ID =  '';

const
  REGEXP_MOVIE_VARIABLES = '\.addVariable\s*\(\s*''(?P<VARNAME>[^'']+)''\s*,\s*''(?P<VARVALUE>[^'']*)''';

{ TDownloader_PrahovaHD }

class function TDownloader_PrahovaHD.Provider: string;
begin
  Result := 'PrahovaHD.ro';
end;

class function TDownloader_PrahovaHD.Features: TDownloaderFeatures;
begin
  Result := inherited Features + [
    {$IFDEF SUBTITLES} dfSubtitles {$ENDIF}
    ];
end;

class function TDownloader_PrahovaHD.UrlRegExp: string;
begin
  Result := Format(URLREGEXP_BEFORE_ID + '(?P<%s>' + URLREGEXP_ID + ')' + URLREGEXP_AFTER_ID, [MovieIDParamName]);;
end;

constructor TDownloader_PrahovaHD.Create(const AMovieID: string);
begin
  inherited;
  InfoPageEncoding := peUTF8;
  MovieVariablesRegExp := RegExCreate(REGEXP_MOVIE_VARIABLES)
end;

destructor TDownloader_PrahovaHD.Destroy;
begin
  RegExFreeAndNil(MovieVariablesRegExp);
  inherited;
end;

function TDownloader_PrahovaHD.GetMovieInfoUrl: string;
begin
  Result := 'http://live.prahovahd.ro/playondemand.php' + MovieID;
end;

function TDownloader_PrahovaHD.AfterPrepareFromPage(var Page: string; PageXml: TXmlDoc; Http: THttpSend): boolean;
var Streamer, Location, Captions: string;
    Sub: AnsiString;
begin
  inherited AfterPrepareFromPage(Page, PageXml, Http);
  Result := False;
  GetRegExpVarPairs(MovieVariablesRegExp, Page, ['streamer', 'file', 'captions.file'], [@Streamer, @Location, @Captions]);
  if Streamer = '' then
    SetLastErrorMsg(ERR_FAILED_TO_LOCATE_MEDIA_URL)
  else if Location = '' then
    SetLastErrorMsg(ERR_FAILED_TO_LOCATE_MEDIA_URL)
  else
    begin
    {$IFDEF SUBTITLES}
    if SubtitlesEnabled then
      if Captions <> '' then
        if DownloadBinary(Http, Captions, Sub) then
          begin
          fSubtitles := Sub;
          fSubtitlesExt := ExtractUrlExt(Captions);
          end;
    {$ENDIF}
    Name := ChangeFileExt(Location, '');
    MovieUrl := Streamer + '/mp4:' + Location;
    Self.RtmpUrl := Streamer;
    Self.Playpath := 'mp4:' + Location;
    SetPrepared(True);
    Result := True;
    end;
end;

initialization
  RegisterDownloader(TDownloader_PrahovaHD);

end.
