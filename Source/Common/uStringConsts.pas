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

unit uStringConsts;
{$INCLUDE 'YTD.inc'}

interface

const
  REGEXP_BASE_URL = '%s(?P<%s>%s)%s';
  REGEXP_COMMON_URL_PREFIX = '^https?://(?:[a-z0-9-]+\.)*';
  REGEXP_COMMON_URL = REGEXP_COMMON_URL_PREFIX + REGEXP_BASE_URL;
    // Protocol HTTP or HTTPS, any number of subdomains, pre-ID, downloader class, ID, post-ID
  REGEXP_ANYTHING = '.*';
  REGEXP_SOMETHING = '.+';
  REGEXP_NUMBERS = '[0-9]+';
  REGEXP_PATH_COMPONENT = '[^/?&]+';
  REGEXP_PARAM_COMPONENT = '[^&]+';

  // Common regular expressions for getting Title
  REGEXP_TITLE_TITLE = '<title>\s*(?P<TITLE>.*?)\s*</title>';
  REGEXP_TITLE_A_CLASS = '<a\s+[^>]*\bclass="%s">\s*(?P<TITLE>.*?)\s*</a>';
  REGEXP_TITLE_DIV_CLASS = '<div\s+[^>]*\bclass="%s">\s*(?P<TITLE>.*?)\s*</div>';
  REGEXP_TITLE_SPAN_CLASS = '<span\s+[^>]*\bclass="%s">\s*(?P<TITLE>.*?)\s*</span>';
  REGEXP_TITLE_META_TITLE = '<meta\s+name="title"\s+content="\s*(?P<TITLE>.*?)\s*"';
  REGEXP_TITLE_META_OGTITLE = '<meta\s+(?:property|name)="og:title"\s+content="\s*(?P<TITLE>.*?)\s*"';
  REGEXP_TITLE_META_DESCRIPTION = '<meta\s+name="description"\s+content="\s*(?P<TITLE>.*?)\s*"';
  REGEXP_TITLE_H1 = '<h1[^>]*>\s*(?P<TITLE>.*?)\s*</h1>';
  REGEXP_TITLE_H1_CLASS = '<h1\s+class="%s">\s*(?P<TITLE>.*?)\s*</h1>';
  REGEXP_TITLE_H2 = '<h2[^>]*>\s*(?P<TITLE>.*?)\s*</h2>';
  REGEXP_TITLE_H2_CLASS = '<h2\s+class="%s">\s*(?P<TITLE>.*?)\s*</h2>';
  REGEXP_TITLE_H3 = '<h3[^>]*>\s*(?P<TITLE>.*?)\s*</h3>';
  REGEXP_TITLE_H3_CLASS = '<h3\s+class="%s">\s*(?P<TITLE>.*?)\s*</h3>';

  // Common regular expressions for getting Url
  REGEXP_URL_EMBED_SRC = '<embed\s[^>]*\bsrc="(?P<URL>https?://.+?)"';
  REGEXP_URL_IFRAME_SRC = '<iframe\s[^>]*\bsrc="(?P<URL>https?://.+?)"';
  REGEXP_URL_VIDEO_SRC = '<video\s[^>]*\bsrc="(?P<URL>https?://.+?)"';
  REGEXP_URL_VIDEO_SOURCE_SRC = '<video\b.*?<source\s[^>]*\bsrc="(?P<URL>https?://.+?)"';
  REGEXP_URL_META_OGVIDEO = '<meta\s+(?:property|name)="og:video"\s+content="(?P<URL>.+?)"';
  REGEXP_URL_EMBED_FLASHVARS_FILE = '<embed\b[^>]*\sflashvars="(?:[^"]*?&(?:amp;|#038;)?)*?file=(?P<URL>https?://.+?)(?:"|&amp;|&)';
  REGEXP_URL_PARAM_MOVIE = '<param\s+name\s*=\s*"movie"[^>]*\s+value="(?P<URL>.+?)"';
  REGEXP_URL_PARAM_FLASHVARS_OPTIONS = '<param\s+name="FlashVars"\s+value="options=(?P<URL>https?://.+?)"';
  REGEXP_URL_PARAM_FLASHVARS_FILE = '<param\s+name="FlashVars"\s+value="(?:[^"]*?&(?:amp;|#038;)?)*?file=(?P<URL>https?://.+?)(?:"|&amp;|&)';
  REGEXP_URL_LINK_VIDEOSRC = '<link\s+rel="video_src"\s+href="(?P<URL>https?://.+?)"';
  REGEXP_URL_ADDVARIABLE_FILE = '\.addVariable\s*\(\s*(?P<QUOTE1>[''"])file(?P=QUOTE1)\s*,\s*(?P<QUOTE2>[''"])(?P<URL>https?://.+?)(?P=QUOTE2)';
  REGEXP_URL_ADDVARIABLE_FILE_RELATIVE = '\.addVariable\s*\(\s*(?P<QUOTE1>[''"])file(?P=QUOTE1)\s*,\s*(?P<QUOTE2>[''"])(?P<URL>.+?)(?P=QUOTE2)';
  REGEXP_URL_ADDPARAM_FLASHVARS_FILE = '\.addParam\s*\(\s*(?P<QUOTE1>[''"])flashvars(?P=QUOTE1)\s*,\s*(?P<QUOTE2>[''"])(?:[^"'']*(?:&amp;|&))*file=(?P<URL>https?://.+?)(?:&amp;|[&"''])';
  REGEXP_URL_FILE_COLON_VALUE = '(?P<QUOTE1>[''"])file(?P=QUOTE1)\s*:\s*(?P<QUOTE2>[''"])(?P<URL>(?:https?|mmsh?)://.+?)(?P=QUOTE2)';

  REGEXP_FLASHVARS = '<param\s+name="flashvars"\s+value="(?P<FLASHVARS>.*?)"';
  REGEXP_FLASHVARS_JS = '\bvar\s+flashvars\s*=\s*\{(?P<FLASHVARS>.+?)\}\s*;';
  REGEXP_PARSER_FLASHVARS_JS = '(?P<QUOTE1>[''"]?)(?P<VARNAME>\w+)(?P=QUOTE1)\s*:\s*(?P<QUOTE2>[''"]?)(?P<VARVALUE>.*?)(?P=QUOTE2)\s*(?:,|$)';
  REGEXP_PARSER_HTMLVARS = '(?:^|&amp;|&)(?P<VARNAME>[^=]+?)(?:=(?P<VARVALUE>.*?))?(?=$|&amp;|&)';

  HTTP_FORM_URLENCODING = 'application/x-www-form-urlencoded';
  HTTP_FORM_URLENCODING_UTF8 = HTTP_FORM_URLENCODING + '; charset=UTF-8';
  HTTP_SOAP_ENCODING = 'text/xml; charset=utf-8';

  URL_QUERY_VARS = '[?&](?P<VARNAME>[^=]+)=(?P<VARVALUE>[^&]*)';

  FLASH_DEFAULT_VERSION = 'WIN 10,1,82,76';

  INVALID_FILENAME_CHARS = '\/:*?"<>|'#9#10#13;
  INVALID_FILENAME_CHARS_REPLACEMENTS = '--;..''--!   ';

implementation

end.
