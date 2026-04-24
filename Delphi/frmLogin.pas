unit frmLogin;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, frmForgot,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.Edit, FMX.Objects,
  frmRegister,uNav;

type
  TForm2 = class(TForm)
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
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

implementation

{$R *.fmx}

procedure TForm2.lblForgotClick(Sender: TObject);
begin
    TNav.Go(Self, Form3);
    Hide;
end;

procedure TForm2.lblRegisterClick(Sender: TObject);
begin
  TNav.Go(Self, Form4);
  Hide;
end;

end.
