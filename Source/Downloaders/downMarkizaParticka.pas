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

unit downMarkizaParticka;
{$INCLUDE 'ytd.inc'}

interface

uses
  SysUtils, Classes,
  uPCRE, uXml, HttpSend,
  uDownloader, uCommonDownloader, uHttpDownloader;

type
  TDownloader_Markiza_Particka = class(THttpDownloader)
    private
    protected
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
  {$IFDEF JSON}
  uJSON,
  {$ENDIF}
  uDownloadClassifier,
  uMessages;

// http://particka.markiza.sk/archiv.php?vid=65598
const
  URLREGEXP_BEFORE_ID = '^https?://(?:[a-z0-9-]+\.)*particka\.markiza\.sk/archiv\.php\?(?:.*?&)?vid=';
  URLREGEXP_ID =        '[0-9]+';
  URLREGEXP_AFTER_ID =  '';

{ TDownloader_Markiza_Particka }

class function TDownloader_Markiza_Particka.Provider: string;
begin
  Result := 'Markiza.sk';
end;

class function TDownloader_Markiza_Particka.UrlRegExp: string;
begin
  Result := Format(URLREGEXP_BEFORE_ID + '(?P<%s>' + URLREGEXP_ID + ')' + URLREGEXP_AFTER_ID, [MovieIDParamName]);;
end;

constructor TDownloader_Markiza_Particka.Create(const AMovieID: string);
begin
  inherited;
  InfoPageIsXml := True;
end;

destructor TDownloader_Markiza_Particka.Destroy;
begin
  inherited;
end;

function TDownloader_Markiza_Particka.GetMovieInfoUrl: string;
begin
  Result := 'http://particka.markiza.sk/xml/video/parts_flowplayer.rss?ID_entity=' + MovieID;
end;

function TDownloader_Markiza_Particka.AfterPrepareFromPage(var Page: string; PageXml: TXmlDoc; Http: THttpSend): boolean;
var
  Title, Url: string;
  ChannelNode: TXmlNode;
  i: integer;
  {$IFDEF MULTIDOWNLOADS}
  n: integer;
  {$ENDIF}
begin
  inherited AfterPrepareFromPage(Page, PageXml, Http);
  Result := False;
  if not XmlNodeByPath(PageXml, 'channel', ChannelNode) then
    SetLastErrorMsg(ERR_FAILED_TO_LOCATE_MEDIA_INFO)
  else if not GetXmlVar(ChannelNode, 'title', Title) then
    SetLastErrorMsg(ERR_FAILED_TO_LOCATE_MEDIA_TITLE)
  else
    begin
    {$IFDEF MULTIDOWNLOADS}
    n := 1;
    {$ENDIF}
    for i := 0 to Pred(ChannelNode.NodeCount) do
      if ChannelNode[i].Name = 'item' then
        if GetXmlAttr(ChannelNode[i], 'media:content', 'url', Url) then
          begin
          {$IFDEF MULTIDOWNLOADS}
          NameList.Add(Format('%s (%d)', [Title, n]));
          UrlList.Add(Url);
          Inc(n);
          {$ELSE}
          Name := Title;
          MovieUrl := Url;
          SetPrepared(True);
          Result := True;
          Exit;
          {$ENDIF}
          end;
    {$IFDEF MULTIDOWNLOADS}
    if UrlList.Count > 0 then
      begin
      SetPrepared(True);
      Result := First;
      end;
    {$ENDIF}
    end;
end;

initialization
  RegisterDownloader(TDownloader_Markiza_Particka);

end.
