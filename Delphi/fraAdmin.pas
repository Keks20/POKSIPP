unit fraAdmin;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.StrUtils,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts, FMX.Objects, FMX.ListBox,
  FMX.DialogService,
  FireDAC.Comp.Client, uUserStore, uNavFrames;

type
  TFrameAdmin = class(TFrame)
    // --- ZAGLAVLJE ---
    layHeader: TLayout;
    lblNaslov: TLabel;
    lblImeAdmin: TLabel;
    rectOdjava: TRectangle;

    // --- GLAVNI SADRZAJ ---
    scrollContent: TScrollBox;

    // ---- LISTA ZAPOSLENIH ----
    lblZaposleniTitle: TLabel;
    lbZaposleni: TListBox;

    // ---- PROFIL SELEKTOVANOG RADNIKA ----
    rectProfil: TRectangle;
    lblProfilIme: TLabel;
    lblProfilUloga: TLabel;
    lblProfilKorIme: TLabel;
    lblProfilDostupnost: TLabel;

    // ---- UNOSI RADNIKA ----
    lblUnosiTitle: TLabel;
    lblBrojUnosi: TLabel;
    lbUnosi: TListBox;

    // ---- CENOVNIK USLUGA ----
    lblCenovnikTitle: TLabel;
    lbCenovnik: TListBox;

    // ---- MAGACIN / ZALIHE ----
    lblMagacinTitle: TLabel;
    lbMagacin: TListBox;

    // ---- IZMENA CENE ----
    rectIzmeniCenu: TRectangle;
    lblIzmeniCenu: TLabel;

    // ---- POPUP DETALJA UNOSA ----
    rectPopup: TRectangle;
    rectPopupCard: TRectangle;
    lblPopupNaslov: TLabel;
    lblPopupDetalji: TLabel;
    rectPopupZatvori: TRectangle;
    lblPopupX: TLabel;

    procedure Loaded; override;
    procedure rectOdjavaClick(Sender: TObject);
    procedure lbZaposleniClick(Sender: TObject);
    procedure lbCenovnikClick(Sender: TObject);
    procedure lbUnosiClick(Sender: TObject);
    procedure rectPopupClick(Sender: TObject);
    procedure rectPopupZatvoriClick(Sender: TObject);
    procedure rectIzmeniCenuClick(Sender: TObject);
  private
    FZapIDs: array[0..99] of Integer;
    FZapCount: Integer;
    FUslugaIDs: array[0..49] of Integer;
    FUslugaCount: Integer;
    FUnosDetalji: array[0..199] of string;
    function JeZauzet(ASifra: Integer): Boolean;
    procedure IzmeniCenuUsluge(idUsluga: Integer);
    procedure UcitajZaposlene;
    procedure PrikaziRadnika(ASifra: Integer);
    procedure UcitajCenovnik;
    procedure UcitajMagacin;
  end;

implementation

{$R *.fmx}

procedure TFrameAdmin.Loaded;
begin
  inherited;
  rectPopup.Visible := False;
  lblImeAdmin.Text := LoggedInImePrezime;
  UcitajZaposlene;

  if (lbZaposleni.Count > 0) and (FZapCount > 0) then
  begin
    lbZaposleni.ItemIndex := 0;
    PrikaziRadnika(FZapIDs[0]);
  end;

  UcitajCenovnik;
  UcitajMagacin;
end;

// -------------------------------------------------------
//  Da li radnik trenutno ima aktivnost "U toku" (zauzet)
// -------------------------------------------------------
function TFrameAdmin.JeZauzet(ASifra: Integer): Boolean;
var
  Q: TFDQuery;
begin
  Result := False;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := DB;
    Q.SQL.Text :=
      'SELECT COUNT(*) FROM DNEVNA_AKTIVNOST ' +
      'WHERE Sifra_zaposlenog = :z AND StatusAktivnosti = ''U toku'' ' +
      'AND date(VremeOd) = date(''now'')';
    Q.ParamByName('z').AsInteger := ASifra;
    Q.Open;
    Result := Q.Fields[0].AsInteger > 0;
    Q.Close;
  finally
    Q.Free;
  end;
end;

// -------------------------------------------------------
//  Cenovnik usluga (USLUGA)
// -------------------------------------------------------
procedure TFrameAdmin.UcitajCenovnik;
var
  Q: TFDQuery;
  Item: TListBoxItem;
