unit uUserStore;

interface

uses
System.SysUtils, System.Generics.Collections,FireDAC.Comp.Client,uPetModel;

var
  Pets: array[0..9] of TPet;
  ActivePetIndex: Integer = -1;
  DB: TFDConnection;

implementation

end.
