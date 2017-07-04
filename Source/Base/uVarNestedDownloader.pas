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

unit uVarNestedDownloader;
{$INCLUDE 'ytd.inc'}

interface

uses
  SysUtils, Classes,
  uPCRE, uXml, HttpSend, blcksock,
  uDownloader, uCommonDownloader, uNestedDownloader;

type
  TVarNestedDownloader = class(TNestedDownloader)
    private
    protected
      NestedUrlRegExps: array of TRegExp;
    protected
      procedure AddNestedUrlRegExps(const RegExps: array of string);
      procedure ClearNestedUrlRegExps;
      function AfterPrepareFromPage(var Page: string; PageXml: TXmlDoc; Http: THttpSend): boolean; override;
    public
      constructor Create(const AMovieID: string); override;
      destructor Destroy; override;
    end;

implementation

uses
  uMessages,
  uDownloadClassifier;

{ TVarNestedDownloader }

constructor TVarNestedDownloader.Create(const AMovieID: string);
begin
  inherited;
  SetLength(NestedUrlRegExps, 0);
end;

destructor TVarNestedDownloader.Destroy;
begin
  ClearNestedUrlRegExps;
  inherited;
end;

procedure TVarNestedDownloader.AddNestedUrlRegExps(const RegExps: array of string);
var i: integer;
begin
  SetLength(NestedUrlRegExps, Length(RegExps));
  for i := 0 to Pred(Length(RegExps)) do
    NestedUrlRegExps[i] := RegExCreate(RegExps[i]);
end;

procedure TVarNestedDownloader.ClearNestedUrlRegExps;
var i: integer;
begin
  for i := 0 to Pred(Length(NestedUrlRegExps)) do
    RegExFreeAndNil(NestedUrlRegExps[i]);
  SetLength(NestedUrlRegExps, 0);
end;

function TVarNestedDownloader.AfterPrepareFromPage(var Page: string; PageXml: TXmlDoc; Http: THttpSend): boolean;
var i: integer;
begin
  Result := False;
  try
    for i := 0 to Pred(Length(NestedUrlRegExps)) do
      begin
      NestedUrlRegExp := NestedUrlRegExps[i];
      if inherited AfterPrepareFromPage(Page, PageXml, Http) then
        begin
        Result := True;
        Break;
        end;
      end;
  finally
    NestedUrlRegExp := nil;
    end;
end;

end.