begin
  lbCenovnik.BeginUpdate;
  try
    lbCenovnik.Clear;
    FUslugaCount := 0;
    Q := TFDQuery.Create(nil);
    try
      Q.Connection := DB;
      Q.SQL.Text := 'SELECT Sifra_usluge, Naziv, Cena FROM USLUGA ORDER BY Naziv';
      Q.Open;
      while not Q.Eof do
      begin
        if FUslugaCount > High(FUslugaIDs) then Break;
        FUslugaIDs[FUslugaCount] := Q.FieldByName('Sifra_usluge').AsInteger;

        Item := TListBoxItem.Create(lbCenovnik);
        Item.Text := Q.FieldByName('Naziv').AsString + '   ·   ' +
          FormatFloat('0.##', Q.FieldByName('Cena').AsFloat) + ' RSD';
        lbCenovnik.AddObject(Item);

        Inc(FUslugaCount);
        Q.Next;
      end;
    finally
      Q.Free;
    end;
  finally
    lbCenovnik.EndUpdate;
  end;
end;

// -------------------------------------------------------
//  Magacin / zalihe (RESURS) - read-only, upozorenje na nizak nivo
// -------------------------------------------------------
procedure TFrameAdmin.UcitajMagacin;
var
  Q: TFDQuery;
  Item: TListBoxItem;
  dTren, dNivo: Double;
begin
  lbMagacin.BeginUpdate;
  try
    lbMagacin.Clear;
    Q := TFDQuery.Create(nil);
    try
      Q.Connection := DB;
      Q.SQL.Text :=
        'SELECT Tip_Resursa, Trenutno_u_Magacinu, Kolicina_Nivo ' +
        'FROM RESURS ORDER BY Tip_Resursa';
      Q.Open;
      while not Q.Eof do
      begin
        dTren := Q.FieldByName('Trenutno_u_Magacinu').AsFloat;
        dNivo := Q.FieldByName('Kolicina_Nivo').AsFloat;

        Item := TListBoxItem.Create(lbMagacin);
        Item.Text := Q.FieldByName('Tip_Resursa').AsString + '   ·   ' +
          'Na stanju: ' + FormatFloat('0.##', dTren) +
          ' (min: ' + FormatFloat('0.##', dNivo) + ')';
        if dTren <= dNivo then
          Item.Text := Item.Text + '   - NIZAK NIVO!';
        lbMagacin.AddObject(Item);
        Q.Next;
      end;
    finally
      Q.Free;
    end;
  finally
    lbMagacin.EndUpdate;
  end;
end;

// -------------------------------------------------------
//  Ucitaj listu svih zaposlenih (bez admin naloga)
// -------------------------------------------------------
procedure TFrameAdmin.UcitajZaposlene;
var
  Q: TFDQuery;
  Item: TListBoxItem;
begin
  lbZaposleni.BeginUpdate;
  try
    lbZaposleni.Clear;
    FZapCount := 0;

    Q := TFDQuery.Create(nil);
    try
      Q.Connection := DB;
      Q.SQL.Text :=
        'SELECT Sifra_zaposlenog, Ime, Prezime, Uloga, Dostupan ' +
        'FROM ZAPOSLENI ' +
        'WHERE lower(Uloga) <> ''admin'' ' +
        'ORDER BY Ime, Prezime';
      Q.Open;

      while not Q.Eof do
      begin
        if FZapCount > High(FZapIDs) then Break;
        FZapIDs[FZapCount] := Q.FieldByName('Sifra_zaposlenog').AsInteger;

        Item := TListBoxItem.Create(lbZaposleni);
        Item.Text := Q.FieldByName('Ime').AsString + ' ' +
                     Q.FieldByName('Prezime').AsString + '   ·   ' +
          IfThen(JeZauzet(Q.FieldByName('Sifra_zaposlenog').AsInteger),
                 'Zauzet', 'Dostupan');
        Item.ItemData.Detail := Q.FieldByName('Uloga').AsString;
        lbZaposleni.AddObject(Item);

        Inc(FZapCount);
        Q.Next;
      end;
    finally
      Q.Free;
    end;
  finally
    lbZaposleni.EndUpdate;
  end;
end;

// -------------------------------------------------------
//  Prikazi profil + unose selektovanog radnika
// -------------------------------------------------------
procedure TFrameAdmin.PrikaziRadnika(ASifra: Integer);
var
  Q: TFDQuery;
  Item: TListBoxItem;
  sPet, sDetalj, sKat: string;
  i: Integer;
