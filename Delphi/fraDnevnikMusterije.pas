unit fraDnevnikMusterije;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts, FMX.Objects, FMX.ListBox,
  FireDAC.Comp.Client, uUserStore, uNavFrames, uPetModel;

type
  TFrameDnevnikMusterije = class(TFrame)
    // --- ZAGLAVLJE ---
    layHeader: TLayout;
    lblNaslov: TLabel;
    lblPozdrav: TLabel;
    rectNazad: TRectangle;

    // --- ODABIR LJUBIMCA ---
    rectOdabir: TRectangle;
    lblOdabirTitle: TLabel;
    cbLjubimci: TComboBox;

    // --- GLAVNI SCROLL ---
    scrollContent: TScrollBox;

    // ---- SEKCIJA: AKTIVNOSTI ----
    rectSekAkt: TRectangle;
    lblSekAkt: TLabel;
    lblBrojAkt: TLabel;
    lbAktivnosti: TListBox;

    // ---- SEKCIJA: HRANA ----
    rectSekHrana: TRectangle;
    lblSekHrana: TLabel;
    lblBrojHrana: TLabel;
    lbHrana: TListBox;

    // ---- SEKCIJA: OSTALO ----
    rectSekOstalo: TRectangle;
    lblSekOstalo: TLabel;
    lblBrojOstalo: TLabel;
    lbOstalo: TListBox;

    // ---- SEKCIJA: POPUP ----
    rectPopup: TRectangle;
    rectPopupCard: TRectangle;
    lblPopupNaslov: TLabel;
    lblPopupDetalji: TLabel;
    rectPopupZatvori: TRectangle;
    lblPopupX: TLabel;


    procedure Loaded; override;
    procedure rectNazadClick(Sender: TObject);
    procedure cbLjubimciChange(Sender: TObject);
    procedure lbAktivnostiClick(Sender: TObject);
    procedure lbHranaClick(Sender: TObject);
    procedure lbOstaloClick(Sender: TObject);
    procedure rectPopupZatvoriClick(Sender: TObject);
    procedure rectPopupClick(Sender: TObject);

  private
    FPetIDs: array[0..19] of Integer;
    FPetCount: Integer;

    // Cuva detalje za svaki item
    FAktDetalji: array[0..49] of string;
    FHranaDetalji: array[0..49] of string;
    FOstaloDetalji: array[0..49] of string;

    procedure UcitajMojeLjubimce;
    procedure UcitajSve;
    procedure UcitajAktivnosti;
    procedure UcitajHranu;
    procedure UcitajOstalo;
    procedure PrikaziPopup(const ANaslov, ADetalji: string);
  end;

implementation

{$R *.fmx}

procedure TFrameDnevnikMusterije.Loaded;
var
  i, nIdx: Integer;
begin
  inherited;
  lblPozdrav.Text := 'Zdravo, ' + LoggedInImePrezime + '!';

  // Popup je na pocetku skriven
  rectPopup.Visible := False;

  UcitajMojeLjubimce;

  if cbLjubimci.Count > 0 then
  begin
    // Zadrzi vec selektovanog ljubimca (kad osoblje dodje preko "Pregled")
    nIdx := 0;
    for i := 0 to FPetCount - 1 do
      if FPetIDs[i] = SelectedPetID then
      begin
        nIdx := i;
        Break;
      end;
    cbLjubimci.ItemIndex := nIdx;
    SelectedPetID := FPetIDs[nIdx];
    UcitajSve;
  end;
end;

procedure TFrameDnevnikMusterije.UcitajMojeLjubimce;
var
  Q: TFDQuery;
begin
  cbLjubimci.Items.Clear;
  FPetCount := 0;

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := DB;
    Q.SQL.Text :=
      'SELECT id, name, breed, species ' +
      'FROM pets WHERE Sifra_musterije = :mid ORDER BY name';
    Q.ParamByName('mid').AsInteger := LoggedInUserID;
    Q.Open;

    if Q.IsEmpty then
    begin
      Q.Close;
      Q.SQL.Text := 'SELECT id, name, breed, species FROM pets ORDER BY name';
      Q.Open;
    end;

    while not Q.Eof do
    begin
      FPetIDs[FPetCount] := Q.FieldByName('id').AsInteger;
      cbLjubimci.Items.Add(
        Q.FieldByName('name').AsString + '  (' +
        Q.FieldByName('species').AsString + ' · ' +
        Q.FieldByName('breed').AsString + ')'
      );
      Inc(FPetCount);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

