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