begin
  if ASifra <= 0 then Exit;

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := DB;

    // --- Profil ---
    Q.SQL.Text :=
      'SELECT Ime, Prezime, Uloga, KorisnickoIme, Dostupan ' +
      'FROM ZAPOSLENI WHERE Sifra_zaposlenog = :z';
    Q.ParamByName('z').AsInteger := ASifra;
    Q.Open;

    if Q.IsEmpty then
    begin
      Q.Close;
      Exit;
    end;

    lblProfilIme.Text   := Q.FieldByName('Ime').AsString + ' ' +
                           Q.FieldByName('Prezime').AsString;
    lblProfilUloga.Text := 'Uloga: ' + Q.FieldByName('Uloga').AsString;
    lblProfilKorIme.Text := 'Korisnicko ime: ' +
                            Q.FieldByName('KorisnickoIme').AsString;

    Q.Close;

    // Dostupnost se racuna iz aktivnosti "U toku" (ne iz staticke kolone)
    if JeZauzet(ASifra) then
    begin
      lblProfilDostupnost.Text := '● Zauzet';
      lblProfilDostupnost.TextSettings.FontColor := TAlphaColors.Red;
    end
    else
    begin
      lblProfilDostupnost.Text := '● Dostupan';
      lblProfilDostupnost.TextSettings.FontColor := TAlphaColors.Green;
    end;

    // --- Unosi radnika (najskoriji na vrhu) ---
    lbUnosi.BeginUpdate;
    try
      lbUnosi.Clear;
      FillChar(FUnosDetalji, SizeOf(FUnosDetalji), 0);

      Q.SQL.Text :=
        'SELECT da.Kategorija, da.Vrsta_aktivnosti, da.VremeOd, da.VremeDo, ' +
        '       da.DuzinaTrajanja, da.StatusAktivnosti, da.ProcenaPonasanja, ' +
        '       da.Komentar, da.Kolicina, da.VremeObroka, da.StatusOstalo, ' +
        '       p.name AS PetName ' +
        'FROM DNEVNA_AKTIVNOST da ' +
        'LEFT JOIN pets p ON p.id = da.Sifra_ljubimca ' +
        'WHERE da.Sifra_zaposlenog = :z ' +
        'ORDER BY da.VremeOd DESC, da.Sifra_aktivnosti DESC';
      Q.ParamByName('z').AsInteger := ASifra;
      Q.Open;

      lblBrojUnosi.Text := '(' + IntToStr(Q.RecordCount) + ' unosa)';

      if Q.IsEmpty then
      begin
        Item := TListBoxItem.Create(lbUnosi);
        Item.Text := 'Nema unosa za ovog radnika';
        lbUnosi.AddObject(Item);
      end
      else
      begin
        i := 0;
        while not Q.Eof do
        begin
          sPet := Q.FieldByName('PetName').AsString;
          if sPet = '' then sPet := '(nepoznat ljubimac)';
          sKat := Q.FieldByName('Kategorija').AsString;

          Item := TListBoxItem.Create(lbUnosi);
          Item.Text := Q.FieldByName('Vrsta_aktivnosti').AsString +
                       '  (' + sKat + ')  ·  ' + sPet + '  ·  ' +
                       FormatDateTime('dd.mm. hh:nn',
                         Q.FieldByName('VremeOd').AsDateTime);
          lbUnosi.AddObject(Item);

          // Puni detalji za popup
          sDetalj :=
            'Kategorija: ' + sKat + #13#10 +
            'Vrsta: ' + Q.FieldByName('Vrsta_aktivnosti').AsString + #13#10 +
            'Ljubimac: ' + sPet + #13#10 +
            'Vreme: ' + FormatDateTime('dd.mm.yyyy. hh:nn',
              Q.FieldByName('VremeOd').AsDateTime);

          if (sKat = 'Aktivnosti') and (Q.FieldByName('VremeDo').AsDateTime > 0) then
            sDetalj := sDetalj + ' - ' +
              FormatDateTime('hh:nn', Q.FieldByName('VremeDo').AsDateTime);

          sDetalj := sDetalj + #13#10 +
            'Status: ' + Q.FieldByName('StatusAktivnosti').AsString;

          if Trim(Q.FieldByName('DuzinaTrajanja').AsString) <> '' then
            sDetalj := sDetalj + #13#10 +
              'Trajanje: ' + Q.FieldByName('DuzinaTrajanja').AsString;
          if Trim(Q.FieldByName('ProcenaPonasanja').AsString) <> '' then
            sDetalj := sDetalj + #13#10 +
              'Procena: ' + Q.FieldByName('ProcenaPonasanja').AsString;
          if Trim(Q.FieldByName('VremeObroka').AsString) <> '' then
            sDetalj := sDetalj + #13#10 +
              'Vreme obroka: ' + Q.FieldByName('VremeObroka').AsString;
          if Trim(Q.FieldByName('Kolicina').AsString) <> '' then
            sDetalj := sDetalj + #13#10 +
              'Kolicina: ' + Q.FieldByName('Kolicina').AsString;
          if Trim(Q.FieldByName('StatusOstalo').AsString) <> '' then
            sDetalj := sDetalj + #13#10 +
              'Status (ostalo): ' + Q.FieldByName('StatusOstalo').AsString;
          if Trim(Q.FieldByName('Komentar').AsString) <> '' then
            sDetalj := sDetalj + #13#10 +
              'Komentar: ' + Q.FieldByName('Komentar').AsString;

          if i <= High(FUnosDetalji) then
            FUnosDetalji[i] := sDetalj;

          Inc(i);
          Q.Next;
        end;
      end;
      Q.Close;
    finally
      lbUnosi.EndUpdate;
    end;
  finally
    Q.Free;
  end;