procedure TFrameDnevnikMusterije.cbLjubimciChange(Sender: TObject);
begin
  if (cbLjubimci.ItemIndex < 0) or
     (cbLjubimci.ItemIndex >= FPetCount) then Exit;
  SelectedPetID := FPetIDs[cbLjubimci.ItemIndex];
  UcitajSve;
end;

procedure TFrameDnevnikMusterije.UcitajSve;
begin
  UcitajAktivnosti;
  UcitajHranu;
  UcitajOstalo;
end;

// -------------------------------------------------------
//  Prikazi popup sa detaljima
// -------------------------------------------------------
procedure TFrameDnevnikMusterije.PrikaziPopup(
  const ANaslov, ADetalji: string);
begin
  lblPopupNaslov.Text  := ANaslov;
  lblPopupDetalji.Text := ADetalji;
  rectPopup.Visible    := True;
  rectPopup.BringToFront;
end;

// -------------------------------------------------------
//  Klik na aktivnost → prikazi detalje
// -------------------------------------------------------
procedure TFrameDnevnikMusterije.lbAktivnostiClick(Sender: TObject);
var
  idx: Integer;
begin
  idx := lbAktivnosti.ItemIndex;
  if (idx < 0) or (idx > High(FAktDetalji)) then Exit;
  if FAktDetalji[idx] = '' then Exit;

  PrikaziPopup(
    lbAktivnosti.Items[idx],
    FAktDetalji[idx]
  );
end;

procedure TFrameDnevnikMusterije.lbHranaClick(Sender: TObject);
var
  idx: Integer;
begin
  idx := lbHrana.ItemIndex;
  if (idx < 0) or (idx > High(FHranaDetalji)) then Exit;
  if FHranaDetalji[idx] = '' then Exit;

  PrikaziPopup(
    lbHrana.Items[idx],
    FHranaDetalji[idx]
  );
end;

procedure TFrameDnevnikMusterije.lbOstaloClick(Sender: TObject);
var
  idx: Integer;
begin
  idx := lbOstalo.ItemIndex;
  if (idx < 0) or (idx > High(FOstaloDetalji)) then Exit;
  if FOstaloDetalji[idx] = '' then Exit;

  PrikaziPopup(
    lbOstalo.Items[idx],
    FOstaloDetalji[idx]
  );
end;

// Zatvori popup klikom na X ili na pozadinu
procedure TFrameDnevnikMusterije.rectPopupZatvoriClick(Sender: TObject);
begin
  rectPopup.Visible := False;
end;

procedure TFrameDnevnikMusterije.rectPopupClick(Sender: TObject);
begin
  rectPopup.Visible := False;
end;

// -------------------------------------------------------
//  AKTIVNOSTI
// -------------------------------------------------------
procedure TFrameDnevnikMusterije.UcitajAktivnosti;
var
  Q: TFDQuery;
  Item: TListBoxItem;
  sDetalj: string;
  i: Integer;
