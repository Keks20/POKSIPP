unit fraHrana;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs,
  FMX.StdCtrls, FMX.Controls.Presentation, FMX.Layouts, FMX.Objects,
  FMX.Edit, FMX.Memo, FMX.Memo.Types, FMX.ScrollBox,
  FireDAC.Comp.Client, uUserStore, uNavFrames;

type
  TFrameHrana = class(TFrame)


    layHeader: TLayout;
    lblNaslov: TLabel;
    rectNazad: TRectangle;


    rectForma: TRectangle;

    lblVrsta: TLabel;
    edtVrsta: TEdit;          // npr. "Super premium granule (Junior)"

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
    function ParsujVreme(const AVreme: string;
      out ADT: TDateTime): Boolean;
    procedure SacuvajHranu;
  end;

implementation

{$R *.fmx}

procedure TFrameHrana.Loaded;
begin
  inherited;
  lblNaslov.Text      := 'Hrana';
  edtVremeObroka.Text := FormatDateTime('hh:nn', Now);
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

procedure TFrameHrana.SacuvajHranu;
var
  Q: TFDQuery;
  dtVreme: TDateTime;
begin
  // --- Validacija ---
  if Trim(edtVrsta.Text) = '' then
  begin
    ShowMessage('Unesite vrstu hrane!');
    edtVrsta.SetFocus;
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

  // --- SQL INSERT ---
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := DB;
    Q.SQL.Text :=
      'INSERT INTO DNEVNA_AKTIVNOST ' +
      '  (Kategorija, Vrsta_aktivnosti, VremeOd, VremeDo, ' +
      '   DuzinaTrajanja, StatusAktivnosti, ' +
      '   VremeObroka, Kolicina, Komentar, ' +
      '   Sifra_zaposlenog, Sifra_ljubimca) ' +
      'VALUES ' +
      '  (:kat, :vrsta, :od, :od, ' +
      '   :traj, :status, ' +
      '   :vobroka, :kol, :kom, ' +
      '   :zap, :pet)';

    Q.ParamByName('kat').AsString     := 'Hrana';
    Q.ParamByName('vrsta').AsString   := Trim(edtVrsta.Text);
    Q.ParamByName('od').AsDateTime    := dtVreme;
    Q.ParamByName('traj').AsString    := '0 min';
    Q.ParamByName('status').AsString  := 'Zavrseno';
    Q.ParamByName('vobroka').AsString := Trim(edtVremeObroka.Text);
    Q.ParamByName('kol').AsString     := Trim(edtKolicina.Text);
    Q.ParamByName('kom').AsString     := Trim(memoKomentar.Text);
    Q.ParamByName('zap').AsInteger    := LoggedInUserID;
    Q.ParamByName('pet').AsInteger    := SelectedPetID;
    Q.ExecSQL;

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
