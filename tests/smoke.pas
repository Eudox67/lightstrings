// ###########################################################
// #### LightStrings - stack-based string handling for Free Pascal
// ####
// #### Copyright 2026 Eudox67. All rights reserved.
// #### Licensed under the MIT License - see LICENSE.
// ###########################################################
program smoke;

{$mode objfpc}{$H+}

uses
  SysUtils, LightStrings, LightStringsUtils;

var
  B: TBuildStr;
  Parts: TStringArray;
begin
  B.Init;
  B.Append('hello');
  B.Append(' world');
  WriteLn('build: ', B.ToString);

  Parts := Split('a,b,c', ',');
  WriteLn('split: ', Length(Parts), ' -> ', Join(Parts, '+'));
  WriteLn('trim:  [', Trim('  x  '), ']');
  WriteLn('starts:', BeginsWith('lightstrings', 'light'));
end.
