unit fraLogin;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Edit, FMX.Objects, FMX.Controls.Presentation, FMX.Layouts,uNavFrames,fraForgot,
  fraRegister,FireDAC.Comp.Client,uUserStore,fraHome;

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
  Username, Pass: string;
begin
  Username := Trim(edtUsername.Text);
  Pass := Trim(edtPassword.Text);

  with TFDQuery.Create(nil) do
  begin
    try
      Connection := DB;
      // Proveravamo prvo tabelu ZAPOSLENI
      SQL.Text := 'SELECT * FROM ZAPOSLENI WHERE KorisnickoIme = :u AND Lozinka = :p';
      ParamByName('u').AsString := Username;
      ParamByName('p').AsString := Pass;
      Open;

      if not IsEmpty then
      begin
        LoggedInUserID := FieldByName('Sifra_zaposlenog').AsInteger;
        LoggedInRole := 'ZAPOSLENI';
        LoggedInUsername := FieldByName('KorisnickoIme').AsString;
        TNavFrames.Go(TFrame5.Create(nil)); // Ide na Home
        Exit;
      end;

      // Ako nije zaposleni, proveravamo obične korisnike (tabela users)
      Close;
      SQL.Text := 'SELECT * FROM users WHERE (username = :u OR email = :u) AND password = :p';
      ParamByName('u').AsString := Username;
      ParamByName('p').AsString := Pass;
      Open;

      if not IsEmpty then
      begin
        LoggedInUserID := FieldByName('id').AsInteger;
        LoggedInRole := 'USER';
        LoggedInUsername := FieldByName('username').AsString;
        TNavFrames.Go(TFrame5.Create(nil));
      end
      else
        ShowMessage('Pogresni podaci za prijavu!');
    finally
      Free;
    end;
  end;
end;
end.
