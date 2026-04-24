unit frmRegister;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts,uNav;

type
  TForm4 = class(TForm)
    Layout1: TLayout;
    Layout2: TLayout;
    btnBack: TButton;
    procedure btnBackClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form4: TForm4;

implementation

{$R *.fmx}

procedure TForm4.btnBackClick(Sender: TObject);
begin
  TNav.Back(Self);
end;

end.
