unit fraOstaloUnos;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs,
  FMX.StdCtrls, FMX.Controls.Presentation, FMX.Layouts, FMX.Objects,
  FMX.Edit, FMX.Memo, FMX.Memo.Types, FMX.ScrollBox,
  FireDAC.Comp.Client, uUserStore, uNavFrames;

type
  TFrameOstaloUnos = class(TFrame)

    layHeader: TLayout;
    lblNaslov: TLabel;
    rectNazad: TRectangle;


    rectForma: TRectangle;

    lblVrsta: TLabel;
    edtVrsta: TEdit;          // npr. "Higijena"

    lblVreme: TLabel;
    edtVreme: TEdit;          // npr. "14:00"

    lblStatus: TLabel;
    edtStatus: TEdit;         // npr. "Dlaka ociscena, nokti sredjeni"

    lblKolicina: TLabel;
    edtKolicina: TEdit;       // npr. "50" (sampon ml) ili "5" (maramice kom)

    lblKomentar: TLabel;
    memoKomentar: TMemo;

    rectPotvrdi: TRectangle;
    lblPotvrdi: TLabel;

    procedure Loaded; override;
    procedure rectPotvrdiClick(Sender: TObject);
    procedure rectNazadClick(Sender: TObject);

  private
    function ParsujVreme(const AVreme: string;
      out ADT: TDateTime): Boolean;
    procedure SacuvajOstalo;
  end;

implementation

{$R *.fmx}

procedure TFrameOstaloUnos.Loaded;
begin
  inherited;
  lblNaslov.Text := 'Ostalo';
  edtVreme.Text  := FormatDateTime('hh:nn', Now);
end;

// -------------------------------------------------------
//  Isti ParsujVreme kao u fraAktivnosti
//  Prihvata format hh:nn bez StrToDateTime
// -------------------------------------------------------
function TFrameOstaloUnos.ParsujVreme(const AVreme: string;
  out ADT: TDateTime): Boolean;
var
  parts: TArray<string>;
  nH, nM: Integer;
begin
  Result := False;
  parts  := Trim(AVreme).Split([':']);

  if Length(parts) < 2 then Exit;
  if not TryStrToInt(Trim(parts[0]), nH) then Exit;
  if not TryStrToInt(Trim(parts[1]), nM) then Exit;
  if (nH < 0) or (nH > 23) then Exit;
  if (nM < 0) or (nM > 59) then Exit;

  ADT    := Trunc(Now) + EncodeTime(nH, nM, 0, 0);
  Result := True;
end;

// Izvlaci pocetni ceo broj iz teksta kolicine (npr. "50 ml" -> 50)
function ParsujKolicinu(const AKol: string): Integer;
var
  i: Integer;
  sNum: string;
begin
  sNum := '';
  for i := 1 to Length(AKol) do
    if CharInSet(AKol[i], ['0'..'9']) then
      sNum := sNum + AKol[i]
    else if sNum <> '' then
      Break;
  Result := StrToIntDef(sNum, 0);
end;

procedure TFrameOstaloUnos.SacuvajOstalo;
var
  Q: TFDQuery;
  dtVreme: TDateTime;
  idUsluga, idResurs, nUtrosak: Integer;
  sResTip, sVrstaLower: string;
