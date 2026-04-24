unit fraRegister;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts,uNavFrames, FMX.Objects, FMX.Edit,
  FireDAC.Comp.Client,uUserStore;

type
  TFrame4 = class(TFrame)
    Layout1: TLayout;
    Layout3: TLayout;
    lblTitle: TLabel;
    rectCard: TRectangle;
    edtUsername: TEdit;
    edtPassword: TEdit;
    edtNumber: TEdit;
    edtEmail: TEdit;
    btnRegister: TRectangle;
    Label1: TLabel;
    lblLogin: TLabel;
    lbHaveAcc: TLabel;
    procedure lblLoginClick(Sender: TObject);
    procedure btnRegisterClick(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.fmx}



procedure TFrame4.btnRegisterClick(Sender: TObject);
begin

  if Trim(edtUsername.Text) = '' then
  begin
    ShowMessage('Unesite korisničko ime');
    Exit;
  end;

  if Trim(edtEmail.Text) = '' then
  begin
    ShowMessage('Unesite email');
    Exit;
  end;

  if Trim(edtNumber.Text) = '' then
  begin
    ShowMessage('Unesite broj telefona');
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
          'INSERT INTO users (username, email, phone, password) ' +
          'VALUES (:u, :e, :p, :pw)';

        ParamByName('u').AsString := edtUsername.Text;
        ParamByName('e').AsString := edtEmail.Text;
        ParamByName('p').AsString := edtNumber.Text;
        ParamByName('pw').AsString := edtPassword.Text;

        ExecSQL;
      finally
        Free;
      end;
    end;

    ShowMessage('Uspešna registracija!');
    TNavFrames.Back;

  except
    on E: Exception do
      ShowMessage('Greška: ' + E.Message);
  end;
end;

procedure TFrame4.lblLoginClick(Sender: TObject);
begin

  TNavFrames.Back;
end;

end.
