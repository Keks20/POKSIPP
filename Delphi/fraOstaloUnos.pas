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
    edtStatus: TEdit;         // npr. "Dlaka ociscena, nokti skropani"

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

procedure TFrameOstaloUnos.SacuvajOstalo;
var
  Q: TFDQuery;
  dtVreme: TDateTime;
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

  // --- SQL INSERT ---
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := DB;
    Q.SQL.Text :=
      'INSERT INTO DNEVNA_AKTIVNOST ' +
      '  (Kategorija, Vrsta_aktivnosti, VremeOd, VremeDo, ' +
      '   DuzinaTrajanja, StatusAktivnosti, ' +
      '   StatusOstalo, Komentar, ' +
      '   Sifra_zaposlenog, Sifra_ljubimca) ' +
      'VALUES ' +
      '  (:kat, :vrsta, :od, :od, ' +
      '   :traj, :status, ' +
      '   :stost, :kom, ' +
      '   :zap, :pet)';

    Q.ParamByName('kat').AsString    := 'Ostalo';
    Q.ParamByName('vrsta').AsString  := Trim(edtVrsta.Text);
    Q.ParamByName('od').AsDateTime   := dtVreme;
    Q.ParamByName('traj').AsString   := '0 min';
    Q.ParamByName('status').AsString := 'Zavrseno';
    Q.ParamByName('stost').AsString  := Trim(edtStatus.Text);
    Q.ParamByName('kom').AsString    := Trim(memoKomentar.Text);
    Q.ParamByName('zap').AsInteger   := LoggedInUserID;
    Q.ParamByName('pet').AsInteger   := SelectedPetID;
    Q.ExecSQL;

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
