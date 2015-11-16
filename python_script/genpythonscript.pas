{*******************************************************************************
  Copyright (C) Christian Ulrich info@cu-tec.de

  This source is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License as published by the Free
  Software Foundation; either version 2 of the License, or commercial alternative
  contact us for more information

  This code is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
  details.

  A copy of the GNU General Public License is available on the World Wide Web
  at <http://www.gnu.org/copyleft/gpl.html>. You can also obtain it by writing
  to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
  MA 02111-1307, USA.
Created 07.10.2015
*******************************************************************************}
unit genpythonscript;

//TODO:Debugging seems to be only over pdb possible wich could be used from script itself or as commandline tool

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Utils, genscript, PythonEngine;

type
  { TPythonScript }

  TPythonScript = class(TScript)
  private
    fEngine : TPythonEngine;
    fIO: TPythonInputOutput;
    FLines : TStringList;
    procedure fIOReceiveData(Sender: TObject; var Data: AnsiString);
    procedure fIOSendData(Sender: TObject; const Data: AnsiString);
  protected
    function GetTyp: string; override;
  public
    procedure Init; override;
    function IsRunning: Boolean; override;
    function GetStatus: TScriptStatus; override;
    function Stop: Boolean; override;
    function Execute(aParameters: Variant;Debug : Boolean = false): Boolean; override;
    destructor Destroy; override;
  end;

implementation

procedure TPythonScript.fIOReceiveData(Sender: TObject; var Data: AnsiString);
begin
  if Assigned(Readln) then
    Readln(Data);
end;

procedure TPythonScript.fIOSendData(Sender: TObject; const Data: AnsiString);
begin
  if Assigned(WriteLn) then
    WriteLn(Data);
end;

function TPythonScript.GetTyp: string;
begin
  Result := 'Python';
end;

procedure TPythonScript.Init;
begin
  FLines:=nil;
  fEngine := TPythonEngine.Create(nil);
  fIO := TPythonInputOutput.Create(nil);
  fIO.OnReceiveData:=@fIOReceiveData;
  fIO.OnSendData:=@fIOSendData;
  fEngine.IO := fIO;
  fEngine.RedirectIO:=True;
  fEngine.Initialize;
end;

function TPythonScript.IsRunning: Boolean;
begin
  Result:=Assigned(FLines);
end;

function TPythonScript.GetStatus: TScriptStatus;
begin
  if IsRunning then
    Result := ssRunning
  else Result := ssNone;
end;

function TPythonScript.Stop: Boolean;
begin
  if IsRunning then
    begin
      FreeAndNil(FLines);
      Result:=True;
    end;
end;

function TPythonScript.Execute(aParameters: Variant; Debug: Boolean): Boolean;
var
  aLine: Integer=0;
  aPosition : Integer=0;
  i: Integer;
begin
  Result := False;
  try
    if Debug then
      begin
        FLines := TStringList.Create;
        FLines.Text:=Source;
        for i := 0 to FLines.Count-1 do
          if copy(FLines[i],length(FLines[i]),1)<>':' then
            FLines[i] := FLines[i]+';_CallLineInfo';
        fEngine.ExecString(FLines.Text);
        FreeAndNil(FLines);
      end
    else fEngine.ExecString(Source);
    Result := True;
  except
    on e : Exception do
      if Assigned(Writeln) then
        Writeln(e.Message);
  end;
end;

destructor TPythonScript.Destroy;
begin
  FreeAndNil(fIO);
  FreeAndNil(fEngine);
  inherited Destroy;
end;

initialization

end.