begin
  lbAktivnosti.BeginUpdate;
  try
    lbAktivnosti.Clear;
    FillChar(FAktDetalji, SizeOf(FAktDetalji), 0);
    if SelectedPetID <= 0 then Exit;

    Q := TFDQuery.Create(nil);
    try
      Q.Connection := DB;
      Q.SQL.Text :=
        'SELECT da.Vrsta_aktivnosti, da.VremeOd, da.VremeDo, ' +
        '       da.DuzinaTrajanja, da.ProcenaPonasanja, da.Komentar, ' +
        '       da.StatusAktivnosti, z.Ime, z.Prezime ' +
        'FROM DNEVNA_AKTIVNOST da ' +
        'LEFT JOIN ZAPOSLENI z ON z.Sifra_zaposlenog = da.Sifra_zaposlenog ' +
        'WHERE da.Sifra_ljubimca = :pid AND da.Kategorija = ''Aktivnosti'' ' +
        'ORDER BY da.VremeOd DESC';
      Q.ParamByName('pid').AsInteger := SelectedPetID;
      Q.Open;

      lblBrojAkt.Text := '(' + IntToStr(Q.RecordCount) + ' zapisa)';

      if Q.IsEmpty then
      begin
        Item := TListBoxItem.Create(lbAktivnosti);
        Item.Text := 'Nema zabelezenih aktivnosti';
        lbAktivnosti.AddObject(Item);
      end
      else
      begin
        i := 0;
        while not Q.Eof do
        begin
          Item := TListBoxItem.Create(lbAktivnosti);
          Item.Text := Q.FieldByName('Vrsta_aktivnosti').AsString;
          Item.ItemData.Detail :=
            FormatDateTime('hh:nn', Q.FieldByName('VremeOd').AsDateTime) +
            ' - ' +
            FormatDateTime('hh:nn', Q.FieldByName('VremeDo').AsDateTime) +
            '  (' + Q.FieldByName('DuzinaTrajanja').AsString + ')';
          lbAktivnosti.AddObject(Item);

          // Sacuvaj pune detalje za popup
          if Q.FieldByName('StatusAktivnosti').AsString = 'U toku' then
          begin
            sDetalj :=
              'Vrsta: ' + Q.FieldByName('Vrsta_aktivnosti').AsString + #13#10 +
              'Pocelo: ' +
              FormatDateTime('hh:nn', Q.FieldByName('VremeOd').AsDateTime) + #13#10 +
              'Predvidjeno zavrsetka: ' +
              FormatDateTime('hh:nn', Q.FieldByName('VremeDo').AsDateTime) + #13#10 +
              'Status: U toku';
          end
          else
          begin
            sDetalj :=
              'Vrsta: ' + Q.FieldByName('Vrsta_aktivnosti').AsString + #13#10 +
              'Od: ' + FormatDateTime('hh:nn', Q.FieldByName('VremeOd').AsDateTime) +
              '  Do: ' + FormatDateTime('hh:nn', Q.FieldByName('VremeDo').AsDateTime) + #13#10 +
              'Trajanje: ' + Q.FieldByName('DuzinaTrajanja').AsString + #13#10 +
              'Status: Zavrseno';

            if Q.FieldByName('ProcenaPonasanja').AsString <> '' then
              sDetalj := sDetalj + #13#10 +
                'Procena: ' + Q.FieldByName('ProcenaPonasanja').AsString;

            if Q.FieldByName('Komentar').AsString <> '' then
              sDetalj := sDetalj + #13#10 +
                'Komentar: ' + Q.FieldByName('Komentar').AsString;
          end;

          sDetalj := sDetalj + #13#10 +
            'Zaposleni: ' + Q.FieldByName('Ime').AsString +
            ' ' + Q.FieldByName('Prezime').AsString;

          if i <= High(FAktDetalji) then
            FAktDetalji[i] := sDetalj;

          Inc(i);
          Q.Next;
        end;
      end;
    finally
      Q.Free;
    end;
  finally
    lbAktivnosti.EndUpdate;
  end;
end;

// -------------------------------------------------------
//  HRANA
// -------------------------------------------------------
procedure TFrameDnevnikMusterije.UcitajHranu;
var
  Q: TFDQuery;
  Item: TListBoxItem;
  sDetalj: string;
  i: Integer;
begin
  lbHrana.BeginUpdate;
  try
    lbHrana.Clear;
    FillChar(FHranaDetalji, SizeOf(FHranaDetalji), 0);
    if SelectedPetID <= 0 then Exit;

    Q := TFDQuery.Create(nil);
    try
      Q.Connection := DB;
      Q.SQL.Text :=
        'SELECT da.Vrsta_aktivnosti, da.VremeObroka, da.Kolicina, ' +
        '       da.Komentar, z.Ime, z.Prezime ' +
        'FROM DNEVNA_AKTIVNOST da ' +
        'LEFT JOIN ZAPOSLENI z ON z.Sifra_zaposlenog = da.Sifra_zaposlenog ' +
        'WHERE da.Sifra_ljubimca = :pid AND da.Kategorija = ''Hrana'' ' +
        'ORDER BY da.VremeOd DESC';
      Q.ParamByName('pid').AsInteger := SelectedPetID;
      Q.Open;

      lblBrojHrana.Text := '(' + IntToStr(Q.RecordCount) + ' obroka)';

      if Q.IsEmpty then
      begin
        Item := TListBoxItem.Create(lbHrana);
        Item.Text := 'Nema zabelezenih obroka';
        lbHrana.AddObject(Item);
      end
      else
      begin
        i := 0;
        while not Q.Eof do
        begin
          Item := TListBoxItem.Create(lbHrana);
          Item.Text := Q.FieldByName('Vrsta_aktivnosti').AsString;
          Item.ItemData.Detail :=
            'Vreme: ' + Q.FieldByName('VremeObroka').AsString +
            '  |  ' + Q.FieldByName('Kolicina').AsString;
          lbHrana.AddObject(Item);

          sDetalj :=
            'Vrsta hrane: ' + Q.FieldByName('Vrsta_aktivnosti').AsString + #13#10 +
            'Vreme obroka: ' + Q.FieldByName('VremeObroka').AsString + #13#10 +
            'Kolicina: ' + Q.FieldByName('Kolicina').AsString;

          if Q.FieldByName('Komentar').AsString <> '' then
            sDetalj := sDetalj + #13#10 +
              'Komentar: ' + Q.FieldByName('Komentar').AsString;

          sDetalj := sDetalj + #13#10 +
            'Zaposleni: ' + Q.FieldByName('Ime').AsString +
            ' ' + Q.FieldByName('Prezime').AsString;

          if i <= High(FHranaDetalji) then
            FHranaDetalji[i] := sDetalj;

          Inc(i);
          Q.Next;
        end;
      end;
    finally
      Q.Free;
    end;
  finally
    lbHrana.EndUpdate;
  end;
