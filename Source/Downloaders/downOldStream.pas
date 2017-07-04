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

unit downOldStream;
{$INCLUDE 'ytd.inc'}
{.DEFINE XMLINFO}

interface

uses
  SysUtils, Classes, Windows,
  uPCRE, uXml, HttpSend,
  uDownloader, uCommonDownloader, uHttpDownloader, uHttpDirectDownloader;

type
  TDownloader_Stream_Old = class(THttpDownloader)
    private
    protected
      MovieParamsRegExp: TRegExp;
      FlashVarsParserRegExp: TRegExp;
      ExternalCDNID: string;
    protected
      function GetMovieInfoUrlForID(const ID: string): string; virtual;
      function GetFlashVarsIdStrings(out ID, cdnLQ, cdnHQ, cdnHD, Title: string): boolean; virtual;
    protected
      function GetMovieInfoUrl: string; override;
      function AfterPrepareFromPage(var Page: string; PageXml: TXmlDoc; Http: THttpSend): boolean; override;
    public
      class function Provider: string; override;
      class function UrlRegExp: string; override;
      constructor Create(const AMovieID: string); override;
      destructor Destroy; override;
      function Prepare: boolean; override;
    end;

  TDownloader_Stream_Old_Cache = class(THttpDirectDownloader)
    private
    protected
    public
      class function Provider: string; override;
      class function UrlRegExp: string; override;
    end;

implementation

uses
  uStringConsts,
  {$IFDEF XMLINFO}
  uXML,
  {$ENDIF}
  uDownloadClassifier,
  uMessages;

// http://old.stream.cz/uservideo/79233-serial-recepty-nasich-prababicek-3-dil-trnkova-omacka
const
  URLREGEXP_BEFORE_ID = 'old\.stream\.cz/';
  URLREGEXP_ID =        REGEXP_SOMETHING;
  URLREGEXP_AFTER_ID =  '';

const
  DIRECTURLREGEXP_BEFORE_ID = '^';
  DIRECTURLREGEXP_ID =        'https?://(?:[a-z0-9-]+\.)*cdn-cache[^.]+\.stream\.cz/.+';
  DIRECTURLREGEXP_AFTER_ID =  '';

const
  REGEXP_MOVIE_TITLE = '<title>(?P<TITLE>.*?)(?:\s*\|[^<]*)?</title>';
  REGEXP_MOVIE_PARAMS = '<param\s+name="flashvars"\s+value="(?P<PARAM>.+?)"';
  REGEXP_FLASHVARS_PARSER = '(?<=^|&amp;|&)(?P<VARNAME>.+?)=(?P<VARVALUE>.*?)(?:&amp;|&|$)';

{ TDownloader_Stream_Old }

class function TDownloader_Stream_Old.Provider: string;
begin
  Result := 'Stream.cz';
end;

class function TDownloader_Stream_Old.UrlRegExp: string;
begin
  Result := Format(REGEXP_COMMON_URL, [URLREGEXP_BEFORE_ID, MovieIDParamName, URLREGEXP_ID, URLREGEXP_AFTER_ID]);
end;

constructor TDownloader_Stream_Old.Create(const AMovieID: string);
begin
  inherited Create(AMovieID);
  InfoPageEncoding := peUTF8;
  MovieTitleRegExp := RegExCreate(REGEXP_MOVIE_TITLE);
  MovieParamsRegExp := RegExCreate(REGEXP_MOVIE_PARAMS);
  FlashVarsParserRegExp := RegExCreate(REGEXP_FLASHVARS_PARSER);
end;

destructor TDownloader_Stream_Old.Destroy;
begin
  RegExFreeAndNil(MovieTitleRegExp);
  RegExFreeAndNil(MovieParamsRegExp);
  RegExFreeAndNil(FlashVarsParserRegExp);
  inherited;
end;

function TDownloader_Stream_Old.GetMovieInfoUrl: string;
begin
  Result := GetMovieInfoUrlForID(MovieID);
end;

function TDownloader_Stream_Old.GetMovieInfoUrlForID(const ID: string): string;
begin
  Result := 'http://old.stream.cz/' + ID;
