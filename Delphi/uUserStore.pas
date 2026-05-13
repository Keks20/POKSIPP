unit uUserStore;

interface

uses
System.SysUtils, System.Generics.Collections,FireDAC.Comp.Client,uPetModel;

var
   // Baza konekcija
  DB: TFDConnection;

  // Ljubimci niz
  Pets: array[0..9] of TPet;
  ActivePetIndex: Integer = -1;

  // Sesija ulogovanog korisnika
  LoggedInUserID: Integer = 0;
  LoggedInRole: string = '';       // 'ZAPOSLENI', 'MUSTERIJA', ili 'USER'
  LoggedInUsername: string = '';
  LoggedInImePrezime: string = ''; // Ime i prezime za prikaz

implementation

end.
