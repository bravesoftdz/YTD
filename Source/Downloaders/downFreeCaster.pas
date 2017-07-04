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

unit downFreeCaster;
{$INCLUDE 'ytd.inc'}

interface

uses
  SysUtils, Classes,
  uPCRE, uXml, HttpSend,
  uDownloader, uCommonDownloader, uHttpDownloader;

type
  TDownloader_FreeCaster = class(THttpDownloader)
    private
    protected
      StreamIdRegExp: TRegExp;
    protected
      function GetMovieInfoUrl: string; override;
      function GetMediaInfoFromPage(const Page: string; Http: THttpSend; out Title: string; out Url: string): boolean;
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
  uHttpDirectDownloader,
  uRtmpDirectDownloader,
  uDownloadClassifier,
  uMessages;

// http://freecaster.tv/freeski/1012253
const
  URLREGEXP_BEFORE_ID = '^https?://(?:[a-z0-9-]+\.)*freecaster\.tv/';
  URLREGEXP_ID =        '[^/]+/[0-9]+';
  URLREGEXP_AFTER_ID =  '';

const
  REGEXP_STREAM_ID = '<param\s+name="flashvars"\s+value="(?:[^"]*?&amp;)*id=(?P<ID>[^&"]+)';

type
  TDownloader_FreeCaster_HTTP = class(THttpDirectDownloader);
  TDownloader_FreeCaster_RTMP = class(TRtmpDirectDownloader);

{ TDownloader_FreeCaster }

class function TDownloader_FreeCaster.Provider: string;
begin
  Result := 'FreeCaster.tv';
end;

class function TDownloader_FreeCaster.UrlRegExp: string;
begin
  Result := Format(URLREGEXP_BEFORE_ID + '(?P<%s>' + URLREGEXP_ID + ')' + URLREGEXP_AFTER_ID, [MovieIDParamName]);;
end;

constructor TDownloader_FreeCaster.Create(const AMovieID: string);
begin
  inherited;
  InfoPageEncoding := peUnknown;
  StreamIdRegExp := RegExCreate(REGEXP_STREAM_ID);
end;

destructor TDownloader_FreeCaster.Destroy;
begin
  RegExFreeAndNil(StreamIdRegExp);
  inherited;
end;

function TDownloader_FreeCaster.GetMovieInfoUrl: string;
begin
  Result := 'http://freecaster.tv/' + MovieID;
end;

function TDownloader_FreeCaster.GetMediaInfoFromPage(const Page: string; Http: THttpSend; out Title, Url: string): boolean;
var StreamID, BaseUrl, BestUrl, sUrl, sBitrate, sQuality: string;
    BestBitrate, Bitrate, i: integer;
    Xml: TXmlDoc;
    Node: TXmlNode;
begin
  Result := False;
  if not GetRegExpVar(StreamIdRegExp, Page, 'ID', StreamID) then
    SetLastErrorMsg(ERR_FAILED_TO_LOCATE_MEDIA_INFO_PAGE)
  else if not DownloadXml(Http, 'http://freecaster.tv/player/info/' + StreamID, Xml) then
    SetLastErrorMsg(ERR_FAILED_TO_DOWNLOAD_MEDIA_INFO_PAGE)
  else
    try
      if not Xml.NodeByPath('streams', Node) then
        SetLastErrorMsg(ERR_INVALID_MEDIA_INFO_PAGE)
      else if not GetXmlAttr(Node, '', 'server', BaseUrl) then
        SetLastErrorMsg(ERR_FAILED_TO_LOCATE_MEDIA_SERVER)
      else if not GetXmlVar(Xml, 'video/title', Title) then
        SetLastErrorMsg(ERR_FAILED_TO_LOCATE_MEDIA_TITLE)
      else
        begin
        BestUrl := '';
        BestBitrate := -1;
        for i := 0 to Pred(Node.NodeCount) do
          if Node.Nodes[i].Name = 'stream' then
            if GetXmlVar(Node.Nodes[i], '', sUrl) then
              begin
              Bitrate := 0;
              if GetXmlAttr(Node.Nodes[i], '', 'bitrate', sBitrate) then
                Bitrate := StrToIntDef(sBitrate, 0)
              else if GetXmlAttr(Node.Nodes[i], '', 'quality', sQuality) then
                if sQuality = 'LD' then
                  Bitrate := 1
                else if sQuality = 'SD' then
                  Bitrate := 10
                else if sQuality = 'HD' then
                  Bitrate := 1200;
              if BestBitrate < Bitrate then
                begin
                BestBitrate := Bitrate;
                BestUrl := sUrl;
                end;
              end;
        if BestUrl = '' then
          SetLastErrorMsg(ERR_FAILED_TO_LOCATE_MEDIA_URL)
        else
          begin
          Url := BaseUrl + BestUrl;
          Result := True;
          end;
        end;
    finally
      Xml.Free;
      end;
end;

function TDownloader_FreeCaster.AfterPrepareFromPage(var Page: string; PageXml: TXmlDoc; Http: THttpSend): boolean;
var Title, Url: string;
begin
  inherited AfterPrepareFromPage(Page, PageXml, Http);
  Result := False;
  if GetMediaInfoFromPage(Page, Http, Title, Url) then
      begin
      Name := Title;
      MovieUrl := Url;
      SetPrepared(True);
      Result := True;
      end;
end;

initialization
  RegisterDownloader(TDownloader_FreeCaster);

end.