end;

// -------------------------------------------------------
//  OSTALO
// -------------------------------------------------------
procedure TFrameDnevnikMusterije.UcitajOstalo;
var
  Q: TFDQuery;
  Item: TListBoxItem;
  sDetalj: string;
  i: Integer;
begin
  lbOstalo.BeginUpdate;
  try
    lbOstalo.Clear;
    FillChar(FOstaloDetalji, SizeOf(FOstaloDetalji), 0);
    if SelectedPetID <= 0 then Exit;

    Q := TFDQuery.Create(nil);
    try
      Q.Connection := DB;
      Q.SQL.Text :=
        'SELECT da.Vrsta_aktivnosti, da.VremeOd, da.StatusOstalo, ' +
        '       da.Komentar, z.Ime, z.Prezime ' +
        'FROM DNEVNA_AKTIVNOST da ' +
        'LEFT JOIN ZAPOSLENI z ON z.Sifra_zaposlenog = da.Sifra_zaposlenog ' +
        'WHERE da.Sifra_ljubimca = :pid AND da.Kategorija = ''Ostalo'' ' +
        'ORDER BY da.VremeOd DESC';
      Q.ParamByName('pid').AsInteger := SelectedPetID;
      Q.Open;

      lblBrojOstalo.Text := '(' + IntToStr(Q.RecordCount) + ' zapisa)';

      if Q.IsEmpty then
      begin
        Item := TListBoxItem.Create(lbOstalo);
        Item.Text := 'Nema zabelezenih aktivnosti';
        lbOstalo.AddObject(Item);
      end
      else
      begin
        i := 0;
        while not Q.Eof do
        begin
          Item := TListBoxItem.Create(lbOstalo);
          Item.Text := Q.FieldByName('Vrsta_aktivnosti').AsString;
          Item.ItemData.Detail :=
            'Vreme: ' +
            FormatDateTime('hh:nn', Q.FieldByName('VremeOd').AsDateTime);
          lbOstalo.AddObject(Item);

          sDetalj :=
            'Vrsta: ' + Q.FieldByName('Vrsta_aktivnosti').AsString + #13#10 +
            'Vreme: ' +
            FormatDateTime('hh:nn', Q.FieldByName('VremeOd').AsDateTime);

          if Q.FieldByName('StatusOstalo').AsString <> '' then
            sDetalj := sDetalj + #13#10 +
              'Status: ' + Q.FieldByName('StatusOstalo').AsString;

          if Q.FieldByName('Komentar').AsString <> '' then
            sDetalj := sDetalj + #13#10 +
              'Komentar: ' + Q.FieldByName('Komentar').AsString;

          sDetalj := sDetalj + #13#10 +
            'Zaposleni: ' + Q.FieldByName('Ime').AsString +
            ' ' + Q.FieldByName('Prezime').AsString;

          if i <= High(FOstaloDetalji) then
            FOstaloDetalji[i] := sDetalj;

          Inc(i);
          Q.Next;
        end;
      end;
    finally
      Q.Free;
    end;
  finally
    lbOstalo.EndUpdate;
  end;
end;

procedure TFrameDnevnikMusterije.rectNazadClick(Sender: TObject);
begin
  if LoggedInRole = 'MUSTERIJA' then
  begin
    LoggedInUserID     := 0;
    LoggedInRole       := '';
    LoggedInUsername   := '';
    LoggedInImePrezime := '';
    SelectedPetID      := 0;
    TNavFrames.GoLogin;
  end
  else
    TNavFrames.Back;
end;

end.
