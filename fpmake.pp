// ###########################################################
// #### LightStrings - stack-based string handling for Free Pascal
// ####
// #### Copyright 2026 Eudox67. All rights reserved.
// #### Licensed under the MIT License - see LICENSE.
// ###########################################################
program fpmake;

{$mode objfpc}{$H+}

uses
{$ifdef unix}
  cthreads,
{$endif}
  fpmkunit;

var
  P: TPackage;
begin
  with Installer do
  begin
    P := AddPackage('lightstrings');
    P.Version := '1.0.0';
    P.Author := 'LightStrings Contributors';
    P.License := 'MIT';
    P.Description := 'Lightweight stack-based string handling for Free Pascal';

    P.OSes := [linux, win32, win64, darwin];
    P.CPUs := [x86_64, i386, aarch64];

    // SourcePath locates the files named in AddUnit; UnitPath feeds -Fu
    // and IncludePath feeds -Fi for the shared *.inc files.
    P.SourcePath.Add('src');
    P.UnitPath.Add('src');
    P.IncludePath.Add('src');

    // The units declare {$mode objfpc} themselves; stating it keeps the
    // package build identical to a hand-written fpc invocation.
    P.Options.Add('-Mobjfpc');

    // fpmkunit injects an implicit dependency on the "rtl" package, which
    // needs a per-package unit-config file (<unitdir>/rtl/rtl.fpc) that
    // many FPC installs do not ship; the lookup then aborts with
    //   Could not find unit directory for dependency package "rtl"
    // The compiler already knows where its own RTL is, so the dependency
    // is dropped and this package needs no external resolution.
    P.Dependencies.Clear;

    P.Targets.AddUnit('LightStrings.pas');
    P.Targets.AddUnit('LightStringsUtils.pas');

    Run;
  end;
end.
