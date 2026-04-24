unit uPetModel;

interface
uses
  System.SysUtils;
type
  TPet = record
    Id: Integer;
    Name: string;
    Species: string;
    Breed: string;
    Age: string;
    ImageBlob: TBytes;
  end;

implementation

end.
