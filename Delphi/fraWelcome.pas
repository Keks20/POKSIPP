unit fraWelcome;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Controls.Presentation, FMX.Layouts,uNavFrames, fraLogin;

type
  TFrame1 = class(TFrame)
    Layout1: TLayout;
    Label1: TLabel;
    Image1: TImage;
    Rectangle1: TRectangle;
    Label2: TLabel;
    Layout2: TLayout;
    procedure Rectangle1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.fmx}

procedure TFrame1.Rectangle1Click(Sender: TObject);
begin
  TNavFrames.Go(TFrame2.Create(Self));
end;

end.
