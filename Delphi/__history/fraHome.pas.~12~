unit fraHome;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Controls.Presentation, FMX.Layouts, FMX.ListBox,
  FireDAC.Comp.Client, uUserStore, uPetModel,uNavFrames;

type
  TFrame5 = class(TFrame)
    Layout1: TLayout;
    Layout2: TLayout;
    imgPet: TImage;
    lblName: TLabel;
    lblBreed: TLabel;
    lblAge: TLabel;
    ListBox1: TListBox;
    Layout3: TLayout;
    Rectangle2: TRectangle;
    Layout7: TLayout;
    GridLayout1: TGridLayout;
    Image1: TImage;
    Image2: TImage;
    Image3: TImage;
    Image4: TImage;
    Label3: TLabel;
    Image5: TImage;
    Label4: TLabel;
    Rectangle3: TRectangle;
    Rectangle4: TRectangle;
    Rectangle5: TRectangle;
    Layout8: TLayout;
    Label5: TLabel;
    Layout9: TLayout;
    Label6: TLabel;
    Layout10: TLayout;
    Label7: TLabel;
    procedure FrameEnter(Sender: TObject);
    procedure btnChangePetClick(Sender: TObject);
    procedure ListBox1Click(Sender: TObject);
    procedure Label3Click(Sender: TObject);
    procedure Image5Click(Sender: TObject);
    procedure Loaded; override;
  private
    procedure LoadPetsFromDB;
    procedure LoadPetsIntoListBox;
    procedure RefreshMainCard;
  public
  end;

implementation
{$R *.fmx}

procedure TFrame5.Loaded;
begin
  inherited;

  LoadPetsFromDB;
  LoadPetsIntoListBox;

  if ActivePetIndex < 0 then
    ActivePetIndex := 0;

  RefreshMainCard;
end;
procedure TFrame5.FrameEnter(Sender: TObject);
begin
  LoadPetsFromDB;
  LoadPetsIntoListBox;
  RefreshMainCard;
  if Pets[0].Id = 0 then
    LoadPetsFromDB;
  LoadPetsIntoListBox;
  if ActivePetIndex = -1 then
    ActivePetIndex := 0;
  RefreshMainCard;
end;

procedure TFrame5.Image5Click(Sender: TObject);
begin
  ActivePetIndex := -1;
  ListBox1.Visible := False;
 TNavFrames.GoLogin;
end;

procedure TFrame5.LoadPetsFromDB;
var
  Q: TFDQuery;
  i: Integer;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := DB;
    Q.SQL.Text := 'SELECT id, name, species, breed, age, image_blob FROM pets ORDER BY id';
    Q.Open;

    FillChar(Pets, SizeOf(Pets), 0);
    i := 0;
    while not Q.Eof and (i <= High(Pets)) do
    begin
      Pets[i].Id := Q.FieldByName('id').AsInteger;
      Pets[i].Name := Q.FieldByName('name').AsString;
      Pets[i].Species := Q.FieldByName('species').AsString;
      Pets[i].Breed := Q.FieldByName('breed').AsString;
      Pets[i].Age := Q.FieldByName('age').AsString;
      Pets[i].ImageBlob := Q.FieldByName('image_blob').AsBytes;
      Inc(i);
      Q.Next;
    end;

    
    if i = 0 then
      ShowMessage('Nema ljubimaca u bazi. Dodajte prvog!');
  finally
    Q.Free;
  end;
end;

procedure TFrame5.LoadPetsIntoListBox;
var
  i: Integer;
  Item: TListBoxItem;
begin
  ListBox1.BeginUpdate;
  try
    ListBox1.Clear;

    for i := 0 to High(Pets) do
    begin
      if Pets[i].Id = 0 then
        Continue;

      Item := TListBoxItem.Create(ListBox1);
      Item.Text := Pets[i].Name;
      Item.ItemData.Detail := Pets[i].Breed + ' • ' + Pets[i].Age;

      ListBox1.AddObject(Item);
    end;

  finally
    ListBox1.EndUpdate;
  end;

  if (ActivePetIndex >= 0) and (ActivePetIndex < ListBox1.Count) then
    ListBox1.ItemIndex := ActivePetIndex;
end;


procedure TFrame5.RefreshMainCard;
var
  Stream: TMemoryStream;
begin
  if (ActivePetIndex < 0) or (Pets[ActivePetIndex].Id = 0) then
  begin
    imgPet.Bitmap.Clear(TAlphaColors.Null);
    lblName.Text := 'Izaberi ljubimca';
    lblBreed.Text := '';
    lblAge.Text := '';
    Exit;
  end;

  lblName.Text := Pets[ActivePetIndex].Name;
  lblBreed.Text := Pets[ActivePetIndex].Breed;
  lblAge.Text := Pets[ActivePetIndex].Age;

  if Length(Pets[ActivePetIndex].ImageBlob) > 0 then
  begin
    Stream := TMemoryStream.Create;
    try
      Stream.WriteBuffer(
        Pets[ActivePetIndex].ImageBlob[0],
        Length(Pets[ActivePetIndex].ImageBlob)
      );
      Stream.Position := 0;
      imgPet.Bitmap.LoadFromStream(Stream);
    finally
      Stream.Free;
    end;
  end
  else
    imgPet.Bitmap.Clear(TAlphaColors.Lightgray);
end;

procedure TFrame5.btnChangePetClick(Sender: TObject);
begin
  ListBox1.Visible := not ListBox1.Visible;
  if ListBox1.Visible then
    ListBox1.BringToFront
  else
    ListBox1.SendToBack;
end;

procedure TFrame5.Label3Click(Sender: TObject);
begin
  ListBox1.Visible := not ListBox1.Visible;
  if ListBox1.Visible then
    ListBox1.BringToFront
  else
    ListBox1.SendToBack;
end;

procedure TFrame5.ListBox1Click(Sender: TObject);
begin
  if ListBox1.ItemIndex < 0 then Exit;
  ActivePetIndex := ListBox1.ItemIndex;
  RefreshMainCard;
  ListBox1.Visible := False;
end;





end.
