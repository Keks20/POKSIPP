unit frmMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  uNavFrames, fraWelcome, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf,
  FireDAC.DApt.Intf, FireDAC.Stan.Async, FireDAC.DApt, FireDAC.UI.Intf,
  FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Phys, FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs,
  FireDAC.Phys.SQLiteWrapper.Stat, FireDAC.FMXUI.Wait, Data.DB,
  FireDAC.Comp.Client, FireDAC.Comp.DataSet, uUserStore, fraHome, System.IOUtils;

type
  TForm5 = class(TForm)
    layHost: TLayout;
    FDQuery1: TFDQuery;
    FDConnection1: TFDConnection;
    procedure FormCreate(Sender: TObject);
    procedure FDConnection1AfterConnect(Sender: TObject);
  private
    procedure KreirajTabele;
    procedure UcitajTestPodatke;
    procedure LoadPetsFromDB;
  public
  end;

var
  Form5: TForm5;

implementation

{$R *.fmx}

procedure TForm5.FDConnection1AfterConnect(Sender: TObject);
begin
     FDConnection1.ExecSQL(
    'CREATE TABLE IF NOT EXISTS ZAPOSLENI (' +
    'Sifra_zaposlenog INTEGER PRIMARY KEY AUTOINCREMENT, ' +
    'Ime VARCHAR(50), ' +
    'Prezime VARCHAR(50), ' +
    'Uloga VARCHAR(50), ' +
    'KorisnickoIme VARCHAR(50) UNIQUE, ' +
    'Lozinka VARCHAR(50), ' +
    'Dostupan INTEGER DEFAULT 1)' // 1 = Slobodan, 0 = Zauzet (Profesorov zahtev)
  );

  FDConnection1.ExecSQL(
    'CREATE TABLE IF NOT EXISTS MUSTERIJA (' +
    'Sifra_musterije INTEGER PRIMARY KEY AUTOINCREMENT, ' +
    'Ime VARCHAR(50), ' +
    'Prezime VARCHAR(50), ' +
    'Nalog VARCHAR(50), ' +
    'Telefon_Hitno VARCHAR(20), ' +
    'KorisnickoIme VARCHAR(50) UNIQUE, ' +
    'Lozinka VARCHAR(50))'
  );

 FDConnection1.ExecSQL(
    'CREATE TABLE IF NOT EXISTS DNEVNA_AKTIVNOST (' +
    'Sifra_aktivnosti INTEGER PRIMARY KEY AUTOINCREMENT, ' +
    'Vrsta_aktivnosti VARCHAR(100), ' +
    'VremeOd DATETIME, ' +              // Dodato: Vreme početka
    'VremeDo DATETIME, ' +              // Dodato: Vreme završetka
    'DuzinaTrajanja VARCHAR(50), ' +    // Dodato: Trajanje
    'StatusAktivnosti VARCHAR(50), ' +  // Dodato: 'U toku', 'Završeno'
    'Ocena INTEGER, ' +
    'Komentar TEXT, ' +
    'Sifra_zaposlenog INTEGER, ' +
    'Sifra_ljubimca INTEGER, ' +
    'FOREIGN KEY(Sifra_zaposlenog) REFERENCES ZAPOSLENI(Sifra_zaposlenog), ' +
     'FOREIGN KEY(Sifra_ljubimca) REFERENCES pets(id))'
  );

 FDConnection1.ExecSQL(
    'INSERT INTO ZAPOSLENI (Ime, Prezime, Uloga, KorisnickoIme, Lozinka, Dostupan) ' +
    'SELECT ''Admin'', ''Adminovic'', ''Menadzer'', ''admin'', ''admin123'', 1 ' +
    'WHERE NOT EXISTS (SELECT 1 FROM ZAPOSLENI WHERE KorisnickoIme = ''admin'')'
  );
end;

procedure TForm5.FormCreate(Sender: TObject);
var
  LDatabasePath: string;
begin
  // 1. Kreiranje foldera 'Baza' i definisanje putanje (Profesor predlozio)
  LDatabasePath := TPath.Combine(ExtractFilePath(ParamStr(0)), 'Baza');
  if not TDirectory.Exists(LDatabasePath) then
    LDatabasePath := TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)), '..\Baza'));
     if not TDirectory.Exists(LDatabasePath) then
  begin
    LDatabasePath := TPath.Combine(ExtractFilePath(ParamStr(0)), 'Baza');
    TDirectory.CreateDirectory(LDatabasePath);
  end;
 // 2. Povezivanje na bazu
  FDConnection1.Connected := False;
  FDConnection1.DriverName := 'SQLITE';
  FDConnection1.Params.Values['Database'] := TPath.Combine(LDatabasePath, 'users.db');

  try
    FDConnection1.Open;
    DB := FDConnection1;
    KreirajTabele;
    LoadPetsFromDB;
    TNavFrames.Init(layHost);
    TNavFrames.Go(TFrame1.Create(nil));
  except
    on E: Exception do
      ShowMessage('Greska pri povezivanju sa bazom: ' + E.Message);
  end;
