unit fraHrana;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs,
  FMX.StdCtrls, FMX.Controls.Presentation, FMX.Layouts, FMX.Objects,
  FMX.Edit, FMX.Memo, FMX.Memo.Types, FMX.ScrollBox, FMX.ListBox,
  FireDAC.Comp.Client, uUserStore, uNavFrames;

type
  TFrameHrana = class(TFrame)


    layHeader: TLayout;
    lblNaslov: TLabel;
    rectNazad: TRectangle;


    rectForma: TRectangle;

    lblVrsta: TLabel;
    cbVrsta: TComboBox;       // izbor vrste hrane iz magacina (RESURS)

    lblVremeObroka: TLabel;
    edtVremeObroka: TEdit;    // npr. "08:30"

    lblKolicina: TLabel;
    edtKolicina: TEdit;       // npr. "280g"

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
    procedure SacuvajHranu;
  end;

implementation

{$R *.fmx}

procedure TFrameHrana.Loaded;
begin
  inherited;
  lblNaslov.Text      := 'Hrana';
  edtVremeObroka.Text := FormatDateTime('hh:nn', Now);
  UcitajResurse;
end;

// Napuni padajuci meni vrstama hrane iz magacina (RESURS)
procedure TFrameHrana.UcitajResurse;
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
        'WHERE lower(Tip_Resursa) LIKE ''%hrana%'' ' +
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
//  ParsujVreme - prihvata hh:nn bez StrToDateTime
// -------------------------------------------------------
function TFrameHrana.ParsujVreme(const AVreme: string;
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

// Izvlaci pocetni ceo broj iz teksta kolicine (npr. "280g" -> 280)
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

procedure TFrameHrana.SacuvajHranu;
var
  Q: TFDQuery;
  dtVreme: TDateTime;
  idUsluga, idResurs, nUtrosak: Integer;
  sVrsta: string;
begin
  // --- Validacija ---
  if (cbVrsta.ItemIndex < 0) or (cbVrsta.ItemIndex >= FResCount) then
  begin
    ShowMessage('Izaberite vrstu hrane iz padajuceg menija!');
    Exit;
  end;

  if Trim(edtVremeObroka.Text) = '' then
  begin
    ShowMessage('Unesite vreme obroka!');
    edtVremeObroka.SetFocus;
    Exit;
  end;

  if not ParsujVreme(edtVremeObroka.Text, dtVreme) then
  begin
    ShowMessage('Pogresno vreme obroka!' + #13#10 +
                'Koristite format: hh:nn (npr. 08:30)');
    edtVremeObroka.SetFocus;
    Exit;
  end;

  if Trim(edtKolicina.Text) = '' then
  begin
    ShowMessage('Unesite kolicinu hrane (npr. 280g)!');
    edtKolicina.SetFocus;
    Exit;
  end;

  // --- Vrsta hrane i resurs dolaze direktno iz izbora u meniju (RESURS) ---
  nUtrosak := ParsujKolicinu(edtKolicina.Text);
  sVrsta   := cbVrsta.Items[cbVrsta.ItemIndex];
  idResurs := FResIDs[cbVrsta.ItemIndex];

  // --- SQL INSERT ---
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := DB;

    idUsluga := 0;
    Q.SQL.Text := 'SELECT Sifra_usluge FROM USLUGA WHERE Naziv = ''Hranjenje'' LIMIT 1';
    Q.Open;
    if not Q.IsEmpty then idUsluga := Q.Fields[0].AsInteger;
    Q.Close;

    Q.SQL.Text :=
      'INSERT INTO DNEVNA_AKTIVNOST ' +
      '  (Kategorija, Vrsta_aktivnosti, VremeOd, VremeDo, ' +
      '   DuzinaTrajanja, StatusAktivnosti, ' +
      '   VremeObroka, Kolicina, Komentar, ' +
      '   Sifra_usluge, Sifra_resursa, Kolicina_Utroska, ' +
      '   Sifra_zaposlenog, Sifra_ljubimca) ' +
      'VALUES ' +
      '  (:kat, :vrsta, :od, :od, ' +
      '   :traj, :status, ' +
      '   :vobroka, :kol, :kom, ' +
      '   :usl, :res, :utr, ' +
      '   :zap, :pet)';

    Q.ParamByName('kat').AsString     := 'Hrana';
    Q.ParamByName('vrsta').AsString   := sVrsta;
    Q.ParamByName('od').AsDateTime    := dtVreme;
    Q.ParamByName('traj').AsString    := '0 min';
    Q.ParamByName('status').AsString  := 'Zavrseno';
    Q.ParamByName('vobroka').AsString := Trim(edtVremeObroka.Text);
    Q.ParamByName('kol').AsString     := Trim(edtKolicina.Text);
    Q.ParamByName('kom').AsString     := Trim(memoKomentar.Text);
    Q.ParamByName('usl').AsInteger    := idUsluga;
    Q.ParamByName('res').AsInteger    := idResurs;
    Q.ParamByName('utr').AsInteger    := nUtrosak;
    Q.ParamByName('zap').AsInteger    := LoggedInUserID;
    Q.ParamByName('pet').AsInteger    := SelectedPetID;
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

    ShowMessage('Obrok je uspesno zabelezen!');
    TNavFrames.Back;

  except
    on E: Exception do
      ShowMessage('Greska: ' + E.Message);
  end;
  Q.Free;
end;

procedure TFrameHrana.rectPotvrdiClick(Sender: TObject);
begin
  SacuvajHranu;
end;

procedure TFrameHrana.rectNazadClick(Sender: TObject);
begin
  TNavFrames.Back;
end;

end.
