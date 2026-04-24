unit frmMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  uNavFrames, fraWelcome, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf,
  FireDAC.DApt.Intf, FireDAC.Stan.Async, FireDAC.DApt, FireDAC.UI.Intf,
  FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Phys, FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs,
  FireDAC.Phys.SQLiteWrapper.Stat, FireDAC.FMXUI.Wait, Data.DB,
  FireDAC.Comp.Client, FireDAC.Comp.DataSet,uUserStore,fraHome;

type
  TForm5 = class(TForm)
    layHost: TLayout;
    FDQuery1: TFDQuery;
    FDConnection1: TFDConnection;
    procedure FormCreate(Sender: TObject);
  private
    procedure LoadPetsFromDB;
  public
    { Public declarations }
  end;

var
  Form5: TForm5;

implementation

{$R *.fmx}

 procedure TForm5.FormCreate(Sender: TObject);
 var
  Stream: TResourceStream;
begin
  TNavFrames.Init(layHost);
  TNavFrames.Go(TFrame1.Create(nil));
  FDConnection1.Connected := True;
  DB := FDConnection1;
  FDQuery1.SQL.Text :=
  'CREATE TABLE IF NOT EXISTS users (' +
  'id INTEGER PRIMARY KEY AUTOINCREMENT,' +
  'username TEXT UNIQUE,' +
  'email TEXT UNIQUE,' +
  'phone TEXT,' +
  'password TEXT' +
  ')';
  FDQuery1.ExecSQL;
  FDQuery1.SQL.Text :=
    'CREATE TABLE IF NOT EXISTS pets (' +
    'id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    'name TEXT,' +
    'species TEXT,' +
    'breed TEXT,' +
    'age TEXT,' +
    'image_blob BLOB' +
    ')';
  FDQuery1.ExecSQL;
  FDQuery1.SQL.Text := 'SELECT COUNT(*) FROM pets';
  FDQuery1.Open;
  if FDQuery1.Fields[0].AsInteger = 0 then
  begin
    FDQuery1.SQL.Text :=
      'INSERT INTO pets (name, species, breed, age, image_blob) ' +
      'VALUES (:name, :species, :breed, :age, :img)';
    FDQuery1.ParamByName('name').AsString := 'Fido';
    FDQuery1.ParamByName('species').AsString := 'pas';
    FDQuery1.ParamByName('breed').AsString := 'Labrador';
    FDQuery1.ParamByName('age').AsString := '3 godine';
    Stream := TResourceStream.Create(HInstance, 'PngImage_1', RT_RCDATA);
    try
      FDQuery1.ParamByName('img').LoadFromStream(Stream, ftBlob);
    finally
      Stream.Free;
    end;
    FDQuery1.ExecSQL;

    FDQuery1.ParamByName('name').AsString := 'Gus';
    FDQuery1.ParamByName('species').AsString := 'guster';
    FDQuery1.ParamByName('breed').AsString := 'Zeleni guster';
    FDQuery1.ParamByName('age').AsString := '1 godina';
    Stream := TResourceStream.Create(HInstance, 'PngImage_2', RT_RCDATA);
    try
      FDQuery1.ParamByName('img').LoadFromStream(Stream, ftBlob);
    finally
      Stream.Free;
    end;
    FDQuery1.ExecSQL;

    FDQuery1.ParamByName('name').AsString := 'Maca';
    FDQuery1.ParamByName('species').AsString := 'mačka';
    FDQuery1.ParamByName('breed').AsString := 'Persijska mačka';
    FDQuery1.ParamByName('age').AsString := '2 godine';
    Stream := TResourceStream.Create(HInstance, 'PngImage_3', RT_RCDATA);
    try
      FDQuery1.ParamByName('img').LoadFromStream(Stream, ftBlob);
    finally
      Stream.Free;
    end;
    FDQuery1.ExecSQL;
  end
  else
  FDQuery1.Close;
  LoadPetsFromDB;
  TNavFrames.Init(layHost);
  TNavFrames.Go(TFrame1.Create(nil));
end;

procedure TForm5.LoadPetsFromDB;
var
  Q: TFDQuery;
  i: Integer;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := DB;
    Q.SQL.Text :=
      'SELECT id, name, species, breed, age, image_blob FROM pets ORDER BY id';
    Q.Open;

    i := 0;
    while (not Q.Eof) and (i <= High(Pets)) do
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
  finally
    Q.Free;
  end;
end;


end.