end;
 

procedure TForm5.KreirajTabele;
begin

  FDQuery1.SQL.Text :=
    'CREATE TABLE IF NOT EXISTS users (' +
    '  id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    '  username TEXT UNIQUE,' +
    '  email TEXT UNIQUE,' +
    '  phone TEXT,' +
    '  password TEXT,' +
    '  Ime VARCHAR(50),' +
    '  Prezime VARCHAR(50),' +
    '  Nalog VARCHAR(50)' +
    ')';
  FDQuery1.ExecSQL;


  FDQuery1.SQL.Text :=
    'CREATE TABLE IF NOT EXISTS pets (' +
    '  id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    '  name TEXT,' +
    '  species TEXT,' +
    '  breed TEXT,' +
    '  age TEXT,' +
    '  image_blob BLOB,' +
    '  Status VARCHAR(50),' +
    '  Sifra_musterije INT' +
    ')';
  FDQuery1.ExecSQL;

  // --- Tabela: ZAPOSLENI (nova) ---
  FDQuery1.SQL.Text :=
    'CREATE TABLE IF NOT EXISTS ZAPOSLENI (' +
    '  Sifra_zaposlenog INTEGER PRIMARY KEY AUTOINCREMENT,' +
    '  Ime VARCHAR(50),' +
    '  Prezime VARCHAR(50),' +
    '  Uloga VARCHAR(50),' +
    '  KorisnickoIme VARCHAR(50) UNIQUE,' +
    '  Lozinka VARCHAR(50)' +
    ')';
  FDQuery1.ExecSQL;

  // --- Tabela: MUSTERIJA (nova) ---
  FDQuery1.SQL.Text :=
    'CREATE TABLE IF NOT EXISTS MUSTERIJA (' +
    '  Sifra_musterije INTEGER PRIMARY KEY AUTOINCREMENT,' +
    '  Ime VARCHAR(50),' +
    '  Prezime VARCHAR(50),' +
    '  Nalog VARCHAR(50),' +
    '  Telefon_Hitno VARCHAR(20),' +
    '  KorisnickoIme VARCHAR(50) UNIQUE,' +
    '  Lozinka VARCHAR(50)' +
    ')';
  FDQuery1.ExecSQL;

  // --- Tabela: DNEVNA_AKTIVNOST (nova) ---
  FDQuery1.SQL.Text :=
   'CREATE TABLE IF NOT EXISTS DNEVNA_AKTIVNOST (' +
    '  Sifra_aktivnosti INTEGER PRIMARY KEY AUTOINCREMENT,' +
    '  Vrsta_aktivnosti VARCHAR(100),' +
    '  VremeOd DATETIME,' +             // Izmenjeno!
    '  VremeDo DATETIME,' +             // Izmenjeno!
    '  DuzinaTrajanja VARCHAR(50),' +   // Izmenjeno!
    '  StatusAktivnosti VARCHAR(50),' + // Izmenjeno!
    '  Ocena INT,' +
    '  Komentar TEXT,' +
    '  Sifra_zaposlenog INT,' +
    '  Sifra_ljubimca INT,' +
    '  FOREIGN KEY (Sifra_zaposlenog) REFERENCES ZAPOSLENI(Sifra_zaposlenog),' +
    '  FOREIGN KEY (Sifra_ljubimca) REFERENCES pets(id)' +
    ')';
  FDQuery1.ExecSQL;
end;

procedure TForm5.UcitajTestPodatke;
var
  Stream: TResourceStream;
