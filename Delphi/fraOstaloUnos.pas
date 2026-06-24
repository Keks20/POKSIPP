unit fraOstaloUnos;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs,
  FMX.StdCtrls, FMX.Controls.Presentation, FMX.Layouts, FMX.Objects,
  FMX.Edit, FMX.Memo, FMX.Memo.Types, FMX.ScrollBox, FMX.ListBox,
  FireDAC.Comp.Client, uUserStore, uNavFrames;

type
  TFrameOstaloUnos = class(TFrame)

    layHeader: TLayout;
    lblNaslov: TLabel;
    rectNazad: TRectangle;


    rectForma: TRectangle;

    lblVrsta: TLabel;
    cbVrsta: TComboBox;       // izbor vrste iz magacina (RESURS)

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
    FResIDs: array[0..49] of Integer;  // Sifra_resursa za svaku stavku menija
    FResCount: Integer;
    function ParsujVreme(const AVreme: string;
      out ADT: TDateTime): Boolean;
    procedure UcitajResurse;
    procedure SacuvajOstalo;
  end;

implementation

{$R *.fmx}

procedure TFrameOstaloUnos.Loaded;
begin
  inherited;
  lblNaslov.Text := 'Ostalo';
  edtVreme.Text  := FormatDateTime('hh:nn', Now);
  UcitajResurse;
end;

// Napuni padajuci meni vrstama iz magacina (RESURS) - sve sem hrane
procedure TFrameOstaloUnos.UcitajResurse;
var
  Q: TFDQuery;
begin
  cbVrsta.Items.BeginUpdate;
  try
    cbVrsta.Items.Clear;
    FResCount := 0;
    Q := TFDQuery.Create(nil);
    try
      Q.Connection := DB;
      Q.SQL.Text :=
        'SELECT Sifra_resursa, Tip_Resursa FROM RESURS ' +
        'WHERE lower(Tip_Resursa) NOT LIKE ''%hrana%'' ' +
        'ORDER BY Tip_Resursa';
      Q.Open;
      while not Q.Eof and (FResCount <= High(FResIDs)) do
      begin
        FResIDs[FResCount] := Q.FieldByName('Sifra_resursa').AsInteger;
        cbVrsta.Items.Add(Q.FieldByName('Tip_Resursa').AsString);
        Inc(FResCount);
        Q.Next;
      end;
    finally
      Q.Free;
    end;
  finally
    cbVrsta.Items.EndUpdate;
  end;
  if cbVrsta.Items.Count > 0 then
    cbVrsta.ItemIndex := 0;
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
  sVrsta: string;
begin
  // --- Validacija ---
  if (cbVrsta.ItemIndex < 0) or (cbVrsta.ItemIndex >= FResCount) then
  begin
    ShowMessage('Izaberite vrstu iz padajuceg menija!');
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

  // --- Vrsta i resurs koji se trosi (TROSI) dolaze iz izbora u meniju (RESURS) ---
  sVrsta   := cbVrsta.Items[cbVrsta.ItemIndex];
  idResurs := FResIDs[cbVrsta.ItemIndex];

  // Kolicina koja se skida iz magacina = uneta vrednost (npr. "50 ml" -> 50)
  nUtrosak := ParsujKolicinu(edtKolicina.Text);

  // --- SQL INSERT ---
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := DB;

    // Usluga (OBUHVATA) - best effort prema nazivu vrste
    idUsluga := 0;
    Q.SQL.Text := 'SELECT Sifra_usluge FROM USLUGA ' +
      'WHERE instr(lower(:v), lower(Naziv)) > 0 LIMIT 1';
    Q.ParamByName('v').AsString := sVrsta;
    Q.Open;
    if not Q.IsEmpty then idUsluga := Q.Fields[0].AsInteger;
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
    Q.ParamByName('vrsta').AsString  := sVrsta;
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
