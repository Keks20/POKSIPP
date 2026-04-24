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
begin
  if Trim(edtUsername.Text) = '' then
  begin
    ShowMessage('Unesite korisničko ime ili email');
    Exit;
  end;

  if Trim(edtPassword.Text) = '' then
  begin
    ShowMessage('Unesite lozinku');
    Exit;
  end;

  try
    with TFDQuery.Create(nil) do
    begin
      try
        Connection := DB;

        SQL.Text :=
          'SELECT * FROM users ' +
          'WHERE (lower(username) = lower(:u) OR lower(email) = lower(:u)) ' +
          'AND password = :p';

        ParamByName('u').AsString := Trim(edtUsername.Text);
        ParamByName('p').AsString := edtPassword.Text;

        Open;

        if IsEmpty then
        begin
          ShowMessage('Pogrešan username/email ili lozinka');
          Exit;
        end;

      finally
        Free;
      end;
    end;

    TNavFrames.Go(TFrame5.Create(nil));

  except
    on E: Exception do
      ShowMessage('Greška: ' + E.Message);
  end;
end;


end.