begin
  // --- Test zaposleni (ako ne postoje) ---
  FDQuery1.SQL.Text := 'SELECT COUNT(*) FROM ZAPOSLENI';
  FDQuery1.Open;
  if FDQuery1.Fields[0].AsInteger = 0 then
  begin
    FDQuery1.Close;
    FDQuery1.SQL.Text :=
      'INSERT INTO ZAPOSLENI (Ime, Prezime, Uloga, KorisnickoIme, Lozinka) ' +
      'VALUES (:ime, :prez, :uloga, :kor, :loz)';

    FDQuery1.ParamByName('ime').AsString := 'Marko';
    FDQuery1.ParamByName('prez').AsString := 'Marković';
    FDQuery1.ParamByName('uloga').AsString := 'Negovatelj';
    FDQuery1.ParamByName('kor').AsString := 'osoblje1';
    FDQuery1.ParamByName('loz').AsString := 'pass123';
    FDQuery1.ExecSQL;

    FDQuery1.ParamByName('ime').AsString := 'Ana';
    FDQuery1.ParamByName('prez').AsString := 'Anić';
    FDQuery1.ParamByName('uloga').AsString := 'Veterinar';
    FDQuery1.ParamByName('kor').AsString := 'osoblje2';
    FDQuery1.ParamByName('loz').AsString := 'pass123';
    FDQuery1.ExecSQL;
  end
  else
    FDQuery1.Close;

  // --- Test musterije (ako ne postoje) ---
  FDQuery1.SQL.Text := 'SELECT COUNT(*) FROM MUSTERIJA';
  FDQuery1.Open;
  if FDQuery1.Fields[0].AsInteger = 0 then
  begin
    FDQuery1.Close;
    FDQuery1.SQL.Text :=
      'INSERT INTO MUSTERIJA (Ime, Prezime, Nalog, Telefon_Hitno, KorisnickoIme, Lozinka) ' +
      'VALUES (:ime, :prez, :nalog, :tel, :kor, :loz)';

    FDQuery1.ParamByName('ime').AsString := 'Jovana';
    FDQuery1.ParamByName('prez').AsString := 'Jovanović';
    FDQuery1.ParamByName('nalog').AsString := 'Standard';
    FDQuery1.ParamByName('tel').AsString := '0641234567';
    FDQuery1.ParamByName('kor').AsString := 'musterija1';
    FDQuery1.ParamByName('loz').AsString := 'pass123';
    FDQuery1.ExecSQL;
  end
  else
    FDQuery1.Close;

  // --- Test ljubimci (ako ne postoje) ---
  FDQuery1.SQL.Text := 'SELECT COUNT(*) FROM pets';
  FDQuery1.Open;
  if FDQuery1.Fields[0].AsInteger = 0 then
  begin
    FDQuery1.Close;
    FDQuery1.SQL.Text :=
      'INSERT INTO pets (name, species, breed, age, image_blob, Status, Sifra_musterije) ' +
      'VALUES (:name, :species, :breed, :age, :img, :status, :sid)';

    FDQuery1.ParamByName('name').AsString := 'Fido';
    FDQuery1.ParamByName('species').AsString := 'Pas';
    FDQuery1.ParamByName('breed').AsString := 'Labrador';
    FDQuery1.ParamByName('age').AsString := '3 godine';
    FDQuery1.ParamByName('status').AsString := 'Aktivan';
    FDQuery1.ParamByName('sid').AsInteger := 1;
    Stream := TResourceStream.Create(HInstance, 'PngImage_1', RT_RCDATA);
    try
      FDQuery1.ParamByName('img').LoadFromStream(Stream, ftBlob);
    finally
      Stream.Free;
    end;
    FDQuery1.ExecSQL;

    FDQuery1.ParamByName('name').AsString := 'Maca';
    FDQuery1.ParamByName('species').AsString := 'Mačka';
    FDQuery1.ParamByName('breed').AsString := 'Persijska';
    FDQuery1.ParamByName('age').AsString := '2 godine';
    FDQuery1.ParamByName('status').AsString := 'Aktivan';
    FDQuery1.ParamByName('sid').AsInteger := 1;
    Stream := TResourceStream.Create(HInstance, 'PngImage_3', RT_RCDATA);
    try
      FDQuery1.ParamByName('img').LoadFromStream(Stream, ftBlob);
    finally
      Stream.Free;
    end;
    FDQuery1.ExecSQL;
  end
  else
    FDQuery1.Close;
end;

procedure TForm5.LoadPetsFromDB;
var
  Q: TFDQuery;
  i: Integer;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := DB;
    Q.SQL.Text := 'SELECT id, name, species, breed, age, image_blob FROM pets ORDER BY id';
    Q.Open;
    FillChar(Pets, SizeOf(Pets), 0);
    i := 0;
    while (not Q.Eof) and (i <= High(Pets)) do
    begin
      Pets[i].Id      := Q.FieldByName('id').AsInteger;
      Pets[i].Name    := Q.FieldByName('name').AsString;
      Pets[i].Species := Q.FieldByName('species').AsString;
      Pets[i].Breed   := Q.FieldByName('breed').AsString;
      Pets[i].Age     := Q.FieldByName('age').AsString;
      Pets[i].ImageBlob := Q.FieldByName('image_blob').AsBytes;
      Inc(i);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

end.
