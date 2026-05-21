unit fraOsoblje;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts, FMX.Objects, FMX.ListBox,
  FireDAC.Comp.Client, uUserStore, uNavFrames;

type
  TFrameOsoblje = class(TFrame)
    // --- ZAGLAVLJE ---
    layHeader: TLayout;
    lblNaslov: TLabel;
    rectOdjava: TRectangle;

    // --- LJUBIMCI ---

    lbLjubimci: TListBox;

   // --- PLAN ---
    lblPlanTitle: TLabel;

    rectAktivnosti: TRectangle;
    lblAktivnosti: TLabel;
    lblAktivnostiSub: TLabel;
    rectAktivnostiBtn: TRectangle;

    rectHrana: TRectangle;
    lblHrana: TLabel;
    lblHranaSub: TLabel;
    rectHranaBtn: TRectangle;

    rectOstalo: TRectangle;
    lblOstalo: TLabel;
    lblOstaloSub: TLabel;
    rectOstaloBtn: TRectangle;

    procedure Loaded; override;
    procedure Show; override;
    procedure rectOdjavaClick(Sender: TObject);
    procedure rectAktivnostiBtnClick(Sender: TObject);
    procedure rectHranaBtnClick(Sender: TObject);
    procedure rectOstaloBtnClick(Sender: TObject);
    procedure lbLjubimciClick(Sender: TObject);

  private
    FPetIDs: array[0..19] of Integer;
    FPetCount: Integer;
    procedure UcitajLjubimce;
    procedure AzurirajBrojeve;
  public
  end;

implementation

{$R *.fmx}
uses fraAktivnosti, fraHrana, fraOstaloUnos;
// -------------------------------------------------------
//  Ucitaj ljubimce - samo tekst, bez slika u ListBoxu
//  (isto kao fraHome - Item.Text + Item.ItemData.Detail)
// -------------------------------------------------------
procedure TFrameOsoblje.UcitajLjubimce;
var
  Q: TFDQuery;
  Item: TListBoxItem;
begin
  lbLjubimci.BeginUpdate;
  try
    lbLjubimci.Clear;
    FPetCount := 0;

    Q := TFDQuery.Create(nil);
    try
      Q.Connection := DB;
      Q.SQL.Text :=
        'SELECT p.id, p.name, p.breed, p.species, p.age, ' +
        '       m.Ime, m.Prezime ' +
        'FROM pets p ' +
        'LEFT JOIN MUSTERIJA m ON m.Sifra_musterije = p.Sifra_musterije ' +
        'ORDER BY p.name';
      Q.Open;

      while not Q.Eof do
      begin
        FPetIDs[FPetCount] := Q.FieldByName('id').AsInteger;

        Item := TListBoxItem.Create(lbLjubimci);
        Item.Text := Q.FieldByName('name').AsString;
        Item.ItemData.Detail :=
          Q.FieldByName('species').AsString + ' · ' +
          Q.FieldByName('breed').AsString + ' · ' +
          Q.FieldByName('age').AsString + '  |  ' +
          'Vlasnik: ' +
          Q.FieldByName('Ime').AsString + ' ' +
          Q.FieldByName('Prezime').AsString;
        lbLjubimci.AddObject(Item);

        Inc(FPetCount);
        Q.Next;
      end;
    finally
      Q.Free;
    end;
  finally
    lbLjubimci.EndUpdate;
  end;

  if lbLjubimci.Count > 0 then
  begin
    lbLjubimci.ItemIndex := 0;
    ActivePetIndex := 0;
    SelectedPetID  := FPetIDs[0];
  end;
end;


procedure TFrameOsoblje.Loaded;
begin
  inherited;
  UcitajLjubimce;
  AzurirajBrojeve;
end;

procedure TFrameOsoblje.AzurirajBrojeve;
var
  Q: TFDQuery;
  nAkt, nHrana, nOst: Integer;
begin

  if SelectedPetID <= 0 then Exit;

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := DB;
    Q.SQL.Text :=
      'SELECT COUNT(*) FROM DNEVNA_AKTIVNOST ' +
      'WHERE Sifra_ljubimca = :pid AND Kategorija = :kat ' +
      'AND date(VremeOd) = date(''now'')';

    Q.ParamByName('pid').AsInteger := SelectedPetID;

    Q.ParamByName('kat').AsString := 'Aktivnosti';
    Q.Open; nAkt   := Q.Fields[0].AsInteger; Q.Close;

    Q.ParamByName('kat').AsString := 'Hrana';
    Q.Open; nHrana := Q.Fields[0].AsInteger; Q.Close;

    Q.ParamByName('kat').AsString := 'Ostalo';
    Q.Open; nOst   := Q.Fields[0].AsInteger; Q.Close;

    lblAktivnostiSub.Text := 'Uneseno danas: ' + IntToStr(nAkt);
    lblHranaSub.Text      := 'Uneseno danas: ' + IntToStr(nHrana);
    lblOstaloSub.Text     := 'Uneseno danas: ' + IntToStr(nOst);

  finally
    Q.Free;
  end;
end;

procedure TFrameOsoblje.lbLjubimciClick(Sender: TObject);
begin
  if (lbLjubimci.ItemIndex < 0) or
     (lbLjubimci.ItemIndex >= FPetCount) then Exit;
  ActivePetIndex := lbLjubimci.ItemIndex;
  SelectedPetID  := FPetIDs[lbLjubimci.ItemIndex];
  AzurirajBrojeve;
end;

procedure TFrameOsoblje.rectAktivnostiBtnClick(Sender: TObject);
begin
  if SelectedPetID <= 0 then
  begin
    ShowMessage('Izaberite ljubimca sa liste!');
    Exit;
  end;
  TNavFrames.Go(TFrameAktivnosti.Create(nil));
end;

procedure TFrameOsoblje.rectHranaBtnClick(Sender: TObject);
begin
  if SelectedPetID <= 0 then
  begin
    ShowMessage('Izaberite ljubimca sa liste!');
    Exit;
  end;

   TNavFrames.Go(TFrameHrana.Create(nil));
end;

procedure TFrameOsoblje.rectOstaloBtnClick(Sender: TObject);
begin
  if SelectedPetID <= 0 then
  begin
    ShowMessage('Izaberite ljubimca sa liste!');
    Exit;
  end;
  TNavFrames.Go(TFrameOstaloUnos.Create(nil));
end;

procedure TFrameOsoblje.rectOdjavaClick(Sender: TObject);
begin
  LoggedInUserID     := 0;
  LoggedInRole       := '';
  LoggedInUsername   := '';
  LoggedInImePrezime := '';
  SelectedPetID      := 0;
  TNavFrames.GoLogin;
end;
procedure TFrameOsoblje.Show;
begin
  inherited;
  AzurirajBrojeve;

end;

end.
