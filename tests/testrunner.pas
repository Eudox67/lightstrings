// ###########################################################
// #### LightStrings - stack-based string handling for Free Pascal
// ####
// #### Copyright 2026 Eudox67. All rights reserved.
// #### Licensed under the MIT License - see LICENSE.
// ###########################################################
program testrunner;

{$mode objfpc}{$H+}

uses
  consoletestrunner, fpcunit,
  TestLightStrings;

type
  { TLightStringsTestRunner }
  TLightStringsTestRunner = class(TTestRunner)
  end;

var
  App: TLightStringsTestRunner;

begin
  DefaultRunAllTests := True;
  DefaultFormat := fplain;
  App := TLightStringsTestRunner.Create(nil);
  try
    App.Initialize;
    App.Title := 'LightStrings FPCUnit test runner';
    App.Run;
  finally
    App.Free;
  end;
end.
