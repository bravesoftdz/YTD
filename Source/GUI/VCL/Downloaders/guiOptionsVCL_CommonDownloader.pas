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

unit guiOptionsVCL_CommonDownloader;
{$INCLUDE 'ytd.inc'}

interface

uses
  {$ifdef mswindows}
    Windows,
  {$ELSE}
    LCLIntf, LCLType, LMessages,
  {$ENDIF}

  Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls,
  uDownloader, uOptions, guiOptionsVCL_Downloader;

type
  TFrameDownloaderOptionsPageCommon = class(TFrameDownloaderOptionsPage)
    PanelCommonOptions: TPanel;
    PanelSpecificOptions: TPanel;
    CheckDownloadSubtitles: TCheckBox;
    CheckConvertSubtitles: TCheckBox;
    CheckLiveStream: TCheckBox;
    LabelSecureToken: TLabel;
    EditSecureToken: TEdit;
    LabelUserName: TLabel;
    EditUserName: TEdit;
    LabelPassword: TLabel;
    EditPassword: TEdit;
    CheckRealtime: TCheckBox;
  private
    fDownloaderClass: TDownloaderClass;
  protected
    function GetProvider: string; override;
    function Supports(Feature: TDownloaderFeature): boolean; overload;
    function Supports(Feature: TDownloaderFeature; const Controls: array of TControl): boolean; overload;
    function Supports(Feature: TDownloaderFeature; const Controls: array of TControl; Hide: boolean): boolean; overload;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure LoadFromOptions; override;
    procedure SaveToOptions; override;
    property DownloaderClass: TDownloaderClass read fDownloaderClass write fDownloaderClass;
  end;

implementation

{$R *.dfm}

uses
  uCommonDownloader;

{ TFrameDownloaderOptionsPageCommon }

constructor TFrameDownloaderOptionsPageCommon.Create(AOwner: TComponent);
begin
  inherited;
  {$IFNDEF SUBTITLES}
  CheckDownloadSubtitles.Enabled := False;
  CheckConvertSubtitles.Enabled := False;
  {$ENDIF}
end;

destructor TFrameDownloaderOptionsPageCommon.Destroy;
begin
  inherited;
end;

function TFrameDownloaderOptionsPageCommon.GetProvider: string;
begin
  if DownloaderClass <> nil then
    Result := DownloaderClass.Provider
  else
    Result := inherited GetProvider;
end;

function TFrameDownloaderOptionsPageCommon.Supports(Feature: TDownloaderFeature): boolean;
begin
  Result := False;
  if DownloaderClass <> nil then
    if Feature in DownloaderClass.Features then
      Result := True;
end;

function TFrameDownloaderOptionsPageCommon.Supports(Feature: TDownloaderFeature; const Controls: array of TControl): boolean;
begin
  Result := Supports(Feature, Controls, False);
end;

function TFrameDownloaderOptionsPageCommon.Supports(Feature: TDownloaderFeature; const Controls: array of TControl; Hide: boolean): boolean;
var i: integer;
begin
  Result := Supports(Feature);
  if not Result then
    for i := 0 to Pred(Length(Controls)) do
      if Hide then
        Controls[i].Visible := False
      else
        Controls[i].Enabled := False;
end;

procedure TFrameDownloaderOptionsPageCommon.LoadFromOptions;
begin
  inherited;
  {$IFDEF SUBTITLES}
  if Supports(dfSubtitles, [CheckDownloadSubtitles, CheckConvertSubtitles]) then
    begin
    CheckDownloadSubtitles.Checked := Options.ReadProviderOptionDef(Provider, OPTION_COMMONDOWNLOADER_SUBTITLESENABLED, True);
    if Supports(dfSubtitlesConvert, [CheckConvertSubtitles]) then
      CheckConvertSubtitles.Checked := Options.ReadProviderOptionDef(Provider, OPTION_COMMONDOWNLOADER_CONVERTSUBTITLES, OPTION_COMMONDOWNLOADER_CONVERTSUBTITLES_DEFAULT);
    end;
  {$ENDIF}
  if Supports(dfRtmpLiveStream, [CheckLiveStream]) then
    CheckLiveStream.Checked := Options.ReadProviderOptionDef(Provider, OPTION_COMMONDOWNLOADER_RTMPLIVESTREAM, dfPreferRtmpLiveStream in DownloaderClass.Features);
  if Supports(dfRtmpRealtime, [CheckRealtime]) then
    CheckRealtime.Checked := Options.ReadProviderOptionDef(Provider, OPTION_COMMONDOWNLOADER_RTMPREALTIME, dfPreferRtmpRealtime in DownloaderClass.Features);
  if Supports(dfRequireSecureToken, [LabelSecureToken, EditSecureToken]) or Supports(dfAcceptSecureToken, [LabelSecureToken, EditSecureToken]) then
    EditSecureToken.Text := Options.ReadProviderOptionDef(Provider, OPTION_COMMONDOWNLOADER_SECURETOKEN, '');
  if Supports(dfUserLogin, [LabelUserName, EditUserName, LabelPassword, EditPassword]) then
    begin
    EditUserName.Text := Options.ReadProviderOptionDef(Provider, OPTION_COMMONDOWNLOADER_USERNAME, '');
    EditPassword.Text := Options.ReadProviderOptionDef(Provider, OPTION_COMMONDOWNLOADER_PASSWORD, '');
    end;
end;

procedure TFrameDownloaderOptionsPageCommon.SaveToOptions;
begin
  inherited;
  {$IFDEF SUBTITLES}
  if Supports(dfSubtitles) then
    begin
    Options.WriteProviderOption(Provider, OPTION_COMMONDOWNLOADER_SUBTITLESENABLED, CheckDownloadSubtitles.Checked);
    if Supports(dfSubtitlesConvert) then
      Options.WriteProviderOption(Provider, OPTION_COMMONDOWNLOADER_CONVERTSUBTITLES, CheckConvertSubtitles.Checked);
    end;
  {$ENDIF}
  if Supports(dfRtmpLiveStream) then
    Options.WriteProviderOption(Provider, OPTION_COMMONDOWNLOADER_RTMPLIVESTREAM, CheckLiveStream.Checked);
  if Supports(dfRtmpRealtime) then
    Options.WriteProviderOption(Provider, OPTION_COMMONDOWNLOADER_RTMPREALTIME, CheckRealtime.Checked);
  if Supports(dfRequireSecureToken) or Supports(dfAcceptSecureToken) then
    Options.WriteProviderOption(Provider, OPTION_COMMONDOWNLOADER_SECURETOKEN, EditSecureToken.Text);
  if Supports(dfUserLogin) then
    begin
    Options.WriteProviderOption(Provider, OPTION_COMMONDOWNLOADER_USERNAME, EditUserName.Text);
    Options.WriteProviderOption(Provider, OPTION_COMMONDOWNLOADER_PASSWORD, EditPassword.Text);
    end;
end;

end.