begin
  // --- Validacija ---
  if Trim(edtVrsta.Text) = '' then
  begin
    ShowMessage('Unesite vrstu aktivnosti!');
    edtVrsta.SetFocus;
    Exit;
  end;

  if Trim(edtVreme.Text) = '' then
  begin
    ShowMessage('Unesite vreme!');
    edtVreme.SetFocus;
    Exit;
  end;

  if not ParsujVreme(edtVreme.Text, dtVreme) then
  begin
    ShowMessage('Pogresno vreme!' + #13#10 +
                'Koristite format: hh:nn (npr. 14:00)');
    edtVreme.SetFocus;
    Exit;
  end;

  if Trim(edtStatus.Text) = '' then
  begin
    ShowMessage('Unesite status (opis obavljenog)!');
    edtStatus.SetFocus;
    Exit;
  end;

  // --- Odredi uslugu (OBUHVATA) i resurs koji se trosi iz magacina (TROSI) ---
  // Kupanje/pranje trosi sampon, ostalo (higijena) trosi maramice.
  sVrstaLower := LowerCase(Trim(edtVrsta.Text));
  if (Pos('kupanj', sVrstaLower) > 0) or (Pos('sampon', sVrstaLower) > 0) or
     (Pos('pranj', sVrstaLower) > 0) then
    sResTip := 'Sampon (ml)'
  else
    sResTip := 'Higijenske maramice (kom)';

  // Kolicina koja se skida iz magacina = uneta vrednost (npr. "50 ml" -> 50)
  nUtrosak := ParsujKolicinu(edtKolicina.Text);

  // --- SQL INSERT ---
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := DB;

    idUsluga := 0;
    Q.SQL.Text := 'SELECT Sifra_usluge FROM USLUGA ' +
      'WHERE instr(lower(:v), lower(Naziv)) > 0 LIMIT 1';
    Q.ParamByName('v').AsString := Trim(edtVrsta.Text);
    Q.Open;
    if not Q.IsEmpty then idUsluga := Q.Fields[0].AsInteger;
    Q.Close;

    idResurs := 0;
    Q.SQL.Text := 'SELECT Sifra_resursa FROM RESURS WHERE Tip_Resursa = :t LIMIT 1';
    Q.ParamByName('t').AsString := sResTip;
    Q.Open;
    if not Q.IsEmpty then idResurs := Q.Fields[0].AsInteger;
    Q.Close;

    Q.SQL.Text :=
      'INSERT INTO DNEVNA_AKTIVNOST ' +
      '  (Kategorija, Vrsta_aktivnosti, VremeOd, VremeDo, ' +
      '   DuzinaTrajanja, StatusAktivnosti, ' +
      '   StatusOstalo, Komentar, Kolicina, ' +
      '   Sifra_usluge, Sifra_resursa, Kolicina_Utroska, ' +
      '   Sifra_zaposlenog, Sifra_ljubimca) ' +
      'VALUES ' +
      '  (:kat, :vrsta, :od, :od, ' +
      '   :traj, :status, ' +
      '   :stost, :kom, :kol, ' +
      '   :usl, :res, :utr, ' +
      '   :zap, :pet)';

    Q.ParamByName('kat').AsString    := 'Ostalo';
    Q.ParamByName('vrsta').AsString  := Trim(edtVrsta.Text);
    Q.ParamByName('od').AsDateTime   := dtVreme;
    Q.ParamByName('traj').AsString   := '0 min';
    Q.ParamByName('status').AsString := 'Zavrseno';
    Q.ParamByName('stost').AsString  := Trim(edtStatus.Text);
    Q.ParamByName('kom').AsString    := Trim(memoKomentar.Text);
    Q.ParamByName('kol').AsString    := Trim(edtKolicina.Text);
    Q.ParamByName('usl').AsInteger   := idUsluga;
    Q.ParamByName('res').AsInteger   := idResurs;
    Q.ParamByName('utr').AsInteger   := nUtrosak;
    Q.ParamByName('zap').AsInteger   := LoggedInUserID;
    Q.ParamByName('pet').AsInteger   := SelectedPetID;
    Q.ExecSQL;

    // --- Automatsko umanjenje zaliha u magacinu (A2.4) ---
    if (idResurs > 0) and (nUtrosak > 0) then
    begin
      Q.SQL.Text :=
        'UPDATE RESURS SET Trenutno_u_Magacinu = ' +
        '  MAX(0, Trenutno_u_Magacinu - :u) ' +
        'WHERE Sifra_resursa = :r';
      Q.ParamByName('u').AsInteger := nUtrosak;
      Q.ParamByName('r').AsInteger := idResurs;
      Q.ExecSQL;
    end;

    ShowMessage('Aktivnost je uspesno zabelezena!');
    TNavFrames.Back;

  except
    on E: Exception do
      ShowMessage('Greska: ' + E.Message);
  end;
  Q.Free;
end;

procedure TFrameOstaloUnos.rectPotvrdiClick(Sender: TObject);
begin
  SacuvajOstalo;
end;

procedure TFrameOstaloUnos.rectNazadClick(Sender: TObject);
begin
  TNavFrames.Back;
end;

end.
