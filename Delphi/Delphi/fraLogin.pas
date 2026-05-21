unit fraLogin;

interface


uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Edit, FMX.Objects, FMX.Controls.Presentation, FMX.Layouts,
  uNavFrames, fraForgot, fraRegister, FireDAC.Comp.Client, uUserStore;

type
  TFrame2 = class(TFrame)
    Layout1: TLayout;
    Label1: TLabel;
    rectCard: TRectangle;
    edtUsername: TEdit;
    edtPassword: TEdit;
    rectLoginButton: TRectangle;
    Label2: TLabel;
    lblForgot: TLabel;
    lbNoAcc: TLabel;
    lblRegister: TLabel;
    procedure lblForgotClick(Sender: TObject);
    procedure lblRegisterClick(Sender: TObject);
    procedure rectLoginButtonClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.fmx}

uses fraOsoblje, fraDnevnikMusterije;

procedure TFrame2.lblForgotClick(Sender: TObject);
begin
  TNavFrames.Go(TFrame3.Create(nil));
end;

procedure TFrame2.lblRegisterClick(Sender: TObject);
begin
  TNavFrames.Go(TFrame4.Create(nil));
end;

procedure TFrame2.rectLoginButtonClick(Sender: TObject);
var
  sUser, sPass: string;
  Q: TFDQuery;
begin
  sUser := Trim(edtUsername.Text);
  sPass := Trim(edtPassword.Text);

  if sUser = '' then
  begin
    ShowMessage('Unesite korisnicko ime!');
    Exit;
  end;

  if sPass = '' then
  begin
    ShowMessage('Unesite lozinku!');
    Exit;
  end;

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := DB;

    // ============================================
    // KORAK 1: ZAPOSLENI → fraOsoblje
    // ============================================
    Q.SQL.Text :=
      'SELECT Sifra_zaposlenog, Ime, Prezime, KorisnickoIme ' +
      'FROM ZAPOSLENI ' +
      'WHERE lower(KorisnickoIme) = lower(:u) AND Lozinka = :p';
    Q.ParamByName('u').AsString := sUser;
    Q.ParamByName('p').AsString := sPass;
    Q.Open;

    if not Q.IsEmpty then
    begin
      LoggedInUserID     := Q.FieldByName('Sifra_zaposlenog').AsInteger;
      LoggedInUsername   := Q.FieldByName('KorisnickoIme').AsString;
      LoggedInImePrezime := Q.FieldByName('Ime').AsString + ' ' +
                            Q.FieldByName('Prezime').AsString;
      LoggedInRole := 'ZAPOSLENI';
      Q.Close;
      TNavFrames.Go(TFrameOsoblje.Create(nil));
      Exit;
    end;
    Q.Close;

    // ============================================
    // KORAK 2: MUSTERIJA → fraDnevnikMusterije
    // ============================================
    Q.SQL.Text :=
      'SELECT Sifra_musterije, Ime, Prezime, KorisnickoIme ' +
      'FROM MUSTERIJA ' +
      'WHERE lower(KorisnickoIme) = lower(:u) AND Lozinka = :p';
    Q.ParamByName('u').AsString := sUser;
    Q.ParamByName('p').AsString := sPass;
    Q.Open;

    if not Q.IsEmpty then
    begin
      LoggedInUserID     := Q.FieldByName('Sifra_musterije').AsInteger;
      LoggedInUsername   := Q.FieldByName('KorisnickoIme').AsString;
      LoggedInImePrezime := Q.FieldByName('Ime').AsString + ' ' +
                            Q.FieldByName('Prezime').AsString;
      LoggedInRole := 'MUSTERIJA';
      Q.Close;
      // Direktno na dnevnik — bez fraHome
      TNavFrames.Go(TFrameDnevnikMusterije.Create(nil));
      Exit;
    end;
    Q.Close;

    ShowMessage('Pogresno korisnicko ime ili lozinka!');

  finally
    Q.Free;
  end;
end;

end.
