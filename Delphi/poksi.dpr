program poksi;



{$R *.dres}

uses
  System.StartUpCopy,
  FMX.Forms,
  uUserStore in 'uUserStore.pas',
  frmMain in 'frmMain.pas' {Form5},
  fraWelcome in 'fraWelcome.pas' {Frame1: TFrame},
  fraLogin in 'fraLogin.pas' {Frame2: TFrame},
  fraForgot in 'fraForgot.pas' {Frame3: TFrame},
  fraRegister in 'fraRegister.pas' {Frame4: TFrame},
  uNavFrames in 'uNavFrames.pas',
  fraHome in 'fraHome.pas' {Frame5: TFrame},
  uPetModel in 'uPetModel.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm5, Form5);
  Application.Run;
end.
