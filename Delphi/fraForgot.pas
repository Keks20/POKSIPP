unit fraForgot;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts,uNavFrames, FMX.Edit, FMX.Objects,
  uUserStore,FireDAC.Comp.Client;

type
  TFrame3 = class(TFrame)
    Layout1: TLayout;
    rectCard: TRectangle;
    edtUsername: TEdit;
    edtPassword: TEdit;
    rectChange: TRectangle;
    Label1: TLabel;
    edtAgain: TEdit;
    Label2: TLabel;
    lbHaveAcc: TLabel;
    lblLogin: TLabel;
    procedure lblLoginClick(Sender: TObject);
    procedure rectChangeClick(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.fmx}


procedure TFrame3.lblLoginClick(Sender: TObject);
begin
TNavFrames.Back;
end;



procedure TFrame3.rectChangeClick(Sender: TObject);
var
  identifier: string;
begin
  identifier := Trim(edtUsername.Text);


  if identifier = '' then
  begin
    ShowMessage('Unesite korisničko ime, email ili broj telefona');
    Exit;
  end;

  if Trim(edtPassword.Text) = '' then
  begin
    ShowMessage('Unesite novu lozinku');
    Exit;
  end;

  if Trim(edtAgain.Text) = '' then
  begin
    ShowMessage('Ponovite lozinku');
    Exit;
  end;

  if Trim(edtPassword.Text) <> Trim(edtAgain.Text) then
  begin
    ShowMessage('Lozinke se ne poklapaju');
    Exit;
  end;


  try
    with TFDQuery.Create(nil) do
    begin
      try
        Connection := DB;

        // Proveri u MUSTERIJA tabeli (po korisničkom imenu, emailu ili telefonu)
        SQL.Text :=
          'SELECT Sifra_musterije FROM MUSTERIJA ' +
          'WHERE lower(KorisnickoIme) = lower(:x) ' +
          '   OR lower(COALESCE(Email, '''')) = lower(:x) ' +
          '   OR Telefon_Hitno = :x';
        ParamByName('x').AsString := identifier;
        Open;

        if IsEmpty then
        begin
          Close;
          ShowMessage('Ne postoji korisnik sa tim podacima.' + #13#10 +
                      'Unesite korisničko ime, email ili telefon.');
          Exit;
        end;
        Close;

        SQL.Text :=
          'UPDATE MUSTERIJA SET Lozinka = :p ' +
          'WHERE lower(KorisnickoIme) = lower(:x) ' +
          '   OR lower(COALESCE(Email, '''')) = lower(:x) ' +
          '   OR Telefon_Hitno = :x';
        ParamByName('p').AsString := Trim(edtPassword.Text);
        ParamByName('x').AsString := identifier;
        ExecSQL;

      finally
        Free;
      end;
    end;

    ShowMessage('Lozinka je uspešno promenjena!');
    TNavFrames.Back;

  except
    on E: Exception do
      ShowMessage('Greška: ' + E.Message);
  end;
end;

end.
