unit uNavFrames;

interface

uses
  System.Generics.Collections,System.SysUtils,System.Classes,
  FMX.Controls, FMX.Forms, FMX.Layouts,FMX.Types,Winapi.Windows;

type
  TNavFrames = class
  private
    class var FStack: TStack<TFrame>;
    class var FHost: TLayout;
    class var FCurrent: TFrame;
    class procedure ClearHost;
    class var FCache: TDictionary<TClass, TFrame>;
  public
    class constructor Create;
    class destructor Destroy;
    class procedure GoCached(AFrameClass: TClass; AOwner: TComponent);
    class procedure Init(AHost: TLayout);
    class procedure Go(ANext: TFrame);
    class procedure Back;
  end;

implementation
type
  TFrameClass = class of TFrame;
class constructor TNavFrames.Create;
begin
  FStack := TStack<TFrame>.Create;
  FCache := TDictionary<TClass, TFrame>.Create;
end;

class destructor TNavFrames.Destroy;
var
  P: TPair<TClass, TFrame>;
begin
  for P in FCache do
  begin
    P.Value.Parent := nil;
    P.Value.Free;
  end;

  FCache.Free;
  FStack.Free;
end;

class procedure TNavFrames.Init(AHost: TLayout);
begin
  FHost := AHost;
end;

class procedure TNavFrames.Go(ANext: TFrame);
begin
  if (FHost = nil) or (ANext = nil) then Exit;


  if FCurrent <> nil then
  begin
    FCurrent.Visible := False;
    FCurrent.Parent := nil;
    if (FCurrent <> nil) and (FCurrent <> ANext) then
    begin
    FCurrent.Visible := False;
    FStack.Push(FCurrent);
    end;
    OutputDebugString(PChar('Stack=' + FStack.Count.ToString));
  end;


  FCurrent := ANext;
  ClearHost;
  FCurrent.Parent := FHost;
  FCurrent.Align := TAlignLayout.Client;
  FCurrent.Visible := True;
  FCurrent.BringToFront;
end;

class procedure TNavFrames.ClearHost;
var
  i: Integer;
begin
  if FHost = nil then Exit;

  for i := 0 to FHost.ControlsCount - 1 do
    FHost.Controls[i].Visible := False;
end;

class procedure TNavFrames.GoCached(AFrameClass: TClass; AOwner: TComponent);
var
  F: TFrame;
begin
  if (FHost = nil) or (AFrameClass = nil) then Exit;

  if not FCache.TryGetValue(AFrameClass, F) then
  begin
    F := TFrameClass(AFrameClass).Create(nil);
    F.Name := 'fr_' + AFrameClass.ClassName;
    FCache.Add(AFrameClass, F);
  end;

  Go(F);
end;

class procedure TNavFrames.Back;
var
  Prev: TFrame;
begin
  if (FHost = nil) or (FStack.Count = 0) then Exit;


  if FCurrent <> nil then
  begin
    FCurrent.Visible := False;
    FCurrent.Parent := nil;
  end;


  Prev := FStack.Pop;
  FCurrent := Prev;
  ClearHost;
  FCurrent.Parent := FHost;
  FCurrent.Align := TAlignLayout.Client;
  FCurrent.Visible := True;
  FCurrent.BringToFront;
end;

end.