end;

procedure TFrameAdmin.lbZaposleniClick(Sender: TObject);
begin
  if (lbZaposleni.ItemIndex < 0) or
     (lbZaposleni.ItemIndex >= FZapCount) then Exit;
  PrikaziRadnika(FZapIDs[lbZaposleni.ItemIndex]);
end;

// -------------------------------------------------------
//  Klik na uslugu u cenovniku -> izmena cene (admin)
// -------------------------------------------------------
procedure TFrameAdmin.IzmeniCenuUsluge(idUsluga: Integer);
var
  sNaziv: string;
  dStara: Double;
  Q: TFDQuery;
begin
  // Trenutni naziv i cena (za prikaz u dijalogu)
  sNaziv := '';
  dStara := 0;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := DB;
    Q.SQL.Text := 'SELECT Naziv, Cena FROM USLUGA WHERE Sifra_usluge = :id';
    Q.ParamByName('id').AsInteger := idUsluga;
    Q.Open;
    if Q.IsEmpty then Exit;
    sNaziv := Q.FieldByName('Naziv').AsString;
    dStara := Q.FieldByName('Cena').AsFloat;
  finally
    Q.Free;
  end;

  TDialogService.InputQuery(
    'Izmena cene: ' + sNaziv,
    ['Nova cena (RSD)'],
    [FormatFloat('0.##', dStara)],
    procedure(const AResult: TModalResult; const AValues: array of string)
    var
      sNova: string;
      dNova: Double;
      Q2: TFDQuery;
    begin
      if AResult <> mrOk then Exit;
      if Length(AValues) = 0 then Exit;

      sNova := StringReplace(Trim(AValues[0]), ',', '.', [rfReplaceAll]);
      if not TryStrToFloat(sNova, dNova, TFormatSettings.Invariant) then
      begin
        ShowMessage('Neispravna cena! Unesite broj (npr. 750).');
        Exit;
      end;
      if dNova < 0 then
      begin
        ShowMessage('Cena ne moze biti negativna.');
        Exit;
      end;

      Q2 := TFDQuery.Create(nil);
      try
        Q2.Connection := DB;
        Q2.SQL.Text := 'UPDATE USLUGA SET Cena = :c WHERE Sifra_usluge = :id';
        Q2.ParamByName('c').AsFloat   := dNova;
        Q2.ParamByName('id').AsInteger := idUsluga;
        Q2.ExecSQL;
      finally
        Q2.Free;
      end;

      UcitajCenovnik;
    end);
end;

procedure TFrameAdmin.lbCenovnikClick(Sender: TObject);
var
  idx: Integer;
begin
  idx := lbCenovnik.ItemIndex;
  if (idx < 0) or (idx >= FUslugaCount) then Exit;
  IzmeniCenuUsluge(FUslugaIDs[idx]);
end;

procedure TFrameAdmin.rectIzmeniCenuClick(Sender: TObject);
var
  idx: Integer;
begin
  idx := lbCenovnik.ItemIndex;
  if (idx < 0) or (idx >= FUslugaCount) then
  begin
    ShowMessage('Izaberite uslugu iz liste pa kliknite "Izmeni cenu".');
    Exit;
  end;
  IzmeniCenuUsluge(FUslugaIDs[idx]);
end;

// -------------------------------------------------------
//  Klik na unos radnika -> popup sa detaljima
// -------------------------------------------------------
procedure TFrameAdmin.lbUnosiClick(Sender: TObject);
var
  idx: Integer;
begin
  idx := lbUnosi.ItemIndex;
  if (idx < 0) or (idx > High(FUnosDetalji)) then Exit;
  if FUnosDetalji[idx] = '' then Exit;

  lblPopupNaslov.Text  := lbUnosi.ListItems[idx].Text;
  lblPopupDetalji.Text := FUnosDetalji[idx];
  rectPopup.Visible    := True;
  rectPopup.BringToFront;
end;

procedure TFrameAdmin.rectPopupClick(Sender: TObject);
begin
  rectPopup.Visible := False;
end;

procedure TFrameAdmin.rectPopupZatvoriClick(Sender: TObject);
begin
  rectPopup.Visible := False;
end;

procedure TFrameAdmin.rectOdjavaClick(Sender: TObject);
begin
  LoggedInUserID     := 0;
  LoggedInRole       := '';
  LoggedInUsername   := '';
  LoggedInImePrezime := '';
  SelectedPetID      := 0;
  TNavFrames.GoLogin;
end;

end.