end;

function TDownloader_Stream_Old.GetFlashVarsIdStrings(out ID, cdnLQ, cdnHQ, cdnHD, Title: string): boolean;
begin
  ID := 'id';
  cdnLQ := 'cdnLQ';
  cdnHQ := 'cdnHQ';
  cdnHD := 'cdnHD';
  Title := '';
  Result := True;
end;

function TDownloader_Stream_Old.AfterPrepareFromPage(var Page: string; PageXml: TXmlDoc; Http: THttpSend): boolean;
var {$IFDEF XMLINFO}
    Xml: TXmlDoc;
    TitleNode, ContentNode: TjanXmlNode2;
    {$ENDIF}
    Params, CdnID, CdnLQ, CdnHQ, CdnHD, ID, Title: string;
    AttrCdnID, AttrCdnLQ, AttrCdnHQ, AttrCdnHD, AttrTitle: string;
begin
  inherited AfterPrepareFromPage(Page, PageXml, Http);
  Result := False;
  Params := '';
  CdnID := '';
  if ExternalCDNID <> '' then
    CdnID := ExternalCDNID
  else
    begin
    if not GetRegExpVar(MovieParamsRegExp, Page, 'PARAM', Params) then
      SetLastErrorMsg(ERR_FAILED_TO_LOCATE_MEDIA_INFO)
    else if not GetFlashVarsIdStrings(AttrCdnID, AttrCdnLQ, AttrCdnHQ, AttrCdnHD, AttrTitle) then
      SetLastErrorMsg(ERR_FAILED_TO_LOCATE_MEDIA_INFO)
    else if not GetRegExpVarPairs(FlashVarsParserRegExp, Params,
                   [AttrCdnID, AttrCdnLQ, AttrCdnHQ, AttrCdnHD, AttrTitle],
                   [@ID,       @CdnLQ,    @CdnHQ,    @CdnHD,    @Title ])
    then
    //else if not GetRegExpVar(MovieCdnIdFromParamsRegExp, Params, 'ID', CdnID) then
      SetLastErrorMsg(ERR_FAILED_TO_LOCATE_MEDIA_URL)
    else
      begin
      if CdnHD <> '' then
        CdnID := CdnHD
      else if CdnHQ <> '' then
        CdnID := CdnHQ
      else if CdnLQ <> '' then
        CdnID := CdnLQ
      else
        begin
        CdnID := '';
        SetLastErrorMsg(ERR_FAILED_TO_LOCATE_MEDIA_URL);
        end;
      end;
    end;
  if CdnID <> '' then
    begin
    {$IFDEF XMLINFO}
    if GetRegExpVar(MovieIdFromParamsRegExp, Params, 'ID', ID) then
      try
        if DownloadXml(Http, 'http://flash.stream.cz/get_info/' + ID, Xml) then
          try
            if GetXmlVar(Xml, 'video/title', Title) then
              Name := Title;
          finally
            Xml.Free;
            end;
      except
        ;
        end;
    {$ENDIF}
    if DownloadPage(Http, 'http://cdn-dispatcher.stream.cz/?id=' + CdnID, hmHEAD) then
      begin
      if Title <> '' then
        Name := Title;
      MovieURL := LastUrl;
      Result := True;
      SetPrepared(True);
      end;
    end;
end;

function TDownloader_Stream_Old.Prepare: boolean;
begin
  ExternalCDNID := '';
  Result := inherited Prepare;
end;

{ TDownloader_Stream_Old_Cache }

class function TDownloader_Stream_Old_Cache.Provider: string;
begin
  Result := TDownloader_Stream_Old.Provider;
end;

class function TDownloader_Stream_Old_Cache.UrlRegExp: string;
begin
  Result := Format(DIRECTURLREGEXP_BEFORE_ID + '(?P<%s>' + DIRECTURLREGEXP_ID + ')' + DIRECTURLREGEXP_AFTER_ID, [MovieIDParamName]);
end;

initialization
  RegisterDownloader(TDownloader_Stream_Old_Cache);
  RegisterDownloader(TDownloader_Stream_Old);

end.
