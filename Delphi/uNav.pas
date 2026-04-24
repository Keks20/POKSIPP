unit uNav;

interface

uses
  System.Generics.Collections,
  FMX.Forms;

type
  TNav = class
  private
    class var FStack: TStack<TForm>;
  public
    class constructor Create;
    class destructor Destroy;


    class procedure Go(ACurrent, ANext: TForm);


    class procedure Back(ACurrent: TForm);


    class function CanBack: Boolean;
  end;

implementation

class constructor TNav.Create;
begin
  FStack := TStack<TForm>.Create;
end;

class destructor TNav.Destroy;
begin
  FStack.Free;
end;

class procedure TNav.Go(ACurrent, ANext: TForm);
begin
  if (ACurrent = nil) or (ANext = nil) then Exit;


  FStack.Push(ACurrent);


  ANext.Show;


  ACurrent.Hide;
end;

class procedure TNav.Back(ACurrent: TForm);
var
  Prev: TForm;
begin
  if (ACurrent = nil) then Exit;
  if FStack.Count = 0 then Exit;

  Prev := FStack.Pop;
  Prev.Show;
  ACurrent.Hide;
end;

class function TNav.CanBack: Boolean;
begin
  Result := (FStack.Count > 0);
end;

end.

